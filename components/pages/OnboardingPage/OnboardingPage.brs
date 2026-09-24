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
    m.scene.callFunc("ShowHideLoader", false)
    ' m.global.homeConfig guarda la respuesta completa de /feed/configuracion
    ' (ver MainScene::OnGetConfigAPIResponse) - de ahi salen los campos que
    ' usa especificamente esta pantalla en c13_reloaded (LoginView.tsx):
    ' fondo_corporativo (fondo) y logo_invertido (la caja naranja, distinta
    ' del logo_blanco que usa el sidebar).
    m.homeConfig = m.global.homeConfig
end sub

sub SetControls()
    m.rBackground = m.top.findNode("rBackground")
    m.pBackground = m.top.findNode("pBackground")
    m.pFadeLeft = m.top.findNode("pFadeLeft")
    m.pFadeBottom = m.top.findNode("pFadeBottom")
    m.logo = m.top.findNode("logo")
    m.welcomeTitleText = m.top.findNode("WelcomeTitleText")
    m.welcomeBodyText = m.top.findNode("WelcomeBodyText")
    m.haveAccountText = m.top.findNode("HaveAccountText")
    m.loginButton = m.top.findNode("LoginButton")
    m.lQrTitle = m.top.findNode("lQrTitle")
    m.registerFooterText = m.top.findNode("RegisterFooterText")

    backgroundImage = getValueFromProps(m.homeConfig, "fondo_corporativo", "")
    if not isNonEmptyString(backgroundImage) then backgroundImage = GlobalGet("backgroundImage")
    if isNonEmptyString(backgroundImage) then m.pBackground.uri = backgroundImage

    logoImage = getValueFromProps(m.homeConfig, "logo_invertido", "")
    if isNonEmptyString(logoImage)
        m.logo.uri = logoImage
    else
        m.logo.uri = "pkg:/images/brand/logo_bienvenida.png"
    end if

    btnFields = {
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.white
        backgroundColor: "#8C8C8C"
        focusBackgroundColor: m.theme.focPrimary
        fontSize: "dmSansBold23"
        margin: 20
    }
    m.LoginButton.update(btnFields)
end sub

sub SetupFonts()
    m.welcomeBodyText.font = m.fonts.dmSansBold23
    m.haveAccountText.font = m.fonts.dmSansBold23
    m.lQrTitle.font = m.fonts.dmSansBold23
end sub

sub SetupColor()
    m.rBackground.color = m.theme.clrPrimary
    m.welcomeBodyText.color = m.theme.white
    m.haveAccountText.color = m.theme.white
    m.lQrTitle.color = m.theme.black
end sub

sub SetObservers()
    m.top.observeField("focusedChild", "OnFocusedChild")
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
    ' Titulo con la segunda linea destacada en naranjo, igual que el
    ' <span class="highlight"> de LoginView.tsx.
    titleStyles = {
        "Normal": {
            "fontUri": "pkg:/fonts/DMSans-Bold.ttf"
            "fontSize": 46
            "color": m.theme.white
        }
        "Link": {
            "fontUri": "pkg:/fonts/DMSans-Bold.ttf"
            "fontSize": 46
            "color": m.theme.focPrimary
        }
    }
    m.welcomeTitleText.drawingStyles = titleStyles
    m.welcomeTitleText.text = "<Normal>Regístrate y</Normal>" + chr(10) + "<Link>descubre 13Go</Link>"

    footerStyles = {
        "Normal": {
            "fontUri": "pkg:/fonts/DMSans-Bold.ttf"
            "fontSize": 23
            "color": m.theme.white
        }
        "Link": {
            "fontUri": "pkg:/fonts/DMSans-Bold.ttf"
            "fontSize": 23
            "color": m.theme.focPrimary
        }
    }
    m.registerFooterText.drawingStyles = footerStyles
    m.registerFooterText.text = "<Normal>o entrando a </Normal><Link>13go.cl</Link>"

    SetFocus(m.LoginButton)
end sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
    print " Page : OnboardingPage : onKeyEvent : key = " key " press = " press
    handled = false
    if press
        if key = "OK"
            if m.LoginButton.hasFocus()
                m.scene.callFunc("ShowDeviceLinkPage", true)
                handled = true
            end if
        end if
    end if
    return handled
End Function
