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
    m.registryManager = CreateRegistryManager()
    m.rawProfileItems = invalid
    m.avatarBaseUrl = ""
    m.profileItems = []
    m.defaultProfileUri = "pkg:/images/other/default_user.png"
    m.maxVisibleProfileColumns = 4
    m.pendingRequests = 0
end sub

sub SetControls()
    m.backgroundPanel = m.top.findNode("backgroundPanel")
    m.brandLogo = m.top.findNode("brandLogo")
    m.logoutButton = m.top.findNode("logoutButton")
    m.screenTitle = m.top.findNode("screenTitle")
    m.profilesMarkup = m.top.findNode("profilesMarkup")
    m.emptyStateText = m.top.findNode("emptyStateText")
end sub

sub SetupFonts()
    m.screenTitle.font = m.fonts.dmSansBold48
    m.emptyStateText.font = m.fonts.dmSansMedium24
end sub

sub SetupColor()
    m.backgroundPanel.color = m.theme.clrPrimary
    m.screenTitle.color = m.theme.white
    m.emptyStateText.color = m.theme.clrSecondaryText
end sub

sub SetObservers()
    m.profilesMarkup.observeField("itemSelected", "onProfilesSelected")
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
        node.width = node.bitmapWidth * (node.height / node.bitmapHeight)
        node.translation = [(1920 - node.width) / 2, node.translation[1]]
    end if
end sub

sub OnVisibleChange()
    if m.top.visible then SetFocus(m.profilesMarkup)
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
    m.scene.callFunc("ShowHideMenu", false)
    m.scene.callFunc("ShowHideLoader", true)
    m.logoutButton.update({
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.clrSecondaryText
        backgroundColor: m.theme.clrSecondaryText
        focusBorderImage: "pkg:/images/focus/R5T3_35px_outborder_nopadding.9.png"
        focusBackgroundColor: m.theme.focPrimary
        fontSize: "dmSansMedium24"
        margin: 20
    })
    ' Las dos llamadas salen juntas (como el Promise.all de WhosThere.tsx);
    ' la grilla se arma recien cuando vuelven las dos.
    m.pendingRequests = 2
    CallGetAvatarBaseUrlAPI()
    CallGetProfilesAPI()
    SetFocus(m.profilesMarkup)
end sub

sub CallGetAvatarBaseUrlAPI()
    m.GetAvatarAPI = CreateObject("roSGNode", "AuthAPIAction")
    m.GetAvatarAPI.functionName = "GetAvatarBaseUrl"
    m.GetAvatarAPI.ObserveField("result", "OnGetAvatarBaseUrlAPIResponse")
    m.GetAvatarAPI.control = "RUN"
end sub

sub OnGetAvatarBaseUrlAPIResponse(event as dynamic)
    response = event.getData()
    print "EditorProfilesPage : OnGetAvatarBaseUrlAPIResponse : " FormatJson(response)
    m.GetAvatarAPI = invalid
    m.avatarBaseUrl = getValueFromProps(response, "data.data.url.stringValue", "")
    OnRequestFinished()
end sub

sub CallGetProfilesAPI()
    m.GetProfilesAPI = CreateObject("roSGNode", "AuthAPIAction")
    m.GetProfilesAPI.functionName = "GetProfilesData"
    m.GetProfilesAPI.ObserveField("result", "OnGetProfilesAPIResponse")
    m.GetProfilesAPI.control = "RUN"
end sub

sub OnGetProfilesAPIResponse(event as dynamic)
    response = event.getData()
    print "EditorProfilesPage : OnGetProfilesAPIResponse : " FormatJson(response)
    m.GetProfilesAPI = invalid
    m.rawProfileItems = getValueFromProps(response, "data.data", invalid)
    OnRequestFinished()
end sub

sub OnRequestFinished()
    m.pendingRequests = m.pendingRequests - 1
    print "EditorProfilesPage : OnRequestFinished : pendingRequests=" m.pendingRequests
    if m.pendingRequests > 0 then return
    m.scene.callFunc("ShowHideLoader", false)
    BuildProfileItems()
    RefreshProfilesMarkup()
end sub

' Cada perfil llega como documento de Firestore:
'   { fields: { order: {integerValue}, name: {stringValue}, avatar: {stringValue} } }
' y la imagen se arma como <urlBase><avatar>.jpg (igual que WhosThere.tsx).
sub BuildProfileItems()
    m.profileItems = []
    if not isNotEmptyArray(m.rawProfileItems) then return
    for each document in m.rawProfileItems
        fields = getValueFromProps(document, "fields", invalid)
        if not isValid(fields) then continue for
        order = FirestoreString(fields, "order", "0")
        avatarId = FirestoreString(fields, "avatar")
        profileName = FirestoreString(fields, "name")
        if profileName = "" then profileName = "Mi perfil"
        profileUri = m.defaultProfileUri
        if isNonEmptyString(m.avatarBaseUrl) AND isNonEmptyString(avatarId)
            profileUri = m.avatarBaseUrl + avatarId + ".jpg"
        end if
        m.profileItems.Push({
            id: order
            avatarId: avatarId
            profileName: profileName
            profileUri: profileUri
        })
    end for
end sub

sub RefreshProfilesMarkup()
    profileContent = CreateObject("RoSGNode", "ContentNode")
    for each itemAA in m.profileItems
        itemContent = CreateObject("RoSGNode", "ContentNode")
        itemContent.id = itemAA.id
        itemContent.AddFields(itemAA)
        profileContent.appendChild(itemContent)
    end for
    m.profilesMarkup.content = profileContent
    totalItems = profileContent.getChildCount()
    m.emptyStateText.visible = (totalItems = 0)
    ApplyProfilesMarkupLayout(totalItems)
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
    m.profilesMarkup.translation = [Int((1920 - gridWidth) / 2), 470]
end sub

sub onProfilesSelected(event as dynamic)
    selectedIndex = event.getData()
    if not isValid(m.profilesMarkup.content) then return
    selectedItem = m.profilesMarkup.content.getChild(selectedIndex)
    if not isValid(selectedItem) then return
    profileData = {
        "profileId": selectedItem.id
        "profileUri": selectedItem.profileUri
        "profileName": selectedItem.profileName
    }
    ' En la web esto es el localStorage "currentProfile" de ProfileItem.tsx.
    m.registryManager.SaveSelectedProfile(profileData)
    GlobalSet("selectedProfileID", selectedItem.id)
    m.scene.ProfileData = profileData
    m.scene.callFunc("StartApp")
end sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
    print " Page : EditorProfilesPage : onKeyEvent : key = " key " press = " press
    handled = false
    if press
        if m.logoutButton.hasFocus()
            ' Desde "Cerrar sesión" solo se puede bajar a los perfiles.
            if key = "OK"
                m.scene.callFunc("OnLogout")
                handled = true
            else if key = "down"
                SetFocus(m.profilesMarkup)
                handled = true
            else if key = "up" OR key = "left" OR key = "right"
                handled = true ' bloqueado a proposito (no hace nada)
            end if
        else if m.profilesMarkup.hasFocus()
            ' En los perfiles: arriba va al boton; izquierda/derecha SOLO
            ' llegan hasta aca cuando el MarkupGrid ya no puede moverse mas
            ' (primer/ultimo perfil) - se bloquean en vez de dejar que
            ' burbujeen a MainScene y salten al sidebar. Abajo no hace nada.
            if key = "up"
                SetFocus(m.logoutButton)
                handled = true
            else if key = "down" OR key = "left" OR key = "right"
                handled = true ' bloqueado a proposito (no hace nada)
            end if
        end if
    end if
    return handled
End Function
