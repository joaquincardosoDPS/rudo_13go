sub init()
    setLocals()
    setControls()
    setUpColor()
    setUpFonts()
    setupPageLoader()
    setObservers()
end sub

sub setLocals()
    m.theme = m.global.appTheme
    m.fonts = m.global.Fonts
    m.appConfig = GlobalGet("appConfig")
    m.scene = m.top.getScene()
    m.programData = invalid
    m.scene.hasTopMenuBackground = false
    m.lastSelectedTabData = invalid
    m.lastSelectedSeasonTabData = invalid
    m.programProgress = 0
    m.programDuration = 0
    m.isDetailsScreenVisible = false
    m.lastPlayedEpisode = invalid
    resetPagination()
    m.apiInProgress = 0
end sub

sub setControls()
    m.gDetails = m.top.findNode("gDetails")
    m.shortMetaData = m.top.findNode("shortMetaData")
    m.lgDetails = m.top.findNode("lgDetails")
    m.gProgressBar = m.top.findNode("gProgressBar")
    m.pUnfillProgressRect = m.top.findNode("pUnfillProgressRect")
    m.pFillProgressRect = m.top.findNode("pFillProgressRect")
    m.lRemainingTime = m.top.findNode("lRemainingTime")
    m.pMetaOverlay = m.top.findNode("pMetaOverlay")
    m.pVideo = m.top.findNode("pVideo")
    m.gSegmentGrid = m.top.findNode("gSegmentGrid")
    m.tabView = m.top.findNode("tabView")
    m.horizLine = m.top.findNode("horizLine")
    m.seasonTabView = m.top.findNode("seasonTabView")
    m.mgEpisode = m.top.findNode("mgEpisode")
    m.lNoEpisode = m.top.findNode("lNoEpisode")
    m.gDetailsSection = m.top.findNode("gDetailsSection")
    m.rBottomMetaOverlay = m.top.findNode("rBottomMetaOverlay")

    m.gDetailsUpAnimation = m.top.findNode("gDetailsUpAnimation")
    m.gDetailsDownAnimation = m.top.findNode("gDetailsDownAnimation")

    m.pageLoader = m.top.findNode("pageLoader")
    if(m.global.designResolution = "720p")
        m.mgEpisode.focusBitmapUri = "pkg:/images/focus/R5T3_35px_outborder_nopadding.9.png"
    else
        m.mgEpisode.focusBitmapUri = "pkg:/images/focus/R8_T3_50PX_border.9.png"
    end if
    m.mgEpisode.focusBitmapBlendColor = m.theme.focPrimary
end sub

sub setUpFonts()
    m.lRemainingTime.font = m.fonts.dmSansMedium20
    m.lNoEpisode.font = m.fonts.dmSansMedium20
end sub

sub setUpColor()
    ' m.pMetaOverlay.blendColor = m.theme.black
    m.rBottomMetaOverlay.color = "#001A28"
    m.pUnfillProgressRect.blendColor = m.theme.white
    m.pFillProgressRect.blendColor = m.theme.focPrimary
    m.lRemainingTime.color = m.theme.clrSecondaryText
    m.horizLine.color = m.theme.white
    m.lNoEpisode.color = m.theme.clrSecondaryText
end sub

sub setObservers()
    m.top.observeField("focusedChild", "onFocusedChild")
    m.top.observeField("visible", "onVisibleChanged")
    m.scene.ObserveField("isItemAddRemoveFav", "onAddRemoveItemFromMyListBtn")
    m.tabView.observeField("updateContent", "onUpdateContent")
    m.seasonTabView.observeField("updateContent", "onSeasonTabView")
    m.mgEpisode.observeField("itemFocused", "OnEpisodeItemFocus")
    m.mgEpisode.observeField("itemSelected", "OnEpisodeItemSelected")
    m.transAnimation = m.top.FindNode("transAnimation")
    m.scene.observeField("isWatchHistoryFetched", "refreshContent")
end sub

sub setupPageLoader()
    m.pageLoader.poster.uri = "pkg:/images/loader/loader_image.png"
    m.pageLoader.poster.width = 100
    m.pageLoader.poster.height = 100
    m.pageLoader.poster.loadwidth = 100
    m.pageLoader.poster.loadheight = 100
    m.pageLoader.poster.blendColor = m.theme.focPrimary
    m.pageLoader.poster.loadDisplayMode = "scaleToFit"
end sub

sub refreshContent()
    if m.scene.isWatchHistoryFetched AND m.top.visible
        startDetailsUpAnimation()
        onContentInfoChanged()
    end if
end sub

sub resetPagination()
    m.currentPage = 1
    m.isPagination = false
    m.paginationData = {}
    m.programKey = ""
    m.indexValForPagination = 5
end sub

sub startAnimation()
    m.transAnimation.control = "stop"
    m.transAnimation.control = "start"
end sub

sub startDetailsUpAnimation()
    m.gDetailsUpAnimation.control = "start"
end sub

sub startDetailsDownAnimation()
    m.gDetailsDownAnimation.control = "start"
end sub

sub onFocusedChild()
    if m.top.hasFocus()
        focusRestored = RestoreFocus()
        if focusRestored = false
            if isValid(m.bWatchNow)
                setFocus(m.bWatchNow)
            end if
        end if
    end if
