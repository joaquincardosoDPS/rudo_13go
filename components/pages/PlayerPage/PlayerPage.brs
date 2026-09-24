' Reproductor de capitulos calcado de PlayerView.tsx (carga del episodio) +
' VideoPlayer.tsx / use-hls-player.ts (URL final con la sesion DPS, arranque en
' initialSeconds, calidades, controles propios en PlayerControls). La pagina
' mantiene el foco y le pasa las teclas a los controles.
' Antes del capitulo, el anuncio VAST (PrerollAdsTask, con RAF). Pendiente: GA4.
sub Init()
    print "PlayerPage Init "
    m.scene = m.top.GetScene()
    m.theme = m.global.appTheme
    m.video = m.top.findNode("video")
    m.controls = m.top.findNode("controls")
    m.adsTimeout = m.top.findNode("adsTimeout")
    m.adsTimeout.observeField("fire", "OnAdsTimeout")
    m.adsPlaying = false
    m.adsTask = invalid
    m.lError = m.top.findNode("lError")
    m.lError.font = m.global.fonts.dmSansMedium32
    m.lError.color = m.theme.white
    m.cancelled = false
    ' Calidades: [{ value, label, url }] con "auto" (el m3u8 maestro) primero.
    m.qualities = []
    m.currentQuality = "auto"
    m.masterUrl = ""
    m.controls.observeField("action", "OnControlsAction")
    ' Datos del capitulo que van a usar el tracking, "siguiente capitulo", el
    ' panel de episodios y la publicidad (pasos siguientes).
    m.episode = invalid
    m.show = invalid
    m.chapter = invalid
    m.chapters = []
    m.info = invalid
    m.top.observeField("visible", "OnVisibleChange")
    m.video.observeField("state", "OnVideoStateChange")
    m.video.observeField("position", "OnVideoPositionChange")
    m.lastReported = 0
end sub

' ---- Carga del episodio (loadEpisode de PlayerView.tsx) ----

sub OnParamsSet()
    link = getValueFromProps(m.top.params, "link", "")
    live = getValueFromProps(m.top.params, "live", invalid)
    if not isValid(live) AND not isNonEmptyString(link) then return
    ' Otro capitulo en la misma pagina ("A continuacion" o el panel de
    ' episodios, el navigate(ep.link) de la web): se corta el anterior.
    if m.adsPlaying then FinishPreroll()
    if isValid(m.info)
        m.video.control = "stop"
        m.info = invalid
        m.controls.nextVisible = false
        m.controls.episodes = []
        m.controls.callFunc("HideControls")
    end if
    m.nextTriggered = false
    m.nextChapter = invalid
    m.lastPosition = invalid
    m.video.visible = true
    m.liveDaiAssetKey = ""
    m.cancelled = false
    m.lError.visible = false
    ShowLoading(true)
    if isValid(live)
        StartLiveDirect(live)
        return
    end if
    ' 1. Info del episodio por su link
    m.episodeTask = RunTask("ContentAPIAction", "GetEpisodeByLink", { link: link }, "OnEpisodeResponse")
end sub

sub OnEpisodeResponse(event as dynamic)
    if IsStale() then return
    m.episodeTask = invalid
    list = getValueFromProps(event.getData(), "data", [])
    if not isNotEmptyArray(list)
        ShowError("Programa no encontrado")
        return
    end if
    m.episode = list[0]
    print "PlayerPage : episodio encontrado : " getValueFromProps(m.episode, "title", "")
    ' 2. Info del show (programa padre)
    m.showTask = RunTask("ContentAPIAction", "GetProgramBySlug", { slug: Slug() }, "OnShowResponse")
end sub

sub OnShowResponse(event as dynamic)
    if IsStale() then return
    m.showTask = invalid
    list = getValueFromProps(event.getData(), "data", [])
    if not isNotEmptyArray(list)
        ShowError("Show no encontrado")
        return
    end if
    m.show = list[0]
    ' 3. Capitulos de la categoria (la del episodio, o la del link)
    category = getValueFromProps(m.episode, "category", "")
    if not isNonEmptyString(category) then category = LinkCategory()
    m.chaptersTask = RunTask("ContentAPIAction", "GetProgramChapters", { slug: Slug(), category: category }, "OnChaptersResponse")
