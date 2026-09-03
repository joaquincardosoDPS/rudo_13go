sub Init()
    print "SignUpPage Init "
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
    m.scene.callFunc("ShowHideLoader", false)
    m.registryManager = CreateRegistryManager()

    m.formData = {
        name: ""
        email: ""
        password: ""
    }
    m.currentStep = 1
    m.totalSteps = 3
    m.keyboardTarget = ""
end sub

sub SetControls()
    m.logo = m.top.findNode("logo")
    m.rBackground = m.top.findNode("rBackground")
    m.gSignUpFlow = m.top.findNode("gSignUpFlow")
    m.lgSignUpForm = m.top.findNode("lgSignUpForm")
    m.stepLabel = m.top.findNode("stepLabel")
    m.titleLabel = m.top.findNode("titleLabel")
    m.inputButton = m.top.findNode("inputButton")
    m.inputPlaceholderLabel = m.top.findNode("inputPlaceholderLabel")
    m.helperLabel = invalid
    m.errorLabel = invalid
    m.actionButton = m.top.findNode("actionButton")
    m.signupPreloader = m.top.findNode("signupPreloader")
    m.loginLinkGroup = m.top.findNode("loginLinkGroup")
    m.loginLinkText = m.top.findNode("loginLinkText")
    m.loginFocusline = m.top.findNode("loginFocusline")

    m.gSuccessState = m.top.findNode("gSuccessState")
    m.successLogo = m.top.findNode("successLogo")
    m.successTitle = m.top.findNode("successTitle")
    m.successSubtitle = m.top.findNode("successSubtitle")
    m.hideSucessScreenTimer = m.top.findNode("hideSucessScreenTimer")
end sub

sub SetupFonts()
    m.stepLabel.font = m.fonts.dmSansMedium24
    m.titleLabel.font = m.fonts.dmSansMedium29
    m.inputPlaceholderLabel.font = m.fonts.dmSansMedium24
    m.successTitle.font = m.fonts.dmSansMedium37
    m.successSubtitle.font = m.fonts.dmSansMedium23
end sub

sub SetupColor()
    m.rBackground.color = m.theme.clrPrimary
    m.stepLabel.color = m.theme.clrSecondaryText
    m.titleLabel.color = m.theme.white
    m.inputPlaceholderLabel.color = m.theme.clrSecondaryText
    m.successTitle.color = m.theme.focPrimary
    m.successSubtitle.color = m.theme.white
    m.loginFocusline.blendColor = m.theme.focPrimary

    inputFields = {
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.black
        backgroundColor: m.theme.clrPrimaryButton
        focusBorderImage: m.theme.filledBackGroundImage
        focusBackgroundColor: m.theme.focPrimary
        margin: 20
    }
    m.inputButton.update(inputFields)

    btnFields = {
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.white
        backgroundColor: m.theme.clrPrimaryButton
        focusBorderImage: m.theme.filledBackGroundImage
        focusBackgroundColor: m.theme.focPrimary
        fontSize: "dmSansMedium24"
        margin: 20
    }
    m.actionButton.update(btnFields)
end sub

sub SetObservers()
    m.top.observeField("visible", "OnVisibleChange")
    m.top.observeField("focusedChild", "OnFocusedChild")
    m.hideSucessScreenTimer.observeField("fire", "hideSucessScreen")
    m.logo.observeField("loadStatus", "OnLogoLoadStatusChanged")
    m.successLogo.observeField("loadStatus", "OnSuccessLogoLoadStatusChanged")
    logoImage = GlobalGet("logo")
    if isNonEmptyString(logoImage)
        m.logo.uri = logoImage
        m.successLogo.uri = logoImage
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

sub OnSuccessLogoLoadStatusChanged(event as object)
    status = event.GetData()
    node = event.getRoSGNode()
    if status = "ready"
        imageWidth = node.bitmapWidth
        imageHeight = node.bitmapHeight
        node.width = imageWidth * (node.height / imageHeight)
    end if
end sub

Sub SetBusySpinnerControls()
    m.signupPreloader.poster.uri = "pkg:/images/loader/small-loader.png"
    m.signupPreloader.poster.blendColor = m.theme.white
    m.signupPreloader.poster.width = 50
    m.signupPreloader.poster.height = 50
    codeBtnBondinRect = m.actionButton.boundingrect()
    m.signupPreloader.translation = [(codeBtnBondinRect.width - m.signupPreloader.poster.width) / 2, (codeBtnBondinRect.height - (m.signupPreloader.poster.height)) / 2] '[177, 31.5]
End Sub

sub GetUserInfoForSignUp()
    m.store = CreateObject("roSGNode", "ChannelStore")
    ' Request several properties for sign-up
    m.store.requestedUserData = "email, firstname, lastname"
    m.store.command = "getUserData"
    m.store.ObserveField("userData", "OnGetChannelUserData")