end sub

sub onVisibleChanged()
    if m.top.visible
        if isValid(m.bWatchNow)
            setFocus(m.bWatchNow)
        end if
    end if
end sub

sub showHidePageLoader(visible as boolean)
    m.pageLoader.visible = visible
end sub

sub onContentInfoChanged()
    contentNode = m.top.contentNode
    if isValid(contentNode) AND isValid(contentNode.itemData)
        print "onContentInfoChanged : contentNode : " contentNode.itemData
        m.programKey = ""
        if isValid(contentNode.sliderId) AND contentNode.sliderId = "seguirviendo"
            m.programKey = contentNode.itemData.key_program
        else
            m.programKey = contentNode.itemData.key
        end if
        fetchAndStoreWatchHistory()
        ValidateFavouriteStatus()
        if (m.scene.isWatchHistoryFetched = false OR m.programData = invalid)
            getProgramDetails()
        end if
    end if
end sub

sub fetchAndStoreWatchHistory()
    if m.scene.isUserLoggedIn
        m.apiInProgress++
        showHidePageLoader(true)
        if isValid(m.watchHistoryTask)
            m.watchHistoryTask.control = "STOP"
            m.watchHistoryTask = invalid
            m.apiInProgress--
        end if
        params = {}
        params["client"] = GlobalGet("appConfig").client
        params["token"] = GlobalGet("token")
        params["profile"] = GlobalGet("selectedProfileID")
        params["program"] = m.programKey
        params["end"] = 0
        params["limit"] = 1
        m.watchHistoryTask = CreateObject("roSGNode", "ContentAPIAction")
        m.watchHistoryTask.functionName = "GetAllWatchHistory"
        m.watchHistoryTask.params = params
        m.watchHistoryTask.observeField("result", "onGetAllWatchHistoryResponse")
        m.watchHistoryTask.control = "RUN"
    end if
end sub

sub onGetAllWatchHistoryResponse(event as dynamic)
    response = event.getData()
    print "onGetAllWatchHistoryResponse >>>> response : " 'formatjson(response)
    if isValid(response) AND isValid(response.data) AND isValid(response.data.data) AND isValid(response.data.data[0]) AND response.data.data[0].count() > 0
        contentData = response.data.data[0]
        programItem = CreateObject("roSGNode", "EpisodeItemNode")
        programItem.setFields(contentData)
        m.lastPlayedEpisode = programItem
        if isValid(contentData) AND isValid(contentData.time)
            m.programProgress = contentData.time
            m.programDuration = contentData.duration_seg
        end if
    end if
    m.apiInProgress--
    callProgramAPI()
    m.watchHistoryTask = invalid
end sub

sub ValidateFavouriteStatus()
    m.apiInProgress++
    if isValid(m.favouriteStatusTask)
        m.favouriteStatusTask.control = "STOP"
        m.favouriteStatusTask = invalid
        m.apiInProgress--
    end if
    params = {}
    params["profile"] = GlobalGet("selectedProfileID")
    params["program"] = m.programKey
    m.favouriteStatusTask = CreateObject("roSGNode", "ContentAPIAction")
    m.favouriteStatusTask.functionName = "CheckItemInFavourite"
    m.favouriteStatusTask.params = params
    m.favouriteStatusTask.observeField("result", "onCheckItemInFavouriteResponse")
    m.favouriteStatusTask.control = "RUN"
end sub

sub onCheckItemInFavouriteResponse(event as dynamic)
    response = event.getData()
    m.favouriteStatus = false
    print "onCheckItemInFavouriteResponse >>>> response : " 'formatjson(response)
    if isValid(response) AND isValid(response.data) AND isValid(response.data.data) AND response.data.data.Count() > 0 AND isValid(response.data.data[0]) AND response.data.data[0] = m.programKey
        m.favouriteStatus = true
    end if
    m.apiInProgress--
    callProgramAPI()
    m.favouriteStatusTask = invalid
end sub

sub callProgramAPI()
    if m.apiInProgress > 0 return
    updateMetaDetails()
    if m.scene.isWatchHistoryFetched = false AND m.programData <> invalid
        checkAndCreateBottomList()
    end if
    startAnimation()
    showHidePageLoader(false)
end sub

sub getProgramDetails()
    m.apiInProgress++
    if isValid(m.getProgramDetailsTask)
        m.getProgramDetailsTask.control = "STOP"
        m.getProgramDetailsTask = invalid
        m.apiInProgress--
    end if
    params = {}
    params["client"] = m.appConfig.client
    params["program"] = m.programKey
    m.getProgramDetailsTask = CreateObject("roSGNode", "ContentAPIAction")
    m.getProgramDetailsTask.functionName = "GetProgramDetails"
    m.getProgramDetailsTask.params = params
    m.getProgramDetailsTask.ObserveField("result", "OnGetProgramDetailsAPIResponse")
    m.getProgramDetailsTask.control = "RUN"
end sub

sub OnGetProgramDetailsAPIResponse(event as dynamic)
    response = event.getData()
    print "OnGetProgramDetailsAPIResponse : response : " 'formatjson(response)
    if isValid(response) AND isValid(response.data) AND isValid(response.data.data) AND response.data.data.count() > 0
        m.programData = response.data.data
    end if
    m.apiInProgress--
    callProgramAPI()
    m.getProgramDetailsTask = invalid
