sub init()
    setLocals()
    setControls()
    setUpFonts()
    setUpColor()
    setObservers()
end sub

sub setLocals()
    m.theme = m.global.appTheme
    m.fonts = m.global.Fonts
    m.scene = m.top.getScene()
    m.items = []
    m.activeIndex = 0
    m.currentItem = invalid
    m.buttonStyled = false
    m.sideMargin = 106
    m.leftInset = 100
    m.topInset = 20
    m.cw = 0
    m.cardHeight = 0
    m.imgBoxW = 0
    m.imgBoxH = 0
    m.slidePhase = 0
    m.pendingIndex = 0
    m.slideDirection = 1
end sub

sub setControls()
    m.rCardBg = m.top.findNode("rCardBg")
    m.pImageGroup = m.top.findNode("pImageGroup")
    m.mgImageMask = m.top.findNode("mgImageMask")
    m.pImage = m.top.findNode("pImage")
    m.pFadeLeft = m.top.findNode("pFadeLeft")
    m.pFocusBorder = m.top.findNode("pFocusBorder")
    m.pTitleBg = m.top.findNode("pTitleBg")
    m.lSectionTitle = m.top.findNode("lSectionTitle")
    m.lgDetails = m.top.findNode("lgDetails")
    m.title = m.top.findNode("titleLabel")
    m.desc = m.top.findNode("descLabel")
    m.bWatchNow = m.top.findNode("bWatchNow")
    m.gSlideClip = m.top.findNode("gSlideClip")
    m.gSlide = m.top.findNode("gSlide")
    m.slideAnim = m.top.findNode("slideAnim")
    m.slideInterp = m.top.findNode("slideInterp")
end sub

sub setUpFonts()
    m.title.font = m.fonts.dmSansBold32
    m.desc.font = m.fonts.dmSansMedium24
    m.lSectionTitle.font = m.fonts.dmSansBold32
end sub

sub setUpColor()
    m.title.color = m.theme.white
    m.desc.color = m.theme.white
    m.lSectionTitle.color = m.theme.white
    m.pFocusBorder.blendColor = m.theme.focPrimary
end sub

sub setObservers()
    m.top.observeField("items", "onItemsSet")
    m.top.observeField("sectionTitle", "onSectionTitleSet")
    m.pImage.observeField("loadStatus", "onLoadStatusChanged")
    m.slideAnim.observeField("state", "onSlideAnimState")
    m.top.observeField("focusedChild", "onFocusedChild")
end sub

sub onSectionTitleSet()
    title = m.top.sectionTitle
    m.lSectionTitle.text = ""
    m.pTitleBg.visible = false
    if isValid(title) AND isNonEmptyString(title)
        m.lSectionTitle.text = title
        m.pTitleBg.visible = true
    end if
end sub

sub onItemsSet()
    m.items = m.top.items
    if m.items = invalid then m.items = []
    m.activeIndex = 0
    if m.items.count() = 0 then return
    m.currentItem = m.items[m.activeIndex]
    setupLayout()
    updateMeta()
    m.bWatchNow.visible = true
    finalizeLayout()
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
    ' El mask solo cubre maskSize; lo que sobresale toma su ultima fila
    ' (opaca) y se ve. Un clippingRect duro lo corta.
    m.mgImageMask.clippingRect = [0, 0, w, h]
end sub

sub setupLayout()
    w = m.top.width
    if w <= 0 then w = 1920
    cw = w - (m.sideMargin * 2) - m.leftInset
    m.cardHeight = cw * 0.34
    cardHeight = m.cardHeight
    imgWidth = cw * 0.5
    imgX = cw - imgWidth
    m.cw = cw
    m.gSlideClip.clippingRect = [m.leftInset, m.topInset, cw, cardHeight]
    setPosterSize(m.rCardBg, cw, cardHeight)
    m.rCardBg.translation = [m.leftInset, m.topInset]
    m.rCardBg.visible = true
    m.pImage.loadDisplayMode = "scaleToFit"
    setMaskBox(imgWidth, cardHeight, m.leftInset + imgX, m.topInset)
    m.imgBoxW = imgWidth
    m.imgBoxH = cardHeight
    setPosterSize(m.pImage, imgWidth, cardHeight)
    m.pImage.translation = [0, 0]
    ' +10 de colchon vertical: stretchToFit sobre un asset chico a veces deja
    ' un par de pixeles sin cubrir en el borde inferior por redondeo
    setPosterSize(m.pFadeLeft, imgWidth, cardHeight + 10)
    m.pFadeLeft.translation = [m.leftInset + imgX, m.topInset]
    m.pFadeLeft.visible = true
    m.lgDetails.translation = [m.leftInset + 115, m.topInset + 190]
    m.title.width = cw * 0.45
    m.desc.width = cw * 0.45
    m.desc.maxLines = 4
    setPosterSize(m.pTitleBg, 350, 180)
    m.pTitleBg.translation = [m.leftInset, m.topInset]
    setPosterSize(m.pFocusBorder, cw, cardHeight)
    m.pFocusBorder.translation = [m.leftInset, m.topInset]
    m.pFocusBorder.visible = m.top.isInFocusChain()
    m.pImage.uri = getSliderImage(m.currentItem)
