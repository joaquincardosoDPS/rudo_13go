Sub Init()
    Print "CustomButton : Init"
    SetLocals()
    SetControls()
    SetObservers()
    SetupFonts()
    SetupColor()
    OnBorderSize()
End Sub

Sub SetLocals()
    m.theme = m.global.appTheme
    m.fonts = m.global.fonts
End Sub

Sub SetControls()
    m.slButtonText = m.top.FindNode("slButtonText")
    m.btnImage = m.top.FindNode("btnImage")
    m.rButtonBackround = m.top.FindNode("rButtonBackround")
    m.Padding = 10
End Sub

Sub SetObservers()
    m.top.observeField("focusedChild", "OnFocusedChild")
End Sub

Sub SetupFonts()
End Sub

Sub SetupColor()
End Sub

sub OnBorderSize()

end sub

sub OnPosterImageDataChange()
    m.btnImage.uri = m.top.posterImage
    if isValid(m.top.posterImageSize)
        size = m.top.posterImageSize
        m.btnImage.height = size
        m.btnImage.width = size
        m.btnImage.loadHeight = size
        m.btnImage.loadWidth = size
    end if
    m.btnImage.visible = true
    SetTranslations()
end sub

Sub OnMarginChange()
    m.slButtonText.Width = m.top.buttonWidth - (m.top.margin * 2) - (m.top.rightExtraPadding)
    m.slButtonText.height = m.top.buttonHeight
    if isValid(m.top.posterImage) AND m.top.posterImage <> ""
    else
        m.slButtonText.translation = [m.top.margin, 0]
    end if
    OnBorderSize()
    SetTranslations()
End Sub

Sub OnPaddingChange()
    m.Padding = m.top.padding
    SetTranslations()
End Sub

Sub OnButtonWidthChange()
    if isValid(m.top.posterImage) AND m.top.posterImage <> ""
        m.slButtonText.Width = m.top.buttonWidth - m.btnImage.width
    else
        m.slButtonText.Width = m.top.buttonWidth
    end if
    OnBorderSize()
    SetTranslations()
End Sub

Sub OnFontSizeChange()
    if isValid(m.top.fontSize) AND m.top.fontSize <> ""
        textFont = m.top.fontSize
        m.slButtonText.font = m.fonts[textFont]
    end if
    SetTranslations()
End Sub

Sub OnButtonTextChange()
    m.slButtonText.text = m.top.buttonText
    SetTranslations()
End Sub

Sub OnButtonHeightChange()
    m.slButtonText.height = m.top.buttonHeight
    SetTranslations()
End Sub

Sub OnBackgroundColorChange()
    m.rButtonBackround.blendColor = m.top.backgroundColor
End Sub

Sub OnUnFocusTextColorChange()
    m.slButtonText.color = m.top.unfocusTextColor
    if isValid(m.top.addColorOnImage) AND m.top.addColorOnImage
        m.btnImage.blendcolor = m.top.unfocusTextColor
    end if
End Sub

Sub OnIsFilledBgOnFocusChange()
    If(m.top.isFilledBgOnFocus)
        m.slButtonText.font = m.fonts.dmSansMedium25
    End IF
End Sub

Sub OnFocusedChild()
    SetFocusItem(m.top.hasFocus())
End Sub

' Boton con icono (.btn: display flex, gap 10px): icono + texto centrados como
' un bloque, el icono centrado en el alto. Se recalcula ante cualquier cambio
' de icono/texto/fuente/medidas porque update() aplica los campos en cualquier
' orden (antes el icono quedaba calculado con alto 0 y se veia corrido abajo).
Sub SetTranslations()
    if not isNonEmptyString(m.top.posterImage) then return
    gap = 10
    padding = m.top.padding
    iconW = m.btnImage.width
    iconH = m.btnImage.height
    m.slButtonText.horizAlign = "left"
    m.slButtonText.vertAlign = "center"
    m.slButtonText.height = m.top.buttonHeight
    ' Se mide en una sola linea: un Label con wrap y sin ancho puede medir 0.
    m.slButtonText.wrap = false
    m.slButtonText.width = 0
    textW = m.slButtonText.boundingRect().width
    x = (m.top.buttonWidth - (iconW + gap + textW)) / 2
    ' Sin medida del texto (aun sin fuente/texto): alineado a la izquierda.
    if textW <= 0 OR x < padding then x = padding
    maxTextW = m.top.buttonWidth - x - iconW - gap - padding
    if textW <= 0 OR textW > maxTextW
        textW = maxTextW
        m.slButtonText.wrap = true
    end if
    m.btnImage.translation = [x, (m.top.buttonHeight - iconH) / 2]
    m.slButtonText.translation = [x + iconW + gap, 0]
    if textW > 0 then m.slButtonText.width = textW
    m.rButtonBackround.width = m.top.buttonWidth
    m.rButtonBackround.loadwidth = m.rButtonBackround.width
End Sub

Sub SetFocusItem(isFocused)
    If isFocused
        m.slButtonText.color = m.top.focusTextColor
        If(m.top.isFilledBgOnFocus)
            m.rButtonBackround.uri = "pkg:/images/focus/R5Filled_30px.9.png"
        Else
            m.rButtonBackround.uri = m.top.backGroundImage
        End If
        m.rButtonBackround.blendColor = m.top.focusBackgroundColor
        m.btnImage.uri = m.top.posterImage
        if isValid(m.top.addColorOnImage) AND m.top.addColorOnImage
            m.btnImage.blendcolor = m.top.focusTextColor
        end if
        ' m.slButtonText.repeatCount = -1
    Else
        m.slButtonText.color = m.top.unfocusTextColor
        m.rButtonBackround.uri = m.top.focusBorderImage
        m.rButtonBackround.blendColor = m.top.backgroundColor
        ' m.slButtonText.repeatCount = 0
        if isNonEmptyString(m.top.unoFcusPosterImage)
            m.btnImage.uri = m.top.unoFcusPosterImage
        end if
        if isValid(m.top.addColorOnImage) AND m.top.addColorOnImage
            m.btnImage.blendcolor = m.top.unfocusTextColor
        end if
    End If
End Sub

Function OnkeyEvent(key as String, press as boolean) as boolean
    result = false
    If press
        Print "CustomButton : onKeyEvent : key = " key " press = " press
        If key = "back"
            result = false
        End If
    End If
    Return result
End Function
