sub Init()
    setLocals()
    setControls()
    setupPageLoader()
    setupFonts()
    setupColors()
    setObservers()
    initialize()
end sub

sub setLocals()
    m.scene = m.top.GetScene()
    m.theme = m.global.appTheme
    m.fonts = m.global.Fonts
    initVar()
end sub

sub setControls()
    m.epgGrid = m.top.findNode("epgGrid")
    m.noData = m.top.findNode("noData")
    m.lNow = m.top.findNode("lNow")
    m.lComing = m.top.findNode("lComing")
    m.lgDetailSection = m.top.findNode("lgDetailSection")
    m.refreshSchedule = m.top.findNode("refreshSchedule")
    m.gridColTitle = m.top.findNode("gridColTitle")
    m.epgSection = m.top.findNode("epgSection")
    m.lDay = m.top.findNode("lDay")
    m.vLivePlayer = m.top.findNode("vLivePlayer")
    m.bigLivePlayer = m.top.findNode("bigLivePlayer")
    m.smallLivePlayer = m.top.findNode("smallLivePlayer")
    m.bsLoader = m.top.findNode("bsLoader")

    m.vLivePlayer.enableTrickPlay = false
    m.vLivePlayer.enableUI = false
end sub

sub setupFonts()
    m.noData.font = m.fonts.dmSansBold32
    m.lNow.font = m.fonts.dmSansMedium30
    m.lComing.font = m.fonts.dmSansMedium30
    m.lDay.font = m.fonts.dmSansMedium30
end sub

sub setupPageLoader()
    m.bsLoader.poster.uri = "pkg:/images/loader/loader_image.png"
    m.bsLoader.poster.width = 100
    m.bsLoader.poster.height = 100
    m.bsLoader.poster.loadwidth = 100
    m.bsLoader.poster.loadheight = 100
    m.bsLoader.poster.blendColor = m.theme.focPrimary
    m.bsLoader.poster.loadDisplayMode = "scaleToFit"
end sub

sub setupColors()
    m.noData.color = m.theme.white
    m.lNow.color = m.theme.focPrimary
    m.lComing.color = m.theme.focPrimary
    m.lDay.color = m.theme.focPrimary
end sub

sub setObservers()
    m.top.observeField("focusedChild", "onFocusedChild")
    m.epgGrid.observeField("itemFocused", "onItemFocused")
    m.epgGrid.observeField("itemSelected", "onItemSelected")
    m.epgGrid.observeField("jumpToMenu", "onJumpToMenu")
    m.refreshSchedule.observeField("fire", "onRefreshSchedules")
    m.top.observeField("visible", "onVisibleChange")
    m.vLivePlayer.observeField("bufferingStatus", "handleBufferingStatus")
end sub

sub initVar()
    m.isbigLivePlayerAnimation = false
    m.liveVideoStatus = ""
    m.lastPlayedChannel = ""
    m.focusedChildNode = invalid
    m.isRAFAdsPlaying = false

    m.isFirstTime = true
    m.lastFocusIndex = 1
    m.networkErrorWhenLoadingData = false
    m.hasDataLoadedOnce = false
    m.isDataAvailable = false
end sub

sub onPageDestroy()
    if m.top.isDestroy
        initVar()
        m.refreshSchedule.control = "stop"
        if isValid(m.vLivePlayer)
            m.vLivePlayer.control = "stop"
            m.vLivePlayer.content = invalid
        end if
        if isValid(m.getEPGDataTask)
            m.getEPGDataTask.control = "stop"
            m.getEPGDataTask = invalid
        end if
        if isValid(m.getEPGProgramDataTask)
            m.getEPGProgramDataTask.control = "stop"
            m.getEPGProgramDataTask = invalid
        end if
        allPlayerAndTaskReset()
        if isValid(m.epgGrid) AND isValid(m.epgGrid.content)
            m.epgGrid.content.RemoveChildrenIndex(m.epgGrid.content.GetChildCount(), 0)
        end if
        m.epgGrid.content = invalid
    end if
end sub

