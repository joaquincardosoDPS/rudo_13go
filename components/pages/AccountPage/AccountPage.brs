' "Mi Cuenta" calcada de AccountView.tsx + use-account-data.ts de c13_reloaded.
' Foco virtual sobre gProfiles (mismo patron que RadioPage/SearchPage): la fila
' de avatares y la fila de botones "editar" debajo; "Cerrar Sesión" si recibe
' foco real, para que CustomButton pinte su estado enfocado.
sub Init()
    print "AccountPage Init "
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
    m.defaultProfileUri = "pkg:/images/other/default_user.png"
    m.profiles = []
    m.profileNodes = []
    m.avatarBaseUrl = ""
    m.rawProfileItems = invalid
    m.subscription = invalid
    m.pendingRequests = 0
    m.isLoaded = false
    m.reloading = false
    ' "profiles" | "edit" | "logout"
    m.focusArea = "profiles"
    m.focusIndex = 0
end sub

sub SetControls()
    m.gContent = m.top.findNode("gContent")
    m.lTitle = m.top.findNode("lTitle")
    m.lPersonalHeader = m.top.findNode("lPersonalHeader")
    m.lName = m.top.findNode("lName")
    m.lEmail = m.top.findNode("lEmail")
    m.lSubscriptionHeader = m.top.findNode("lSubscriptionHeader")
    m.lStatus = m.top.findNode("lStatus")
    m.lSubscriptionContent = m.top.findNode("lSubscriptionContent")
    m.lProfilesTitle = m.top.findNode("lProfilesTitle")
    m.gProfiles = m.top.findNode("gProfiles")
    m.logoutButton = m.top.findNode("logoutButton")
end sub

sub SetupFonts()
    ' titulo-1 = 2.4vw (46px); los h2 de info = 1.5vw (29px); el texto 1.2vw
    ' (23px); titulo-2 = 1.74 * 1.2vw (40px).
    m.lTitle.font = m.fonts.dmSansBold48
    m.lPersonalHeader.font = m.fonts.dmSansBold28
    m.lSubscriptionHeader.font = m.fonts.dmSansBold28
    m.lName.font = m.fonts.dmSansMedium23
    m.lEmail.font = m.fonts.dmSansMedium23
    m.lStatus.font = m.fonts.dmSansMedium23
    m.lSubscriptionContent.font = m.fonts.dmSansMedium23
    m.lProfilesTitle.font = m.fonts.dmSansBold36
end sub

sub SetupColor()
    m.lTitle.color = m.theme.white
    ' rgba(255,255,255,0.6)
    m.lPersonalHeader.color = "#FFFFFF99"
    m.lSubscriptionHeader.color = "#FFFFFF99"
    m.lName.color = m.theme.white
    m.lEmail.color = m.theme.white
    m.lStatus.color = m.theme.white
    m.lSubscriptionContent.color = m.theme.white
    m.lProfilesTitle.color = m.theme.white
end sub

sub SetObservers()
    m.top.observeField("focusedChild", "OnFocusedChild")
end sub

sub Initialize()
    ' Mismo boton pill sin relleno que "Ver ahora" (.btn .btn-reanudar):
    ' borde gris, naranjo con foco, icono de play a la izquierda.
    m.logoutButton.update({
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.white
        backgroundColor: m.theme.clrSecondaryText
        focusBackgroundColor: m.theme.focPrimary
        focusBorderImage: "pkg:/images/focus/R5T3_35px_outborder_nopadding.9.png"
        fontSize: "dmSansBold23"
        posterImage: "pkg:/images/focus/btnplay.png"
        addColorOnImage: true
        padding: 20
        posterImageSize: 20
        margin: 10
    })
    LoadData()
end sub

' Al volver de "Editar perfil" despues de guardar (la web vuelve a montar
' /mi-cuenta y pide todo de nuevo). Se conserva la posicion del foco.
sub ReloadData()
    m.isLoaded = false
    m.reloading = true
    LoadData()
end sub

sub LoadData()
    ' Como el FullScreenSpinner de la web: no se muestra nada hasta que
    ' vuelven los datos.
    m.gContent.visible = false
    m.scene.callFunc("ShowHideLoader", true)
    m.pendingRequests = 3
    m.avatarTask = RunAuthTask("GetAvatarBaseUrl", "OnGetAvatarBaseUrlAPIResponse")
    m.profilesTask = RunAuthTask("GetProfilesData", "OnGetProfilesAPIResponse")
    m.userInfoTask = RunAuthTask("GetUserInfo", "OnGetUserInfoAPIResponse")
