sub init()
    SetLocals()
    SetControls()
    SetupColor()
    SetupFonts()
    SetObservers()
    Initlization()
end sub

sub SetLocals()
    m.theme = m.global.appTheme
    m.fonts = m.global.Fonts
    m.scene = m.top.getScene()
    m.isMenuExpanded = false
    m.defaultProfileUri = "pkg:/images/other/default_user.png"
    m.addProfileUri = "pkg:/images/other/addProfile.png"
    m.rawProfileItems = []
    m.profileItems = []
    m.avatarImagesById = {}
    m.avatarInfoById = {}
    m.avatarListItems = []
    m.profileId = ""
    m.lastSelectedMenu = invalid
    m.shouldFallbackToFirstProfile = false
end sub

sub SetControls()
    m.pMyProfile = m.top.findNode("pMyProfile")
    m.pMyProfileBorder = m.top.findNode("pMyProfileBorder")
    m.pLogoImage = m.top.findNode("pLogoImage")
    m.mgMyProfile = m.top.findNode("mgMyProfile")
    m.lMyProfile = m.top.findNode("lMyProfile")
    m.gMyProfile = m.top.findNode("gMyProfile")
    m.bgProfilePopup = m.top.findNode("bgProfilePopup")
    m.loginButton = m.top.findNode("loginButton")
    m.topMenuGrid = m.top.findNode("topMenuGrid")
    m.lHidden = m.top.findNode("lHidden")
    m.pProfilePopup = m.top.findNode("pProfilePopup")
    m.gProfilePopup = m.top.findNode("gProfilePopup")
    m.lgProfileActions = m.top.findNode("lgProfileActions")
    m.profilePopupGrid = m.top.findNode("profilePopupGrid")
    m.addEditProfilePopup = m.top.findNode("addEditProfilePopup")
    m.gEditProfileAction = m.top.findNode("gEditProfileAction")
    m.gAccountAction = m.top.findNode("gAccountAction")
    m.gLogoutAction = m.top.findNode("gLogoutAction")
    m.lEditProfileAction = m.top.findNode("lEditProfileAction")
    m.lAccountAction = m.top.findNode("lAccountAction")
    m.lLogoutAction = m.top.findNode("lLogoutAction")
    m.lLogoutAction.text = "Cerrar sesión"
    maskSize = [m.mgMyProfile.BoundingRect().width, m.mgMyProfile.BoundingRect().height]
    if m.global.designresolution = "720p"
        maskSize = [maskSize[0] / 1.5, maskSize[1] / 1.5]
    end if
    m.mgMyProfile.maskSize = maskSize
end sub 

sub SetupColor()
    m.bgProfilePopup.blendColor = m.theme.black
    m.lMyProfile.color = m.theme.white
    m.pMyProfileBorder.blendColor = m.theme.white
    m.pProfilePopup.blendColor = m.theme.clrPrimary
    m.lEditProfileAction.color = m.theme.white
    m.lAccountAction.color = m.theme.white
    m.lLogoutAction.color = m.theme.white
end sub

sub SetupFonts()
    m.lMyProfile.font = m.fonts.dmSansMedium24
    m.lHidden.font = m.fonts.dmSansMedium24
    m.lEditProfileAction.font = m.fonts.dmSansMedium20
    m.lAccountAction.font = m.fonts.dmSansMedium20
    m.lLogoutAction.font = m.fonts.dmSansMedium20
end sub

sub SetObservers()
    m.top.observeField("focusedChild", "OnFocusChild")
    m.topMenuGrid.observeField("itemSelected", "OnItemSelected")
    m.scene.observeField("ProfileData", "OnMyProfileUriChanged")
    m.scene.observeField("isUserLoggedIn", "ChangeProfileOnLogin")
    m.profilePopupGrid.observeField("itemSelected", "OnProfilePopupItemSelected")
    m.addEditProfilePopup.observeField("closeRequested", "OnAddEditProfilePopupCloseRequested")
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

Sub ChangeProfileOnLogin()
    if m.scene.isUserLoggedIn = false
        m.gMyProfile.visible = false
        m.loginButton.visible = true
    end if
end sub

