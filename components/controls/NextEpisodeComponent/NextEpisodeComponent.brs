sub Init()
    print "CategoryDetailPage Init "
    SetLocals()
    SetControls()
    SetupColor()
    SetupFonts()
    SetObservers()
end sub

sub SetLocals()
    m.scene = m.top.GetScene()
    m.fonts = m.global.fonts
    m.theme = m.global.appTheme
end sub

sub SetControls()
    m.pVideo = m.top.findNode("pVideo")
    m.overlay = m.top.findNode("overlay")
    m.lgDetails = m.top.findNode("lgDetails")
    m.pLogo = m.top.findNode("pLogo")
    m.lTitle = m.top.findNode("lTitle")
    m.lEpisodeTitle = m.top.findNode("lEpisodeTitle")
    m.lDescription = m.top.findNode("lDescription")
    m.lgButtons = m.top.findNode("lgButtons")
    m.nextEpisodeButton = m.top.findNode("nextEpisodeButton")
    m.episodeListButton = m.top.findNode("episodeListButton")
end sub

sub SetupColor()
    m.overlay.color = m.theme.black
    m.lTitle.color = m.theme.white
    m.lEpisodeTitle.color = m.theme.white
    m.lDescription.color = m.theme.white
end sub

sub SetupFonts()
    m.lTitle.font = m.fonts.poppinsBold48
    m.lEpisodeTitle.font = m.fonts.poppinsBold48
    m.lDescription.font = m.fonts.poppinsMedium24
end sub

sub SetObservers()
    m.top.observeField("focusedChild", "OnFocusedChild")
end sub

sub onContentInfoChanged()
    m.content = m.top.contentNode
    if isValid(m.content)
        if isNonEmptyString(m.content.logoTitle)
            m.pLogo.uri = m.content.logoTitle
            m.pLogo.visible = true
            m.lgDetails.removeChild(m.lTitle)
        else
            m.lTitle.text = m.content.title
            m.lTitle.visible = true
            m.lgDetails.removeChild(m.pLogo)
        end if
        if isValid(m.content.episodeTitle) AND m.content.episodeTitle <> ""
            m.lEpisodeTitle.text = m.content.episodeTitle
            m.lEpisodeTitle.font = m.fonts.poppinsBold32
        else
            m.lgDetails.removeChild(m.lEpisodeTitle)
        end if
        if isNonEmptyString(m.content.description)
            m.lDescription.text = m.content.description
        else
            m.lgDetails.removeChild(m.lDescription)
        end if
        if isNonEmptyString(m.content.episodeImage)
            m.pVideo.uri = m.content.episodeImage
            m.pVideo.visible = true
        end if
        btnFields = {
            focusTextColor: m.theme.white
            unfocusTextColor: m.theme.white
            backgroundColor: m.theme.clrSecondary
            focusBorderImage: m.theme.filledBackGroundImage
            focusBackgroundColor: m.theme.focPrimary
            fontSize: "poppinsMedium24"
            margin: 20
            addColorOnImage: true
        }
        m.nextEpisodeButton.update(btnFields)
        m.episodeListButton.update(btnFields)
        SetFocus(m.episodeListButton)
        if isValid(m.content.isShowNextEpisode) AND m.content.isShowNextEpisode
            m.nextEpisodeButton.visible = true
            SetFocus(m.nextEpisodeButton)
        else
            m.lgButtons.removeChild(m.nextEpisodeButton)
        end if
    end if
end sub

sub OnFocusedChild()
    if m.top.hasFocus()
        focusRestored = RestoreFocus()
        if focusRestored = false
            if isValid(m.nextEpisodeButton) AND m.nextEpisodeButton.visible
                SetFocus(m.nextEpisodeButton)
            else
                SetFocus(m.episodeListButton)
            end if
        end if
    end if
end sub

sub OnVideoPositionChanged(event as dynamic)
    position = event.getData()
    buttonText = "Siguiente episodio en "
    m.nextEpisodeButton.buttonText = buttonText + position.toStr()
    m.nextEpisodeButton.buttonWidth = 395
end sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = true
    if press
        print " Page : NextEpisodeComponent : onKeyEvent : key = " key " press = " press
        if key = "left"
            if isValid(m.nextEpisodeButton) AND m.nextEpisodeButton.visible AND m.episodeListButton.hasFocus()
                SetFocus(m.nextEpisodeButton)
            end if
            handled = true
        else if key = "right"
            if isValid(m.nextEpisodeButton) AND m.nextEpisodeButton.visible AND m.nextEpisodeButton.hasFocus()
                SetFocus(m.episodeListButton)
            end if
            handled = true
        else if key = "OK"
            if isValid(m.nextEpisodeButton) AND m.nextEpisodeButton.visible AND m.nextEpisodeButton.hasFocus()
                m.top.showNextEpisode = true
            else if m.episodeListButton.hasFocus()
                m.top.showEpisodeList = true
            end if
        else if key = "back"
            handled = false
        end if
    end if
    return handled
End Function
