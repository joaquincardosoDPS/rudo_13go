sub init()
    m.rBg = m.top.findNode("rBg")
    m.pCornerTL = m.top.findNode("pCornerTL")
    m.pCornerTR = m.top.findNode("pCornerTR")
    m.pCornerBL = m.top.findNode("pCornerBL")
    m.pCornerBR = m.top.findNode("pCornerBR")
    m.lTitle = m.top.findNode("lTitle")
    m.lTime = m.top.findNode("lTime")
    m.pLive = m.top.findNode("pLive")
    m.pFocus = m.top.findNode("pFocus")
    if isValid(m.global) AND isValid(m.global.appTheme)
        m.pFocus.blendColor = m.global.appTheme.focPrimary
    end if
    if isValid(m.global) AND isValid(m.global.Fonts)
        m.lTitle.font = m.global.Fonts.dmSansMedium23
        m.lTime.font = m.global.Fonts.dmSansMedium14
    end if
    onResize()
    onTitleChanged()
    onContentChanged()
    onFocusChanged()
end sub

sub onResize()
    w = m.top.itemWidth
    h = m.top.itemHeight
    if w <= 0 then w = 300
    if h <= 0 then h = 117
    m.rBg.width = w
    m.rBg.height = h
    m.pFocus.width = w
    m.pFocus.height = h
    m.pCornerTL.translation = [0, 0]
    m.pCornerTR.translation = [w - 10, 0]
    m.pCornerBL.translation = [0, h - 10]
    m.pCornerBR.translation = [w - 10, h - 10]
    m.lTitle.width = w - 40
    m.lTitle.height = h
    m.lTitle.translation = [20, 0]
    m.lTime.width = w - 30
    m.lTime.height = 24
    m.lTime.translation = [0, 8]
    m.pLive.translation = [w - 26, 10]
end sub

sub onTitleChanged()
    m.lTitle.text = m.top.title
    if m.top.isFirstRowItem
        m.lTitle.color = "#FFFFFF"
    else
        m.lTitle.color = "#8A8A8A"
    end if
    ' Redondeo solo en los extremos de la fila (la web usa radius en first/last)
    m.pCornerTL.visible = m.top.isFirstRowItem
    m.pCornerBL.visible = m.top.isFirstRowItem
    m.pCornerTR.visible = m.top.isLastRowItem
    m.pCornerBR.visible = m.top.isLastRowItem
end sub

sub onContentChanged()
    isLive = m.top.isLive
    timeText = m.top.timeText
    m.pLive.visible = isLive
    m.lTime.visible = (not isLive) AND isNonEmptyString(timeText)
    m.lTime.text = timeText
    m.lTime.color = "#8A8A8A"
end sub

sub onFocusChanged()
    m.pFocus.visible = m.top.itemHasFocus
end sub