end sub

function RunAuthTask(functionName as string, callback as string) as object
    task = CreateObject("roSGNode", "AuthAPIAction")
    task.functionName = functionName
    task.ObserveField("result", callback)
    task.control = "RUN"
    return task
end function

sub OnGetAvatarBaseUrlAPIResponse(event as dynamic)
    response = event.getData()
    print "AccountPage : OnGetAvatarBaseUrlAPIResponse : " FormatJson(response)
    m.avatarTask = invalid
    m.avatarBaseUrl = getValueFromProps(response, "data.data.url.stringValue", "")
    OnRequestFinished()
end sub

sub OnGetProfilesAPIResponse(event as dynamic)
    response = event.getData()
    print "AccountPage : OnGetProfilesAPIResponse : " FormatJson(response)
    m.profilesTask = invalid
    m.rawProfileItems = getValueFromProps(response, "data.data", invalid)
    OnRequestFinished()
end sub

' /userInfo/{uid}: el gateway trae "title"/"content" de la suscripcion al
' lado de los campos de Firestore (setSubscription(userInfoResponse.data)).
sub OnGetUserInfoAPIResponse(event as dynamic)
    response = event.getData()
    print "AccountPage : OnGetUserInfoAPIResponse : " FormatJson(response)
    m.userInfoTask = invalid
    m.subscription = getValueFromProps(response, "data", invalid)
    OnRequestFinished()
end sub

sub OnRequestFinished()
    m.pendingRequests = m.pendingRequests - 1
    print "AccountPage : OnRequestFinished : pendingRequests=" m.pendingRequests
    if m.pendingRequests > 0 then return
    m.scene.callFunc("ShowHideLoader", false)
    FillUserInfo()
    BuildProfiles()
    m.gContent.visible = true
    m.isLoaded = true
    ' preferredChildFocusKey: el primer perfil (o el boton si no hay perfiles).
    ' Al recargar se retoma donde estaba (el lapiz del perfil editado).
    reloading = m.reloading
    m.reloading = false
    if not m.top.isInFocusChain() then return
    if m.profileNodes.count() = 0
        SetFocusArea("logout", 0)
    else if reloading
        SetFocusArea(m.focusArea, m.focusIndex)
    else
        SetFocusArea("profiles", 0)
    end if
end sub

' Nombre y email salen del JWT (jwtDecode(accessToken) en la web).
sub FillUserInfo()
    decode = DecodeJwtPayload(GlobalGet("token"))
    m.lName.text = "Nombre: " + getValueFromProps(decode, "name", "")
    m.lEmail.text = "Email: " + getValueFromProps(decode, "email", "")
    title = getValueFromProps(m.subscription, "title", "")
    if not isNonEmptyString(title) then title = "Sin datos"
    m.lStatus.text = "Estado: " + title
    content = getValueFromProps(m.subscription, "content", "")
    if isNonEmptyString(content)
        m.lSubscriptionContent.text = content
        m.lSubscriptionContent.visible = true
    else
        m.lSubscriptionContent.text = ""
        m.lSubscriptionContent.visible = false
    end if
end sub

' Mismo mapeo que use-account-data.ts: order / name / <urlBase><avatar>.jpg.
sub BuildProfiles()
    m.profiles = []
    m.profileNodes = []
    m.gProfiles.removeChildrenIndex(m.gProfiles.getChildCount(), 0)
    if not isNotEmptyArray(m.rawProfileItems) then return
    for each document in m.rawProfileItems
        fields = getValueFromProps(document, "fields", invalid)
        if not isValid(fields) then continue for
        avatarId = FirestoreString(fields, "avatar")
        profileUri = m.defaultProfileUri
        if isNonEmptyString(m.avatarBaseUrl) AND isNonEmptyString(avatarId)
            profileUri = m.avatarBaseUrl + avatarId + ".jpg"
        end if
        m.profiles.Push({
            profileId: FirestoreString(fields, "order", "0")
            profileName: FirestoreString(fields, "name")
            profileUri: profileUri
        })
    end for
    ' Cada .item mide 8vw (154px) + padding-right 1vw (19px).
    for i = 0 to m.profiles.count() - 1
        profile = m.profiles[i]
        node = CreateObject("roSGNode", "AccountProfileItem")
        node.translation = [i * 173, 0]
        node.profileName = profile.profileName
        node.isPhoto = profile.profileUri <> m.defaultProfileUri
        node.profileUri = profile.profileUri
        m.gProfiles.appendChild(node)
        m.profileNodes.Push(node)
    end for
