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
    m.radios = []
    m.cardNodes = []
    m.currentIndex = 0
    m.focusIndex = 0
    m.focusArea = "player"
    m.isPlaying = false
    m.isLoading = false
    m.radiosLoaded = false
end sub

sub setControls()
    m.pPlayerBg = m.top.findNode("pPlayerBg")
    m.gPlayer = m.top.findNode("gPlayer")
    m.pPlayerLogoBg = m.top.findNode("pPlayerLogoBg")
    m.pPlayerLogo = m.top.findNode("pPlayerLogo")
    m.lLive = m.top.findNode("lLive")
    m.lRadioName = m.top.findNode("lRadioName")
    m.pPlayPause = m.top.findNode("pPlayPause")
    m.bsLoading = m.top.findNode("bsLoading")
    m.pPlayerFocusBorder = m.top.findNode("pPlayerFocusBorder")
    m.lTitle = m.top.findNode("lTitle")
    m.gCardsTrack = m.top.findNode("gCardsTrack")
    m.audio = m.top.findNode("audio")
end sub

sub setupFonts()
    m.lLive.font = m.fonts.dmSansMedium18
    m.lRadioName.font = m.fonts.dmSansBold30
    m.lTitle.font = m.fonts.dmSansBold32
end sub

sub setupColors()
    m.lLive.color = "#8c8c8c"
    m.lRadioName.color = m.theme.black
    m.lTitle.color = m.theme.white
    m.pPlayPause.blendColor = m.theme.black
    m.pPlayerFocusBorder.blendColor = "#ff3c00"
    m.pPlayerLogoBg.blendColor = "#1c1d28"
end sub

sub setObservers()
    m.top.observeField("focusedChild", "onFocusedChild")
    m.top.observeField("visible", "onVisibleChange")
    m.pPlayerBg.observeField("loadStatus", "onPlayerBgLoadStatus")
    m.audio.observeField("state", "onAudioStateChanged")
end sub

sub initialize()
    m.pPlayerBg.uri = "pkg:/images/radio/radio_fondo.jpg"
    m.pPlayPause.uri = "pkg:/images/PlayerOverlayIcon/play.png"
    getRadios()
end sub

sub onPlayerBgLoadStatus(event as dynamic)
    status = event.GetData()
    node = event.getRoSGNode()
    if status = "ready"
        if node.bitmapHeight > 0
            newWidth = node.bitmapWidth * (648 / node.bitmapHeight)
            node.width = newWidth
            node.loadWidth = newWidth
            node.translation = [1920 - newWidth, 0]
        end if
    end if
end sub

sub getRadios()
    m.getRadiosTask = CreateObject("roSGNode", "ContentAPIAction")
    m.getRadiosTask.functionName = "GetJsonByUrl"
    m.getRadiosTask.params = { "url": m.global.apiEndPoints.GetRadios }
    m.getRadiosTask.observeField("result", "OnGetRadiosAPIResponse")
    m.getRadiosTask.control = "RUN"
end sub

sub OnGetRadiosAPIResponse(event as dynamic)
    apiResponse = event.getData()
    rawItems = getValueFromProps(apiResponse, "data", [])
    m.radios = []
    for each raw in rawItems
        if isNonEmptyString(raw.name) AND isNonEmptyString(raw.liveUrl)
            m.radios.push({
                "name": raw.name
                "image": ResolveRadioImage(raw.image)
                "color": raw.color
                "liveUrl": raw.liveUrl
            })
        end if
    end for
    m.getRadiosTask = invalid
    if m.radios.count() > 0
        buildCards()
        setCurrentRadio(0, true)
        m.radiosLoaded = true
        setFocusToPlayer()
    end if
end sub

' Los logos del CDN son 1921x1081; escalarlos en el Roku a 192px da pixelado.
' Si hay una version ya redimensionada en el paquete (images/radio/<archivo>),
' se usa esa; si no, se cae al URL remoto.
function ResolveRadioImage(imageUrl as dynamic) as string
    if not isNonEmptyString(imageUrl) then return imageUrl
    parts = imageUrl.Split("/")
    if parts.count() = 0 then return imageUrl
    fileName = parts[parts.count() - 1]
    if isEmptyString(fileName) then return imageUrl
    localPath = "pkg:/images/radio/" + fileName
    if CreateObject("roFileSystem").Exists(localPath) then return localPath
    return imageUrl
end function

sub buildCards()
    m.gCardsTrack.removeChildrenIndex(m.gCardsTrack.getChildCount(), 0)
    m.cardNodes = []
    borderColors = ["#ff3c00", "#ff0000", "#fa6428", "#587fed"]
    cardSize = 192
    spacing = 38
    totalWidth = m.radios.count() * cardSize + (m.radios.count() - 1) * spacing
    startX = (1920 - totalWidth) / 2
    for i = 0 to m.radios.count() - 1
        card = createObject("roSGNode", "RadioCardItem")
        card.imageUri = m.radios[i].image
        card.bgColor = m.radios[i].color
        card.borderColor = borderColors[i MOD borderColors.count()]
        card.itemHasFocus = false
        card.translation = [startX + i * (cardSize + spacing), 0]
        m.gCardsTrack.appendChild(card)
        m.cardNodes.push(card)
    end for
