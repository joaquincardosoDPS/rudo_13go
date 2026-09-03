Sub Init()
    Print "ExitDialog : Init"
    SetLocals()
    SetControls()
    SetupFonts()
    SetupColors()
    SetObservers()
    Initialize()
End Sub

Sub SetLocals()
    m.theme = m.global.appTheme
    m.fonts = m.global.fonts
End Sub

Sub SetControls()
    m.rBackground = m.top.findNode("rBackground")
    m.pBackgroundImage = m.top.findNode("pBackgroundImage")
    m.topGradient = m.top.findNode("topGradient")
    m.pLogo = m.top.findNode("pLogo")
    m.message = m.top.findNode("message")
    m.bNo = m.top.findNode("bNo")
    m.bExit = m.top.findNode("bPositive")
    m.lgButtons = m.top.findNode("lgButtons")
    m.exitGrp = m.top.findNode("exitGrp")

    m.buttons = []
    m.buttons.push(m.bNo)
    m.buttons.push(m.bExit)
End Sub

Sub SetupFonts()
    m.message.font = m.fonts.poppinsMedium32
End Sub

Sub SetupColors()

    btnFields = {
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.white
        backgroundColor: m.theme.clrSecondary
        focusBackgroundColor: m.theme.focPrimary
        backGroundImage: m.theme.filledBackGroundImage
        focusBorderImage: m.theme.filledBackGroundImage
        isFilledBgOnFocus: true
        fontSize: "poppinsMedium26"
        margin: 10
    }
    m.bNo.update(btnFields)
    m.bExit.update(btnFields)

    m.rBackground.color = m.theme.clrPrimary
    m.message.color = m.theme.white
End Sub

Sub SetObservers()
    m.top.observeField("focusedChild", "OnFocusedChild")
    m.pBackgroundImage.observeField("loadStatus", "OnLoadStatusChanged")
    m.pLogo.observeField("loadStatus", "OnLogoLoadStatusChanged")

    logoImage = GlobalGet("logo")
    if isNonEmptyString(logoImage)
        m.pLogo.uri = logoImage
    end if
    backgroundImage = GlobalGet("backgroundImage")
    if isNonEmptyString(backgroundImage)
        m.pBackgroundImage.uri = backgroundImage
    end if
End Sub

sub OnLoadStatusChanged(event as object)
    status = event.GetData()
    node = event.getRoSGNode()
    if status = "ready"
        imageWidth = node.bitmapWidth
        imageHeight = node.bitmapHeight
        node.width = imageWidth * (node.height / imageHeight) 
        xPos = (1920 - node.width)
        m.pBackgroundImage.translation = [xPos, 0]
        m.topGradient.visible = true
    end if
end sub

sub OnLogoLoadStatusChanged(event as object)
    status = event.GetData()
    node = event.getRoSGNode()
    if status = "ready"
        imageWidth = node.bitmapWidth
        imageHeight = node.bitmapHeight
        node.width = imageWidth * (node.height / imageHeight)
    end if
end sub

Sub OnPositiveButtonTextChanged()
    If isValid(m.bExit)
        m.bExit.buttonText = m.top.positiveButtonText
    End If
End Sub

Sub OnPositiveButtonWidthChanged()
    If isValid(m.bExit)
        m.bExit.buttonWidth = m.top.positiveButtonWidth
    End If
End Sub

Sub Initialize()
    OnPositiveButtonTextChanged()
    OnPositiveButtonWidthChanged()
    m.message.translation = [80, 0]
    buttonsYPos = m.message.BoundingRect().height + 40
    m.lgButtons.translation = [80, buttonsYPos]
    yPos = (1080 - m.exitGrp.BoundingRect().height) / 2
    m.exitGrp.translation = [0, yPos]
End Sub

Sub OnMessageChangedEvent(event as Dynamic)
    data = event.GetData()
    If isValid(data)
        m.message.text = data
        If (isValid(m.bLogout))
            m.buttons.Pop()
            m.bLogout = invalid
        End If
        If m.top.showLogoutButton
            m.bLogout = CreateObject("roSGNode", "CustomButton")
            m.bLogout.id = "bLogout"
            m.bLogout.buttonWidth = "200"
            m.bLogout.buttonHeight = "80"
            m.bLogout.buttonText = "LOG OUT"
            m.bLogout.isFilledBgOnFocus = true
            m.bLogout.focusTextColor = m.theme.white
            m.bLogout.unfocusTextColor = m.theme.white
            m.bLogout.backgroundColor = m.theme.clrSecondary
            m.bLogout.backGroundImage = m.theme.filledBackGroundImage
            m.bLogout.focusBorderImage = m.theme.filledBackGroundImage
            m.bLogout.focusBackgroundColor = m.theme.focPrimary
            m.bLogout.fontSize = "poppinsMedium26"
            m.bLogout.margin = 10
            m.lgButtons.appendChild(m.bLogout)
            m.buttons.push(m.bLogout)
            m.message.text = "Please select required action:"
        End If
    End If
End Sub

Sub SetButton(index as Object, selected as boolean)
    If selected
        m.currentBtn = index
        m.buttons[index].setFocus(true)
    End If
End Sub

Sub OnFocusedChild()
    If m.top.hasFocus()
        SetButton(0, true)
        SetButton(1, false)
        SetButton(2, false)
    End If
End Sub

Function OnKeyEvent(key as String, press as boolean) as boolean
    If press
        Print "ExitDialog : Key = " key " Press = " press
        If key = "back"
            m.top.selectedButton = 0
        Else If key = "OK"
            m.top.selectedButton = m.currentBtn
        Else If key = "left"
            If isValid(m.bLogout) AND m.bLogout.hasFocus() AND m.bExit.visible
                SetButton(0, false)
                SetButton(1, true)
                SetButton(2, false)
            Else If m.bExit.hasFocus() AND m.bNo.visible
                SetButton(0, true)
                SetButton(1, false)
                SetButton(2, false)
            End If
        Else If key = "right"
            If m.bNo.hasFocus() AND m.bExit.visible
                SetButton(0, false)
                SetButton(1, true)
                SetButton(2, false)
            Else If isValid(m.bLogout) AND m.bExit.hasFocus() AND m.bLogout.visible
                SetButton(0, false)
                SetButton(1, false)
                SetButton(2, true)
            End If
        End If
    End If

    Return true
End Function
