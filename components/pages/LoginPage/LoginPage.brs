sub Init()
    print "LoginPage Init "
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
    m.scene.callFunc("ShowHideLoader", false)
    m.link = "Regístrate"

    ' TODO Remove this textValue
    m.lEmail = ""
    m.lPassword = ""

    m.errorLabel = invalid
    m.errorParent = invalid
end sub

sub SetControls()
    'Email
    m.lgloginEmail = m.top.findNode("lgloginEmail")
    m.logo = m.top.findNode("logo")
    m.rBackground = m.top.findNode("rBackground")
    m.loginEmailTitleText = m.top.findNode("loginEmailTitleText")
    m.bEmailField = m.top.findNode("bEmailField")
    m.emailPlaceholderText = m.top.findNode("emailPlaceholderText")
    m.continueButton = m.top.findNode("continueButton")
    m.registerLinkGroup = m.top.findNode("registerLinkGroup")
    m.registerText = m.top.findNode("registerText")
    m.registerFocusline = m.top.findNode("registerFocusline")

    'Password
    m.lgloginPassword = m.top.findNode("lgloginPassword")
    m.loginPasswordTitleText = m.top.findNode("loginPasswordTitleText")
    m.bPasswordField = m.top.findNode("bPasswordField")
    m.passwordPlaceholderText = m.top.findNode("passwordPlaceholderText")
    m.loginButton = m.top.findNode("loginButton")
    m.forgotPasswordPromptText = m.top.findNode("forgotPasswordPromptText")

    m.loginPreloader = m.top.findNode("loginPreloader")
end sub

sub SetupFonts()
    m.loginEmailTitleText.font = m.fonts.poppinsMedium29
    m.emailPlaceholderText.font = m.fonts.poppinsMedium24

    m.loginPasswordTitleText.font = m.fonts.poppinsMedium29
    m.passwordPlaceholderText.font = m.fonts.poppinsMedium24
    m.forgotPasswordPromptText.font = m.fonts.poppinsMedium24
end sub

sub SetupColor()
    m.rBackground.color = m.theme.clrPrimary
    m.loginEmailTitleText.color = m.theme.white
    m.loginPasswordTitleText.color = m.theme.white
    inputFields = {
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.black 'white
        backgroundColor: m.theme.clrPrimaryButton
        focusBorderImage: m.theme.filledBackGroundImage
        focusBackgroundColor: m.theme.focPrimary
        margin: 20
    }
    m.bEmailField.update(inputFields)
    m.bPasswordField.update(inputFields)
    btnFields = {
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.white
        backgroundColor: m.theme.clrPrimaryButton
        focusBorderImage: m.theme.filledBackGroundImage
        focusBackgroundColor: m.theme.focPrimary
        fontSize: "poppinsMedium24"
        margin: 20
    }
    m.continueButton.update(btnFields)
    m.loginButton.update(btnFields)
    m.emailPlaceholderText.color = m.theme.inputTextColor

    m.passwordPlaceholderText.color = m.theme.inputTextColor
    m.forgotPasswordPromptText.color = m.theme.white
    m.registerFocusline.blendColor = m.theme.focPrimary
end sub

sub SetObservers()
    m.top.observeField("visible", "OnVisibleChange")
    m.top.observeField("focusedChild", "OnFocusedChild")
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

sub UpdateRegisterFocus()
    m.registerFocusline.visible = m.registerText.hasFocus() OR m.registerText.IsInFocusChain()
end sub

sub UpdateRegisterLinkLayout()
    activeGroup = GetActiveLoginGroup()
    groupBounds = activeGroup.boundingRect()
    linkY = activeGroup.translation[1] + groupBounds.height + 20
    m.registerLinkGroup.translation = [708, linkY]
end sub

sub OnVisibleChange()
    if m.top.visible
        HideError()
        if m.lgloginPassword.visible
            SetFocus(m.bPasswordField)
        else
            SetFocus(m.bEmailField)
        end if
        UpdateRegisterLinkLayout()
        UpdateRegisterFocus()
    end if
end sub

