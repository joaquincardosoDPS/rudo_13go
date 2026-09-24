sub Init()
    print "MainScene Init "
    setGlobalNode()
    SetLocals()
    SetControls()
    SetupFonts()
    SetupColor()
    SetObservers()
    Initialize()
end sub

sub SetLocals()
    m.theme = m.global.appTheme
    m.fonts = m.global.Fonts
    m.scene = m.top.GetScene()
    m.appConfig = m.global.appConfig
    m.appLaunchCompleteBeaconSent = false
    m.appDialogInitiateBeaconSent = false
    m.appDialogCompleteBeaconSent = false
    m.ViewStackManager = CreateViewStackManager()
    m.registryManager = CreateRegistryManager()
    m.defaultProfileName = "Mi perfil"
    m.defaultProfileUri = "pkg:/images/focus/add_profile_img_unfocus.png"
    m.exitPopUpOpened = false
    m.exitCalled = false
    m.exitDialogMode = "exit"
    m.lastProfileId = ""
    m.skipProfilePickerIfSaved = false
end sub

sub SetControls()
    m.gPageContainer = m.top.findNode("gPageContainer")
    m.logo = m.top.FindNode("Logo")
    m.gTopMenu = m.top.findNode("gTopMenu")
    m.pageLoader = m.top.findNode("pageLoader")
    m.pTopMenuBackground = m.top.findNode("pTopMenuBackground")
    m.rBackground = m.top.findNode("rBackground")
    CreateToastMessageControls()
end sub

sub ShowHideLoader(flag as boolean)
    print "MainScene : ShowHideLoader : flag : " flag
    m.pageLoader.visible = flag
end sub

sub SetupFonts()
end sub

sub SetupColor()
    m.pTopMenuBackground.blendColor = m.theme.black
    m.rBackground.color = m.theme.clrPrimary
end sub

sub SetObservers()
    m.top.observeField("ProfileData", "OnProfileDataChanged")
end sub

' Start Deep Linking
sub CreateToastMessageControls()
    m.toastMsgBox = m.top.findNode("ToastMsgBox")
    m.toastMsgText = m.top.findNode("ToastMsgText")
    m.toastMessageTimer = m.top.FindNode("toastMessageTimer")
    m.toastMessageTimer.observeField("fire", "toastMessageTimerExpired")
end sub

function IsValidDeepLink() as boolean
    contentID = m.top.deepLinkingContentId
    mediaType = LCase(m.top.deepLinkingMediaType)
    print "MainScene : IsValidDeepLink : contentID : " contentID
    print "MainScene : IsValidDeepLink : mediaType : " mediaType
    validData = false
    if (isEmptyString(contentID) AND not IsSupportedDeepLinkMediaType(mediaType))
        m.top.DeeplinkMsg = "Wrong arguments provided for deeplinking."
    else if isEmptyString(contentID)
        m.top.DeeplinkMsg = "Required contentId not provided."
    else if not IsSupportedDeepLinkMediaType(mediaType)
        m.top.DeeplinkMsg = "Required mediaType not provided."
    else
        m.top.deeplinkingData = splitDeeplinkingData(contentID)
        if m.top.deeplinkingData.count() > 0
            m.top.DeeplinkMsg = "Fetching details for provided id..."
            validData = true
            m.top.isDeeplinking = true
        else
            m.top.DeeplinkMsg = "No data found..."
            validData = false
        end if
    end if
    if (not IsNullOrEmpty(m.top.DeeplinkMsg))
        ShowDeeplinkDialog(m.top.DeeplinkMsg)
        m.toastMessageTimer.control = "start"
    end if
    if (not validData)
        DeeplinkingDialogClosed()
    end if
    return validData
end function

function splitDeeplinkingData(deepLinkingContentId as string) as object
    deeplinkingCollection = deepLinkingContentId.Split("|")
    data = {}
    if deeplinkingCollection <> invalid AND deeplinkingCollection.count() > 0 AND deeplinkingCollection[0] <> invalid
        for i = 0 to deeplinkingCollection.count() - 1
            key = deeplinkingCollection[i].Split("=")[0]
            value = deeplinkingCollection[i].Split("=")[1].toStr()
            if LCase(key) = "programid"
                data.programId = value
            else if LCase(key) = "segmentid"
                data.segmentId = value
            else if LCase(key) = "seasonid"
                data.seasonId = value
            else if LCase(key) = "episodeid"
                data.episodeId = value
            end if
        end for
    end if
    return data
end function

function IsSupportedDeepLinkMediaType(mediaType as dynamic) as boolean
    return isValid(mediaType) AND mediaType = "movie" OR mediaType = "season" OR mediaType = "episode" OR mediaType = "series" OR mediaType = "live"
end function

function IsValidDeepLinkingParams() as boolean
    return isValid(m.top.deepLinkingContentId) AND isNonEmptyString(m.top.deepLinkingContentId) AND isValid(m.top.deepLinkingMediaType) AND isNonEmptyString(m.top.deepLinkingMediaType)
end function

sub DeeplinkingDialogClosed()
    m.top.deepLinkingContentId = ""
    m.top.deepLinkingMediaType = ""
end sub

sub DeletePages()
    if isValid(m.videoPlayerControl)
        m.videoPlayerControl.callFunc("closePlayer")
        m.top.removeChild(m.videoPlayerControl)
        m.videoPlayerControl = invalid
    end if
    m.top.isWatchHistoryFetched = false
    m.ViewStackManager.HideScreen(invalid, true)
end sub

sub HandleInputEvent(deeplinkData)
    print "MainScene : HandleDeepLinkingInputEvent : DeepLinking Data : " deeplinkData
    m.top.deepLinkingContentId = ""
    m.top.deepLinkingMediaType = ""

    m.top.deepLinkingContentId = deeplinkData.contentid
    m.top.deepLinkingMediaType = deeplinkData.mediaType

    if IsValidDeepLinkingParams() AND IsValidDeepLink()
        DeletePages()
        Initialize()
    else
        DeeplinkingDialogClosed()
    end if
