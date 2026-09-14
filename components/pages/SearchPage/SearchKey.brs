sub init()
    m.rBg = m.top.findNode("rBg")
    m.lLabel = m.top.findNode("lLabel")
    m.pIcon = m.top.findNode("pIcon")
    if isValid(m.global) AND isValid(m.global.Fonts)
        m.lLabel.font = m.global.Fonts.dmSansMedium23
    end if
    onSizeChanged()
    onKeyCharChanged()
    applyFocus(false)
end sub

sub onSizeChanged()
    w = m.top.keyWidth
    h = m.top.keyHeight
    if w <= 0 then w = 54
    if h <= 0 then h = 60
    m.rBg.width = w
    m.rBg.height = h
    m.lLabel.width = w
    m.lLabel.height = h
    m.pIcon.translation = [Int((w - 34) / 2), Int((h - 24) / 2)]
end sub

sub onKeyCharChanged()
    char = m.top.keyChar
    if char = "DEL"
        m.lLabel.visible = false
        m.pIcon.visible = true
    else if char = "SPACE"
        m.lLabel.visible = true
        m.pIcon.visible = false
        m.lLabel.text = "Espacio"
    else
        m.lLabel.visible = true
        m.pIcon.visible = false
        m.lLabel.text = char
    end if
end sub

sub onFocusChanged()
    applyFocus(m.top.itemHasFocus)
end sub

sub applyFocus(focused as boolean)
    if focused
        m.rBg.color = "#FFFFFF"
        m.lLabel.color = "#000000"
    else
        m.rBg.color = "#101114"
        m.lLabel.color = "#DDDDDD"
    end if
    m.pIcon.blendColor = m.lLabel.color
end sub
