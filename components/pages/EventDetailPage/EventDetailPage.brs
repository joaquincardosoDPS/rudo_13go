sub init()
    setLocals()
    setControls()
    setUpColor()
    setUpFonts()
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
    m.staticResumeProgress = 0
    m.staticResumeDuration = 0
    m.isDetailsScreenVisible = false
    resetPagination()
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
    m.bWatchNow = m.top.findNode("bWatchNow")
    m.pVideo = m.top.findNode("pVideo")
    m.gSegmentGrid = m.top.findNode("gSegmentGrid")
    m.tabView = m.top.findNode("tabView")
    m.horizLine = m.top.findNode("horizLine")
    m.mgEpisode = m.top.findNode("mgEpisode")
    m.gDetailsSection = m.top.findNode("gDetailsSection")
    m.rBottomMetaOverlay = m.top.findNode("rBottomMetaOverlay")
    m.gDetailsContent = m.top.findNode("gDetailsContent")

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
end sub

sub setUpColor()
    ' m.pMetaOverlay.blendColor = m.theme.black
    m.rBottomMetaOverlay.color = "#001A28"
    m.pUnfillProgressRect.blendColor = m.theme.white
    m.pFillProgressRect.blendColor = m.theme.focPrimary
    m.lRemainingTime.color = m.theme.clrSecondaryText
    m.horizLine.color = m.theme.white
end sub

sub setObservers()
    m.top.observeField("focusedChild", "onFocusedChild")
    m.top.observeField("visible", "onVisibleChanged")
    m.scene.ObserveField("isItemAddRemoveFav", "onAddRemoveItemFromMyListBtn")
    m.tabView.observeField("updateContent", "onUpdateContent")
    m.mgEpisode.observeField("itemFocused", "OnEpisodeItemFocus")
    m.mgEpisode.observeField("itemSelected", "OnEpisodeItemSelected")
    m.transAnimation = m.top.FindNode("transAnimation")
    m.scene.observeField("isWatchHistoryFetched", "refreshContent")
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
        if isValid(contentNode.itemData.format) AND contentNode.itemData.format = "event"
            keyId = contentNode.itemData.key
            getProgramDetails(keyId)
        end if
    end if
end sub

sub getProgramDetails(programKey as string)
    showHidePageLoader(true)
    params = {}
    params["client"] = m.appConfig.client
    m.getProgramDetailsTask = CreateObject("roSGNode", "ContentAPIAction")
    params["event"] = programKey
    m.getProgramDetailsTask.functionName = "GetProgramEventsDetails"
    m.getProgramDetailsTask.params = params
    m.getProgramDetailsTask.ObserveField("result", "OnGetProgramDetailsAPIResponse")
    m.getProgramDetailsTask.control = "RUN"
end sub

sub OnGetProgramDetailsAPIResponse(event as dynamic)
    response = event.getData()
    print "OnGetProgramDetailsAPIResponse : response : " 'formatjson(response)
    if isValid(response) AND isValid(response.data) AND isValid(response.data.data) AND response.data.data.count() > 0
        m.programData = response.data.data
        updateMetaDetails()
    end if
    checkAndCreateBottomList()
    showHidePageLoader(false)
end sub

sub ResetDetails()
    if isValid(m.pBackClassification)
        m.pBackClassification.unObserveField("loadStatus")
        m.pBackClassification = invalid
    end if
    if isValid(m.pSmallLogo)
        m.pSmallLogo.unObserveField("loadStatus")
        m.pSmallLogo = invalid
    end if
    m.lgDetails.removeChildrenIndex(m.lgDetails.getChildCount(), 0)
    m.gDetailsSection.removeChildrenIndex(m.gDetailsSection.getChildCount(), 0)
    m.bWatchNow = invalid
end sub