end sub

sub onImageLoadStatusChange(event as dynamic)
    status = event.getData()
    node = event.getRoSGNode()
    if status = "ready"
        imageWidth = node.bitmapWidth
        imageHeight = node.bitmapHeight
        node.width = imageWidth * (node.height / imageHeight)
        print "Image loaded successfully, width : " node.width " height : " node.height
    else if status = "failed"
        print "Image failed to load"
    end if
end sub

sub updateMetaDetails()
    if m.lgDetails.getChildCount() > 0
        m.lgDetails.removeChildrenIndex(m.lgDetails.getChildCount(), 0)
        m.bWatchNow = invalid
        m.bAddToFavourite = invalid
        if isValid(m.pBackClassification)
            m.pBackClassification.unObserveField("loadStatus")
            m.pBackClassification = invalid
        end if
    end if
    if (isValid(m.programData))
        imageType = "big"
        if m.global.designresolution = "720p" then imageType = "medium"
        m.pVideo.uri = GetImageURL(m.programData.image_land, imageType)
        isLogo = false
        if (isValid(m.programData.image_logo) AND (m.programData.image_logo.count() > 0))
            logoImage = GetImageURL(m.programData.image_logo, "medium")
            if isNonEmptyString(logoImage)
                m.pBackClassification = createObject("roSGNode", "Poster")
                m.pBackClassification.id = "pBackClassification"
                m.pBackClassification.height = 160
                m.pBackClassification.loadHeight = 160
                m.pBackClassification.loadDisplayMode = "scaleToFit"
                m.pBackClassification.observeField("loadStatus", "onImageLoadStatusChange")
                m.pBackClassification.uri = logoImage
                m.lgDetails.appendChild(m.pBackClassification)
                isLogo = true
            end if
        end if
        if (isValid(m.programData.title) AND (isNonEmptyString(m.programData.title)) AND isLogo = false)
            lTitle = createObject("roSGNode", "Label")
            lTitle.id = "lTitle"
            lTitle.width = 900
            lTitle.lineSpacing = -3
            lTitle.wrap = true
            lTitle.maxLines = 2
            lTitle.font = m.fonts.dmSansBold32
            lTitle.color = m.theme.clrPrimaryTitle
            lTitle.text = m.programData.title
            m.lgDetails.appendChild(lTitle)
        end if

        lgHoriz = createObject("roSGNode", "LayoutGroup")
        lgHoriz.id = "lgHoriz"
        lgHoriz.layoutDirection = "horiz"
        lgHoriz.itemSpacings = "10"
        if (isValid(m.programData.classification) AND (isNonEmptyString(m.programData.classification)))
            if isValid(m.programData.classification) AND isNonEmptyString(m.programData.classification)
                pRating = createObject("roSGNode", "Poster")
                pRating.id = "pRating"
                pRating.width = 51
                pRating.loadWidth = 51
                pRating.height = 32
                pRating.loadHeight = 32
                pRating.loadDisplayMode = "scaleTozoom"
                pRating.uri = "pkg:/images/other/rating_back.png"
                pRating.blendColor = m.theme.black

                lRating = createObject("roSGNode", "Label")
                lRating.id = "lRating"
                lRating.width = 51
                lRating.height = 32
                lRating.horizAlign = "center"
                lRating.vertAlign = "center"
                lRating.font = m.fonts.dmSansMedium24
                lRating.color = m.theme.white
                lRating.text = m.programData.classification
                pRating.appendChild(lRating)
                lgHoriz.appendChild(pRating)
            end if
        end if
        genderText = ""
        if isValid(m.programData.anio_production) AND isNonEmptyString(m.programData.anio_production)
            if genderText <> "" then genderText += ", "
            genderText += m.programData.anio_production

            if isValid(m.programData.segments) AND m.programData.segments.count() > 0 AND isValid(m.programData.segments[0]) AND isValid(m.programData.segments[0].max_temp) AND isNonEmptyString(m.programData.segments[0].max_temp.toStr())
                genderText += " - " + m.programData.segments[0].max_temp.toStr() + " temaporadas"
            end if
        end if
        genderText += getGeneder(genderText, "name")
        if isNonEmptyString(genderText)
            lGender = createObject("roSGNode", "Label")
            lGender.id = "lGender"
            lGender.width = 800
            lGender.font = m.fonts.dmSansMedium24
            lGender.color = m.theme.white
            lGender.text = genderText
            lgHoriz.appendChild(lGender)
        end if
        m.lgDetails.appendChild(lgHoriz)

        if isValid(m.programData.description) AND isNonEmptyString(m.programData.description)
            lDescription = createObject("roSGNode", "Label")
            lDescription.id = "lDescription"
            lDescription.width = 900
            lDescription.lineSpacing = -3
            lDescription.wrap = true
            lDescription.maxLines = 3
            lDescription.font = m.fonts.dmSansMedium24
            lDescription.color = m.theme.white
            if m.programData.description_short <> invalid AND m.programData.description_short <> ""
                lDescription.text = m.programData.description_short
            else if m.programData.description <> invalid
                lDescription.text = m.programData.description
            end if
            m.lgDetails.appendChild(lDescription)
        end if
    end if
    ' shortMetaDataBoundingRect = m.lgDetails.boundingRect()
    ' m.lgDetails.translation = [shortMetaDataBoundingRect.x, shortMetaDataBoundingRect.y + shortMetaDataBoundingRect.height + 20]
    createMetadataButtons()
