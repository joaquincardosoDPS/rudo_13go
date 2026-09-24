function ContentAPI()
    gThis = GetGlobalAA()
    if gThis.ContentAPI = invalid
        gThis.ContentAPI = ContentAPI__New()
    end if
    return gThis.ContentAPI
end function

function ContentAPI__New()
    this = {}
    ' Auth y perfiles: todo va por el gateway único (ver bloque más abajo)
    this.GetDeviceCode = ContentAPI__GetDeviceCode
    this.VerifyDevice = ContentAPI__VerifyDevice
    this.RefreshToken = ContentAPI__RefreshToken
    this.GetUserProfile = ContentAPI__GetUserProfile
    this.GetUserInfo = ContentAPI__GetUserInfo
    this.GetProfilesData = ContentAPI__GetProfilesData
    this.GetAvatarBaseUrl = ContentAPI__GetAvatarBaseUrl
    this.UpdateProfile = ContentAPI__UpdateProfile
    this.GetProfileData = ContentAPI__GetProfileData
    this.AuthenticateContent = ContentAPI__AuthenticateContent
    this.GetTracking = ContentAPI__GetTracking
    this.UpdateTracking = ContentAPI__UpdateTracking
    this.GetFavorites = ContentAPI__GetFavorites
    this.SaveFavorite = ContentAPI__SaveFavorite

    ' Vista de programa (feed 13.cl)
    this.GetProgramBySlug = ContentAPI__GetProgramBySlug
    this.GetProgramCategories = ContentAPI__GetProgramCategories
    this.GetProgramChapters = ContentAPI__GetProgramChapters

    ' Reproductor de capitulos (PlayerView)
    this.GetEpisodeByLink = ContentAPI__GetEpisodeByLink
    this.GetVodMediaInfo = ContentAPI__GetVodMediaInfo

    ' Analitica (GA4)
    this.SendAnalyticsHit = ContentAPI__SendAnalyticsHit

    this.GetConfig = ContentAPI__GetConfig
    this.GetHomeConfig = ContentAPI__GetHomeConfig

    this.GetCategoryPrograms = ContentAPI__GetCategoryPrograms
    this.GetJsonByUrl = ContentAPI__GetJsonByUrl
    this.GetTextByUrl = ContentAPI__GetTextByUrl
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


' ===================================================================
' Gateway de 13go: auth y perfiles
' -------------------------------------------------------------------
' A diferencia de MiCHV (un endpoint REST por accion), 13go expone un
' unico POST (https://rudo.video/gateway/13go/) donde la operacion se
' elige con el campo "action". Con action=firebase, ademas, el campo
' "path" apunta al documento de Firestore a leer/escribir.
' Referencia: c13_reloaded/src/features/auth/services/authentication.ts
' y c13_reloaded/src/services/profileService.ts
' ===================================================================

function ContentAPI__GatewayPost(data as object)
    path = GlobalGet("apiEndPoints").Gateway
    headers = { "Content-Type": "application/x-www-form-urlencoded" }
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

' Lectura/escritura de Firestore a traves del gateway. El token va SIEMPRE
' como campo del form (el gateway no usa el header Authorization).
function ContentAPI__FirebaseRequest(firebasePath as string, extraData = invalid as dynamic)
    data = {
        "action": "firebase"
        "path": firebasePath
        "token": GetAccessToken()
    }
    if isValid(extraData)
        for each key in extraData
            data[key] = extraData[key]
        end for
    end if
    return ContentAPI__GatewayPost(data)
end function

' Paso 1 del device linking: pide el codigo que se muestra en pantalla.
' Respuesta: { data: { device_code, user_code, interval, expires, status } }
function ContentAPI__GetDeviceCode()
    return ContentAPI__GatewayPost({ "action": "deviceCode" })
end function

' Paso 2: se consulta cada "interval" segundos hasta que el usuario aprueba
' el dispositivo en la web. Mientras espera devuelve status=error/message=pending.
' Al aprobar: { data: { access_token, refresh_token, expires_in, token_type, user_id } }
function ContentAPI__VerifyDevice(params as dynamic)
    return ContentAPI__GatewayPost({
        "action": "deviceToken"
        "device_code": getValueFromProps(params, "deviceCode", "")
    })
end function

function ContentAPI__RefreshToken(params as dynamic)
    return ContentAPI__GatewayPost({
        "action": "refreshToken"
        "refresh_token": getValueFromProps(params, "refreshToken", "")
    })
end function

' Datos personales del usuario (nombre, genero, fecha de nacimiento...).
function ContentAPI__GetUserProfile()
    return ContentAPI__FirebaseRequest("/userProfile/" + GetUserId())
end function

' Estado de la suscripcion (subscriptionStatus, plans, products, ads_free).
function ContentAPI__GetUserInfo()
    return ContentAPI__FirebaseRequest("/userInfo/" + GetUserId())
end function

