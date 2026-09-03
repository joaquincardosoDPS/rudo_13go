sub Init()
    SetLocals()
    SetControls()
    SetupFonts()
    SetupColor()
    SetBusySpinnerControls()
    CreateBusySpinnerControls()
    SetObservers()
end sub

sub SetLocals()
    m.scene = m.top.GetScene()
    m.fonts = m.global.fonts
    m.theme = m.global.appTheme
    m.defaultProfileUri = "pkg:/images/other/default_user.png"
    m.profileName = ""
    m.profileUri = m.defaultProfileUri
    m.selectedAvatarId = ""
    m.lastFormFocusId = "profileNameButton"
    m.errorLabel = invalid
    m.buttonText = ""
end sub

sub SetControls()
    m.popupRoot = m.top.findNode("popupRoot")
    m.bgPopup = m.top.findNode("bgPopup")
    m.pLogoImage = m.top.findNode("pLogoImage")
    m.pageTitle = m.top.findNode("pageTitle")
    m.profileNameButton = m.top.findNode("profileNameButton")
    m.profileNameText = m.top.findNode("profileNameText")
    m.createProfileButton = m.top.findNode("createProfileButton")
    m.createProfilePreloader = m.top.findNode("createProfilePreloader")
    m.gDeleteProfile = m.top.findNode("gDeleteProfile")
    m.deleteProfileText = m.top.findNode("deleteProfileText")
    m.gAvatarPicker = m.top.findNode("gAvatarPicker")
    m.mgAvatar = m.top.findNode("mgAvatar")
    m.avatarBorder = m.top.findNode("avatarBorder")
    m.avatarIcon = m.top.findNode("avatarIcon")
    m.avatarList = m.top.findNode("avatarList")
    m.lgForm = m.top.findNode("lgForm")
    m.gDeleteProfilePopup = m.top.findNode("gDeleteProfilePopup")
    m.gDeleteConfirmation = m.top.findNode("gDeleteConfirmation")
    m.rdeleteDialogBg = m.top.findNode("rdeleteDialogBg")
    m.deleteDialogBg = m.top.findNode("deleteDialogBg")
    m.deleteDialogText = m.top.findNode("deleteDialogText")
    m.deleteDialogMeasureText = m.top.findNode("deleteDialogMeasureText")
    m.lgDeleteButtons = m.top.findNode("lgDeleteButtons")
    m.cancelDeleteButton = m.top.findNode("cancelDeleteButton")
    m.confirmDeleteButton = m.top.findNode("confirmDeleteButton")
    m.bsPreloader = m.top.findNode("bsPreloader")
    maskSize = [m.mgAvatar.BoundingRect().width, m.mgAvatar.BoundingRect().height]
    if m.global.designresolution = "720p"
        maskSize = [maskSize[0] / 1.5, maskSize[1] / 1.5]
    end if
    m.mgAvatar.maskSize = maskSize
end sub

sub SetupFonts()
    m.pageTitle.font = m.fonts.poppinsMedium29
    m.profileNameText.font = m.fonts.poppinsMedium24
    m.deleteProfileText.font = m.fonts.poppinsMedium24
    m.deleteDialogText.font = m.fonts.poppinsMedium25
    m.deleteDialogMeasureText.font = m.fonts.poppinsMedium25
end sub

