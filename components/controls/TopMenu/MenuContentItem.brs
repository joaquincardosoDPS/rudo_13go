sub init()
    SetLocals()
    SetControls()
    SetupFonts()
end sub

sub SetLocals()
    m.theme = m.global.appTheme
    m.fonts = m.global.fonts
    m.focusPercent = 0
end sub 

sub SetControls()
    m.itemIcon = m.top.findNode("itemIcon")
    m.itemTitle = m.top.findNode("itemTitle")
end sub 

sub SetupFonts()
    m.itemTitle.font = m.fonts.dmSansMedium24
end sub

sub ShowContent()
    itemContent = m.top.itemContent
    if isValid(itemContent)
        if isNonEmptyString(itemContent.iconUri)
            m.itemIcon.uri = itemContent.iconUri
        end if
        m.itemTitle.text = itemContent.title
        itemContent.ObserveField("isExpanded", "OnExpandedChanged")
        UpdateExpandedState(itemContent.isExpanded)
    end if
    UpdateIconColor()
end sub

sub OnExpandedChanged(event as dynamic)
    UpdateExpandedState(event.GetData())
end sub

sub UpdateExpandedState(expanded as boolean)
    m.itemTitle.visible = expanded
end sub

Sub FocusPercentChanged(event as Dynamic)
    value = event.GetData()
    If (m.top.gridHasFocus)
        changeFocus(value)
    Else
        changeFocus(0)
    End If
End Sub

Sub ItemHasFocusChanged(event as Dynamic)
    value = event.GetData()
    If (value)
        changeFocus(1)
    End If
End Sub

Sub GridHasFocusChanged()
    If (m.top.GridHasFocus AND (m.top.ItemHasFocus OR m.top.FocusPercent = 1))
        changeFocus(1)
    Else
        changeFocus(0)
    End If
End Sub

Sub ChangeFocus(focusPercent)
    m.focusPercent = focusPercent
    UpdateIconColor()
end Sub

sub UpdateIconColor()
    itemContent = m.top.itemContent
    isFocused = isValid(m.focusPercent) AND m.focusPercent > 0
    isActive = isValid(itemContent) AND itemContent.isSelected
    color = m.theme.clrSecondaryText
    if isFocused
        color = m.theme.white
    else if isActive
        color = m.theme.focPrimary
    end if
    m.itemIcon.blendColor = color
    m.itemTitle.color = color
end sub