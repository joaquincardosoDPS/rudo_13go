function ContentAPI()
    gThis = GetGlobalAA()
    if gThis.ContentAPI = invalid
        gThis.ContentAPI = TVCHVContentAPI__New()
    end if
    return gThis.ContentAPI
end function

function TVCHVContentAPI__New()
    this = {}
    this.Login = TVCHVContentAPI__Login
    this.SignUp = TVCHVContentAPI__SignUp
    this.CheckValidToken = TVCHVContentAPI__CheckValidToken
    this.ProfileManagement = TVCHVContentAPI__ProfileManagement
    this.GetDeviceCodeAPI = TVCHVContentAPI__GetDeviceCodeAPI

    this.GetAllAvatar = TVCHVContentAPI__GetAllAvatar
    this.GetProfilesData = TVCHVContentAPI__GetProfilesData
    this.VerifyDevice = TVCHVContentAPI__VerifyDevice

    this.GetConfig = TVCHVContentAPI__GetConfig

    this.GetAllCategories = TVCHVContentAPI__GetAllCategories
    this.GetFeaturedSliderPrograms = TVCHVContentAPI__GetFeaturedSliderPrograms
    this.GetSearchPrograms = TVCHVContentAPI__GetSearchPrograms
    this.GetMyListPrograms = TVCHVContentAPI__GetMyListPrograms
    this.GetPrograms = TVCHVContentAPI__GetPrograms
    this.GetProgramDetails = TVCHVContentAPI__GetProgramDetails
    this.GetSeasonEpisodeDetails = TVCHVContentAPI__GetSeasonEpisodeDetails
    this.GetEpisodeDetails = TVCHVContentAPI__GetEpisodeDetails
    this.GetProgramEventsDetails = TVCHVContentAPI__GetProgramEventsDetails
    this.GetEventSeasonEpisodeDetails = TVCHVContentAPI__GetEventSeasonEpisodeDetails
    this.GetEPGData = TVCHVContentAPI__GetEPGData
    this.GetEPGPrograms = TVCHVContentAPI__GetEPGPrograms
    this.GetRecommendedPrograms = TVCHVContentAPI__GetRecommendedPrograms
    this.CheckItemInFavourite = TVCHVContentAPI__CheckItemInFavourite
    this.AddRemoveFavourite = TVCHVContentAPI__AddRemoveFavourite
    this.GetAllPrograms = TVCHVContentAPI__GetAllPrograms

    this.GetWatchHistory = TVCHVContentAPI__GetWatchHistory
    this.GetAllWatchHistory = TVCHVContentAPI__GetAllWatchHistory
    this.AddWatchHistory = TVCHVContentAPI__AddWatchHistory

    return this
end function

function TVCHVContentAPI__Login(params as dynamic)
    path = GlobalGet("apiEndPoints").Login
    headers = GetHeaders()
    data = {
        "device": "roku"
        "client": GlobalGet("appConfig").client
        "email": params.email,
        "password": params.password
    }
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__SignUp(params as dynamic)
    path = GlobalGet("apiEndPoints").SignUp
    headers = GetHeaders()
    data = {
        "client": GlobalGet("appConfig").client
        "device": "roku"
        "name": params.name,
        "email": params.email,
        "password": params.password
    }
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__CheckValidToken(params as object)
    path = GlobalGet("apiEndPoints").AutoLogin
    headers = GetHeaders()
    data = params
    data["client"] = GlobalGet("appConfig").client
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__GetProfilesData()
    path = GlobalGet("apiEndPoints").GetProfilesData
    headers = GetHeaders()
    data = {
        "client": GlobalGet("appConfig").client
        "token": GlobalGet("token")
    }
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__GetAllAvatar()
    path = GlobalGet("apiEndPoints").GetAllAvatar
    headers = GetHeaders()
    data = {
        "client": GlobalGet("appConfig").client
    }
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function


