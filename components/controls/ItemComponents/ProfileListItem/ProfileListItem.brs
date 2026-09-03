sub init()
    setLocals()
    setControls()
    setupColor()
    setupFonts()
    setObservers()
end sub

sub setLocals()
    m.fonts = m.global.fonts
    m.theme = m.global.appTheme
    m.defaultProfileUri = "pkg:/images/focus/add_profile_img_unfocus.png"
end sub

sub setControls()
    m.title = m.top.findNode("title")
    m.borderMask = m.top.FindNode("borderMask")
    m.poster = m.top.findNode("poster")
    m.email = m.top.findNode("email")
    m.roundedTransparent_Poster = m.top.findNode("roundedTransparent_Poster")
    m.editBadge = m.top.findNode("editBadge")
end sub

sub setupColor()
    m.title.color = m.theme.white
end sub

sub setupFonts()
    m.title.font = m.fonts.poppinsMedium29
end sub

sub setObservers()
end sub

sub itemContentChanged(event as dynamic)
    m.itemContent = event.getData()
    if isValid(m.itemContent)
        m.title.text = m.itemContent.profileName
        profileUri = m.defaultProfileUri
        if m.itemContent.hasField("profileUri") AND m.itemContent.profileUri <> invalid AND m.itemContent.profileUri.Trim() <> ""
            profileUri = m.itemContent.profileUri
        end if
        m.poster.uri = profileUri
        maskSize = [m.poster.width, m.poster.height]
        if m.global.designresolution = "720p"
            maskSize = [maskSize[0] / 1.5, maskSize[1] / 1.5]
        end if
        m.borderMask.maskSize = maskSize
        showEditBadge = false
        if m.itemContent.hasField("showEditBadge")
            showEditBadge = m.itemContent.showEditBadge
        end if
        m.editBadge.visible = showEditBadge
    end if
end sub

sub focusPercentChanged()
    if m.top.gridHasFocus AND m.top.focusPercent > 0.5
        if isValid(m.itemContent)
            m.poster.opacity = 1
            m.title.color = m.theme.focPrimary
            m.roundedTransparent_Poster.blendColor = m.theme.focPrimary
        end if
    else
        if isValid(m.itemContent)
            m.poster.opacity = 0.6
            m.title.color = m.theme.white
            m.roundedTransparent_Poster.blendColor = m.theme.white
        end if
    end if
end sub