end sub

sub OnChaptersResponse(event as dynamic)
    if IsStale() then return
    m.chaptersTask = invalid
    list = getValueFromProps(event.getData(), "data.data", [])
    ' La web invierte la lista siempre (a diferencia de la vista de programa,
    ' que solo invierte con on_air = "0").
    m.chapters = []
    if isNotEmptyArray(list)
        for i = list.count() - 1 to 0 step -1
            m.chapters.Push(list[i])
        end for
    end if
    ' 4. El capitulo actual dentro de la categoria
    episodeId = getValueFromProps(m.episode, "id", "")
    m.chapter = invalid
    for each chapter in m.chapters
        if getValueFromProps(chapter, "id", "") = episodeId
            m.chapter = chapter
            exit for
        end if
    end for
    if not isValid(m.chapter)
        ShowError("Episodio no encontrado")
        return
    end if
    print "PlayerPage : capitulo : " getValueFromProps(m.chapter, "title", "") " key : " getValueFromProps(m.chapter, "key", "")
    ' 5. Restricciones
    restriction = getValueFromProps(m.chapter, "restriction", "0")
    if restriction <> "0"
        if m.scene.isUserLoggedIn <> true
            ' navigate("/login")
            ShowLoading(false)
            m.scene.callFunc("ClosePlayerPage")
            m.scene.callFunc("ShowOnboardingPage", false)
            return
        end if
        if ValidateRestriction(restriction, getValueFromProps(m.chapter, "packs", []))
            ' navigate("/suscribe"): SuscribeView todavia no esta portada.
            ShowError("Este contenido requiere una suscripción")
            return
        end if
    end if
    ' 6. URL del video (m3u8) desde rudo
    m.mediaTask = RunTask("ContentAPIAction", "GetVodMediaInfo", { key: getValueFromProps(m.chapter, "key", "") }, "OnMediaInfoResponse")
end sub

' /player/live (LiveDirectPlayerView.tsx), desde una tarjeta de Destacados que
' es una senal en vivo: sin cadena de capitulos, el m3u8 sale de la media info
' de rudo con la key de la tarjeta (firmado si es restringido) y se reproduce en
' modo en vivo (sin barra, sin panel de episodios ni tracking). Si trae
' DPSDAIAssetKey se usa el stream de DAI. Back vuelve al Home.
sub StartLiveDirect(live as object)
    restriction = getValueFromProps(live, "restriction", "0")
    packs = getValueFromProps(live, "packs", [])
    ' FeaturedItem.handleClick: la restriccion se valida antes de abrir
    if isNonEmptyString(restriction) AND restriction <> "0"
        if m.scene.isUserLoggedIn <> true
            ShowLoading(false)
            m.scene.callFunc("ClosePlayerPage")
            m.scene.callFunc("ShowOnboardingPage", false)
            return
        end if
        if restriction = "1" AND ValidateRestriction(restriction, packs)
            ' navigate("/suscribe"): SuscribeView todavia no esta portada.
            ShowError("Este contenido requiere una suscripción")
            return
        end if
    end if
    m.episode = { live_redirect: "1", vast_app: getValueFromProps(live, "vastUrl", ""), show: "" }
    m.show = invalid
    m.chapters = []
    m.chapter = {
        key: getValueFromProps(live, "key", "")
        title: getValueFromProps(live, "title", "")
        restriction: restriction
        packs: packs
        link: ""
        image: ""
    }
    m.liveDaiAssetKey = getValueFromProps(live, "daiAssetKey", "")
    ' La web la cuenta por el cambio de ruta a /player/live (titulo "Live").
    m.scene.callFunc("TrackPage", { path: "/player/live" })
    m.mediaTask = RunTask("ContentAPIAction", "GetVodMediaInfo", { key: m.chapter.key }, "OnMediaInfoResponse")
