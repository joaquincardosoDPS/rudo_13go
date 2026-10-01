sub init()
    m.top.poster.uri = "pkg:/images/loader/spinner_dots.png"
    m.top.poster.loadDisplayMode = "scaleToFit"
    m.top.clockwise = true
    m.top.spinInterval = 1
    OnSizeChange()
    m.top.control = "start"
end sub

sub OnSizeChange()
    size = m.top.size
    m.top.poster.width = size
    m.top.poster.height = size
    m.top.poster.loadWidth = size * 2
    m.top.poster.loadHeight = size * 2
end sub
