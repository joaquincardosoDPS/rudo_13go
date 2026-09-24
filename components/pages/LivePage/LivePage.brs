sub init()
    setLocals()
    setControls()
    setupFonts()
    setupColors()
    setObservers()
    initialize()
end sub

sub setLocals()
    m.scene = m.top.GetScene()
    m.theme = m.global.appTheme
    m.fonts = m.global.Fonts
    m.playlist = []
    m.programation = []
    m.loadedPlaylist = false
    m.loadedEpg = false
    m.channels = []
    m.rowNodes = []
    m.selectedIndex = 0
    m.overlayShown = false
    m.focusArea = "grid"
    m.controlIndex = 0
    m.gridRow = 0
    m.gridItem = 0
    m.scrollY = 0
    m.isPaused = false
    m.loaded = false
    m.rowHeight = 117
    m.rowGap = 5
    m.clipHeight = 441
    m.gridWidth = 1721
    m.adsPlaying = false
    m.adsTask = invalid
end sub

sub setControls()
    m.vLive = m.top.findNode("vLive")
    m.gOverlay = m.top.findNode("gOverlay")
    m.pFadeBottom = m.top.findNode("pFadeBottom")
    m.pPill = m.top.findNode("pPill")
    m.lEnvivo = m.top.findNode("lEnvivo")
    m.lChannelName = m.top.findNode("lChannelName")
    m.lProgramTitle = m.top.findNode("lProgramTitle")
    m.gControls = m.top.findNode("gControls")
    m.bPause = m.top.findNode("bPause")
    m.pPauseBg = m.top.findNode("pPauseBg")
    m.pPauseIcon = m.top.findNode("pPauseIcon")
    m.pPauseFocus = m.top.findNode("pPauseFocus")
    m.bQuality = m.top.findNode("bQuality")
    m.pQualBg = m.top.findNode("pQualBg")
    m.pQualFocus = m.top.findNode("pQualFocus")
    m.lQualLabel = m.top.findNode("lQualLabel")
    m.lQualValue = m.top.findNode("lQualValue")
    m.gGridClip = m.top.findNode("gGridClip")
    m.gGridTrack = m.top.findNode("gGridTrack")
    m.tHide = m.top.findNode("tHide")
    m.bsLoading = m.top.findNode("bsLoading")
end sub

sub setupFonts()
    m.lEnvivo.font = m.fonts.dmSansBold18
    m.lChannelName.font = m.fonts.dmSansBold48
    m.lProgramTitle.font = m.fonts.dmSansMedium23
    m.lQualLabel.font = m.fonts.dmSansMedium20
    m.lQualValue.font = m.fonts.dmSansMedium20
end sub

sub setupColors()
    m.pPill.blendColor = "#FF0000"
    m.pPauseBg.blendColor = "#1C1D28"
    m.pQualBg.blendColor = "#1C1D28"
    m.pPauseFocus.blendColor = m.theme.focPrimary
    m.pQualFocus.blendColor = m.theme.focPrimary
    m.pPauseIcon.blendColor = "#FFFFFF"
    m.lProgramTitle.color = m.theme.white
end sub

sub setObservers()
    m.top.observeField("focusedChild", "onFocusedChild")
    m.top.observeField("visible", "onVisibleChange")
    m.tHide.observeField("fire", "onHideTimer")
    m.vLive.observeField("state", "onVideoState")
end sub

sub onVisibleChange(event as dynamic)
    if not event.getData()
        finishPreroll()
        stopDai()
        if isValid(m.vLive)
            m.vLive.control = "stop"
            m.vLive.content = invalid
        end if
        setMenuVisible(true)
    end if
end sub

sub initialize()
    m.pPauseIcon.uri = "pkg:/images/PlayerOverlayIcon/pause.png"
    showLoading(true)
    setMenuVisible(false)
    getPlaylist()
    getEpg()
end sub

sub setMenuVisible(flag as boolean)
    if isValid(m.scene)
        m.scene.callFunc("ShowHideMenu", flag)
    end if
end sub