end sub

sub OnMediaInfoResponse(event as dynamic)
    if IsStale() then return
    m.mediaTask = invalid
    media = getValueFromProps(event.getData(), "data.data", invalid)
    m3u8 = getValueFromProps(media, "m3u8", "")
    if not isNonEmptyString(m3u8)
        ShowError("No se pudo cargar el video")
        return
    end if
    m.mediaUrl = m3u8
    m.mediaDuration = Int(convertToNumber(getValueFromProps(media, "duration", 0)))
    ' 7. Firma del VOD si es restringido. authenticateContent exige suscripcion
    ' activa; si no la hay (o el gateway falla) la web sigue sin firma.
    subscriptionActive = getValueFromProps(GlobalGet("UserData"), "suscription.active", false) = true
    if getValueFromProps(media, "restriction", "0") = "1" AND isNonEmptyString(GlobalGet("token")) AND subscriptionActive
        m.authTask = RunTask("AuthAPIAction", "AuthenticateContent", { type: "vod", id: getValueFromProps(m.chapter, "key", "") }, "OnAuthContentResponse")
    else
        StartPlayback(m.mediaUrl)
    end if
end sub

sub OnAuthContentResponse(event as dynamic)
    if IsStale() then return
    m.authTask = invalid
    data = getValueFromProps(event.getData(), "data.data", {})
    url = m.mediaUrl
    if getValueFromProps(data, "status", "") = "ok"
        token = "st=" + ToText(getValueFromProps(data, "st", "")) + "&ts=" + ToText(getValueFromProps(data, "ts", "")) + "&e=" + ToText(getValueFromProps(data, "e", ""))
        if Instr(1, url, "?") > 0 then url = url + "&" + token else url = url + "?" + token
        print "PlayerPage : VOD autenticado"
    else
        print "PlayerPage : error autenticando VOD : " FormatJson(event.getData())
    end if
    StartPlayback(url)
end sub

' ---- Reproduccion (useHlsPlayer) ----

sub StartPlayback(mediaUrl as string)
    isLive = getValueFromProps(m.episode, "live_redirect", "0") = "1"
    ' description del VideoPlayer: prog.show || show.title
    showTitle = getValueFromProps(m.episode, "show", "")
    if not isNonEmptyString(showTitle) then showTitle = getValueFromProps(m.show, "title", "")
    m.info = {
        key: getValueFromProps(m.chapter, "key", "")
        title: getValueFromProps(m.chapter, "title", "")
        description: showTitle
        image: getValueFromProps(m.chapter, "image", "")
        link: getValueFromProps(m.chapter, "link", "")
        restriction: getValueFromProps(m.chapter, "restriction", "0")
        packs: getValueFromProps(m.chapter, "packs", [])
        vastUrl: getValueFromProps(m.episode, "vast_app", "")
        isLive: isLive
    }
    ' streamUrl de LiveDirectPlayerView: con DPSDAIAssetKey, el stream de DAI.
    if isLive AND isNonEmptyString(m.liveDaiAssetKey)
        mediaUrl = "https://dai.google.com/linear/hls/event/" + m.liveDaiAssetKey + "/master.m3u8"
    end if
    ' La misma sesion DPS va en el video y en la URL del anuncio.
    session = GetDpsSessionParams()
    url = ForceSessionParams(mediaUrl, session)
    ' GA4 a mano, como PlayerView.tsx: trackPage(pathname, titulo del capitulo).
    m.scene.callFunc("TrackPage", { path: getValueFromProps(m.top.params, "link", ""), title: m.info.title })
    print "PlayerPage : URL final : " url
    content = CreateObject("roSGNode", "ContentNode")
    content.url = url
    content.streamFormat = "hls"
    content.title = decodeHtmlEntities(m.info.title)
    initialSeconds = convertToNumber(getValueFromProps(m.top.params, "initialSeconds", 0))
    if isLive
        content.live = true
    else if initialSeconds > 0
        content.playStart = initialSeconds
    end if
    m.lastReported = 0
    m.masterUrl = url
    m.qualities = []
    m.currentQuality = "auto"
    m.controls.title = m.info.title
    m.controls.description = m.info.description
    m.controls.isLive = isLive
    m.controls.qualities = []
    m.controls.currentQuality = "auto"
    ' Panel de episodios: los capitulos de la categoria (sin panel en vivo).
    episodes = []
    if not isLive
        for each chapter in m.chapters
            episodes.Push({ key: getValueFromProps(chapter, "key", ""), title: getValueFromProps(chapter, "title", "") })
        end for
    end if
    m.controls.currentEpisodeKey = m.info.key
    m.controls.episodes = episodes
    m.controls.countdown = 60
    m.nextTriggered = false
    m.pendingContent = content
    if ShouldPlayAds()
        StartPreroll(BuildVastUrl(m.info.vastUrl, session))
    else
        PlayContent()
    end if