end sub

function OnGetChannelUserData()
    if isValid(m.store) AND isValid(m.store.userData)
        fullName = ""
        if isValid(m.store.userData.email) AND isNonEmptyString(m.store.userData.email)
            m.formData.email = m.store.userData.email
        end if
        if isValid(m.store.userData.firstname) AND isNonEmptyString(m.store.userData.firstname) then fullName = m.store.userData.firstname
        if isValid(m.store.userData.lastname) AND isNonEmptyString(m.store.userData.lastname)
            if fullName <> "" then fullName = fullName + " "
            fullName = fullName + m.store.userData.lastname
        end if
        if isNonEmptyString(fullName)
            m.formData.name = fullName
            m.inputPlaceholderLabel.text = m.formData["name"]
        end if
    end if
end function

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
    m.loginLinkText.drawingStyles = fontStyle
    m.loginLinkText.text = "<Normal>¿Ya tienes cuenta?  </Normal><Link>Inicio sesión</Link>"
    RefreshStepUI()
    UpdateLoginLinkLayout()
    UpdateLoginLinkFocus()
end sub

sub UpdateLoginLinkFocus()
    m.loginFocusline.visible = m.loginLinkText.hasFocus() OR m.loginLinkText.IsInFocusChain()
end sub

sub UpdateLoginLinkLayout()
    formBounds = m.lgSignUpForm.boundingRect()
    linkY = m.lgSignUpForm.translation[1] + formBounds.height + 20
    m.loginLinkGroup.translation = [708, linkY]
end sub

sub OnVisibleChange()
    if m.top.visible
        RefreshStepUI()
        UpdateLoginLinkLayout()
        UpdateLoginLinkFocus()
    end if
end sub

sub OnFocusedChild()
    if m.top.hasFocus()
        if m.gSuccessState.visible
            return
        end if
        focusRestored = RestoreFocus()
        if focusRestored = false
            GetUserInfoForSignUp()
            SetFocus(m.inputButton)
        end if
        UpdateLoginLinkLayout()
        UpdateLoginLinkFocus()
    end if
end sub

sub hideSucessScreen()
    m.hideSucessScreenTimer.control = "stop"
    m.scene.isUserLoggedIn = true
    m.scene.callFunc("ShowEditorProfilesPage", true)
end sub

sub RefreshStepUI()
    if m.gSuccessState.visible
        return
    end if
    config = GetStepConfig(m.currentStep)
    m.stepLabel.text = config.stepText
    m.titleLabel.text = config.title
    m.inputPlaceholderLabel.text = GetStepDisplayValue(m.currentStep)
    m.inputPlaceholderLabel.color = iif(HasStepValue(m.currentStep), m.theme.white, m.theme.inputTextColor)
    m.actionButton.buttonText = config.buttonText
    UpdateHelperLabel(config.helperText)
    UpdateInputButtonState()
    HideError()
    UpdateLoginLinkLayout()
end sub

sub UpdateInputButtonState()
    hasValue = HasStepValue(m.currentStep)
    isActionFocused = m.actionButton.hasFocus() OR m.actionButton.IsInFocusChain()

    if hasValue AND isActionFocused
        m.inputButton.backgroundColor = m.theme.selectedFieldColor
        m.inputPlaceholderLabel.color = m.theme.white
    else
        m.inputButton.backgroundColor = m.theme.clrPrimaryButton
        m.inputPlaceholderLabel.color = iif(hasValue, m.theme.white, m.theme.inputTextColor)
    end if
end sub

sub UpdateHelperLabel(helperText as string)
    if isInvalid(helperText) OR helperText = ""
        HideHelperLabel()
        return
    end if

    if isInvalid(m.helperLabel)
        m.helperLabel = CreateObject("roSGNode", "Label")
        m.helperLabel.width = 504
        m.helperLabel.horizAlign = "left"
        m.helperLabel.wrap = true
        m.helperLabel.font = m.fonts.dmSansMedium19
        m.helperLabel.color = m.theme.white
        m.lgSignUpForm.insertChild(m.helperLabel, 3)
        UpdateLoginLinkLayout()
    end if

    m.helperLabel.text = helperText
    UpdateLoginLinkLayout()
end sub

sub HideHelperLabel()
    if isValid(m.helperLabel)
        m.lgSignUpForm.removeChild(m.helperLabel)
        m.helperLabel = invalid
        UpdateLoginLinkLayout()
    end if
end sub