sub Initlization()
    if m.scene.isUserLoggedIn
        m.loginButton.visible = false
        m.gMyProfile.visible = true
        LoadProfiles()
    else
        ChangeProfileOnLogin()
    end if
    btnFields = {
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.white
        backgroundColor: m.theme.clrSecondary
        focusBorderImage: m.theme.filledBackGroundImage
        focusBackgroundColor: m.theme.focPrimary
        fontSize: "dmSansMedium24"
        margin: 20
    }
    m.loginButton.update(btnFields)
    menuList = m.global.menuList.items

    menuIcons = {
        "Portada": "pkg:/images/icons/sidebar/icon_home.png"
        "Programas": "pkg:/images/icons/sidebar/icon_vod.png"
        "En vivo": "pkg:/images/icons/sidebar/icon_live.png"
        "Radios": "pkg:/images/icons/sidebar/icon_radios.png"
        "Búsqueda": "pkg:/images/icons/sidebar/icon_search.png"
    }


    m.content = createObject("roSGNode", "ContentNode")
    for each menu in menuList
        menuContent = createObject("roSGNode", "MenuContent")
        menuContent.title = menu
        menuContent.isSelected = false
        iconUri = ""
        If menuIcons.DoesExist(menu) then iconUri = menuIcons[menu]
        menuContent.iconUri = iconUri
        m.content.appendChild(menuContent)
    end for
    SetupContent()
end sub

sub LoadProfiles()
    CallGetAvatarAPI()
    CallGetProfilesAPI()
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
    RebuildProfileItems()
    SyncSceneProfileData()
    OnMyProfileUriChanged()
end sub

sub RebuildProfileItems()
    m.profileItems = []
    if isValid(m.rawProfileItems)
        for each itemAA in m.rawProfileItems
            m.profileItems.Push(NormalizeProfileData(itemAA))
        end for
    end if
    RefreshProfilePopup()
end sub

function NormalizeProfileData(itemAA as Object) as Object
    normalizedItem = {}
    if isValid(itemAA)
        normalizedItem.Append(itemAA)
    end if

    profileName = ""
    if normalizedItem.DoesExist("name_perfil") AND normalizedItem.name_perfil <> invalid
        profileName = normalizedItem.name_perfil
    else if normalizedItem.DoesExist("Username") AND normalizedItem.Username <> invalid
        profileName = normalizedItem.Username
    end if
    if profileName.Trim() = "" then profileName = "Nuevo perfil"

    profileUri = ""
    if normalizedItem.DoesExist("profileUri") AND normalizedItem.profileUri <> invalid
        profileUri = normalizedItem.profileUri
    end if

    profileImages = invalid
    if profileUri.Trim() = "" AND normalizedItem.DoesExist("images") AND Type(normalizedItem.images) = "roAssociativeArray"
        profileImages = normalizedItem.images
    else if profileUri.Trim() = "" AND normalizedItem.DoesExist("avatar") AND normalizedItem.avatar <> invalid
        avatarId = normalizedItem.avatar
        normalizedItem.avatarId = avatarId
        if m.avatarImagesById.DoesExist(avatarId)
            profileImages = m.avatarImagesById[avatarId]
        end if
        if m.avatarInfoById.DoesExist(avatarId)
            normalizedItem.avatarType = m.avatarInfoById[avatarId].avatarType
        end if
    end if

    if profileUri.Trim() = ""
        profileUri = GetAvatarImageUri(profileImages)
        if profileUri = invalid
            profileUri = ""
        end if
    end if
    if profileUri.Trim() = ""
        profileUri = m.defaultProfileUri
    end if

    normalizedItem.profileName = profileName
    normalizedItem.profileUri = profileUri
    if not normalizedItem.DoesExist("avatarId") AND normalizedItem.DoesExist("avatar") AND normalizedItem.avatar <> invalid
        normalizedItem.avatarId = normalizedItem.avatar
    end if
    return normalizedItem
end function

sub RefreshProfilePopup()
    content = CreateObject("RoSGNode", "ContentNode")
    for each itemAA in m.profileItems
        if itemAA.id <> m.profileId
            content.appendChild(CreatePopupNode({
                id: itemAA.id
                title: itemAA.profileName
                profileUri: itemAA.profileUri
                showAvatar: true
                actionType: "profile"
            }))
        end if
    end for
    if m.profileItems.Count() < 4
        content.appendChild(CreatePopupNode({
            id: "Agregar perfil"
            title: "Agregar perfil"
            profileUri: m.addProfileUri
            showAvatar: true
            actionType: "addProfile"
        }))
    end if 
    m.profilePopupGrid.content = content
    ChangeProfilePopupSize()
