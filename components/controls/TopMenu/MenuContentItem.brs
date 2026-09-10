sub init()
    SetLocals()
    SetControls()
    SetupFonts()
    SetupColor()
end sub

sub SetLocals()
    m.theme = m.global.appTheme
    m.fonts = m.global.fonts
    m.focusPercent = 0
end sub 

sub SetControls()
    m.itemIcon = m.top.findNode("itemIcon")
    m.itemTitle = m.top.findNode("itemTitle")
    m.pFocusBg = m.top.findNode("pFocusBg")
end sub 

sub SetupFonts()
    m.itemTitle.font = m.fonts.dmSansMedium24
end sub

sub SetupColor()
    if isValid(m.pFocusBg)
        m.pFocusBg.blendColor = m.theme.white
        m.pFocusBg.opacity = 0.22
    end if
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
    ' El fondo de foco se adapta: cubre todo el ítem cuando el sidebar está
    ' expandido (ícono + texto) y solo el ícono cuando está colapsado.
    if isValid(m.pFocusBg)
        if expanded
            m.pFocusBg.width = 256
            m.pFocusBg.height = 80
            m.pFocusBg.translation = [2, 5]
        else
            m.pFocusBg.width = 76
            m.pFocusBg.height = 76
            m.pFocusBg.translation = [8, 7]
        end if
    end if
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
    ' Color por estado (los íconos son blancos, blendColor los tiñe):
    '   seleccionado -> naranjo (independiente del foco)
    '   con foco     -> blanco
    '   ninguno      -> gris
    color = "#9b9b9b"
    if isActive
        color = m.theme.focPrimary
    else if isFocused
        color = m.theme.white
    end if
    m.itemIcon.blendColor = color
    m.itemTitle.color = color
    ' Fondo de foco: marca el ítem enfocado sin depender del color.
    if isValid(m.pFocusBg) then m.pFocusBg.visible = isFocused
end sub