function GetStepConfig(stepIndex as integer) as object
    if stepIndex = 1
        return {
            stepText: "PASO 1 DE 3"
            title: "Ingresa tu nombre"
            placeholder: "Nombre de usuario"
            buttonText: "CONTINUAR"
            helperText: ""
            keyboardTitle: "Name"
        }
    else if stepIndex = 2
        return {
            stepText: "PASO 2 DE 3"
            title: "Ingresa tu correo electrónico"
            placeholder: "Correo electrónico"
            buttonText: "CONTINUAR"
            helperText: ""
            keyboardTitle: "Email"
        }
    end if

    return {
        stepText: "PASO 3 DE 3"
        title: "Crea una contraseña"
        placeholder: "Password"
        buttonText: "CREAR CUENTA"
        helperText: "Usa como mínimo 6 caracteres"
        keyboardTitle: "Password"
    }
end function

function GetStepFieldName(stepIndex as integer) as string
    if stepIndex = 1
        return "name"
    else if stepIndex = 2
        return "email"
    end if
    return "password"
end function

function GetStepDisplayValue(stepIndex as integer) as string
    config = GetStepConfig(stepIndex)
    fieldName = GetStepFieldName(stepIndex)
    value = m.formData[fieldName]

    if isInvalid(value) OR value = ""
        return config.placeholder
    end if

    if stepIndex = 3
        return String(Len(value), "•")
    end if

    return value
end function

function HasStepValue(stepIndex as integer) as boolean
    fieldName = GetStepFieldName(stepIndex)
    value = m.formData[fieldName]
    return isValid(value) AND value.Trim() <> ""
end function

sub HandleOkEvent()
    if m.gSuccessState.visible
        return
    end if

    if m.inputButton.hasFocus() OR m.inputButton.IsInFocusChain()
        ShowDialogKeyboard(m.currentStep)
    else if m.actionButton.hasFocus() OR m.actionButton.IsInFocusChain()
        HandlePrimaryAction()
    else if m.loginLinkText.hasFocus() OR m.loginLinkText.IsInFocusChain()
        m.scene.callFunc("ShowLoginPage", false)
    end if
end sub

sub HandlePrimaryAction()
    validationResult = ValidateCurrentStep()
    if isNonEmptyString(validationResult)
        ShowError(validationResult)
        return
    end if
    HideError()
    if m.currentStep < m.totalSteps
        m.lastStep = m.currentStep
        m.currentStep = m.currentStep + 1
        RefreshStepUI()
        SetFocus(m.inputButton)
    else
        CallSignUp(m.formData)
    end if
end sub

Sub CallSignUp(params as dynamic)
    If isValid(m.signupTask)
        m.signupTask.control = "stop"
    End If
    m.signupTask = CreateObject("roSGNode", "AuthAPIAction")
    m.signupTask.params = params
    m.signupTask.functionName = "SignUp"
    m.signupTask.ObserveField("result", "OnSignUpAPIResponse")
    m.signupTask.control = "RUN"
    m.actionButton.buttontext = ""
    m.signupPreloader.visible = true
End Sub

Sub OnSignUpAPIResponse(event as dynamic)
    response = event.getData()
    print "OnSignUpAPIResponse : response : " 'FormatJson(response)
    m.actionButton.buttontext = "CREAR CUENTA"
    m.signupPreloader.visible = false
    If isValid(response) AND isValid(response.data) AND isValid(response.data.user) AND isValid(response.data.user.token) AND response.data.user.token <> ""
        m.registryManager.SaveUserData(response.data.user)
        GlobalSet("UserData", response.data.user)
        m.registryManager.SaveToken(response.data.user.token)
        GlobalSet("token", response.data.user.token)
        ShowSuccessState()
    Else
        if isValid(response) AND isValid(response.data) AND isNonEmptyString(response.data.msj)
            m.lErrorMsgText = response.data.msj
        else
            m.lErrorMsgText = "Algo salió mal, inténtalo de nuevo más tarde."
        end if
        ShowError(m.lErrorMsgText)
    End If
    m.signupTask = invalid
End Sub

function ValidateCurrentStep() as object
    fieldName = GetStepFieldName(m.currentStep)
    value = m.formData[fieldName]
    if isInvalid(value) OR value.Trim() = ""
        config = GetStepConfig(m.currentStep)
        return {
            ok: false
            message: "Completa el campo " + LCase(config.placeholder)
        }
    end if
    if m.currentStep = 1 AND IsValidUserName(value) = false
        return "El nombre debe tener al menos 2 caracteres"
    end if
    if m.currentStep = 2 AND IsValidEmail(value) = false
        return "Ingresa un email válido"
    end if
    if m.currentStep = 3 AND Len(value) < 6
        return "La contraseña debe tener al menos 6 caracteres"
    end if
    return {
        ok: true
        message: ""
    }
end function

function IsValidUserName(userName as string) as boolean
    trimmedUserName = userName.Trim()
    if Len(trimmedUserName) < 2
        return false
    end if
    return true
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