sub onPageDestroy()
    if m.top.isDestroy
        finishPreroll()
        stopDai()
        if isValid(m.vLive)
            m.vLive.control = "stop"
            m.vLive.content = invalid
        end if
        m.tHide.control = "stop"
        setMenuVisible(true)
        if isValid(m.getPlaylistTask) then m.getPlaylistTask.control = "stop"
        if isValid(m.getEpgTask) then m.getEpgTask.control = "stop"
        if isValid(m.getQualitiesTask) then m.getQualitiesTask.control = "stop"
    end if
end sub

sub showLoading(flag as boolean)
    m.bsLoading.visible = flag
end sub

'===> Data
sub getPlaylist()
    m.getPlaylistTask = CreateObject("roSGNode", "ContentAPIAction")
    m.getPlaylistTask.functionName = "GetJsonByUrl"
    m.getPlaylistTask.params = { "url": m.global.apiEndPoints.GetPlaylistPremium }
    m.getPlaylistTask.observeField("result", "onPlaylistResponse")
    m.getPlaylistTask.control = "RUN"
end sub

sub onPlaylistResponse(event as dynamic)
    apiResponse = event.getData()
    items = getValueFromProps(apiResponse, "data.data", [])
    m.playlist = items
    m.loadedPlaylist = true
    m.getPlaylistTask = invalid
    tryBuildChannels()
end sub

sub getEpg()
    m.getEpgTask = CreateObject("roSGNode", "ContentAPIAction")
    m.getEpgTask.functionName = "GetJsonByUrl"
    m.getEpgTask.params = { "url": m.global.apiEndPoints.GetEPGPrograms }
    m.getEpgTask.observeField("result", "onEpgResponse")
    m.getEpgTask.control = "RUN"
end sub

sub onEpgResponse(event as dynamic)
    apiResponse = event.getData()
    items = getValueFromProps(apiResponse, "data", [])
    m.programation = items
    m.loadedEpg = true
    m.getEpgTask = invalid
    tryBuildChannels()
end sub

sub tryBuildChannels()
    if not (m.loadedPlaylist AND m.loadedEpg) then return
    buildChannels()
    if m.channels.count() = 0
        showLoading(false)
        return
    end if
    buildRows()
    m.loaded = true
    showLoading(false)
    selectChannel(0)
end sub

function nowEpoch() as integer
    nd = CreateObject("roDateTime")
    nd.Mark()
    return nd.AsSeconds()
end function

' ISO 8601 UTC (YYYY-MM-DDTHH:MM:SS...) -> epoch (segundos). No depende de
' fromISO8601String (que en algunos equipos/emulador no parsea el offset).
function isoToEpoch(iso as string) as integer
    if Len(iso) < 19 then return 0
    y = Val(Mid(iso, 1, 4))
    mo = Val(Mid(iso, 6, 2))
    d = Val(Mid(iso, 9, 2))
    h = Val(Mid(iso, 12, 2))
    mi = Val(Mid(iso, 15, 2))
    s = Val(Mid(iso, 18, 2))
    yy = y
    mm = mo
    if mm <= 2
        yy = yy - 1
        mm = mm + 12
    end if
    era = Int(yy / 400)
    yoe = yy - era * 400
    doy = Int((153 * (mm - 3) + 2) / 5) + d - 1
    doe = yoe * 365 + Int(yoe / 4) - Int(yoe / 100) + doy
    days = era * 146097 + doe - 719468
    return days * 86400 + h * 3600 + mi * 60 + s
end function

' Nombre de un bloque del EPG: como la grilla de 13go.cl, el del episodio
' ("episodeTitle": "Machos | Capitulo 100", "Tu Dia"...) y, si no viene, "title"
' (en algunas senales "title" es solo el nombre del canal o de la serie).
function ProgramTitle(ev as object) as string
    episodeTitle = getValueFromProps(ev, "episodeTitle", "")
    if isNonEmptyString(episodeTitle) then return episodeTitle
    return getValueFromProps(ev, "title", "")
end function