end sub

function checkTextBlankOrNot(metaText as string) as string
    metaTextNew = ""
    if metaText <> invalid AND metaText <> ""
        metaTextNew = metaText + "  •  "
        return metaTextNew
    else
        return metaTextNew
    end if
end function

sub createMetadataButtons()
    gButtonProgress = CreateObject("roSGNode", "Group")
    gButtonProgress.id = "gButtonProgress"

    lgButtonRow = CreateObject("roSGNode", "LayoutGroup")
    lgButtonRow.id = "lgButtonRow"
    lgButtonRow.layoutDirection = "horiz"
    lgButtonRow.itemSpacings = -20

    m.bWatchNow = CreateObject("roSGNode", "CustomButton")
    m.bWatchNow.id = "bWatchNow"
    buttonFields = {
        buttonWidth: 150,
        buttonHeight: 70,
        backGroundImage: "pkg:/images/focus/filled_r6.9.png",
        buttonText: "Play",
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.black
        backgroundColor: m.theme.white
        focusBackgroundColor: m.theme.focPrimary
        backGroundImage: m.theme.filledBackGroundImage
        focusBorderImage: m.theme.filledBackGroundImage
        isFilledBgOnFocus: true
        fontSize: "dmSansMedium26"
        posterImage: "pkg:/images/focus/btnplay.png"
        addColorOnImage: true
        padding: 20
        posterImageSize: 35
        margin: 10
    }
    m.bWatchNow.update(buttonFields)
    m.lastFocusedButton = m.bWatchNow
    m.bAddToFavourite = CreateObject("roSGNode", "CustomButton")
    m.bAddToFavourite.id = "bAddToFavourite"
    buttonFields = {
        buttonWidth: 62
        buttonHeight: 62
        backGroundImage: "pkg:/images/icons/addToMylist-icon.png"
        buttonText: ""
        backgroundColor: m.theme.white
        focusBackgroundColor: m.theme.focPrimary
        focusBorderImage: "pkg:/images/icons/addToMylist-icon.png"
        isFilledBgOnFocus: false
        fontSize: "dmSansMedium26"
        margin: 0
    }
    m.bAddToFavourite.update(buttonFields)
    if m.favouriteStatus
        m.bAddToFavourite.update({
            backGroundImage: "pkg:/images/icons/removeFromMylist-icon.png"
            focusBorderImage: "pkg:/images/icons/removeFromMylist-icon.png" 
        })
    end if
    lgButtonRow.appendChild(m.bWatchNow)
    lgButtonRow.appendChild(m.bAddToFavourite)
    gButtonProgress.appendChild(lgButtonRow)
    m.lgDetails.appendChild(gButtonProgress)
    updateProgressBar(gButtonProgress)
    SetFocus(m.bWatchNow)
end sub

sub updateProgressBar(buttonGroup as object)
    m.gProgressBar.visible = false
    if isValid(m.programProgress) AND isValid(m.programDuration) AND m.programProgress > 0 AND m.programDuration > 0
        progressPercent = getProgressPercent(m.programProgress, m.programDuration)
        if isValid(progressPercent) AND progressPercent > 0
            m.gProgressBar.visible = true
            m.bWatchNow.buttonText = getWatchButtonText(progressPercent)
            m.bWatchNow.buttonWidth = 210
            brLgDetail = m.lgDetails.boundingRect()
            progressbarWidth = buttonGroup.boundingRect().width
            m.pUnfillProgressRect.width = progressbarWidth
            m.pUnfillProgressRect.loadWidth = progressbarWidth
            m.pFillProgressRect.width = (progressPercent * progressbarWidth) / 100
            m.pFillProgressRect.loadWidth = progressbarWidth
            m.lRemainingTime.text = getRemainingTimeText()
            m.lRemainingTime.translation = [progressbarWidth + 20, -16]
            m.gProgressBar.translation = [brLgDetail.x, brLgDetail.y + brLgDetail.height + 20]
            if m.bWatchNow.buttonText = "Play"
                m.bWatchNow.update({
                    buttonWidth: 150
                })
                m.gProgressBar.visible = false
            end if
        end if
    end if
end sub

function getWatchButtonText(progressPercent as integer) as string
    if hasResumeProgress(progressPercent)
        return "Reanudar"
    end if
    return "Play"
end function

function getResumeDuration() as float
    duration = 0
    if isValid(m.programData) AND isValid(m.programData.duration_seg) AND m.programData.duration_seg > 0
        duration = m.programData.duration_seg
    end if
    return duration
end function

function getRemainingTimeText() as string
    remainingSeconds = getResumeDuration() - m.programProgress
    if remainingSeconds <= 0 then return ""
    totalMinutes = Int((remainingSeconds + 59) / 60)
    hours = Int(totalMinutes / 60)
    minutes = totalMinutes mod 60
    if hours > 0
        return hours.toStr() + "h " + minutes.toStr() + "m restantes"
    end if
    return minutes.toStr() + "m restantes"
end function

