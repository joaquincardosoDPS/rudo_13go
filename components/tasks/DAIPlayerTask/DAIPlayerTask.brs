Library "Roku_Ads.brs"
Library "IMA3.brs"

sub init()
    m.top.functionName = "PlayLiveDai"
end sub

sub PlayLiveDai()
    ' Sin el SDK (ej: el simulador brs-node no trae IMA ni RAF) la pagina sigue
    ' con el stream normal.
    if type(New_IMASDK) <> "Function" AND type(New_IMASDK) <> "roFunction"
        Fail("SDK IMA no disponible")
        return
    end if
    m.video = m.top.video
    ' Cualquier falla del SDK termina en errors (la pagina sigue sin DAI) en
    ' vez de colgar la task.
    try
        m.sdk = New_IMASDK()
        m.sdk.initSdk()
        SetupPlayer()
        if LoadStream() then RunLoop()
    catch e
        Fail("fallo del SDK: " + e.message)
    end try
end sub

sub Fail(reason as string)
    print "DAIPlayerTask : " reason
    m.top.errors = [reason]
end sub

' Callbacks que el SDK llama sobre el "player": loadUrl entrega la URL del
' stream con los anuncios; adBreakStarted/Ended marcan las tandas.
sub SetupPlayer()
    m.player = m.sdk.createPlayer()
    m.player.top = m.top
    m.player.loadUrl = function(urlData)
        m.top.urlData = urlData
    end function
    m.player.adBreakStarted = function(adBreakInfo as object)
        print "DAIPlayerTask : empieza la tanda"
        m.top.adPlaying = true
    end function
    m.player.adBreakEnded = function(adBreakInfo as object)
        print "DAIPlayerTask : termina la tanda"
        m.top.adPlaying = false
    end function
    m.player.seek = function(timeSeconds as double)
        m.top.video.seekMode = "accurate"
        m.top.video.seek = timeSeconds
    end function
end sub

function LoadStream() as boolean
    data = m.top.streamData
    ' Como el LiveStream del reproductor de Rudo: solo el assetKey (sin apiKey ni
    ' networkCode, que el evento no exige).
    request = m.sdk.CreateLiveStreamRequest(data.assetKey, "", "")
    request.player = m.player
    request.adUiNode = m.video
    requestError = m.sdk.requestStream(request)
    if requestError <> invalid
        Fail("error pidiendo el stream: " + FormatJson(requestError))
        return false
    end if
    ' El SDK entrega el streamManager cuando Google responde (hasta 15s).
    m.streamManager = invalid
    waited = 0
    while m.streamManager = invalid
        if m.top.stop then return false
        if waited >= 15000
            Fail("Google no respondio el stream")
            return false
        end if
        sleep(50)
        waited = waited + 50
        m.streamManager = m.sdk.getStreamManager()
    end while
    if m.streamManager["type"] <> invalid AND m.streamManager["type"] = "error"
        Fail("stream con error: " + FormatJson(m.streamManager["info"]))
        return false
    end if
    m.top.streamManagerReady = true
    m.streamManager.addEventListener(m.sdk.AdEvent.ERROR, OnAdError)
    m.streamManager.addEventListener(m.sdk.AdEvent.START, OnAdStart)
    m.player.streamManager = m.streamManager
    m.streamManager.start()
    return true
end function

' El SDK lee los metadatos ID3 del stream y los eventos del Video para medir
' cada anuncio; RAF maneja los interactivos (companions).
sub RunLoop()
    m.video.timedMetaDataSelectionKeys = ["*"]
    m.port = CreateObject("roMessagePort")
    fields = m.video.getFields()
    for each field in fields
        m.video.observeFieldScoped(field, m.port)
    end for
    interactivePlayer = { sgNode: m.video, port: m.port }
    adIface = Roku_Ads()
    adIface.enableAdMeasurements(true)
    adIface.setContentLength(99999999)
    contentId = m.top.streamData.contentId
    if contentId <> invalid then adIface.setContentId(contentId)
    while true
        msg = wait(1000, m.port)
        if m.top.stop then exit while
        curAd = adIface.stitchedAdHandledEvent(msg, interactivePlayer)
        if curAd <> invalid AND curAd.evtHandled = true AND curAd.adExited = true then exit while
        m.streamManager.onMessage(msg)
    end while
    ' Solo los observers de esta task: los de la pagina sobre el mismo Video siguen.
    for each field in fields
        m.video.unobserveFieldScoped(field)
    end for
    print "DAIPlayerTask : fin"
end sub

' Los callbacks del SDK no garantizan que "m" sea el de la task: el Video se
' toma de GetGlobalAA().
function OnAdStart(ad as object) as void
    if ad.companions <> invalid AND ad.companions.count() > 0
        adIface = Roku_Ads()
        adIface.enableAdMeasurements(true)
        adIface.stitchedAdsInit(convertToRaf(ad, Int(GetGlobalAA().video.position)))
    end if
end function

function OnAdError(error as object) as void
    ' Un anuncio que falla no corta el stream: el contenido sigue.
    print "DAIPlayerTask : error de anuncio : " FormatJson(error)
end function
