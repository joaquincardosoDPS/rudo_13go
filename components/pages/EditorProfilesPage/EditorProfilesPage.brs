sub Init()
    print "EditorProfilesPage Init "
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
    m.theme = m.global.appTheme
    m.selectedAccountOption = ""
    m.rawProfileItems = []
    m.profileItems = []
    m.avatarImagesById = {}
    m.avatarInfoById = {}
    m.avatarListItems = []
    m.defaultProfileUri = "pkg:/images/other/default_user.png"
    m.addProfileUri = "pkg:/images/other/addProfile.png"
    m.maxVisibleProfileColumns = 4
    m.isEditMode = false
end sub

sub SetControls()
    m.backgroundPanel = m.top.findNode("backgroundPanel")
    m.brandLogo = m.top.findNode("brandLogo")
    m.editProfilesButton = m.top.findNode("editProfilesButton")
    m.screenTitle = m.top.findNode("screenTitle")
    m.screenSubtitle = m.top.findNode("screenSubtitle")
    m.profilesMarkup = m.top.findNode("profilesMarkup")
    m.arrowleft = m.top.findNode("arrowleft")
    m.arrowright = m.top.findNode("arrowright")
    m.addEditProfilePopup = m.top.findNode("addEditProfilePopup")
end sub

sub SetupFonts()
    m.screenTitle.font = m.fonts.poppinsMedium29
    m.screenSubtitle.font = m.fonts.poppinsMedium24
end sub

sub SetupColor()
    m.backgroundPanel.color = m.theme.clrPrimary
    m.screenTitle.color = m.theme.white
    m.screenSubtitle.color = m.theme.clrSecondaryText
end sub

sub SetObservers()
    m.profilesMarkup.observeField("itemFocused", "onProfilesFocused")
    m.profilesMarkup.observeField("itemSelected", "onProfilesSelected")
    m.addEditProfilePopup.observeField("closeRequested", "OnAddEditProfilePopupCloseRequested")
    m.top.observeField("visible", "OnVisibleChange")
    m.top.observeField("focusedChild", "OnFocusedChild")
    m.brandLogo.observeField("loadStatus", "OnLogoLoadStatusChanged")
    logoImage = GlobalGet("logo")
    if isNonEmptyString(logoImage)
        m.brandLogo.uri = logoImage
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
        SetFocus(m.profilesMarkup)
    end if
end sub

sub OnFocusedChild()
    if m.top.hasFocus()
        focusRestored = RestoreFocus()
        if focusRestored = false
            SetFocus(m.profilesMarkup)
        end if
    end if
end sub

sub Initialize()
    m.scene.callFunc("ShowHideLoader", true)
    btnFields = {
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.white
        backgroundColor: m.theme.clrSecondary
        focusBorderImage: m.theme.filledBackGroundImage
        focusBackgroundColor: m.theme.focPrimary
        fontSize: "poppinsMedium24"
        margin: 20
    }
    m.editProfilesButton.update(btnFields)
    CallGetAvatarAPI()
    CallGetProfilesAPI()
    SetFocus(m.profilesMarkup)
end sub

sub CallGetAvatarAPI()
    m.GetAvatarAPI = CreateObject("roSGNode", "AuthAPIAction")
    m.GetAvatarAPI.functionName = "GetAllAvatar"
    m.GetAvatarAPI.ObserveField("result", "OnGetAvatarAPIResponse")
    m.GetAvatarAPI.control = "RUN"
end sub

sub OnGetAvatarAPIResponse(event as dynamic)
    response = event.getData()
    if isValid(response) AND isValid(response.data) AND isValid(response.data.data) AND isValid(response.data.data.data)
        avatarGroups = response.data.data.data
        avatarData = BuildAvatarData(avatarGroups)
        m.avatarImagesById = avatarData.avatarImagesById
        m.avatarInfoById = avatarData.avatarInfoById
        m.avatarListItems = avatarData.avatarListItems
        RebuildProfileItems()
    end if
end sub

sub CallGetProfilesAPI()
    m.GetProfilesAPI = CreateObject("roSGNode", "AuthAPIAction")
    m.GetProfilesAPI.functionName = "GetProfilesData"
    m.GetProfilesAPI.ObserveField("result", "OnGetProfilesAPIResponse")
    m.GetProfilesAPI.control = "RUN"
end sub

sub OnGetProfilesAPIResponse(event as dynamic)
    response = event.getData()
    if isValid(response) AND isValid(response.data) AND isValid(response.data.data) AND isValid(response.data.data.data)
        m.rawProfileItems = response.data.data.data
    end if
    m.scene.callFunc("ShowHideLoader", false)
    RebuildProfileItems()
end sub

sub RebuildProfileItems(focusIndex = invalid as dynamic)
    m.profileItems = []
    if isValid(m.rawProfileItems)
        for each itemAA in m.rawProfileItems
            m.profileItems.Push(NormalizeProfileData(itemAA))
        end for
    end if
    RefreshProfilesMarkup(focusIndex)
