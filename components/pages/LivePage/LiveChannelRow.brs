sub init()
    m.pCircleBg = m.top.findNode("pCircleBg")
    m.pLogo = m.top.findNode("pLogo")
    m.pRing = m.top.findNode("pRing")
    m.pLockOverlay = m.top.findNode("pLockOverlay")
    m.pLock = m.top.findNode("pLock")
    m.gItems = m.top.findNode("gItems")
    m.itemNodes = []
    onRingColorChanged()
    onLayoutChanged()
end sub

sub onRingColorChanged()
    if isNonEmptyString(m.top.ringColor)
        m.pRing.blendColor = m.top.ringColor
    else
        m.pRing.blendColor = "#FA6428"
    end if
end sub

sub onContentChanged()
    m.pLockOverlay.visible = m.top.blocked
    m.pLock.visible = m.top.blocked
end sub

sub onLayoutChanged()
    if isNonEmptyString(m.top.logo)
        m.pLogo.uri = m.top.logo
    end if
    rebuildItems()
end sub

sub onProgramsChanged()
    rebuildItems()
end sub

sub rebuildItems()
    gItems = m.top.findNode("gItems")
    gItems.removeChildrenIndex(gItems.getChildCount(), 0)
    m.itemNodes = []
    programs = m.top.programs
    if not isValid(programs) then programs = []
    n = programs.count()
    if n <= 0
        ' Canal sin programación: un solo item con el nombre del canal (como la web)
        programs = [{ "title": m.top.channelName, "timeText": "", "isLive": true }]
        n = 1
    end if
    logoW = 117
    colGap = 28
    itemGap = 5
    rowW = m.top.rowWidth
    if rowW <= 0 then rowW = 1721
    rowH = m.top.rowHeight
    if rowH <= 0 then rowH = 117
    avail = rowW - logoW - colGap
    itemW = (avail - (n - 1) * itemGap) / n
    for i = 0 to n - 1
        p = programs[i]
        item = createObject("roSGNode", "LiveProgramItem")
        item.itemWidth = itemW
        item.itemHeight = rowH
        item.title = getValueFromProps(p, "title", "")
        item.timeText = getValueFromProps(p, "timeText", "")
        item.isLive = getValueFromProps(p, "isLive", false)
        item.isFirstRowItem = (i = 0)
        item.isLastRowItem = (i = n - 1)
        item.itemHasFocus = false
        item.translation = [logoW + colGap + i * (itemW + itemGap), 0]
        gItems.appendChild(item)
        m.itemNodes.push(item)
    end for
end sub

sub onFocusChanged()
    setFocusedItem(m.top.focusedItemIndex)
end sub

sub setFocusedItem(index as integer)
    for i = 0 to m.itemNodes.count() - 1
        m.itemNodes[i].itemHasFocus = (i = index)
    end for
end sub