sub onVisibleChange(event as dynamic)
    visible = event.GetData()
    if not visible
        if isValid(m.vLivePlayer)
            m.vLivePlayer.control = "stop"
            m.vLivePlayer.content = invalid
        end if
    end if
end sub

sub OnVideoPlayerStatusChange(event as dynamic)
    videoStatus = event.GetData()
    node = event.getRoSGNode()
    m.liveVideoStatus = videoStatus
    if videoStatus = "playing"
        showHidePageLoader(false)
    else if videoStatus = "finished"
        if isValid(node) AND isNonEmptyString(node.id) AND node.id = "PlayerTask"
            showHidePageLoader(true, false)
            m.vLivePlayer.control = "play"
        else
            allPlayerAndTaskReset()
        end if
        SetFocus(m.epgGrid)
    end if
end sub

sub OnVideoPositionChanged(event as dynamic)
    videoPosition = event.GetData()
    if videoPosition \ 1 = 30
        print "OnVideoPositionChanged : "videoPosition
    end if
end sub

sub handleBufferingStatus(event as dynamic)
    bufferingStatus = event.getData()
    if bufferingStatus <> invalid
        if not m.isbigLivePlayerAnimation then showHidePageLoader(true, false)
        m.loadingPercentage = bufferingStatus.percentage
        if m.loadingPercentage = 100
            showHidePageLoader(false)
        end if
    end if
end sub

sub initialize()
    ' todayDate = CreateObject("roDateTime")
    m.lDay.text = "Hoy" 'todayDate.GetWeekday()
    m.lNow.text = "Ahora"
    m.lComing.text = "A continuación" 
    createEPGView()
end sub

sub showHidePageLoader(visible as boolean, isCenter = true as boolean)
    if visible = m.bsLoader.visible then return
    m.bsLoader.visible = visible
    if isCenter
        m.bsLoader.translation = "[910,490]"
    else
        m.bsLoader.translation = "[511, 387.5]"
    end if
end sub

sub onRefreshPage()
    if m.networkErrorWhenLoadingData AND m.isDataAvailable'only refresh data if network error has occurred while loading the data
        m.networkErrorWhenLoadingData = false
        refreshData() 
        'TODO: need to check the case where partial data is loaded and partial is failed due to network error
        ' this case is might no be possible as we are setting translation once all the data is loaded. in checkAppendNodes. but verify.
    end if
    restoreFocus()
end sub

sub refreshData()
    m.noData.visible = false
    m.isRefreshing = true
    ' proccessPageComponents()
end sub

' sub onPageComponents(event as object)
'     pageComponents = event.getData()
'     components = getValueFromProps(pageComponents, "components", [])
'     if (components.count() > 0)
'         componentsArray = getValueFromProps(components, "0.components", [])
'         if (componentsArray.count() > 0)
'             m.isDataAvailable = true
'             m.EPGComponents = componentsArray
'             proccessPageComponents()
'         end if
'     end if
'     if not m.isDataAvailable
'         m.scene.callFunc("showHideLoader", false)
'         showNoData()
'     end if
' end sub

sub proccessPageComponents()
    createEPGView()
end sub

sub showNoData()
    m.epgSection.visible = false
    m.noData.text = "No hay datos disponibles"
    m.noData.visible = true
    setFocus(m.noData)
end sub

sub createEPGView()
    m.epgSection.visible = false
    getEPGData()
end sub

sub getEPGPrograms()
    showHidePageLoader(true)
    m.getEPGProgramDataTask = CreateObject("roSGNode", "ContentAPIAction")
    m.getEPGProgramDataTask.functionName = "GetEPGPrograms"
    m.getEPGProgramDataTask.observeField("result", "OnGetEPGProgramsAPIResponse")
    m.getEPGProgramDataTask.control = "RUN"
end sub

