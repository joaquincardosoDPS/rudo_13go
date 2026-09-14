sub init()
    m.pImage = m.top.findNode("pImage")
    m.pDim = m.top.findNode("pDim")
    m.pFrame = m.top.findNode("pFrame")
    m.pBorder = m.top.findNode("pBorder")
    if isValid(m.global) AND isValid(m.global.appTheme)
        m.pBorder.blendColor = m.global.appTheme.focPrimary
        m.pFrame.blendColor = m.global.appTheme.clrPrimary
    end if
    applyFocus(false)
end sub

sub onItemContentChanged()
    if isValid(m.top.itemContent) AND isValid(m.top.itemContent.image)
        m.pImage.uri = m.top.itemContent.image
    end if
end sub

sub onFocusChanged()
    refresh()
end sub

sub onFocusPercentChanged()
    refresh()
end sub

sub onGridFocusChanged()
    refresh()
end sub

sub refresh()
    focused = m.top.gridHasFocus AND (m.top.itemHasFocus OR m.top.focusPercent > 0.5)
    applyFocus(focused)
end sub

sub applyFocus(focused as boolean)
    m.pBorder.visible = focused
    if focused
        m.pDim.opacity = 0.0
    else
        m.pDim.opacity = 0.4
    end if
end sub
