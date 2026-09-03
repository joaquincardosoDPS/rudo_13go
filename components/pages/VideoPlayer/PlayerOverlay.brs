sub init()
    SetLocals()
    SetControls()
    SetupColor()
    SetupFonts()
    SetObservers()
    initilize()
end sub
'
sub SetLocals()
    m.scene = m.top.GetScene()
    m.theme = m.global.appTheme
    m.appConfig = m.global.appConfig
    m.fonts = m.global.fonts
    m.isContentUpdate = false
end sub
'
sub SetControls()
    m.leftProgressLabel = m.top.findNode("leftProgressLabel")
    m.crossArrow = m.top.findNode("crossArrow")
    m.rightProgressLabel = m.top.findNode("rightProgressLabel")
    m.outlineRect = m.top.findNode("outlineRect")
    m.progressRect = m.top.findNode("progressRect")
    m.pSeekingDotFocused = m.top.findNode("pSeekingDotFocused")
    m.pSeekingDotUnfocused = m.top.findNode("pSeekingDotUnfocused")

    m.gOverlayDetails = m.top.findNode("gOverlayDetails")
    m.lVideoTitle = m.top.findNode("lVideoTitle")

    m.playerButtonsMarkupGrid = m.top.findNode("playerButtonsMarkupGrid")
    m.playerButtonsMarkupGrid.columnSpacings = "[0,0,696,16]"

    m.loaderSection = m.top.findNode("loaderSection")
    m.loadingStatus = m.top.findNode("loadingStatus")
    m.lSpinner = m.top.findNode("lSpinner")
end sub

sub SetObservers()
    m.top.observeField("visible", "onVisibleChange")
    m.top.observeField("focusedChild", "onFocusedChild")
    m.outlineRect.observeField("focusedChild", "onOutlinerectFocused")
    m.playerButtonsMarkupGrid.observeField("itemSelected", "onPlayerButtonsSelected")
end sub

sub SetupColor()
    m.progressRect.blendColor = m.theme.focPrimary
    m.outlineRect.blendColor = m.theme.white
    m.leftProgressLabel.color = m.theme.white
    m.crossArrow.color = m.theme.white
    m.rightProgressLabel.color = m.theme.white
    m.lVideoTitle.color = m.theme.white
end sub

sub SetupFonts()
    m.leftProgressLabel.font = m.fonts.poppinsMedium24
    m.crossArrow.font = m.fonts.poppinsMedium24
    m.rightProgressLabel.font = m.fonts.poppinsMedium24
    m.lVideoTitle.font = m.fonts.poppinsBold28
end sub

sub initilize()
    m.progressWidth = m.outlineRect.width
    m.videoDuration = 0
    m.trickPosition = 0
    m.trickOffset = 0

    m.top.endDuration = 0
    m.trickPlayTimer = createObject("roSGNode", "Timer")
    m.trickPlayTimer.duration = 1
    m.trickPlayTimer.repeat = True
    m.trickPlayTimer.observeField("fire", "handleTrickPlayTimer")

    m.singleSeeking = false
    m.progressBarPosition = 0
    ResetData()
end sub

sub ResetData()
    m.progressBarPosition = 0
    m.videoDuration = 0
    if isValid(m.playerButtonsMarkupGrid.content) AND isValid(m.playerButtonsMarkupGrid.content.getChild(1))
        m.playerButtonsMarkupGrid.content.getChild(1).icon_url = "pkg:/images/PlayerOverlayIcon/pause.png"
    end if
    m.progressRect.width = 0
    m.progressRect.visible = false
    m.top.seekingStatus = ""
    m.top.videoPlayerState = ""
    resetSeekLogic()
end sub

sub focusSeekBar()
    SetFocus(m.outlineRect)
end sub

sub onFocusedChild()
    if m.top.hasFocus()
        if not RestoreFocus()
            focusSeekBar()
        end if
    end if
end sub

sub setupPlayerButtons()
    m.row = CreateObject("roSGNode", "ContentNode")
    ButtonsData = ReadAsciiFile("pkg:/source/data/PlayerButtonsItems.json")
    Buttons = ParseJson(ButtonsData)
    totalItems = Buttons.count() - 1
    for i = 0 to totalItems
        item = Buttons[i]
        PlayerButtonsItemData = m.row.CreateChild("ContentNode")
        PlayerButtonsItemData.id = item.itemId
        PlayerButtonsItemData.AddFields({ "icon_url": item.icon_url })
        if item.itemId = "like" AND isValid(m.top.videoParams.isLike) AND isValid(item.icon_fill_uri)
            PlayerButtonsItemData.AddFields({ "isLike": m.top.videoParams.isLike })
            PlayerButtonsItemData.AddFields({ "icon_fill_uri": item.icon_fill_uri })
        end if
        if item.itemId = "addWatchList" AND isValid(m.top.videoParams.isWatch) AND isValid(item.icon_fill_uri)
            PlayerButtonsItemData.AddFields({ "isWatch": m.top.videoParams.isWatch })
            PlayerButtonsItemData.AddFields({ "icon_fill_uri": item.icon_fill_uri })
        end if
    end for
    m.playerButtonsMarkupGrid.content = m.row
