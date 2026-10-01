sub init()
    setLocals()
    setControls()
    setColors()
    Initialize()
end sub

sub setLocals()
    m.theme = m.global.appTheme
    m.fonts = m.global.fonts
end sub

sub setControls()
    m.rLoaderBackground = m.top.findNode("rLoaderBackground")
    m.gLoader = m.top.findNode("gLoader")
    m.bsLoader = m.top.findNode("bsLoader")
    m.lSpinnerText = m.top.findNode("lSpinnerText")
end sub

sub setColors()
    if isValid(m.theme)
        m.rLoaderBackground.color = m.theme.black
    end if
end sub

sub Initialize(width = "100" as string)
    ' Spinner de la web (DotsSpinner, 56px como el FullScreenSpinner); loaderWidth ya no
    ' cambia el tamano (antes era la imagen de MiCHV tenida de rosado).
    setColors()
    if m.top.isCenter
        xPos = (1920 - m.bsLoader.size) / 2
        yPos = (1080 - m.bsLoader.size) / 2
        m.gLoader.translation = [xPos, yPos]
    end if
end sub

sub OnShowSpinnerTextChange()
    if m.top.showSpinnerText <> ""
        m.lSpinnerText.visible = true
        m.lSpinnerText.text = m.top.showSpinnerText
    else
        m.lSpinnerText.visible = false
    end if
    Initialize(m.top.loaderWidth)
end sub