end sub

sub onDeepLinkingLand()
    print "MainScene : OnDeepLinkingLand"
    if m.top.deepLinkingLand
        m.top.deepLinkingLand = false
        if IsValidDeepLinkingParams()
            if IsValidDeepLink() = false
                DeeplinkingDialogClosed()
            end if
        else
            DeeplinkingDialogClosed()
        end if
    end if
end sub

sub ShowDeeplinkDialog(message as string)
    sendAppDialogInitiateBeacon()
    if IsValidDeepLinkingParams()
        m.top.dialog = invalid
        dialog = createObject("roSGNode", "ProgressDialog")
        dialog.title = "Deeplinking..."
        dialog.message = message
        print "Dialog Message "
        dialog.optionsDialog = false
        m.top.dialog = dialog
        m.top.dialog = dialog
    end if
end sub

sub CloseDeeplinkDialog()
    if isValid(m.top.dialog)
        print "MainScene : CloseDeeplinkDialog : dialog closed"
        m.top.dialog.close = true
        m.top.dialog = invalid
    end if
    sendAppDialogCompleteBeacon()
    sendAppLaunchCompleteBeacon()
end sub

sub ChangeDeeplinkDialogMessage()
    if isValid(m.top.dialog)
        m.top.dialog.message = m.top.DeeplinkMsg
    end if
end sub

sub toastMessageTimerExpired()
    print "MainScene : toastMessageTimerExpired"
    if m.top.deepLinkingContentId = ""
        m.top.DeeplinkMsg = ""
        m.toastMessageTimer.control = "stop"
        CloseDeeplinkDialog()
    end if
end sub
' End Deep Linking

' Beacon Events'
sub sendAppLaunchCompleteBeacon()
    if (m.appLaunchCompleteBeaconSent = false)
        print "MainScene : Sending AppLaunchComplete..."
        m.top.signalBeacon("AppLaunchComplete")
        m.appLaunchCompleteBeaconSent = true
    end if
end sub

sub sendAppDialogInitiateBeacon()
    if (m.appDialogInitiateBeaconSent = false AND m.appLaunchCompleteBeaconSent = false)
        print "MainScene : Sending AppDialogInitiate..."
        m.top.signalBeacon("AppDialogInitiate")
        m.appDialogInitiateBeaconSent = true
    end if
end sub

sub sendAppDialogCompleteBeacon()
    if (m.appDialogCompleteBeaconSent = false AND m.appDialogInitiateBeaconSent = true)
        print "MainScene : Sending AppDialogComplete..."
        m.top.signalBeacon("AppDialogComplete")
        m.appDialogCompleteBeaconSent = true
    end if
end sub

sub Initialize()
    m.top.ProfileData = {
        profileName: m.defaultProfileName
        profileUri: m.defaultProfileUri
    }
    ShowHideLoader(true)
    GetConfig()
end sub

sub GetConfig()
    if isValid(m.getConfigTask) Then
        m.getConfigTask.control = "stop"
    end if
    m.getConfigTask = CreateObject("roSGNode", "ContentAPIAction")
    m.getConfigTask.functionName = "GetConfig"
    m.getConfigTask.ObserveField("result", "OnGetConfigAPIResponse")
    m.getConfigTask.control = "RUN"
end sub

sub OnGetConfigAPIResponse(event as dynamic)
    apiResponse = event.getData()
    print "Mainscene : OnGetConfigAPIResponse : " 'FormatJson(apiResponse)
    response = getValueFromProps(apiResponse, "data.0", {})
    GlobalSet("homeConfig", response)
    logo = "pkg:/images/brand/logo.png"
    background_image = invalid
    urlTVVincular = ""
    vastURL = ""
    if isValid(m.theme) AND isValid(m.theme.background_image) then background_image = m.theme.background_image
    If isValid(response) AND response.count() > 0
        if isNonEmptyString(response.logo_blanco)
            logo = response.logo_blanco
        end if
        if isNonEmptyString(response.fondo_bienvenida)
            background_image = response.fondo_bienvenida
        end if
        ' TODO (Paso 4 - auth/ads): /configuracion de 13go no trae "base_ads" ni "url-tv-vincular".
        ' vastURL sale de deviceAdService (VAST/VMAP por request) y el link de vinculacion TV
        ' se resuelve con el flujo action=deviceCode/deviceToken del gateway. Quedan en "" por ahora.
        newTheme = MergeMissingConfigColorsIntoTheme(m.theme, response)
        m.global.setFields({ "appTheme": newTheme })
        m.theme = m.global.appTheme
    end if
    GlobalSet("vastURL", vastURL)
    GlobalSet("urlTVVincular", urlTVVincular)
    GlobalSet("logo", logo)
    GlobalSet("backgroundImage", background_image)
    m.getConfigTask = invalid
    RestoreSession()
end sub