' Perfiles de la cuenta: array de documentos Firestore con fields.order/name/avatar.
function ContentAPI__GetProfilesData()
    return ContentAPI__FirebaseRequest("/userAccount/" + GetUserId() + "/profiles")
end function

' URL base de los avatares: se le concatena "<avatar>.jpg" de cada perfil.
function ContentAPI__GetAvatarBaseUrl()
    return ContentAPI__FirebaseRequest("/appData/avatars")
end function

' Un perfil puntual (EditProfileView): { data: { name: {stringValue}, avatar: {stringValue} } }
function ContentAPI__GetProfileData(params as dynamic)
    profileOrder = getValueFromProps(params, "profile", "")
    return ContentAPI__FirebaseRequest("/userAccount/" + GetUserId() + "/profiles/profile-" + profileOrder + "/")
end function

' TrackingService.getTracking: historial de reproduccion del perfil
' ({ data: [{ key_rudo, fields: { event_type, seconds, duration } }] }).
function ContentAPI__GetTracking(params as dynamic)
    return ContentAPI__FirebaseRequest("/accountTracking/" + GetUserId() + "/history", {
        "profile": getValueFromProps(params, "profile", "")
    })
end function

' TrackingService.updateTracking: guarda el punto de avance de un VOD
' (event_type "progress" | "end"). Alimenta "Reanudar" y "Seguir viendo".
function ContentAPI__UpdateTracking(params as dynamic)
    return ContentAPI__GatewayPost({
        "action": "contentTracking"
        "token": GetAccessToken()
        "profile_id": "profile-" + getValueFromProps(params, "profile", "")
        "content_id": getValueFromProps(params, "contentId", "")
        "event_type": getValueFromProps(params, "eventType", "progress")
        "seconds": getValueFromProps(params, "seconds", "0")
        "duration": getValueFromProps(params, "duration", "0")
        "restriction": getValueFromProps(params, "restriction", "0")
        "title": getValueFromProps(params, "title", "")
        "show": getValueFromProps(params, "show", "")
        "image": getValueFromProps(params, "image", "")
        "path": getValueFromProps(params, "path", "")
    })
end function

' FavoriteService.getFavorites: { data: { <id>: { fields: { nid, slug, id_program, status } } } }
function ContentAPI__GetFavorites(params as dynamic)
    profileId = "profile-" + getValueFromProps(params, "profile", "")
    return ContentAPI__FirebaseRequest("/accountMyList/" + GetUserId() + "/categories/" + profileId + "/items")
end function

' FavoriteService.addFavorite/removeFavorite: mismo POST, status active/inactive.
function ContentAPI__SaveFavorite(params as dynamic)
    return ContentAPI__GatewayPost({
        "action": "saveFavorites"
        "token": GetAccessToken()
        "user_id": GetUserId()
        "profile_id": "profile-" + getValueFromProps(params, "profile", "")
        "nid": getValueFromProps(params, "nid", "")
        "tid": getValueFromProps(params, "tid", "")
        "title": getValueFromProps(params, "title", "")
        "slug": getValueFromProps(params, "slug", "")
        "imagen_vertical": getValueFromProps(params, "imagen_vertical", "")
        "url": getValueFromProps(params, "url", "")
        "status": getValueFromProps(params, "status", "active")
    })
end function

' Canal13GoService.getProgramBySlug: [{ title, description, fondo_imagen, config_id, tid, on_air, video_key, ... }]
function ContentAPI__GetProgramBySlug(params as dynamic)
    path = GlobalGet("apiEndPoints").GetProgramBySlug
    headers = { "Content-Type": "application/json" }
    return handleApiResponse(getRequest(path + "?v=/programas/" + getValueFromProps(params, "slug", ""), {}, headers))
end function

' Canal13GoService.getRudoCategoriesVod: [{ name, id, show }]
function ContentAPI__GetProgramCategories(params as dynamic)
    path = GlobalGet("apiEndPoints").GetProgramVod
    headers = { "Content-Type": "application/json" }
    return handleApiResponse(getRequest(path + getValueFromProps(params, "slug", "") + "/categorias", {}, headers))
end function

' Canal13GoService.getRudoCategoriesVodChapters: { data: [{ key, title, image, duration, link, restriction, packs }] }
' La categoria va codificada a mano (puede traer tildes, espacios o "&").
function ContentAPI__GetProgramChapters(params as dynamic)
    path = GlobalGet("apiEndPoints").GetProgramVod
    headers = { "Content-Type": "application/json" }
    category = getValueFromProps(params, "category", "")
    url = (path + getValueFromProps(params, "slug", "")).EncodeUri() + "?t=" + category.EncodeUriComponent()
    return handleApiResponse(getRequest(url, {}, headers, true))
end function

