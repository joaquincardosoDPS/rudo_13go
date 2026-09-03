function ContentAPI()
    gThis = GetGlobalAA()
    if gThis.ContentAPI = invalid
        gThis.ContentAPI = ContentAPI__New()
    end if
    return gThis.ContentAPI
end function

function ContentAPI__New()
    this = {}
    this.Login = ContentAPI__Login
    this.SignUp = ContentAPI__SignUp
    this.CheckValidToken = ContentAPI__CheckValidToken
    this.ProfileManagement = ContentAPI__ProfileManagement
    this.GetDeviceCodeAPI = ContentAPI__GetDeviceCodeAPI

    this.GetAllAvatar = ContentAPI__GetAllAvatar
    this.GetProfilesData = ContentAPI__GetProfilesData
    this.VerifyDevice = ContentAPI__VerifyDevice

    this.GetConfig = ContentAPI__GetConfig

    this.GetAllCategories = ContentAPI__GetAllCategories
    this.GetFeaturedSliderPrograms = ContentAPI__GetFeaturedSliderPrograms
    this.GetSearchPrograms = ContentAPI__GetSearchPrograms
    this.GetMyListPrograms = ContentAPI__GetMyListPrograms
    this.GetPrograms = ContentAPI__GetPrograms
    this.GetProgramDetails = ContentAPI__GetProgramDetails
    this.GetSeasonEpisodeDetails = ContentAPI__GetSeasonEpisodeDetails
    this.GetEpisodeDetails = ContentAPI__GetEpisodeDetails
    this.GetProgramEventsDetails = ContentAPI__GetProgramEventsDetails
    this.GetEventSeasonEpisodeDetails = ContentAPI__GetEventSeasonEpisodeDetails
    this.GetEPGData = ContentAPI__GetEPGData
    this.GetEPGPrograms = ContentAPI__GetEPGPrograms
    this.GetRecommendedPrograms = ContentAPI__GetRecommendedPrograms
    this.CheckItemInFavourite = ContentAPI__CheckItemInFavourite
    this.AddRemoveFavourite = ContentAPI__AddRemoveFavourite
    this.GetAllPrograms = ContentAPI__GetAllPrograms

    this.GetWatchHistory = ContentAPI__GetWatchHistory
    this.GetAllWatchHistory = ContentAPI__GetAllWatchHistory
    this.AddWatchHistory = ContentAPI__AddWatchHistory

    return this
end function

function ContentAPI__Login(params as dynamic)
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

function ContentAPI__SignUp(params as dynamic)
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

function ContentAPI__CheckValidToken(params as object)
    path = GlobalGet("apiEndPoints").AutoLogin
    headers = GetHeaders()
    data = params
    data["client"] = GlobalGet("appConfig").client
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__GetProfilesData()
    path = GlobalGet("apiEndPoints").GetProfilesData
    headers = GetHeaders()
    data = {
        "client": GlobalGet("appConfig").client
        "token": GlobalGet("token")
    }
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__GetAllAvatar()
    path = GlobalGet("apiEndPoints").GetAllAvatar
    headers = GetHeaders()
    data = {
        "client": GlobalGet("appConfig").client
    }
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function


function ContentAPI__ProfileManagement(action as dynamic, params as dynamic)
    path = GlobalGet("apiEndPoints").ProfileManagement + action
    headers = GetHeaders()
    data = params
    data["token"] = GlobalGet("token")
    data["client"] = GlobalGet("appConfig").client

    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__GetDeviceCodeAPI()
    path = GlobalGet("apiEndPoints").GetDeviceCode
    headers = GetHeaders()
    data = {
        "client": GlobalGet("appConfig").client
    }
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__VerifyDevice(params as dynamic)
    path = GlobalGet("apiEndPoints").VerifyDevice
    headers = GetHeaders()
    data = params
    data["client"] = GlobalGet("appConfig").client
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__GetConfig()
    path = GlobalGet("apiEndPoints").GetConfig
    headers = { "Content-Type": "application/json" }
    data = {}
    response = getRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__GetAllCategories(requestParams as object)
    path = GlobalGet("apiEndPoints").GetAllCategories
    headers = GetHeaders()
    data = requestParams
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__GetFeaturedSliderPrograms(requestParams as object)
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

function ContentAPI__GetSearchPrograms(params as object)
    path = GlobalGet("apiEndPoints").GetSearchPrograms
    headers = GetHeaders()
    data = params
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__GetMyListPrograms(requestParams = invalid as dynamic)
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

function ContentAPI__GetPrograms(params as object)
    path = GlobalGet("apiEndPoints").GetPrograms
    headers = GetHeaders()
    data = params
    data["client"] = GlobalGet("appConfig").client
    data["show_event"] = true
    data["show_ranking"] = true
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__GetAllPrograms(params as object)
    path = GlobalGet("apiEndPoints").GetAllPrograms
    headers = GetHeaders()
    data = params
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__GetProgramDetails(params as object)
    path = GlobalGet("apiEndPoints").GetProgramDetails
    headers = GetHeaders()
    data = params
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__GetSeasonEpisodeDetails(params as object)
    path = GlobalGet("apiEndPoints").GetSeasonEpisodeDetails
    headers = GetHeaders()
    data = params
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function


function ContentAPI__GetEpisodeDetails(params as object)
    path = GlobalGet("apiEndPoints").GetEpisodeDetails
    headers = GetHeaders()
    data = params
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__GetProgramEventsDetails(params as object)
    path = GlobalGet("apiEndPoints").GetProgramEventsDetails
    headers = GetHeaders()
    data = params
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__GetEventSeasonEpisodeDetails(params as object)
    path = GlobalGet("apiEndPoints").GetEventSeasonEpisodeDetails
    headers = GetHeaders()
    data = params
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function


function ContentAPI__GetEPGData()
    randomNumber = RND(10)
    path = GlobalGet("apiEndPoints").GetEPGChannels + randomNumber.toStr()
    headers = { "Content-Type": "application/json" }
    data = {}
    response = getRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__GetEPGPrograms()
    path = GlobalGet("apiEndPoints").GetEPGPrograms
    headers = { "Content-Type": "application/json" }
    data = {}
    response = getRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__GetRecommendedPrograms()
    path = GlobalGet("apiEndPoints").GetRecommendedPrograms
    headers = { "Content-Type": "application/json" }
    data = { "client": GlobalGet("appConfig").client }
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__CheckItemInFavourite(params as object)
    path = GlobalGet("apiEndPoints").CheckItemInFavourite
    headers = GetHeaders()
    data = params
    data["token"] = GlobalGet("token")
    data["client"] = GlobalGet("appConfig").client
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__AddRemoveFavourite(params as object)
    path = GlobalGet("apiEndPoints").AddRemoveFavourite + params.action
    headers = { "Content-Type": "application/json" }
    params["token"] = GlobalGet("token")
    data = params
    response = postRequest(path, data, headers, true)
    return handleApiResponse(response)
end function

function ContentAPI__GetWatchHistory(params as object)
    path = GlobalGet("apiEndPoints").GetWatchHistory
    headers = GetHeaders()
    data = params
    data["token"] = GlobalGet("token")
    data["client"] = GlobalGet("appConfig").client
    data["profile"] = GlobalGet("selectedProfileID")
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__GetAllWatchHistory(params as object)
    path = GlobalGet("apiEndPoints").GetAllWatchHistory
    headers = GetHeaders()
    data = params
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__AddWatchHistory(params as object)
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