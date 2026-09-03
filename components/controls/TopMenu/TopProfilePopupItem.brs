sub init()
    m.theme = m.global.appTheme
    m.fonts = m.global.Fonts
    m.mgAvatar = m.top.findNode("mgAvatar")
    m.pAvatar = m.top.findNode("pAvatar")
    m.lTitle = m.top.findNode("lTitle")
    m.lTitle.font = m.fonts.poppinsMedium24
    m.lTitle.color = m.theme.white
end sub

sub ShowContent()
    itemContent = m.top.itemContent
    if itemContent = invalid then return

    m.lTitle.text = itemContent.title
    showAvatar = false
    if itemContent.hasField("showAvatar")
        showAvatar = itemContent.showAvatar
    end if
    maskSize = [m.mgAvatar.BoundingRect().width, m.mgAvatar.BoundingRect().height]
    if m.global.designresolution = "720p"
        maskSize = [maskSize[0] / 1.5, maskSize[1] / 1.5]
    end if
    m.mgAvatar.maskSize = maskSize
    m.mgAvatar.visible = showAvatar
    if showAvatar AND itemContent.hasField("profileUri") AND itemContent.profileUri <> invalid AND itemContent.profileUri <> ""
        m.pAvatar.uri = itemContent.profileUri
    end if
end sub

sub FocusPercentChanged(event as Dynamic)
    UpdateFocus(event.GetData())
end sub

sub ItemHasFocusChanged(event as Dynamic)
    if event.GetData()
        UpdateFocus(1)
    end if
end sub

sub GridHasFocusChanged()
    if m.top.GridHasFocus AND (m.top.ItemHasFocus OR m.top.FocusPercent = 1)
        UpdateFocus(1)
    else
        UpdateFocus(0)
    end if
end sub

sub UpdateFocus(focusPercent as Float)
    if focusPercent > 0
        m.lTitle.color = m.theme.focPrimary
    else
        m.lTitle.color = m.theme.white
    end if
end sub