sub OnGetEPGProgramsAPIResponse(event as dynamic)
    response = event.getData()
    print "OnGetEPGProgramsAPIResponse : response : " 'formatjson(response)
    if isValid(response) AND isValid(response.data) AND isValid(response.data) AND response.data.count() > 0
        m.epgData = makeEPGChannelWiseData(response.data)
        m.hasDataLoadedOnce = true
        mainContent = createObject("roSGNode", "contentNode")
        gridIndex = 0
        for each liveItem in m.epgData
            contentNode = createObject("roSGNode", "EPGItemData")
            contentNode.addFields({ colIndex: 0, index: gridIndex })
            contentNode.setFields(liveItem)
            mainContent.appendChild(contentNode)
            gridIndex++
            if isValid(liveItem.events) then liveItem.events.SortBy("beginTime")
            isLiveAdded = false
            isUpNextAdded = false
            for i = 0 to 1 step 1
                schedule = liveItem.events[i]
                if (isValid(schedule))
                    schedule.preview_m3u8 = liveItem.preview_m3u8
                    schedule.m3u8 = liveItem.m3u8
                    schedule.live = liveItem.live
                    schedule.background_image = liveItem.background_image
                    schedule.logo = liveItem.logo
                    schedule.vast = liveItem.vast
                    schedule.active_item_data = liveItem.active_item_data
                    schedule.DPSDAIAssetKey = liveItem.DPSDAIAssetKey
                    schedule.assetKey = liveItem.assetKey
                    startDt = CreateObject("roDateTime")
                    startDt.fromISO8601String(schedule.beginTime)
                    endDt = CreateObject("roDateTime")
                    endDt.fromISO8601String(schedule.endTime)
                    currentTime = CreateObject("roDateTime")
                    currentTime.ToISOString()
                    schedule.duration_seg = endDt.asSeconds() - startDt.asSeconds()
                    if (currentTime.asSeconds() < endDt.asSeconds())
                        if (currentTime.asSeconds() >= startDt.asSeconds() AND currentTime.asSeconds() <= endDt.asSeconds() AND not isLiveAdded)
                            contentNode = createObject("roSGNode", "ScheduleItemData")
                            contentNode.addFields({ colIndex: 1, index: gridIndex })
                            contentNode.setField("isLive", true)
                            contentNode.setFields(schedule)
                            mainContent.appendChild(contentNode)
                            gridIndex++
                            isLiveAdded = true
                        else if (currentTime.asSeconds() < startDt.asSeconds() AND not isUpNextAdded AND currentTime.GetDayOfMonth() = startDt.GetDayOfMonth())
                            if (not isLiveAdded)
                                contentNode = createObject("roSGNode", "ScheduleItemData")
                                contentNode.addFields({ colIndex: 1, index: gridIndex })
                                contentNode.setField("name_live", "no_transmission")
                                contentNode.setField("title", liveItem.name_live)
                                mainContent.appendChild(contentNode)
                                gridIndex++
                                isLiveAdded = true
                            end if
                            contentNode = createObject("roSGNode", "ScheduleItemData")
                            contentNode.addFields({ colIndex: 2, index: gridIndex })
                            contentNode.setFields(schedule)
                            mainContent.appendChild(contentNode)
                            gridIndex++
                            isUpNextAdded = true
                            exit for
                        else if not isUpNextAdded AND i = 1
                            if (not isLiveAdded)
                                contentNode = createObject("roSGNode", "ScheduleItemData")
                                contentNode.addFields({ colIndex: 1, index: gridIndex })
                                contentNode.setField("name_live", "no_transmission")
                                contentNode.setField("title", liveItem.name_live)
                                mainContent.appendChild(contentNode)
                                isLiveAdded = true
                                gridIndex++
                            end if
                            contentNode = createObject("roSGNode", "ScheduleItemData")
                            contentNode.addFields({ colIndex: 2, index: gridIndex })
                            contentNode.setField("name_live", "no_transmission")
                            contentNode.setField("title", liveItem.name_live)
                            mainContent.appendChild(contentNode)
                            gridIndex++
                        else if i = 1
                            contentNode = createObject("roSGNode", "ScheduleItemData")
                            contentNode.addFields({ colIndex: i + 1, index: gridIndex })
                            contentNode.setField("name_live", "no_transmission")
                            contentNode.setField("title", liveItem.name_live)
                            mainContent.appendChild(contentNode)
                            gridIndex++
                        end if
                    else
                        contentNode = createObject("roSGNode", "ScheduleItemData")
                        contentNode.addFields({ colIndex: i + 1, index: gridIndex })
                        contentNode.setField("name_live", "no_transmission")
                        contentNode.setField("title", liveItem.name_live)
                        mainContent.appendChild(contentNode)
                        gridIndex++
                    end if
                else
                    contentNode = createObject("roSGNode", "ScheduleItemData")
                    contentNode.addFields({ colIndex: i + 1, index: gridIndex })
                    schedule = {}
                    schedule.preview_m3u8 = liveItem.preview_m3u8
                    schedule.m3u8 = liveItem.m3u8
                    schedule.background_image = liveItem.background_image
                    schedule.logo = liveItem.logo
                    schedule.vast = liveItem.vast
                    schedule.active_item_data = liveItem.active_item_data
                    contentNode.setFields(schedule)
                    contentNode.setField("name_live", "no_transmission")
                    contentNode.setField("title", liveItem.name_live)
                    mainContent.appendChild(contentNode)
                    gridIndex++
                end if
            end for
        end for
        m.epgGrid.content = mainContent
        if (m.epgGrid.content.getChildCount() > 0)
            m.epgSection.visible = true
        end if
        setFocus(m.epgGrid)
        m.epgGrid.jumpToItem = m.lastFocusIndex
        ' m.refreshSchedule.control = "start"
    else
        showNoData()
    end if
    m.getEPGProgramDataTask = invalid