' ===================================================================
' Sesion (equivalente a checkUserSession() del AuthProvider de c13_reloaded)
' -------------------------------------------------------------------
' Al arrancar: si hay sesion guardada se valida el access token (JWT.exp);
' si venció se renueva con el refresh token, y recien despues se piden
' /userProfile y /userInfo. Sin sesion, el canal arranca igual como
' invitado en la Portada (el login se entra desde "Mi cuenta" del sidebar).
' ===================================================================
sub RestoreSession()
    authData = m.registryManager.GetAuthData()
    accessToken = getValueFromProps(authData, "accessToken", "")
    if not isNonEmptyString(accessToken)
        StartAsGuest()
        sendAppLaunchCompleteBeacon()
        return
    end if
    m.authData = authData
    if IsJwtValid(accessToken)
        ApplySession(m.authData)
        ' Relanzamiento de la app con una sesion ya existente: si ya habia un
        ' perfil elegido, se respeta y se salta "¿Quién anda ahí?" (igual que
        ' currentProfile en el localStorage de la web). Distinto del flujo de
        ' vinculacion recien completada (OnDeviceLinked), que en c13_reloaded
        ' SIEMPRE muestra WhosThere (ConnectView.tsx navega ahi sin condicion).
        m.skipProfilePickerIfSaved = true
        LoadUserData()
    else
        print "MainScene : access token vencido, renovando con el refresh token"
        RefreshSessionToken()
    end if
    sendAppLaunchCompleteBeacon()
end sub

sub StartAsGuest()
    m.authData = invalid
    ShowHideLoader(false)
    StartApp()
end sub

sub RefreshSessionToken()
    if isValid(m.refreshTokenTask) then m.refreshTokenTask.control = "stop"
    m.refreshTokenTask = CreateObject("roSGNode", "AuthAPIAction")
    m.refreshTokenTask.functionName = "RefreshToken"
    m.refreshTokenTask.params = { "refreshToken": getValueFromProps(m.authData, "refreshToken", "") }
    m.refreshTokenTask.ObserveField("result", "OnRefreshTokenAPIResponse")
    m.refreshTokenTask.control = "RUN"
end sub

sub OnRefreshTokenAPIResponse(event as dynamic)
    response = event.getData()
    m.refreshTokenTask = invalid
    tokenData = getValueFromProps(response, "data.data", invalid)
    if isValid(tokenData) AND isNonEmptyString(getValueFromProps(tokenData, "access_token", ""))
        m.authData = BuildAuthDataFromGateway(tokenData, getValueFromProps(m.authData, "deviceId", ""))
        m.registryManager.SaveAuthData(m.authData)
        ApplySession(m.authData)
        ' Esto solo se llama desde RestoreSession() (relanzamiento) - ver nota ahi.
        m.skipProfilePickerIfSaved = true
        LoadUserData()
    else
        ' El refresh token tambien vencio: se descarta la sesion y se sigue como invitado.
        print "MainScene : no se pudo renovar la sesion, se cierra"
        m.registryManager.ClearAuthData()
        ClearSession()
        StartAsGuest()
    end if
end sub

sub ApplySession(authData as object)
    GlobalSet("token", getValueFromProps(authData, "accessToken", ""))
    GlobalSet("userId", getValueFromProps(authData, "userId", ""))
end sub

sub ClearSession()
    GlobalSet("token", "")
    GlobalSet("userId", "")
    GlobalSet("UserData", {})
    GlobalSet("selectedProfileID", "")
    m.authData = invalid
    m.lastProfileId = ""
end sub

' /userProfile trae los datos personales y /userInfo el estado de la
' suscripcion. Se piden en secuencia (el segundo arranca al volver el primero).
sub LoadUserData()
    print "MainScene : LoadUserData : userId=" getValueFromProps(m.authData, "userId", "") " token=" Left(getValueFromProps(m.authData, "accessToken", ""), 12) "..."
    if isValid(m.userProfileTask) then m.userProfileTask.control = "stop"
    m.userProfileTask = CreateObject("roSGNode", "AuthAPIAction")
    m.userProfileTask.functionName = "GetUserProfile"
    m.userProfileTask.ObserveField("result", "OnGetUserProfileAPIResponse")
    m.userProfileTask.control = "RUN"
end sub

sub OnGetUserProfileAPIResponse(event as dynamic)
    response = event.getData()
    print "MainScene : OnGetUserProfileAPIResponse : " FormatJson(response)
    m.userProfileTask = invalid
    fields = getValueFromProps(response, "data.data", {})
    m.userData = {
        id: getValueFromProps(m.authData, "userId", "")
        name: FirestoreString(fields, "name")
        gender: FirestoreString(fields, "gender")
        birthYear: FirestoreString(fields, "birthYear")
        birthMonth: FirestoreString(fields, "birthMonth")
        birthDay: FirestoreString(fields, "birthDay")
    }
    print "MainScene : OnGetUserProfileAPIResponse : pidiendo GetUserInfo"
    if isValid(m.userInfoTask) then m.userInfoTask.control = "stop"
    m.userInfoTask = CreateObject("roSGNode", "AuthAPIAction")
    m.userInfoTask.functionName = "GetUserInfo"
    m.userInfoTask.ObserveField("result", "OnGetUserInfoAPIResponse")
    m.userInfoTask.control = "RUN"
end sub

