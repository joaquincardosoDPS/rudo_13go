sub init()
    setLocals()
    setControls()
    setupFonts()
    setupColors()
    setObservers()
    initialize()
end sub

sub setLocals()
    m.scene = m.top.GetScene()
    m.theme = m.global.appTheme
    m.fonts = m.global.Fonts
    m.playlist = []
    m.programation = []
    m.loadedPlaylist = false
    m.loadedEpg = false
    m.channels = []
    m.rowNodes = []
    m.selectedIndex = 0
    m.overlayShown = false
    m.focusArea = "grid"
    m.controlIndex = 0
    m.gridRow = 0
    m.gridItem = 0
    m.scrollY = 0
    m.isPaused = false
    m.loaded = false
    m.rowHeight = 117
    m.rowGap = 5
    m.clipHeight = 441
    m.gridWidth = 1721
end sub

sub setControls()
    m.vLive = m.top.findNode("vLive")
    m.gOverlay = m.top.findNode("gOverlay")
    m.pFadeBottom = m.top.findNode("pFadeBottom")
    m.pPill = m.top.findNode("pPill")
    m.lEnvivo = m.top.findNode("lEnvivo")
    m.lChannelName = m.top.findNode("lChannelName")
    m.lProgramTitle = m.top.findNode("lProgramTitle")
    m.gControls = m.top.findNode("gControls")
    m.bPause = m.top.findNode("bPause")
    m.pPauseBg = m.top.findNode("pPauseBg")
    m.pPauseIcon = m.top.findNode("pPauseIcon")
    m.pPauseFocus = m.top.findNode("pPauseFocus")
    m.bQuality = m.top.findNode("bQuality")
    m.pQualBg = m.top.findNode("pQualBg")
    m.pQualFocus = m.top.findNode("pQualFocus")
    m.lQualLabel = m.top.findNode("lQualLabel")
    m.lQualValue = m.top.findNode("lQualValue")
    m.gGridClip = m.top.findNode("gGridClip")
    m.gGridTrack = m.top.findNode("gGridTrack")
    m.tHide = m.top.findNode("tHide")
    m.bsLoading = m.top.findNode("bsLoading")
end sub

sub setupFonts()
    m.lEnvivo.font = m.fonts.dmSansBold18
    m.lChannelName.font = m.fonts.dmSansBold48
    m.lProgramTitle.font = m.fonts.dmSansMedium23
    m.lQualLabel.font = m.fonts.dmSansMedium20
    m.lQualValue.font = m.fonts.dmSansMedium20
end sub

sub setupColors()
    m.pPill.blendColor = "#FF0000"
    m.pPauseBg.blendColor = "#1C1D28"
    m.pQualBg.blendColor = "#1C1D28"
    m.pPauseFocus.blendColor = m.theme.focPrimary
    m.pQualFocus.blendColor = m.theme.focPrimary
    m.pPauseIcon.blendColor = "#FFFFFF"
    m.lProgramTitle.color = m.theme.white
end sub

sub setObservers()
    m.top.observeField("focusedChild", "onFocusedChild")
    m.top.observeField("visible", "onVisibleChange")
    m.tHide.observeField("fire", "onHideTimer")
    m.vLive.observeField("state", "onVideoState")
end sub

sub onVisibleChange(event as dynamic)
    if not event.getData()
        if isValid(m.vLive)
            m.vLive.control = "stop"
            m.vLive.content = invalid
        end if
        setMenuVisible(true)
    end if
end sub

sub initialize()
    m.pPauseIcon.uri = "pkg:/images/PlayerOverlayIcon/pause.png"
    showLoading(true)
    setMenuVisible(false)
    getPlaylist()
    getEpg()
end sub

sub setMenuVisible(flag as boolean)
    if isValid(m.scene)
        m.scene.callFunc("ShowHideMenu", flag)
    end if
end sub

sub onPageDestroy()
    if m.top.isDestroy
        if isValid(m.vLive)
            m.vLive.control = "stop"
            m.vLive.content = invalid
        end if
        m.tHide.control = "stop"
        setMenuVisible(true)
        if isValid(m.getPlaylistTask) then m.getPlaylistTask.control = "stop"
        if isValid(m.getEpgTask) then m.getEpgTask.control = "stop"
        if isValid(m.getQualitiesTask) then m.getQualitiesTask.control = "stop"
    end if
end sub

sub showLoading(flag as boolean)
    m.bsLoading.visible = flag
end sub

'===> Data
sub getPlaylist()
    m.getPlaylistTask = CreateObject("roSGNode", "ContentAPIAction")
    m.getPlaylistTask.functionName = "GetJsonByUrl"
    m.getPlaylistTask.params = { "url": m.global.apiEndPoints.GetPlaylistPremium }
    m.getPlaylistTask.observeField("result", "onPlaylistResponse")
    m.getPlaylistTask.control = "RUN"
