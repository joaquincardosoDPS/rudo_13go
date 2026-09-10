sub init()
    setLocals()
    setControls()
    setUpColor()
    setUpFonts()
    setObservers()
    Initialize()
end sub

sub setLocals()
    m.theme = m.global.appTheme
    m.fonts = m.global.Fonts
    m.scene = m.top.getScene()
    m.items = []
    m.isImagesHidden = false
    m.activeIndex = 0
    m.currentItem = invalid
end sub

sub setControls()
    m.pImage = m.top.findNode("pImage")
    m.mgImageMask = m.top.findNode("mgImageMask")
    m.overlayImage = m.top.findNode("overlayImage")
    m.pFadeBottom = m.top.findNode("pFadeBottom")
    m.pFadeLeft = m.top.findNode("pFadeLeft")
    m.pLogo = m.top.findNode("pLogo")
    m.liveLabel = m.top.findNode("liveLabel")
    m.epigrafeLabel = m.top.findNode("epigrafeLabel")
    m.title = m.top.findNode("titleLabel")
    m.lgDetails = m.top.findNode("lgDetails")
    m.desc = m.top.findNode("descLabel")
    m.bWatchNow = m.top.findNode("bWatchNow")
    m.pImageGroup = m.top.findNode("pImageGroup")
end sub

sub setScrollStateImageVisibility(hidden as boolean)
    m.pImageGroup.visible = not hidden
end sub

sub setUpFonts()
    m.title.font = m.fonts.dmSansBold32
    m.desc.font = m.fonts.dmSansMedium24
    m.liveLabel.font = m.fonts.dmSansBold20
    m.epigrafeLabel.font = m.fonts.dmSansBold23
end sub

sub setUpColor()
    m.title.color = m.theme.white
    m.desc.color = m.theme.white
    m.liveLabel.color = m.theme.white
    m.epigrafeLabel.color = m.theme.focPrimary
    ' m.overlayImage.blendColor = m.theme.black
end sub

sub setObservers()
    m.top.observeField("items", "onItemsSet")
    m.top.observeField("focusedItem", "onFocusedItemSet")
    m.top.observeField("visible", "onVisibilityChanged")
    m.pImage.observeField("loadStatus", "onLoadStatusChanged")
    m.pLogo.observeField("loadStatus", "onLogoImageLoadStatusChanged")
    m.top.observeField("focusedChild", "onFocusedChild")
end sub

sub Initialize()
end sub

sub onLogoImageLoadStatusChanged(event as dynamic)
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

sub onLoadStatusChanged(event as object)
    status = event.GetData()
    if status = "ready" OR status = "failed"
        m.pImageGroup.visible = true
    end if
end sub

sub setupWatchNowButton()
    if m.bWatchNow = invalid then return
    buttonFields = {
        buttonWidth: 220,
        buttonHeight: 60,
        buttonText: "Ver ahora",
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.white
        backgroundColor: m.theme.clrSecondaryText
        focusBackgroundColor: m.theme.focPrimary
        backGroundImage: "pkg:/images/focus/R5T3_35px_outborder_nopadding.9.png"
        focusBorderImage: "pkg:/images/focus/R5T3_35px_outborder_nopadding.9.png"
        isFilledBgOnFocus: false
        fontSize: "dmSansMedium26"
        posterImage: "pkg:/images/focus/btnplay.png"
        addColorOnImage: true
        padding: 20
        posterImageSize: 25
        margin: 10
    }
    m.bWatchNow.update(buttonFields)
end sub

sub onItemsSet()
    m.items = m.top.items
    if m.items = invalid then m.items = []
    m.activeIndex = 0
    if m.items.count() = 0
        clearSlider()
        return
    end if
    m.currentItem = m.items[m.activeIndex]
    setupPosters()
    updateMeta()
    if m.top.variant <> "compact" then m.bWatchNow.visible = true
end sub

sub onFocusedItemSet()
    item = m.top.focusedItem
    if item = invalid then return
    m.currentItem = item
    setupPosters()
    updateMeta()
end sub

sub clearSlider()
    m.pImage.uri = ""
    setOverlayVisibility(false)
    m.pLogo.uri = ""
    m.title.text = ""
    m.desc.text = ""
end sub

sub setupPosters()
    w = m.top.width
    h = m.top.height
    if w <= 0 then w = 1920
    if h <= 0 then h = 1080
    if m.top.variant = "compact"
        imgWidth = w * 0.72
        imgHeight = w * 0.41
        imgX = w - imgWidth
        m.pImage.loadDisplayMode = "scaleToZoom"
        setMaskBox(imgWidth, imgHeight, imgX, 0)
        setPosterSize(m.pImage, imgWidth, imgHeight)
        m.pImage.translation = [0, 0]
        m.lgDetails.translation = [100, 220]
        m.title.width = w * 0.32
        m.desc.width = w * 0.32
        setOverlayVisibility(false)
        setPosterSize(m.pFadeBottom, imgWidth, imgHeight * 0.5)
        m.pFadeBottom.translation = [imgX, imgHeight * 0.5]
        m.pFadeBottom.visible = true
        setPosterSize(m.pFadeLeft, imgWidth * 0.6, imgHeight)
        m.pFadeLeft.translation = [imgX, 0]
        m.pFadeLeft.uri = "pkg:/images/overlay/hero_fade_left.png"
        m.pFadeLeft.visible = true
    else
        m.pImage.loadDisplayMode = "scaleToZoom"
        setMaskBox(w, h, 0, 0)
        setPosterSize(m.pImage, w, h)
        m.pImage.translation = [0, 0]
        setPosterSize(m.overlayImage, w, h)
        m.lgDetails.translation = [100, 163]
        m.title.width = 900
        m.desc.width = 900
        setOverlayVisibility(true)
        m.pFadeBottom.visible = false
        m.pFadeLeft.visible = false
    end if
    m.pImage.uri = getSliderImage(m.currentItem)
