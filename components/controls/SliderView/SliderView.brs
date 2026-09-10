sub init()
    setLocals()
    setControls()
    setObservers()
    setFonts()
    setColors()
end sub

sub setLocals()
    m.libScene = m.top.GetScene()
    m.theme = m.global.appTheme
    m.fonts = m.global.fonts
end sub

sub setControls()
    m.gEventPage = m.top.findNode("gEventPage")
    m.pEventBackground = m.top.findNode("pEventBackground")
    m.pEvent = m.top.findNode("pEvent")
    m.lEventTitle = m.top.findNode("lEventTitle")
    m.gCircleClip = m.top.findNode("gCircleClip")
    m.gCircleTrack = m.top.findNode("gCircleTrack")
    m.circleSlideAnim = m.top.findNode("circleSlideAnim")
    m.circleSlideInterp = m.top.findNode("circleSlideInterp")
end sub

sub setObservers()
    m.top.observeField("focusedChild", "onFocusedChild")
    m.pEvent.observeField("loadStatus", "onpEventLoad")
end sub

sub onpEventLoad(event as object)
    status = event.GetData()
    if status = "ready"
        newWidth = (m.pEvent.bitmapWidth * m.pEvent.height) / m.pEvent.bitmapHeight
        m.pEvent.width = newWidth
        m.pEvent.loadWidth = newWidth
    end if
end sub

sub setFonts()
    m.lEventTitle.font = m.fonts.dmSansReg26
end sub

sub setColors()
    m.lEventTitle.color = m.theme.white
end sub

sub initialize()
    if isCircleContent()
        createCircleCarousel()
    else
        createDynamicCardsRowList()
    end if
end sub

sub onFocusedChild()
    if not m.top.hasFocus() then return
    if isCircleContent()
        applyCircleFocus()
    else if isValid(m.rowList)
        m.rowList.vertFocusAnimationStyle = "fixedFocus"
        setFocus(m.rowList)
    end if
end sub

function isCircleContent() as boolean
    if isValid(m.top.category) AND isValid(m.top.category.format) AND m.top.category.format = "circle" then return true
    if isValid(m.top.content) AND m.top.content.getChildCount() > 0
        firstRow = m.top.content.getChild(0)
        if isValid(firstRow) AND isValid(firstRow.format) AND firstRow.format = "circle" then return true
    end if
    return false
end function

' Carrusel propio para la fila de circulos: emula scrollIntoView(inline:"center")
' de la web (centra el item enfocado con tope al inicio/fin), cosa que RowList
' no puede hacer de forma suave.
sub createCircleCarousel()
    m.circleItems = []
    m.circleItemNodes = []
    m.circleFocusIndex = 0
    m.circleItemWidth = 200
    m.circleSpacing = 25
    m.circleVisibleWidth = 1814
    m.circleLeftInset = 100
    m.circleRightInset = 100
    h = m.top.componentHeight
    if h <= 0 then h = 220
    m.gCircleClip.clippingRect = [0, 0, m.circleVisibleWidth, h]
    m.gCircleTrack.removeChildrenIndex(m.gCircleTrack.getChildCount(), 0)
    if isValid(m.top.content) AND m.top.content.getChildCount() > 0
        rowNode = m.top.content.getChild(0)
        for i = 0 to rowNode.getChildCount() - 1
            m.circleItems.push(rowNode.getChild(i))
        end for
    end if
    for i = 0 to m.circleItems.count() - 1
        item = createObject("roSGNode", "CommonItemComponent")
        item.itemContent = m.circleItems[i]
        item.translation = [m.circleLeftInset + i * (m.circleItemWidth + m.circleSpacing), 0]
        item.rowListHasFocus = true
        item.rowHasFocus = true
        item.itemHasFocus = false
        item.focusPercent = 0
        m.gCircleTrack.appendChild(item)
        m.circleItemNodes.push(item)
    end for
    m.circleFocusIndex = 0
    applyCircleFocus()
end sub