end sub

sub UpdateEditModeUI()
    if m.isEditMode
        m.editProfilesButton.update({
            buttonText: "Listo"
        })
        m.screenTitle.text = "Editar perfiles"
        m.screenTitle.translation = [0, 240]
        m.screenSubtitle.text = "Elige un perfil para editar"
        m.screenSubtitle.visible = true
        m.arrowleft.translation = "[315, 513]"
        m.arrowright.translation = "[1531, 513]"
    else
        m.editProfilesButton.update({
            buttonText: "Editar perfiles"
        })
        m.screenTitle.text = "Quien anda ahi?"
        m.screenTitle.translation = [0, 280]
        m.screenSubtitle.visible = false
        m.arrowleft.translation = "[315, 473]"
        m.arrowright.translation = "[1531, 473]"
    end if
end sub

sub ApplyProfilesMarkupLayout(totalItems as Integer)
    columnCount = totalItems
    if columnCount < 1
        columnCount = 1
    else if columnCount > m.maxVisibleProfileColumns
        columnCount = m.maxVisibleProfileColumns
    end if
    itemSize = m.profilesMarkup.itemSize
    itemSpacing = m.profilesMarkup.itemSpacing
    gridWidth = (columnCount * itemSize[0]) + ((columnCount - 1) * itemSpacing[0])
    m.profilesMarkup.numColumns = columnCount
    gridY = 370
    if m.isEditMode
        gridY = 410
    end if
    m.profilesMarkup.translation = [Int((1920 - gridWidth) / 2), gridY]
end sub

sub RefreshProfilesMarkup(focusIndex = invalid as dynamic)
    profileContent = BuildProfileContent()
    m.profilesMarkup.content = profileContent
    totalItems = profileContent.getChildCount()
    showNavigationArrows = totalItems > m.maxVisibleProfileColumns
    m.arrowleft.visible = showNavigationArrows
    m.arrowright.visible = showNavigationArrows
    if showNavigationArrows
        m.arrowleft.opacity = "0.6"
        m.arrowright.opacity = "1"
    end if
    ApplyProfilesMarkupLayout(totalItems)
    if focusIndex <> invalid AND focusIndex >= 0 AND focusIndex < totalItems
        m.profilesMarkup.jumpToItem = focusIndex
    else
        UpdateArrowState()
    end if
    AutoSelectDefaultProfileForDeepLink()
end sub

function BuildProfileContent() as Object
    profileContent = CreateObject("RoSGNode", "ContentNode")
    for each itemAA in m.profileItems
        itemData = {}
        itemData.Append(itemAA)
        itemData.showEditBadge = m.isEditMode
        profileContent.appendChild(CreateProfileNode(itemData))
    end for
    if m.profileItems.Count() < 4
        profileContent.appendChild(CreateProfileNode({
            id: "Agregar perfil"
            profileUri: m.addProfileUri
            profileName: "Agregar perfil"
            isAddProfile: true
            showEditBadge: m.isEditMode
        }))
    end if
    return profileContent
end function

function CreateProfileNode(itemData as Object) as Object
    itemContent = CreateObject("RoSGNode", "ContentNode")
    itemContent.id = itemData.id
    itemContent.AddFields(itemData)
    return itemContent
end function

function NormalizeProfileData(itemAA as Object) as Object
    normalizedItem = {}
    if isValid(itemAA) then normalizedItem.Append(itemAA)
    profileName = ""
    if normalizedItem.DoesExist("name_perfil") AND normalizedItem.name_perfil <> invalid then profileName = normalizedItem.name_perfil
    if profileName.Trim() = "" then profileName = "Nuevo perfil"
    profileUri = ""
    if normalizedItem.DoesExist("profileUri") AND normalizedItem.profileUri <> invalid then profileUri = normalizedItem.profileUri
    profileImages = invalid
    if profileUri.Trim() = "" AND normalizedItem.DoesExist("images") AND Type(normalizedItem.images) = "roAssociativeArray"
        profileImages = normalizedItem.images
    else if profileUri.Trim() = "" AND normalizedItem.DoesExist("avatar") AND normalizedItem.avatar <> invalid
        avatarId = normalizedItem.avatar
        normalizedItem.avatarId = avatarId
        if m.avatarImagesById.DoesExist(avatarId) then profileImages = m.avatarImagesById[avatarId]
        if m.avatarInfoById.DoesExist(avatarId) then normalizedItem.avatarType = m.avatarInfoById[avatarId].avatarType
    end if
    if profileUri.Trim() = ""
        profileUri = GetAvatarImageUri(profileImages)
        if profileUri = invalid then profileUri = ""
    end if
    if profileUri.Trim() = "" then profileUri = m.defaultProfileUri
    normalizedItem.profileName = profileName
    normalizedItem.profileUri = profileUri
    if not normalizedItem.DoesExist("avatarId") AND normalizedItem.DoesExist("avatar") AND normalizedItem.avatar <> invalid
        normalizedItem.avatarId = normalizedItem.avatar
    end if
    normalizedItem.Delete("isAddProfile")
    return normalizedItem