end sub

sub setPosterSize(node as object, w as dynamic, h as dynamic)
    if node = invalid then return
    node.width = w
    node.height = h
    node.loadWidth = w
    node.loadHeight = h
end sub

sub setMaskBox(w as float, h as float, x as float, y as float)
    if m.mgImageMask = invalid then return
    m.mgImageMask.maskSize = [w, h]
    m.mgImageMask.translation = [x, y]
end sub

function getSliderImage(item as object) as string
    if item = invalid then return ""
    imageURL = ""
    imageType = "big"
    if m.global.designresolution = "720p" then imageType = "medium"
    if item.image_slider <> invalid
        imageURL = GetImageURL(item.image_slider, imageType)
    end if
    if imageURL = "" AND item.image_land <> invalid
        imageURL = GetImageURL(item.image_land, imageType)
    end if
    if imageURL = "" AND item.image_background <> invalid
        imageURL = GetImageURL(item.image_background, imageType)
    end if
    return imageURL
end function

sub updateMeta()
    item = m.currentItem
    if item = invalid then return
    if m.top.variant <> "compact"
        if m.buttonStyled <> true
            setupWatchNowButton()
            m.buttonStyled = true
        end if
        SetFocus(m.bWatchNow)
    end if
    m.pLogo.uri = ""
    m.title.text = ""
    m.desc.text = ""
    m.liveLabel.text = ""
    m.liveLabel.visible = false
    m.epigrafeLabel.text = ""
    m.epigrafeLabel.visible = false
    if isValid(item.llamado) AND isNonEmptyString(item.llamado)
        m.liveLabel.text = UCase(item.llamado)
        m.liveLabel.visible = true
    end if
    if isValid(item.epigrafe) AND isNonEmptyString(item.epigrafe)
        m.epigrafeLabel.text = item.epigrafe
        m.epigrafeLabel.visible = true
    end if
    if item.image_logo <> invalid
        m.lgDetails.itemSpacings = "[10,10,10,-60,20,20]"
        m.pLogo.uri = GetImageURL(item.image_logo, "medium")
    end if
    if item.title <> invalid AND m.pLogo.uri = ""
        m.lgDetails.itemSpacings = "[0,10,10,20,20,20]"
        m.title.text = item.title
    end if
    if item.description_short <> invalid AND item.description_short <> ""
        m.desc.text = item.description_short
    else if item.description <> invalid
        m.desc.text = item.description
    end if
end sub

sub onFocusedChild()
    if m.top.hasFocus() AND m.top.variant <> "compact" AND m.bWatchNow <> invalid then setFocus(m.bWatchNow)
end sub

sub setFocusState(focused as boolean)
    if focused AND m.top.variant <> "compact" AND m.bWatchNow <> invalid then setFocus(m.bWatchNow)
end sub

sub setOverlayVisibility(shouldShow as boolean)
    if m.overlayImage = invalid then return
    if shouldShow
        m.overlayImage.opacity = 1.0
    else
        m.overlayImage.opacity = 0.0
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false
    sliderHasFocus = false
    if (m.top.hasFocus() OR m.top.isInFocusChain()) then sliderHasFocus = true
    if sliderHasFocus = false then return false
    if key = "OK"
        if isValid(m.bWatchNow) AND m.bWatchNow.hasFocus()
            item = m.currentItem
            if item <> invalid
                itemContent = CreateObject("roSGNode", "ProgramItemNode")
                itemContent.setFields(item)
                itemSelected = {
                    "itemData": itemContent
                    "sliderId": "heroSlider"
                }
                m.scene.callFunc("showDetailPage", itemSelected, false)
            end if
        end if
    else if key = "right"
        if m.items.count() > 1 AND m.activeIndex < m.items.count() - 1
            m.activeIndex = m.activeIndex + 1
            m.currentItem = m.items[m.activeIndex]
            setupPosters()
            updateMeta()
            return true
        end if
        return false
    else if key = "left"
        ' En el primer ítem, "izquierda" sale al sidebar (como la web).
        if m.items.count() > 1 AND m.activeIndex > 0
            m.activeIndex = m.activeIndex - 1
            m.currentItem = m.items[m.activeIndex]
            setupPosters()
            updateMeta()
            return true
        end if
        return false
    end if
    return false
end function