sub applyCircleFocus()
    for i = 0 to m.circleItemNodes.count() - 1
        m.circleItemNodes[i].itemHasFocus = (i = m.circleFocusIndex)
        m.circleItemNodes[i].focusPercent = 0
    end for
    if m.circleItemNodes.count() > 0 then m.circleItemNodes[m.circleFocusIndex].focusPercent = 1
    animateCircleToFocused()
    emitCircleFocused()
end sub

sub animateCircleToFocused()
    if m.circleItemNodes.count() <= 0 then return
    stepSize = m.circleItemWidth + m.circleSpacing
    contentWidth = m.circleItemNodes.count() * stepSize - m.circleSpacing
    usableWidth = m.circleVisibleWidth - m.circleLeftInset - m.circleRightInset
    targetX = usableWidth / 2 - m.circleFocusIndex * stepSize - m.circleItemWidth / 2
    minX = usableWidth - contentWidth
    if minX > 0 then minX = 0
    if targetX > 0 then targetX = 0
    if targetX < minX then targetX = minX
    m.circleSlideInterp.keyValue = [[m.gCircleTrack.translation[0], 0], [targetX, 0]]
    m.circleSlideAnim.control = "start"
end sub

sub emitCircleFocused()
    if m.circleFocusIndex < 0 OR m.circleFocusIndex >= m.circleItems.count() then return
    m.top.itemFocused = {
        "itemData": m.circleItems[m.circleFocusIndex]
        "sliderId": m.top.id
        "lastSelectedNodeIndex": [0, m.circleFocusIndex]
    }
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if not isCircleContent() then return false
    if key = "left"
        if m.circleFocusIndex > 0
            m.circleFocusIndex = m.circleFocusIndex - 1
            applyCircleFocus()
        end if
        return true
    else if key = "right"
        if m.circleFocusIndex < m.circleItemNodes.count() - 1
            m.circleFocusIndex = m.circleFocusIndex + 1
            applyCircleFocus()
        end if
        return true
    else if key = "OK"
        if m.circleFocusIndex >= 0 AND m.circleFocusIndex < m.circleItems.count()
            m.top.itemSelected = {
                "itemData": m.circleItems[m.circleFocusIndex]
                "sliderId": m.top.id
                "lastSelectedNodeIndex": [0, m.circleFocusIndex]
            }
        end if
        return true
    end if
    return false
end function

function AddSizeFields(childNode as dynamic)
    if isValid(childNode) AND isValid(childNode.image_orientation)
        isCatEvent = false
        if isValid(childNode.format) AND childNode.format = "event" AND isValid(childNode.liveCategory) AND childNode.liveCategory = true
            isCatEvent = true
        end if
        if isValid(childNode.format) AND childNode.format = "circle"
            m.rowHeights.push(220)
            m.rowItemSize.push([200, 200])
            m.rowSpacings.push(70)
            m.rowItemSpacing.push([25, 100])
        else if childNode.image_orientation = "portrait"
            if isCatEvent
                m.rowHeights.push(706)
            else
                m.rowHeights.push(596)
            end if
            m.rowItemSize.push([324, 576])
            m.rowSpacings.push(70)
            m.rowItemSpacing.push([20, 100])
        else if (childNode.image_orientation = "landscape")
            m.rowHeights.push(230)
            m.rowItemSize.push([320, 180])
            m.rowSpacings.push(70)
            m.rowItemSpacing.push([40, 100])
        else
            m.rowHeights.push(230)
            m.rowItemSize.push([320, 180])
            m.rowSpacings.push(70)
            m.rowItemSpacing.push([40, 100])
        end if
    end if
end function

function isEventCategory()
    return isValid(m.top.category) AND isValid(m.top.category.format) AND m.top.category.format = "event" AND isValid(m.top.category.liveCategory) AND m.top.category.liveCategory = true AND isValid(m.top.category.image_orientation) AND m.top.category.image_orientation = "portrait"
end function