end sub

sub onPlaylistResponse(event as dynamic)
    apiResponse = event.getData()
    items = getValueFromProps(apiResponse, "data.data", [])
    m.playlist = items
    m.loadedPlaylist = true
    m.getPlaylistTask = invalid
    tryBuildChannels()
end sub

sub getEpg()
    m.getEpgTask = CreateObject("roSGNode", "ContentAPIAction")
    m.getEpgTask.functionName = "GetJsonByUrl"
    m.getEpgTask.params = { "url": m.global.apiEndPoints.GetEPGPrograms }
    m.getEpgTask.observeField("result", "onEpgResponse")
    m.getEpgTask.control = "RUN"
end sub

sub onEpgResponse(event as dynamic)
    apiResponse = event.getData()
    items = getValueFromProps(apiResponse, "data", [])
    m.programation = items
    m.loadedEpg = true
    m.getEpgTask = invalid
    tryBuildChannels()
end sub

sub tryBuildChannels()
    if not (m.loadedPlaylist AND m.loadedEpg) then return
    buildChannels()
    if m.channels.count() = 0
        showLoading(false)
        return
    end if
    buildRows()
    m.loaded = true
    showLoading(false)
    selectChannel(0)
end sub

function nowEpoch() as integer
    nd = CreateObject("roDateTime")
    nd.Mark()
    return nd.AsSeconds()
end function

' ISO 8601 UTC (YYYY-MM-DDTHH:MM:SS...) -> epoch (segundos). No depende de
' fromISO8601String (que en algunos equipos/emulador no parsea el offset).
function isoToEpoch(iso as string) as integer
    if Len(iso) < 19 then return 0
    y = Val(Mid(iso, 1, 4))
    mo = Val(Mid(iso, 6, 2))
    d = Val(Mid(iso, 9, 2))
    h = Val(Mid(iso, 12, 2))
    mi = Val(Mid(iso, 15, 2))
    s = Val(Mid(iso, 18, 2))
    yy = y
    mm = mo
    if mm <= 2
        yy = yy - 1
        mm = mm + 12
    end if
    era = Int(yy / 400)
    yoe = yy - era * 400
    doy = Int((153 * (mm - 3) + 2) / 5) + d - 1
    doe = yoe * 365 + Int(yoe / 4) - Int(yoe / 100) + doy
    days = era * 146097 + doe - 719468
    return days * 86400 + h * 3600 + mi * 60 + s
end function

function epochToLocalHHMM(epoch as integer) as string
    nd = CreateObject("roDateTime")
    nd.fromSeconds(epoch)
    nd.toLocalTime()
    h = nd.GetHours()
    mi = nd.GetMinutes()
    hs = h.ToStr()
    ms = mi.ToStr()
    if h < 10 then hs = "0" + hs
    if mi < 10 then ms = "0" + ms
    return hs + ":" + ms
end function

sub buildChannels()
    m.channels = []
    nowE = nowEpoch()
    for each item in m.playlist
        active = getValueFromProps(item, "active", false)
        if not active then continue for
        keyLive = getValueFromProps(item, "key_live", "")
        programs = []
        for each epgItem in m.programation
            if getValueFromProps(epgItem, "key_live", "") = keyLive
                events = getValueFromProps(epgItem, "events", [])
                for each ev in events
                    endE = isoToEpoch(getValueFromProps(ev, "endTime", ""))
                    if endE > nowE
                        if programs.count() >= 5 then exit for
                        beginE = isoToEpoch(getValueFromProps(ev, "beginTime", ""))
                        programs.push({
                            "title": getValueFromProps(ev, "title", "")
                            "timeText": epochToLocalHHMM(beginE)
                            "isLive": (nowE >= beginE AND nowE <= endE)
                        })
                    end if
                end for
                exit for
            end if
        end for
        restriction = getValueFromProps(item, "restriction", "0")
        m.channels.push({
            "key_live": keyLive
            "name_live": getValueFromProps(item, "name_live", "")
            "logo": getValueFromProps(item, "logo", "")
            "color": getValueFromProps(item, "color", "")
            "preview_m3u8": getValueFromProps(item, "preview_m3u8", "")
            "m3u8": getValueFromProps(item, "m3u8", "")
            "blocked": (restriction <> "0")
            "programs": programs
        })
    end for
end sub

sub buildRows()
    m.gGridTrack.removeChildrenIndex(m.gGridTrack.getChildCount(), 0)
    m.rowNodes = []
    pitch = m.rowHeight + m.rowGap
    for i = 0 to m.channels.count() - 1
        ch = m.channels[i]
        row = CreateObject("roSGNode", "LiveChannelRow")
        row.rowWidth = m.gridWidth
        row.rowHeight = m.rowHeight
        row.logo = ch.logo
        row.channelName = ch.name_live
        row.ringColor = ch.color
        row.blocked = ch.blocked
        row.programs = ch.programs
        row.focusedItemIndex = -1
        row.translation = [0, i * pitch]
        m.gGridTrack.appendChild(row)
        m.rowNodes.push(row)
    end for