end sub

sub ChangeProfilePopupSize()
    contentCount = m.profilePopupGrid.content.getChildCount()
    x = 30
    if contentCount > 0
        if contentCount = 1
            m.pProfilePopup.height = 229
            m.lgProfileActions.translation = [x, 104]
        else if contentCount = 2
            m.pProfilePopup.height = 307
            m.lgProfileActions.translation = [x, 182]
        else if contentCount >= 3
            m.pProfilePopup.height = 385
            m.lgProfileActions.translation = [x, 260]
        end if
    end if
end sub

function CreatePopupNode(itemAA as Object) as Object
    itemContent = CreateObject("RoSGNode", "ContentNode")
    itemContent.id = itemAA.id
    itemContent.AddFields(itemAA)
    return itemContent
end function

sub SyncSceneProfileData()
    if m.profileItems.Count() = 0
        return
    end if
    matchedProfile = invalid
    if isNonEmptyString(m.profileId)
        for each itemAA in m.profileItems
            if itemAA.id = m.profileId
                matchedProfile = itemAA
                exit for
            end if
        end for
    end if
    if matchedProfile <> invalid
        if m.scene.ProfileData.profileName <> matchedProfile.profileName OR m.scene.ProfileData.profileUri <> matchedProfile.profileUri
            m.scene.ProfileData = {
                profileId: matchedProfile.id
                profileName: matchedProfile.profileName
                profileUri: matchedProfile.profileUri
            }
            GlobalSet("selectedProfileID", matchedProfile.id)
        end if
    else if m.shouldFallbackToFirstProfile
        fallbackProfile = m.profileItems[0]
        m.scene.ProfileData = {
            profileId: fallbackProfile.id
            profileName: fallbackProfile.profileName
            profileUri: fallbackProfile.profileUri
        }
    end if
    m.shouldFallbackToFirstProfile = false
end sub

sub OnMyProfileUriChanged()
    if isValid(m.scene.ProfileData)
        if isNonEmptyString(m.scene.ProfileData.profileUri)
            m.pMyProfile.uri = m.scene.ProfileData.profileUri
        end if
        if isNonEmptyString(m.scene.ProfileData.profileName)
            m.lMyProfile.text = m.scene.ProfileData.profileName
        end if
        if isNonEmptyString(m.scene.ProfileData.profileId)
            m.profileId = m.scene.ProfileData.profileId
        end if
    end if
end sub

sub ToggleProfilePopup()
    if m.gProfilePopup.visible
        HideProfilePopup()
    else
        ShowProfilePopup()
    end if
end sub

sub ShowProfilePopup()
    RefreshProfilePopup()
    m.bgProfilePopup.visible = true
    m.gProfilePopup.visible = true
    SetFocus(m.profilePopupGrid)
end sub

sub HideProfilePopup()
    m.bgProfilePopup.visible = false
    m.gProfilePopup.visible = false
    UpdatePopupActionFocus()
    SetFocusOnLoginMyProfile(true)
end sub

sub OnProfilePopupItemSelected()
    m.selectedIndex = m.profilePopupGrid.itemSelected
    selectedItem = m.profilePopupGrid.content.getChild(m.selectedIndex)
    m.selectedItem = selectedItem
    actionType = ""
    if selectedItem.hasField("actionType")
        actionType = selectedItem.actionType
    end if
    if actionType = "profile"
        HideProfilePopup()
        SetFocusOnLoginMyProfile(false)
        UpdatePopupActionFocus()
        GlobalSet("selectedProfileID", selectedItem.id)
        m.scene.ProfileData = {
            profileId: selectedItem.id
            profileName: selectedItem.title
            profileUri: selectedItem.profileUri
        }
    else if actionType = "addProfile"
        ShowAddEditProfilePopup()
    end if
end sub

sub UpdatePopupActionFocus()
    actionGroups = [
        { group: m.gEditProfileAction, label: m.lEditProfileAction }
        { group: m.gAccountAction, label: m.lAccountAction }
        { group: m.gLogoutAction, label: m.lLogoutAction }
    ]
    for each item in actionGroups
        if item.group.hasFocus()
            item.label.color = m.theme.focPrimary
        else
            item.label.color = m.theme.white
        end if
    end for
end sub