end sub

sub onPlayerButtonsSelected(event as dynamic)
    index = event.GetData()
    if (not m.isContentUpdate AND isValid(m.playerButtonsMarkupGrid) AND isValid(m.playerButtonsMarkupGrid.content))
        childNode = m.playerButtonsMarkupGrid.content.getChild(index)
        if childNode.id = "rewind"
            checkAndStartForwardRewindSeeking("left")
        else if childNode.id = "forward"
            checkAndStartForwardRewindSeeking("right")
        else if childNode.id = "settings"
            ' TODO: open settings dialog or others
        end if
    end if
end sub

sub checkAndStartForwardRewindSeeking(key as string)
    m.singleSeeking = true
    m.top.seekingStatus = "STARTED"
    m.trickPlayTimer.control = "stop"
    m.trickPlaySpeed = 0
    handleSingleSeeking(key)
    endSeeking()
end sub

' Show Toast Message
sub showTopRightCornerToast(message as string)
    print "MainScene : ShowTopRightCornerToast : " message
    messageData = {}
    messageData = {
        "message": message,
        "width": 430,
        "height": 70,
        "iconURI": "pkg:/images/icons/info-50.png",
        "iconWidth": 50,
        "iconHeight": 50,
        "toastDuration": 3,
        "lgLayoutWidth": 473,
        "showBackground": false,
        "messageColor": m.theme.white
    }
    showToastMessage(messageData)
end sub

sub showToastMessage(msg)
    if m.toastMessageBox <> invalid
        m.toastMessageBox.toastClosed = true
        m.top.removeChild(m.toastMessageBox)
        m.toastMessageBox = invalid
    end if
    m.toastMessageBox = m.top.CreateChild("ToastMessage")
    m.toastMessageBox.observeField("toastClosed", "hideToastMessage")
    m.toastMessageBox.msgData = msg
end sub

sub hideToastMessage()
    if m.toastMessageBox <> invalid
        m.toastMessageBox.quickHide = true
    end if
end sub
' Hide Toast Message

sub onOutlinerectFocused()
    if m.outlineRect.hasFocus()
        m.pSeekingDotUnfocused.visible = false
        m.pSeekingDotFocused.visible = true
    else
        m.pSeekingDotFocused.visible = false
        m.pSeekingDotUnfocused.visible = true
    end if
end sub

sub onVisibleChange()
    if m.top.visible = true then
        if not restoreFocus()
            setFocus(m.outlineRect)
        end if
        UpdateIconState()
        showProgressBar(m.position)
    else
        m.trickPlayTimer.control = "STOP"
    end if
end sub

sub OnVideoDurationChanged(event as dynamic)
    m.duration = event.GetData()
    if isValid(m.duration) AND m.duration > 0
        m.videoDuration = m.duration
        m.top.endDuration = m.duration
    end if
    if isValid(m.videoDuration)
        m.rightProgressLabel.text = FormatTime(m.videoDuration)
    end if
end sub

sub OnVideoParamsChanged(event as dynamic)
    m.videoParams = event.getData()
    print "PlayerOverlay : OnVideoParamsChanged : videoParams : " m.videoParams
    if isValid(m.videoParams) then
        if isValid(m.videoParams.duration_seg)
            m.videoDuration = m.videoParams.duration_seg
        end if
        m.lVideoTitle.text = m.videoParams.title
        setupPlayerButtons()
        m.gOverlayDetails.visible = true
    else
        m.gOverlayDetails.visible = true
    end if
    if isValid(m.videoParams.duration)
        m.rightProgressLabel.text = FormatTime(m.videoParams.duration.toInt())
    end if
end sub

function resetSeekLogic()
    m.trickPlaySpeed = 0
    m.trickOffset = 0
    m.trickPlayTimer.duration = 1
    m.trickInterval = 10
    m.trickSingleOffset = 0
    m.singleSeeking = false
    UpdateIconState()
end function

function isSeeking() as boolean
    return m.trickPlaySpeed <> 0 OR m.trickOffset <> 0 OR m.trickSingleOffset <> 0
end function

function startSeeking()
    PauseVideo()
    m.trickPlayTimer.control = "STOP"

    if m.trickPlaySpeed <> 0
        m.trickPlayTimer.duration = 1 / abs(m.trickPlaySpeed)
        m.trickPlayTimer.control = "START"
    else
        m.TrickPlayTimer.duration = 1
    end if