end sub

'===> Player
sub selectChannel(index as integer)
    if index < 0 OR index >= m.channels.count() then return
    ch = m.channels[index]
    if ch.blocked then return
    m.selectedIndex = index
    updateHeader(ch)
    playUrl(ch.preview_m3u8, ch.m3u8)
    hideOverlay()
end sub

sub updateHeader(ch as dynamic)
    m.lChannelName.text = ch.name_live
    if ch.programs.count() > 0
        m.lProgramTitle.text = ch.programs[0].title
    else
        m.lProgramTitle.text = ""
    end if
end sub

sub playUrl(previewUrl as string, fallbackUrl as string)
    url = previewUrl
    if not isNonEmptyString(url) then url = fallbackUrl
    if not isNonEmptyString(url) then return
    m.masterPlaylistUrl = url
    m.availableQualities = [{ "label": "Auto", "url": url }]
    m.qualityIndex = 0
    m.lQualValue.text = "Auto"
    startPlayback(url)
    fetchQualities(url)
end sub

sub startPlayback(url as string)
    content = CreateObject("roSGNode", "ContentNode")
    content.url = url
    content.streamformat = "hls"
    content.live = true
    m.isPaused = false
    updatePauseIcon()
    m.vLive.content = content
    m.vLive.control = "play"
end sub

'===> Calidad (parseo del manifest HLS para listar las variantes reales)
sub fetchQualities(url as string)
    if isValid(m.getQualitiesTask) then m.getQualitiesTask.control = "stop"
    m.getQualitiesTask = CreateObject("roSGNode", "ContentAPIAction")
    m.getQualitiesTask.functionName = "GetTextByUrl"
    m.getQualitiesTask.params = { "url": url }
    m.getQualitiesTask.observeField("result", "onQualitiesResponse")
    m.getQualitiesTask.control = "RUN"
end sub

sub onQualitiesResponse(event as dynamic)
    response = event.getData()
    m.getQualitiesTask = invalid
    if not isValid(response) OR not response.ok then return
    variants = parseHlsVariants(response.data)
    if variants.count() = 0 then return
    qualities = [{ "label": "Auto", "url": m.masterPlaylistUrl }]
    for each v in variants
        qualities.push({ "label": v.label, "url": v.url })
    end for
    m.availableQualities = qualities
    m.qualityIndex = 0
end sub

' Extrae las variantes (#EXT-X-STREAM-INF) de un manifest maestro HLS, ordenadas
' de mayor a menor calidad.
function parseHlsVariants(playlistText as string) as object
    variants = []
    regexCR = CreateObject("roRegex", chr(13), "")
    lines = regexCR.ReplaceAll(playlistText, "").Split(chr(10))
    n = lines.count()
    regexInf = CreateObject("roRegex", "^#EXT-X-STREAM-INF:", "i")
    regexRes = CreateObject("roRegex", "RESOLUTION=(\d+)x(\d+)", "i")
    regexBw = CreateObject("roRegex", "BANDWIDTH=(\d+)", "i")
    i = 0
    while i < n
        line = lines[i].Trim()
        if regexInf.IsMatch(line)
            bandwidth = 0
            label = ""
            bwMatch = regexBw.Match(line)
            if bwMatch.count() > 1 then bandwidth = Val(bwMatch[1])
            resMatch = regexRes.Match(line)
            if resMatch.count() > 2
                label = resMatch[2] + "p"
            else if bandwidth > 0
                label = Str(Int(bandwidth / 1000)).Trim() + " kbps"
            end if
            j = i + 1
            while j < n AND (lines[j].Trim() = "" OR Left(lines[j].Trim(), 1) = "#")
                j = j + 1
            end while
            if j < n AND isNonEmptyString(label)
                variants.push({ "label": label, "url": lines[j].Trim(), "bandwidth": bandwidth })
            end if
            i = j
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

sub cycleQuality()
    if not isValid(m.availableQualities) OR m.availableQualities.count() <= 1 then return
    m.qualityIndex = (m.qualityIndex + 1) mod m.availableQualities.count()
    q = m.availableQualities[m.qualityIndex]
    m.lQualValue.text = q.label
    startPlayback(q.url)
end sub

sub togglePause()
    if m.isPaused
        m.vLive.control = "play"
        m.isPaused = false
    else
        m.vLive.control = "pause"
        m.isPaused = true
    end if
    updatePauseIcon()
end sub