function HandlePopupActionSelection(actionType as String)
    if isEmptyString(actionType) then return false
    HideProfilePopup()
    if actionType = "editProfile"
        currentProfile = GetCurrentProfileData()
        ShowAddEditProfilePopup("edit", currentProfile.profileName, currentProfile.profileUri, currentProfile.profileIndex, currentProfile.profileId, currentProfile.avatarId)
    else if actionType = "account"
        m.scene.callFunc("ShowAccountPage", false)
        SetFocusOnLoginMyProfile(false)
    else if actionType = "logout"
        m.scene.callFunc("OnLogout")
    end if
end function

function GetCurrentProfileData() as Object
    currentProfile = {
        profileId: m.profileId
        avatarId: ""
        profileName: m.lMyProfile.text
        profileUri: m.pMyProfile.uri
        profileIndex: -1
    }
    for i = 0 to m.profileItems.Count() - 1
        itemAA = m.profileItems[i]
        if isNonEmptyString(currentProfile.profileId) AND itemAA.id = currentProfile.profileId
            currentProfile.profileIndex = i
            if itemAA.DoesExist("avatarId")
                currentProfile.avatarId = itemAA.avatarId
            end if
            exit for
        else if itemAA.profileName = currentProfile.profileName AND itemAA.profileUri = currentProfile.profileUri
            currentProfile.profileIndex = i
            if itemAA.DoesExist("avatarId")
                currentProfile.avatarId = itemAA.avatarId
            end if
            exit for
        end if
    end for
    return currentProfile
end function

sub ShowAddEditProfilePopup(popupMode = "create" as String, profileName = "" as String, profileUri = "" as String, profileIndex = -1 as Integer, profileId = "" as String, avatarId = "" as String)
    m.addEditProfilePopup.popupMode = popupMode
    m.addEditProfilePopup.profileId = profileId
    m.addEditProfilePopup.selectedAvatarId = avatarId
    m.addEditProfilePopup.avatarItems = m.avatarListItems
    m.addEditProfilePopup.profileName = profileName
    m.addEditProfilePopup.profileUri = profileUri
    m.addEditProfilePopup.profileIndex = profileIndex
    m.addEditProfilePopup.visible = true
    SetFocus(m.addEditProfilePopup)
end sub

sub OnAddEditProfilePopupCloseRequested()
    if not m.addEditProfilePopup.closeRequested then return
    actionSucceeded = m.addEditProfilePopup.actionSucceeded
    profileAction = m.addEditProfilePopup.profileAction
    resultProfileData = m.addEditProfilePopup.resultProfileData
    m.addEditProfilePopup.visible = false
    HideProfilePopup()
    if actionSucceeded
        if isValid(resultProfileData) AND profileAction = "update" AND resultProfileData.profileId = m.profileId
            m.scene.ProfileData = {
                profileId: resultProfileData.profileId
                profileName: resultProfileData.profileName
                profileUri: resultProfileData.profileUri
            }
        else if isValid(resultProfileData) AND profileAction = "delete" AND resultProfileData.profileId = m.profileId
            ChangeProfilePopupSize()
            m.shouldFallbackToFirstProfile = true
        end if
        CallGetProfilesAPI()
    end if
    SetFocusOnLoginMyProfile(true)
end sub

sub OnFocusChild()
    if m.top.hasFocus()
        focusRestored = RestoreFocus()
        focusedNode = m.top.focusedChild
        if focusRestored = false
            if isValid(focusedNode) AND focusedNode.id <> "gMyProfile"
                SetFocusOnLoginMyProfile(false)
                if not m.gProfilePopup.visible AND not m.addEditProfilePopup.visible AND m.top.isInfocusChain()
                    setFocus(m.topMenuGrid)
                else if m.gProfilePopup.visible
                    UpdatePopupActionFocus()
                end if
            end if
        end if
        if isValid(focusedNode) AND focusedNode.id = "gMyProfile"
            SetFocusOnLoginMyProfile(true)
        end if
    end if
    isGridFocused = m.top.hasFocus() AND isValid(m.top.focusedChild) AND m.top.focusedChild.id = "topMenuGrid"
    SetMenuExpanded(isGridFocused)
end sub

sub SetMenuExpanded(expanded as boolean)
    if m.isMenuExpanded = expanded then return
    m.isMenuExpanded = expanded
    if isValid(m.content)
        for i = 0 to m.content.getChildCount() - 1
            m.content.getChild(i).isExpanded = expanded
        end for
    end if
