' Controles del reproductor (PlayerTopBar + Seekbar + PlayerControls /
' PlayerControlsLive + EpisodeSidebar + NextEpisodeOverlay de c13_reloaded).
' Foco virtual: m.focusArea = "seek" | "buttons" | "back" | "menu" | "episodes" |
' "next" y m.buttonIndex dentro de la fila.
sub Init()
    m.fonts = m.global.fonts
    m.theme = m.global.appTheme
    m.orange = "#FF3C00"
    m.gOverlay = m.top.findNode("gOverlay")
    m.bBack = m.top.findNode("bBack")
    m.lTitle = m.top.findNode("lTitle")
    m.lDescription = m.top.findNode("lDescription")
    m.gSeek = m.top.findNode("gSeek")
    m.pTrack = m.top.findNode("pTrack")
    m.pProgress = m.top.findNode("pProgress")
    m.pThumb = m.top.findNode("pThumb")
    m.lCurrent = m.top.findNode("lCurrent")
    m.lTotal = m.top.findNode("lTotal")
    m.gButtons = m.top.findNode("gButtons")
    m.bRestart = m.top.findNode("bRestart")
    m.bPlay = m.top.findNode("bPlay")
    m.bQuality = m.top.findNode("bQuality")
    m.lQualityText = m.top.findNode("lQualityText")
    m.lQualityValue = m.top.findNode("lQualityValue")
    m.gQualityMenu = m.top.findNode("gQualityMenu")
    m.rMenuBorder = m.top.findNode("rMenuBorder")
    m.rMenuBg = m.top.findNode("rMenuBg")
    m.rMenuFocus = m.top.findNode("rMenuFocus")
    m.gMenuOptions = m.top.findNode("gMenuOptions")
    m.hideTimer = m.top.findNode("hideTimer")
    m.seekTimer = m.top.findNode("seekTimer")
    m.fadeIn = m.top.findNode("fadeIn")
    m.fadeOut = m.top.findNode("fadeOut")

    m.lTitle.font = m.fonts.dmSansBold40
    m.lTitle.color = m.theme.white
    m.lDescription.font = m.fonts.dmSansMedium24
    m.lDescription.color = m.theme.white
    m.lCurrent.font = m.fonts.dmSansBold20
    m.lCurrent.color = m.theme.white
    m.lTotal.font = m.fonts.dmSansBold20
    m.lTotal.color = m.theme.white
    m.lQualityText.font = m.fonts.dmSansBold20
    m.lQualityValue.font = m.fonts.dmSansBold20

    m.trackWidth = 1810
    m.menuOptionHeight = 44
    m.focusArea = "seek"
    m.buttonIndex = 0
    m.menuIndex = 0
    ' Seekbar: posicion mostrada, salto acelerado y sincronizacion con el video.
    m.clock = CreateObject("roTimespan")
    m.displayPosition = 0
    m.isSeeking = false
    m.consecutiveSeeks = 0
    m.lastSeekMs = -1000
    m.lastTarget = invalid
    m.lastTargetMs = 0

    ' Flecha mantenida sobre la barra: la perilla avanza sola con holdTimer y el
    ' salto recien se aplica al soltar (si se aplicara a mitad de camino, el
    ' video se pone a cargar y la perilla se detiene).
    m.holdTimer = m.top.findNode("holdTimer")
    m.heldKey = ""
    m.holdTicks = 0

    ' Panel de capitulos (EpisodeSidebar)
    m.bEpisodes = m.top.findNode("bEpisodes")
    m.rSidebarDim = m.top.findNode("rSidebarDim")
    m.gSidebar = m.top.findNode("gSidebar")
    m.gEpisodeList = m.top.findNode("gEpisodeList")
    m.sidebarAnimation = m.top.findNode("sidebarAnimation")
    m.sidebarInterpolator = m.top.findNode("sidebarInterpolator")
    m.listAnimation = m.top.findNode("listAnimation")
    m.listInterpolator = m.top.findNode("listInterpolator")
    m.sidebarOpen = false
    m.episodeIndex = 0
    ' [{ node, top, height }] de cada item del panel
    m.episodeItems = []
    ' 500px de ancho con padding lateral de 16px
    m.sidebarX = 1920 - 500 + 16

    ' Tarjeta "A continuacion" (NextEpisodeOverlay)
    m.gNext = m.top.findNode("gNext")
    m.gNextCard = m.top.findNode("gNextCard")
    m.pNextImage = m.top.findNode("pNextImage")
    m.pNextBorder = m.top.findNode("pNextBorder")
    m.lNextHeader = m.top.findNode("lNextHeader")
    m.lNextCountdown = m.top.findNode("lNextCountdown")
    m.lNextTitle = m.top.findNode("lNextTitle")
    m.nextFadeIn = m.top.findNode("nextFadeIn")
    m.nextMove = m.top.findNode("nextMove")
    m.nextMoveInterpolator = m.top.findNode("nextMoveInterpolator")
    m.lNextHeader.font = m.fonts.dmSansBold20
    m.lNextTitle.font = m.fonts.dmSansBold20
    m.lNextTitle.color = m.theme.white
    m.lNextCountdown.font = m.fonts.dmSansBold18
    m.lNextCountdown.color = m.theme.white
    ' right 4vw; bottom 12vw con controles, 4vw sin ellos (tarjeta de 235px)
    m.nextX = 1920 - 77 - 614
    m.nextYShown = 1080 - 230 - 235
    m.nextYHidden = 1080 - 77 - 235

    m.hideTimer.observeField("fire", "OnHideTimer")
    m.seekTimer.observeField("fire", "OnSeekTimer")
    m.holdTimer.observeField("fire", "OnHoldTimer")
    OnLiveChange()
    OnQualitiesChange()
    RenderSeekbar()