sub updateMetaDetails()
    m.lgDetails.itemSpacings = [15, 15, 15, 40, 40, 30]
    if (isValid(m.programData))
        if isNonEmptyString(m.programData.gmt0_unlocked)
            pBadge = createObject("roSGNode", "Poster")
            pBadge.id = "pBackClassification"
            pBadge.uri = "pkg:/images/focus/white_fill_corner_radius_10.9.png"
            pBadge.height = 15
            pBadge.blendColor = m.theme.focTertiary
            pBadge.loadDisplayMode = "scaleToFit"
            lBadge = createObject("roSGNode", "Label")
            lBadge.id = "lBadge"
            lBadge.font = m.fonts.dmSansMedium14
            lBadge.color = m.theme.black
            lBadge.text = getBadgeText(m.programData, true)
            pBadge.width = lBadge.boundingRect().width + 12
            pBadge.height = lBadge.boundingRect().height + 4
            lBadge.width = pBadge.width
            lBadge.height = pBadge.height
            lBadge.horizAlign = "center"
            lBadge.vertAlign = "center"
            pBadge.appendChild(lBadge)
            m.lgDetails.appendChild(pBadge)
        end if
        imageURL = ""
        imageType = "big"
        if m.global.designresolution = "720p" then imageType = "medium"
        if isValid(m.programData.image_background) AND m.programData.image_background.count() > 0
            imageURL = GetImageURL(m.programData.image_background, imageType)
        end if
        if imageURL = ""
            imageURL = GetImageURL(m.programData.image_land, imageType)
        end if
        if isNonEmptyString(imageURL) then m.pVideo.uri = imageURL
        isLogo = false
        if (isValid(m.programData.image_logo) AND (m.programData.image_logo.count() > 0))
            logoImage = GetImageURL(m.programData.image_logo, "medium")
            if isNonEmptyString(logoImage)
                m.pBackClassification = createObject("roSGNode", "Poster")
                m.pBackClassification.id = "pBackClassification"
                m.pBackClassification.uri = logoImage
                m.pBackClassification.height = 160
                m.pBackClassification.observeField("loadStatus", "onImageLoadStatusChange")
                m.pBackClassification.loadDisplayMode = "scaleToFit"
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
        if (isValid(m.programData.classification) AND (isNonEmptyString(m.programData.classification)))
            pRating = createObject("roSGNode", "Poster")
            pRating.id = "pRating"
            pRating.loadDisplayMode = "scaleTozoom"
            pRating.uri = "pkg:/images/other/rating_back.png"
            pRating.blendColor = m.theme.black
            lRating = createObject("roSGNode", "Label")
            lRating.id = "lRating"
            lRating.font = m.fonts.dmSansMedium14
            lRating.color = m.theme.white
            lRating.text = UCase(m.programData.classification)
            pRating.width = lRating.boundingRect().width + 12
            pRating.height = lRating.boundingRect().height + 4
            lRating.width = pRating.width
            lRating.height = pRating.height
            lRating.horizAlign = "center"
            lRating.vertAlign = "center"
            pRating.appendChild(lRating)
            m.lgDetails.appendChild(pRating)
        end if
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
        m.lgDetails.appendChild(m.bWatchNow)
        SetFocus(m.bWatchNow)

        lgHoriz = createObject("roSGNode", "LayoutGroup")
        lgHoriz.id = "lgHoriz"
        lgHoriz.layoutDirection = "horiz"
        lgHoriz.vertAlignment = "center"
        lgHoriz.itemSpacings = "20"
        if isValid(m.programData.category) AND m.programData.category.count() > 0
            catLogo = GetImageURL(m.programData.category.image_logo, "medium")
            m.pSmallLogo = createObject("roSGNode", "Poster")
            m.pSmallLogo.id = "pSmallLogo"
            m.pSmallLogo.uri = catLogo
            m.pSmallLogo.height = 80
            m.pSmallLogo.observeField("loadStatus", "onImageLoadStatusChange")
            m.pSmallLogo.loadDisplayMode = "scaleToFit"
            lgHoriz.appendChild(m.pSmallLogo)

            if isValid(m.programData.category.name)
                lTitle = createObject("roSGNode", "Label")
                lTitle.id = "lTitle"
                lTitle.width = 900
                lTitle.lineSpacing = -3
                lTitle.wrap = true
                lTitle.maxLines = 2
                lTitle.font = m.fonts.dmSansMedium24
                lTitle.color = m.theme.clrPrimaryTitle
                lTitle.text = m.programData.category.name
                lgHoriz.appendChild(lTitle)
            end if
        end if
        m.lgDetails.appendChild(lgHoriz)

        lMainTitle = createObject("roSGNode", "Label")
        lMainTitle.id = "lTitle"
        lMainTitle.width = 900
        lMainTitle.lineSpacing = -3
        lMainTitle.wrap = true
        lMainTitle.maxLines = 2
        lMainTitle.font = m.fonts.dmSansBold36
        lMainTitle.color = m.theme.white
        lMainTitle.text = m.programData.title
        m.lgDetails.appendChild(lMainTitle)
        if isValid(m.programData.description) AND isNonEmptyString(m.programData.description)
            lDescription = createObject("roSGNode", "Label")
            lDescription.id = "lDescription"
            lDescription.width = 700
            lDescription.lineSpacing = -3
            lDescription.wrap = true
            lDescription.maxLines = 3
            lDescription.font = m.fonts.dmSansMedium24
            lDescription.color = m.theme.white
            if m.programData.description_short <> invalid AND m.programData.description_short <> ""
                lDescription.text = m.programData.description_short
            else if m.programData.description <> invalid
                lDescription.text = m.programData.description
            else
                lDescription.text = ""
            end if
            m.lgDetails.appendChild(lDescription)
        end if
    end if
    ' shortMetaDataBoundingRect = m.lgDetails.boundingRect()
    ' m.lgDetails.translation = [shortMetaDataBoundingRect.x, shortMetaDataBoundingRect.y + shortMetaDataBoundingRect.height + 20]
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

