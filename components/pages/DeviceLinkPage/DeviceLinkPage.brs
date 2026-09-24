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
    m.deviceCode = ""
    m.userCode = ""
    ' m.global.homeConfig guarda la respuesta completa de /feed/configuracion
    ' (ver MainScene::OnGetConfigAPIResponse). logo_invertido es la caja naranja
    ' que usa esta pantalla en c13_reloaded (ConnectView.tsx), distinta del
    ' logo_blanco que usa el sidebar.
    m.homeConfig = m.global.homeConfig
end sub

sub SetControls()
    m.rBackground = m.top.findNode("rBackground")
    m.logo = m.top.findNode("logo")
    m.DeviceLinkTitleText = m.top.findNode("DeviceLinkTitleText")
    m.QrHintText = m.top.findNode("QrHintText")
    m.CodeHintText = m.top.findNode("CodeHintText")
    m.qrCode = m.top.findNode("qrCode")
    m.rDivider = m.top.findNode("rDivider")
    m.codeGroup = m.top.findNode("codeGroup")
    m.codeValueText = m.top.findNode("codeValueText")
    m.errorText = m.top.findNode("ErrorText")
    m.devicePollTimer = m.top.findNode("devicePollTimer")
    m.codeExpiryTimer = m.top.findNode("codeExpiryTimer")
    m.deviceLinkPreloader = m.top.findNode("deviceLinkPreloader")

    logoImage = getValueFromProps(m.homeConfig, "logo_invertido", "")
    if isNonEmptyString(logoImage)
        m.logo.uri = logoImage
    else
        m.logo.uri = "pkg:/images/brand/logo_bienvenida.png"
    end if
end sub

sub SetupFonts()
    m.DeviceLinkTitleText.font = m.fonts.dmSansBold48
    m.CodeHintText.font = m.fonts.dmSansBold23
    ' El código real se ve enorme (7vw ≈ 134px en 1920) - mucho más grande que
    ' cualquier tamaño ya registrado en FontManager, así que se arma un Font
    ' puntual acá en vez de agregar un dmSansBold130 de un solo uso.
    codeFont = CreateObject("roSGNode", "Font")
    codeFont.uri = "pkg:/fonts/DMSans-Bold.ttf"
    codeFont.size = 130
    m.codeValueText.font = codeFont
    m.errorText.font = m.fonts.dmSansMedium24
end sub

sub SetupColor()
    m.rBackground.color = m.theme.clrPrimary
    m.DeviceLinkTitleText.color = m.theme.white
    m.CodeHintText.color = m.theme.white
    m.codeValueText.color = m.theme.white
    m.errorText.color = m.theme.clrSecondaryText
end sub

sub SetObservers()
    m.devicePollTimer.ObserveField("fire", "CallDevicePairAPI")
    m.codeExpiryTimer.ObserveField("fire", "CallGetDeviceCodeAPI")
end sub

Sub SetBusySpinnerControls()
    m.deviceLinkPreloader.poster.uri = "pkg:/images/loader/small-loader.png"
    m.deviceLinkPreloader.poster.blendColor = m.theme.white
    m.deviceLinkPreloader.poster.width = 50
    m.deviceLinkPreloader.poster.height = 50
    ' codeGroup mide 912x350 (mismo tamaño que el bloque real del código)
    m.deviceLinkPreloader.translation = [(912 - m.deviceLinkPreloader.poster.width) / 2, (350 - m.deviceLinkPreloader.poster.height) / 2]
End Sub

