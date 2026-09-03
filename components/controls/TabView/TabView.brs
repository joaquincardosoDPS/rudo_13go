sub init()
    setLocals()
    setControls()
    setObservers()
    setupColor()
    setupFonts()
end sub

sub setLocals()
    m.theme = m.global.appTheme
    m.fonts = m.global.Fonts
    m.appConfig = m.global.appConfig
    m.scene = m.top.getScene()
end sub

sub setControls()
    m.lHiddenTitle = m.top.findNode("lHiddenTitle")
end sub

sub setObservers()
    m.top.observeField("focusedChild", "onFocusedChild")
end sub

sub setupFonts()
    m.lHiddenTitle.font = m.fonts.poppinsMedium26
end sub

sub setupColor()
    m.lHiddenTitle.color = m.theme.white
end sub

sub onFocusedChild()
    if m.top.hasFocus() AND isValid(m.tabList)
        setFocus(m.tabList)
    end if
end sub

function createRowList() as dynamic
    tabList = CreateObject("roSGNode", "RowList")
    tabList.id = "tabs"
    tabList.itemComponentName = "TabItem"
    tabList.numRows = "1"
    tabList.itemSize = "[1720, 50]"
    tabList.rowHeights = "[50]"
    tabList.variableWidthItems = "[true]"
    tabList.rowItemSpacing = "[[40,0]]"
    tabList.rowFocusAnimationStyle = "floatingFocus"
    tabList.translation = "[0, 0]"
    tabList.drawFocusFeedback = "false"
    tabList.observeField("rowItemSelected", "onRowItemSelected")
    tabList.observeField("rowItemFocused", "onRowItemFocused")
    return tabList
end function

sub createTabList(tabData as dynamic)
    m.rowItemSize = []
    if tabData <> invalid AND tabData.count() > 0
        mainNode = CreateObject("roSGNode", "ContentNode")
        contentType = "Tab"
        buttons = mainNode.CreateChild("ContentNode")
        m.tabList = createRowList()
        firstItem = true
        for each item in tabData
            m.lHiddenTitle.text = ""
            isSelected = false
            if (firstItem = true)
                firstItem = false
                isSelected = true
            end if
            if m.top.isSeasonTab
                m.lHiddenTitle.text = "Temporada " + item.toStr()
                width = AddSizeFields()
                buttonObject = {
                    "title": "Temporada " + item.toStr()
                    "id": item.toStr()
                    "width": width
                    "underlineHeight": 4
                    "titleHeight": 36
                    "contentType": "Season"
                    "isSelected": isSelected
                    "key": ""
                    "max_temp": ""
                    "all_temp": []
                }
                menu = buttons.CreateChild("TabItemContent")
                menu.addField("FHDItemWidth", "float", false)
                menu.FHDItemWidth = m.lHiddenTitle.BoundingRect().width
                menu.update(buttonObject)
            else
                itemLabel = getValueFromProps(item, "name", "")
                m.lHiddenTitle.text = itemLabel
                width = AddSizeFields()
                buttonObject = {
                    "title": itemLabel
                    "id": item.id
                    "width": width
                    "underlineHeight": 4
                    "titleHeight": 36
                    "contentType": contentType
                    "isSelected": isSelected
                    "key": item.key
                    "max_temp": item.max_temp.toStr()
                    "all_temp": item.all_temp
                }
                menu = buttons.CreateChild("TabItemContent")
                menu.addField("FHDItemWidth", "float", false)
                menu.FHDItemWidth = m.lHiddenTitle.BoundingRect().width
                menu.update(buttonObject)
            end if
        end for
        m.tabList.rowItemSize = m.rowItemSize
        m.tabList.content = mainNode
        m.tabList.visible = true
        m.top.appendChild(m.tabList)
    else
        if isValid(m.tabList) then m.tabList.visible = false
    end if
end sub

function AddSizeFields() as dynamic
    width = m.lHiddenTitle.BoundingRect().width
    m.rowItemSize.push([width, 50])
    return width
end function

sub OnInitSelectTab(event as dynamic)
    if event.getData()
        if isValid(m.tabList) then m.tabList.rowItemSelected = [0, 0]
        m.top.initSelect = false
    end if
end sub

sub onContentChanged(event as dynamic)
    tabData = event.getData()
    createTabList(tabData)
    if isValid(m.top.ItemSelected) AND isValid(m.tabList) AND m.top.ItemSelected >= 0 AND isNonEmptyString(m.scene.deepLinkingMediaType) AND isNonEmptyString(m.scene.deepLinkingContentId)
        m.tabList.rowItemSelected = [0, m.top.ItemSelected]
    end if
end sub

sub onRowItemFocused(event as dynamic)
    index = event.getData()
    print "onRowItemFocused index >>>>>>>>> : " index
end sub

sub onRowItemSelected(event as dynamic)
    index = event.getData()
    selectRowIndex = index[0]
    selectColIndex = index[1]
    if isValid(selectColIndex) AND isValid(m.tabList) AND isValid(m.tabList.content) AND isValid(m.tabList.content.getChild(0))
        childNode = m.tabList.content.getChild(selectRowIndex).getChild(selectColIndex)
        if isValid(childNode)
            m.top.updateContent = childNode.getFields()
            updateselectedOptionData(childNode.id)
        end if
    end if
end sub

sub updateselectedOptionData(tabId as string)
    if isValid(m.tabList) AND isValid(m.tabList.content) AND isValid(m.tabList.content.getChild(0))
        for index = 0 to m.tabList.content.getChild(0).getChildCount() - 1
            child = m.tabList.content.getChild(0).getChild(index)
            if isValid(child)
                if child.id = tabId
                    child.isselected = true
                else
                    child.isselected = false
                end if
            end if
        end for
    end if
end sub

sub clearTabView()
    if(m.tabList <> invalid AND m.tabList.content <> invalid AND m.tabList.content.GetChildCount() > 0)
        for i = 0 to m.tabList.content.GetChildCount() - 1
            childRow = m.tabList.content.getChild(i)
            childRow.RemoveChildrenIndex(childRow.GetChildCount(), 0)
        end for
        m.tabList.content.RemoveChildrenIndex(m.tabList.content.GetChildCount(), 0)
        m.tabList.content = invalid
    end if
end sub