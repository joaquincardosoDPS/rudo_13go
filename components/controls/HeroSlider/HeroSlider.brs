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
end sub

sub setControls()
    m.pImage = m.top.findNode("pImage")
    m.overlayImage = m.top.findNode("overlayImage")
    m.pLogo = m.top.findNode("pLogo")
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
    m.title.font = m.fonts.poppinsBold32 
    m.desc.font = m.fonts.poppinsMedium24 
end sub

sub setUpColor()
    m.title.color = m.theme.white
    m.desc.color = m.theme.white
    ' m.overlayImage.blendColor = m.theme.black
end sub

sub setObservers()
    m.top.observeField("items", "onItemsSet")
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
        fontSize: "poppinsMedium26"
        posterImage: "pkg:/images/focus/btnplay.png"
        addColorOnImage: true
        padding: 20
        posterImageSize: 35
        margin: 10
    }
    m.bWatchNow.update(buttonFields)
end sub

sub onItemsSet()
    m.items = m.top.items
    if m.items = invalid then m.items = []
    if m.items.count() = 0
        clearSlider()
        return
    end if
    setupPosters()
    updateMeta()
    m.bWatchNow.visible = true
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
    setPosterSize(m.pImage, w, h)
    setPosterSize(m.overlayImage, w, h)
    m.pImage.uri = getSliderImage(m.items[0])
    setOverlayVisibility(true)
end sub

sub setPosterSize(node as object, w as dynamic, h as dynamic)
    if node = invalid then return
    node.width = w
    node.height = h
    node.loadWidth = w
    node.loadHeight = h
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
    if m.items = invalid OR m.items.count() = 0 then return
    item = m.items[0]
    if item = invalid then return
    setupWatchNowButton()
    SetFocus(m.bWatchNow)
    m.pLogo.uri = ""
    m.title.text = ""
    m.desc.text = ""
    if item.image_logo <> invalid
        m.lgDetails.itemSpacings = "[20,-60,20,20]"
        m.pLogo.uri = GetImageURL(item.image_logo, "medium")
    end if
    if item.title <> invalid AND m.pLogo.uri = ""
        m.lgDetails.itemSpacings = "[0,20,20,20]"
        m.title.text = item.title
    end if
    if item.description_short <> invalid AND item.description_short <> ""
        m.desc.text = item.description_short
    else if item.description <> invalid
        m.desc.text = item.description
    end if
end sub

sub onFocusedChild()
    if m.top.hasFocus() AND m.bWatchNow <> invalid then setFocus(m.bWatchNow)
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
            item = m.items[0]
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
        return true
    else if key = "left"
        return true
    end if
    return false
end function
