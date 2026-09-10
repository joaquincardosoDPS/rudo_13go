sub init()
    m.pBg = m.top.findNode("pBg")
    m.pLogo = m.top.findNode("pLogo")
    m.pDim = m.top.findNode("pDim")
    m.pBorderThin = m.top.findNode("pBorderThin")
    m.pBorderThick = m.top.findNode("pBorderThick")
    setFocused(false)
end sub

sub onImageChanged()
    m.pLogo.uri = m.top.imageUri
end sub

sub onBgColorChanged()
    if isNonEmptyString(m.top.bgColor)
        m.pBg.blendColor = m.top.bgColor
    end if
end sub

sub onBorderColorChanged()
    if isNonEmptyString(m.top.borderColor)
        m.pBorderThin.blendColor = m.top.borderColor
        m.pBorderThick.blendColor = m.top.borderColor
    end if
end sub

sub onFocusChanged()
    setFocused(m.top.itemHasFocus)
end sub

sub setFocused(focused as boolean)
    m.pBorderThin.visible = not focused
    m.pBorderThick.visible = focused
    if focused
        m.pDim.opacity = 0.0
    else
        m.pDim.opacity = 0.55
    end if
end sub
