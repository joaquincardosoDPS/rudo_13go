' Utilidades del reproductor, calcadas de c13_reloaded/src/services/hlsSessionService.ts.

' Parametros de sesion del redirector DPS (getHlsSessionParams): dpssid
' persistente por dispositivo (ndvc = "1" solo la primera vez que se genera),
' sid nuevo en cada reproduccion y la plataforma. Se guarda en una seccion
' propia del registry para que no se borre al cerrar sesion (en la web vive en
' localStorage, fuera de la sesion).
function GetDpsSessionParams() as object
    reg = CreateObject("roRegistrySection", "Canal13GoDevice")
    dpssid = ""
    ndvc = "0"
    if reg.Exists("dpssid") then dpssid = reg.Read("dpssid")
    if not isNonEmptyString(dpssid)
        dpssid = "b" + NewSessionHex()
        reg.Write("dpssid", dpssid)
        reg.Flush()
        ndvc = "1"
    end if
    return {
        dpssid: dpssid
        ndvc: ndvc
        sid: "s" + NewSessionHex()
        platform: "13GOTVRoku"
    }
end function

' 32 caracteres hex al azar (bin2hex(random_bytes(16)) en la web).
function NewSessionHex() as string
    return LCase(CreateObject("roDeviceInfo").GetRandomUUID().Replace("-", ""))
end function

' forceSessionParams: agrega (o reemplaza) dpssid/ndvc/sid/platform en la URL.
' El redirector los propaga solo a cada calidad del m3u8, asi que en Roku
' alcanza con ponerlos en la URL principal.
function ForceSessionParams(url as string, params as object) as string
    if not isNonEmptyString(url) then return url
    keys = ["dpssid", "ndvc", "sid", "platform"]
    base = url
    query = ""
    q = Instr(1, url, "?")
    if q > 0
        base = Left(url, q - 1)
        query = Mid(url, q + 1)
    end if
    parts = []
    if query <> ""
        for each pair in query.Split("&")
            if pair <> ""
                name = pair.Split("=")[0]
                keep = true
                for each key in keys
                    if name = key then keep = false
                end for
                if keep then parts.Push(pair)
            end if
        end for
    end if
    for each key in keys
        parts.Push(key + "=" + params[key])
    end for
    return base + "?" + parts.Join("&")
end function

' Variantes (#EXT-X-STREAM-INF) de un m3u8 maestro: [{ height, bandwidth, url }]
' ordenadas de mayor a menor bitrate. height = 0 si no trae RESOLUTION (audio).
function ParseHlsVariants(playlistText as string) as object
    variants = []
    lines = playlistText.Replace(Chr(13), "").Split(Chr(10))
    regexRes = CreateObject("roRegex", "RESOLUTION=(\d+)x(\d+)", "i")
    regexBw = CreateObject("roRegex", "BANDWIDTH=(\d+)", "i")
    n = lines.count()
    i = 0
    while i < n
        line = lines[i].Trim()
        if UCase(Left(line, 18)) = "#EXT-X-STREAM-INF:"
            bandwidth = 0
            height = 0
            match = regexBw.Match(line)
            if match.count() > 1 then bandwidth = Val(match[1])
            match = regexRes.Match(line)
            if match.count() > 2 then height = Int(Val(match[2]))
            j = i + 1
            while j < n AND (lines[j].Trim() = "" OR Left(lines[j].Trim(), 1) = "#")
                j = j + 1
            end while
            if j < n then variants.Push({ height: height, bandwidth: bandwidth, url: lines[j].Trim() })
            i = j + 1
        else
            i = i + 1
        end if
    end while
    for a = 0 to variants.count() - 2
        for b = 0 to variants.count() - 2 - a
            if variants[b].bandwidth < variants[b + 1].bandwidth
                tmp = variants[b]
                variants[b] = variants[b + 1]
                variants[b + 1] = tmp
            end if
        end for
    end for
    return variants
end function