sub OnFocusedChild()
    if m.top.hasFocus()
        focusRestored = RestoreFocus()
        if focusRestored = false
            if m.lgloginEmail.visible
                SetFocus(m.bEmailField)
                GetUserInfoForSignIn()
            else if m.lgloginPassword.visible
                SetFocus(m.bPasswordField)
            end if
        end if
        UpdateRegisterLinkLayout()
        UpdateRegisterFocus()
    end if
end sub

sub GetUserInfoForSignIn()
    m.store = CreateObject("roSGNode", "ChannelStore")
    ' Set sign-in context for RFI screen
    info = CreateObject("roSGNode", "ContentNode")
    info.addFields({ context: "signin" })
    m.store.requestedUserDataInfo = info
    ' Request user's email for sign-in
    m.store.requestedUserData = "email"
    m.store.command = "getUserData"
    m.store.ObserveField("userData", "OnGetChannelUserData")
end sub

function OnGetChannelUserData()
    if isValid(m.store) AND isValid(m.store.userData)
        if isValid(m.store.userData.email) AND isNonEmptyString(m.store.userData.email)
            m.lEmail = m.store.userData.email
            m.emailPlaceholderText.text = m.store.userData.email
        end if
    end if
end function

Sub SetBusySpinnerControls()
    m.loginPreloader.poster.uri = "pkg:/images/loader/small-loader.png"
    m.loginPreloader.poster.blendColor = m.theme.white
    m.loginPreloader.poster.width = 50
    m.loginPreloader.poster.height = 50
    codeBtnBondinRect = m.loginButton.boundingrect()
    m.loginPreloader.translation = [(codeBtnBondinRect.width - m.loginPreloader.poster.width) / 2, (codeBtnBondinRect.height - (m.loginPreloader.poster.height)) / 2] '[177, 31.5]
End Sub

sub Initialize()
    fontStyle = {
        "Normal": {
            "fontUri": "pkg:/fonts/Poppins-Medium.ttf"
            "fontSize": 24
            "color": m.theme.white
        }
        "Link": {
            "fontUri": "pkg:/fonts/Poppins-Medium.ttf"
            "fontSize": 24
            "color": m.theme.focPrimary
        }
    }
    m.registerText.drawingStyles = fontStyle
    m.registerText.text = "<Normal>¿No tienes cuenta?  </Normal><Link>" + m.link + "</Link>"
    UpdateRegisterLinkLayout()
    UpdateRegisterFocus()
end sub

Sub ShowDialogKeyboard(title as String, preEnteredText as String) as Object
    dialog = CreateObject("roSGNode", "StandardKeyboardDialog")
    dialog.buttons = [tr("OK"), tr("Cancel")]
    If title = "Email"
        event_to_trigger = "DialogKeyboardButtonSelectedForEmail"
        title = "Introduce tu dirección de correo electrónico"
        dialog.textEditBox.secureMode = false
    Else If title = "Password"
        event_to_trigger = "DialogKeyboardButtonSelectedForPassword"
        dialog.buttons = [tr("OK"), tr("Cancel"), tr("Show/Hide Password")]
        title = "Ingrese su Contraseña"
        dialog.textEditBox.secureMode = true
    End If
    dialog.title = title
    dialog.text = preEnteredText
    dialog.textEditBox.cursorPosition = Len(preEnteredText)
    dialog.observeField("buttonSelected", event_to_trigger)
    m.scene.dialog = dialog
End Sub

Sub DialogKeyboardButtonSelectedForEmail(event as Object)
    bIndex = event.GetData()
    If bIndex = 0
        m.top.enteredEmail = m.scene.dialog.text.trim()
        If(Len(m.top.enteredEmail) > 0)
            m.lEmail = m.top.enteredEmail
            m.emailPlaceholderText.color = m.theme.white
            m.emailPlaceholderText.text = m.top.enteredEmail
            m.bEmailField.backgroundColor = m.theme.selectedFieldColor
            HideError()
            SetFocus(m.continueButton)
        Else
            m.lEmail = ""
            m.emailPlaceholderText.text = ""
            m.emailPlaceholderText.text = "Correo electronico"
        End If
    End If
    m.scene.dialog.close = true