function checkTextBlankOrNot(metaText as string) as string
    metaTextNew = ""
    if metaText <> invalid AND metaText <> ""
        metaTextNew = metaText + "  •  "
        return metaTextNew
    else
        return metaTextNew
    end if
end function

function getWatchButtonText(progressPercent as integer) as string
    if hasResumeProgress(progressPercent)
        return "Continuar"
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
    remainingSeconds = getResumeDuration() - m.staticResumeProgress
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
    segments = []
    if isValid(m.programData) 
        if m.programData.segments <> invalid AND m.programData.segments.Count() > 0
            segments = m.programData.segments
        end if
        m.gSegmentGrid.visible = false
        m.tabView.visible = false
        m.horizLine.visible = false
        m.mgEpisode.visible = false
        m.lastSelectedTabData = invalid
        if (segments = invalid OR (isValid(segments) AND segments.Count() = 0))
            related = {
                "all_temp": [],
                "id": "relacionados",
                "key": "",
                "max_temp": 0,
                "name": "Relacionados"
            }
            segments.push(related)
        end if
        details = {
            "all_temp": [],
            "id": "detalles",
            "key": "",
            "max_temp": 0,
            "name": "Detalles"
        }
        segments.push(details)
        if isValid(segments) AND segments.Count() > 0
            m.tabView.tabData = segments
            m.gSegmentGrid.visible = true
            m.tabView.visible = true
            m.horizLine.visible = true
            m.tabView.initSelect = true
        end if
    end if
    startAnimation()
end sub

sub onUpdateContent(event as dynamic)
    tabData = event.getData()
    m.gDetailsSection.visible = false
    m.isDetailsScreenVisible = false
    if isValid(tabData) AND isNonEmptyString(tabData.title) AND (m.lastSelectedTabData = invalid OR tabData.id <> m.lastSelectedTabData.id)
        resetPagination()
        if tabData.title <> "Detalles"
            m.lastSelectedTabData = tabData
            m.gDetailsSection.visible = false
            getSeasonEpisode()
        else
            m.mgEpisode.visible = false
            m.lastSelectedTabData = invalid
            m.isDetailsScreenVisible = true
            CreateDetailsSection()
            m.gDetailsSection.visible = true
        end if
    end if
end sub

sub getSeasonEpisode(page = 1 as integer)
    showHidePageLoader(true)
    params = {}
    params["client"] = m.appConfig.client
    if isValid(m.top.contentNode) AND isValid(m.top.contentNode.itemData)
        params["slug_exclude"] = m.top.contentNode.itemData.key
        params["category"] = m.top.contentNode.itemData.category_key
        params["page"] = page
        params["order"] = "num_capitulo"
        params["order_type"] = "asc"
        params["limit"] = 25
        if m.lastSelectedTabData <> invalid then params["season"] = m.lastSelectedTabData.id
        if m.lastSelectedTabData <> invalid then params["season"] = m.lastSelectedTabData.id
        m.getProgramDetailsTask = CreateObject("roSGNode", "ContentAPIAction")
        m.getProgramDetailsTask.functionName = "GetEventSeasonEpisodeDetails"
        m.getProgramDetailsTask.params = params
        if m.isPagination
            m.getProgramDetailsTask.ObserveField("result", "onSeasonEpisodeDetailsAPIPaginationDataResponse")
        else
            m.getProgramDetailsTask.ObserveField("result", "OnGetSeasonEpisodeDetailsAPIResponse")
        end if
        m.getProgramDetailsTask.control = "RUN"
    end if
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
        for each vid in m.seasonEpisodeList
            vid.image_orientation = "eventEpisode"
            episodeItem = gridItem.CreateChild("EpisodeItemNode")
            episodeItem.setFields(vid)
        end for
        m.mgEpisode.content = gridItem
        m.mgEpisode.visible = true
        if isNonEmptyString(m.scene.deepLinkingContentId) AND isNonEmptyString(m.scene.deepLinkingMediaType) 
            if isValid(m.scene.deeplinkingData) AND isNonEmptyString(m.scene.deeplinkingData.episodeId)
                episodeId = m.scene.deeplinkingData.episodeId
                for i = 0 to m.mgEpisode.content.getChildCount() - 1
                    episodeNode = m.mgEpisode.content.getChild(i)
                    if isValid(episodeNode) AND (episodeNode.slug = episodeId OR episodeNode.id = episodeId)
                        m.mgEpisode.ItemSelected = i
                        exit for
                    end if
                end for
            else
                m.mgEpisode.ItemSelected = 0
            end if
            m.scene.callFunc("CloseDeeplinkDialog")
        end if
    end if
    showHidePageLoader(false)
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
            vid.image_orientation = "eventEpisode"
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
        print "DetailPage : OnEpisodeItemSelected: childNode : " childNode.getFields()
        if isValid(childNode)
            startDetailsUpAnimation()
            ResetDetails()
            getProgramDetails(childNode.key)
        end if
    end if
