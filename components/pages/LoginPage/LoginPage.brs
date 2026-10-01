' Login con correo y contrasena (PROVISORIA, hasta el mockup de Canal 13).
' Accion "login" del gateway de Rudo; con exito deja la sesion en el registry
' igual que la vinculacion (DeviceLinkPage) y MainScene sigue con el mismo
' camino (OnDeviceLinked: datos del usuario -> "Quien anda ahi?").
' Foco: 0 correo, 1 contrasena (foco virtual, la pagina tiene el foco real),
' 2 "Ingresar", 3 "Vincular con codigo QR" (foco real en el boton).
sub Init()
    m.scene = m.top.GetScene()
    m.fonts = m.global.fonts
    m.theme = m.global.appTheme
    m.homeConfig = m.global.homeConfig
    m.registryManager = CreateRegistryManager()
    m.scene.callFunc("ShowHideLoader", false)

    m.email = ""
    m.password = ""
    m.focusIndex = 0
    m.loginTask = invalid
    m.keyboardDialog = invalid
    m.editingField = ""

    m.rBackground = m.top.findNode("rBackground")
    m.pBackground = m.top.findNode("pBackground")
    m.logo = m.top.findNode("logo")
    m.lTitle = m.top.findNode("lTitle")
    m.lSubtitle = m.top.findNode("lSubtitle")
    m.lEmailTitle = m.top.findNode("lEmailTitle")
    m.lPasswordTitle = m.top.findNode("lPasswordTitle")
    m.pEmail = m.top.findNode("pEmail")
    m.pPassword = m.top.findNode("pPassword")
    m.lEmail = m.top.findNode("lEmail")
    m.lPassword = m.top.findNode("lPassword")
    m.lError = m.top.findNode("lError")
    m.bLogin = m.top.findNode("bLogin")
    m.bLink = m.top.findNode("bLink")
    m.lQrTitle = m.top.findNode("lQrTitle")
    m.lQrFooter = m.top.findNode("lQrFooter")

    m.rBackground.color = m.theme.clrPrimary
    backgroundImage = getValueFromProps(m.homeConfig, "fondo_corporativo", "")
    if not isNonEmptyString(backgroundImage) then backgroundImage = GlobalGet("backgroundImage")
    if isNonEmptyString(backgroundImage) then m.pBackground.uri = backgroundImage
    logoImage = getValueFromProps(m.homeConfig, "logo_invertido", "")
    if not isNonEmptyString(logoImage) then logoImage = "pkg:/images/brand/logo_bienvenida.png"
    m.logo.uri = logoImage

    m.lTitle.font = m.fonts.dmSansBold48
    m.lTitle.color = m.theme.white
    m.lSubtitle.font = m.fonts.dmSansMedium26
    m.lSubtitle.color = "#C8C8C8"
    for each label in [m.lEmailTitle, m.lPasswordTitle]
        label.font = m.fonts.dmSansBold23
        label.color = m.theme.white
    end for
    for each label in [m.lEmail, m.lPassword]
        label.font = m.fonts.dmSansMedium29
    end for
    m.lError.font = m.fonts.dmSansMedium24
    m.lError.color = "#FF6B6B"
    m.lQrTitle.font = m.fonts.dmSansBold23
    m.lQrTitle.color = m.theme.black
    m.lQrFooter.drawingStyles = {
        "Normal": { "fontUri": "pkg:/fonts/DMSans-Bold.ttf", "fontSize": 23, "color": m.theme.white }
        "Link": { "fontUri": "pkg:/fonts/DMSans-Bold.ttf", "fontSize": 23, "color": m.theme.focPrimary }
    }
    m.lQrFooter.text = "<Normal>regístrate en </Normal><Link>13go.cl</Link>"

    buttonStyle = {
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.white
        backgroundColor: "#8C8C8C"
        focusBackgroundColor: m.theme.focPrimary
        fontSize: "dmSansBold23"
        margin: 20
    }
    m.bLogin.update(buttonStyle)
    m.bLink.update(buttonStyle)

    RenderFields()
    m.top.observeField("focusedChild", "OnFocusedChild")
    ApplyFocus()
end sub

sub OnFocusedChild()
    ' Al volver a la pagina (ej. back desde la vinculacion) se repone el foco.
    if m.top.hasFocus() then ApplyFocus()