sub createDynamicCardsRowList()
    m.rowItemSize = []
    m.rowHeights = []
    m.rowItemSpacing = []
    m.rowSpacings = []

    m.rowList = createObject("roSGNode", "RowList")
    isCircleRow = false
    if isValid(m.top.category) AND isValid(m.top.category.format) AND m.top.category.format = "circle"
        isCircleRow = true
    else if isValid(m.top.content) AND m.top.content.getChildCount() > 0
        firstRow = m.top.content.getChild(0)
        if isValid(firstRow) AND isValid(firstRow.format) AND firstRow.format = "circle"
            isCircleRow = true
        end if
    end if
    m.isCircleRow = isCircleRow
    m.rowList.vertFocusAnimationStyle = "floatingFocus"
    if isCircleRow
        m.rowList.rowFocusAnimationStyle = "fixedFocus"
    else
        m.rowList.rowFocusAnimationStyle = "floatingFocus"
    end if
    m.rowList.translation = [0, 0]
    m.gEventPage.visible = false
    if isEventCategory()
        m.gEventPage.visible = true
        m.pEventBackground.uri = GetImageURL(m.top.category.image_background_category)
        m.pEvent.uri = GetImageURL(m.top.category.image_logo_category)
        m.lEventTitle.text = m.top.category.title
        m.rowList.translation = [0, 106]
        m.rowList.rowLabelOffset = [[796, 15]]
        m.rowList.itemClippingRect = "[796,0,1150,584]"
        m.rowList.focusxOffset = [796]
        m.rowList.showRowLabel = [false]
        m.rowList.itemSize = [1150, 584]
    else if isCircleRow
        m.rowList.rowLabelOffset = [[100, 15]]
        m.rowList.focusxOffset = [758]
        m.rowList.showRowLabel = [true]
        m.rowList.itemSize = [1760, 1416]
    else
        m.rowList.rowLabelOffset = [[100, 15]]
        m.rowList.focusxOffset = [100]
        m.rowList.showRowLabel = [true]
        m.rowList.itemSize = [1760, 1416]
    end if
    m.rowList.numRows = 3
    m.rowList.drawFocusFeedbackOnTop = "true"
    m.rowList.drawFocusFeedback = not isCircleRow
    if(m.global.designResolution = "720p")
        m.rowList.focusBitmapUri = "pkg:/images/focus/R5T3_35px_outborder_nopadding.9.png"
    else
        m.rowList.focusBitmapUri = "pkg:/images/focus/R8_T3_50PX_border.9.png"
    end if
    m.rowList.focusBitmapBlendColor = m.theme.focPrimary
    m.rowList.itemComponentName = "CommonItemComponent"

    m.rowList.rowLabelFont = m.fonts.dmSansBold32
    m.rowList.rowLabelColor = m.theme.white
    for i = 0 to m.top.content.getChildCount() - 1
        child = m.top.content.getChild(i)
        AddSizeFields(child)
    end for

    m.rowList.rowHeights = m.rowHeights
    m.rowList.rowItemSize = m.rowItemSize
    m.rowList.rowItemSpacing = m.rowItemSpacing
    m.rowList.rowSpacings = m.rowSpacings

    m.rowList.observeField("rowItemFocused", "onRowItemFocused")
    m.rowList.observeField("rowItemSelected", "onRowItemSelected")
    m.rowList.content = m.top.content
    if isCircleRow
        m.rowList.rowFocusAnimationStyle = "fixedFocus"
        m.rowList.drawFocusFeedback = false
    end if
    m.top.appendChild(m.rowList)
end sub

sub onRowItemFocused(event as dynamic)
    index = event.getData()
    selectItemNode = m.rowList.content.getChild(index[0]).getChild(index[1])
    m.top.itemFocused = {
        "itemData": selectItemNode
        "sliderId": m.top.id
        "lastSelectedNodeIndex": index
        "isViewMoreCard": selectItemNode.isViewMoreCard
    }
end sub

sub onRowItemSelected(event as dynamic)
    index = event.getData()
    rowNode = m.rowList.content.getChild(index[0])
    selectItemNode = rowNode.getChild(index[1])
    itemSelected = {
        "itemData": selectItemNode
        "sliderId": m.top.id
        "lastSelectedNodeIndex": index
    }
    m.top.itemSelected = itemSelected
end sub

sub updateSliderContent()
    if isValid(m.rowList) AND isValid(m.rowList.content) AND isValid(m.top.updateContent) AND m.top.updateContent.getChildCount() > 0
        m.rowList.content = m.top.updateContent
    end if
end sub
