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
    m.isAvatarItem = false
    m.defaultAvatarUri = "pkg:/images/other/default_user.png"
end sub

sub SetControls()
    m.itemIcon = m.top.findNode("itemIcon")
    m.itemTitle = m.top.findNode("itemTitle")
    m.pFocusBg = m.top.findNode("pFocusBg")
    m.pAvatarFocusBg = m.top.findNode("pAvatarFocusBg")
    m.pAvatar = m.top.findNode("pAvatar")
    m.pAvatarFrame = m.top.findNode("pAvatarFrame")
    m.pPremiumRing = m.top.findNode("pPremiumRing")
    m.pPremiumBadgeBg = m.top.findNode("pPremiumBadgeBg")
    m.lPremiumBadge = m.top.findNode("lPremiumBadge")
end sub

sub SetupFonts()
    m.itemTitle.font = m.fonts.dmSansMedium24
    ' La placa "Premium" real es chiquita (0.6vw de fuente) - dmSansBold18 es
    ' el tamaño mas chico que tenemos importado.
    m.lPremiumBadge.font = m.fonts.dmSansBold18
end sub

sub SetupColor()
    if isValid(m.pFocusBg)
        m.pFocusBg.blendColor = m.theme.white
        m.pFocusBg.opacity = 0.22
    end if
    m.pAvatarFocusBg.blendColor = m.theme.white
    ' El anillo y la placa "Premium" del sidebar son amarillos en la web
    ' (#ffcf04, .menu .premium / .premium::after), con texto negro en la placa.
    m.pPremiumRing.blendColor = m.theme.focTertiary
    m.pPremiumBadgeBg.blendColor = m.theme.focTertiary
    m.lPremiumBadge.color = m.theme.black
end sub

sub ShowContent()
    itemContent = m.top.itemContent
    if isValid(itemContent)
        m.isAvatarItem = itemContent.isAvatar
        if isNonEmptyString(itemContent.iconUri)
            m.itemIcon.uri = itemContent.iconUri
        end if
        m.itemTitle.text = itemContent.title
        itemContent.ObserveField("isExpanded", "OnExpandedChanged")
        itemContent.ObserveField("avatarUri", "OnAvatarChanged")
        itemContent.ObserveField("isPremium", "OnAvatarChanged")
        UpdateExpandedState(itemContent.isExpanded)
        UpdateAvatar()
    end if
    UpdateIconColor()
end sub

sub OnAvatarChanged()
    UpdateAvatar()
end sub

' El item "Mi cuenta" muestra el avatar del perfil activo en vez de un icono
' plano (ver el menuItems[0] del Sidebar.tsx de c13_reloaded).
sub UpdateAvatar()
    itemContent = m.top.itemContent
    if not isValid(itemContent) then return
    m.itemIcon.visible = not m.isAvatarItem
    m.pAvatar.visible = m.isAvatarItem
    if not m.isAvatarItem
        m.pAvatarFrame.visible = false
        m.pPremiumRing.visible = false
        m.pPremiumBadgeBg.visible = false
        m.lPremiumBadge.visible = false
        return
    end if
    avatarUri = itemContent.avatarUri
    if not isNonEmptyString(avatarUri) then avatarUri = m.defaultAvatarUri
    m.pAvatar.uri = avatarUri
    ' Las fotos reales son JPG cuadrados y necesitan el marco circular;
    ' default_user.png ya trae el circulo con esquinas transparentes.
    m.pAvatarFrame.visible = avatarUri <> m.defaultAvatarUri
    isPremium = itemContent.isPremium
    m.pPremiumRing.visible = isPremium
    m.pPremiumBadgeBg.visible = isPremium
    m.lPremiumBadge.visible = isPremium
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
    ' El avatar es una foto: no se tiñe, solo se atenúa cuando no tiene foco.
    if m.isAvatarItem
        if isFocused
            m.pAvatar.opacity = 1
        else
            m.pAvatar.opacity = 0.7
        end if
    end if
    ' Fondo de foco: marca el ítem enfocado sin depender del color. El avatar
    ' usa su propio anillo circular (pAvatarFocusBg) en vez del rectangulo
    ' redondeado genérico (pFocusBg), que se apaga siempre para este ítem.
    if m.isAvatarItem
        m.pAvatarFocusBg.visible = isFocused
        if isValid(m.pFocusBg) then m.pFocusBg.visible = false
    else
        m.pAvatarFocusBg.visible = false
        if isValid(m.pFocusBg) then m.pFocusBg.visible = isFocused
    end if
end sub
