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
    CheckValidToken()
end sub

sub CheckValidToken()
    userToken = m.registryManager.GetToken()
    if isNonEmptyString(userToken)
        if isValid(m.checkValidTokenTask) Then
            m.checkValidTokenTask.control = "stop"
        end if
        m.checkValidTokenTask = CreateObject("roSGNode", "AuthAPIAction")
        m.checkValidTokenTask.functionName = "CheckValidToken"
        m.checkValidTokenTask.params = { "token": userToken }
        m.checkValidTokenTask.ObserveField("result", "OnCheckValidTokenAPIResponse")
        m.checkValidTokenTask.control = "RUN"
    else
        ShowHideLoader(false)
        StartApp()
    end if
    sendAppLaunchCompleteBeacon()
end sub

sub OnCheckValidTokenAPIResponse(event as dynamic)
    response = event.getData()
    print "Mainscene : OnCheckValidTokenAPIResponse " 'FormatJson(response)
    hasValidToken = false
    response = getValueFromProps(response.data, "data", {})
    If isValid(response) AND isValid(response.user) AND isValid(response.user.token) AND response.user.token <> ""
        m.registryManager.SaveUserData(response.user)
        GlobalSet("UserData", response.user)
        m.registryManager.SaveToken(response.user.token)
        GlobalSet("token", response.user.token)
        hasValidToken = true
    end if
    ShowHideLoader(false)
    if (hasValidToken = true)
        print "Valid User ................. "
        m.top.isUserLoggedIn = true
        ShowEditorProfilesPage(true)
    else
        print "Not Valid User"
        StartApp()
    end if
    m.checkValidTokenTask = invalid
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
    if pageId = "EditorProfilesPage" OR pageId = "OnboardingPage" OR pageId = "LoginPage" OR pageId = "SignUpPage" OR pageId = "DeviceLinkPage"
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
    if isValid(pageName)
        if pageName = "Radios"
            ' TODO Paso 5: pantalla de Radios pendiente de construir. Por ahora no navega a ningun lado.
            return
        end if

        targetPageId = ""
        if pageName = "Portada"
            targetPageId = "homepage"
        else if pageName = "Búsqueda"
            targetPageId = "searchpage"
        else if pageName = "Programas"
            targetPageId = "showprogramspage"
        else if pageName = "En vivo"
            targetPageId = "livepage"
        end if

        topNode = m.ViewStackManager.GetTop()
        if isValid(topNode) AND isNonEmptyString(targetPageId) AND LCase(topNode.id) = targetPageId
            return
        end if

        if isValid(m.HomePage) then m.HomePage.isDestroy = true
        if isValid(m.LivePage) then m.LivePage.isDestroy = true
        if isValid(m.MyListPage) then m.MyListPage.isDestroy = true
        if pageName = "Portada"
            ShowHomePage(true)
        else if pageName = "Búsqueda"
            ShowSearchPage(true)
        else if pageName = "Programas"
            ShowProgramsPage(true)
        else if pageName = "En vivo"
            ShowLivePage(true)
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
    m.registryManager.ClearAllSettings()
    GlobalSet("UserData", {})
    GlobalSet("token", "")
    m.top.isUserLoggedIn = false
    m.viewStackManager.HideAll()
    UpdateSelectedTopMenu(0)
    showHomePage(true)
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

sub ShowLoginPage(isReplace = false as boolean)
    LoginPage = GetLoginPageObject(isReplace)
    if (isReplace = true)
        m.ViewStackManager.ReplaceScreen(LoginPage)
    else
        m.ViewStackManager.ShowScreen(LoginPage)
    end if
    setFocus(LoginPage)
end sub

function GetLoginPageObject(isReplace as boolean) as object
    LoginPage = createObject("roSGNode", "LoginPage")
    LoginPage.visible = true
    LoginPage.id = "LoginPage"
    ShowHideMenu(false)
    m.gPageContainer.appendChild(LoginPage)
    return LoginPage
end function

sub ShowSignUpPage(isReplace = false as boolean)
    SignUpPage = GetSignUpPageObject(isReplace)
    if (isReplace = true)
        m.ViewStackManager.ReplaceScreen(SignUpPage)
    else
        m.ViewStackManager.ShowScreen(SignUpPage)
    end if
    ShowHideMenu(false)
    setFocus(SignUpPage)
end sub

function GetSignUpPageObject(isReplace as boolean) as object
    SignUpPage = createObject("roSGNode", "SignUpPage")
    SignUpPage.visible = true
    SignUpPage.id = "SignUpPage"
    m.gPageContainer.appendChild(SignUpPage)
    return SignUpPage
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
    ShowHideMenu(false)
    setFocus(m.AccountPage)
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
