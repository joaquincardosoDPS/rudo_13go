' /suscribe (SuscribeView.tsx): invita a suscribirse cuando el usuario tiene
' sesion pero su plan no incluye el contenido. "Volver" (o back) cierra la
' pantalla: MainScene.CloseSuscribePage, el navigate(-1) de la web.
sub Init()
    m.scene = m.top.GetScene()
    m.fonts = m.global.fonts
    m.theme = m.global.appTheme
    m.homeConfig = m.global.homeConfig
    m.scene.callFunc("ShowHideLoader", false)

    m.rBackground = m.top.findNode("rBackground")
    m.pBackground = m.top.findNode("pBackground")
    m.logo = m.top.findNode("logo")
    m.lTitle = m.top.findNode("lTitle")
    m.bBack = m.top.findNode("bBack")
    m.lQrTitle = m.top.findNode("lQrTitle")
    m.lQrFooter = m.top.findNode("lQrFooter")

    m.rBackground.color = m.theme.clrPrimary
    m.lQrTitle.font = m.fonts.dmSansBold23
    m.lQrTitle.color = m.theme.black

    ' La web usa el SVG logo-13go-caja; Roku no dibuja SVG: el logo_invertido
    ' del feed de configuracion (el mismo de la bienvenida).
    logoImage = getValueFromProps(m.homeConfig, "logo_invertido", "")
    if not isNonEmptyString(logoImage) then logoImage = "pkg:/images/brand/logo_bienvenida.png"
    m.logo.uri = logoImage

    m.bBack.update({
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.white
        backgroundColor: "#8C8C8C"
        focusBackgroundColor: m.theme.focPrimary
        fontSize: "dmSansBold23"
        margin: 20
    })

    m.lQrFooter.drawingStyles = {
        "Normal": { "fontUri": "pkg:/fonts/DMSans-Bold.ttf", "fontSize": 23, "color": m.theme.white }
        "Link": { "fontUri": "pkg:/fonts/DMSans-Bold.ttf", "fontSize": 23, "color": m.theme.focPrimary }
    }
    m.lQrFooter.text = "<Normal>o entrando a </Normal><Link>13go.cl</Link>"

    ' titulo-1 (46px, bold) con los mismos cortes de linea que la web.
    m.lTitle.drawingStyles = {
        "Normal": { "fontUri": "pkg:/fonts/DMSans-Bold.ttf", "fontSize": 46, "color": m.theme.white }
    }
    m.lTitle.text = "<Normal>Suscríbete para</Normal>" + chr(10) + "<Normal>disfrutar de este y de</Normal>" + chr(10) + "<Normal>otros contenidos.</Normal>"

    OnBackgroundImageSet()
    ' Deep link a un contenido que el plan no incluye: esta es la pantalla lista.
    m.scene.callFunc("SignalLaunchReady", "content")
    m.top.observeField("focusedChild", "OnFocusedChild")
    SetFocus(m.bBack)
end sub

' state.bgImage (la imagen del contenido) o, si no viene, fondo_corporativo.
sub OnBackgroundImageSet()
    image = m.top.backgroundImage
    if not isNonEmptyString(image) then image = getValueFromProps(m.homeConfig, "fondo_corporativo", "")
    if not isNonEmptyString(image) then image = GlobalGet("backgroundImage")
    if isNonEmptyString(image) then m.pBackground.uri = image
end sub

' Foco inicial en "Volver", como el setFocus('btn-back') de la web.
sub OnFocusedChild()
    if m.top.hasFocus() then SetFocus(m.bBack)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "OK" AND m.bBack.hasFocus()
        m.scene.callFunc("CloseSuscribePage")
        return true
    end if
    ' Es el unico control: las flechas no llevan a otro lado (ni al sidebar,
    ' que esta oculto). Back lo maneja MainScene.
    if key = "up" OR key = "down" OR key = "left" OR key = "right" then return true
    return false
end function