end sub

sub SetFocusArea(area as string, index as integer)
    if (area = "profiles" OR area = "edit") AND m.profileNodes.count() = 0 then area = "logout"
    if index < 0 then index = 0
    if index > m.profileNodes.count() - 1 then index = m.profileNodes.count() - 1
    m.focusArea = area
    m.focusIndex = index
    if area = "logout"
        m.logoutButton.setFocus(true)
    else
        m.gProfiles.setFocus(true)
    end if
    ApplyFocusVisuals()
end sub

sub ApplyFocusVisuals()
    for i = 0 to m.profileNodes.count() - 1
        m.profileNodes[i].avatarFocused = (m.focusArea = "profiles") AND (i = m.focusIndex)
        m.profileNodes[i].editFocused = (m.focusArea = "edit") AND (i = m.focusIndex)
    end for
end sub

sub ClearFocusVisuals()
    for each node in m.profileNodes
        node.avatarFocused = false
        node.editFocused = false
    end for
end sub

' Al volver desde el sidebar (MainScene hace FocusTop sobre esta pagina) se
' retoma el ultimo lugar; al irse al sidebar se apagan los focos.
sub OnFocusedChild()
    if not m.top.isInFocusChain()
        ClearFocusVisuals()
    else if m.top.hasFocus() AND m.isLoaded
        SetFocusArea(m.focusArea, m.focusIndex)
    end if
end sub

' setProfile(profile) + navigate("/home") de ProfileItem.tsx.
sub SelectProfile(index as integer)
    profile = m.profiles[index]
    if not isValid(profile) then return
    m.registryManager.SaveSelectedProfile(profile)
    GlobalSet("selectedProfileID", profile.profileId)
    m.scene.ProfileData = profile
    m.scene.callFunc("StartApp")
end sub

' Navegacion calcada de la web: izquierda/derecha entre perfiles (o entre
' botones de editar), abajo del avatar a su "editar", abajo de "editar" a
' "Cerrar Sesión", arriba desde "Cerrar Sesión" al ultimo "editar"
' (handleUpFromLogout), e izquierda en la primera columna o en el boton sale
' al sidebar (devolver false deja que MainScene lo maneje).
function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if not m.isLoaded then return false
    lastIndex = m.profileNodes.count() - 1
    if m.focusArea = "profiles"
        if key = "OK"
            SelectProfile(m.focusIndex)
            return true
        else if key = "left"
            if m.focusIndex = 0 then return false
            SetFocusArea("profiles", m.focusIndex - 1)
            return true
        else if key = "right"
            if m.focusIndex < lastIndex then SetFocusArea("profiles", m.focusIndex + 1)
            return true
        else if key = "down"
            SetFocusArea("edit", m.focusIndex)
            return true
        else if key = "up"
            return true
        end if
    else if m.focusArea = "edit"
        if key = "OK"
            ' navigate(`/edit-perfil/${profile.order}`)
            profile = m.profiles[m.focusIndex]
            if isValid(profile) then m.scene.callFunc("ShowEditProfilePage", profile.profileId)
            return true
        else if key = "left"
            if m.focusIndex = 0 then return false
            SetFocusArea("edit", m.focusIndex - 1)
            return true
        else if key = "right"
            if m.focusIndex < lastIndex then SetFocusArea("edit", m.focusIndex + 1)
            return true
        else if key = "up"
            SetFocusArea("profiles", m.focusIndex)
            return true
        else if key = "down"
            SetFocusArea("logout", 0)
            return true
        end if
    else if m.focusArea = "logout"
        if key = "OK"
            m.scene.callFunc("OnLogout")
            return true
        else if key = "left"
            return false
        else if key = "up"
            if lastIndex >= 0 then SetFocusArea("edit", lastIndex)
            return true
        else if key = "down" OR key = "right"
            return true
        end if
    end if
    return false
end function
