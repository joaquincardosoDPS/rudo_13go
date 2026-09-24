sub init()
    m.pImage = m.top.findNode("pImage")
    m.pDurationFade = m.top.findNode("pDurationFade")
    m.lDuration = m.top.findNode("lDuration")
    m.rProgress = m.top.findNode("rProgress")
    m.pFocus = m.top.findNode("pFocus")
    m.lEpigrafe = m.top.findNode("lEpigrafe")
    m.lTitle = m.top.findNode("lTitle")
    theme = m.global.appTheme
    fonts = m.global.fonts
    m.lEpigrafe.font = fonts.dmSansMedium23
    m.lEpigrafe.color = theme.focPrimary
    m.lTitle.font = fonts.dmSansBold23
    m.lTitle.color = theme.white
    m.lDuration.font = fonts.dmSansMedium18
    m.lDuration.color = theme.white
    m.pFocus.blendColor = theme.focPrimary
end sub

' itemContent: { image, show, title, seconds, duration } (campos de /accountTracking)
sub OnContentChange()
    content = m.top.itemContent
    if not isValid(content) then return
    m.pImage.uri = content.image
    m.lEpigrafe.text = decodeHtmlEntities(content.show)
    m.lTitle.text = decodeHtmlEntities(content.title)
    seconds = convertToNumber(content.seconds)
    duration = convertToNumber(content.duration)
    ' calcProgress: min(seconds / duration, 1); formatDuration de la duracion total
    ratio = 0
    if duration > 0 then ratio = seconds / duration
    if ratio > 1 then ratio = 1
    m.rProgress.width = Int(326 * ratio)
    hasDuration = duration > 0
    m.lDuration.visible = hasDuration
    m.pDurationFade.visible = hasDuration
    if hasDuration then m.lDuration.text = FormatClock(Int(duration))
end sub

sub OnFocusChange()
    focused = m.top.rowListHasFocus AND (m.top.itemHasFocus OR m.top.focusPercent > 0.5)
    m.pFocus.visible = focused
    if focused
        m.pImage.blendColor = "#FFFFFF"
    else
        m.pImage.blendColor = "#808080"
    end if
end sub

' HH:MM:SS si hay horas, si no MM:SS
function FormatClock(total as integer) as string
    h = Int(total / 3600)
    mm = Int((total MOD 3600) / 60)
    s = total MOD 60
    text = TwoDigits(mm) + ":" + TwoDigits(s)
    if h > 0 then text = TwoDigits(h) + ":" + text
    return text
end function

function TwoDigits(value as integer) as string
    if value < 10 then return "0" + value.ToStr()
    return value.ToStr()
end function