sub ShowDialogKeyboard(stepIndex as integer)
    fieldName = GetStepFieldName(stepIndex)
    currentValue = m.formData[fieldName]

    dialog = CreateObject("roSGNode", "StandardKeyboardDialog")
    if stepIndex = 3
        dialog.buttons = [tr("OK"), tr("Cancel"), tr("Show/Hide Password")]
        dialog.textEditBox.secureMode = true
        dialog.observeField("buttonSelected", "DialogKeyboardButtonSelectedForPassword")
    else
        dialog.buttons = [tr("OK"), tr("Cancel")]
        dialog.textEditBox.secureMode = false
        dialog.observeField("buttonSelected", "DialogKeyboardButtonSelected")
    end if

    dialog.title = GetDialogTitle(stepIndex)
    dialog.text = currentValue
    dialog.textEditBox.cursorPosition = Len(currentValue)
    m.keyboardTarget = fieldName
    m.scene.dialog = dialog
end sub

function GetDialogTitle(stepIndex as integer) as string
    if stepIndex = 1
        return "Ingresa tu nombre"
    else if stepIndex = 2
        return "Introduce tu dirección de correo electrónico"
    end if
    return "Crea tu contraseña"
end function

sub DialogKeyboardButtonSelected(event as object)
    bIndex = event.GetData()
    if bIndex = 0
        SaveDialogValue(m.scene.dialog.text.Trim())
    end if
    m.scene.dialog.close = true
end sub

sub DialogKeyboardButtonSelectedForPassword(event as object)
    bIndex = event.GetData()
    if bIndex = 0
        SaveDialogValue(m.scene.dialog.text.Trim())
        m.scene.dialog.close = true
    else if bIndex = 1
        m.scene.dialog.close = true
    else if bIndex = 2
        isSecure = m.scene.dialog.textEditBox.secureMode
        m.scene.dialog.textEditBox.secureMode = not isSecure
    end if
end sub

sub SaveDialogValue(value as string)
    if m.keyboardTarget = ""
        return
    end if
    trimmedValue = value.Trim()
    m.formData[m.keyboardTarget] = trimmedValue
    if m.keyboardTarget = "name"
        m.top.enteredName = trimmedValue
    else if m.keyboardTarget = "email"
        m.top.enteredEmail = trimmedValue
    else if m.keyboardTarget = "password"
        m.top.enteredPassword = trimmedValue
    end if
    RefreshStepUI()
    SetFocus(m.actionButton)
    UpdateInputButtonState()
end sub

sub ShowSuccessState()
    ResetFocus()
    m.gSignUpFlow.visible = false
    m.gSuccessState.visible = true
    m.hideSucessScreenTimer.control = "start"
    HideHelperLabel()
    HideError()
end sub

sub ShowError(message as string)
    if isInvalid(m.errorLabel)
        m.errorLabel = CreateObject("roSGNode", "Label")
        m.errorLabel.width = 504
        m.errorLabel.horizAlign = "left"
        m.errorLabel.wrap = true
        m.errorLabel.font = m.fonts.dmSansMedium18
        m.errorLabel.color = m.theme.focPrimary
        m.lgSignUpForm.insertChild(m.errorLabel, 3)
    end if

    m.errorLabel.text = message
    UpdateLoginLinkLayout()
end sub

sub HideError()
    if isValid(m.errorLabel)
        m.lgSignUpForm.removeChild(m.errorLabel)
        m.errorLabel = invalid
        UpdateLoginLinkLayout()
    end if
end sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
    print "SignUpPage : onKeyEvent : key = " key " press = " press
    handled = true
    if press = false
        return handled
    end if
    if m.gSuccessState.visible
        if key = "back"
            handled = false
        end if
        return handled
    end if

    if key = "OK"
        HandleOkEvent()
        handled = true
    else if key = "down"
        if m.inputButton.hasFocus() OR m.inputButton.IsInFocusChain()
            SetFocus(m.actionButton)
            handled = true
        else if m.actionButton.hasFocus() OR m.actionButton.IsInFocusChain()
            SetFocus(m.loginLinkText)
            handled = true
        end if
        UpdateLoginLinkFocus()
    else if key = "up"
        if m.loginLinkText.hasFocus() OR m.loginLinkText.IsInFocusChain()
            SetFocus(m.actionButton)
            handled = true
        else if m.actionButton.hasFocus() OR m.actionButton.IsInFocusChain()
            SetFocus(m.inputButton)
        end if
        UpdateLoginLinkFocus()
        handled = true
    else if key = "back"
        if m.currentStep > 1
            m.currentStep = m.currentStep - 1
            RefreshStepUI()
            m.inputButton.backgroundColor = m.theme.selectedFieldColor
            m.inputPlaceholderLabel.color = m.theme.white
            SetFocus(m.inputButton)
            UpdateLoginLinkFocus()
            handled = true
        else
            handled = false
        end if
    end if

    return handled
End Function