end sub

function makeEPGChannelWiseData(epgPrograms as dynamic) as dynamic
    newData = []
    for each item in m.epgData
        for each program in epgPrograms
            if program.key_live = item.key_live
                for each key in program
                    item[key] = program[key]
                end for
                exit for
            end if
        end for
        if NOT item.DoesExist("events") then item.events = []
        newData.push(item)
    end for
    return newData
end function

sub getEPGData()
    showHidePageLoader(true)
    m.getEPGDataTask = CreateObject("roSGNode", "ContentAPIAction")
    m.getEPGDataTask.functionName = "GetEPGData"
    m.getEPGDataTask.observeField("result", "OnGetEPGDataAPIResponse")
    m.getEPGDataTask.control = "RUN"
end sub

sub OnGetEPGDataAPIResponse(event as dynamic)
    response = event.getData()
    print "OnGetEPGDataAPIResponse : response : " 'formatjson(response)
    getEPGPrograms()
    if isValid(response) AND isValid(response.data) AND isValid(response.data.data) AND response.data.data.count() > 0
        m.epgData = response.data.data
    else
        showNoData()
    end if
    showHidePageLoader(false)
    m.getEPGDataTask = invalid
end sub

sub onGetRefreshLivesEpgeResponse(event as object)
    response = event.getData()
    if (response.ok AND isValid(response.data) AND response.data.Count() > 0)
        '     getLives = getValueFromProps(response, "data.data.getLives", invalid)
        '     oldContent = m.epgGrid.content
        '     totalContent = oldContent.getChildCount()
        '     for i = 0 to totalContent - 1 step 3
        '         itemNode = oldContent.getChild(i)
        '         channelIndex = itemNode.index
        '         for each liveItem in getLives
        '             if liveItem._id = itemNode._id
        '                 liveItem.schedules.SortBy("beginTime")
        '                 schedules = []
        '                 isLiveAdded = false
        '                 isUpNextAdded = false
        '                 nextIndex = channelIndex
        '                 for j = 0 to 1 step 1
        '                     schedule = liveItem.schedules[j]
        '                     if (isValid(schedule))
        '                         startDt = CreateObject("roDateTime")
        '                         startDt.asSeconds()
        '                         startDt.fromISO8601String(schedule.beginTime)
        '                         endDt = CreateObject("roDateTime")
        '                         endDt.asSeconds()
        '                         endDt.fromISO8601String(schedule.endTime)
        '                         currentTime = CreateObject("roDateTime")
        '                         currentTime.asSeconds()
        '                         currentTime.ToISOString()
        '                         if (currentTime.asSeconds() < endDt.asSeconds())
        '                             if (currentTime.asSeconds() >= startDt.asSeconds() AND currentTime.asSeconds() <= endDt.asSeconds() AND not isLiveAdded)
        '                                 contentNode = createObject("roSGNode", "ScheduleItemData")
        '                                 contentNode.addFields({ colIndex: 1 })
        '                                 contentNode.setField("isLive", true)
        '                                 contentNode.setFields(schedule)
        '                                 nextIndex++
        '                                 oldContent.replaceChild(contentNode, nextIndex)
        '                                 isLiveAdded = true
        '                             else if (currentTime.asSeconds() < startDt.asSeconds() AND not isUpNextAdded AND currentTime.GetDayOfMonth() = startDt.GetDayOfMonth())
        '                                 if (not isLiveAdded)
        '                                     contentNode = createObject("roSGNode", "ScheduleItemData")
        '                                     contentNode.addFields({ "colIndex": 1 })
        '                                     contentNode.setField("name_live", "no_transmission")
        '                                     nextIndex++
        '                                     oldContent.replaceChild(contentNode, nextIndex)
        '                                 end if
        '                                 contentNode = createObject("roSGNode", "ScheduleItemData")
        '                                 contentNode.addFields({ "colIndex": 2 })
        '                                 contentNode.setFields(schedule)
        '                                 nextIndex++
        '                                 oldContent.replaceChild(contentNode, nextIndex)
        '                                 isUpNextAdded = true
        '                                 exit for
        '                             else if not isUpNextAdded
        '                                 contentNode = createObject("roSGNode", "ScheduleItemData")
        '                                 contentNode.addFields({ "colIndex": 2 })
        '                                 contentNode.setField("name_live", "no_transmission")
        '                                 nextIndex++
        '                                 oldContent.replaceChild(contentNode, nextIndex)
        '                             else
        '                                 contentNode = createObject("roSGNode", "ScheduleItemData")
        '                                 contentNode.addFields({ "colIndex": j + 1 })
        '                                 contentNode.setField("name_live", "no_transmission")
        '                                 nextIndex++
        '                                 oldContent.replaceChild(contentNode, nextIndex)
        '                             end if
        '                         else
        '                             contentNode = createObject("roSGNode", "ScheduleItemData")
        '                             contentNode.addFields({ "colIndex": j + 1 })
        '                             contentNode.setField("name_live", "no_transmission")
        '                             nextIndex++
        '                             oldContent.replaceChild(contentNode, nextIndex)
        '                         end if
        '                     else
        '                         contentNode = createObject("roSGNode", "ScheduleItemData")
        '                         contentNode.addFields({ "colIndex": j + 1 })
        '                         contentNode.setField("name_live", "no_transmission")
        '                         nextIndex++
        '                         oldContent.replaceChild(contentNode, nextIndex)
        '                     end if
        '                 end for
        '             end if
        '         end for
        '     end for
        '     m.epgGrid.content = oldContent
        '     setFocus(m.epgGrid)
        '     m.epgGrid.jumpToItem = m.lastFocusIndex
    end if