sub SetupColor()
    m.bgPopup.color = m.theme.clrPrimary
    m.pageTitle.color = m.theme.white
    m.profileNameText.color = m.theme.clrSecondaryText
    m.deleteProfileText.color = m.theme.white
    m.deleteDialogText.color = m.theme.white
    m.deleteDialogMeasureText.color = m.theme.white
    m.rdeleteDialogBg.color = m.theme.clrSecondary
    m.deleteDialogBg.blendColor = m.theme.clrPrimary
    inputFields = {
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.black
        backgroundColor: m.theme.clrPrimaryButton
        focusBorderImage: m.theme.filledBackGroundImage
        focusBackgroundColor: m.theme.focPrimary
        fotnSize: "poppinsMedium24"
        margin: 18
    }
    m.profileNameButton.update(inputFields)

    btnFields = {
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.white
        backgroundColor: m.theme.clrSecondary
        focusBorderImage: m.theme.filledBackGroundImage
        focusBackgroundColor: m.theme.focPrimary
        fontSize: "poppinsMedium24"
        margin: 20
    }
    m.createProfileButton.update(btnFields)
    m.cancelDeleteButton.update(btnFields)
    m.confirmDeleteButton.update(btnFields)
    m.avatarBorder.blendColor = m.theme.white
    m.avatarIcon.uri = m.defaultProfileUri
end sub

Sub SetBusySpinnerControls()
    m.createProfilePreloader.poster.uri = "pkg:/images/loader/small-loader.png"
    m.createProfilePreloader.poster.blendColor = m.theme.white
    m.createProfilePreloader.poster.width = 50
    m.createProfilePreloader.poster.height = 50
    codeBtnBondinRect = m.createProfileButton.boundingrect()
    m.createProfilePreloader.translation = [(codeBtnBondinRect.width - m.createProfilePreloader.poster.width) / 2, (codeBtnBondinRect.height - (m.createProfilePreloader.poster.height)) / 2] '[177, 31.5]
End Sub

sub CreateBusySpinnerControls()
    m.bsPreloader.poster.uri = "pkg:/images/loader/loader.png"
    m.bsPreloader.poster.width = "160"
    m.bsPreloader.poster.height = "160"
end sub

sub SetObservers()
    m.top.observeField("visible", "OnVisibleChange")
    m.top.observeField("focusedChild", "OnFocusedChild")
    m.avatarList.observeField("closeRequested", "OnAvatarListCloseRequested")
    m.pLogoImage.observeField("loadStatus", "OnLogoLoadStatusChanged")
    logoImage = GlobalGet("logo")
    if isNonEmptyString(logoImage)
        m.pLogoImage.uri = logoImage
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

sub OnVisibleChange()
    if m.top.visible
        m.popupRoot.visible = true
        ApplyPopupState()
        SetFocus(m.profileNameButton)
    else
        m.popupRoot.visible = false
        HideError()
    end if
end sub

sub OnFocusedChild()
    if m.top.visible AND m.top.hasFocus()
        UpdateFocusState()
    end if
end sub

sub ResetPopup()
    m.top.closeRequested = false
    m.top.profileAction = ""
    m.top.actionSucceeded = false
    m.top.resultProfileData = {}
    m.profileName = ""
    m.profileUri = m.defaultProfileUri
    m.selectedAvatarId = ""
    m.top.enteredProfileName = ""
    m.top.enteredProfileUri = ""
    m.profileNameText.text = "Nombre del perfil"
    m.profileNameText.color = m.theme.inputTextColor
    m.profileNameButton.backgroundColor = m.theme.clrPrimaryButton
    m.pageTitle.text = "Agregar perfil"
    m.gDeleteProfile.visible = false
    m.gDeleteProfilePopup.visible = false
    m.avatarList.visible = false
    m.createProfileButton.update({
        buttonText: "CREAR PERFIL"
    })
    m.avatarIcon.uri = m.profileUri
    UpdateAvatarFocusStyle(false)
    UpdateDeleteActionFocus(false)
    HideError()
end sub

