sub init()
    SetLocals()
    SetControls()
    SetupFonts()
    SetupColors()
end sub

sub SetLocals()
    m.fonts = m.global.fonts
    m.theme = m.global.appTheme
    m.appConfig = m.global.appConfig
end sub

sub SetControls()
    m.gHorizCard = m.top.findNode("gHorizCard")
    m.mgHBorderMask = m.top.findNode("mgHBorderMask")
    m.rHRightTop = m.top.findNode("rHRightTop")
    m.lHRightTop = m.top.findNode("lHRightTop")
    m.lHEpigrafe = m.top.findNode("lHEpigrafe")
    m.lHTitle = m.top.findNode("lHTitle")
    m.pHCard = m.top.findNode("pHCard")
    m.pUnfillProgressRect = m.top.findNode("pUnfillProgressRect")
    m.pFillProgressRect = m.top.findNode("pFillProgressRect")

    m.gVerticalCard = m.top.findNode("gVerticalCard")
    m.mgVBorderMask = m.top.findNode("mgVBorderMask")
    m.rVRightTop = m.top.findNode("rVRightTop")
    m.lVRightTop = m.top.findNode("lVRightTop")
    m.pVCard = m.top.findNode("pVCard")
    m.rVBottomTime = m.top.findNode("rVBottomTime")
    m.lVBottomTime = m.top.findNode("lVBottomTime")

    m.gNumber = m.top.findNode("gNumber")
    m.mgNumberBorderMask = m.top.findNode("mgNumberBorderMask")
    m.pNumber = m.top.findNode("pNumber")
    m.lNumberRightTop = m.top.findNode("lNumberRightTop")
    m.pNCard = m.top.findNode("pNCard")

    m.gCircle = m.top.findNode("gCircle")
    m.pCircleCard = m.top.findNode("pCircleCard")
    m.pCircleRing = m.top.findNode("pCircleRing")
    m.pCircleLockBg = m.top.findNode("pCircleLockBg")
    m.pCircleLock = m.top.findNode("pCircleLock")

    m.gEpisodeCard = m.top.findNode("gEpisodeCard")
    m.mgEBorderMask = m.top.findNode("mgEBorderMask")
    m.pECard = m.top.findNode("pECard")
    m.lETime = m.top.findNode("lETime")
    m.lEDescription = m.top.findNode("lEDescription")

    m.gViewMoreCard = m.top.findNode("gViewMoreCard")
    m.mgViewMoreBorderMask = m.top.findNode("mgViewMoreBorderMask")
    m.pViewMoreCard = m.top.findNode("pViewMoreCard")
    m.lViewMoreTitle = m.top.findNode("lViewMoreTitle")
end sub

sub SetupFonts()
    m.lNumberRightTop.font = m.fonts.dmSansBold23
    m.lVRightTop.font = m.fonts.dmSansMedium18
    m.lHRightTop.font = m.fonts.dmSansMedium12
    m.lHEpigrafe.font = m.fonts.dmSansBold18
    m.lHTitle.font = m.fonts.dmSansMedium18
    m.lViewMoreTitle.font = m.fonts.dmSansMedium24
    m.lETime.font = m.fonts.dmSansBold23
    m.lEDescription.font = m.fonts.dmSansMedium20
    m.lVBottomTime.font = m.fonts.dmSansMedium12
end sub

sub SetupColors()
    m.lNumberRightTop.color = m.theme.white
    m.lVRightTop.color = m.theme.black
    m.lHRightTop.color = m.theme.white
    m.rHRightTop.color = m.theme.focPrimary
    m.lHEpigrafe.color = m.theme.focPrimary
    m.lHTitle.color = m.theme.white
    m.pUnfillProgressRect.color = m.theme.white
    m.pFillProgressRect.color = m.theme.focPrimary
    m.rVRightTop.color = m.theme.focTertiary
    m.pViewMoreCard.blendColor = m.theme.clrSecondary
    m.lViewMoreTitle.color = m.theme.White
    m.lETime.color = m.theme.clrSecondaryText
    m.lEDescription.color = m.theme.clrSecondaryText
    m.rVBottomTime.color = m.theme.focPrimary
    m.lVBottomTime.color = m.theme.white
    ' La web atenúa la imagen de las tarjetas verticales (brightness .6) y la
    ' ilumina con foco (brightness 1).
    m.pVCard.blendColor = "#999999"
end sub