end sub

sub onRefreshSchedules()
    getEPGPrograms()
end sub

sub onItemFocused(event as dynamic)
    index = event.getData()
    if isValid(index) AND index > 0
        m.lastFocusIndex = index
        m.focusedChildNode = m.epgGrid.content.getChild(index)
        if isValid(m.focusedChildNode)
            CreateMetaData()
            if isValid(m.focusedChildNode.m3u8) AND isNonEmptyString(m.focusedChildNode.m3u8) AND (m.lastPlayedChannel = invalid OR m.lastPlayedChannel <> m.focusedChildNode.m3u8)
                allPlayerAndTaskReset()
                if isValid(m.vLivePlayer)
                    m.vLivePlayer.control = "STOP"
                    m.vLivePlayer.content = invalid
                end if
                m.vLivePlayer.observeField("state", "OnVideoPlayerStatusChange")
                m.vLivePlayer.observeField("position", "OnVideoPositionChanged")
                if (isNonEmptyString(m.focusedChildNode.DPSDAIAssetKey) OR isNonEmptyString(m.focusedChildNode.assetKey))
                    DAIPlayerTask()
                    showHidePageLoader(true, false)
                else if isValid(m.focusedChildNode) AND isValid(m.focusedChildNode.vast) AND m.focusedChildNode.vast <> ""
                    PlayVideo(m.focusedChildNode.m3u8, m.focusedChildNode.vast)
                    PlayerTask()
                else
                    showHidePageLoader(true, false)
                    PlayVideo(m.focusedChildNode.m3u8, "")
                    m.vLivePlayer.control = "play"
                end if
                m.lastPlayedChannel = m.focusedChildNode.m3u8
                m.vLivePlayer.visible = true
            end if
        end if
    end if
