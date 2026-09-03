sub Init()
    print "DeviceLinkPage Init "
    SetLocals()
    SetControls()
    SetupFonts()
    SetupColor()
    SetObservers()
    SetBusySpinnerControls()
    Initialize()
end sub

sub SetLocals()
    m.scene = m.top.GetScene()
    m.fonts = m.global.fonts
    m.config = m.global.appConfig
    m.theme = m.global.appTheme
    m.registryManager = CreateRegistryManager()
    m.response = invalid
    m.TokenValue = ""
    m.link = GlobalGet("urlTVVincular")
end sub

sub SetControls()
    m.rBackground = m.top.findNode("rBackground")
    m.pBackground = m.top.findNode("pBackground")
    m.logo = m.top.findNode("logo")
    m.DeviceLinkTitleText = m.top.findNode("DeviceLinkTitleText")
    m.stepOneBadge = m.top.findNode("stepOneBadge")
    m.stepOneNumber = m.top.findNode("stepOneNumber")
    m.stepOneText = m.top.findNode("stepOneText")
    m.qrCode = m.top.findNode("qrCode")
    m.stepTwoBadge = m.top.findNode("stepTwoBadge")
    m.stepTwoNumber = m.top.findNode("stepTwoNumber")
    m.stepTwoText = m.top.findNode("stepTwoText")
    m.codeBackground = m.top.findNode("codeBackground")
    m.codeValueText = m.top.findNode("codeValueText")
    m.emailText = m.top.findNode("emailText")
    m.deviceLinkTimer = m.top.findNode("deviceLinkTimer")
    m.deviceLinkPreloader = m.top.findNode("deviceLinkPreloader")
    m.codeExpiryTimer = m.top.findNode("codeExpiryTimer")
    backgroundImage = GlobalGet("backgroundImage")
    if isNonEmptyString(backgroundImage)
        m.pBackground.uri = backgroundImage
    end if
end sub

sub SetupFonts()
    m.DeviceLinkTitleText.font = m.fonts.dmSansMedium32
    m.stepOneNumber.font = m.fonts.dmSansMedium30
    m.stepOneText.font = m.fonts.dmSansMedium25
    m.stepTwoNumber.font = m.fonts.dmSansMedium30
    m.stepTwoText.font = m.fonts.dmSansMedium25
    m.codeValueText.font = m.fonts.dmSansMedium24
    m.emailText.font = m.fonts.dmSansMedium24
end sub

sub SetupColor()
    m.rBackground.color = m.theme.clrPrimary
    m.DeviceLinkTitleText.color = m.theme.white
    m.stepOneBadge.blendColor = m.theme.clrSecondary
    m.stepOneNumber.color = m.theme.white
    m.stepOneText.color = m.theme.clrSecondaryText
    m.stepTwoBadge.blendColor = m.theme.clrSecondary
    m.stepTwoNumber.color = m.theme.white
    m.stepTwoText.color = m.theme.clrSecondaryText
    m.codeValueText.color = m.theme.white
    m.codeBackground.blendColor = m.theme.clrSecondary
    m.emailText.color = m.theme.focPrimary
end sub

sub SetObservers()
    m.deviceLinkTimer.ObserveField("fire", "CallDevicePairAPI")
    m.codeExpiryTimer.ObserveField("fire", "callGetDeviceCodeAPI")
    m.pBackground.observeField("loadStatus", "OnLoadStatusChanged")
    m.logo.observeField("loadStatus", "OnLogoLoadStatusChanged")
    logoImage = GlobalGet("logo")
    if isNonEmptyString(logoImage)
        m.logo.uri = logoImage
    end if
end sub

sub OnLogoLoadStatusChanged(event as object)
    status = event.GetData()
    node = event.getRoSGNode()
    if status = "ready"
        imageWidth = node.bitmapWidth
        imageHeight = node.bitmapHeight
        node.width = imageWidth * (node.height / imageHeight)
    end if