sub OnGetUserInfoAPIResponse(event as dynamic)
    response = event.getData()
    print "MainScene : OnGetUserInfoAPIResponse : " FormatJson(response)
    m.userInfoTask = invalid
    gateway = getValueFromProps(response, "data", {})
    fields = getValueFromProps(gateway, "data", {})
    status = FirestoreString(fields, "subscriptionStatus")
    m.userData.suscription = {
        active: isNonEmptyString(status) AND status <> "pending"
        status: status
        subStatus: FirestoreString(fields, "subscriptionSubStatus")
        title: getValueFromProps(gateway, "title", "")
        content: getValueFromProps(gateway, "content", "")
        plans: FirestoreArray(fields, "plans")
        products: FirestoreArray(fields, "products")
    }
    m.userData.adsFreeType = FirestoreString(fields, "ads_free", "default")
    GlobalSet("UserData", m.userData)
    ' En la web el anillo "Premium" del sidebar depende de este estado.
    GlobalSet("isPremiumUser", status = "success" OR status = "light")
    print "MainScene : OnGetUserInfoAPIResponse : ocultando loader, isUserLoggedIn=true"
    ShowHideLoader(false)
    m.top.isUserLoggedIn = true
    ' Si esto es un relanzamiento de la app (RestoreSession) y ya habia un
    ' perfil elegido, se respeta y se salta el picker (como el "currentProfile"
    ' del localStorage de la web). Recien vinculado (OnDeviceLinked) siempre
    ' muestra "¿Quién anda ahí?" - ver notas en RestoreSession()/OnDeviceLinked().
    savedProfile = m.registryManager.GetSelectedProfile()
    hasSavedProfile = isValid(savedProfile) AND isNonEmptyString(getValueFromProps(savedProfile, "profileId", ""))
    if m.skipProfilePickerIfSaved AND hasSavedProfile
        print "MainScene : OnGetUserInfoAPIResponse : relanzamiento con perfil guardado, StartApp directo"
        GlobalSet("selectedProfileID", savedProfile.profileId)
        m.top.ProfileData = savedProfile
        StartApp()
    else
        print "MainScene : OnGetUserInfoAPIResponse : mostrando selector de perfiles (skipIfSaved=" m.skipProfilePickerIfSaved " hasSavedProfile=" hasSavedProfile ")"
        StartApp()
        ShowEditorProfilesPage(false)
    end if
end sub

sub OnUserLoggedIn()
    print "MainScene : OnUserLoggedIn : m.top.isUserLoggedIn : " m.top.isUserLoggedIn
    if m.top.isUserLoggedIn
        ' createTopMenu()
        ' ShowHideMenu(true)
        ' SetFocus(m.TopMenu)
        ' ShowEditorProfilesPage(true)
    end if
end sub

sub OnProfileDataChanged()
    if not isValid(m.top.ProfileData) OR not isNonEmptyString(m.top.ProfileData.profileId)
        return
    end if
    profileId = m.top.ProfileData.profileId
    if m.lastProfileId = profileId
        return
    end if
    m.lastProfileId = profileId
    RefreshVisiblePageForProfile()
end sub

sub RefreshVisiblePageForProfile()
    topNode = m.ViewStackManager.GetTop()
    if not isValid(topNode) then return
    pageId = topNode.id
    if pageId = "EditorProfilesPage" OR pageId = "OnboardingPage" OR pageId = "DeviceLinkPage"
        return
    end if
    if pageId = "HomePage"
        showHomePage(true)
    else if pageId = "SearchPage"
        ShowSearchPage(true)
    else if pageId = "ShowProgramsPage"
        ShowProgramsPage(true)
    else if pageId = "LivePage"
        ShowLivePage(true)
    else if pageId = "RadioPage"
        ShowRadioPage(true)
    else if pageId = "MyListPage"
        ShowMyListPage(true)
    else if pageId = "CategoryDetailPage"
        categoryContent = topNode.contentNode
        if isValid(categoryContent)
            showCategoryDetailPage(categoryContent, true)
        end if
    end if
end sub

sub StartApp()
    print "Mainscene : StartApp "
    if m.top.isUserLoggedIn
        m.top.updatedContinueWatchData = {}
    end if
    createTopMenu()
    ShowHideMenu(true)
    SetFocus(m.TopMenu)
    showHomePage(true)
end sub

'===> Start Top Menu Objects
sub createTopMenu()
    if (isValid(m.TopMenu))
        m.TopMenu.unObserveField("selectedItem")
        m.gTopMenu.removeChild(m.TopMenu)
        m.TopMenu = invalid
    end if
    m.TopMenu = m.gTopMenu.createChild("TopMenu")
    m.TopMenu.observeField("selectedItem", "onTopMenuItemSelected")
    ' SetFocus(m.TopMenu)
    ShowHideMenu(true)
end sub

sub UpdateSelectedTopMenu(index as integer)
    if isValid(m.TopMenu) AND isValid(index) AND index <> -1 AND isValid(m.TopMenu)
        topNode = m.viewStackManager.GetTop()
        if isValid(topNode) AND isValid(topNode.id) AND LCase(topNode.id) = "eventdetailpage" AND isValid(m.ViewStackManager) AND m.ViewStackManager.count() > 0
            m.ViewStackManager.HideTop()
            m.gPageContainer.removeChild(topNode)
            topNode = invalid
        end if
        ShowHideMenu(true)
        m.TopMenu.callFunc("UpdateSelectedTopMenu", index, true)
    end if
end sub

sub ShowHideMenu(visible as boolean)
    print "MainScene : ShowHideMenu"
    if isValid(m.TopMenu) AND isValid(m.gTopMenu)
        m.gTopMenu.visible = visible
        m.pTopMenuBackground.visible = visible
    end if
end sub

sub onTopMenuItemSelected(event as dynamic)
    menuItem = event.getData()
    if menuItem = invalid then return

    pageName = menuItem.title
    print "MainScene : onTopMenuItemSelected : pageName = " pageName
    ' "Editar perfil" esta apilada sobre "Mi Cuenta": al ir a otra seccion se
    ' cierra primero, para que el reemplazo de pagina actue sobre la seccion
    ' real. Con "Mi cuenta" se queda: la grilla puede disparar itemSelected del
    ' item enfocado solo con entrar al riel (ver "Bug real #4" en CLAUDE.md).
    topNode = m.ViewStackManager.GetTop()
    if isValid(topNode) AND topNode.id = "EditProfilePage"
        if pageName = "Mi cuenta" then return
        CloseEditProfilePage(false)
    end if
    if pageName = "Mi cuenta"
        ShowMyAccount()
        return
    end if
    if isValid(pageName)
        targetPageId = ""
        if pageName = "Portada"
            targetPageId = "homepage"
        else if pageName = "Búsqueda"
            targetPageId = "searchpage"
        else if pageName = "Programas"
            targetPageId = "showprogramspage"
        else if pageName = "En vivo"
            targetPageId = "livepage"
        else if pageName = "Radios"
            targetPageId = "radiopage"
        end if

        topNode = m.ViewStackManager.GetTop()
        if isValid(topNode) AND isNonEmptyString(targetPageId) AND LCase(topNode.id) = targetPageId
            return
        end if

        if isValid(m.HomePage) then m.HomePage.isDestroy = true
        if isValid(m.LivePage) then m.LivePage.isDestroy = true
        if isValid(m.MyListPage) then m.MyListPage.isDestroy = true
        if isValid(m.RadioPage) then m.RadioPage.isDestroy = true
        if isValid(m.SearchPage) then m.SearchPage.isDestroy = true
        if pageName = "Portada"
            ShowHomePage(true)
        else if pageName = "Búsqueda"
            ShowSearchPage(true)
        else if pageName = "Programas"
            ShowProgramsPage(true)
        else if pageName = "En vivo"
            ShowLivePage(true)
        else if pageName = "Radios"
            ShowRadioPage(true)
        else
            ShowHomePage(true)
        end if
    end if