' Canal13GoService.getProgramByLink: feed/video?v={link del capitulo} ->
' [{ title, category, show, id, restriccion, vast_app, live_redirect, ... }]
function ContentAPI__GetEpisodeByLink(params as dynamic)
    path = GlobalGet("apiEndPoints").GetVideos
    headers = { "Content-Type": "application/json" }
    return handleApiResponse(getRequest(path + "?v=" + getValueFromProps(params, "link", ""), {}, headers))
end function

' RudoService.getVodMediaInfo: { status, data: { key, m3u8, duration, restriction, ... } }
function ContentAPI__GetVodMediaInfo(params as dynamic)
    path = GlobalGet("apiEndPoints").GetVodMediaInfo + "/" + getValueFromProps(params, "key", "")
    headers = { "X-ACCESS-TOKEN": getValueFromProps(GlobalGet("appConfig"), "rudoAccessToken", "") }
    return handleApiResponse(getRequest(path, {}, headers))
end function

' ga4Service.ts: el hit va entero en la URL (g/collect?v=2&tid=...) como un POST
' sin cuerpo. GA4 responde 204 sin contenido, asi que no se parsea.
function ContentAPI__SendAnalyticsHit(params as dynamic)
    response = postRequest(getValueFromProps(params, "url", ""), {}, {})
    if response.isSuccess then return ok("")
    return error(GetErrorReason(response))
end function

function ContentAPI__UpdateProfile(params as dynamic)
    profileOrder = getValueFromProps(params, "profile", "")
    return ContentAPI__FirebaseRequest("/userAccount/" + GetUserId() + "/profiles/profile-" + profileOrder + "/", {
        "name": getValueFromProps(params, "name", "")
        "avatar": getValueFromProps(params, "avatar", "")
        "store_method": "update"
    })
end function

' Firma la reproduccion de un contenido restringido (type = "live" | "vod").
function ContentAPI__AuthenticateContent(params as dynamic)
    return ContentAPI__GatewayPost({
        "action": "authContent"
        "token": GetAccessToken()
        "type": getValueFromProps(params, "type", "vod")
        "id": getValueFromProps(params, "id", "")
    })
end function

function GetAccessToken() as string
    token = GlobalGet("token")
    if isNonEmptyString(token) then return token
    return ""
end function

function GetUserId() as string
    userId = GlobalGet("userId")
    if isNonEmptyString(userId) then return userId
    return ""
end function

function ContentAPI__GetConfig()
    path = GlobalGet("apiEndPoints").GetConfig
    headers = { "Content-Type": "application/json" }
    data = {}
    response = getRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__GetCategoryPrograms(categoryId as string)
    path = GlobalGet("apiEndPoints").GetCategoryPrograms + categoryId
    headers = { "Content-Type": "application/json" }
    data = { }
    response = getRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__GetJsonByUrl(requestParams as object)
    path = requestParams.url
    headers = { "Content-Type": "application/json" }
    data = {}
    response = getRequest(path, data, headers)
    return handleApiResponse(response)
end function

' A diferencia de GetJsonByUrl, no intenta parsear la respuesta como JSON.
' Se usa para traer texto plano (ej: un manifest .m3u8 de HLS).
function ContentAPI__GetTextByUrl(requestParams as object)
    path = requestParams.url
    headers = {}
    data = {}
    response = getRequest(path, data, headers)
    if response.isSuccess
        return ok(response.response)
    else
        return error(getErrorReason(response))
    end if
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
    headers = { "Content-Type": "application/json" }
    data = { }
    response = getRequest(path, data, headers)
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

' Favoritos/historial (Paso 4d.5) todavia no esta implementado para 13go - no
' hay endpoint equivalente cargado en apiEndPoints (ver Global.brs). Estas tres
' funciones son heredadas de MiCHV; se dejan sin borrar porque HomePage.brs/
' DetailPage.brs/VideoPlayer.brs ya las llaman, pero devuelven error en vez de
' crashear (path quedaba Invalid -> Type Mismatch en postRequest, crash real
' visto en un Roku con telnet conectado apenas el login funciono por primera vez).
function ContentAPI__GetWatchHistory(params as object)
    path = GlobalGet("apiEndPoints").GetWatchHistory
    if not isNonEmptyString(path) then return error("GetWatchHistory: endpoint no implementado (pendiente 4d.5)")
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
    if not isNonEmptyString(path) then return error("GetAllWatchHistory: endpoint no implementado (pendiente 4d.5)")
    headers = GetHeaders()
    data = params
    response = postRequest(path, data, headers)
    return handleApiResponse(response)
end function

function ContentAPI__AddWatchHistory(params as object)
    path = GlobalGet("apiEndPoints").AddWatchHistory
    if not isNonEmptyString(path) then return error("AddWatchHistory: endpoint no implementado (pendiente 4d.5)")
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

function ContentAPI__GetHomeConfig()
    ' Lista de secciones del home'
    path = GlobalGet("apiEndPoints").GetHomeConfig
    headers = { "Content-Type": "application/json" }
    data = {}
    response = getRequest(path, data, headers)
    return handleApiResponse(response)
end function