end sub

sub OnLoadStatusChanged(event as object)
    status = event.GetData()
    if status = "ready"
        m.pBackground.width = m.pBackground.bitmapWidth
        newWidth = (m.pBackground.bitmapWidth * m.pBackground.height) / m.pBackground.bitmapHeight
        xPos = (1920 - newWidth)
        m.pBackground.translation = [xPos, 0]
    end if
end sub

Sub SetBusySpinnerControls()
    m.deviceLinkPreloader.poster.uri = "pkg:/images/loader/small-loader.png"
    m.deviceLinkPreloader.poster.blendColor = m.theme.white
    m.deviceLinkPreloader.poster.width = 50
    m.deviceLinkPreloader.poster.height = 50
    codeBtnBondinRect = m.codeBackground.boundingrect()
    m.deviceLinkPreloader.translation = [(codeBtnBondinRect.width - m.deviceLinkPreloader.poster.width) / 2, (codeBtnBondinRect.height - (m.deviceLinkPreloader.poster.height + 5)) / 2] '[177, 31.5]
End Sub

sub Initialize()
    m.scene.callFunc("ShowHideLoader", false)
    m.stepOneNumber.text = "1"
    m.stepTwoNumber.text = "2"
    m.qrCode.uri = m.config.qrLink + m.link
    SetFocus(m.emailText)
    callGetDeviceCodeAPI()
end sub

sub callGetDeviceCodeAPI()
    m.codeValueText.text = ""
    m.deviceLinkPreloader.visible = true
    m.GetDeviceCodeAPI = CreateObject("roSGNode", "AuthAPIAction")
    m.GetDeviceCodeAPI.functionName = "GetDeviceCodeAPI"
    m.GetDeviceCodeAPI.ObserveField("result", "OnGetDeviceCodeAPIResponse")
    m.GetDeviceCodeAPI.control = "RUN"
end sub

sub OnGetDeviceCodeAPIResponse(event as dynamic)
    response = event.getData()
    print "OnGetDeviceCodeAPIResponse : response : " 'FormatJson(response)
    response = getValueFromProps(response.data.data, "data", {})
    if response.count() > 0 AND isValid(response.code_tv)
        m.codeValueText.text = response.code_tv
        m.TokenValue = response.token_tv
        m.deviceLinkPreloader.visible = false
        duration = checkAndReturnSecond(response.expires)
        m.codeExpiryTimer.duration = duration
        m.codeExpiryTimer.control = "start"
        CallDevicePairAPI()
    end if
end sub

sub CallDevicePairAPI()
    params = {
        token_tv: m.TokenValue
    }
    m.DevicePairAPI = CreateObject("roSGNode", "AuthAPIAction")
    m.DevicePairAPI.functionName = "VerifyDevice"
    m.DevicePairAPI.params = params
    m.DevicePairAPI.ObserveField("result", "OnDevicePairAPIResponse")
    m.DevicePairAPI.control = "RUN"
end sub

sub OnDevicePairAPIResponse(event as dynamic)
    response = event.getData()
    response = getValueFromProps(response.data, "data", {})
    If isValid(response) AND isValid(response.user) AND isValid(response.user.token) AND response.user.token <> ""
        m.registryManager.SaveUserData(response.user)
        GlobalSet("UserData", response.user)
        m.registryManager.SaveToken(response.user.token)
        GlobalSet("token", response.user.token)
        m.deviceLinkTimer.control = "stop"
        m.scene.isUserLoggedIn = true
        m.scene.callFunc("ShowEditorProfilesPage", true)
    End If
end sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
    print "Page : DeviceLinkPage : onKeyEvent : key = " key " press = " press
    handled = true
    if press
        if key = "OK"
            if m.emailText.hasFocus()
                m.scene.callFunc("ShowLoginPage", false)
                handled = true
            end if
        else if key = "back"
            handled = false
        end if
        return handled
    end if
End Function