function epochToLocalHHMM(epoch as integer) as string
    nd = CreateObject("roDateTime")
    nd.fromSeconds(epoch)
    nd.toLocalTime()
    h = nd.GetHours()
    mi = nd.GetMinutes()
    hs = h.ToStr()
    ms = mi.ToStr()
    if h < 10 then hs = "0" + hs
    if mi < 10 then ms = "0" + ms
    return hs + ":" + ms
end function

sub buildChannels()
    m.channels = []
    nowE = nowEpoch()
    for each item in m.playlist
        active = getValueFromProps(item, "active", false)
        if not active then continue for
        keyLive = getValueFromProps(item, "key_live", "")
        programs = []
        for each epgItem in m.programation
            if getValueFromProps(epgItem, "key_live", "") = keyLive
                events = getValueFromProps(epgItem, "events", [])
                for each ev in events
                    endE = isoToEpoch(getValueFromProps(ev, "endTime", ""))
                    if endE > nowE
                        if programs.count() >= 5 then exit for
                        beginE = isoToEpoch(getValueFromProps(ev, "beginTime", ""))
                        programs.push({
                            "title": ProgramTitle(ev)
                            "timeText": epochToLocalHHMM(beginE)
                            "isLive": (nowE >= beginE AND nowE <= endE)
                        })
                    end if
                end for
                exit for
            end if
        end for
        restriction = getValueFromProps(item, "restriction", "0")
        m.channels.push({
            "key_live": keyLive
            "name_live": getValueFromProps(item, "name_live", "")
            "logo": getValueFromProps(item, "logo", "")
            "color": getValueFromProps(item, "color", "")
            "preview_m3u8": getValueFromProps(item, "preview_m3u8", "")
            "m3u8": getValueFromProps(item, "m3u8", "")
            ' validateRestriction, como LiveGridRow de la web: un suscriptor cuyo plan
            ' incluye la senal no la ve bloqueada.
            "blocked": ValidateRestriction(restriction, getValueFromProps(item, "packs", []))
            "restriction": restriction
            "assetKey": getValueFromProps(item, "assetKey", "")
            "vast": getValueFromProps(item, "vast", "")
            "programs": programs
        })
    end for
end sub

sub buildRows()
    m.gGridTrack.removeChildrenIndex(m.gGridTrack.getChildCount(), 0)
    m.rowNodes = []
    pitch = m.rowHeight + m.rowGap
    for i = 0 to m.channels.count() - 1
        ch = m.channels[i]
        row = CreateObject("roSGNode", "LiveChannelRow")
        row.rowWidth = m.gridWidth
        row.rowHeight = m.rowHeight
        row.logo = ch.logo
        row.channelName = ch.name_live
        row.ringColor = ch.color
        row.blocked = ch.blocked
        row.programs = ch.programs
        row.focusedItemIndex = -1
        row.translation = [0, i * pitch]
        m.gGridTrack.appendChild(row)
        m.rowNodes.push(row)
    end for
end sub

'===> Player
sub selectChannel(index as integer)
    if index < 0 OR index >= m.channels.count() then return
    ch = m.channels[index]
    if ch.blocked then return
    m.selectedIndex = index
    updateHeader(ch)
    hideOverlay()
    finishPreroll()
    stopDai()
    ' Reproductor de Rudo (haveAds = 1 en todas las senales, sin mirar al
    ' usuario): primero el anuncio VAST y recien despues el stream (DAI, firmado
    ' o normal).
    if isNonEmptyString(ch.vast)
        startPreroll(index)
        return
    end if
    playChannel(index)
end sub