' Resuelve la URL de una variante relativa al m3u8 maestro (el redirector de
' rudo tambien atiende las listas de cada calidad).
function ResolveHlsUrl(baseUrl as string, ref as string) as string
    if LCase(Left(ref, 4)) = "http" then return ref
    base = baseUrl
    q = Instr(1, base, "?")
    if q > 0 then base = Left(base, q - 1)
    if Left(ref, 1) = "/"
        hostEnd = Instr(Instr(1, base, "://") + 3, base, "/")
        if hostEnd > 0 then return Left(base, hostEnd - 1) + ref
        return base + ref
    end if
    lastSlash = 0
    for k = 1 to Len(base)
        if Mid(base, k, 1) = "/" then lastSlash = k
    end for
    return Left(base, lastSlash) + ref
end function

' URL final del anuncio, como VideoPlayer.tsx + VastPlayer.tsx: primero la
' sesion DPS (forceSessionParams) y despues appendAdParamsToVastUrl de
' deviceAdService.ts. En vez del TIFA/LGUDID de Samsung/LG va el ID publicitario
' de Roku (RIDA, idtype=rida) y si el usuario limito el seguimiento, is_lat=1.
function BuildVastUrl(vastUrl as string, session as object) as string
    url = vastUrl
    while Instr(1, url, "&amp;") > 0
        url = url.Replace("&amp;", "&")
    end while
    url = ForceSessionParams(url, session)
    base = url
    query = ""
    q = Instr(1, url, "?")
    if q > 0
        base = Left(url, q - 1)
        query = Mid(url, q + 1)
    end if
    ' Parametros en orden (como un objeto de JS): [{ key, value }]
    params = []
    if query <> ""
        for each pair in query.Split("&")
            if pair <> ""
                eq = Instr(1, pair, "=")
                if eq = 0
                    params.Push({ key: pair, value: "" })
                else
                    params.Push({ key: Left(pair, eq - 1), value: Mid(pair, eq + 1) })
                end if
            end if
        end for
    end if
    deviceInfo = CreateObject("roDeviceInfo")
    rida = deviceInfo.GetRIDA()
    if isNonEmptyString(rida)
        isLat = "0"
        if deviceInfo.IsRIDADisabled() then isLat = "1"
        SetUrlParam(params, "rdid", rida.EncodeUriComponent())
        SetUrlParam(params, "is_lat", isLat)
        SetUrlParam(params, "idtype", "rida")
    end if
    if GetUrlParam(params, "correlator") = "" then SetUrlParam(params, "correlator", (Rnd(2147483646)).ToStr() + (Rnd(99999)).ToStr())
    if GetUrlParam(params, "unviewed_position_start") = "" then SetUrlParam(params, "unviewed_position_start", "1")
    if GetUrlParam(params, "vpos") = "" then SetUrlParam(params, "vpos", "preroll")
    if GetUrlParam(params, "impl") = "" then SetUrlParam(params, "impl", "s")
    ' La web cambia sz 512x288 -> 640x480, pero las campañas de estos ad units son
    ' de 512x288: con 640x480 Google responde vacio (medido: 0/32 contra 32/32).
    ' Se deja el sz que manda el feed.
    ' Solo para Google Ad Manager
    if Instr(1, base, "pubads.g.doubleclick.net") > 0 OR Instr(1, base, "googleads.g.doubleclick.net") > 0
        iu = GetUrlParam(params, "iu")
        if Instr(1, iu, "app.13go.cl") > 0 then SetUrlParam(params, "iu", iu.Replace("app.13go.cl", "13go.cl"))
        SetUrlParam(params, "url", "https://www.13go.cl".EncodeUriComponent())
        SetUrlParam(params, "ref", "https://www.13go.cl/".EncodeUriComponent())
        description = GetUrlParam(params, "description_url")
        if description = "" OR Instr(1, description, "localhost") > 0 then SetUrlParam(params, "description_url", "https://www.13go.cl".EncodeUriComponent())
        SetUrlParam(params, "env", "vp")
    end if
    parts = []
    for each param in params
        parts.Push(param.key + "=" + param.value)
    end for
    return base + "?" + parts.Join("&")
end function

function GetUrlParam(params as object, key as string) as string
    for each param in params
        if param.key = key then return param.value
    end for
    return ""
end function

sub SetUrlParam(params as object, key as string, value as string)
    for each param in params
        if param.key = key
            param.value = value
            return
        end if
    end for
    params.Push({ key: key, value: value })
end sub