end sub

' ---- Visibilidad (resetUIVisibility de VideoPlayer.tsx) ----

' Muestra los controles y reinicia los 4s. Al aparecer, el foco va a la barra
' (en vivo, a play/pausa), como el setFocus de PlayerControls al hacerse visible.
sub ShowControls()
    if not m.top.shown
        m.top.shown = true
        m.fadeOut.control = "stop"
        m.fadeIn.control = "start"
        CloseMenu()
        if m.top.isLive
            SetFocusArea("buttons", ButtonIndexOf("play"))
        else
            SetFocusArea("seek", 0)
        end if
        MoveNextCard()
    end if
    ' Con el panel de capitulos abierto los controles no se ocultan solos.
    m.hideTimer.control = "stop"
    if not m.sidebarOpen then m.hideTimer.control = "start"
end sub

sub HideControls()
    m.hideTimer.control = "stop"
    StopHold()
    if not m.top.shown then return
    m.top.shown = false
    CloseMenu()
    CloseSidebar(false)
    ' Sin controles, el foco queda en la tarjeta "A continuacion" si esta visible.
    if m.top.nextVisible then m.focusArea = "next"
    RenderFocus()
    MoveNextCard()
    m.fadeIn.control = "stop"
    m.fadeOut.control = "start"
end sub

sub OnHideTimer()
    HideControls()
end sub

' ---- Teclas ----

function HandleKey(key as string) as boolean
    if key = "back" then return false
    ' Repeticion del control remoto con la tecla ya mantenida: la maneja holdTimer.
    if key = m.heldKey then return true
    if not m.top.shown
        ' Con la tarjeta "A continuacion" enfocada, OK pasa al siguiente capitulo.
        if key = "OK" AND m.top.nextVisible
            EmitAction({ type: "next" })
            return true
        end if
        ' Con los controles ocultos, OK pausa/reanuda (no en vivo); cualquier
        ' otra tecla solo los muestra.
        if (key = "OK" AND not m.top.isLive) OR key = "play" then EmitAction({ type: "toggle" })
        ShowControls()
        return true
    end if
    ShowControls()
    if key = "play"
        EmitAction({ type: "toggle" })
        return true
    end if
    ' Extra de Roku: adelantar/retroceder del control remoto mueven la barra.
    if (key = "fastforward" OR key = "rewind") AND not m.top.isLive
        CloseMenu()
        CloseSidebar(true)
        SetFocusArea("seek", 0)
        if key = "fastforward" then Seek("right") else Seek("left")
        StartHold(key)
        return true
    end if
    if m.focusArea = "seek" then return HandleSeekKey(key)
    if m.focusArea = "buttons" then return HandleButtonsKey(key)
    if m.focusArea = "back" then return HandleBackButtonKey(key)
    if m.focusArea = "menu" then return HandleMenuKey(key)
    if m.focusArea = "episodes" then return HandleEpisodesKey(key)
    if m.focusArea = "next" then return HandleNextKey(key)
    return true
end function

