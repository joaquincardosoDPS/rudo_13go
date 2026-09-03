sub Init()
    print "AccountPage Init "
    SetLocals()
    SetControls()
    SetupFonts()
    SetupColor()
    SetObservers()
    Initialize()
end sub

sub SetLocals()
    m.scene = m.top.GetScene()
    m.fonts = m.global.fonts
    m.theme = m.global.appTheme
    m.scene.callFunc("ShowHideLoader", false)
    m.userData = GlobalGet("UserData")
    m.profileData = m.scene.profileData
end sub

sub SetControls()
    m.backgroundPanel = m.top.findNode("backgroundPanel")
    m.brandLogo = m.top.findNode("brandLogo")
    m.bgPoster = m.top.findNode("bgPoster")
    m.backButton = m.top.findNode("backButton")
    m.titleLabel = m.top.findNode("titleLabel")
    m.accountLayout = m.top.findNode("accountLayout")
    m.borderMask = m.top.findNode("borderMask")
    m.poster = m.top.findNode("poster")
    maskSize = [m.poster.width, m.poster.height]
    if m.global.designresolution = "720p"
        maskSize = [maskSize[0] / 1.5, maskSize[1] / 1.5]
    end if
    m.borderMask.maskSize = maskSize
    m.lProfileName = m.top.findNode("lProfileName")
    m.lName = m.top.findNode("lName")
    m.lEmail = m.top.findNode("lEmail")
    m.lGender = m.top.findNode("lGender")
    m.lBirthdate = m.top.findNode("lBirthdate")
    m.logoutButton = m.top.findNode("logoutButton")
end sub 

sub SetupFonts()
    m.titleLabel.font = m.fonts.poppinsMedium29
    m.lProfileName.font = m.fonts.poppinsMedium20
    m.lName.font = m.fonts.poppinsMedium20
    m.lEmail.font = m.fonts.poppinsMedium20
    m.lGender.font = m.fonts.poppinsMedium20
    m.lBirthdate.font = m.fonts.poppinsMedium20
end sub

sub SetupColor()
    m.backgroundPanel.color = m.theme.clrPrimary
    m.titleLabel.color = m.theme.white
    m.bgPoster.blendColor = m.theme.clrSecondary
    m.lProfileName.color = m.theme.white
    m.lName.color = m.theme.white
    m.lEmail.color = m.theme.white
    m.lGender.color = m.theme.white
    m.lBirthdate.color = m.theme.white
end sub 

sub SetObservers()
    m.top.observeField("visible", "OnVisibleChange")
    m.top.observeField("focusedChild", "OnFocusedChild")
    m.brandLogo.observeField("loadStatus", "OnLogoLoadStatusChanged")
    logoImage = GlobalGet("logo")
    if isNonEmptyString(logoImage)
        m.brandLogo.uri = logoImage
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

sub Initialize()
    print "User Data ::: " m.userData
    if isNotEmptyAA(m.userData)
        if IsNonEmptyString(m.profileData.profileUri)
            m.poster.uri = m.profileData.profileUri
        else
            m.poster.uri = "pkg:/images/other/default_user.png"
        end if
        if IsNonEmptyString(m.profileData.profileName)
            m.lProfileName.text = m.profileData.profileName
        else
            m.lProfileName.text = "Por defecto"
        end if
        fields = [
            { key: "name", node: m.lName },
            { key: "email", node: m.lEmail },
            { key: "gender", node: m.lGender },
            { key: "birthdate", node: m.lBirthdate }
        ]
        for each item in fields
            value = m.userData.Lookup(item.key)
            if isNonEmptyString(value)
                item.node.text = value
                if item.key = "birthdate"
                    item.node.text = getSpanishFormattedDate(value)
                end if
                if item.key = "gender"
                    if value = "m"
                        item.node.text = "Masculino"
                    else
                        item.node.text = "Femenino"
                    end if
                end if
            else
                m.accountLayout.removeChild(item.node)
            end if
        end for
    end if
    btnFields = {
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.white
        backgroundColor: m.theme.clrSecondary
        focusBorderImage: m.theme.filledBackGroundImage
        focusBackgroundColor: m.theme.focPrimary
        fontSize: "poppinsMedium24"
        padding: 20
        posterImageSize: "35"
        margin: 18
    }
    m.backButton.update(btnFields)
    m.logoutButton.update(btnFields)
    brLGAccountLayout = m.accountLayout.boundingRect()
    m.logoutButton.translation = [825, brLGAccountLayout.y + brLGAccountLayout.height + 50]
    SetFocus(m.logoutButton)
end sub

sub OnVisibleChange()
    if m.top.visible
        SetFocus(m.logoutButton)
    end if
end sub

sub OnFocusedChild()
    if m.top.hasFocus()
        SetFocus(m.logoutButton)
    end if
end sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false
    if press
        print " Page : AccountPage : onKeyEvent : key = " key " press = " press
        if key = "OK"
            if m.backButton.hasFocus()
                handled = m.scene.callFunc("HandleBackKey")
            else if m.logoutButton.hasFocus()
                m.scene.callFunc("OnLogout")
                handled = true
            end if
        else if key = "up"
            if m.logoutButton.hasFocus()
                SetFocus(m.backButton)
            end if
            handled = true
        else if key = "down"
            if m.backButton.hasFocus()
                SetFocus(m.logoutButton)
            end if
            handled = true
        end if
    end if
    return handled
End Function