end function

function onProfilesFocused()
    UpdateArrowState()
end function

sub UpdateArrowState()
    if not m.arrowleft.visible OR not isValid(m.profilesMarkup.content)
        return
    end if

    focusedIndex = m.profilesMarkup.itemFocused
    lastIndex = m.profilesMarkup.content.getChildCount() - 1
    if focusedIndex <= 0
        m.arrowleft.opacity = "0.6"
    else
        m.arrowleft.opacity = "1"
    end if

    if focusedIndex >= lastIndex
        m.arrowright.opacity = "0.6"
    else
        m.arrowright.opacity = "1"
    end if
end sub

function onProfilesSelected(event as dynamic)
    selectedIndex = event.getData()
    m.selectedItem = m.profilesMarkup.content.getChild(selectedIndex)
    print "ProfilesPage : onProfilesSelected : selectedItem : " m.selectedItem
    if isValid(m.selectedItem)
        isAddProfile = false
        if m.selectedItem.hasField("isAddProfile")
            isAddProfile = m.selectedItem.isAddProfile
        end if
        if m.isEditMode
            if isAddProfile = true
                ShowAddEditProfilePopup()
            else
                ShowAddEditProfilePopup("edit", m.selectedItem.profileName, m.selectedItem.profileUri, selectedIndex)
            end if
        else if isAddProfile = true
            ShowAddEditProfilePopup()
        else
            ProfileData = {
                "profileId": m.selectedItem.id
                "profileUri": m.selectedItem.profileUri
                "profileName": m.selectedItem.profileName
            }
            GlobalSet("selectedProfileID", m.selectedItem.id)
            m.scene.ProfileData = ProfileData
            m.scene.callFunc("StartApp")
        end if
    end if
end function

sub AutoSelectDefaultProfileForDeepLink()
    if isValidDeeplinkingParams()
        if isValid(m.profilesMarkup.content) AND m.profilesMarkup.content.getChildCount() > 0
            m.profilesMarkup.itemSelected = 0
        end if
    end if
end sub

function isValidDeeplinkingParams() as boolean
    return isNonEmptyString(m.scene.deepLinkingContentId) AND isNonEmptyString(m.scene.deepLinkingMediaType) AND isValid(m.scene.deeplinkingData) AND isNonEmptyString(m.scene.deeplinkingData.episodeId)
end function

sub ShowAddEditProfilePopup(popupMode = "create" as String, profileName = "" as String, profileUri = "" as String, profileIndex = -1 as Integer)
    m.addEditProfilePopup.popupMode = popupMode
    if popupMode = "edit" AND isValid(m.selectedItem)
        m.addEditProfilePopup.profileId = m.selectedItem.id
        if m.selectedItem.hasField("avatarId")
            m.addEditProfilePopup.selectedAvatarId = m.selectedItem.avatarId
        else
            m.addEditProfilePopup.selectedAvatarId = ""
        end if
    else
        m.addEditProfilePopup.profileId = ""
        m.addEditProfilePopup.selectedAvatarId = ""
    end if
    m.addEditProfilePopup.avatarItems = m.avatarListItems
    m.addEditProfilePopup.profileName = profileName
    m.addEditProfilePopup.profileUri = profileUri
    m.addEditProfilePopup.profileIndex = profileIndex
    m.addEditProfilePopup.visible = true
    SetFocus(m.addEditProfilePopup)
end sub

sub HideAddEditProfilePopup()
    m.addEditProfilePopup.visible = false
    UpdateEditModeUI()
    SetFocus(m.profilesMarkup)
end sub

sub OnAddEditProfilePopupCloseRequested()
    if not m.addEditProfilePopup.closeRequested then return
    actionSucceeded = m.addEditProfilePopup.actionSucceeded
    HideAddEditProfilePopup()
    if actionSucceeded
        CallGetProfilesAPI()
    end if
end sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
    print " Page : EditorProfilesPage : onKeyEvent : key = " key " press = " press
    handled = false
    if press
        if m.addEditProfilePopup.visible
            return false
        end if
        if key = "OK"
            if m.editProfilesButton.hasFocus()
                m.isEditMode = not m.isEditMode
                UpdateEditModeUI()
                RefreshProfilesMarkup(m.profilesMarkup.itemFocused)
                handled = true
            end if
        else if key = "up"
            if m.profilesMarkup.hasFocus()
                SetFocus(m.editProfilesButton)
            end if
            handled = true
        else if key = "down"
            if m.editProfilesButton.hasFocus()
                SetFocus(m.profilesMarkup)
            end if
            handled = true
        else if key = "back"
            if m.isEditMode
                m.isEditMode = false
                UpdateEditModeUI()
                RefreshProfilesMarkup(m.profilesMarkup.itemFocused)
                handled = true
            end if
        end if
        return handled
    end if
End Function