end sub

function OnLogout()
    if (m.top.isUserLoggedIn = true)
        ShowLogoutConfirmation()
    end if
end function
'===> End Top Menu Objects

sub OnLogoutUser()
    m.registryManager.ClearAuthData()
    ClearSession()
    m.top.isUserLoggedIn = false
    m.top.ProfileData = {
        profileName: m.defaultProfileName
        profileUri: m.defaultProfileUri
    }
    m.viewStackManager.HideAll()
    UpdateSelectedTopMenu(1)
    showHomePage(true)
end sub

' Destino del item "Mi cuenta" del sidebar: con sesion abierta es una seccion
' mas (/mi-cuenta -> AccountView en la web, con el sidebar visible); sin
' sesion arranca el flujo de vinculacion de TV (bienvenida -> codigo QR),
' igual que LoginView -> ConnectView en la web.
sub ShowMyAccount()
    if m.top.isUserLoggedIn
        topNode = m.ViewStackManager.GetTop()
        if isValid(topNode) AND topNode.id = "AccountPage" then return
        if isValid(m.HomePage) then m.HomePage.isDestroy = true
        if isValid(m.LivePage) then m.LivePage.isDestroy = true
        if isValid(m.MyListPage) then m.MyListPage.isDestroy = true
        if isValid(m.RadioPage) then m.RadioPage.isDestroy = true
        if isValid(m.SearchPage) then m.SearchPage.isDestroy = true
        ShowAccountPage(true)
        m.TopMenu.callFunc("UpdateSelectedTopMenu", 0, true)
    else
        ShowOnboardingPage(false)
    end if
end sub

' La DeviceLinkPage ya guardo la sesion en el registry; desde aca se completa
' igual que checkUserSession() en la web: datos de usuario y suscripcion.
sub OnDeviceLinked()
    print "MainScene : OnDeviceLinked"
    m.authData = m.registryManager.GetAuthData()
    print "MainScene : OnDeviceLinked : authData leido del registry : " FormatJson(m.authData)
    ' Vinculacion recien completada: en c13_reloaded, ConnectView.tsx navega a
    ' /whosthere SIEMPRE al autenticarse, sin importar si ya habia un perfil
    ' elegido antes - a diferencia de un relanzamiento de la app (RestoreSession).
    m.skipProfilePickerIfSaved = false
    LoadUserData()
end sub

sub ShowOnboardingPage(isReplace = false as boolean)
    m.OnboardingPage = GetOnboardingPageObject(true)
    if (isReplace = true)
        m.ViewStackManager.ReplaceScreen(m.OnboardingPage)
    else
        m.ViewStackManager.ShowScreen(m.OnboardingPage)
    end if
    ShowHideMenu(false)
    setFocus(m.OnboardingPage)
end sub

function GetOnboardingPageObject(isReplace as boolean) as object
    if isReplace
        m.gPageContainer.removeChild(m.OnboardingPage)
        m.OnboardingPage = invalid
    end if
    if isInvalid(m.OnboardingPage)
        m.OnboardingPage = createObject("roSGNode", "OnboardingPage")
        m.OnboardingPage.visible = true
        m.OnboardingPage.id = "OnboardingPage"
    end if
    m.gPageContainer.appendChild(m.OnboardingPage)
    return m.OnboardingPage
end function

sub ShowDeviceLinkPage(isReplace = false as boolean)
    m.DeviceLinkPage = GetDeviceLinkPageObject(true)
    if (isReplace = true)
        m.ViewStackManager.ReplaceScreen(m.DeviceLinkPage)
    else
        m.ViewStackManager.ShowScreen(m.DeviceLinkPage)
    end if
    ShowHideMenu(false)
    setFocus(m.DeviceLinkPage)
end sub

function GetDeviceLinkPageObject(isReplace as boolean) as object
    if isReplace
        m.gPageContainer.removeChild(m.DeviceLinkPage)
        m.DeviceLinkPage = invalid
    end if
    if isInvalid(m.DeviceLinkPage)
        m.DeviceLinkPage = createObject("roSGNode", "DeviceLinkPage")
        m.DeviceLinkPage.visible = true
        m.DeviceLinkPage.id = "DeviceLinkPage"
    end if
    m.gPageContainer.appendChild(m.DeviceLinkPage)
    return m.DeviceLinkPage
end function

sub ShowEditorProfilesPage(isReplace = false as boolean)
    m.EditorProfilesPage = GetEditorProfilesPageObject(true)
    if (isReplace = true)
        m.ViewStackManager.ReplaceScreen(m.EditorProfilesPage)
    else
        m.ViewStackManager.ShowScreen(m.EditorProfilesPage)
    end if
    ShowHideMenu(false)
    setFocus(m.EditorProfilesPage)