End Sub

Sub DialogKeyboardButtonSelectedForPassword(event as Object)
    bIndex = event.GetData()
    If bIndex = 0
        m.top.enteredPassword = m.scene.dialog.text.trim()
        If(Len(m.top.enteredPassword) > 0)
            m.lPassword = m.top.enteredPassword
            m.passwordPlaceholderText.text = String(Len(m.top.enteredPassword), "•")
            m.bPasswordField.backgroundColor = m.theme.selectedFieldColor
            HideError()
            SetFocus(m.loginButton)
        Else
            m.lPassword = ""
            m.passwordPlaceholderText.text = ""
            m.passwordPlaceholderText.text = "Pasword"
        End If
        m.scene.dialog.close = true
    Else If bIndex = 1
        m.scene.dialog.close = true
    Else If bIndex = 2
        If m.scene.dialog.textEditBox.secureMode = true
            m.scene.dialog.textEditBox.secureMode = false
        Else
            m.scene.dialog.textEditBox.secureMode = true
        End If
    End If
End Sub

Sub HandleOkEvent()
    If(m.bEmailField.hasFocus())
        ShowDialogKeyboard("Email", m.lEmail)
    Else If(m.bPasswordField.hasFocus())
        ShowDialogKeyboard("Password", m.lPassword)
    Else If(m.continueButton.hasFocus())
        validationResult = ValidateEmailStep()
        if isEmptyString(validationResult)
            HideError()
            m.lgloginEmail.visible = false
            m.lgloginPassword.visible = true
            UpdateRegisterLinkLayout()
            SetFocus(m.bPasswordField)
        else
            ShowError(validationResult)
        end if
    else if (m.loginButton.hasFocus())
        validationResult = ValidatePasswordStep()
        if isEmptyString(validationResult)
            HideError()
            params = {}
            if isValid(m.lEmail) AND m.lEmail.Trim() <> ""
                params["email"] = m.lEmail.Trim()
            end if
            if isValid(m.lPassword) AND m.lPassword.Trim() <> ""
                params["password"] = m.lPassword.Trim()
            end if
            CallLoginWithEmailPass(params)
        else
            ShowError(validationResult)
        end if
    else if m.registerText.hasFocus()
        m.scene.callFunc("ShowSignUpPage", false)
    End If
End Sub

Sub CallLoginWithEmailPass(params as dynamic)
    If isValid(m.loginTask)
        m.loginTask.control = "stop"
    End If
    m.loginTask = CreateObject("roSGNode", "AuthAPIAction")
    m.loginTask.params = params
    m.loginTask.functionName = "Login"
    m.loginTask.ObserveField("result", "OnLoginAPIResponse")
    m.loginTask.control = "RUN"
    m.loginButton.buttonText = ""
    m.loginPreloader.visible = true
End Sub

Sub OnLoginAPIResponse(event as dynamic)
    response = event.getData()
    print "OnLoginAPIResponse : response : " 'FormatJson(response)
    m.loginPreloader.visible = false
    m.loginButton.buttonText = "INGRESAR"
    If isValid(response) AND isValid(response.data) AND isValid(response.data.user) AND isValid(response.data.user.token) AND response.data.user.token <> ""
        m.registryManager.SaveUserData(response.data.user)
        GlobalSet("UserData", response.data.user)
        m.registryManager.SaveToken(response.data.user.token)
        GlobalSet("token", response.data.user.token)
        m.scene.isUserLoggedIn = true
        m.scene.callFunc("ShowEditorProfilesPage", true)
    Else
        if isValid(response) AND isValid(response.data) AND isNonEmptyString(response.data.msj)
            m.lErrorMsgText = response.data.msj
        else
            m.lErrorMsgText = "Algo salió mal, inténtalo de nuevo más tarde."
        end if
        ShowError(m.lErrorMsgText)
    End If
    m.loginTask = invalid
End Sub

function ValidateEmailStep() as object
    if isInvalid(m.lEmail) OR m.lEmail.Trim() = ""
        return "Ingresa un email válido"
    end if
    if IsValidEmail(m.lEmail) = false
        return "Ingresa un email válido"
    end if
    return ""