end sub

sub RenderFields()
    if m.email = ""
        m.lEmail.text = "nombre@correo.cl"
        m.lEmail.color = "#8C8C8C"
    else
        m.lEmail.text = m.email
        m.lEmail.color = m.theme.white
    end if
    if m.password = ""
        m.lPassword.text = "Tu contraseña"
        m.lPassword.color = "#8C8C8C"
    else
        m.lPassword.text = String(Len(m.password), Chr(8226))
        m.lPassword.color = m.theme.white
    end if
end sub

sub ApplyFocus()
    if m.focusIndex = 0
        m.pEmail.uri = "pkg:/images/login/input_pill_72_focus.9.png"
    else
        m.pEmail.uri = "pkg:/images/login/input_pill_72.9.png"
    end if
    if m.focusIndex = 1
        m.pPassword.uri = "pkg:/images/login/input_pill_72_focus.9.png"
    else
        m.pPassword.uri = "pkg:/images/login/input_pill_72.9.png"
    end if
    if m.focusIndex = 2
        SetFocus(m.bLogin)
    else if m.focusIndex = 3
        SetFocus(m.bLink)
    else if not m.top.hasFocus()
        m.top.setFocus(true)
    end if
end sub

sub ShowError(message as string)
    m.lError.text = message
    m.lError.visible = message <> ""
end sub

' ---- Teclado de Roku (StandardKeyboardDialog: con dictado por voz, requisito
' 4.12 de certificacion). Si el equipo no lo tiene, KeyboardDialog. ----
sub OpenKeyboard(field as string)
    m.editingField = field
    dialog = CreateObject("roSGNode", "StandardKeyboardDialog")
    if not isValid(dialog) then dialog = CreateObject("roSGNode", "KeyboardDialog")
    if not isValid(dialog) then return
    isPassword = field = "password"
    if isPassword
        dialog.title = "Contraseña"
        dialog.text = m.password
    else
        dialog.title = "Correo electrónico"
        dialog.text = m.email
    end if
    dialog.buttons = ["Aceptar", "Cancelar"]
    if dialog.hasField("keyboardDomain")
        if isPassword then dialog.keyboardDomain = "password" else dialog.keyboardDomain = "email"
    end if
    editBox = invalid
    if dialog.hasField("textEditBox") then editBox = dialog.textEditBox
    if not isValid(editBox) AND dialog.hasField("keyboard") AND isValid(dialog.keyboard) then editBox = dialog.keyboard.textEditBox
    if isValid(editBox) then editBox.secureMode = isPassword
    dialog.observeField("buttonSelected", "OnKeyboardButton")
    if dialog.hasField("wasClosed") then dialog.observeField("wasClosed", "OnKeyboardClosed")
    m.keyboardDialog = dialog
    m.scene.dialog = dialog
end sub

sub OnKeyboardButton()
    dialog = m.keyboardDialog
    if not isValid(dialog) then return
    if dialog.buttonSelected = 0
        value = dialog.text.Trim()
        if m.editingField = "password"
            m.password = dialog.text
        else
            m.email = LCase(value)
        end if
        ShowError("")
        RenderFields()
        ' Correo listo: pasa a la contrasena; contrasena lista: a "Ingresar".
        if m.editingField = "email" then m.focusIndex = 1 else m.focusIndex = 2
    end if
    CloseKeyboard()
end sub

sub OnKeyboardClosed()
    CloseKeyboard()
end sub

sub CloseKeyboard()
    if isValid(m.keyboardDialog)
        m.keyboardDialog.unobserveField("buttonSelected")
        if m.keyboardDialog.hasField("wasClosed") then m.keyboardDialog.unobserveField("wasClosed")
        m.keyboardDialog.close = true
        m.keyboardDialog = invalid
    end if
    m.editingField = ""
    ApplyFocus()
end sub

' ---- Ingreso ----
sub SubmitLogin()
    if isValid(m.loginTask) then return
    if m.email = "" OR m.password = ""
        ShowError("Ingresa tu correo y tu contraseña.")
        return
    end if
    ShowError("")
    m.scene.callFunc("ShowHideLoader", true)
    m.loginTask = CreateObject("roSGNode", "AuthAPIAction")
    m.loginTask.functionName = "Login"
    m.loginTask.params = { email: m.email, password: m.password }
    m.loginTask.observeField("result", "OnLoginResponse")
    m.loginTask.control = "RUN"