' Tarjeta "A continuacion": arriba -> volver, abajo -> reiniciar, OK -> siguiente;
' izquierda/derecha bloqueadas.
function HandleNextKey(key as string) as boolean
    if key = "up"
        SetFocusArea("back", 0)
    else if key = "down"
        SetFocusArea("buttons", 0)
    else if key = "OK"
        EmitAction({ type: "next" })
    end if
    return true
end function

function HandleSeekKey(key as string) as boolean
    if key = "up"
        SetFocusArea("buttons", 0)
    else if key = "down"
        HideControls()
    else if key = "left" OR key = "right"
        Seek(key)
        StartHold(key)
    else if key = "OK"
        EmitAction({ type: "toggle" })
    end if
    return true
end function

' Soltar la flecha mantenida: el salto se aplica 600ms despues (si el usuario
' vuelve a tocar antes, se sigue sumando).
function HandleKeyRelease(key as string) as boolean
    if key <> "" AND key = m.heldKey
        StopHold()
        if m.isSeeking
            m.seekTimer.control = "stop"
            m.seekTimer.control = "start"
        end if
    end if
    return true
end function

sub StartHold(key as string)
    m.heldKey = key
    m.holdTicks = 0
    m.seekTimer.control = "stop"
    m.holdTimer.control = "stop"
    m.holdTimer.control = "start"
end sub

sub StopHold()
    m.holdTimer.control = "stop"
    m.heldKey = ""
end sub

' Cada 0.2s mientras la tecla sigue apretada (tras 0.4s de espera, como la
' repeticion de un teclado): el mismo salto acelerado de la web.
sub OnHoldTimer()
    if m.heldKey = "" then return
    m.holdTicks = m.holdTicks + 1
    if m.holdTicks <= 2 then return
    ShowControls()
    if m.heldKey = "right" OR m.heldKey = "fastforward" then Seek("right") else Seek("left")
end sub

function HandleButtonsKey(key as string) as boolean
    buttons = ButtonIds()
    if key = "left"
        if m.buttonIndex > 0 then SetFocusArea("buttons", m.buttonIndex - 1)
    else if key = "right"
        if m.buttonIndex < buttons.count() - 1 then SetFocusArea("buttons", m.buttonIndex + 1)
    else if key = "up"
        if m.top.nextVisible then SetFocusArea("next", 0) else SetFocusArea("back", 0)
    else if key = "down"
        if m.top.isLive then HideControls() else SetFocusArea("seek", 0)
    else if key = "OK"
        id = buttons[m.buttonIndex]
        if id = "restart"
            m.displayPosition = 0
            ApplySeek(0)
        else if id = "play"
            EmitAction({ type: "toggle" })
        else if id = "episodes"
            OpenSidebar()
        else if id = "quality"
            OpenMenu()
        end if
    end if
    return true
end function

function HandleBackButtonKey(key as string) as boolean
    if key = "down"
        if m.top.nextVisible then SetFocusArea("next", 0) else SetFocusArea("buttons", 0)
    else if key = "right"
        SetFocusArea("buttons", 0)
    else if key = "OK"
        EmitAction({ type: "back" })
    end if
    return true
end function

function HandleMenuKey(key as string) as boolean
    qualities = QualityList()
    if key = "up"
        if m.menuIndex > 0 then m.menuIndex = m.menuIndex - 1
        RenderMenuFocus()
    else if key = "down"
        if m.menuIndex < qualities.count() - 1 then m.menuIndex = m.menuIndex + 1
        RenderMenuFocus()
    else if key = "left" OR key = "right"
        CloseMenu()
        SetFocusArea("buttons", ButtonIndexOf("quality"))
    else if key = "OK"
        EmitAction({ type: "quality", value: qualities[m.menuIndex].value })
        CloseMenu()
        SetFocusArea("buttons", ButtonIndexOf("quality"))
    end if
    return true
end function

' ---- Seekbar ----

