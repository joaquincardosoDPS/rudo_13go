sub init()
    m.pImage = m.top.findNode("pImage")
    m.rLocked = m.top.findNode("rLocked")
    m.pLock = m.top.findNode("pLock")
    m.pDurationFade = m.top.findNode("pDurationFade")
    m.lDuration = m.top.findNode("lDuration")
    m.pFocus = m.top.findNode("pFocus")
    m.lTitle = m.top.findNode("lTitle")
    m.lTitle.font = m.global.fonts.dmSansBold23
    m.lTitle.color = m.global.appTheme.white
    m.lDuration.font = m.global.fonts.dmSansMedium18
    m.lDuration.color = m.global.appTheme.white
    m.pFocus.blendColor = m.global.appTheme.focPrimary
end sub

sub OnContentChange()
    content = m.top.itemContent
    if not isValid(content) then return
    m.pImage.uri = content.image
    m.lTitle.text = content.title
    hasDuration = isNonEmptyString(content.duration)
    m.lDuration.text = content.duration
    m.lDuration.visible = hasDuration
    m.pDurationFade.visible = hasDuration
    m.rLocked.visible = content.blocked = true
    m.pLock.visible = content.blocked = true
end sub

sub OnFocusChange()
    focused = m.top.gridHasFocus AND (m.top.itemHasFocus OR m.top.focusPercent > 0.5)
    m.pFocus.visible = focused
    if focused
        m.pImage.blendColor = "#FFFFFF"
    else
        m.pImage.blendColor = "#808080"
    end if
end sub
