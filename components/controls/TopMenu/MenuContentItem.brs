sub init()
    SetLocals()
    SetControls()
    SetupFonts()
    SetupColor()
end sub

sub SetLocals()
    m.theme = m.global.appTheme
    m.fonts = m.global.Fonts
end sub 

sub SetControls()
    m.itemTitle = m.top.findNode("itemTitle")
    m.itemSelect = m.top.findNode("itemSelect")
    m.itemFocus = m.top.findNode("itemFocus")
end sub 

sub SetupFonts()
    m.itemTitle.font = m.fonts.dmSansMedium24
end sub 

sub SetupColor()
    m.defaultTextColor = m.theme.clrSecondaryText
    m.activeTextColor = m.theme.white
    m.itemTitle.color = m.defaultTextColor
    m.itemSelect.blendColor = m.theme.selectedFieldColor
    m.itemFocus.blendColor = m.theme.focPrimary
end sub 

sub ShowContent()
    itemContent = m.top.itemContent
    m.itemTitle.width = m.top.width
    m.itemTitle.text = itemContent.title
    textBounds = m.itemTitle.boundingRect()
    underlineWidth = textBounds.width
    underlineY = textBounds.height + 3
    m.itemSelect.width = underlineWidth
    m.itemFocus.width = underlineWidth
    m.itemFocus.translation = [0, underlineY]
    m.itemSelect.translation = [0, underlineY]
    m.itemSelect.visible = itemContent.isSelected
    UpdateTitleColor()
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
    m.itemFocus.opacity = focusPercent
    UpdateTitleColor()
end Sub

sub UpdateTitleColor()
    itemContent = m.top.itemContent
    hasActiveState = false
    if ((itemContent <> invalid AND itemContent.isSelected) OR (m.itemFocus.opacity > 0))
        hasActiveState = true
    end if
    if hasActiveState
        m.itemTitle.color = m.activeTextColor
    else
        m.itemTitle.color = m.defaultTextColor
    end if
End Sub
