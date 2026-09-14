
Sub SetGlobalNode()
    appConfig = GetAppConfigFromFile()
    deviceInfo = CreateObject("roDeviceInfo")
    globalFields = {
        appConfig: appConfig,
        appTheme: GetAppThemeFromFile(),
        apiEndPoints: GetApiEndPoints(appConfig),
        fonts: CreateFontManager(),
        deviceId: deviceInfo.GetChannelClientId(),
        deviceVersion: GetAppOsVersion()
        deviceModel: deviceInfo.GetModel()
        menuList: GetMenuList(),
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
    End if

    Return configJson

End Sub

Sub GetAppThemeFromFile() as Dynamic
    Print "Globals : GetAppThemeFromFile"
    theme = ReadAsciiFile("pkg:/source/data/AppTheme.json")
    themeJson = ParseJson(theme)
    If themeJson <> invalid
        Print "Globals : GetAppThemeFromFile : App theme file loaded : " ' theme
    Else
        Print "*** Error : Globals : GetAppThemeFromFile : Invalid theme configuration!"
    End if

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
        currentChar = Mid(key, i+1, 1)
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


Sub GetApiEndPoints(appConfig as object) as Dynamic
    Print "Globals : GetApiEndPoints : appConfig : " appConfig
    feedBaseUrl = appConfig.feedBaseUrl
    cdnBaseUrl = appConfig.cdnBaseUrl
    tenant = appConfig.tenant

    apiEndPoints = {
        ' Gateway único: auth y perfiles viven acá, diferenciados por "action"/"path" en el POST (se arma en Paso 4)
        Gateway: appConfig.gatewayUrl

        ' Catálogo: feed tipo WordPress en 13.cl
        GetConfig: feedBaseUrl + "configuracion",
        GetHomeConfig: feedBaseUrl + "configuracion-portada",
        GetCategoryPrograms: feedBaseUrl + "categorias/",
        GetPrograms: feedBaseUrl + "programas",
        GetVideos: feedBaseUrl + "video",
        GetSearch: feedBaseUrl + "search",

        ' Streaming / EPG: CDN de rudo.video, bajo el tenant "canal-13"
        GetEPGChannels: cdnBaseUrl + "assets/" + tenant + "/playlists/static/playlist.json?random="
        GetEPGPrograms: cdnBaseUrl + "assets/" + tenant + "/playlists/global_epg.json"
        GetPlaylistPremium: cdnBaseUrl + "assets/" + tenant + "/playlists/static/playlist_premium.json"
        GetRadios: cdnBaseUrl + "assets/" + tenant + "/playlists/static/radios.json"

        ' Info de medios (API de rudo.video)
        GetVodMediaInfo: appConfig.rudoApiUrl + "v3/media/info"
    }

    Return apiEndPoints

End Sub