sub ApplyPopupState()
    ResetPopup()
    isEditMode = m.top.popupMode = "edit"
    if isEditMode
        m.pageTitle.text = "Editar perfil"
        m.gDeleteProfile.visible = true
        m.createProfileButton.update({
            buttonText: "GUARDAR CAMBIOS"
        })
    end if

    if m.top.profileName <> invalid AND m.top.profileName.Trim() <> ""
        m.profileName = m.top.profileName.Trim()
        m.top.enteredProfileName = m.profileName
        m.profileNameText.text = m.profileName
        m.profileNameText.color = m.theme.white
        m.profileNameButton.backgroundColor = m.theme.selectedFieldColor
        if m.top.profileName = "Default"
            m.gDeleteProfile.visible = false
        end if
    end if

    if m.top.profileUri <> invalid AND m.top.profileUri.Trim() <> ""
        m.profileUri = m.top.profileUri
        m.top.enteredProfileUri = m.profileUri
        m.avatarIcon.uri = m.profileUri
    end if

    if m.top.selectedAvatarId <> invalid AND m.top.selectedAvatarId <> ""
        ApplyAvatarSelectionById(m.top.selectedAvatarId)
    else if m.top.profileUri <> invalid AND m.top.profileUri.Trim() <> ""
        ApplyAvatarSelectionByUri(m.top.profileUri)
    else
        ApplyDefaultAvatarSelection()
    end if

    UpdateDeleteConfirmationText()
end sub

sub UpdateDeleteConfirmationText()
    profileDisplayName = m.profileName
    if profileDisplayName = invalid OR profileDisplayName.Trim() = ""
        profileDisplayName = "este perfil"
    end if
    m.deleteDialogText.text = "¿Quieres borrar el perfil " + profileDisplayName + "?"
    m.deleteDialogMeasureText.text = m.deleteDialogText.text
    UpdateDeleteConfirmationLayout()
end sub

sub UpdateDeleteConfirmationLayout()
    textHorizontalPadding = 150
    dialogMinWidth = 550
    dialogMaxWidth = 1500
    buttonRowWidth = 410
    brDeleteDialogText = m.deleteDialogMeasureText.boundingrect()
    dialogWidth = brDeleteDialogText.width + textHorizontalPadding
    if dialogWidth < dialogMinWidth
        dialogWidth = dialogMinWidth
    else if dialogWidth > dialogMaxWidth
        dialogWidth = dialogMaxWidth
    end if
    textWidth = dialogWidth - textHorizontalPadding
    m.deleteDialogText.width = textWidth
    brDeleteDialogText = m.deleteDialogText.boundingrect()
    textHeight = brDeleteDialogText.height
    if textHeight < 60 then textHeight = 60
    buttonsY = 30 + textHeight + 28
    dialogHeight = buttonsY + 70 + 50
    m.deleteDialogBg.width = dialogWidth
    m.deleteDialogBg.height = dialogHeight
    m.deleteDialogBg.translation = [0, 0]
    m.deleteDialogText.height = textHeight
    m.deleteDialogText.translation = [(dialogWidth - textWidth) / 2, 30]
    m.lgDeleteButtons.translation = [(dialogWidth - buttonRowWidth) / 2, buttonsY]
    m.gDeleteConfirmation.translation = [(1920 - dialogWidth) / 2, (1080 - dialogHeight) / 2]
end sub

sub UpdateFocusState()
    if m.profileNameButton.hasFocus()
        m.lastFormFocusId = "profileNameButton"
        UpdateAvatarFocusStyle(false)
        UpdateDeleteActionFocus(false)
    else if m.createProfileButton.hasFocus()
        m.lastFormFocusId = "createProfileButton"
        UpdateAvatarFocusStyle(false)
        UpdateDeleteActionFocus(false)
    else if m.gDeleteProfile.hasFocus()
        m.lastFormFocusId = "gDeleteProfile"
        UpdateAvatarFocusStyle(false)
        UpdateDeleteActionFocus(true)
    else if m.gAvatarPicker.hasFocus()
        UpdateAvatarFocusStyle(true)
        UpdateDeleteActionFocus(false)
    else
        UpdateAvatarFocusStyle(false)
        UpdateDeleteActionFocus(false)
    end if
end sub

