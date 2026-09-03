sub init()
    m.theme = m.global.appTheme
    m.fonts = m.global.fonts
    m.focusBorder = m.top.findNode("focusBorder")
    m.avatarMask = m.top.findNode("avatarMask")
    m.avatarPoster = m.top.findNode("avatarPoster")
    m.focusBorder.blendColor = m.theme.white
    m.avatarPoster.opacity = 0.65
end sub

sub OnItemContentChanged()
    itemContent = m.top.itemContent
    if not isValid(itemContent)
        return
    end if
    if itemContent.hasField("profileUri") AND itemContent.profileUri <> invalid AND itemContent.profileUri <> ""
        m.avatarPoster.uri = itemContent.profileUri
    end if
    maskSize = [m.avatarMask.BoundingRect().width, m.avatarMask.BoundingRect().height]
    if m.global.designresolution = "720p"
        maskSize = [maskSize[0] / 1.5, maskSize[1] / 1.5]
    end if
    m.avatarMask.maskSize = maskSize
end sub

sub OnFocusChanged()
    if m.top.gridHasFocus AND m.top.focusPercent > 0.5
        m.focusBorder.blendColor = m.theme.focPrimary
        m.avatarPoster.opacity = 1
    else
        m.focusBorder.blendColor = m.theme.white
        m.avatarPoster.opacity = 0.65
    end if
end sub