end sub

function PlayVideo(url, vastURL)
    videoContent = createObject("RoSGNode", "ContentNode")
    videoContent.url = url
    videoContent.addFields({ "ad_url": vastURL, "length": 0 })
    videoContent.streamformat = "auto"
    m.vLivePlayer.enableTrickPlay = false
    m.vLivePlayer.enableUI = false
    m.vLivePlayer.content = videoContent
end function

sub allPlayerAndTaskReset()
    m.vLivePlayer.unobserveField("state")
    m.vLivePlayer.unobserveField("position")
    if m.PlayerTask <> invalid
        m.PlayerTask.control = "stop"
        m.PlayerTask.unobserveField("state")
        m.PlayerTask.unobserveField("isAdplaying")
        m.PlayerTask.unobserveField("currentState")
        m.PlayerTask.unobserveField("currentPosition")
        m.PlayerTask = invalid
    end if
    if isValid(m.DAIPlayerTask)
        m.DAIPlayerTask.control = "STOP"
        m.DAIPlayerTask.unobserveField("sdkLoaded")
        m.DAIPlayerTask.unobserveField("errors")
        m.DAIPlayerTask.unobserveField("adPlaying")
        m.DAIPlayerTask.unobserveField("urlData")
        m.DAIPlayerTask = invalid
    end if
    m.vLivePlayer.enableTrickPlay = false
    m.vLivePlayer.enableUI = false
end sub

sub PlayerTask()
    m.PlayerTask = CreateObject("roSGNode", "PlayerTask")
    m.PlayerTask.observeField("state", "taskStateChanged")
    m.PlayerTask.observeField("currentState", "OnVideoPlayerStatusChange")
    m.PlayerTask.observeField("currentPosition", "OnVideoPositionChanged")
    m.PlayerTask.observeField("isAdplaying", "onAdsPlaying")
    m.PlayerTask.isLivePlayer = true
    m.PlayerTask.video = m.vLivePlayer
    m.PlayerTask.functionName = "playContentWithAds"
    m.PlayerTask.control = "RUN"
end sub

sub onAdsPlaying(event as dynamic)
    m.isRAFAdsPlaying = event.getData()
    if m.isRAFAdsPlaying then showHidePageLoader(false)
    if not m.isbigLivePlayerAnimation
        SetFocus(m.epgGrid)
    end if
end sub

sub taskStateChanged(event as Object)
    print "Player: taskStateChanged(), id = "; event.getNode(); ", "; event.getField(); " = "; event.getData()
    state = event.GetData()
    if state = "done"
        allPlayerAndTaskReset()
    end if
end sub

