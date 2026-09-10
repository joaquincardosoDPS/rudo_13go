sub init()
    m.theme = m.global.appTheme
    m.fonts = m.global.Fonts
    m.pHeaderBg = m.top.findNode("pHeaderBg")
    m.lVodTitle = m.top.findNode("lVodTitle")
    m.lVodDesc = m.top.findNode("lVodDesc")
    m.lVodTitle.font = m.fonts.dmSansBold48
    m.lVodDesc.font = m.fonts.dmSansBold23
    m.lVodTitle.color = m.theme.white
    m.lVodDesc.color = m.theme.white
    onTitleChanged()
    onDescriptionChanged()
end sub

sub onBackgroundImageChanged()
    if isNonEmptyString(m.top.backgroundImage)
        m.pHeaderBg.uri = m.top.backgroundImage
    end if
end sub

sub onTitleChanged()
    m.lVodTitle.text = m.top.title
end sub

sub onDescriptionChanged()
    m.lVodDesc.text = m.top.description
end sub