sub updatePauseIcon()
    if m.isPaused
        m.pPauseIcon.uri = "pkg:/images/PlayerOverlayIcon/play.png"
    else
        m.pPauseIcon.uri = "pkg:/images/PlayerOverlayIcon/pause.png"
    end if
end sub

sub onVideoState(event as dynamic)
end sub

'===> Overlay / focus
sub showOverlay()
    if m.overlayShown then return
    m.overlayShown = true
    m.gOverlay.visible = true
    setMenuVisible(true)
    m.pFadeBottom.visible = true
    m.vLive.translation = [672, 0]
    m.vLive.width = 1248
    m.vLive.height = 702
    m.focusArea = "grid"
    applyGridFocus()
    updateScroll()
    updateFocusVisuals()
    resetHideTimer()
end sub

sub hideOverlay()
    if not m.overlayShown then return
    m.overlayShown = false
    m.gOverlay.visible = false
    setMenuVisible(false)
    m.pFadeBottom.visible = false
    m.vLive.translation = [0, 0]
    m.vLive.width = 1920
    m.vLive.height = 1080
    m.tHide.control = "stop"
end sub

sub resetHideTimer()
    m.tHide.control = "stop"
    m.tHide.control = "start"
end sub

sub onHideTimer()
    hideOverlay()
end sub

function programCount(row as integer) as integer
    if row < 0 OR row >= m.channels.count() then return 0
    return m.channels[row].programs.count()
end function

sub clampGridItem()
    count = programCount(m.gridRow)
    if count <= 0
        m.gridItem = 0
    else if m.gridItem > count - 1
        m.gridItem = count - 1
    end if
end sub

sub applyGridFocus()
    for i = 0 to m.rowNodes.count() - 1
        if i = m.gridRow
            m.rowNodes[i].focusedItemIndex = m.gridItem
        else
            m.rowNodes[i].focusedItemIndex = -1
        end if
    end for
end sub

sub clearGridFocus()
    for i = 0 to m.rowNodes.count() - 1
        m.rowNodes[i].focusedItemIndex = -1
    end for
end sub

sub updateFocusVisuals()
    inControls = (m.focusArea = "controls")
    m.pPauseFocus.visible = (inControls AND m.controlIndex = 0)
    m.pQualFocus.visible = (inControls AND m.controlIndex = 1)
end sub

sub updateScroll()
    pitch = m.rowHeight + m.rowGap
    y = m.gridRow * pitch
    if y < m.scrollY then m.scrollY = y
    if y + pitch > m.scrollY + m.clipHeight then m.scrollY = y + pitch - m.clipHeight
    total = m.rowNodes.count() * pitch - m.rowGap
    maxScroll = total - m.clipHeight
    if maxScroll < 0 then maxScroll = 0
    if m.scrollY < 0 then m.scrollY = 0
    if m.scrollY > maxScroll then m.scrollY = maxScroll
    m.gGridTrack.translation = [0, -m.scrollY]
end sub

sub onFocusedChild()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if not m.loaded then return false

    if not m.overlayShown
        if key = "OK" then togglePause()
        showOverlay()
        return true
    end if

    resetHideTimer()

    if m.focusArea = "controls"
        if key = "OK"
            if m.controlIndex = 0
                togglePause()
            else
                cycleQuality()
            end if
            return true
        else if key = "left"
            if m.controlIndex > 0
                m.controlIndex = m.controlIndex - 1
                updateFocusVisuals()
                return true
            end if
            return false
        else if key = "right"
            if m.controlIndex < 1
                m.controlIndex = m.controlIndex + 1
                updateFocusVisuals()
                return true
            end if
            return false
        else if key = "down"
            m.focusArea = "grid"
            m.gridRow = 0
            m.gridItem = 0
            applyGridFocus()
            updateScroll()
            updateFocusVisuals()
            return true
        end if
        return false
    end if

    ' focusArea = "grid"
    if key = "OK"
        selectChannel(m.gridRow)
        return true
    else if key = "left"
        if m.gridItem > 0
            m.gridItem = m.gridItem - 1
            applyGridFocus()
            return true
        end if
        return false
    else if key = "right"
        count = programCount(m.gridRow)
        if m.gridItem < count - 1
            m.gridItem = m.gridItem + 1
            applyGridFocus()
        end if
        return true
    else if key = "up"
        if m.gridRow > 0
            m.gridRow = m.gridRow - 1
            clampGridItem()
            applyGridFocus()
            updateScroll()
            return true
        end if
        m.focusArea = "controls"
        m.controlIndex = 0
        clearGridFocus()
        updateFocusVisuals()
        return true
    else if key = "down"
        if m.gridRow < m.rowNodes.count() - 1
            m.gridRow = m.gridRow + 1
            clampGridItem()
            applyGridFocus()
            updateScroll()
        end if
        return true
    end if
    return false
end function