' Bottom View
sub checkAndCreateBottomList()
    if isValid(m.programData) AND m.programData.segments <> invalid AND m.programData.segments.Count() > 0
        segments = m.programData.segments
        m.gSegmentGrid.visible = false
        m.tabView.visible = false
        m.horizLine.visible = false
        m.seasonTabView.visible = false
        m.mgEpisode.visible = false
        m.lastSelectedTabData = invalid
        if isValid(segments) AND segments.Count() > 0
            details = {
                "all_temp": [],
                "id": "",
                "key": "",
                "max_temp": 0,
                "name": "Detalles"
            }
            segments.push(details)
            m.tabView.tabData = segments
            m.gSegmentGrid.visible = true
            m.tabView.visible = true
            m.horizLine.visible = true
            if isValid(m.scene.deeplinkingData) AND isNonEmptyString(m.scene.deeplinkingData.segmentId)
                segmentId = m.scene.deeplinkingData.segmentId
                segmentIdLower = LCase(segmentId)
                for i = 0 to segments.Count() - 1
                    segment = segments[i]
                    segmentKeyLower = ""
                    segmentIdFieldLower = ""
                    if isValid(segment.key) then segmentKeyLower = LCase(segment.key)
                    if isValid(segment.id) then segmentIdFieldLower = LCase(segment.id)
                    if segmentIdFieldLower = segmentIdLower OR segmentKeyLower = segmentIdLower
                        m.tabView.ItemSelected = i
                        exit for
                    end if
                end for
            else
                m.tabView.initSelect = true
            end if
            if isValid(m.top.contentNode.sliderId) AND m.top.contentNode.sliderId = "seguirviendo"
                segmentId = m.top.contentNode.itemData.key_segment
                segmentIdLower = LCase(segmentId)
                selectedId = -1
                for i = 0 to segments.Count() - 1
                    segment = segments[i]
                    segmentKeyLower = ""
                    segmentIdFieldLower = ""
                    if isValid(segment.key) then segmentKeyLower = LCase(segment.key)
                    if isValid(segment.id) then segmentIdFieldLower = LCase(segment.id)
                    if segmentIdFieldLower = segmentIdLower OR segmentKeyLower = segmentIdLower
                        selectedId = i
                    end if
                end for
                if selectedId > 0
                    m.tabView.ItemSelected = selectedId
                else
                    m.tabView.initSelect = true
                end if
            end if
        end if
    end if
    ' startAnimation()
end sub

sub onUpdateContent(event as dynamic)
    tabData = event.getData()
    if isValid(tabData) AND isNonEmptyString(tabData.title) AND (m.lastSelectedTabData = invalid OR tabData.id <> m.lastSelectedTabData.id)
        m.lastSelectedSeasonTabData = invalid
        if m.seasonTabView.visible then clearSeasonViewContent()
        m.seasonTabView.visible = false
        m.gDetailsSection.visible = false
        resetPagination()
        m.lNoEpisode.visible = false
        m.isDetailsScreenVisible = false
        if tabData.title <> "Detalles"
            m.lastSelectedTabData = tabData
            if isValid(tabData.all_temp) AND tabData.all_temp.count() > 0
                m.seasonTabView.tabData = tabData.all_temp
                m.seasonTabView.visible = true
                if isValid(m.scene.deeplinkingData) AND isNonEmptyString(m.scene.deeplinkingData.seasonId)
                    seasonId = m.scene.deeplinkingData.seasonId
                    for i = 0 to tabData.all_temp.Count() - 1
                        season = tabData.all_temp[i].toStr()
                        if season = seasonId
                            m.seasonTabView.ItemSelected = i
                            exit for
                        end if
                    end for
                else
                    m.seasonTabView.initSelect = true
                end if
            else
                m.lNoEpisode.text = "Datos no disponibles."
                m.lNoEpisode.visible = true
            end if
        else
            m.lastSelectedTabData = invalid
            m.isDetailsScreenVisible = true
            CreateDetailsSection()
        end if
    end if
end sub

sub clearSeasonViewContent()
    m.seasonTabView.callFunc("clearTabView")
    if isValid(m.mgEpisode) AND m.mgEpisode.visible AND isValid(m.mgEpisode.content) AND m.mgEpisode.content.getChildCount() > 0
        m.mgEpisode.content.removeChildrenIndex(m.mgEpisode.content.getChildCount(), 0)
        m.mgEpisode.content = invalid
    end if
    m.seasonTabView.visible = false
    m.mgEpisode.visible = false
end sub

sub onSeasonTabView(event as dynamic)
    tabData = event.getData()
    if isValid(tabData) AND isNonEmptyString(tabData.title) AND (m.lastSelectedSeasonTabData = invalid OR tabData.id <> m.lastSelectedSeasonTabData.id)
        m.mgEpisode.visible = false
        m.gDetailsSection.visible = false
        resetPagination()
        if tabData.title <> "Detalles"
            m.lastSelectedSeasonTabData = tabData
            getSeasonEpisode()
        else
            m.lastSelectedSeasonTabData = invalid
        end if
    end if
end sub