' Salto dinamico de 15s a 300s: cada toque a menos de 400ms del anterior suma
' 15s; el salto se aplica 600ms despues del ultimo toque.
sub Seek(direction as string)
    duration = m.top.duration
    if duration <= 0 then return
    now = m.clock.TotalMilliseconds()
    if now - m.lastSeekMs < 400
        m.consecutiveSeeks = m.consecutiveSeeks + 1
    else
        m.consecutiveSeeks = 0
    end if
    m.lastSeekMs = now
    stepSeconds = 15 + m.consecutiveSeeks * 15
    if stepSeconds > 300 then stepSeconds = 300
    m.isSeeking = true
    m.lastTarget = invalid
    if direction = "left"
        m.displayPosition = m.displayPosition - stepSeconds
        if m.displayPosition < 0 then m.displayPosition = 0
    else
        m.displayPosition = m.displayPosition + stepSeconds
        if m.displayPosition > duration then m.displayPosition = duration
    end if
    RenderSeekbar()
    m.seekTimer.control = "stop"
    ' Con la tecla mantenida no se aplica: se espera a que la suelte.
    if m.heldKey = "" then m.seekTimer.control = "start"
end sub

sub OnSeekTimer()
    ApplySeek(m.displayPosition)
end sub

' applySeek: durante 2s (o hasta que el video llegue a menos de 5s del destino)
' la barra no vuelve a la posicion vieja mientras el video termina de saltar.
sub ApplySeek(target as float)
    m.consecutiveSeeks = 0
    m.isSeeking = false
    m.lastTarget = target
    m.lastTargetMs = m.clock.TotalMilliseconds()
    RenderSeekbar()
    EmitAction({ type: "seek", time: target })
end sub

sub OnProgressChange()
    if not m.isSeeking
        position = m.top.position
        if isValid(m.lastTarget)
            if Abs(position - m.lastTarget) < 5 OR m.clock.TotalMilliseconds() - m.lastTargetMs > 2000
                m.lastTarget = invalid
                m.displayPosition = position
            end if
        else
            m.displayPosition = position
        end if
    end if
    RenderSeekbar()
end sub

sub RenderSeekbar()
    duration = m.top.duration
    ratio = 0
    if duration > 0 then ratio = m.displayPosition / duration
    if ratio < 0 then ratio = 0
    if ratio > 1 then ratio = 1
    x = Int(m.trackWidth * ratio)
    ' El 9-patch de la barra necesita al menos sus dos extremos redondos (12px).
    m.pProgress.visible = x >= 12
    if x >= 12 then m.pProgress.width = x
    focused = m.focusArea = "seek"
    if focused
        m.pThumb.uri = "pkg:/images/player/thumb_focus.png"
        m.pThumb.width = 38
        m.pThumb.height = 38
        m.pThumb.translation = [x - 19, -13]
    else
        m.pThumb.uri = "pkg:/images/player/thumb.png"
        m.pThumb.width = 30
        m.pThumb.height = 30
        m.pThumb.translation = [x - 15, -9]
    end if
    m.lCurrent.text = FormatSeekTime(m.displayPosition)
    m.lTotal.text = FormatSeekTime(duration)
end sub

' formatTime del Seekbar: HH:MM:SS si hay horas, si no MM:SS.
function FormatSeekTime(value as float) as string
    if value <= 0 then return "00:00"
    total = Int(value)
    h = Int(total / 3600)
    mm = Int((total MOD 3600) / 60)
    s = total MOD 60
    text = Pad2(mm) + ":" + Pad2(s)
    if h > 0 then text = Pad2(h) + ":" + text
    return text
end function

function Pad2(value as integer) as string
    text = value.ToStr()
    if value < 10 then text = "0" + text
    return text
end function

' ---- Botones ----

function ButtonIds() as object
    if m.top.isLive then return ["play", "quality"]
    if EpisodeList().count() > 0 then return ["restart", "play", "episodes", "quality"]
    return ["restart", "play", "quality"]
end function

function ButtonIndexOf(id as string) as integer
    buttons = ButtonIds()
    for i = 0 to buttons.count() - 1
        if buttons[i] = id then return i
    end for
    return 0
end function

function ButtonNode(id as string) as object
    if id = "restart" then return m.bRestart
    if id = "play" then return m.bPlay
    if id = "episodes" then return m.bEpisodes
    return m.bQuality
end function

sub OnLiveChange()
    isLive = m.top.isLive
    m.gSeek.visible = not isLive
    m.bRestart.visible = not isLive
    LayoutButtons()
    RenderFocus()
end sub

sub OnPlayingChange()
    icon = m.bPlay.getChild(2)
    if m.top.playing
        icon.uri = "pkg:/images/player/icon_pause.png"
    else
        icon.uri = "pkg:/images/player/icon_play.png"
    end if
end sub

