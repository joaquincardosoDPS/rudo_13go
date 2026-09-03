sub init()
    setControls()
    setLocals()
    setObservers()
    setupColor()
    setupFonts()
end sub

sub setLocals()
    m.theme = m.global.appTheme
    m.fonts = m.global.Fonts
end sub

sub setControls()
    m.lTitle = m.top.findNode("lTitle")
    m.focusLine = m.top.findNode("focusLine")
    m.scene = m.top.GetScene()
end sub

sub setObservers()
end sub

sub setupColor()
    m.lTitle.color = m.theme.clrSecondaryText
    m.focusLine.color = m.theme.clrSecondaryText
end sub

sub setupFonts()
    m.lTitle.font = m.fonts.poppinsMedium26
end sub

sub onContentChange()
    itemContent = m.top.itemContent
    m.lTitle.text = itemContent.title
    m.lTitle.update({
        "width": itemContent.width
        "height": itemContent.titleHeight
    })
    m.focusLine.update({
        "width": itemContent.width
        "height": itemContent.underlineHeight
    })
end sub

sub changeFocus(focusPercent)
    hasActiveState = false
    if isValid(m.top.itemContent) AND isValid(m.top.itemContent.isSelected)
        hasActiveState = m.top.itemContent.isSelected
    end if
    isFocused = (focusPercent > 0.5)
    if hasActiveState
        m.lTitle.color = m.theme.focPrimary
    else
        m.lTitle.color = m.theme.white
    end if
    if hasActiveState OR isFocused
        m.focusLine.opacity = 1
        m.lTitle.opacity = 1
    else
        m.lTitle.opacity = 0.5
        m.focusLine.opacity = 0
    end if
    if isFocused
        m.focusLine.color = m.theme.focPrimary
    else
        m.focusLine.color = m.theme.white
    end if
end sub

sub FocusPercent_Changed(event as dynamic)
    value = event.GetData()
    if (m.top.rowListHasFocus AND m.top.RowHasFocus)
        changeFocus(value)
    else
        changeFocus(0)
    end if
end sub

sub ItemHasFocus_Changed(event as dynamic)
    value = event.GetData()
    if (value)
        changeFocus(1)
    end if
end sub

sub RowHasFocus_Changed()
    if (m.top.RowHasFocus AND m.top.ItemHasFocus)
        changeFocus(1)
    else
        changeFocus(0)
    end if
end sub

sub ParentHasFocus_Changed()
    if ((m.top.RowListHasFocus AND m.top.RowHasFocus) AND (m.top.ItemHasFocus OR m.top.FocusPercent = 1))
        changeFocus(1)
    else
        changeFocus(0)
    end if
end sub