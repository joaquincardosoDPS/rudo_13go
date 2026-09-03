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
end sub

Sub OnMarginChange()
    m.slButtonText.Width = m.top.buttonWidth - (m.top.margin * 2) - (m.top.rightExtraPadding)
    m.slButtonText.height = m.top.buttonHeight
    if isValid(m.top.posterImage) AND m.top.posterImage <> ""
    else
        m.slButtonText.translation = [m.top.margin, 0]
    end if
    OnBorderSize()
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
End Sub

Sub OnButtonHeightChange()
    m.slButtonText.height = m.top.buttonHeight
    ' brButtonBackround = m.rButtonBackround.boundingRect()
    btnImageRect = m.btnImage.boundingRect()
    yPos = (m.top.buttonHeight - btnImageRect.width) / 2
    m.btnImage.translation = [m.Padding, yPos]
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
        m.slButtonText.font = m.fonts.poppinsMedium25
    End IF
End Sub

Sub OnFocusedChild()
    SetFocusItem(m.top.hasFocus())
End Sub

Sub SetTranslations()
    if isNonEmptyString(m.top.posterImage)
        Xpos = m.Padding
        btnImageRect = m.btnImage.boundingRect()
        yPos = (m.top.buttonHeight - btnImageRect.height) / 2
        m.btnImage.translation = [Xpos, yPos]
        slButtonText = m.slButtonText.boundingRect()
        m.slButtonText.translation = [Xpos + 50, 0]
        m.slButtonText.height = m.top.buttonHeight
        if isValid(m.btnImage) AND m.btnImage.visible AND (m.btnImage.width + m.btnImage.translation[0] + slButtonText.width) > m.top.buttonWidth
            m.slButtonText.width = m.top.buttonWidth - (m.btnImage.width + (m.slButtonText.translation[0] - 30))
        else
            m.slButtonText.width = (slButtonText.width + (Xpos * 2))
        end if
        m.rButtonBackround.width = m.top.buttonWidth 'slButtonText.width + (Xpos * 2) + btnImageRect.width
        m.rButtonBackround.loadwidth = m.rButtonBackround.width
        m.slButtonText.horizAlign = "left"
        m.slButtonText.vertAlign = "center"
    end if
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