sub OnTextChange()
    m.lTitle.text = decodeHtmlEntities(m.top.title)
    m.lDescription.text = decodeHtmlEntities(m.top.description)
    m.lDescription.visible = isNonEmptyString(m.top.description)
end sub

' Pildora "Calidad": padding 20 + icono 26 + gap 8 + "Calidad" + gap 8 +
' margen 10 + valor + padding 20 (+ bordes de 2px).
sub LayoutButtons()
    textW = MeasureText(m.lQualityText, 7)
    valueW = MeasureText(m.lQualityValue, 4)
    m.lQualityText.translation = [22 + 26 + 8, 0]
    m.lQualityValue.translation = [22 + 26 + 8 + textW + 18, 0]
    qualityW = 22 + 26 + 8 + textW + 18 + valueW + 22
    m.bQuality.getChild(1).width = qualityW
    m.bQuality.getChild(0).width = qualityW
    m.qualityWidth = qualityW
    ' De derecha a izquierda desde right: 55px.
    bottom = 140
    if m.top.isLive then bottom = 80
    y = 1080 - bottom - 56
    x = 1920 - 55 - qualityW
    m.bQuality.translation = [x, y]
    hasEpisodes = not m.top.isLive AND EpisodeList().count() > 0
    m.bEpisodes.visible = hasEpisodes
    if hasEpisodes
        x = x - 22 - 56
        m.bEpisodes.translation = [x, y]
    end if
    x = x - 22 - 56
    m.bPlay.translation = [x, y]
    x = x - 22 - 56
    m.bRestart.translation = [x, y]
end sub

' Ancho real del texto (boundingRect de un Label sin ancho); si el motor no
' mide fuentes, se estima por cantidad de caracteres.
function MeasureText(label as object, charCount as integer) as integer
    label.width = 0
    w = label.boundingRect().width
    if w <= 0 then w = Len(label.text) * 12
    if w <= 0 then w = charCount * 12
    return Int(w)
end function

sub SetFocusArea(area as string, index as integer)
    m.focusArea = area
    m.buttonIndex = index
    RenderFocus()
    RenderSeekbar()
end sub

sub RenderFocus()
    SetButtonFocus(m.bBack, m.focusArea = "back")
    for each id in ["restart", "play", "episodes", "quality"]
        SetButtonFocus(ButtonNode(id), false)
    end for
    buttons = ButtonIds()
    focusedId = ""
    if m.focusArea = "buttons" AND m.buttonIndex < buttons.count() then focusedId = buttons[m.buttonIndex]
    ' Con la lista de calidades o el panel abiertos, su boton sigue marcado.
    if m.focusArea = "menu" then focusedId = "quality"
    if m.focusArea = "episodes" then focusedId = "episodes"
    if focusedId <> "" then SetButtonFocus(ButtonNode(focusedId), true)
    m.lQualityText.color = m.theme.white
    if focusedId = "quality" then m.lQualityText.color = m.orange
    ' Tarjeta "A continuacion": borde naranjo y scale(1.05) con foco.
    nextFocused = m.top.nextVisible AND m.focusArea = "next"
    m.pNextBorder.visible = nextFocused
    if nextFocused then m.gNextCard.scale = [1.05, 1.05] else m.gNextCard.scale = [1, 1]
end sub

' Borde blanco al 60% sin foco; naranjo + relleno blanco al 10% con foco.
sub SetButtonFocus(button as object, focused as boolean)
    ring = button.getChild(1)
    fill = button.getChild(0)
    fill.visible = focused
    if focused
        ring.blendColor = m.orange
        ring.opacity = 1
    else
        ring.blendColor = "#FFFFFF"
        ring.opacity = 0.6
    end if
end sub

' ---- Calidad ----

function QualityList() as object
    list = m.top.qualities
    if not isNotEmptyArray(list) then return []
    return list
end function

sub OnQualitiesChange()
    label = "Auto"
    for each q in QualityList()
        if q.value = m.top.currentQuality then label = q.label
    end for
    m.lQualityValue.text = label
    LayoutButtons()
end sub