sub getSeasonEpisode(page = 1 as integer)
    showHidePageLoader(true)
    params = {}
    params["client"] = m.appConfig.client
    params["program"] = m.programData.key
    if m.lastSelectedSeasonTabData <> invalid then params["season"] = m.lastSelectedSeasonTabData.id
    if isValid(m.lastSelectedTabData) then params["segment"] = m.lastSelectedTabData.key
    params["page"] = page
    params["order"] = "num_capitulo"
    params["order_type"] = "desc"
    params["limit"] = 25
    m.getProgramDetailsTask = CreateObject("roSGNode", "ContentAPIAction")
    m.getProgramDetailsTask.functionName = "GetSeasonEpisodeDetails"
    m.getProgramDetailsTask.params = params
    if m.isPagination
        m.getProgramDetailsTask.ObserveField("result", "onSeasonEpisodeDetailsAPIPaginationDataResponse")
    else
        m.getProgramDetailsTask.ObserveField("result", "OnGetSeasonEpisodeDetailsAPIResponse")
    end if
    m.getProgramDetailsTask.control = "RUN"
end sub

sub OnGetSeasonEpisodeDetailsAPIResponse(event as dynamic)
    response = event.getData()
    print "OnGetSeasonEpisodeDetailsAPIResponse : response : " 'formatjson(response)
    if isValid(response) AND isValid(response.data) AND isValid(response.data.data) AND response.data.data.count() > 0
        m.seasonEpisodeList = response.data.data
        m.paginationData = {}
        m.paginationData["total_display_records"] = response.data.total_display_records
        m.paginationData["total_records"] = response.data.total_records
        m.paginationData["last_page"] = response.data.last_page
        gridItem = createObject("roSGNode", "contentNode")
        selectedIndex = 0
        episodeId = ""
        episodeIndex = 0
        if isValidDeeplinkingParams() then episodeId = m.scene.deeplinkingData.episodeId
        if m.top.contentNode.sliderId = "seguirviendo" AND isValid(m.top.contentNode.itemData) AND isValid(m.top.contentNode.itemData.slug) then episodeId = m.top.contentNode.itemData.slug
        for each vid in m.seasonEpisodeList
            vid.image_orientation = "episode"
            episodeItem = gridItem.CreateChild("EpisodeItemNode")
            if m.top.contentNode.sliderId = "seguirviendo" AND m.programProgress > 0
                vid.time = m.programProgress
            end if
            episodeItem.setFields(vid)
            if isValid(vid) AND isNonEmptyString(episodeId) AND (vid.slug = episodeId OR vid.id = episodeId)
                episodeIndex = selectedIndex
            end if
            selectedIndex++
        end for
        m.mgEpisode.content = gridItem
        if ((isValidDeeplinkingParams() OR (isValid(m.scene.deepLinkingMediaType) AND m.scene.deepLinkingMediaType = "series")) OR (m.top.contentNode.sliderId = "seguirviendo" AND m.scene.isWatchHistoryFetched = false))
            if isValidDeeplinkingParams() then m.scene.deepLinkingContentId = ""
            m.mgEpisode.ItemSelected = episodeIndex
        end if
        m.mgEpisode.visible = true
    end if
    m.scene.deepLinkingContentId = ""
    showHidePageLoader(false)
end sub

function isValidDeeplinkingParams() as boolean
    return isNonEmptyString(m.scene.deepLinkingContentId) AND isNonEmptyString(m.scene.deepLinkingMediaType) AND isValid(m.scene.deeplinkingData) AND isNonEmptyString(m.scene.deeplinkingData.episodeId)
end function

sub GetDeeplinkingData()
    if isValidDeeplinkingParams()
        print "DetailPage : GetDeeplinkingData"
        m.scene.isDeeplinking = true
        if isValid(m.bWatchNow) AND m.bWatchNow.visible
            if isValid(m.videoDetails.resume)
                m.videoDetails.resume = 0
            end if
            videoInfo = m.videoDetails.setFields()
            m.scene.callFunc("StartVideo", videoInfo)
        end if
        m.scene.deepLinkingMediaType = ""
        m.scene.deepLinkingContentId = ""
    else
        m.scene.DeeplinkMsg = "No data found..."
        m.scene.deepLinkingMediaType = ""
        m.scene.deepLinkingContentId = ""
    end if

    ' if (not IsNullOrEmpty(m.scene.deepLinkingContentId) AND m.scene.deeplinkingData <> invalid AND m.scene.deeplinkingData.count() > 0 AND m.scene.isDeeplinking AND m.currentProgram <> invalid)
    '     checkDeeplinkingDetailValidorNot()
    ' else
    '     if m.scene.isDeeplinking AND not IsNullOrEmpty(m.scene.deepLinkingContentId)
    '         m.scene.isCloseTitlePage = true
    '         m.scene.callFunc("DeeplinkingDataInvalid")
    '     end if
    ' end if
end sub

sub onSeasonEpisodeDetailsAPIPaginationDataResponse(event as dynamic)
    response = event.getData()
    print "OnGetSeasonEpisodeDetailsAPIResponse : response : " 'formatjson(response)
    if isValid(response) AND isValid(response.data) AND isValid(response.data.data) AND response.data.data.count() > 0
        seasonEpisodeList = response.data.data
        m.paginationData = {}
        if isValid(response.data.total_display_records) then m.paginationData["total_display_records"] = response.data.total_display_records
        if isValid(response.data.total_records) then m.paginationData["total_records"] = response.data.total_records
        if isValid(response.data.last_page) then m.paginationData["last_page"] = response.data.last_page
        paginationData = []
        for each vid in seasonEpisodeList
            vid.image_orientation = "episode"
            programItem = CreateObject("roSGNode", "EpisodeItemNode")
            programItem.setFields(vid)
            paginationData.push(programItem)
        end for
        if hasValidEpisodeGrid()
            m.mgEpisode.content.insertChildren(paginationData, m.mgEpisode.content.getChildCount())
        end if
        m.isPagination = false
    end if
    showHidePageLoader(false)