sub UpdateAvatarFocusStyle(isFocused as boolean)
    if isFocused
        m.avatarBorder.blendColor = m.theme.focPrimary
        m.avatarBorder.visible = true
        m.avatarIcon.uri = m.profileUri
    else
        m.avatarBorder.visible = false
        m.avatarIcon.uri = m.profileUri
    end if
end sub

sub UpdateDeleteActionFocus(isFocused as boolean)
    if isFocused
        m.deleteProfileText.color = m.theme.focPrimary
    else
        m.deleteProfileText.color = m.theme.white
    end if
end sub

Sub ShowDialogKeyboard() as Object
    dialog = CreateObject("roSGNode", "StandardKeyboardDialog")
    dialog.buttons = [tr("OK"), tr("Cancel")]
    dialog.title = "Nombre del perfil"
    dialog.text = m.profileName
    dialog.textEditBox.secureMode = false
    dialog.textEditBox.cursorPosition = Len(m.profileName)
    dialog.observeField("buttonSelected", "DialogKeyboardButtonSelected")
    m.scene.dialog = dialog
End Sub

Sub DialogKeyboardButtonSelected(event as Object)
    buttonIndex = event.GetData()
    if buttonIndex = 0
        m.top.enteredProfileName = m.scene.dialog.text.Trim()
        if Len(m.top.enteredProfileName) > 0
            m.profileName = m.top.enteredProfileName
            m.profileNameText.text = m.profileName
            m.profileNameText.color = m.theme.white
            m.profileNameButton.backgroundColor = m.theme.selectedFieldColor
            HideError()
            SetFocus(m.createProfileButton)
        else
            m.profileName = ""
            m.profileNameText.text = "Nombre del perfil"
            m.profileNameText.color = m.theme.inputTextColor
            m.profileNameButton.backgroundColor = m.theme.clrPrimaryButton
        end if
    end if
    m.scene.dialog.close = true
End Sub

sub HandleOkEvent()
    if m.gDeleteProfilePopup.visible
        if m.cancelDeleteButton.hasFocus()
            HideDeleteConfirmation()
        else if m.confirmDeleteButton.hasFocus()
            SubmitProfileAction("delete")
        end if
    else if m.avatarList.visible
        return
    else if m.profileNameButton.hasFocus()
        ShowDialogKeyboard()
    else if m.createProfileButton.hasFocus()
        if ValidateProfileName()
            HideError()
            m.top.enteredProfileName = m.profileName
            m.top.enteredProfileUri = m.profileUri
            if m.top.popupMode = "edit"
                SubmitProfileAction("update")
            else
                SubmitProfileAction("add")
            end if
        else
            ShowError("Completa el nombre del perfil")
        end if
    else if m.gAvatarPicker.hasFocus()
        ShowAvatarList()
    else if m.gDeleteProfile.hasFocus()
        ShowDeleteConfirmation()
    end if
end sub

sub ShowDeleteConfirmation()
    UpdateDeleteConfirmationText()
    m.gDeleteConfirmation.visible = true
    m.gDeleteProfilePopup.visible = true
    HideError()
    SetFocus(m.cancelDeleteButton)
end sub

sub HideDeleteConfirmation()
    m.gDeleteProfilePopup.visible = false
    SetFocus(m.gDeleteProfile)
end sub

sub ShowAvatarList()
    if not isValid(m.top.avatarItems) OR m.top.avatarItems.Count() = 0
        ShowError("No hay avatars disponibles")
        return
    end if
    m.avatarList.avatarItems = m.top.avatarItems
    m.avatarList.selectedAvatarId = m.selectedAvatarId
    m.avatarList.selectionConfirmed = false
    m.avatarList.closeRequested = false
    m.avatarList.visible = true
    HideError()
    SetFocus(m.avatarList)
end sub

sub HideAvatarList()
    m.avatarList.visible = false
    SetFocus(m.gAvatarPicker)
    UpdateFocusState()
end sub