end function

function endSeeking(shouldSeek = true as boolean, isSingleSeeking = false as boolean)
    m.trickPlayTimer.control = "STOP"
    if shouldSeek = true then
        m.top.seekPosition = m.progressBarPosition
        m.position = m.progressBarPosition
    else
        m.progressBarPosition = m.position
        m.top.seekPosition = -1
    end if
    if not isSingleSeeking then m.top.seekingStatus = "STOPPED"
    resetSeekLogic()
end function

sub OnVideoPositionChanged(event as dynamic)
    m.position = event.getData()
    showProgressBar(m.position)
end sub

sub ActionOnPlay()
    if (m.top.videoPlayerState = "playing") then
        m.top.action = {
            userAction: "PAUSED",
            videoPosition: m.position
        }
    else
        m.top.action = {
            userAction: "PLAYED",
            videoPosition: m.position
        }
    end if
end sub

sub OnUserAction(event as dynamic)
    params = event.getData()
    if not IsNullOrEmpty(params.userAction) then
        if params.userAction = "PAUSED" then
            if isValid(m.playerButtonsMarkupGrid.content) AND isValid(m.playerButtonsMarkupGrid.content.getChild(1))
                m.playerButtonsMarkupGrid.content.getChild(1).icon_url = "pkg:/images/PlayerOverlayIcon/play.png"
            end if
            if(m.progressBarPosition > 0 AND params.videoPosition <> m.progressBarPosition AND isSeeking())
                showProgressBar(m.progressBarPosition)
            else
                showProgressBar(params.videoPosition)
            end if
        else if params.userAction = "PLAYED" then
            if isValid(m.playerButtonsMarkupGrid.content) AND isValid(m.playerButtonsMarkupGrid.content.getChild(1))
                m.playerButtonsMarkupGrid.content.getChild(1).icon_url = "pkg:/images/PlayerOverlayIcon/pause.png"
            end if
            resetSeekLogic()
        end if
    end if
end sub

sub UpdateIconState()
    if (m.top.videoPlayerState = "buffering" OR m.top.videoPlayerState = "finished")
        m.isContentUpdate = false
    end if
    if isValid(m.playerButtonsMarkupGrid.content) AND isValid(m.playerButtonsMarkupGrid.content.getChild(1))
        if (m.top.videoPlayerState = "paused") then
            m.playerButtonsMarkupGrid.content.getChild(1).icon_url = "pkg:/images/PlayerOverlayIcon/play.png"
        else
            m.playerButtonsMarkupGrid.content.getChild(1).icon_url = "pkg:/images/PlayerOverlayIcon/pause.png"
        end if
    end if
end sub

function showProgressBar(position)
    if (isValid(m.videoDuration) AND m.videoDuration <> 0 AND isValid(position))
        m.progressBarPosition = position
        m.progressRect.width = position * m.progressWidth / m.videoDuration

        leftPositionSeconds = position * 100 / 100
        m.leftProgressLabel.text = FormatTime(leftPositionSeconds)

        m.pSeekingDotFocused.translation = [m.progressRect.width - 7, -13]
        m.pSeekingDotUnfocused.translation = [m.progressRect.width - 7, -8]

        if isSeeking()
            if isValid(m.playerButtonsMarkupGrid.content) AND isValid(m.playerButtonsMarkupGrid.content.getChild(1))
                m.playerButtonsMarkupGrid.content.getChild(1).icon_url = "pkg:/images/PlayerOverlayIcon/play.png"
            end if
        end if
        m.top.videoPosition = m.progressBarPosition
        if (m.progressRect.width = 0)
            m.progressRect.visible = false
        else
            m.progressRect.visible = true
        end if
    end if
end function

function handleSingleSeeking(direction as string)
    if direction = "right"
        if m.progressBarPosition + 10 <= m.videoDuration
            m.trickSingleOffset = 10
        else
            m.trickSingleOffset = m.videoDuration - m.progressBarPosition ' Seek to t = duration
        end if
    else if direction = "left"
        if m.progressBarPosition - 10 >= 0
            m.trickSingleOffset = 10 * -1
        else
            m.trickSingleOffset = m.progressBarPosition * -1
        end if
    end if

    showProgressBar(m.progressBarPosition + m.trickSingleOffset)
    if ((m.progressBarPosition <= 0 AND direction = "left") OR (m.progressBarPosition >= m.videoDuration AND direction = "right")) then
        UpdateProgress()
    end if
    endSeeking(true, true)