function TVCHVContentAPI__ProfileManagement(action as dynamic, params as dynamic)
    path = GlobalGet("apiEndPoints").ProfileManagement + action
    headers = GetHeaders()
    data = params
    data["token"] = GlobalGet("token")
    data["client"] = GlobalGet("appConfig").client

    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__GetDeviceCodeAPI()
    path = GlobalGet("apiEndPoints").GetDeviceCode
    headers = GetHeaders()
    data = {
        "client": GlobalGet("appConfig").client
    }
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__VerifyDevice(params as dynamic)
    path = GlobalGet("apiEndPoints").VerifyDevice
    headers = GetHeaders()
    data = params
    data["client"] = GlobalGet("appConfig").client
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__GetConfig()
    path = GlobalGet("apiEndPoints").GetConfig
    headers = GetHeaders()
    data = {}
    data["client"] = GlobalGet("appConfig").client
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__GetAllCategories(requestParams as object)
    path = GlobalGet("apiEndPoints").GetAllCategories
    headers = GetHeaders()
    data = requestParams
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__GetFeaturedSliderPrograms(requestParams as object)
    path = GlobalGet("apiEndPoints").GetFeaturedSliderPrograms
    headers = GetHeaders()
    data = {
        "client": GlobalGet("appConfig").client
        "page": requestParams.page
        "pageSize": GlobalGet("appConfig").pageSize
    }
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__GetSearchPrograms(params as object)
    path = GlobalGet("apiEndPoints").GetSearchPrograms
    headers = GetHeaders()
    data = params
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__GetMyListPrograms(requestParams = invalid as dynamic)
    path = GlobalGet("apiEndPoints").GetMyListPrograms
    headers = GetHeaders()
    data = {
        "token": GlobalGet("token"),
        "client": GlobalGet("appConfig").client,
        "profile": GlobalGet("selectedProfileID")
    }
    if isValid(requestParams)
        if requestParams.DoesExist("page") then data["page"] = requestParams.page
        if requestParams.DoesExist("limit") then data["limit"] = requestParams.limit
    end if
    headers = GetHeaders()
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__GetPrograms(params as object)
    path = GlobalGet("apiEndPoints").GetPrograms
    headers = GetHeaders()
    data = params
    data["client"] = GlobalGet("appConfig").client
    data["show_event"] = true
    data["show_ranking"] = true
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__GetAllPrograms(params as object)
    path = GlobalGet("apiEndPoints").GetAllPrograms
    headers = GetHeaders()
    data = params
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__GetProgramDetails(params as object)
    path = GlobalGet("apiEndPoints").GetProgramDetails
    headers = GetHeaders()
    data = params
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__GetSeasonEpisodeDetails(params as object)
    path = GlobalGet("apiEndPoints").GetSeasonEpisodeDetails
    headers = GetHeaders()
    data = params
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function


function TVCHVContentAPI__GetEpisodeDetails(params as object)
    path = GlobalGet("apiEndPoints").GetEpisodeDetails
    headers = GetHeaders()
    data = params
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__GetProgramEventsDetails(params as object)
    path = GlobalGet("apiEndPoints").GetProgramEventsDetails
    headers = GetHeaders()
    data = params
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__GetEventSeasonEpisodeDetails(params as object)
    path = GlobalGet("apiEndPoints").GetEventSeasonEpisodeDetails
    headers = GetHeaders()
    data = params
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function


function TVCHVContentAPI__GetEPGData()
    randomNumber = RND(10)
    path = GlobalGet("apiEndPoints").GetEPGChannels + randomNumber.toStr()
    headers = { "Content-Type": "application/json" }
    data = {}
    response = getRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__GetEPGPrograms()
    path = GlobalGet("apiEndPoints").GetEPGPrograms
    headers = { "Content-Type": "application/json" }
    data = {}
    response = getRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__GetRecommendedPrograms()
    path = GlobalGet("apiEndPoints").GetRecommendedPrograms
    headers = { "Content-Type": "application/json" }
    data = { "client": GlobalGet("appConfig").client }
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__CheckItemInFavourite(params as object)
    path = GlobalGet("apiEndPoints").CheckItemInFavourite
    headers = GetHeaders()
    data = params
    data["token"] = GlobalGet("token")
    data["client"] = GlobalGet("appConfig").client
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__AddRemoveFavourite(params as object)
    path = GlobalGet("apiEndPoints").AddRemoveFavourite + params.action
    headers = { "Content-Type": "application/json" }
    params["token"] = GlobalGet("token")
    data = params
    response = postRequest(path, data, headers, true)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__GetWatchHistory(params as object)
    path = GlobalGet("apiEndPoints").GetWatchHistory
    headers = GetHeaders()
    data = params
    data["token"] = GlobalGet("token")
    data["client"] = GlobalGet("appConfig").client
    data["profile"] = GlobalGet("selectedProfileID")
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__GetAllWatchHistory(params as object)
    path = GlobalGet("apiEndPoints").GetAllWatchHistory
    headers = GetHeaders()
    data = params
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function TVCHVContentAPI__AddWatchHistory(params as object)
    path = GlobalGet("apiEndPoints").AddWatchHistory
    headers = { "Content-Type": "application/json" }
    data = params
    data["token"] = GlobalGet("token")
    data["client"] = GlobalGet("appConfig").client
    response = postRequest(path, data, headers, true)
    return handleApiResponse(response)
end function

function GetHeaders() as dynamic
    headers = { "Content-Type": "application/x-www-form-urlencoded" }
    token = m.global.token
    if isValid(token) then headers["Authorization"] = "Bearer " + token
    return headers
end function

function handleApiResponse(response as object) as object
    if (response.isSuccess)
        result = ParseJSON(response.response)
        if isValid(result)
            return ok(result)
        else
            return Error("Invalid JSON response")
        end if
    else
        return Error(GetErrorReason(response))
    end if
end function