end sub

function GetEditorProfilesPageObject(isReplace as boolean) as object
    if isReplace
        m.gPageContainer.removeChild(m.EditorProfilesPage)
        m.EditorProfilesPage = invalid
    end if
    if isInvalid(m.EditorProfilesPage)
        m.EditorProfilesPage = createObject("roSGNode", "EditorProfilesPage")
        m.EditorProfilesPage.visible = true
        m.EditorProfilesPage.id = "EditorProfilesPage"
    end if
    m.gPageContainer.appendChild(m.EditorProfilesPage)
    return m.EditorProfilesPage
end function

sub ShowAccountPage(isReplace = false as boolean)
    m.AccountPage = GetAccountPageObject(true)
    if (isReplace = true)
        m.ViewStackManager.ReplaceScreen(m.AccountPage)
    else
        m.ViewStackManager.ShowScreen(m.AccountPage)
    end if
    ShowHideMenu(true)
    setFocus(m.AccountPage)
end sub

' /edit-perfil/:profileId: se apila encima de "Mi Cuenta" (back vuelve a la
' cuenta, como el navigate(-1) de MainLayout.tsx) con el sidebar visible.
sub ShowEditProfilePage(profileId as string)
    m.EditProfilePage = createObject("roSGNode", "EditProfilePage")
    m.EditProfilePage.id = "EditProfilePage"
    m.EditProfilePage.visible = true
    m.gPageContainer.appendChild(m.EditProfilePage)
    m.ViewStackManager.ShowScreen(m.EditProfilePage)
    ShowHideMenu(true)
    m.EditProfilePage.profileId = profileId
    setFocus(m.EditProfilePage)
end sub

' Si el perfil editado es el que esta en uso, el avatar/nombre nuevos se
' reflejan en el sidebar (TopMenu observa ProfileData) y en el perfil guardado
' en el registry. El profileId no cambia, asi que no recarga la pagina.
sub UpdateCurrentProfile(profile as object)
    current = m.top.ProfileData
    currentId = getValueFromProps(current, "profileId", "")
    if not isNonEmptyString(currentId) OR currentId <> getValueFromProps(profile, "profileId", "") then return
    updated = {
        profileId: currentId
        profileName: getValueFromProps(profile, "profileName", "")
        profileUri: getValueFromProps(profile, "profileUri", "")
    }
    m.registryManager.SaveSelectedProfile(updated)
    m.top.ProfileData = updated
end sub

' Tras guardar, la web navega a /mi-cuenta (que vuelve a pedir los datos).
sub CloseEditProfilePage(saved as boolean)
    topNode = m.ViewStackManager.GetTop()
    if isValid(topNode) AND topNode.id = "EditProfilePage"
        m.ViewStackManager.HideTop()
        m.gPageContainer.removeChild(topNode)
    end if
    m.EditProfilePage = invalid
    if saved AND isValid(m.AccountPage) then m.AccountPage.callFunc("ReloadData")
end sub

function GetAccountPageObject(isReplace as boolean) as object
    if isReplace
        m.gPageContainer.removeChild(m.AccountPage)
        m.AccountPage = invalid
    end if
    if isInvalid(m.AccountPage)
        m.AccountPage = createObject("roSGNode", "AccountPage")
        m.AccountPage.visible = true
        m.AccountPage.id = "AccountPage"
    end if
    m.gPageContainer.appendChild(m.AccountPage)
    return m.AccountPage
end function

sub showHomePage(isReplace = false as boolean)
    m.HomePage = GetHomePageObject(true)
    if (isReplace = true)
        m.ViewStackManager.ReplaceScreen(m.HomePage)
    else
        m.ViewStackManager.ShowScreen(m.HomePage)
    end if
    ShowHideMenu(true)
    setFocus(m.HomePage)
end sub

function GetHomePageObject(isReplace as boolean) as object
    if isReplace
        m.gPageContainer.removeChild(m.HomePage)
        m.HomePage = invalid
    end if
    if isInvalid(m.HomePage)
        m.HomePage = createObject("roSGNode", "HomePage")
        m.HomePage.visible = true
        m.HomePage.id = "HomePage"
    end if
    m.gPageContainer.appendChild(m.HomePage)
    return m.HomePage
end function

sub showDetailPage(data as dynamic, isReplace = false as boolean)
    m.DetailPage = GetDetailPageObject(true)
    m.DetailPage.contentNode = data
    if (isReplace = true)
        m.ViewStackManager.ReplaceScreen(m.DetailPage)
    else
        m.ViewStackManager.ShowScreen(m.DetailPage)
    end if
    ShowHideMenu(false)
    setFocus(m.DetailPage)
end sub

function GetDetailPageObject(isReplace as boolean) as object
    if isValid(m.DetailPage) OR isReplace
        m.gPageContainer.removeChild(m.DetailPage)
        m.DetailPage = invalid
    end if
    m.DetailPage = createObject("roSGNode", "DetailPage")
    m.DetailPage.visible = true
    m.DetailPage.id = "DetailPage"
    m.gPageContainer.appendChild(m.DetailPage)
    return m.DetailPage
end function

sub showEventDetailPage(data as dynamic, isReplace = false as boolean)
    m.EventDetailPage = GetEventDetailPageObject(true)
    m.EventDetailPage.contentNode = data
    if (isReplace = true)
        m.ViewStackManager.ReplaceScreen(m.EventDetailPage)
    else
        m.ViewStackManager.ShowScreen(m.EventDetailPage)
    end if
    ShowHideMenu(false)
    setFocus(m.EventDetailPage)
end sub