end sub

sub OnEpisodeItemFocus(event as dynamic)
    index = event.getData()
    if isValid(index) AND hasValidEpisodeGrid()
        gridCount = m.mgEpisode.content.getChildCount()
        if m.isPagination = false AND isValid(m.paginationData) AND m.paginationData.count() > 0 AND m.paginationData.total_records > 0 AND m.paginationData.total_display_records > 0
            if gridCount - index <= m.indexValForPagination AND m.currentPage <= m.paginationData.last_page AND m.mgEpisode.content.getChildCount() < m.paginationData.total_records
                m.isPagination = true
                m.currentPage++
                getSeasonEpisode(m.currentPage)
            end if
        end if
    end if
end sub

sub OnEpisodeItemSelected(event as dynamic)
    index = event.getData()
    if isValid(index) AND hasValidEpisodeGrid()
        childNode = m.mgEpisode.content.getChild(index)
        print "DetailPage : OnEpisodeItemSelected: childNode : " childNode
        objChildNode = childNode.GetFields()
        if (isValid(m.programData.image_logo) AND (m.programData.image_logo.count() > 0))
            logoImage = GetImageURL(m.programData.image_logo, "medium")
            objChildNode["logoTitle"] = logoImage
        else
            objChildNode["title"] = m.programData.title
        end if
        if isValid(childNode)
            m.scene.callFunc("StartVideo", objChildNode)
        end if
    end if
end sub

sub CreateDetailsSection()
    if isValid(m.programData) AND m.programData.count() > 0
        containerWidth = 1720 ' fallback
        leftWidth = containerWidth * 0.6
        rightWidth = containerWidth * 0.2
        centerWidth = containerWidth * 0.2
        hGroup = CreateObject("roSGNode", "LayoutGroup")
        hGroup.layoutDirection = "horiz"
        hGroup.itemSpacings = [20]
        leftGroup = createLeftSection(m.programData, leftWidth)
        centerGroup = createCenterSection(m.programData, centerWidth)
        rightGroup = createRightSection(m.programData, rightWidth)
        hGroup.appendChild(leftGroup)
        hGroup.appendChild(centerGroup)
        hGroup.appendChild(rightGroup)
        m.gDetailsSection.appendChild(hGroup)
        m.gDetailsSection.visible = true
    end if
end sub

function createLeftSection(content as object, width as float) as object
    group = CreateObject("roSGNode", "LayoutGroup")
    group.layoutDirection = "vert"
    group.itemSpacings = [20]
    title = CreateObject("roSGNode", "Label")
    title.width = width
    title.text = "Synopsis"
    title.color = m.theme.white
    title.font = m.fonts.dmSansBold28
    desc = CreateObject("roSGNode", "Label")
    desc.width = width
    desc.wrap = true
    desc.maxLines = 5
    desc.color = m.theme.clrSecondaryText
    desc.font = m.fonts.dmSansMedium24
    if content.description <> invalid AND content.description <> ""
        desc.text = content.description
    else if content.description_short <> invalid AND content.description_short <> ""
        desc.text = content.description_short
    else
        desc = ""
    end if
    group.appendChild(title)
    group.appendChild(desc)
    return group
end function

function createCenterSection(content as object, width as float) as object
    group = CreateObject("roSGNode", "LayoutGroup")
    group.layoutDirection = "vert"
    group.itemSpacings = [20]
    group.appendChild(createLabel("Duración", getValue(content.duration), width))
    group.appendChild(createLabel("Año", getValue(content.anio_production.toStr()), width))
    group.appendChild(createLabel("Género", getValue(getGeneder("", "name")), width))
    return group
end function

function createRightSection(content as object, width as float) as object
    group = CreateObject("roSGNode", "LayoutGroup")
    group.layoutDirection = "vert"
    group.itemSpacings = [20]
    group.appendChild(createLabel("Director", getValue(content.director), width))
    group.appendChild(createLabel("Writer", getValue(content.writer), width))
    return group
end function

function createLabel(label as string, value as dynamic, width as float) as object
    node = CreateObject("roSGNode", "Label")
    node.width = width
    node.color = m.theme.clrSecondaryText
    node.font = m.fonts.dmSansMedium20
    node.text = label + ": " + value
    return node
end function

function getGeneder(genderText = "", keyName = "slug" as string)
    if isValid(m.programData.genders) AND m.programData.genders.Count() > 0
        isFirst = false
        for each item in m.programData.genders
            if isValid(item[keyName]) AND isNonEmptyString(item[keyName])
                if isFirst = false then genderText = " - "
                if isFirst then genderText += ", "
                isFirst = true
                genderText += item[keyName]
            end if
        end for
    end if
    return genderText
end function

