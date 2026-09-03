sub init()
    m.fonts = m.global.fonts
    m.theme = m.global.appTheme
    m.pBackGround = m.top.findNode("pBackGround")
    m.pIcon = m.top.findNode("pIcon")
    m.pBackGround.blendColor = m.theme.focPrimary
end sub

sub ItemContent_Changed()
    itemcontent = m.top.itemContent
    m.pIcon.uri = itemContent.icon_url
    ' if (itemcontent.id = "like" AND isValid(itemcontent.isLike) AND itemcontent.isLike = "1")
    '     m.pIcon.uri = itemContent.icon_fill_uri
    ' end if
    ' if (itemcontent.id = "addWatchList" AND isValid(itemcontent.isWatch) AND itemcontent.isWatch = "1")
    '     m.pIcon.uri = itemContent.icon_fill_uri
    ' end if
end sub

sub setSize(percent as float)
    imagPer = percent
    if (percent < 0.5)
        imagPer = 0
    end if
    m.pBackGround.opacity = imagPer
end sub

sub focusPercent_Changed(event as dynamic)
    value = event.GetData()
    if ((m.top.rowListHasFocus AND m.top.rowHasFocus) OR m.top.gridHasFocus)
        setSize(value)
    else
        setSize(0)
    end if
end sub

sub itemHasFocus_Changed(event as dynamic)
    value = event.GetData()
    if (value)
        setSize(1)
    end if
end sub

sub rowHasFocus_Changed()
    if (m.top.rowHasFocus AND m.top.itemHasFocus)
        setSize(1)
    else
        setSize(0)
    end if
end sub

sub parentHasFocus_Changed()
    if (((m.top.RowListHasFocus AND m.top.rowHasFocus) OR m.top.gridHasFocus) AND (m.top.itemHasFocus OR m.top.focusPercent = 1))
        setSize(1)
    else
        setSize(0)
    end if
end sub