function GetEventDetailPageObject(isReplace as boolean) as object
    if isValid(m.EventDetailPage) OR isReplace
        m.gPageContainer.removeChild(m.EventDetailPage)
        m.EventDetailPage = invalid
    end if
    m.EventDetailPage = createObject("roSGNode", "EventDetailPage")
    m.EventDetailPage.visible = true
    m.EventDetailPage.id = "EventDetailPage"
    m.gPageContainer.appendChild(m.EventDetailPage)
    return m.EventDetailPage
end function

sub showCategoryDetailPage(data as dynamic, isReplace = false as boolean)
    m.CategoryDetailPage = GetCategoryDetailPageObject(true)
    m.CategoryDetailPage.contentNode = data
    if (isReplace = true)
        m.ViewStackManager.ReplaceScreen(m.CategoryDetailPage)
    else
        m.ViewStackManager.ShowScreen(m.CategoryDetailPage)
    end if
    ShowHideMenu(false)
    setFocus(m.CategoryDetailPage)
end sub

function GetCategoryDetailPageObject(isReplace as boolean) as object
    if isValid(m.CategoryDetailPage) OR isReplace
        m.gPageContainer.removeChild(m.DetaCategoryDetailPageilPage)
        m.CategoryDetailPage = invalid
    end if
    m.CategoryDetailPage = createObject("roSGNode", "CategoryDetailPage")
    m.CategoryDetailPage.visible = true
    m.CategoryDetailPage.id = "CategoryDetailPage"
    m.gPageContainer.appendChild(m.CategoryDetailPage)
    return m.CategoryDetailPage
end function

sub ShowSearchPage(isReplace = false as boolean)
    m.SearchPage = GetSearchPageObject(true)
    if (isReplace = true)
        m.ViewStackManager.ReplaceScreen(m.SearchPage)
    else
        m.ViewStackManager.ShowScreen(m.SearchPage)
    end if
    setFocus(m.SearchPage)
end sub

function GetSearchPageObject(isReplace as boolean) as object
    if isValid(m.SearchPage) OR isReplace
        m.gPageContainer.removeChild(m.SearchPage)
        m.SearchPage = invalid
    end if
    m.SearchPage = createObject("roSGNode", "SearchPage")
    m.SearchPage.id = "SearchPage"
    m.SearchPage.visible = true
    m.gPageContainer.appendChild(m.SearchPage)
    return m.SearchPage
end function

sub ShowProgramsPage(isReplace = false as boolean)
    m.ShowProgramsPage = GetShowProgramsPageObject(true)
    if (isReplace = true)
        m.ViewStackManager.ReplaceScreen(m.ShowProgramsPage)
    else
        m.ViewStackManager.ShowScreen(m.ShowProgramsPage)
    end if
    setFocus(m.ShowProgramsPage)
end sub

function GetShowProgramsPageObject(isReplace as boolean) as object
    if isReplace
        m.gPageContainer.removeChild(m.ShowProgramsPage)
        m.ShowProgramsPage = invalid
    end if
    if isInvalid(m.ShowProgramsPage)
        m.ShowProgramsPage = createObject("roSGNode", "ProgramsPage")
        m.ShowProgramsPage.visible = true
        m.ShowProgramsPage.id = "ShowProgramsPage"
    end if
    m.gPageContainer.appendChild(m.ShowProgramsPage)
    return m.ShowProgramsPage
end function


sub ShowLivePage(isReplace = false as boolean)
    m.LivePage = GetLivePageObject(true)
    if (isReplace = true)
        m.ViewStackManager.ReplaceScreen(m.LivePage)
    else
        m.ViewStackManager.ShowScreen(m.LivePage)
    end if
    setFocus(m.LivePage)
end sub

function GetLivePageObject(isReplace as boolean) as object
    if isReplace
        m.gPageContainer.removeChild(m.LivePage)
        m.LivePage = invalid
    end if
    if isInvalid(m.LivePage)
        m.LivePage = createObject("roSGNode", "LivePage")
        m.LivePage.visible = true
        m.LivePage.id = "LivePage"
    end if
    m.gPageContainer.appendChild(m.LivePage)
    return m.LivePage
end function

sub ShowRadioPage(isReplace = false as boolean)
    m.RadioPage = GetRadioPageObject(true)
    if (isReplace = true)
        m.ViewStackManager.ReplaceScreen(m.RadioPage)
    else
        m.ViewStackManager.ShowScreen(m.RadioPage)
    end if
    setFocus(m.RadioPage)
end sub

function GetRadioPageObject(isReplace as boolean) as object
    if isReplace
        m.gPageContainer.removeChild(m.RadioPage)
        m.RadioPage = invalid
    end if
    if isInvalid(m.RadioPage)
        m.RadioPage = createObject("roSGNode", "RadioPage")
        m.RadioPage.visible = true
        m.RadioPage.id = "RadioPage"
    end if
    m.gPageContainer.appendChild(m.RadioPage)
    return m.RadioPage
end function

sub ShowMyListPage(isReplace = false as boolean)
    m.MyListPage = GetMyListPageObject(true)
    if (isReplace = true)
        m.ViewStackManager.ReplaceScreen(m.MyListPage)
    else
        m.ViewStackManager.ShowScreen(m.MyListPage)
    end if
    setFocus(m.MyListPage)
end sub

function GetMyListPageObject(isReplace as boolean) as object
    if isReplace
        m.gPageContainer.removeChild(m.MyListPage)
        m.MyListPage = invalid
    end if
    if isInvalid(m.MyListPage)
        m.MyListPage = createObject("roSGNode", "MyListPage")
        m.MyListPage.id = "MyListPage"
        m.MyListPage.visible = true
    end if
    m.gPageContainer.appendChild(m.MyListPage)
    return m.MyListPage
end function

