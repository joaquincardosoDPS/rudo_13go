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
    createDynamicCardsRowList()
end sub

sub onFocusedChild()
    if (m.top.hasFocus() AND isValid(m.rowList))
        m.rowList.vertFocusAnimationStyle = "fixedFocus"
        setFocus(m.rowList)
    end if
end sub

function AddSizeFields(childNode as dynamic)
    if isValid(childNode) AND isValid(childNode.image_orientation)
        isCatEvent = false
        if isValid(childNode.format) AND childNode.format = "event" AND isValid(childNode.liveCategory) AND childNode.liveCategory = true
            isCatEvent = true
        end if
        if childNode.image_orientation = "portrait"
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
    m.rowList.vertFocusAnimationStyle = "floatingFocus"
    m.rowList.rowFocusAnimationStyle = "floatingFocus"
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
    else
        m.rowList.rowLabelOffset = [[100, 15]]
        m.rowList.focusxOffset = [100]
        m.rowList.showRowLabel = [true]
        m.rowList.itemSize = [320, 180]
    end if
    m.rowList.numRows = 3
    m.rowList.drawFocusFeedbackOnTop = "true"
    m.rowList.drawFocusFeedback = "true"
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