' El stream de la senal elegida, una vez terminado el anuncio.
sub playChannel(index as integer)
    ch = m.channels[index]
    ' Reproductor de Rudo (13go.cl): las senales libres con assetKey van por DAI
    ' de Google (DAI=1); las de suscripcion nunca (DAI=0, stream de DPS con token).
    if ch.restriction = "0" AND isNonEmptyString(ch.assetKey)
        startDai(index)
        return
    end if
    ' LivePlayerContainer: las senales de suscripcion (restriction distinta de 0
    ' y 2) se firman con authContent (type live, id = assetKey). Sin token (o sin
    ' assetKey) se sigue con el stream normal, como la web.
    if ch.restriction <> "0" AND ch.restriction <> "2" AND isNonEmptyString(ch.assetKey)
        if isValid(m.liveAuthTask) then m.liveAuthTask.control = "stop"
        m.liveAuthIndex = index
        m.liveAuthTask = CreateObject("roSGNode", "AuthAPIAction")
        m.liveAuthTask.functionName = "AuthenticateContent"
        m.liveAuthTask.params = { type: "live", id: ch.assetKey }
        m.liveAuthTask.observeField("result", "onLiveAuthResponse")
        m.liveAuthTask.control = "RUN"
        return
    end if
    playUrl(ch.preview_m3u8, ch.m3u8)
end sub

sub onLiveAuthResponse(event as dynamic)
    m.liveAuthTask = invalid
    ' Si mientras tanto se eligio otra senal, esta respuesta ya no sirve.
    if m.liveAuthIndex <> m.selectedIndex then return
    ch = m.channels[m.selectedIndex]
    token = getValueFromProps(event.getData(), "data.data.access_token", "")
    if not isNonEmptyString(token) then token = getValueFromProps(event.getData(), "data.access_token", "")
    ' El gateway puede entregar el token ya codificado (event%3D...): se deja
    ' tal cual lo usa el reproductor de 13go.cl (auth-token=event=...~exp=...~hmac=...).
    ' Codificarlo de nuevo lo arruina y Google/DPS responden 401.
    if isNonEmptyString(token) AND Instr(1, token, "%") > 0 then token = token.DecodeUriComponent()
    if isNonEmptyString(token)
        print "LivePage : senal autenticada : " ch.name_live
        playUrl(BuildLiveTokenUrl(ch.m3u8, token), ch.preview_m3u8)
    else
        print "LivePage : no se pudo autenticar la senal : " FormatJson(event.getData())
        playUrl(ch.preview_m3u8, ch.m3u8)
    end if
end sub

' buildLiveUrl de use-hls-player.ts: el primer tramo despues de /hls/ del m3u8
' de la senal va a redirector.dps.live con el token como auth-token (sin volver a
' codificarlo: los = y ~ del token van tal cual, como en el sitio).
function BuildLiveTokenUrl(src as string, token as string) as string
    match = CreateObject("roRegex", "/hls/([^/]+)/", "").Match(src)
    if match.count() < 2 then return src
    return "https://redirector.dps.live/hls/" + match[1] + "/playlist.m3u8?auth-token=" + token
end function

'===> Anuncio VAST al elegir la senal (el adsURL/VMAP del reproductor de Rudo)
' El campo vast de la senal es el VMAP de Rudo para apps
' (rudo.video/ads/vmap/live/{slug}?app=true): un solo preroll de Google, que RAF
' resuelve tal cual. Sin anuncio, con error o si en 10s no empezo (el
' prerollTimeout de Rudo), sigue el stream.
sub startPreroll(index as integer)
    ch = m.channels[index]
    print "LivePage : anuncio : " ch.vast
    m.vLive.control = "stop"
    showLoading(true)
    m.adsPlaying = true
    m.adsIndex = index
    m.adsTask = CreateObject("roSGNode", "PrerollAdsTask")
    m.adsTask.adUrl = ch.vast
    m.adsTask.view = m.top
    m.adsTask.contentId = ch.key_live
    m.adsTask.observeField("status", "onPrerollStatus")
    m.adsTask.control = "RUN"
    if not isValid(m.tAds)
        m.tAds = CreateObject("roSGNode", "Timer")
        m.tAds.duration = 10
        m.tAds.observeField("fire", "onPrerollTimeout")
    end if
    m.tAds.control = "stop"
    m.tAds.control = "start"
end sub

