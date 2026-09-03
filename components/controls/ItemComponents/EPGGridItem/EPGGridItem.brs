sub init()
    setLocals()
    setControls()
    setupFonts()
    setupColor()
end sub

sub setLocals()
    m.fonts = m.global.fonts
    m.theme = m.global.appTheme
    m.scene = m.top.GetScene()
end sub

sub setControls()
    m.rBox = m.top.findNode("rBox")
    m.channelLogo = m.top.findNode("channelLogo")
    m.programDetail = m.top.findNode("programDetail")
    m.programTitle = m.top.findNode("programTitle")
    m.lLiveTime = m.top.findNode("lLiveTime")
    m.playIcon = m.top.findNode("playIcon")
end sub

sub setupFonts()
    m.programTitle.font = m.fonts.dmSansMedium30
    if isValid(m.lLiveTime) then m.lLiveTime.font = m.fonts.dmSansReg26
end sub

sub setupColor()
    m.rBox.blendColor = m.theme.clrPrimaryButton
    m.programTitle.color = m.theme.white
    if isValid(m.lLiveTime) then m.lLiveTime.color = m.theme.white
    m.playIcon.blendColor = m.theme.white
end sub

sub itemContentChanged()
    itemcontent = m.top.itemContent
    if isValid(itemcontent)
        m.rBox.width = m.top.width
        m.rBox.height = m.top.height
        m.programTitle.text = itemcontent.title
        m.channelLogo.visible = false
        m.programTitle.visible = true
        if isValid(m.lLiveTime) then m.lLiveTime.visible = false
        if isValid(m.lLiveTime) then m.lLiveTime.text = ""
        m.playIcon.opacity = 0
        m.playIcon.translation = [m.top.width - (m.playIcon.width + 8), 8]
        if itemcontent.colIndex = 0
            m.channelLogo.width = "80"
            m.channelLogo.height = "80"
            m.channelLogo.loadWidth = "80"
            m.channelLogo.loadHeight = "80"
            m.channelLogo.translation = [(m.top.width - m.channelLogo.width) / 2, (m.top.height - m.channelLogo.height) / 2]
            m.channelLogo.uri = itemcontent.logo
            m.channelLogo.loadDisplayMode = "scaleToFit"
            m.channelLogo.visible = true
            m.programTitle.visible = false
        else
            if isValid(itemcontent.programId) AND isNonEmptyString(itemcontent.programId) AND itemcontent.programId <> ""
                dateTimeString = ""
                startDate = CreateObject("roDateTime")
                startDate.FromISO8601String(itemcontent.beginTime)
                startDate.ToLocalTime()
                startDateSeconds = startDate.AsSeconds()
                dateTimeString += formatTimeStringInHHMM(startDateSeconds)

                endDate = CreateObject("roDateTime")
                endDate.FromISO8601String(itemcontent.endTime)
                endDate.ToLocalTime()
                endDateSeconds = endDate.AsSeconds()
                dateTimeString += " - " + formatTimeStringInHHMM(endDateSeconds)
                ' dateTimeString += " (" + getDurationFormated(endDateSeconds - startDateSeconds) + ")"
                if isValid(m.lLiveTime) 
                    m.lLiveTime.text = dateTimeString
                    m.lLiveTime.visible = true
                end if
            else
                m.programTitle.height = m.top.width
                m.programDetail.removeChild(m.lLiveTime)
                m.lLiveTime = invalid
            end if
        end if
        programDetailBound = m.programDetail.boundingRect()
        m.programDetail.translation = [15, (m.top.height - programDetailBound.height) / 2]
    end if
end sub

sub setItemFocus(percent)
    if (isValid(m.top.itemContent) AND m.top.itemContent.colIndex <> 0)
        if (isValid(m.top.itemcontent.isLive) AND m.top.itemcontent.isLive)
            m.playIcon.opacity = percent
        end if
        if (percent > 0.5)
            m.rBox.blendColor = m.theme.focPrimary
        else
            m.rBox.blendColor = m.theme.clrPrimaryButton
        end if
    end if
end sub

sub focusPercentChanged(event as dynamic)
    percent = event.getData()
    if (m.top.gridHasFocus)
        setItemFocus(percent)
    else
        setItemFocus(0)
    end if
end sub

sub itemHasFocusChanged(event as dynamic)
    value = event.GetData()
    if (value)
        setItemFocus(1)
    end if
end sub

sub parentHasFocusChanged()
    if (m.top.GridHasFocus AND (m.top.ItemHasFocus OR m.top.FocusPercent = 1))
        setItemFocus(1)
    else
        setItemFocus(0)
    end if
end sub

function OnkeyEvent(key as string, press as boolean) as boolean
    result = false
    if press
        if key = "OK"
        end if
    end if
    return result
end function
