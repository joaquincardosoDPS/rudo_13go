sub init()
    SetLocals()
    SetControls()
end sub

sub SetLocals()
    m.theme = m.global.appTheme
    m.focusPercent = 0
end sub 

sub SetControls()
    m.itemIcon = m.top.findNode("itemIcon")
end sub 


sub ShowContent()
    itemContent = m.top.itemContent
    if isValid(itemContent) AND isNonEmptyString(itemContent.iconUri)
        m.itemIcon.uri = itemContent.iconUri
    end if
    UpdateIconColor()
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
    isFocused = isValid(m.FocusPercent) AND m.FocusPercent > 0
    isActive = isValid(itemContent) and itemContent.isSelected

    if isFocused
        m.itemIcon.blendColor = m.theme.white
    else if isActive
        m.itemIcon.blendColor = m.theme.focPrimary
    else
        m.itemIcon.blendColor = m.theme.clrSecondaryText
    end if
End Sub