sub onPrerollStatus()
    if not isValid(m.adsTask) then return
    status = m.adsTask.status
    if status = "playing"
        ' RAF muestra el anuncio con su propia interfaz y maneja las teclas.
        m.tAds.control = "stop"
        showLoading(false)
    else if status = "none" OR status = "done"
        index = m.adsIndex
        finishPreroll()
        playChannel(index)
    else if status = "exited"
        ' Back durante el anuncio: sale de En vivo, como back en la pagina.
        finishPreroll()
        m.scene.callFunc("HandleBackKey")
    end if
end sub

sub onPrerollTimeout()
    if not m.adsPlaying then return
    print "LivePage : el anuncio no empezo en 10s, sigue la senal"
    index = m.adsIndex
    finishPreroll()
    playChannel(index)
end sub

sub finishPreroll()
    if isValid(m.tAds) then m.tAds.control = "stop"
    if not m.adsPlaying then return
    m.adsPlaying = false
    showLoading(false)
    if isValid(m.adsTask)
        m.adsTask.cancel = true
        m.adsTask.unobserveField("status")
        m.adsTask = invalid
    end if
    ' RAF se queda con el foco mientras reproduce: vuelve a la pagina.
    if m.top.visible then m.top.setFocus(true)
end sub

'===> DAI (SDK IMA de Google, DAIPlayerTask)
sub startDai(index as integer)
    ch = m.channels[index]
    print "LivePage : DAI : " ch.name_live " assetKey " ch.assetKey
    m.vLive.control = "stop"
    m.daiIndex = index
    m.daiTask = NewLiveDaiTask(m.vLive, ch.assetKey, ch.key_live)
    m.daiTask.observeField("urlData", "onDaiUrl")
    m.daiTask.observeField("errors", "onDaiErrors")
    m.daiTask.control = "RUN"
    ' Si Google no entrega el stream a tiempo se sigue con el normal.
    if not isValid(m.tDai)
        m.tDai = CreateObject("roSGNode", "Timer")
        m.tDai.duration = 20
        m.tDai.observeField("fire", "onDaiTimeout")
    end if
    m.tDai.control = "stop"
    m.tDai.control = "start"
end sub

sub stopDai()
    if isValid(m.tDai) then m.tDai.control = "stop"
    if isValid(m.daiTask)
        StopLiveDaiTask(m.daiTask)
        m.daiTask = invalid
    end if
end sub

sub onDaiUrl(event as dynamic)
    if not isValid(m.daiTask) OR m.daiIndex <> m.selectedIndex then return
    m.tDai.control = "stop"
    data = event.getData()
    url = getValueFromProps(data, "manifest", "")
    if not isNonEmptyString(url)
        daiFallback("sin manifest")
        return
    end if
    print "LivePage : stream DAI : " url
    ' Calidades como en las demas senales: las variantes del manifest de DAI son
    ' de la misma sesion (stream_id) y todas traen las marcas ID3 con que el SDK
    ' detecta los anuncios, asi que cambiar de variante no corta la medicion.
    m.masterPlaylistUrl = url
    m.availableQualities = [{ "label": "Auto", "url": url }]
    m.qualityIndex = 0
    m.lQualValue.text = "Auto"
    startPlayback(url)
    fetchQualities(url)
end sub

sub onDaiErrors(event as dynamic)
    if not isValid(m.daiTask) OR m.daiIndex <> m.selectedIndex then return
    daiFallback(FormatJson(event.getData()))
end sub

sub onDaiTimeout()
    if not isValid(m.daiTask) then return
    daiFallback("Google no entrego el stream en 20s")
end sub

' Como el streamURL de Rudo: sin DAI, el stream normal de la senal.
sub daiFallback(reason as string)
    print "LivePage : DAI no disponible (" reason "), stream normal"
    stopDai()
    ch = m.channels[m.selectedIndex]
    playUrl(ch.preview_m3u8, ch.m3u8)
end sub

sub updateHeader(ch as dynamic)
    m.lChannelName.text = ch.name_live
    if ch.programs.count() > 0
        m.lProgramTitle.text = ch.programs[0].title
    else
        m.lProgramTitle.text = ""
    end if
