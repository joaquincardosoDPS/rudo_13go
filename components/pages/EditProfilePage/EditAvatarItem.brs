sub init()
    m.pAvatar = m.top.findNode("pAvatar")
    m.pRing = m.top.findNode("pRing")
    m.pRing.blendColor = m.global.appTheme.focPrimary
end sub

sub OnUriChange()
    m.pAvatar.uri = m.top.uri
end sub

sub UpdateFocus()
    m.pRing.visible = m.top.itemHasFocus
    if m.top.itemHasFocus
        m.pAvatar.opacity = 1
    else
        m.pAvatar.opacity = 0.6
    end if
end sub