sub Initialize()
    m.scene.callFunc("ShowHideLoader", false)
    hintStyles = {
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
    m.QrHintText.drawingStyles = hintStyles
    m.QrHintText.text = "<Normal>Escanea el código QR usando tu teléfono</Normal>" + chr(10) + "<Normal>o visita </Normal><Link>13go.cl/tv</Link>"
    CallGetDeviceCodeAPI()
end sub

' --- Paso 1: pedir un codigo de vinculacion ---------------------------------
sub CallGetDeviceCodeAPI()
    m.devicePollTimer.control = "stop"
    m.codeExpiryTimer.control = "stop"
    m.codeValueText.text = ""
    m.errorText.visible = false
    m.deviceLinkPreloader.visible = true
    if isValid(m.GetDeviceCodeAPI) then m.GetDeviceCodeAPI.control = "stop"
    m.GetDeviceCodeAPI = CreateObject("roSGNode", "AuthAPIAction")
    m.GetDeviceCodeAPI.functionName = "GetDeviceCode"
    m.GetDeviceCodeAPI.ObserveField("result", "OnGetDeviceCodeAPIResponse")
    m.GetDeviceCodeAPI.control = "RUN"
end sub

sub OnGetDeviceCodeAPIResponse(event as dynamic)
    response = event.getData()
    m.GetDeviceCodeAPI = invalid
    data = getValueFromProps(response, "data.data", invalid)
    userCode = getValueFromProps(data, "user_code", invalid)
    deviceCode = getValueFromProps(data, "device_code", "")
    if not isValid(userCode) OR not isNonEmptyString(deviceCode)
        ShowError("No pudimos generar el código. Vuelve a intentarlo más tarde.")
        return
    end if
    m.deviceCode = deviceCode
    m.userCode = userCode.ToStr()
    m.codeValueText.text = m.userCode
    m.deviceLinkPreloader.visible = false
    ' El QR lleva el codigo dentro, para que el telefono no tenga que tipearlo.
    m.qrCode.uri = m.config.qrLink + m.config.tvLinkUrl + "?code=" + m.userCode

    ' El gateway indica cada cuanto consultar y cuando vence el codigo.
    interval = convertToNumber(getValueFromProps(data, "interval", 5))
    if interval < 1 then interval = 5
    m.devicePollTimer.duration = interval
    m.devicePollTimer.control = "start"

    secondsToExpire = IsoUtcToEpoch(getValueFromProps(data, "expires", "")) - CreateObject("roDateTime").AsSeconds()
    if secondsToExpire < 10 then secondsToExpire = 300
    m.codeExpiryTimer.duration = secondsToExpire
    m.codeExpiryTimer.control = "start"

    CallDevicePairAPI()
end sub

' --- Paso 2: consultar si el usuario ya aprobo el dispositivo ---------------
sub CallDevicePairAPI()
    if not isNonEmptyString(m.deviceCode) then return
    if isValid(m.DevicePairAPI) then return ' hay una consulta en vuelo
    m.DevicePairAPI = CreateObject("roSGNode", "AuthAPIAction")
    m.DevicePairAPI.functionName = "VerifyDevice"
    m.DevicePairAPI.params = { "deviceCode": m.deviceCode }
    m.DevicePairAPI.ObserveField("result", "OnDevicePairAPIResponse")
    m.DevicePairAPI.control = "RUN"
end sub

sub OnDevicePairAPIResponse(event as dynamic)
    response = event.getData()
    print "DeviceLinkPage : OnDevicePairAPIResponse : " FormatJson(response)
    m.DevicePairAPI = invalid
    gateway = getValueFromProps(response, "data", invalid)
    ' Mientras el usuario no aprueba, el gateway responde status=error/message=pending.
    if getValueFromProps(gateway, "status", "") <> "success"
        return
    end if
    tokenData = getValueFromProps(gateway, "data", invalid)
    if not isNonEmptyString(getValueFromProps(tokenData, "access_token", ""))
        print "DeviceLinkPage : OnDevicePairAPIResponse : status=success pero sin access_token, se ignora"
        return
    end if
    print "DeviceLinkPage : OnDevicePairAPIResponse : dispositivo vinculado, access_token recibido"
    m.devicePollTimer.control = "stop"
    m.codeExpiryTimer.control = "stop"
    m.scene.callFunc("ShowHideLoader", true)

    authData = BuildAuthDataFromGateway(tokenData, m.deviceCode)
    m.registryManager.SaveAuthData(authData)
    GlobalSet("token", authData.accessToken)
    GlobalSet("userId", authData.userId)
    print "DeviceLinkPage : OnDevicePairAPIResponse : userId=" authData.userId " -> callFunc OnDeviceLinked"
    ' El resto (datos de usuario + suscripcion) lo resuelve MainScene, igual que
    ' en la web el setUserSession() dispara checkUserSession().
    m.scene.callFunc("OnDeviceLinked")
    print "DeviceLinkPage : OnDevicePairAPIResponse : volvio de callFunc OnDeviceLinked"
end sub

sub ShowError(message as string)
    m.deviceLinkPreloader.visible = false
    m.errorText.text = message
    m.errorText.visible = true
end sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
    print "Page : DeviceLinkPage : onKeyEvent : key = " key " press = " press
    return false
End Function