end function
'
function handleTrickPlayTimer()
    if m.trickPlaySpeed > 0
        if m.progressBarPosition + m.trickInterval <= m.videoDuration
            m.trickOffset = m.trickInterval
        else
            m.trickOffset = m.videoDuration - m.progressBarPosition
        end if
    else if m.trickPlaySpeed < 0
        if m.progressBarPosition - m.trickInterval >= 0
            m.trickOffset = m.trickInterval * -1
        else
            m.trickOffset = m.progressBarPosition * -1
        end if
    end if
    showProgressBar(m.progressBarPosition + m.trickOffset)
    if ((m.progressBarPosition <= 0 AND m.trickPlaySpeed < 0) OR (m.progressBarPosition >= m.videoDuration AND m.trickPlaySpeed > 0)) then
        UpdateProgress()
    end if
end function

sub UpdateProgress()
    if isSeeking()
        endSeeking()
    end if
end sub

sub PauseVideo()
    if m.top.videoPlayerState <> "buffering"
        m.top.pauseVideo = true
    end if
end sub

sub SetSeekInterval()
    if m.trickPlaySpeed = 1 OR m.trickPlaySpeed = -1 then
        m.trickInterval = 30
    else if m.trickPlaySpeed = 2 OR m.trickPlaySpeed = -2 then
        m.trickInterval = 60
    else if m.trickPlaySpeed = 3 OR m.trickPlaySpeed = -3 then
        m.trickInterval = 90
    else
        m.trickInterval = 10
    end if
end sub

function OnCustomPlayerKeyPress(msg)
    data = msg.getData()
    onKeyEvent(data.key, data.press)
end function

function OnFocusDown() as boolean
    result = false
    if (isValid(m.playerButtonsMarkupGrid) AND (m.playerButtonsMarkupGrid.hasFocus() OR m.playerButtonsMarkupGrid.IsInFocusChain()))
        focusSeekBar()
        result = true
    end if
    return result
end function

function OnFocusUp() as boolean
    result = false
    if m.outlineRect.hasFocus() AND isValid(m.playerButtonsMarkupGrid.content) AND m.playerButtonsMarkupGrid.visible
        if m.top.seekingStatus = "STARTED"
            endSeeking()
        end if
        setFocus(m.playerButtonsMarkupGrid)
        result = true
    end if
    return result
end function

function handleOKKeyEvent(isPlayPause as boolean)
    result = false
    if (not (isPlayPause) AND isValid(m.playerButtonsMarkupGrid.content) AND (m.playerButtonsMarkupGrid.hasFocus() OR m.playerButtonsMarkupGrid.IsInFocusChain()))
        result = true
    else if isSeeking()
        endSeeking()
        ActionOnPlay()
        result = true
    end if
    return result
end function

function onKeyEvent(key as string, press as boolean) as boolean
    result = false
    print "PlayerOverlay : onKeyEvent : key = " key " press = " press
    if (press AND not m.isContentUpdate)
        if m.top.videoPlayerState <> "paused"
            m.top.resetHideControlsTimer = true
        end if
        if (key = "play" OR key = "OK" OR (key = "back" AND isSeeking()))
            if key = "play"
                if isValid(m.playerButtonsMarkupGrid.content)
                    setFocus(m.playerButtonsMarkupGrid)
                    m.playerButtonsMarkupGrid.jumpToItem = 1
                end if
            end if
            isPlayPause = false
            if isValid(m.playerButtonsMarkupGrid.content) AND isValid(m.playerButtonsMarkupGrid.content.getChild(m.playerButtonsMarkupGrid.itemFocused))
                childNode = m.playerButtonsMarkupGrid.content.getChild(m.playerButtonsMarkupGrid.itemFocused)
                if (isValid(childNode) AND childNode.id = "playPause")
                    isPlayPause = true
                end if
            end if
            if key = "OK"
                result = handleOKKeyEvent(isPlayPause)
            end if
        else if (key = "up")
            result = OnFocusUp()
        else if (key = "down")
            result = OnFocusDown()
        else if (key = "back") then
            m.trickPlayTimer.control = "STOP"
        else if (key = "fastforward" OR key = "rewind")
            m.singleSeeking = false
            m.top.seekingStatus = "STARTED"
            focusSeekBar()
            position = m.progressBarPosition
            if key = "fastforward"
                m.trickPlaySpeed++
                if m.trickPlaySpeed > 3 OR m.trickPlaySpeed <= 0
                    m.trickPlaySpeed = 1
                end if
                SetSeekInterval()
            else if key = "rewind"
                m.trickPlaySpeed--
                if m.trickPlaySpeed < -3 OR m.trickPlaySpeed >= 0
                    m.trickPlaySpeed = -1
                end if
                SetSeekInterval()
            end if
            if position >= 0
                showProgressBar(position)
                startSeeking()
            end if
            result = true
        else if key = "right" OR key = "left"
            if m.outlineRect.visible AND m.outlineRect.hasFocus()
                checkAndStartForwardRewindSeeking(key)
            end if
            result = true
        end if
    else
        result = true
    end if
    return result
end function