sub itemContent_Changed()
    itemContent = m.top.itemContent
    m.gHorizCard.visible = false
    m.gVerticalCard.visible = false
    m.gNumber.visible = false
    m.gEpisodeCard.visible = false
    m.gViewMoreCard.visible = false
    m.gCircle.visible = false
    ResetScheduleLabels()
    ' image_land, image_logo, image_port, image_slider
    if isValid(itemContent) AND isValid(itemContent.isViewMoreCard) AND itemContent.isViewMoreCard = true
        m.gViewMoreCard.visible = true
        
        if isValid(itemContent.image_orientation) AND itemContent.image_orientation = "portrait"
            m.mgViewMoreBorderMask.maskUri = "pkg:/images/card/card_mask_324_576.png"
            m.pViewMoreCard.uri = "pkg:/images/card/card_324_576.png"
            m.pViewMoreCard.loadingBitmapUri = "pkg:/images/card/card_324_576.png"
            m.pViewMoreCard.failedBitmapUri = "pkg:/images/card/card_324_576.png"
            m.pViewMoreCard.height = "576"
            m.pViewMoreCard.loadHeight = "576"
            m.lViewMoreTitle.text = itemContent.title
            m.lViewMoreTitle.height = "576"
        else
            m.mgViewMoreBorderMask.maskUri = "pkg:/images/card/card_mask_320_180.png"
            m.pViewMoreCard.uri = "pkg:/images/card/card_320_180.png"
            m.pViewMoreCard.loadingBitmapUri = "pkg:/images/card/card_320_180.png"
            m.pViewMoreCard.failedBitmapUri = "pkg:/images/card/card_320_180.png"
            m.pViewMoreCard.height = "180"
            m.pViewMoreCard.loadHeight = "180"
            m.lViewMoreTitle.text = itemContent.title
            m.lViewMoreTitle.height = "180"
        end if
        m.mgViewMoreBorderMask.maskSize = getMaskSize(m.pViewMoreCard)
        m.lViewMoreTitle.text = itemContent.title
    else if isValid(itemContent) AND isValid(itemContent.image_orientation) AND (itemContent.image_orientation = "episode" OR itemContent.image_orientation = "eventEpisode")
        m.gEpisodeCard.visible = true
        if itemContent.image <> invalid AND isNonEmptyString(itemContent.image)
            imageURL = itemContent.image
        else
            imageURL = GetImageURL(itemContent.image_land, "small")
        end if
        ' imageURL = itemContent.image
        if isEmptyString(imageURL) then 
            imageURL = "pkg:/images/card/card_320_180.png"
        end if
        m.pECard.uri = imageURL
        m.mgEBorderMask.maskSize = getMaskSize(m.pECard)
        SetEpisodeSchedule(itemContent)
        m.lEDescription.text = itemContent.title
    else if isValid(itemContent) AND isValid(itemContent.image_orientation) AND itemContent.image_orientation = "portrait" AND isValid(itemContent.format) AND itemContent.format = "ranking"
        imageURL = GetImageURL(itemContent.image_port, "small")
        if isEmptyString(imageURL) then 
            imageURL = "pkg:/images/card/card_324_576.png"
        end if
        m.pNCard.uri = imageURL
        m.lNumberRightTop.text = itemContent.number
        m.mgNumberBorderMask.maskSize = getMaskSize(m.mgNumberBorderMask)
        m.gNumber.visible = true
    else if isValid(itemContent) AND isValid(itemContent.format) AND itemContent.format = "circle"
        m.pCircleCard.uri = itemContent.image
        ringColor = m.theme.focPrimary
        if isNonEmptyString(itemContent.ringColor) then ringColor = itemContent.ringColor
        m.pCircleRing.blendColor = ringColor
        blocked = itemContent.blocked = true
        m.pCircleLockBg.visible = blocked
        m.pCircleLock.visible = blocked
        m.gCircle.visible = true
    else if isValid(itemContent) AND isValid(itemContent.image_orientation) AND itemContent.image_orientation = "portrait"
        if isValid(itemContent.type) AND (itemContent.type = "live" OR itemContent.type = "program") AND isValid(itemContent.gmt0_unlocked) AND itemContent.gmt0_unlocked <> ""
            SetBadge(itemContent)
        end if
        imageURL = GetImageURL(itemContent.image_port, "small")
        if isEmptyString(imageURL) then 
            imageURL = "pkg:/images/card/card_324_576.png"
        end if
        m.pVCard.uri = imageURL
        m.mgVBorderMask.maskSize = getMaskSize(m.mgVBorderMask)
        SetVerticalCardSchedule(itemContent)
        m.gVerticalCard.visible = true
    else
        imageURL = GetImageURL(itemContent.image_land, "small")
        if isEmptyString(imageURL) then
            imageURL = "pkg:/images/card/card_320_180.png"
        end if
        m.pHCard.uri = imageURL
        m.mgHBorderMask.maskSize = getMaskSize(m.mgHBorderMask)
        if isValid(itemContent.duration_seg) AND itemContent.duration_seg > 0 AND isValid(itemContent.time) AND itemContent.time > 0
            GetWidthOfProgress(itemContent.duration_seg, itemContent.time)
        else
            m.pFillProgressRect.visible = false
            m.pUnfillProgressRect.visible = false
        end if
        m.lHEpigrafe.text = ""
        m.lHEpigrafe.visible = false
        if isValid(itemContent.epigrafe) AND isNonEmptyString(itemContent.epigrafe)
            m.lHEpigrafe.text = itemContent.epigrafe
            m.lHEpigrafe.visible = true
        end if
        m.lHTitle.text = ""
        if isValid(itemContent.title) AND isNonEmptyString(itemContent.title)
            m.lHTitle.text = itemContent.title
        end if
        m.rHRightTop.visible = false
        if isValid(itemContent.duration) AND isNonEmptyString(itemContent.duration)
            m.lHRightTop.text = itemContent.duration
            m.rHRightTop.visible = true
        end if
        m.gHorizCard.visible = true
    end if