end sub

sub setCurrentRadio(index as integer, autoplay as boolean)
    if index < 0 OR index >= m.radios.count() then return
    m.currentIndex = index
    radio = m.radios[index]
    m.pPlayerLogo.uri = radio.image
    m.pPlayerLogoBg.blendColor = radio.color
    m.lRadioName.text = radio.name
    if autoplay
        playRadio()
    else
        stopRadio()
    end if
end sub

sub playRadio()
    if m.currentIndex < 0 OR m.currentIndex >= m.radios.count() then return
    radio = m.radios[m.currentIndex]
    content = createObject("roSGNode", "ContentNode")
    content.url = radio.liveUrl
    content.streamFormat = "hls"
    content.title = radio.name
    m.isLoading = true
    updatePlayPauseVisual()
    m.audio.content = content
    m.audio.control = "play"
end sub

sub stopRadio()
    if isValid(m.audio)
        m.audio.control = "stop"
        m.audio.content = invalid
    end if
    m.isPlaying = false
    m.isLoading = false
    updatePlayPauseVisual()
end sub

sub togglePlayPause()
    if m.isPlaying
        m.audio.control = "pause"
    else
        if m.audio.state = "paused"
            m.audio.control = "resume"
        else
            playRadio()
        end if
    end if
end sub

sub onAudioStateChanged(event as dynamic)
    state = event.GetData()
    if state = "playing"
        m.isPlaying = true
        m.isLoading = false
    else if state = "paused"
        m.isPlaying = false
        m.isLoading = false
    else if state = "buffering"
        m.isLoading = true
    else if state = "stopped" OR state = "finished" OR state = "error" OR state = "none"
        m.isPlaying = false
        m.isLoading = false
    end if
    updatePlayPauseVisual()
end sub

sub updatePlayPauseVisual()
    if m.isLoading
        m.bsLoading.visible = true
        m.pPlayPause.visible = false
        return
    end if
    m.bsLoading.visible = false
    m.pPlayPause.visible = true
    if m.isPlaying
        m.pPlayPause.uri = "pkg:/images/PlayerOverlayIcon/pause.png"
    else
        m.pPlayPause.uri = "pkg:/images/PlayerOverlayIcon/play.png"
    end if
end sub

sub onFocusedChild()
    if m.top.hasFocus() AND m.top.isInFocusChain()
        applyFocusVisuals()
    else
        clearFocusVisuals()
    end if
end sub

sub applyFocusVisuals()
    isCards = (m.focusArea = "cards") AND m.cardNodes.count() > 0
    m.pPlayerFocusBorder.visible = not isCards
    for i = 0 to m.cardNodes.count() - 1
        m.cardNodes[i].itemHasFocus = isCards AND (i = m.focusIndex)
    end for
end sub

sub clearFocusVisuals()
    m.pPlayerFocusBorder.visible = false
    for i = 0 to m.cardNodes.count() - 1
        m.cardNodes[i].itemHasFocus = false
    end for
end sub

sub setFocusToPlayer()
    m.focusArea = "player"
    m.top.setFocus(true)
    applyFocusVisuals()
end sub

sub setFocusToCards(index as integer)
    if m.cardNodes.count() = 0 then return
    if index < 0 then index = 0
    if index > m.cardNodes.count() - 1 then index = m.cardNodes.count() - 1
    m.focusIndex = index
    m.focusArea = "cards"
    m.top.setFocus(true)
    applyFocusVisuals()
end sub

sub onVisibleChange(event as dynamic)
    visible = event.GetData()
    if not visible then stopRadio()
end sub

sub onPageDestroy()
    if m.top.isDestroy then stopRadio()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if m.top.hasFocus() then applyFocusVisuals()
    if not m.radiosLoaded then return false
    if m.focusArea = "player"
        if key = "OK"
            togglePlayPause()
            return true
        else if key = "down"
            setFocusToCards(m.currentIndex)
            return true
        else if key = "up" OR key = "right"
            return true
        end if
    else if m.focusArea = "cards"
        if key = "OK"
            m.currentIndex = m.focusIndex
            setCurrentRadio(m.focusIndex, true)
            setFocusToPlayer()
            return true
        else if key = "left"
            if m.focusIndex > 0
                setFocusToCards(m.focusIndex - 1)
                return true
            end if
            return false
        else if key = "right"
            if m.focusIndex < m.cardNodes.count() - 1
                setFocusToCards(m.focusIndex + 1)
            end if
            return true
        else if key = "up"
            setFocusToPlayer()
            return true
        end if
    end if
    return false
end function