sub CallFavouriteAPI(action as string)
    params = {}
    params["action"] = action
    params["client"] = m.appConfig.client
    params["program"] = m.top.contentNode.itemData.key
    params["profile"] = GlobalGet("selectedProfileID")
    m.FavouriteAPITask = CreateObject("roSGNode", "ContentAPIAction")
    m.FavouriteAPITask.functionName = "AddRemoveFavourite"
    m.FavouriteAPITask.params = params
    m.FavouriteAPITask.ObserveField("result", "onFavouriteAPIResponse")
    m.FavouriteAPITask.control = "RUN"
end sub

sub onFavouriteAPIResponse(event as dynamic)
    response = event.getData()
    node = event.getRoSGNode().params
    if isValid(response) AND isValid(response.data) AND isValid(response.ok) AND response.ok
        if node.action = "add"
            data = { 
                backGroundImage: "pkg:/images/icons/removeFromMylist-icon.png"
                focusBorderImage: "pkg:/images/icons/removeFromMylist-icon.png" 
            }
            m.favouriteStatus = true
        else
            data = { 
                backGroundImage: "pkg:/images/icons/addToMylist-icon.png"
                focusBorderImage: "pkg:/images/icons/addToMylist-icon.png" 
            }
            m.favouriteStatus = false
        end if
        m.bAddToFavourite.update(data)
    end if
end sub

function hasFocusOnWatchButton()
    m.lastFocusedButton = m.bWatchNow
    return isValid(m.bWatchNow) AND (m.bWatchNow.hasFocus() OR m.bWatchNow.IsInFocusChain())
end function

function hasFocusOnFavouriteButton()
    m.lastFocusedButton = m.bAddToFavourite
    return isValid(m.bAddToFavourite) AND (m.bAddToFavourite.hasFocus() OR m.bAddToFavourite.IsInFocusChain())
end function

function hasFocusOnMetadataButtons()
    return hasFocusOnWatchButton() OR hasFocusOnFavouriteButton()
end function

function hasFocusOnTabView()
    return isValid(m.tabView) AND (m.tabView.hasFocus() OR m.tabView.IsInFocusChain())
end function

function hasFocusOnSeasonTabView()
    return isValid(m.seasonTabView) AND (m.seasonTabView.hasFocus() OR m.seasonTabView.IsInFocusChain())
end function

function hasFocusOnEpisodeList()
    return hasValidEpisodeGrid() AND (m.mgEpisode.hasFocus() OR m.mgEpisode.IsInFocusChain())
end function

function hasValidEpisodeGrid()
    return isValid(m.mgEpisode) AND isValid(m.mgEpisode.content) AND m.mgEpisode.content.getChildCount() > 0
end function

sub OnOkKeyPress()
    if hasFocusOnFavouriteButton() 
        if m.scene.isUserLoggedIn
            if m.favouriteStatus
                action = "delete"
            else
                action = "add"
            end if
            CallFavouriteAPI(action)
        else
            m.scene.callFunc("ShowOnboardingPage", false)
        end if
    else if hasFocusOnWatchButton()
        if isValid(m.lastPlayedEpisode)
            m.scene.callFunc("StartVideo", m.lastPlayedEpisode.GetFields())
        else if hasValidEpisodeGrid()
            m.mgEpisode.ItemSelected = 0
        end if
        ' m.scene.callFunc("StartVideo", m.top.contentNode)
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    result = false
    print "DetailPage : onKeyEvent : key = " key " press = " press
    if press
        if key = "back"
            if (hasFocusOnSeasonTabView() OR hasFocusOnTabView() OR hasFocusOnEpisodeList()) AND isValid(m.bWatchNow)
                startDetailsUpAnimation()
                SetFocus(m.bWatchNow)
                result = true
            else
                m.scene.hasTopMenuBackground = true
            end if
            if m.favouriteStatus = false
                m.scene.RefreshMylistPage = true
            end if
        else if key = "OK"
            OnOkKeyPress()
        else if key = "down"
            result = true
            if hasFocusOnTabView() AND m.isDetailsScreenVisible = true
                result = true
            else if hasFocusOnTabView() AND isValid(m.seasonTabView)
                SetFocus(m.seasonTabView)
            else if hasFocusOnSeasonTabView() AND isValid(m.mgEpisode)
                SetFocus(m.mgEpisode)
            else if hasFocusOnMetadataButtons() AND isValid(m.tabView)
                startDetailsDownAnimation()
                SetFocus(m.tabView)
            end if
        else if key = "up"
            result = true
            if hasFocusOnEpisodeList() AND isValid(m.seasonTabView)
                SetFocus(m.seasonTabView)
            else if hasFocusOnSeasonTabView() AND isValid(m.tabView)
                SetFocus(m.tabView)
            else if hasFocusOnTabView() AND isValid(m.bWatchNow)
                startDetailsUpAnimation()
                if isValid(m.lastFocusedButton)
                    SetFocus(m.lastFocusedButton)
                end if
            end if
        else if key = "right"
            if hasFocusOnWatchButton() AND isValid(m.bAddToFavourite)
                result = true
                SetFocus(m.bAddToFavourite)
            end if
        else if key = "left"
            if hasFocusOnFavouriteButton() AND isValid(m.bWatchNow)
                result = true
                SetFocus(m.bWatchNow)
            end if
        end if
    end if
    return result
end function