end sub

' ---- Publicidad antes del capitulo (use-ads-policy.ts + VastPlayer.tsx) ----

' Sin vast_app no hay anuncio. Con la politica ads_free del feed de
' configuracion: "always" nunca muestra, "never" siempre, "owner" no muestra si
' el usuario tiene acceso al contenido restringido. Sin ads_free (hoy el feed no
' lo trae): con suscripcion activa no hay anuncio.
function ShouldPlayAds() as boolean
    vastUrl = m.info.vastUrl
    if not isNonEmptyString(vastUrl) OR vastUrl.Trim() = "" OR vastUrl = "none" then return false
    user = GlobalGet("UserData")
    policy = getValueFromProps(GlobalGet("homeConfig"), "ads_free", invalid)
    if not isValid(policy) OR type(policy) <> "roAssociativeArray"
        return not (getValueFromProps(user, "suscription.active", false) = true)
    end if
    defaults = getValueFromProps(policy, "default", {})
    userType = getValueFromProps(user, "adsFreeType", "default")
    policyValue = getValueFromProps(defaults, userType, "")
    if not isNonEmptyString(policyValue) then policyValue = getValueFromProps(defaults, "default", "never")
    isAdsFree = false
    if policyValue = "always"
        isAdsFree = true
    else if policyValue = "owner"
        restriction = m.info.restriction
        if isNonEmptyString(restriction) AND restriction <> "0" then isAdsFree = not ValidateRestriction(restriction, m.info.packs)
    end if
    print "PlayerPage : politica de anuncios : " userType " " policyValue " -> sin anuncio=" isAdsFree
    return not isAdsFree
end function

' El capitulo espera mientras se pide y reproduce el anuncio. Si en 15s no
' empezo, sigue con el capitulo (timeout de seguridad del VastPlayer).
sub StartPreroll(adUrl as string)
    print "PlayerPage : anuncio : " adUrl
    ShowLoading(true)
    m.adsPlaying = true
    m.adsTask = CreateObject("roSGNode", "PrerollAdsTask")
    m.adsTask.adUrl = adUrl
    m.adsTask.view = m.top
    m.adsTask.contentId = m.info.key
    if isValid(m.mediaDuration) then m.adsTask.contentLength = m.mediaDuration
    m.adsTask.observeField("status", "OnPrerollStatus")
    m.adsTask.control = "RUN"
    m.adsTimeout.control = "stop"
    m.adsTimeout.control = "start"
end sub

sub OnPrerollStatus()
    if not isValid(m.adsTask) then return
    status = m.adsTask.status
    if status = "playing"
        ' Con anuncio: RAF muestra su propia interfaz y maneja las teclas.
        m.adsTimeout.control = "stop"
        ShowLoading(false)
    else if status = "none" OR status = "done"
        FinishPreroll()
        PlayContent()
    else if status = "exited"
        ' Back durante el anuncio: sale del reproductor, como la web.
        FinishPreroll()
        m.scene.callFunc("ClosePlayerPage")
    end if
