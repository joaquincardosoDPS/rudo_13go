sub init()
    m.theme = m.global.appTheme
    m.pRing = m.top.findNode("pRing")
    m.pAvatar = m.top.findNode("pAvatar")
    m.pAvatarFrame = m.top.findNode("pAvatarFrame")
    m.lName = m.top.findNode("lName")
    m.pEditBorder = m.top.findNode("pEditBorder")
    m.pEditIcon = m.top.findNode("pEditIcon")
    m.lName.font = m.global.fonts.dmSansMedium23
    m.lName.color = m.theme.white
    m.pRing.blendColor = m.theme.focPrimary
    m.pEditIcon.blendColor = "#8C8C8C"
    UpdateFocus()
end sub

sub OnProfileNameChange()
    m.lName.text = m.top.profileName
end sub

sub OnProfileUriChange()
    m.pAvatar.uri = m.top.profileUri
    m.pAvatarFrame.visible = m.top.isPhoto
end sub

sub UpdateFocus()
    avatarFocused = m.top.avatarFocused
    m.pRing.visible = avatarFocused
    if avatarFocused
        m.pAvatar.opacity = 1
    else
        m.pAvatar.opacity = 0.6
    end if
    ' .btn-editar: borde gris #8C8C8C, naranjo con foco (el lapiz no cambia).
    if m.top.editFocused
        m.pEditBorder.blendColor = m.theme.focPrimary
    else
        m.pEditBorder.blendColor = "#8C8C8C"
    end if
end sub
