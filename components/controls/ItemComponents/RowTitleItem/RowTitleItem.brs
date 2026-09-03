sub init()
    SetLocals()
    SetControls()
    SetupFonts()
    SetupColor()
end sub

sub SetLocals()
    m.theme = m.global.appTheme
    m.fonts = m.global.fonts
end sub

sub SetControls()
    m.pCounter = m.top.findNode("pCounter")
    m.lCounter = m.top.findNode("lCounter")
    m.lRowLabelBadgeText = m.top.findNode("lRowLabelBadgeText")
end sub

sub SetupFonts()
    m.lRowLabelBadgeText.font = m.fonts.dmSansMedium26
    m.lCounter.font = m.fonts.dmSansMedium26
end sub

sub SetupColor()
    m.lRowLabelBadgeText.color = m.theme.white
    m.lCounter.color = m.theme.white
    m.pCounter.blendcolor = m.theme.white
    m.pCounter.opacity = 0.8
end sub

sub itemContentChanged(event as dynamic)
    content = event.getData()
    m.lCounter.visible = false
    m.pCounter.visible = false
    m.lRowLabelBadgeText.text = ""
    if (isValid(content.TITLE) AND content.TITLE <> "")
        array = content.TITLE.split("####")
        m.lRowLabelBadgeText.text = array[0]
        if (array.count() > 1 AND array[1].trim() <> "")
            if (array.count() > 2)
                m.lCounter.text = UCase(array[1]) + " " + UCase(array[2])
            else
                m.lCounter.text = UCase(array[1])
            end if
            width = m.lCounter.boundingRect().width
            xPosOfCounter = m.lRowLabelBadgeText.boundingRect().width + 20
            m.pCounter.width = width + 20
            m.lCounter.visible = true
            m.pCounter.visible = true
            m.pCounter.translation = [xPosOfCounter, 8]
            m.lCounter.translation = [xPosOfCounter + 10, 8]
        else
            m.lCounter.visible = false
            m.pCounter.visible = false
        end if
    end if
end sub