end sub

sub OnLoginResponse(event as dynamic)
    m.loginTask = invalid
    response = event.getData()
    gateway = getValueFromProps(response, "data", invalid)
    status = getValueFromProps(gateway, "status", "")
    ' Sin tokens ni contrasena en el log.
    print "LoginPage : login : status=" status " code=" getValueFromProps(gateway, "code", "")
    tokenData = NormalizeLoginTokens(getValueFromProps(gateway, "data", invalid))
    if status = "success" AND isValid(tokenData)
        m.password = ""
        authData = BuildAuthDataFromGateway(tokenData, "")
        m.registryManager.SaveAuthData(authData)
        GlobalSet("token", authData.accessToken)
        GlobalSet("userId", authData.userId)
        ' El loader sigue prendido: MainScene carga los datos y abre "Quien anda ahi?".
        m.scene.callFunc("OnDeviceLinked")
        return
    end if
    m.scene.callFunc("ShowHideLoader", false)
    code = getValueFromProps(gateway, "code", -1)
    if type(code) = "roString" OR type(code) = "String" then code = convertToNumber(code)
    if status = "success"
        print "LoginPage : login : success sin tokens reconocibles, claves: " FormatJson(KeysOf(getValueFromProps(gateway, "data", {})))
        ShowError("No se pudo iniciar sesión. Inténtalo de nuevo.")
    else if code = 2
        ShowError("Correo o contraseña incorrectos.")
    else if code = 1
        ShowError("Ingresa tu correo y tu contraseña.")
    else
        ShowError("No se pudo iniciar sesión. Revisa tu conexión e inténtalo de nuevo.")
    end if
end sub

' La respuesta exitosa de "login" no se pudo ver sin una cuenta real: se acepta la
' forma del gateway (access_token/refresh_token/user_id, como deviceToken y
' refreshToken) y la de Firebase (idToken/refreshToken/localId/expiresIn).
function NormalizeLoginTokens(data as dynamic) as dynamic
    if not isValid(data) OR type(data) <> "roAssociativeArray" then return invalid
    accessToken = getValueFromProps(data, "access_token", "")
    if accessToken = "" then accessToken = getValueFromProps(data, "id_token", "")
    if accessToken = "" then accessToken = getValueFromProps(data, "idToken", "")
    if accessToken = "" then return invalid
    userId = getValueFromProps(data, "user_id", "")
    if userId = "" then userId = getValueFromProps(data, "localId", "")
    if userId = "" then userId = getValueFromProps(data, "uid", "")
    refreshToken = getValueFromProps(data, "refresh_token", "")
    if refreshToken = "" then refreshToken = getValueFromProps(data, "refreshToken", "")
    expiresIn = getValueFromProps(data, "expires_in", "")
    if expiresIn = "" then expiresIn = getValueFromProps(data, "expiresIn", "3600")
    return {
        "access_token": accessToken
        "refresh_token": refreshToken
        "user_id": userId
        "token_type": getValueFromProps(data, "token_type", "Bearer")
        "expires_in": expiresIn
    }
end function

function KeysOf(aa as dynamic) as object
    keys = []
    if type(aa) = "roAssociativeArray" then keys = aa.Keys()
    return keys
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if isValid(m.keyboardDialog) then return false
    if key = "OK"
        if m.focusIndex = 0
            OpenKeyboard("email")
        else if m.focusIndex = 1
            OpenKeyboard("password")
        else if m.focusIndex = 2
            SubmitLogin()
        else if m.focusIndex = 3
            m.scene.callFunc("ShowDeviceLinkPage", false)
        end if
        return true
    end if
    if isValid(m.loginTask) then return key <> "back"
    if key = "down"
        if m.focusIndex < 2 then m.focusIndex = m.focusIndex + 1
    else if key = "up"
        if m.focusIndex >= 2
            m.focusIndex = 1
        else if m.focusIndex = 1
            m.focusIndex = 0
        end if
    else if key = "right"
        if m.focusIndex = 2 then m.focusIndex = 3
    else if key = "left"
        if m.focusIndex = 3 then m.focusIndex = 2
    else
        return false
    end if
    ApplyFocus()
    return true
end function