end sub

sub playUrl(previewUrl as string, fallbackUrl as string)
    url = previewUrl
    if not isNonEmptyString(url) then url = fallbackUrl
    if not isNonEmptyString(url) then return
    url = ForceSessionParams(url, GetDpsSessionParams())
    m.masterPlaylistUrl = url
    m.availableQualities = [{ "label": "Auto", "url": url }]
    m.qualityIndex = 0
    m.lQualValue.text = "Auto"
    startPlayback(url)
    fetchQualities(url)
end sub

sub startPlayback(url as string)
    content = CreateObject("roSGNode", "ContentNode")
    content.url = url
    content.streamformat = "hls"
    content.live = true
    m.isPaused = false
    updatePauseIcon()
    m.vLive.content = content
    m.vLive.control = "play"
end sub

'===> Calidad (parseo del manifest HLS para listar las variantes reales)
sub fetchQualities(url as string)
    if isValid(m.getQualitiesTask) then m.getQualitiesTask.control = "stop"
    m.getQualitiesTask = CreateObject("roSGNode", "ContentAPIAction")
    m.getQualitiesTask.functionName = "GetTextByUrl"
    m.getQualitiesTask.params = { "url": url }
    m.getQualitiesTask.observeField("result", "onQualitiesResponse")
    m.getQualitiesTask.control = "RUN"
end sub

sub onQualitiesResponse(event as dynamic)
    response = event.getData()
    m.getQualitiesTask = invalid
    if not isValid(response) OR not response.ok then return
    variants = ParseHlsVariants(response.data)
    if variants.count() = 0 then return
    qualities = [{ "label": "Auto", "url": m.masterPlaylistUrl }]
    seen = {}
    for each v in variants
        label = ""
        if v.height > 0
            label = v.height.ToStr() + "p"
        else if v.bandwidth > 0
            label = Int(v.bandwidth / 1000).ToStr() + " kbps"
        end if
        if label <> "" AND not seen.DoesExist(label)
            seen[label] = true
            qualities.push({ "label": label, "url": ResolveHlsUrl(m.masterPlaylistUrl, v.url) })
        end if
    end for
    m.availableQualities = qualities
    m.qualityIndex = 0
end sub

sub cycleQuality()
    if not isValid(m.availableQualities) OR m.availableQualities.count() <= 1 then return
    m.qualityIndex = (m.qualityIndex + 1) mod m.availableQualities.count()
    q = m.availableQualities[m.qualityIndex]
    m.lQualValue.text = q.label
    startPlayback(q.url)
end sub

sub togglePause()
    if m.isPaused
        m.vLive.control = "play"
        m.isPaused = false
    else
        m.vLive.control = "pause"
        m.isPaused = true
    end if
    updatePauseIcon()
end sub

sub updatePauseIcon()
    if m.isPaused
        m.pPauseIcon.uri = "pkg:/images/PlayerOverlayIcon/play.png"
    else
        m.pPauseIcon.uri = "pkg:/images/PlayerOverlayIcon/pause.png"
    end if
end sub

sub onVideoState(event as dynamic)
end sub

'===> Overlay / focus
sub showOverlay()
    if m.overlayShown then return
    m.overlayShown = true
    m.gOverlay.visible = true
    setMenuVisible(true)
    m.pFadeBottom.visible = true
    m.vLive.translation = [672, 0]
    m.vLive.width = 1248
    m.vLive.height = 702
    m.focusArea = "grid"
    applyGridFocus()
    updateScroll()
    updateFocusVisuals()
    resetHideTimer()
end sub

sub hideOverlay()
    if not m.overlayShown then return
    m.overlayShown = false
    m.gOverlay.visible = false
    setMenuVisible(false)
    m.pFadeBottom.visible = false
    ' Pantalla completa dentro del area segura de Roku (90%, 16:9): el overscan
    ' de la TV recorta los bordes y la imagen tiene que verse entera, aunque
    ' queden bordes negros.
    m.vLive.translation = [96, 54]
    m.vLive.width = 1728
    m.vLive.height = 972
    m.tHide.control = "stop"