sub OnAvatarListCloseRequested()
    if not m.avatarList.closeRequested
        return
    end if
    HideAvatarList()
    if m.avatarList.selectionConfirmed AND isValid(m.avatarList.selectedAvatar)
        selectedAvatar = m.avatarList.selectedAvatar
        m.selectedAvatarId = selectedAvatar.id
        m.top.selectedAvatarId = m.selectedAvatarId
        if selectedAvatar.profileUri <> invalid AND selectedAvatar.profileUri <> ""
            m.profileUri = selectedAvatar.profileUri
            m.top.enteredProfileUri = m.profileUri
            m.avatarIcon.uri = m.profileUri
        end if
    end if
    m.avatarList.closeRequested = false
    m.avatarList.selectionConfirmed = false
end sub

sub ApplyAvatarSelectionById(avatarId as String)
    if avatarId = invalid OR avatarId = ""
        return
    end if

    avatarItems = m.top.avatarItems
    if not isValid(avatarItems)
        return
    end if

    for each itemAA in avatarItems
        if itemAA.id = avatarId
            m.selectedAvatarId = avatarId
            m.top.selectedAvatarId = avatarId
            if itemAA.profileUri <> invalid AND itemAA.profileUri <> ""
                m.profileUri = itemAA.profileUri
                m.top.enteredProfileUri = m.profileUri
                m.avatarIcon.uri = m.profileUri
            end if
            exit for
        end if
    end for
end sub

sub ApplyAvatarSelectionByUri(profileUri as String)
    avatarItems = m.top.avatarItems
    if not isValid(avatarItems)
        return
    end if

    for each itemAA in avatarItems
        if itemAA.profileUri = profileUri
            ApplyAvatarSelectionById(itemAA.id)
            exit for
        end if
    end for
end sub

sub ApplyDefaultAvatarSelection()
    avatarItems = m.top.avatarItems
    if isValid(avatarItems) AND avatarItems.Count() > 0
        ApplyAvatarSelectionById(avatarItems[0].id)
    end if
end sub

function ValidateProfileName() as boolean
    if isInvalid(m.profileName) OR m.profileName.Trim() = ""
        return false
    end if
    return true
end function

sub ShowError(message as string)
    if isInvalid(m.errorLabel)
        m.errorLabel = CreateObject("roSGNode", "Label")
        m.errorLabel.id = "errorLabel"
        m.errorLabel.width = 600
        m.errorLabel.wrap = true
        m.errorLabel.horizAlign = "left"
        m.errorLabel.font = m.fonts.poppinsMedium18
        m.errorLabel.color = m.theme.focPrimary
        m.lgForm.appendChild(m.errorLabel)
    end if

    m.errorLabel.text = message
end sub

sub HideError()
    if isValid(m.errorLabel)
        m.lgForm.removeChild(m.errorLabel)
        m.errorLabel = invalid
    end if
end sub

sub SubmitProfileAction(action as String)
    if action <> "delete" AND (m.selectedAvatarId = invalid OR m.selectedAvatarId = "")
        ApplyDefaultAvatarSelection()
    end if
    params = {}
    if action = "add"
        params = {
            name_perfil: m.profileName
            avatar: m.selectedAvatarId
        }
    else if action = "update"
        params = {
            id: m.top.profileId
            name_perfil: m.profileName
            avatar: m.selectedAvatarId
        }
    else if action = "delete"
        params = {
            id: m.top.profileId
        }
    else
        return
    end if
    HideError()
    if action = "delete"
        m.gDeleteConfirmation.visible = false
        m.bsPreloader.visible = true
    else
        m.buttonText = m.createProfileButton.buttonText
        m.createProfileButton.buttonText = ""
        m.createProfilePreloader.visible = true
    end if
    m.ProfileManagementAPI = CreateObject("roSGNode", "AuthAPIAction")
    m.ProfileManagementAPI.functionName = "ProfileManagement"
    m.ProfileManagementAPI.action = action
    m.ProfileManagementAPI.params = params
    m.ProfileManagementAPI.ObserveField("result", "OnProfileManagementResponse")
    m.ProfileManagementAPI.control = "RUN"