sub CreateMetaData()
    m.lgDetailSection.removeChildrenIndex(m.lgDetailSection.getChildCount(), 0)
    if isValid(m.pLogo)
        m.pLogo.unObserveField("loadStatus")
        m.pLogo = invalid
    end if
    if isValid(m.focusedChildNode)
        pRating = createObject("roSGNode", "Poster")
        pRating.id = "pRating"
        pRating.width = 157
        pRating.loadWidth = 157
        pRating.height = 32
        pRating.loadHeight = 32
        pRating.loadDisplayMode = "scaleTozoom"
        pRating.uri = "pkg:/images/details/livenow_back.png"
        pRating.blendColor = m.theme.focTertiary
        m.lgDetailSection.appendChild(pRating)

        lRating = createObject("roSGNode", "Label")
        lRating.id = "lRating"
        lRating.width = 157
        lRating.height = 32
        lRating.font = m.fonts.dmSansMedium18
        lRating.color = m.theme.black
        lRating.horizAlign = "center"
        lRating.vertAlign = "center"
        lRating.text = "EN VIVO AHORA"
        pRating.appendChild(lRating)

        imageURL = ""
        if isValid(m.focusedChildNode.active_item_data) AND isValid(m.focusedChildNode.active_item_data.image) AND isNonEmptyString(m.focusedChildNode.active_item_data.image)
            imageURL = m.focusedChildNode.active_item_data.image
        else if isValid(m.focusedChildNode.background_image) AND isNonEmptyString(m.focusedChildNode.background_image)
            imageURL = m.focusedChildNode.background_image
        else if isValid(m.focusedChildNode.logo) AND isNonEmptyString(m.focusedChildNode.logo)
            imageURL = m.focusedChildNode.logo
        end if
        if imageURL <> invalid AND imageURL <> ""
            m.pLogo = createObject("roSGNode", "Poster")
            m.pLogo.id = "pLogo"
            m.pLogo.height = 308
            m.pLogo.loadHeight = 308
            m.pLogo.loadDisplayMode = "scaleToFit"
            m.pLogo.observeField("loadStatus", "onImageLoadStatusChange")
            m.pLogo.uri = imageURL
            m.lgDetailSection.appendChild(m.pLogo)
        end if

        if (isValid(m.focusedChildNode.title))
            lTitle = createObject("roSGNode", "Label")
            lTitle.id = "lTitle"
            lTitle.width = 549
            lTitle.wrap = true
            lTitle.lineSpacing = 0
            lTitle.maxlines = 2
            lTitle.horizAlign = "left"
            lTitle.font = m.fonts.dmSansBold32
            lTitle.text = m.focusedChildNode.title
            lTitle.color = m.theme.white
            m.lgDetailSection.appendChild(lTitle)
        end if
        m.lgDetailSection.translation = [1130, 160]
    end if
end sub

sub onImageLoadStatusChange(event as dynamic)
    status = event.getData()
    node = event.getRoSGNode()
    if status = "ready"
        imageWidth = node.bitmapWidth
        imageHeight = node.bitmapHeight
        node.width = imageWidth * (node.height / imageHeight)
    else if status = "failed"
        print "Image failed to load"
    end if
end sub

sub onItemSelected(event as dynamic)
    index = event.getData()
    selectItemNode = m.epgGrid.content.getChild(index)
    if (isValid(selectItemNode) AND isValid(selectItemNode.isLive))
    end if
end sub

function DAIPlayerTask() as void
    m.DAIPlayerTask = createObject("roSGNode", "DAIPlayerTask")
    m.DAIPlayerTask.observeField("sdkLoaded", "onDAISdkLoaded")
    m.DAIPlayerTask.observeField("errors", "onDAISdkLoadedError")
    m.DAIPlayerTask.observeField("adPlaying", "onAdPlayingUpdated")
    m.DAIPlayerTask.observeField("urlData", "urlLoadRequested")

    assetKey = ""
    if isNonEmptyString(m.focusedChildNode.DPSDAIAssetKey) then assetKey = m.focusedChildNode.DPSDAIAssetKey
    if (assetKey = "" AND isNonEmptyString(m.focusedChildNode.assetKey)) then assetKey = m.focusedChildNode.assetKey

    streamDAIData = {
        title: m.focusedChildNode.title,
        assetKey: assetKey,
        networkCode: "",
        apiKey: "",
        type: "live"
    }

    m.DAIPlayerTask.deviceRida = createObject("roDeviceInfo").GetRIDA()
    m.DAIPlayerTask.streamData = streamDAIData
    m.DAIPlayerTask.setAdsDebugOutput = false
    m.DAIPlayerTask.setAdMeasurements = true
    m.DAIPlayerTask.nielsenAppId = "chvtv"
    m.DAIPlayerTask.nielsenProgramId = ""
    m.DAIPlayerTask.contentGenres = ""
    m.DAIPlayerTask.setJITPods = false
    m.DAIPlayerTask.enableNielsenDAR = true
    m.DAIPlayerTask.video = m.vLivePlayer
    m.DAIPlayerTask.mediaInfo = m.focusedChildNode.getFields()
    ' Setting control to run starts the task thread.
    m.DAIPlayerTask.control = "RUN"