end sub

sub resetHideTimer()
    m.tHide.control = "stop"
    m.tHide.control = "start"
end sub

sub onHideTimer()
    hideOverlay()
end sub

function programCount(row as integer) as integer
    if row < 0 OR row >= m.channels.count() then return 0
    return m.channels[row].programs.count()
end function

sub clampGridItem()
    count = programCount(m.gridRow)
    if count <= 0
        m.gridItem = 0
    else if m.gridItem > count - 1
        m.gridItem = count - 1
    end if
end sub

sub applyGridFocus()
    for i = 0 to m.rowNodes.count() - 1
        if i = m.gridRow
            m.rowNodes[i].focusedItemIndex = m.gridItem
        else
            m.rowNodes[i].focusedItemIndex = -1
        end if
    end for
end sub

sub clearGridFocus()
    for i = 0 to m.rowNodes.count() - 1
        m.rowNodes[i].focusedItemIndex = -1
    end for
end sub

sub updateFocusVisuals()
    inControls = (m.focusArea = "controls")
    m.pPauseFocus.visible = (inControls AND m.controlIndex = 0)
    m.pQualFocus.visible = (inControls AND m.controlIndex = 1)
end sub

sub updateScroll()
    pitch = m.rowHeight + m.rowGap
    y = m.gridRow * pitch
    if y < m.scrollY then m.scrollY = y
    if y + pitch > m.scrollY + m.clipHeight then m.scrollY = y + pitch - m.clipHeight
    total = m.rowNodes.count() * pitch - m.rowGap
    maxScroll = total - m.clipHeight
    if maxScroll < 0 then maxScroll = 0
    if m.scrollY < 0 then m.scrollY = 0
    if m.scrollY > maxScroll then m.scrollY = maxScroll
    m.gGridTrack.translation = [0, -m.scrollY]
end sub

sub onFocusedChild()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    ' Mientras se pide el anuncio, back sigue saliendo y el resto se ignora (con
    ' el anuncio en pantalla las teclas son de RAF).
    if m.adsPlaying
        if key = "back" then return false
        return true
    end if
    if not press then return false
    if not m.loaded then return false

    if not m.overlayShown
        if key = "OK" then togglePause()
        showOverlay()
        return true
    end if

    resetHideTimer()

    if m.focusArea = "controls"
        if key = "OK"
            if m.controlIndex = 0
                togglePause()
            else
                cycleQuality()
            end if
            return true
        else if key = "left"
            if m.controlIndex > 0
                m.controlIndex = m.controlIndex - 1
                updateFocusVisuals()
                return true
            end if
            return false
        else if key = "right"
            if m.controlIndex < 1
                m.controlIndex = m.controlIndex + 1
                updateFocusVisuals()
                return true
            end if
            return false
        else if key = "down"
            m.focusArea = "grid"
            m.gridRow = 0
            m.gridItem = 0
            applyGridFocus()
            updateScroll()
            updateFocusVisuals()
            return true
        end if
        return false
    end if

    ' focusArea = "grid"
    if key = "OK"
        selectChannel(m.gridRow)
        return true
    else if key = "left"
        if m.gridItem > 0
            m.gridItem = m.gridItem - 1
            applyGridFocus()
            return true
        end if
        return false
    else if key = "right"
        count = programCount(m.gridRow)
        if m.gridItem < count - 1
            m.gridItem = m.gridItem + 1
            applyGridFocus()
        end if
        return true
    else if key = "up"
        if m.gridRow > 0
            m.gridRow = m.gridRow - 1
            clampGridItem()
            applyGridFocus()
            updateScroll()
            return true
        end if
        m.focusArea = "controls"
        m.controlIndex = 0
        clearGridFocus()
        updateFocusVisuals()
        return true
    else if key = "down"
        if m.gridRow < m.rowNodes.count() - 1
            m.gridRow = m.gridRow + 1
            clampGridItem()
            applyGridFocus()
            updateScroll()
        end if
        return true
    end if
    return false
end function