end sub

sub OnAdsTimeout()
    if not m.adsPlaying then return
    print "PlayerPage : el anuncio no respondio en 15s, sigue el capitulo"
    FinishPreroll()
    PlayContent()
end sub

sub FinishPreroll()
    m.adsTimeout.control = "stop"
    m.adsPlaying = false
    if isValid(m.adsTask)
        m.adsTask.cancel = true
        m.adsTask.unobserveField("status")
        m.adsTask = invalid
    end if
    ' RAF se queda con el foco mientras reproduce: vuelve a la pagina.
    if m.top.visible then m.top.setFocus(true)
end sub

sub PlayContent()
    if not isValid(m.pendingContent) then return
    content = m.pendingContent
    m.pendingContent = invalid
    ShowLoading(false)
    m.video.content = content
    m.video.control = "play"
    ' La UI arranca visible (isUIVisible = true) y se oculta a los 4s.
    m.controls.callFunc("ShowControls")
    m.qualitiesTask = RunTask("ContentAPIAction", "GetTextByUrl", { url: m.masterUrl }, "OnMasterPlaylistResponse")
end sub

sub OnVideoStateChange()
    state = m.video.state
    print "PlayerPage : state : " state
    if state = "playing"
        ShowLoading(false)
        m.controls.playing = true
        ' resetUIVisibility en cada evento "playing" del video.
        m.controls.callFunc("ShowControls")
    else if state = "buffering"
        ShowLoading(true)
    else if state = "paused" OR state = "stopped" OR state = "finished"
        ShowLoading(false)
        m.controls.playing = false
        ' Al terminar la cuenta llega a 0: pasa al siguiente (handleNativeEnded).
        if state = "finished" AND m.nextTriggered AND isValid(m.nextChapter) then PlayChapter(m.nextChapter)
    else if state = "error"
        print "PlayerPage : error de reproduccion : " m.video.errorCode " " m.video.errorMsg " " m.video.errorStr
        if m.currentQuality <> "auto"
            ' Si una calidad fija no carga, vuelve a Auto en el mismo punto.
            SwitchQuality("auto")
        else
            m.controls.callFunc("HideControls")
            ShowError("No se pudo reproducir el video")
        end if
    end if
end sub

' ---- Controles ----

sub OnControlsAction(event as dynamic)
    action = event.getData()
    kind = getValueFromProps(action, "type", "")
    if kind = "toggle"
        state = m.video.state
        if state = "playing" OR state = "buffering"
            m.video.control = "pause"
        else if state = "paused"
            m.video.control = "resume"
        else
            m.video.control = "play"
        end if
    else if kind = "seek"
        m.video.seek = getValueFromProps(action, "time", 0)
    else if kind = "back"
        ' Boton "volver" de la barra superior: onBack -> /programas/{slug}
        m.scene.callFunc("ClosePlayerPage")
    else if kind = "quality"
        SwitchQuality(getValueFromProps(action, "value", "auto"))
    else if kind = "next"
        if isValid(m.nextChapter) then PlayChapter(m.nextChapter)
    else if kind = "episode"
        index = getValueFromProps(action, "index", -1)
        if index >= 0 AND index < m.chapters.count() then PlayChapter(m.chapters[index])
    end if
end sub

' onEpisodeSelect: navigate(ep.link) -> la misma pagina recarga el capitulo
' (sin initialSeconds). Back sigue volviendo a la vista de programa.
sub PlayChapter(chapter as object)
    link = getValueFromProps(chapter, "link", "")
    if not isNonEmptyString(link) then return
    print "PlayerPage : otro capitulo : " link
    m.top.params = { link: link, slug: Slug(), initialSeconds: 0 }
end sub

' ---- "A continuacion" (VideoPlayer.tsx: a 60s del final, si hay siguiente) ----