end sub

' Alto FIJO: el card no se ajusta al texto (ver m.cardHeight en setupLayout)
sub finalizeLayout()
    cw = m.cw
    cardHeight = m.cardHeight
    m.gSlideClip.clippingRect = [m.leftInset, m.topInset, cw, cardHeight]
    imgWidth = cw * 0.5
    imgX = cw - imgWidth
    setPosterSize(m.rCardBg, cw, cardHeight)
    setMaskBox(imgWidth, cardHeight, m.leftInset + imgX, m.topInset)
    m.imgBoxW = imgWidth
    m.imgBoxH = cardHeight
    applyImageCrop()
    setPosterSize(m.pFadeLeft, imgWidth, cardHeight + 10)
    m.pFadeLeft.translation = [m.leftInset + imgX, m.topInset]
    setPosterSize(m.pFocusBorder, cw, cardHeight)
    m.top.componentHeight = m.topInset + cardHeight + 50
end sub

' Recorte tipo "object-fit: cover; object-position: top right":
' Roku no tiene control de ancla de recorte (scaleToZoom siempre ancla igual),
' asi que se calcula a mano contra el bitmap real ya cargado y se ancla
' el borde derecho de la imagen escalada con el borde derecho del recuadro.
sub applyImageCrop()
    bw = m.pImage.bitmapWidth
    bh = m.pImage.bitmapHeight
    boxW = m.imgBoxW
    boxH = m.imgBoxH
    if bw <= 0 OR bh <= 0 OR boxW <= 0 OR boxH <= 0 then return
    scale = boxW / bw
    if bh * scale < boxH then scale = boxH / bh
    scaledW = bw * scale
    scaledH = bh * scale
    setPosterSize(m.pImage, scaledW, scaledH)
    m.pImage.translation = [boxW - scaledW, 0]
end sub

sub onLoadStatusChanged(event as object)
    status = event.GetData()
    if status = "ready" OR status = "failed"
        m.pImageGroup.visible = true
    end if
    if status = "ready" then applyImageCrop()
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
    if m.buttonStyled <> true
        setupWatchNowButton()
        m.buttonStyled = true
    end if
    SetFocus(m.bWatchNow)
    m.title.text = ""
    m.desc.text = ""
    if item.title <> invalid
        m.title.text = item.title
    end if
    if item.description_short <> invalid AND item.description_short <> ""
        m.desc.text = item.description_short
    else if item.description <> invalid
        m.desc.text = item.description
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

sub onFocusedChild()
    m.pFocusBorder.visible = m.top.isInFocusChain()
    if m.top.isInFocusChain() AND m.bWatchNow <> invalid then setFocus(m.bWatchNow)
end sub

sub setFocusState(focused as boolean)
    m.pFocusBorder.visible = focused
    if focused AND m.bWatchNow <> invalid then setFocus(m.bWatchNow)
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
                    "sliderId": "monumental"
                }
                m.scene.callFunc("showDetailPage", itemSelected, false)
            end if
        end if
    else if key = "right"
        if m.slidePhase = 0 AND m.items.count() > 1
            navigateTo((m.activeIndex + 1) MOD m.items.count(), 1)
        end if
        return true
    else if key = "left"
        if m.slidePhase = 0 AND m.items.count() > 1
            navigateTo((m.activeIndex - 1 + m.items.count()) MOD m.items.count(), -1)
        end if
        return true
    end if
    return false
end function

sub navigateTo(newIndex as integer, direction as integer)
    m.pendingIndex = newIndex
    m.slideDirection = direction
    m.slidePhase = 1
    if direction > 0
        m.slideInterp.keyValue = [[0, 0], [-m.top.width, 0]]
    else
        m.slideInterp.keyValue = [[0, 0], [m.top.width, 0]]
    end if
    m.slideAnim.control = "start"
end sub

sub onSlideAnimState(event as dynamic)
    state = event.getData()
    if state <> "stopped" then return
    if m.slidePhase = 1
        ' fuera de pantalla: cambia el contenido
        m.activeIndex = m.pendingIndex
        m.currentItem = m.items[m.activeIndex]
        m.pImage.uri = getSliderImage(m.currentItem)
        updateMeta()
        finalizeLayout()
        ' entra desde el lado opuesto
        if m.slideDirection > 0
            m.gSlide.translation = [m.top.width, 0]
            m.slideInterp.keyValue = [[m.top.width, 0], [0, 0]]
        else
            m.gSlide.translation = [-m.top.width, 0]
            m.slideInterp.keyValue = [[-m.top.width, 0], [0, 0]]
        end if
        m.slidePhase = 2
        m.slideAnim.control = "start"
    else
        m.slidePhase = 0
    end if
end sub
