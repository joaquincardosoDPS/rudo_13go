Sub SetGlobalNode()
    appConfig = GetAppConfigFromFile()
    deviceInfo = CreateObject("roDeviceInfo")
    globalFields = {
        appConfig: appConfig
        appTheme: GetAppThemeFromFile()
        apiEndPoints: GetApiEndPoints(appConfig)
        fonts: CreateFontManager()
        deviceId: deviceInfo.GetChannelClientId()
        deviceVersion: GetAppOsVersion()
        deviceModel: deviceInfo.GetModel()
        menuList: GetMenuList()
        designResolution: deviceInfo.GetDisplayMode()
    }
    m.global.AddFields(globalFields)
End Sub

Sub GetAppConfigFromFile() as Dynamic
    Print "Globals : GetAppConfigFromFile"
    config = ReadAsciiFile("pkg:/source/data/AppConfig.json")
    configJson = ParseJson(config)
    If configJson <> invalid
        Print "Globals : App config file loaded : " ' config
    Else
        Print "*** Error : Globals : Invalid configuration"
    End If

    Return configJson
End Sub

Sub GetAppThemeFromFile() as Dynamic
    Print "Globals : GetAppConfigFromFile"
    theme = ReadAsciiFile("pkg:/source/data/AppTheme.json")
    themeJson = ParseJson(theme)
    If themeJson <> invalid
        Print "Globals : GetAppThemeFromFile : App config file loaded : " ' config
    Else
        Print "*** Error : Globals : GetAppThemeFromFile : Invalid theme configuration!"
    End If

    Return themeJson
End Sub

function NormalizeThemeColorKeyName(key as String) as String
    if key = invalid OR Instr(1, key, "-") = 0
        return key
    end if
    if key = ""
        return ""
    end if
    normalizedKey = ""
    capitalizeNext = false
    for i = 0 to Len(key) - 1
        currentChar = Mid(key, i + 1, 1)
        if currentChar = "-"
            capitalizeNext = true
        else if capitalizeNext
            normalizedKey = normalizedKey + UCase(currentChar)
            capitalizeNext = false
        else
            normalizedKey = normalizedKey + currentChar
        end if
    end for
    return normalizedKey
end function

function MergeMissingConfigColorsIntoTheme(themeJson as Object, configJson as Object) as Object
    mergedTheme = {}
    if themeJson <> invalid
        mergedTheme.Append(themeJson)
    end if
    if configJson = invalid
        return mergedTheme
    end if
    for each key in configJson
        value = configJson[key]
        if not IsThemeColorValue(value)
            continue for
        end if
        normalizedKey = NormalizeThemeColorKeyName(key)
        if not mergedTheme.DoesExist(normalizedKey)
            mergedTheme[normalizedKey] = value
        end if
    end for
    return mergedTheme
end function

function IsThemeColorValue(value as Dynamic) as Boolean
    if Type(value) <> "roString"
        return false
    end if
    return Left(value, 1) = "#" OR LCase(value) = "transparent"
end function

function GetMenuList() as object
    textLabels = ReadAsciiFile("pkg:/source/data/LocalMenu.json")
    labels = ParseJson(textLabels)
    return labels
end function

Sub GetApiEndPoints(appConfig as object) as dynamic
    Print "Globals : GetApiEndPoints : appConfig : " appConfig
    baseUrl = appConfig.baseUrl
    apiEndPoints = {
        ' Auth API end points
        Login: baseUrl + "users/login"
        SignUp: baseUrl + "users/register"
        AutoLogin: baseUrl + "users/session"
        GetDeviceCode: baseUrl + "users/device_code"
        VerifyDevice: baseUrl + "users/device_verify"

        GetConfig: baseUrl + "config/all"

        ' Profile API end points
        GetProfilesData: baseUrl + "profile/all"
        AddProfile: baseUrl + "profile/add"
        DeleteProfile: baseUrl + "profile/delete" 
        UpdateProfile: baseUrl + "profile/update"
        GetAllAvatar: baseUrl + "avatar/all"
        ProfileManagement: baseUrl + "profile/"

        ' Content API end points
        GetAllCategories: baseUrl + "categories/all"
        GetFeaturedSliderPrograms: baseUrl + "programs/slider"
        GetMyListPrograms: baseUrl + "favorites/all"
        GetSearchPrograms: baseUrl + "programs/all"
        GetPrograms: baseUrl + "categories/all"
        GetAllPrograms: baseUrl + "programs/all"
        GetProgramDetails: baseUrl + "programs/get"
        GetProgramEventsDetails: baseUrl + "events/get"
        GetEventSeasonEpisodeDetails: baseUrl + "events/all"
        GetSeasonEpisodeDetails: baseUrl + "chapters/all"
        GetEpisodeDetails: baseUrl + "chapters/get"
        GetEPGChannels: "https://cdn.rudo.video/assets/" + appConfig.client + "/playlists/static/playlist.json?random="
        GetEPGPrograms: "https://cdn.rudo.video/assets/" + appConfig.client + "/playlists/global_epg.json"
        GetRecommendedPrograms: baseUrl + "programs/recommended"
        CheckItemInFavourite: baseUrl + "favorites/validate"
        AddRemoveFavourite: baseUrl + "favorites/"
        GetWatchHistory: baseUrl + "history/get"
        GetAllWatchHistory: baseUrl + "history/all"
        AddWatchHistory: baseUrl + "history/add"
    }
    Return apiEndPoints
End Sub 