end sub

sub ResetScheduleLabels()
    m.lETime.text = ""
    m.lETime.visible = false
    m.lEDescription.translation = [0, 193]
    m.lEDescription.maxLines = 3
    m.rVRightTop.visible = false
    m.lVRightTop.visible = false
    m.rVBottomTime.visible = false
    m.lVBottomTime.text = ""
end sub

sub SetEpisodeSchedule(itemContent as dynamic)
    scheduleText = ""
    if isValid(itemContent) AND isNonEmptyString(itemContent.gmt0_unlocked)
        scheduleText = getSpanishEventDateTimeText(itemContent.gmt0_unlocked)
    end if
    m.lETime.text = scheduleText
    m.lETime.visible = isNonEmptyString(scheduleText)
    if m.lETime.visible
        m.lEDescription.translation = [0, 225]
        m.lEDescription.maxLines = 2
    else
        m.lEDescription.translation = [0, 193]
        m.lEDescription.maxLines = 3
    end if
end sub

sub SetVerticalCardSchedule(itemContent as dynamic)
    scheduleText = ""
    if isValid(itemContent) AND isNonEmptyString(itemContent.gmt0_unlocked)
        scheduleText = getSpanishEventDateTimeText(itemContent.gmt0_unlocked)
    end if
    m.lVBottomTime.text = scheduleText
    m.rVBottomTime.visible = isNonEmptyString(scheduleText)
end sub

sub GetWidthOfProgress(videoDuration as integer, resumePos as integer)
    progressbarWidth = 320
    progressPercents = 0
    if (isValid(videoDuration) AND videoDuration > 0 AND isValid(resumePos) AND resumePos > 0)
        progressPercents = getProgressPercent(resumePos, videoDuration)
    end if
    if hasResumeProgress(progressPercents)
        progressPercent = (progressPercents * progressbarWidth) / 100
        m.pFillProgressRect.width = progressPercent
        m.pFillProgressRect.visible = true
        m.pUnfillProgressRect.visible = true
        m.pUnfillProgressRect.translation = [0, m.pHCard.boundingRect().height - 10]
        m.pFillProgressRect.translation = [0, m.pUnfillProgressRect.translation[1]]
    else
        m.pFillProgressRect.visible = false
        m.pUnfillProgressRect.visible = false
    end if
end sub

function SetBadge(content, isPageDetail = false)
    badgeText = getBadgeText(content, isPageDetail)
    isVisible = isNonEmptyString(badgeText)
    if isVisible
        m.lVRightTop.text = badgeText
        m.lVRightTop.width = m.lVRightTop.BoundingRect().width
        m.rVRightTop.width = m.lVRightTop.BoundingRect().width + 20
    else
        m.lVRightTop.text = ""
    end if
    m.rVRightTop.visible = isVisible
    m.lVRightTop.visible = isVisible
end function


sub setSize(percent as float)
    if m.gCircle.visible
        if percent > 0
            m.pCircleRing.uri = "pkg:/images/masks/circle_ring_thick.png"
        else
            m.pCircleRing.uri = "pkg:/images/masks/circle_ring_thin.png"
        end if
    end if
    if m.gVerticalCard.visible
        if percent > 0
            m.pVCard.blendColor = m.theme.white
        else
            m.pVCard.blendColor = "#999999"
        end if
    end if
end sub

sub FocusPercent_Changed(event as dynamic)
    value = event.GetData()
    if (m.top.rowListHasFocus AND m.top.RowHasFocus) then
        setSize(value)
    else
        setSize(0)
    end if
end sub

sub ItemHasFocus_Changed(event as dynamic)
    value = event.GetData()
    if (value) then
        SetSize(1)
    end if
end sub

sub RowHasFocus_Changed()
    if (m.top.RowHasFocus AND m.top.ItemHasFocus) then
        SetSize(1)
    else
        SetSize(0)
    end if
end sub

sub ParentHasFocus_Changed()
    if ((m.top.RowListHasFocus AND m.top.RowHasFocus) AND (m.top.ItemHasFocus OR m.top.FocusPercent = 1)) then
        SetSize(1)
    else
        SetSize(0)
    end if
end sub