sub OpenMenu()
    qualities = QualityList()
    if qualities.count() = 0 then return
    m.gMenuOptions.removeChildrenIndex(m.gMenuOptions.getChildCount(), 0)
    widest = 0
    labels = []
    for each q in qualities
        label = CreateObject("roSGNode", "Label")
        label.font = m.fonts.dmSansMedium23
        label.color = m.theme.white
        label.text = q.label
        w = MeasureText(label, Len(q.label))
        if w > widest then widest = w
        labels.Push(label)
    end for
    ' padding 8px 16px, min-width 120, borde 1px
    width = widest + 32 + 2
    if width < 120 then width = 120
    height = qualities.count() * m.menuOptionHeight + 2
    for i = 0 to labels.count() - 1
        labels[i].width = width - 34
        labels[i].height = m.menuOptionHeight
        labels[i].vertAlign = "center"
        labels[i].translation = [17, 1 + i * m.menuOptionHeight]
        m.gMenuOptions.appendChild(labels[i])
    end for
    m.rMenuBorder.width = width
    m.rMenuBorder.height = height
    m.rMenuBg.width = width - 2
    m.rMenuBg.height = height - 2
    m.rMenuFocus.width = width - 2
    m.rMenuFocus.height = m.menuOptionHeight
    ' bottom: 100% + margin-bottom 8px, right: 0 (alineada con la pildora)
    quality = m.bQuality.translation
    m.gQualityMenu.translation = [quality[0] + m.qualityWidth - width, quality[1] - 8 - height]
    m.menuIndex = 0
    m.gQualityMenu.visible = true
    m.focusArea = "menu"
    RenderMenuFocus()
    RenderFocus()
end sub

sub RenderMenuFocus()
    m.rMenuFocus.translation = [1, 1 + m.menuIndex * m.menuOptionHeight]
end sub

sub CloseMenu()
    m.gQualityMenu.visible = false
    if m.focusArea = "menu" then m.focusArea = "buttons"
end sub

sub EmitAction(action as object)
    m.top.action = action
end sub

' ---- Panel de capitulos (EpisodeSidebar) ----

function EpisodeList() as object
    list = m.top.episodes
    if not isNotEmptyArray(list) then return []
    return list
end function

' Un item por capitulo: padding 12px 16px, columna de 24px con el triangulo de
' play (solo con foco), gap 12 y el titulo en negrita de 1.8rem (naranjo si es
' el que se esta viendo). Items de alto variable, separados 4px.
sub OnEpisodesChange()
    m.gEpisodeList.removeChildrenIndex(m.gEpisodeList.getChildCount(), 0)
    m.episodeItems = []
    top = 0
    currentKey = m.top.currentEpisodeKey
    for each episode in EpisodeList()
        item = CreateObject("roSGNode", "Group")
        fill = CreateObject("roSGNode", "Poster")
        fill.uri = "pkg:/images/player/item_fill.9.png"
        fill.width = 468
        fill.opacity = 0.1
        fill.visible = false
        triangle = CreateObject("roSGNode", "Poster")
        triangle.uri = "pkg:/images/player/icon_triangle.png"
        triangle.width = 20
        triangle.height = 20
        triangle.visible = false
        title = CreateObject("roSGNode", "Label")
        title.font = m.fonts.dmSansBold28
        title.width = 400
        title.wrap = true
        title.maxLines = 3
        title.text = decodeHtmlEntities(getValueFromProps(episode, "title", ""))
        if getValueFromProps(episode, "key", "") = currentKey then title.color = m.orange else title.color = m.theme.white
        textHeight = title.boundingRect().height
        if textHeight <= 0 then textHeight = 37
        height = textHeight + 24
        fill.height = height
        triangle.translation = [18, Int((height - 20) / 2)]
        title.translation = [52, 12]
        item.appendChildren([fill, triangle, title])
        item.translation = [0, top]
        m.gEpisodeList.appendChild(item)
        m.episodeItems.Push({ node: item, top: top, height: height })
        top = top + height + 4
    end for
    LayoutButtons()
    RenderFocus()
end sub

' Se abre con el foco en el capitulo actual, centrado en la pantalla.
sub OpenSidebar()
    if m.episodeItems.count() = 0 then return
    m.episodeIndex = 0
    list = EpisodeList()
    for i = 0 to list.count() - 1
        if getValueFromProps(list[i], "key", "") = m.top.currentEpisodeKey then m.episodeIndex = i
    end for
    m.sidebarOpen = true
    m.hideTimer.control = "stop"
    m.rSidebarDim.visible = true
    m.gSidebar.visible = true
    m.sidebarAnimation.control = "stop"
    m.sidebarInterpolator.keyValue = [[1920 + 16, 0], [m.sidebarX, 0]]
    m.sidebarAnimation.control = "start"
    m.focusArea = "episodes"
    ScrollToEpisode(false)
    RenderEpisodeFocus()
    RenderFocus()