end sub

sub OnProfileManagementResponse(event as dynamic)
    response = event.getData()
    node = event.getRoSGNode()
    responseData = getValueFromProps(response, "data", {})
    responseData = getValueFromProps(responseData, "data", responseData)
    if node.action = "add" OR node.action = "update" then m.createProfileButton.buttonText = m.buttonText
    m.createProfilePreloader.visible = false
    if m.gDeleteProfilePopup.visible then m.gDeleteProfilePopup.visible = false
    m.bsPreloader.visible = false
    if getValueFromProps(responseData, "status", "") = "ok"
        ClosePopup(node.action, true, BuildResultProfileData(node.action, responseData))
    else
        ShowError("No se pudo guardar el perfil")
        SetFocus(m.createProfileButton)
    end if
end sub

function BuildResultProfileData(action as String, responseData = {} as dynamic) as Object
    profileId = m.top.profileId
    if action = "add"
        responseProfileId = getValueFromProps(responseData, "id", "")
        if responseProfileId <> invalid AND responseProfileId <> ""
            profileId = responseProfileId
        end if
    end if
    return {
        profileId: profileId
        profileIndex: m.top.profileIndex
        profileName: m.top.enteredProfileName
        profileUri: m.top.enteredProfileUri
        avatarId: m.selectedAvatarId
    }
end function

sub ClosePopup(action = "" as String, succeeded = false as Boolean, resultProfileData = invalid as dynamic)
    if resultProfileData = invalid
        resultProfileData = {}
    end if
    m.top.profileAction = action
    m.top.actionSucceeded = succeeded
    m.top.resultProfileData = resultProfileData
    m.top.closeRequested = true
end sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false
    if press AND m.top.visible
        if m.avatarList.visible
            if key = "back"
                m.avatarList.selectionConfirmed = false
                m.avatarList.closeRequested = true
                handled = true
            end if
        else if m.gDeleteProfilePopup.visible
            if key = "OK"
                HandleOkEvent()
                handled = true
            else if key = "left"
                if m.confirmDeleteButton.hasFocus()
                    SetFocus(m.cancelDeleteButton)
                    handled = true
                end if
            else if key = "right"
                if m.cancelDeleteButton.hasFocus()
                    SetFocus(m.confirmDeleteButton)
                    handled = true
                end if
            else if key = "back"
                HideDeleteConfirmation()
                handled = true
            end if
        else if key = "OK"
            HandleOkEvent()
            handled = true
        else if key = "down"
            if m.profileNameButton.hasFocus()
                SetFocus(m.createProfileButton)
            else if m.createProfileButton.hasFocus() AND m.gDeleteProfile.visible
                SetFocus(m.gDeleteProfile)
            end if
            handled = true
        else if key = "up"
            if m.createProfileButton.hasFocus()
                SetFocus(m.profileNameButton)
                handled = true
            else if m.gDeleteProfile.hasFocus()
                SetFocus(m.createProfileButton)
                handled = true
            end if
        else if key = "right"
            if m.profileNameButton.hasFocus() OR m.createProfileButton.hasFocus() OR m.gDeleteProfile.hasFocus()
                SetFocus(m.gAvatarPicker)
                handled = true
            end if
        else if key = "left"
            if m.gAvatarPicker.hasFocus()
                if m.lastFormFocusId = "gDeleteProfile"
                    SetFocus(m.gDeleteProfile)
                else if m.lastFormFocusId = "createProfileButton"
                    SetFocus(m.createProfileButton)
                else
                    SetFocus(m.profileNameButton)
                end if
                handled = true
            end if
        else if key = "back"
            ClosePopup()
            handled = true
        end if
        UpdateFocusState()
    end if
    return handled
End Function