sub StartVideo(videoData as dynamic)
    print "Main : StartVideo : videoID : " videoData
    if isValid(videoData) AND isNonEmptyString(getValueFromProps(videoData, "m3u8", ""))
        m.videoPlayerControl = GetVideoPlayer()
        m.top.appendChild(m.videoPlayerControl)
        m.videoPlayerControl.visible = true
        SetFocus(m.videoPlayerControl)
        m.videoPlayerControl.content = videoData
    else
        print "MainScene : StartVideo : Missing playable m3u8 URL."
        m.ViewStackManager.FocusTop()
    end if
end sub

sub GetVideoPlayer() as object
    if isValid(m.videoPlayerControl)
        m.top.removeChild(m.videoPlayerControl)
        m.videoPlayerControl = invalid
    end if
    m.videoPlayerControl = createObject("roSGNode", "VideoPlayer")
    m.videoPlayerControl.observeField("isVideoPlayerStopped", "StopVideoPlayback")
    m.videoPlayerControl.id = "videoPlayer"
    return m.videoPlayerControl
end sub

sub StopVideoPlayback()
    if m.videoPlayerControl <> invalid
        m.videoPlayerControl.visible = false
        m.top.removeChild(m.videoPlayerControl)
        m.videoPlayerControl = invalid
        m.ViewStackManager.FocusTop()
    end if
end sub

'===> Exit Confirmation
sub ShowHideExitConfirmation()
    print "MainScene : ShowHideExitConfirmation : "
    if(m.exitPopUpOpened = false)
        ShowConfirmationDialog("Are you sure you want to exit ?", "Exit", 200, "exit")
    else
        CloseExitConfirmation()
    end if
end sub

sub ShowLogoutConfirmation()
    if m.exitPopUpOpened = false
        ShowConfirmationDialog("¿Seguro que quieres cerrar sesión?", "Cerrar sesión", 270, "logout")
    else
        CloseExitConfirmation()
    end if
end sub

sub ShowConfirmationDialog(message as String, positiveButtonText as String, positiveButtonWidth as Integer, mode as String)
    m.exitDialogMode = mode
    m.dlgExit = CreateObject("roSGNode", "ExitDialog")
    m.dlgExit.id = "ExitDialog"
    m.dlgExit.positiveButtonText = positiveButtonText
    m.dlgExit.positiveButtonWidth = positiveButtonWidth
    m.dlgExit.message = message
    m.dlgExit.observeField("selectedButton", "OnExitDialogButtonSelected")
    m.top.appendChild(m.dlgExit)
    m.dlgExit.setFocus(true)
    m.exitPopUpOpened = true
end sub

sub CloseExitConfirmation()
    if isValid(m.dlgExit)
        m.top.removeChild(m.dlgExit)
        m.dlgExit = invalid
    end if
    m.exitPopUpOpened = false
    m.exitDialogMode = "exit"

    topNode = m.ViewStackManager.GetTop()
    if isValid(topNode) AND topNode.id = "AccountPage"
        SetFocus(topNode)
    else if isValid(m.TopMenu)
        SetFocus(m.TopMenu)
    else
        m.ViewStackManager.FocusTop()
    end if
end sub

sub OnExitDialogButtonSelected(event as dynamic)
    data = event.GetData()
    if data = 0
        CloseExitConfirmation()
    else if data = 1
        if m.exitDialogMode = "logout"
            CloseExitConfirmation()
            OnLogoutUser()
        else
            m.exitCalled = true
            m.top.outRequest = { "ExitApp": true }
        end if
    end if
end sub
'<=== Exit Confirmation

function OnkeyEvent(key as string, press as boolean) as boolean
    result = false
    if press
        print "MainScene : onKeyEvent : key = " key " press = " press
        if key = "back"
            result = HandleBackKey()
        else if key = "right"
            if (isValid(m.TopMenu) AND (m.TopMenu.hasFocus() OR m.TopMenu.IsInFocusChain()))
                m.ViewStackManager.FocusTop()
                result = true
            end if
        else if key = "left"
            if isValid(m.TopMenu) AND m.TopMenu.visible 'and topNode.id <> "DetailPage"
                SetFocus(m.TopMenu)
                result = true
            end if
        end if
    end if
    return result
end function

function HandleBackKey() as boolean
    result = false
    if (isValid(m.videoPlayerControl) AND m.videoPlayerControl.visible = true)
        print "MainScene : onKeyEvent : StopVideoPlayback"
        StopVideoPlayback()
        result = true
    else
        if (m.ViewStackManager.GetViewCount() > 1)
            topNode = m.viewStackManager.GetTop()
            m.ViewStackManager.HideTop()
            m.gPageContainer.removeChild(topNode)
            topNode = invalid
            if (m.ViewStackManager.GetViewCount() = 1 AND isValid(m.TopMenu) AND m.TopMenu.visible)
                topNode = m.viewStackManager.GetTop()
                if isValid(topNode) AND (LCase(topNode.id) <> "homepage") then m.top.isWatchHistoryFetched = false
                if isValid(topNode) AND (topNode.id = "loginPage" OR topNode.id = "onboardingPage" OR topNode.id = "DeviceLinkPage")
                else
                    ShowHideMenu(true)
                end if
            end if
            result = true
        else if m.exitCalled = false
            If(m.viewStackManager.GetViewCount() = 1) then
                if (m.TopMenu = invalid OR (isValid(m.TopMenu) AND (m.TopMenu.hasFocus() OR m.TopMenu.IsInFocusChain())))
                    If(m.exitPopUpOpened = false OR m.exitCalled = false)
                        ShowHideExitConfirmation()
                        result = true
                    End If
                else
                    if isValid(m.TopMenu) AND m.TopMenu.visible
                        SetFocus(m.TopMenu)
                        result = true
                    end if
                end if
            else
                m.ViewStackManager.FocusTop()
            end if
        end if
    end if
    return result
end function