end function

function ValidatePasswordStep() as object
    if isInvalid(m.lPassword) OR m.lPassword.Trim() = ""
        return "Ingresa tu contraseña"
    end if
    if Len(m.lPassword.Trim()) < 6
        return "Contraseña incorrecta."
    end if
    return ""
end function

function IsValidEmail(email as string) as boolean
    trimmedEmail = email.Trim()
    if trimmedEmail = ""
        return false
    end if
    atPos = Instr(1, trimmedEmail, "@")
    dotPos = Instr(1, trimmedEmail, ".")
    if atPos <= 1 OR dotPos <= atPos + 1
        return false
    end if
    if dotPos >= Len(trimmedEmail)
        return false
    end if
    return true
end function

function GetActiveLoginGroup() as object
    if m.lgloginPassword.visible
        return m.lgloginPassword
    end if

    return m.lgloginEmail
end function

sub ShowError(message as string)
    parentGroup = GetActiveLoginGroup()

    if isInvalid(m.errorLabel)
        m.errorLabel = CreateObject("roSGNode", "Label")
        m.errorLabel.id = "errorLabel"
        m.errorLabel.width = 504
        m.errorLabel.horizAlign = "left"
        m.errorLabel.wrap = true
        m.errorLabel.font = m.fonts.poppinsMedium18
        m.errorLabel.color = m.theme.focPrimary
        parentGroup.insertChild(m.errorLabel, 2)
        m.errorParent = parentGroup
        UpdateRegisterLinkLayout()
    end if

    if isValid(m.errorParent) AND m.errorParent.id <> parentGroup.id
        m.errorParent.removeChild(m.errorLabel)
        parentGroup.insertChild(m.errorLabel, 2)
        m.errorParent = parentGroup
        UpdateRegisterLinkLayout()
    end if

    m.errorLabel.text = message
    UpdateRegisterLinkLayout()
end sub

sub HideError()
    if isValid(m.errorLabel)
        if isValid(m.errorParent)
            m.errorParent.removeChild(m.errorLabel)
        end if
        m.errorLabel = invalid
        m.errorParent = invalid
        UpdateRegisterLinkLayout()
    end if
end sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
    print "LoginPage : onKeyEvent : key = " key " press = " press
    handled = true
    if press
        if key = "OK"
            HandleOkEvent()
            handled = true
        else if key = "down"
            if m.lgloginEmail.visible AND (m.bEmailField.hasFocus() OR m.bEmailField.IsInFocusChain())
                SetFocus(m.continueButton)
            else if m.lgloginPassword.visible AND (m.bPasswordField.hasFocus() OR m.bPasswordField.IsInFocusChain())
                SetFocus(m.loginButton)
            else if m.continueButton.hasFocus() OR m.continueButton.IsInFocusChain()
                SetFocus(m.registerText)
            else if m.loginButton.hasFocus() OR m.loginButton.IsInFocusChain()
                SetFocus(m.registerText)
            end if
            UpdateRegisterFocus()
            handled = true
        else if key = "up"
            if m.registerText.hasFocus() OR m.registerText.IsInFocusChain()
                if m.lgloginEmail.visible
                    SetFocus(m.continueButton)
                else if m.lgloginPassword.visible
                    SetFocus(m.loginButton)
                end if
            else if ((m.continueButton.hasFocus() OR m.continueButton.IsInFocusChain()) OR (m.loginButton.hasFocus() OR m.loginButton.IsInFocusChain()))
                if m.lgloginEmail.visible
                    SetFocus(m.bEmailField)
                else if m.lgloginPassword.visible
                    SetFocus(m.bPasswordField)
                end if
            end if
            handled = true
            UpdateRegisterFocus()
        else if key = "back"
            if m.lgloginPassword.visible
                HideError()
                m.lgloginPassword.visible = false
                m.lgloginEmail.visible = true
                UpdateRegisterLinkLayout()
                SetFocus(m.continueButton)
                UpdateRegisterFocus()
                handled = true
            else
                handled = false
            end if
        end if
        return handled
    end if
End Function