sub UpdateNextEpisode(position as float, duration as float)
    if m.info.isLive OR m.chapters.count() = 0 OR duration <= 0 then return
    timeLeft = duration - position
    if timeLeft <= 60 AND timeLeft >= -1
        currentIndex = -1
        for i = 0 to m.chapters.count() - 1
            if getValueFromProps(m.chapters[i], "key", "") = m.info.key then currentIndex = i
        end for
        if currentIndex >= 0 AND currentIndex + 1 < m.chapters.count()
            if not m.nextTriggered
                m.nextTriggered = true
                m.nextChapter = m.chapters[currentIndex + 1]
                m.controls.nextEpisode = {
                    title: getValueFromProps(m.nextChapter, "title", "")
                    image: getValueFromProps(m.nextChapter, "image", "")
                }
                m.controls.nextVisible = true
            end if
            ' Math.max(0, Math.ceil(timeLeft))
            countdown = -Int(-timeLeft)
            if countdown < 0 then countdown = 0
            m.controls.countdown = countdown
            if countdown <= 0 then PlayChapter(m.nextChapter)
        end if
    else if m.nextTriggered AND timeLeft > 60
        ' Volvio atras con la barra: se esconde hasta llegar de nuevo al final.
        m.nextTriggered = false
        m.nextChapter = invalid
        m.controls.nextVisible = false
    end if
end sub

' ---- Calidades (niveles de hls.js: "Auto" + una por altura, mayor arriba) ----

sub OnMasterPlaylistResponse(event as dynamic)
    if IsStale() then return
    m.qualitiesTask = invalid
    response = event.getData()
    if not isValid(response) OR response.ok <> true OR not isNonEmptyString(response.data) then return
    qualities = [{ value: "auto", label: "Auto", url: m.masterUrl }]
    seen = {}
    for each variant in ParseHlsVariants(response.data)
        if variant.height > 0
            value = variant.height.ToStr()
            if not seen.DoesExist(value)
                seen[value] = true
                qualities.Push({ value: value, label: value + "p", url: ResolveHlsUrl(m.masterUrl, variant.url) })
            end if
        end if
    end for
    m.qualities = qualities
    uiQualities = []
    for each q in qualities
        uiQualities.Push({ value: q.value, label: q.label })
    end for
    m.controls.qualities = uiQualities
end sub

' En Roku no se puede fijar un nivel de un HLS ya cargado: se recarga con la
' lista de esa calidad (o el maestro para "Auto") desde la posicion actual.
sub SwitchQuality(value as string)
    target = invalid
    for each q in m.qualities
        if q.value = value then target = q
    end for
    if not isValid(target) OR value = m.currentQuality then return
    position = m.video.position
    if position <= 0 AND isValid(m.lastPosition) then position = m.lastPosition
    m.currentQuality = value
    m.controls.currentQuality = value
    content = CreateObject("roSGNode", "ContentNode")
    content.url = target.url
    content.streamFormat = "hls"
    content.title = decodeHtmlEntities(m.info.title)
    if m.info.isLive
        content.live = true
    else if position > 0
        content.playStart = position
    end if
    print "PlayerPage : calidad " value " desde " position
    m.video.content = content
    m.video.control = "play"
end sub

' ---- Tracking de avance (usePlayerAnalytics) ----

' onPlaybackProgress: un "progress" cada 15s de avance y un "end" a 2s del
' final. Sin tracking en vivo (la web no le pasa rudoKey al hook).
sub OnVideoPositionChange()
    if not isValid(m.info) then return
    position = m.video.position
    duration = m.video.duration
    if position > 0 then m.lastPosition = position
    if duration > 0 then m.controls.duration = duration
    m.controls.position = position
    if m.info.isLive then return
    UpdateNextEpisode(position, duration)
    if not isValid(m.info) then return
    if position <= 0 OR duration <= 0 then return
    rounded = Int(position)
    if rounded - m.lastReported >= 15
        m.lastReported = rounded
        SendTracking("progress", rounded, duration)
    end if
    if duration - position <= 2 AND m.lastReported <> -1
        m.lastReported = -1
        SendTracking("end", duration, duration)
    end if
