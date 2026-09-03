sub Init()
    print "OnboardingPage Init "
    SetLocals()
    SetControls()
    SetupFonts()
    SetupColor()
    SetObservers()
    Initialize()
end sub

sub SetLocals()
    m.scene = m.top.GetScene()
    m.fonts = m.global.fonts
    m.config = m.global.appConfig
    m.theme = m.global.appTheme
    m.isFull = false
    m.response = invalid
    m.scene.callFunc("ShowHideLoader", false)
    m.link = GlobalGet("urlTVVincular")
end sub

sub SetControls()
    m.rBackground = m.top.findNode("rBackground")
    m.pBackground = m.top.findNode("pBackground")
    m.logo = m.top.findNode("logo")
    m.welcomeTitleText = m.top.findNode("WelcomeTitleText")
    m.loginButton = m.top.findNode("LoginButton")
    m.donthaveAccountText = m.top.findNode("DonthaveAccountText")
    m.registerText = m.top.findNode("RegisterText")
    m.qrCode = m.top.findNode("qrCode")
    m.gOnboarding = m.top.findNode("gOnboarding")
    backgroundImage = GlobalGet("backgroundImage")
    if isNonEmptyString(backgroundImage)
        m.pBackground.uri = backgroundImage
    end if
    btnFields = {
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.white
        backgroundColor: m.theme.focPrimary
        focusBorderImage: m.theme.filledBackGroundImage
        focusBackgroundColor: m.theme.focPrimary
        fontSize: "dmSansMedium24"
        margin: 20
    }
    m.LoginButton.update(btnFields)
end sub

sub SetupFonts()
    m.welcomeTitleText.font = m.fonts.dmSansMedium29
    m.registerText.font = m.fonts.dmSansMedium26
end sub

sub SetupColor()
    m.rBackground.color = m.theme.clrPrimary
    m.welcomeTitleText.color = m.theme.white
    m.registerText.color = m.theme.white
end sub

sub SetObservers()
    m.top.observeField("focusedChild", "OnFocusedChild")
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

sub OnFocusedChild()
    if m.top.hasFocus()
        focusRestored = RestoreFocus()
        if focusRestored = false
            SetFocus(m.LoginButton)
        end if
    end if
end sub

sub Initialize()
    fontStyle = {
        "Normal": {
            "fontUri": "pkg:/fonts/DMSans-Medium.ttf"
            "fontSize": 24
            "color": m.theme.white
        }
        "Link": {
            "fontUri": "pkg:/fonts/DMSans-Medium.ttf"
            "fontSize": 24
            "color": m.theme.focPrimary
        }
    }
    m.donthaveAccountText.drawingStyles = fontStyle
    multiStyleMakersText = "<Normal>¿No tienes una cuenta? </Normal>" + chr(10) + "<Normal>Regístrate en </Normal>" + "<Link>" + m.link + "</Link>" '+ chr(10) + "<Normal> o escanéa el código QR</Normal>"
    m.donthaveAccountText.text = multiStyleMakersText
    m.qrCode.uri = m.config.qrLink + m.link
    SetFocus(m.LoginButton)
    bound = m.gOnboarding.boundingRect()
    yPos = (1080 - bound.height) / 2
    m.gOnboarding.translation = [0, yPos - 40]
end sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
    print " Page : OnboardingPage : onKeyEvent : key = " key " press = " press
    handled = true
    if press
        if key = "OK"
            if m.LoginButton.hasFocus()
                m.scene.callFunc("showLoginPage", false)
                handled = true
            end if
        else if key = "back"
            handled = false
        end if
        return handled
    end if
End Function
