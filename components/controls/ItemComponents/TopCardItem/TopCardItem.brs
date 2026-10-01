sub init()
    theme = m.global.appTheme
    m.gNumber = m.top.findNode("gNumber")
    m.gImage = m.top.findNode("gImage")
    m.pImage = m.top.findNode("pImage")
    m.pFocus = m.top.findNode("pFocus")
    m.pFocus.blendColor = theme.focPrimary
    ' DM Sans Black (900) a 9vw, la misma fuente para las 9 copias del numero.
    font = CreateObject("roSGNode", "Font")
    font.uri = "pkg:/fonts/DMSans-Black.ttf"
    font.size = 173
    m.numberLabels = []
    for i = 1 to 8
        m.numberLabels.push(m.top.findNode("lN" + i.ToStr()))
    end for
    m.numberLabels.push(m.top.findNode("lNumber"))
    for each label in m.numberLabels
        label.font = font
        label.horizAlign = "right"
        label.vertAlign = "center"
        label.width = 260
        label.height = 173
        label.color = theme.focPrimary
    end for
    m.top.findNode("lNumber").color = "#000000"
    m.baseX = 0
end sub

' itemContent: ProgramItemNode del Top 10 (image_port + number, ver HomePageParser)
sub OnContentChange()
    content = m.top.itemContent
    if not isValid(content) then return
    imageURL = GetImageURL(content.image_port, "small")
    if not isNonEmptyString(imageURL) then imageURL = "pkg:/images/card/card_224_311.png"
    m.pImage.uri = imageURL
    number = ""
    if isValid(content.number) then number = content.number.ToStr()
    for each label in m.numberLabels
        label.text = number
    end for
    ' .card:first-child .posicion { right: 9.6vw }: el "1" queda 11px mas a la izquierda.
    ' El "10" es mas ancho: en la web se compensa con letter-spacing -.5vw (un Label
    ' no lo tiene); aca se corre 25px a la derecha, mas tapado por la imagen.
    m.baseX = 0
    if number = "1" then m.baseX = -11
    if number = "10" then m.baseX = 25
    OnFocusChange()
end sub

' La transicion de .3s de la web: escala y brillo siguen a focusPercent.
sub OnFocusChange()
    f = 0.0
    if m.top.rowListHasFocus then f = m.top.focusPercent
    if f < 0 then f = 0
    if f > 1 then f = 1
    scale = 1 + 0.13 * f
    m.gImage.scale = [scale, scale]
    m.gNumber.scale = [scale, scale]
    ' Con foco el numero pasa de right 9vw a 9.5vw: 10px mas a la izquierda.
    m.gNumber.translation = [m.baseX - 10 * f, 0]
    gray = Int(153 + 102 * f)
    hex = StrI(gray, 16)
    if Len(hex) < 2 then hex = "0" + hex
    m.pImage.blendColor = "#" + hex + hex + hex
    m.pFocus.visible = f > 0.5
end sub
