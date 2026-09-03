sub init()
    setLocals()
    setControls()
    setupColors()
    setupFonts()
    setObservers()
end sub

sub setLocals()
    m.fonts = m.global.Fonts
    m.theme = m.global.appTheme
end sub

sub setControls()
    m.message = m.top.findNode("message")
    m.messageBackground = m.top.findNode("messageBackground")
    m.messageShowAnimation = m.top.findNode("messageShowAnimation")
    m.lText = m.top.findNode("lText")
    m.gDetails = m.top.findNode("gDetails")
    m.messageIcon = m.top.findNode("messageIcon")
    m.tostMessageBackground = m.top.findNode("tostMessageBackground")
end sub

sub setupColors()
    m.messageBackground.blendColor = m.theme.focPrimary
    m.tostMessageBackground.color = m.theme.FocusColor
    m.messageIcon.blendColor = m.theme.white
    m.message.color = m.theme.black
end sub

sub setupFonts()
end sub

sub setObservers()
    m.messageShowAnimation.observeField("state", "onAnimationStateChange")
end sub

sub onAnimationStateChange()
end sub

sub onQuickHideChanged()
    if (m.top.quickHide = true AND m.messageShowAnimation.state <> "stopped") then
        m.messageShowAnimation.control = "finish"
    end if
    m.top.quickHide = false
end sub

sub onMessageChanged()
    setData = m.top.msgData
    if setData.title <> invalid AND setData.title <> ""
        m.lText.text = setData.title
        m.lText.width = setData.width - 30
        m.lText.translation = [15, 15]
        m.lText.font = m.fonts.plusJakartaSansBold25
        m.lText.color = setData.messageColor
    end if

    m.message.text = setData.message
    m.message.width = (setData.width - (setData.iconWidth + 40))
    m.message.font = m.fonts.plusJakartaSansBold20
    m.message.color = setData.messageColor
    m.message.vertAlign = "center"
    m.message.wrap = true
    m.message.maxLines = 2

    m.messageIcon.uri = setData.iconURI
    m.messageIcon.width = setData.iconWidth
    m.messageIcon.height = setData.iconHeight

    boundRect = m.messageBackground.boundingRect()
    m.messageBackground.width = setData.width
    m.messageBackground.height = boundRect.height + 20
    xPos = 1920 - (m.messageBackground.width + 40)
    m.messageBackground.translation = [xPos, 100]

    msgbackground = m.message.boundingRect()
    msgbackgroundIcon = m.messageIcon.boundingRect()
    m.messageIcon.translation = [15, (m.messageBackground.height - msgbackgroundIcon.height) / 2]
    m.message.translation = [15 + setData.iconWidth + 15, (m.messageBackground.height - msgbackground.height) / 2]

    if (setData.showBackground)
        m.tostMessageBackground.visible = true
    end if

    m.messageShowAnimation.duration = setData.toastDuration
    m.messageShowAnimation.easeFunction = "linear"
    if (setData.message <> invalid AND setData.message <> "")
        if (m.messageShowAnimation.state <> "stopped") then
            m.messageShowAnimation.control = "finish"
            m.top.toastClosed = true
        end if
        m.messageBackground.opacity = 0
        m.messageShowAnimation.control = "start"
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    result = false
    if(press)
        if(key = "back")

        else if(key = "OK")
        else if(key = "up" OR key = "down")
            result = true
        else if(key = "left")
            result = true
        else if(key = "right")
            result = true
        end if
    end if

    return result
end function