end sub

sub CreateDetailsSection()
    if isValid(m.programData) AND m.programData.count() > 0
        containerWidth = 1720 ' fallback
        leftWidth = containerWidth * 0.8
        ' rightWidth = containerWidth * 0.2
        ' centerWidth = containerWidth * 0.2
        hGroup = CreateObject("roSGNode", "LayoutGroup")
        hGroup.layoutDirection = "horiz"
        hGroup.itemSpacings = [20]
        leftGroup = createLeftSection(m.programData, leftWidth)
        ' centerGroup = createCenterSection(m.programData, centerWidth)
        ' rightGroup = createRightSection(m.programData, rightWidth)
        hGroup.appendChild(leftGroup)
        ' hGroup.appendChild(centerGroup)
        ' hGroup.appendChild(rightGroup)
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
    title.color = m.theme.White
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
        desc.text = "Sigue todos los partidos en vivo a través de nuestra señal y vibra con el fútbol junto a Chilevisión."
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
        genderText = "- "
        isFirst = false
        for each item in m.programData.genders
            if isValid(item[keyName]) AND isNonEmptyString(item[keyName])
                if isFirst then genderText += ", "
                isFirst = true
                genderText += item[keyName]
            end if
        end for
    end if
    return genderText
end function

function hasFocusOnWatchButton()
    m.lastFocusedButton = m.bWatchNow
    return isValid(m.bWatchNow) AND (m.bWatchNow.hasFocus() OR m.bWatchNow.IsInFocusChain())
end function

function hasFocusOnMetadataButtons()
    return hasFocusOnWatchButton()
end function

function hasFocusOnTabView()
    return isValid(m.tabView) AND (m.tabView.hasFocus() OR m.tabView.IsInFocusChain())
end function

function hasFocusOnEpisodeList()
    return hasValidEpisodeGrid() AND (m.mgEpisode.hasFocus() OR m.mgEpisode.IsInFocusChain())
end function

function hasValidEpisodeGrid()
    return isValid(m.mgEpisode) AND isValid(m.mgEpisode.content) AND m.mgEpisode.content.getChildCount() > 0
end function

sub OnOkKeyPress()
    if hasFocusOnWatchButton()
        m.scene.callFunc("UpdateSelectedTopMenu", 3)
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    result = false
    print "DetailPage : onKeyEvent : key = " key " press = " press
    if press
        if key = "back"
            m.scene.hasTopMenuBackground = true
        else if key = "OK"
            OnOkKeyPress()
        else if key = "down"
            result = true
            if hasFocusOnTabView() AND m.isDetailsScreenVisible = true
                result = true
            else if hasFocusOnTabView() AND isValid(m.mgEpisode)
                SetFocus(m.mgEpisode)
            else if hasFocusOnMetadataButtons() AND isValid(m.tabView)
                startDetailsDownAnimation()
                SetFocus(m.tabView)
            end if
        else if key = "up"
            result = true
            if hasFocusOnEpisodeList() AND isValid(m.tabView)
                SetFocus(m.tabView)
            else if hasFocusOnTabView() AND isValid(m.bWatchNow)
                startDetailsUpAnimation()
                if isValid(m.lastFocusedButton)
                    SetFocus(m.lastFocusedButton)
                end if
            end if
        else if key = "right"
            result = true
        else if key = "left"
            result = true
        end if
    end if
    return result
end function