' Modal de confirmacion (ExitDialog.tsx). Foco virtual: la raiz tiene el foco real y
' m.currentBtn dice cual boton se ve enfocado (0 = "No", 1 = positivo).
sub Init()
    m.theme = m.global.appTheme
    m.fonts = m.global.fonts
    m.gBox = m.top.findNode("gBox")
    m.pBox = m.top.findNode("pBox")
    m.lTitle = m.top.findNode("lTitle")
    m.lDetail = m.top.findNode("lDetail")
    m.gButtons = m.top.findNode("gButtons")
    m.gNo = m.top.findNode("gNo")
    m.gYes = m.top.findNode("gYes")
    m.pNo = m.top.findNode("pNo")
    m.pYes = m.top.findNode("pYes")
    m.lNo = m.top.findNode("lNo")
    m.lYes = m.top.findNode("lYes")

    m.lTitle.font = m.fonts.dmSansBold36
    m.lTitle.color = m.theme.white
    m.lDetail.font = m.fonts.dmSansMedium19
    m.lDetail.color = m.theme.white
    m.lNo.font = m.fonts.dmSansMedium24
    m.lYes.font = m.fonts.dmSansMedium24
    m.lNo.color = m.theme.white
    m.lYes.color = m.theme.white

    ' Foco inicial en "No" (setFocus(DIALOG_BTN_NO) de la web).
    m.currentBtn = 0
    Layout()
end sub

' Alto de la caja segun el texto real: padding 32 + margen del h2 (~30) + titulo +
' 29 + detalle + 24 + botones (48) + padding 32, como se midio en la web.
sub Layout()
    m.lTitle.text = m.top.message
    m.lDetail.text = m.top.detail
    m.lYes.text = m.top.positiveButtonText

    titleH = TextHeight(m.lTitle, 45)
    y = 62 + titleH
    if m.top.detail <> ""
        m.lDetail.visible = true
        m.lDetail.translation = [32, y + 29]
        y = y + 29 + TextHeight(m.lDetail, 25)
        y = y + 24
    else
        m.lDetail.visible = false
        y = y + 29
    end if

    ' Botones: ancho = texto + padding 30 a cada lado; separados 40 y centrados.
    noW = ButtonWidth(m.lNo)
    yesW = ButtonWidth(m.lYes)
    SizeButton(m.gNo, m.pNo, m.lNo, noW)
    SizeButton(m.gYes, m.pYes, m.lYes, yesW)
    m.gYes.translation = [noW + 40, 0]
    totalW = noW + 40 + yesW
    m.gButtons.translation = [(400 - totalW) / 2, y]

    boxH = y + 48 + 32
    m.pBox.height = boxH
    m.gBox.translation = [(1920 - 400) / 2, (1080 - boxH) / 2]
    ApplyButtonFocus()
end sub

' Alto del texto con wrap (boundingRect); si no se puede medir (brs-node), un
' aproximado por linea.
function TextHeight(label as object, lineH as integer) as integer
    if label.text = "" then return 0
    h = label.boundingRect().height
    if h <= 0
        lines = Int(Len(label.text) / 22) + 1
        h = lines * lineH
    end if
    return h
end function

function ButtonWidth(label as object) as integer
    label.width = 0
    w = label.boundingRect().width
    if w <= 0 then w = Len(label.text) * 13
    return w + 60
end function

sub SizeButton(group as object, bg as object, label as object, w as integer)
    bg.width = w
    label.width = w
    group.scaleRotateCenter = [w / 2, 24]
end sub

' Con foco: #FA6428 y scale(1.1); sin foco: #333.
sub ApplyButtonFocus()
    if m.currentBtn = 0
        m.pNo.blendColor = "#FA6428"
        m.pYes.blendColor = "#333333"
        m.gNo.scale = [1.1, 1.1]
        m.gYes.scale = [1, 1]
    else
        m.pNo.blendColor = "#333333"
        m.pYes.blendColor = "#FA6428"
        m.gNo.scale = [1, 1]
        m.gYes.scale = [1.1, 1.1]
    end if
end sub

' DialogButton.tsx: izquierda/derecha cambian entre los dos botones; el foco no sale
' del modal. Back = "No".
function OnKeyEvent(key as string, press as boolean) as boolean
    if not press then return true
    if key = "back"
        m.top.selectedButton = 0
    else if key = "OK"
        m.top.selectedButton = m.currentBtn
    else if key = "left" OR key = "right"
        m.currentBtn = 1 - m.currentBtn
        ApplyButtonFocus()
    end if
    return true
end function