end sub

sub SetupContent()
    m.topMenuGrid.content = m.content
    m.topMenuGrid.itemSelected = 0
end sub

sub OnItemSelected(event as dynamic)
    index = event.getData()
    UpdateSelectedTopMenu(index)
end sub

sub UpdateSelectedTopMenu(selectedIndex as integer, isFromMainScene = false as boolean)
    if isValid(m.topMenuGrid) AND isValid(m.topMenuGrid.content) AND m.topMenuGrid.content.getChildCount() > 0
        if selectedIndex < 0 OR selectedIndex >= m.topMenuGrid.content.getChildCount()
            return
        end if
        if m.lastSelectedMenu <> invalid then m.lastSelectedMenu.isSelected = false
        if isFromMainScene then m.lastSelectedMenu = invalid
        selectedNode = m.topMenuGrid.content.getChild(selectedIndex)
        if ((m.lastSelectedMenu = invalid) OR (isValid(m.lastSelectedMenu) AND isValid(m.lastSelectedMenu.title) AND isValid(selectedNode) AND isValid(selectedNode.title) AND m.lastSelectedMenu.title <> selectedNode.title))
            selectedNode.isSelected = true
            m.top.selectedItem = selectedNode
        end if
        m.lastSelectedMenu = selectedNode
    end if
end sub

sub SetFocusOnLoginMyProfile(isSet as boolean)
    if m.scene.isUserLoggedIn
        if isSet
            m.lMyProfile.color = m.theme.focPrimary
            m.pMyProfileBorder.blendColor = m.theme.focPrimary
            SetFocus(m.gMyProfile)
        else
            m.lMyProfile.color = m.theme.white
            m.pMyProfileBorder.blendColor = m.theme.white
        end if
    else
        if isSet
            SetFocus(m.loginButton)
        end if
    end if
    m.MyProfileLoginFocused = isSet
end sub

function onKeyEvent(key, press) as Boolean
    result = false
    if press
        print "TopMenu : onKeyEvent : key = " key " press = " press
        if m.addEditProfilePopup.visible
            if key = "back"
                m.addEditProfilePopup.closeRequested = true
                result = true
            end if
            return result
        end if
        if key = "right"
            if m.MyProfileLoginFocused = false
                SetFocusOnLoginMyProfile(true)
            end if
            result = true
        else if key = "left" AND (m.MyProfileLoginFocused = true OR (m.loginButton.hasFocus() OR m.loginButton.isInfocusChain())) AND m.gProfilePopup.visible = false
            SetFocusOnLoginMyProfile(false)
            SetFocus(m.topMenuGrid)
            result = true
        else if key = "OK"
            if m.gProfilePopup.visible
                if m.gEditProfileAction.hasFocus()
                    HandlePopupActionSelection("editProfile")
                else if m.gAccountAction.hasFocus()
                    HandlePopupActionSelection("account")
                else if m.gLogoutAction.hasFocus()
                    HandlePopupActionSelection("logout")
                else if (m.MyProfileLoginFocused = true)
                    ToggleProfilePopup()
                end if
                result = true
            else if (m.MyProfileLoginFocused = true)
                if m.scene.isUserLoggedIn
                    ToggleProfilePopup()
                    UpdatePopupActionFocus()
                else
                    m.scene.callFunc("ShowOnboardingPage", false)
                end if
                result = true
            end if
        else if key = "down" 
            if m.gProfilePopup.visible
                if m.profilePopupGrid.hasFocus()
                    SetFocus(m.gEditProfileAction)
                else if m.gEditProfileAction.hasFocus()
                    SetFocus(m.gAccountAction)
                else if m.gAccountAction.hasFocus()
                    SetFocus(m.gLogoutAction)
                end if
                UpdatePopupActionFocus()
                result = true
            else
                SetFocusOnLoginMyProfile(false)
            end if
        else if key = "up" AND m.gProfilePopup.visible
            if m.gLogoutAction.hasFocus()
                SetFocus(m.gAccountAction)
            else if m.gAccountAction.hasFocus()
                SetFocus(m.gEditProfileAction)
            else if m.gEditProfileAction.hasFocus()
                SetFocus(m.profilePopupGrid)
            end if
            UpdatePopupActionFocus()
            result = true
        else if key = "back" AND m.gProfilePopup.visible
            HideProfilePopup()
            result = true
        end if
    end if
    return result
end function