end function

sub urlLoadRequested(message as object)
    data = message.getData()
    format = "auto"
    if isValid(data.format) AND isNonEmptyString(data.format) then format = data.format
    googleStreamId = data.streamid
    videoContent = createObject("RoSGNode", "ContentNode")
    videoContent.streamformat = format
    videoContent.id = m.focusedChildNode.name_live
    videoContent.title = m.focusedChildNode.title
    finalUrl = ""
    if (isValid(data.manifest) AND isNonEmptyString(data.manifest))
        finalUrl = data.manifest
    else if m.focusedChildNode.m3u8 <> invalid
        finalUrl = m.focusedChildNode.m3u8
    end if
    videoContent.url = finalUrl
    videoContent.Live = true
    m.vLivePlayer.content = videoContent
    m.vLivePlayer.visible = true
    m.vLivePlayer.control = "play"
    ' m.vLivePlayer.EnableCookies()
end sub

sub onDAISdkLoaded(message as object)
    print "onDAISdkLoaded : message : " message
end sub

sub onDAISdkLoadedError(message as object)
    print "onDAISdkLoadedError : message : " message
end sub

sub clearView()
    m.top.unObserveField("focusedChild")
end sub

sub onFocusedChild()
    if(m.top.hasFocus())
        if m.top.IsInFocusChain()
            if restoreFocus()
                ' m.refreshSchedule.control = "start"
            end if
        end if
    else if (not m.top.hasFocus() AND not m.top.IsInFocusChain())
        m.refreshSchedule.control = "stop"
    end if
end sub

sub onJumpToMenu()
    m.scene.callFunc("setFocusSidebar")
end sub

sub showbigLivePlayerAnimation(isBig = true as boolean)
    if isBig
        if m.liveVideoStatus = "playing" OR m.liveVideoStatus = "paused"
            m.vLivePlayer.enableTrickPlay = true
            m.vLivePlayer.enableUI = true
            m.isbigLivePlayerAnimation = true
            SetFocus(m.vLivePlayer)
            m.bigLivePlayer.control = "start"
            m.scene.callFunc("ShowHideMenu", false)
        end if
    else
        if m.vLivePlayer.state = "paused" then m.vLivePlayer.control = "play"
        m.vLivePlayer.enableTrickPlay = false
        m.vLivePlayer.enableUI = false
        m.isbigLivePlayerAnimation = false
        SetFocus(m.epgGrid)
        m.smallLivePlayer.control = "start"
        m.scene.callFunc("ShowHideMenu", true)
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    result = false
    if(press)
        if key = "OK"
            if not m.isbigLivePlayerAnimation
                showbigLivePlayerAnimation()
            end if
            result = true
        else if key = "down"
            result = true
        else if key = "up"
            if not m.isbigLivePlayerAnimation AND isValid(m.epgGrid) AND isValid(m.epgGrid.content) AND (m.epgGrid.hasFocus() OR m.epgGrid.IsInFocusChain())
                result = false
            end if
        else if(key = "back")
            if m.isRAFAdsPlaying AND m.PlayerTask <> invalid
                allPlayerAndTaskReset()
                SetFocus(m.epgGrid)
            end if
            if m.isbigLivePlayerAnimation
                showbigLivePlayerAnimation(false)
                result = true
            end if
        end if
        if m.isbigLivePlayerAnimation then result = true
    end if
    return result
end function