end sub

' Solo con sesion y perfil elegido. Va por la escena: el ultimo reporte no se
' pierde si el usuario sale justo despues (la web tampoco lo cancela).
sub SendTracking(eventType as string, seconds as float, duration as float)
    profile = getValueFromProps(m.scene.ProfileData, "profileId", "")
    if m.scene.isUserLoggedIn <> true OR not isNonEmptyString(profile) OR not isNonEmptyString(m.info.key) then return
    title = m.info.title
    if not isNonEmptyString(title) then title = m.info.description
    path = m.info.link
    if not isNonEmptyString(path) then path = "/programas/vod/" + m.info.key
    print "PlayerPage : tracking " eventType " : " Int(seconds) "/" Int(duration)
    m.scene.callFunc("RunBackgroundTask", {
        taskType: "AuthAPIAction"
        functionName: "UpdateTracking"
        params: {
            profile: profile
            contentId: m.info.key
            eventType: eventType
            seconds: Int(seconds).ToStr()
            duration: Int(duration).ToStr()
            restriction: m.info.restriction
            title: title
            show: m.info.description
            image: m.info.image
            path: path
        }
    })
end sub

' ---- Ciclo de vida ----

' Back mientras carga o reproduce: se descartan las respuestas pendientes y se
' corta el video (si no, el audio seguia sonando sobre la vista de programa).
sub OnVisibleChange()
    if not m.top.visible
        m.cancelled = true
        if m.adsPlaying then FinishPreroll()
        m.controls.callFunc("HideControls")
        ShowLoading(false)
        m.video.control = "stop"
    end if
end sub

' Back sube siempre a MainScene.HandleBackKey (vuelve a la vista de programa,
' como el keydown de VideoPlayer.tsx); el resto lo manejan los controles. Sin
' sidebar: ninguna tecla sale del reproductor.
function onKeyEvent(key as string, press as boolean) as boolean
    ' Con el anuncio en pantalla las teclas son de RAF (back lo maneja RAF: sale).
    ' Mientras se pide, back sigue saliendo del reproductor; el resto se ignora.
    if m.adsPlaying
        if key = "back" AND isValid(m.adsTask) AND m.adsTask.status <> "playing" then return false
        return true
    end if
    if key = "back" then return false
    if not press
        ' Soltar una flecha mantenida aplica el salto de la barra.
        if isValid(m.info) then m.controls.callFunc("HandleKeyRelease", key)
        return true
    end if
    if m.lError.visible OR not isValid(m.info) then return true
    m.controls.callFunc("HandleKey", key)
    return true
end function

' ---- Helpers ----

function Slug() as string
    return getValueFromProps(m.top.params, "slug", "")
end function

' /programas/{slug}/{categoria}/{capitulo} -> categoria (el useParams de la web).
function LinkCategory() as string
    parts = getValueFromProps(m.top.params, "link", "").Split("/")
    if parts.count() > 3 then return parts[3].DecodeUriComponent()
    return ""
end function

function RunTask(taskType as string, functionName as string, params as dynamic, callback as string) as object
    task = CreateObject("roSGNode", taskType)
    task.functionName = functionName
    if isValid(params) then task.params = params
    task.ObserveField("result", callback)
    task.control = "RUN"
    return task
end function

function IsStale() as boolean
    return m.cancelled = true
end function

sub ShowLoading(flag as boolean)
    m.scene.callFunc("ShowHideLoader", flag)
end sub

sub ShowError(message as string)
    print "PlayerPage : " message
    ShowLoading(false)
    m.video.control = "stop"
    m.video.visible = false
    m.lError.text = message
    m.lError.visible = true
end sub

' st/ts/e pueden venir como texto o como numero.
function ToText(value as dynamic) as string
    if value = invalid then return ""
    if GetInterface(value, "ifString") <> invalid then return value
    if GetInterface(value, "ifToStr") <> invalid then return value.ToStr()
    return ""
end function
