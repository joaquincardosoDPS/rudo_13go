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
    m.scene = m.top.getScene()
end sub

sub setControls()
    m.gDetails = m.top.findNode("gDetails")
    m.shortMetaData = m.top.findNode("shortMetaData")
    m.lgDetails = m.top.findNode("lgDetails")
    m.pMetaOverlay = m.top.findNode("pMetaOverlay")
    ' m.bWatchNow = m.top.findNode("bWatchNow")
    m.pVideo = m.top.findNode("pVideo")
end sub

sub setUpFonts()
end sub

sub setUpColor()
    ' m.pMetaOverlay.blendColor = m.theme.black
end sub

sub setObservers()
    m.top.observeField("focusedChild", "onFocusedChild")
    m.top.observeField("visible", "onVisibleChanged")
    m.scene.ObserveField("isItemAddRemoveFav", "onAddRemoveItemFromMyListBtn")
end sub

sub onFocusedChild()
    if m.top.hasFocus()
        ' if isValid(m.bWatchNow) AND m.bWatchNow.visible
        '     setFocus(m.bWatchNow)
        ' end if
    end if
end sub

sub onVisibleChanged()
    if m.top.visible
        ' setFocus(m.bWatchNow)
    end if
end sub

sub onContentInfoChanged()
    contentNode = m.top.contentNode
    m.content = contentNode.getFields()
    if m.lgDetails.getChildCount() > 0
        m.lgDetails.removeChildrenIndex(m.lgDetails.getChildCount(), 0)
        ' m.bWatchNow = invalid
    end if
    if (isValid(m.content))
        imageType = "big"
        if m.global.designresolution = "720p" then imageType = "medium"
        m.pVideo.uri = GetImageURL(m.content.image_land, imageType)
        isLogo = false
        if (isValid(m.content.image_logo) AND (m.content.image_logo.count() > 0))
            logoImage = GetImageURL(m.content.image_logo, "medium")
            if isNonEmptyString(logoImage)
                pLogo = createObject("roSGNode", "Poster")
                pLogo.id = "pLogo"
                pLogo.width = 320
                pLogo.loadWidth = 320
                pLogo.height = 160
                pLogo.loadHeight = 160
                pLogo.loadDisplayMode = "scaleTozoom"
                pLogo.uri = logoImage
                m.lgDetails.appendChild(pLogo)
                isLogo = true
            end if
        end if
        if (isValid(m.content.title) AND (not isNullOrEmpty(m.content.title)) AND isLogo = false)
            lTitle = createObject("roSGNode", "Label")
            lTitle.id = "lTitle"
            lTitle.width = 800
            lTitle.lineSpacing = -3
            lTitle.wrap = true
            lTitle.maxLines = 2
            lTitle.font = m.fonts.poppinsBold32
            lTitle.color = m.theme.white
            lTitle.text = m.content.title
            m.lgDetails.appendChild(lTitle)
        end if

        if isValid(m.content.description) AND not isNullOrEmpty(m.content.description)
            lDescription = createObject("roSGNode", "Label")
            lDescription.id = "lDescription"
            lDescription.width = 800
            lDescription.lineSpacing = -3
            lDescription.wrap = true
            lDescription.maxLines = 4
            lDescription.font = m.fonts.poppinsMedium24
            lDescription.color = m.theme.white
            if m.content.description_short <> invalid AND m.content.description_short <> ""
                lDescription.text = m.content.description_short
            else if m.content.description <> invalid
                lDescription.text = m.content.description
            end if
            m.lgDetails.appendChild(lDescription)
        end if
        ' shortMetaDataBoundingRect = m.lgDetails.boundingRect()
        ' m.lgDetails.translation = [shortMetaDataBoundingRect.x, shortMetaDataBoundingRect.y + shortMetaDataBoundingRect.height + 20]
        if m.top.showPlayButton
            createMetadataButtons()
        end if
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

sub createMetadataButtons()
    ' m.bWatchNow = CreateObject("roSGNode", "CustomButton")
    ' m.bWatchNow.id = "bWatchNow"
    ' buttonFields = {
    '     buttonWidth: 150
    '     buttonHeight: 70
    '     backGroundImage: "pkg:/images/focus/filled_r6.9.png" 
    '     buttonText: "Play"
    '     focusTextColor: m.theme.black
    '     unfocusTextColor: m.theme.black
    '     backgroundColor: m.theme.white
    '     focusBackgroundColor: m.theme.white
    '     focusBorderImage: m.theme.filledBackGroundImage
    '     isFilledBgOnFocus: true
    '     fontSize: "poppinsMedium26"
    '     posterImage: "pkg:/images/focus/btnplay.png"
    '     addColorOnImage: true
    '     padding: 20
    '     posterImageSize: 35
    '     margin: 10
    ' }
    ' m.bWatchNow.update(buttonFields)
    ' m.lgDetails.appendChild(m.bWatchNow)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    result = false
    print "ShortDetailsView : onKeyEvent : key = " key " press = " press
    if press
        if key = "OK"
        else if key = "down"
        end if
    end if
    return result
end function