end sub

sub CloseSidebar(restartTimer as boolean)
    if not m.sidebarOpen then return
    m.sidebarOpen = false
    m.sidebarAnimation.control = "stop"
    m.rSidebarDim.visible = false
    m.gSidebar.visible = false
    m.gSidebar.translation = [1920 + 16, 0]
    if m.focusArea = "episodes" then m.focusArea = "buttons"
    if restartTimer
        m.hideTimer.control = "stop"
        m.hideTimer.control = "start"
    end if
end sub

' Arriba/abajo recorren la lista; izquierda cierra todo (panel y controles);
' derecha vuelve al boton "Episodios"; OK en otro capitulo lo reproduce y en
' el actual cierra todo.
function HandleEpisodesKey(key as string) as boolean
    count = m.episodeItems.count()
    if key = "up"
        if m.episodeIndex > 0
            m.episodeIndex = m.episodeIndex - 1
            ScrollToEpisode(true)
            RenderEpisodeFocus()
        end if
    else if key = "down"
        if m.episodeIndex < count - 1
            m.episodeIndex = m.episodeIndex + 1
            ScrollToEpisode(true)
            RenderEpisodeFocus()
        end if
    else if key = "left"
        CloseSidebar(false)
        HideControls()
    else if key = "right"
        CloseSidebar(true)
        SetFocusArea("buttons", ButtonIndexOf("episodes"))
    else if key = "OK"
        episode = EpisodeList()[m.episodeIndex]
        if getValueFromProps(episode, "key", "") <> m.top.currentEpisodeKey
            CloseSidebar(false)
            EmitAction({ type: "episode", index: m.episodeIndex })
        else
            CloseSidebar(false)
            HideControls()
        end if
    end if
    return true
end function

sub RenderEpisodeFocus()
    for i = 0 to m.episodeItems.count() - 1
        node = m.episodeItems[i].node
        focused = m.sidebarOpen AND i = m.episodeIndex
        node.getChild(0).visible = focused
        node.getChild(1).visible = focused
    end for
end sub

' scrollIntoView({ block: "center" }): el item enfocado queda centrado.
sub ScrollToEpisode(animated as boolean)
    if m.episodeIndex >= m.episodeItems.count() then return
    item = m.episodeItems[m.episodeIndex]
    target = [0, Int(540 - (item.top + item.height / 2))]
    m.listAnimation.control = "stop"
    if animated
        m.listInterpolator.keyValue = [m.gEpisodeList.translation, target]
        m.listAnimation.control = "start"
    else
        m.gEpisodeList.translation = target
    end if
end sub

' ---- Tarjeta "A continuacion" (NextEpisodeOverlay) ----

sub OnNextEpisodeChange()
    episode = m.top.nextEpisode
    m.pNextImage.uri = getValueFromProps(episode, "image", "")
    m.lNextTitle.text = decodeHtmlEntities(getValueFromProps(episode, "title", ""))
end sub

sub OnCountdownChange()
    countdown = m.top.countdown
    m.lNextCountdown.visible = countdown > 0
    m.lNextCountdown.text = "En " + countdown.ToStr() + " segundos"
end sub

sub OnNextVisibleChange()
    if m.top.nextVisible
        m.gNext.visible = true
        m.gNext.opacity = 0
        m.gNext.translation = [m.nextX, NextCardY()]
        m.nextFadeIn.control = "start"
        ' Sin controles, la tarjeta toma el foco (useEffect de NextEpisodeOverlay).
        if not m.top.shown then m.focusArea = "next"
    else
        m.nextFadeIn.control = "stop"
        m.gNext.visible = false
        if m.focusArea = "next"
            if m.top.shown then m.focusArea = "buttons" else m.focusArea = "seek"
            m.buttonIndex = 0
        end if
    end if
    RenderFocus()
end sub

function NextCardY() as integer
    if m.top.shown then return m.nextYShown
    return m.nextYHidden
end function

' transition: bottom 0.3s — sube cuando aparecen los controles.
sub MoveNextCard()
    if not m.top.nextVisible then return
    m.nextMove.control = "stop"
    m.nextMoveInterpolator.keyValue = [m.gNext.translation, [m.nextX, NextCardY()]]
    m.nextMove.control = "start"
end sub
