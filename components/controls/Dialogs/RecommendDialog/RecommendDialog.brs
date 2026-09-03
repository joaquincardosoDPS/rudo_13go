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
end sub

sub SetControls()
    m.backgroundPanel = m.top.findNode("backgroundPanel")
    m.titleLabel = m.top.findNode("titleLabel")
    m.descLabel = m.top.findNode("descLabel")
    m.returnHomeButton = m.top.findNode("returnHomeButton")
    m.rlProgramList = m.top.findNode("rlProgramList")
    if(m.global.designResolution = "720p")
        m.rlProgramList.focusBitmapUri = "pkg:/images/focus/R5T3_35px_outborder_nopadding.9.png"
    else
        m.rlProgramList.focusBitmapUri = "pkg:/images/focus/R8_T3_50PX_border.9.png"
    end if
end sub 

sub SetupFonts()
    m.titleLabel.font = m.fonts.poppinsMedium39
    m.descLabel.font = m.fonts.poppinsMedium24
    m.rlProgramList.rowLabelFont = m.fonts.poppinsMedium29
end sub

sub SetupColor()
    m.backgroundPanel.color = m.theme.clrPrimary
    m.descLabel.color = m.theme.clrSecondaryText
    m.rlProgramList.rowLabelColor = m.theme.white
    m.rlProgramList.focusFootprintBlendColor = m.theme.white
    m.rlProgramList.focusBitmapBlendColor = m.theme.focPrimary 
end sub 

sub SetObservers()
    m.rlProgramList.observeField("rowItemSelected", "RlSItems_RowItemSelected")
    m.rlProgramList.observeField("rowItemFocused", "RlsItems_RowItemFocused")
end sub

sub Initialize()
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
    m.returnHomeButton.update(btnFields)
    m.titleLabel.text = "Lo sentimos," + chr(10) + "no encontramos el contenido que buscas"
    m.descLabel.text = "Te recomendamos volver al home o revisar algunos de estos programas que te podrían interesar"
    callGetRecommendedProgramsAPI()
    SetFocus(m.returnHomeButton)
end sub

sub callGetRecommendedProgramsAPI() 
    m.GetRecommendedProgramsTask = CreateObject("roSGNode", "ContentAPIAction")
    m.GetRecommendedProgramsTask.functionName = "GetRecommendedPrograms"
    m.GetRecommendedProgramsTask.ObserveField("result", "OnRecommendedProgramsResult")
    m.GetRecommendedProgramsTask.control = "RUN"
end sub

sub OnRecommendedProgramsResult(event as dynamic)
    recommendedProgramsAPIRes = event.getData()
    recommendedProgramsRes = getValueFromProps(recommendedProgramsAPIRes, "data.data", {})
    categoryMap = {}
    for each item in recommendedProgramsRes
        if isValid(item) AND isValid(item.name_category)
            cat = "Te recomendamos"
            if NOT categoryMap.DoesExist(cat)
                categoryMap[cat] = []
            end if
            categoryMap[cat].push(item)
        end if
    end for
    mainContent = CreateObject("roSGNode", "ContentNode")
    for each cat in categoryMap
        rowContent = mainContent.CreateChild("ContentNode")
        rowContent.id = cat
        rowContent.title = cat
        for each item in categoryMap[cat]
            item.image_orientation = "landscape"
            itemContent = rowContent.CreateChild("ProgramItemNode")
            itemContent.setFields(item)
        end for
    end for

    m.rlProgramList.content = mainContent
end sub

sub OnVisibleChange()
    if m.top.visible
    end if
end sub

sub OnFocusedChild()
    if m.top.hasFocus()
        focusRestored = RestoreFocus()
        if focusRestored = false
            SetFocus(m.returnHomeButton)
        end if
    end if
end sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false
    if press
        print " Page : RecommendDialog : onKeyEvent : key = " key " press = " press
        if key = "OK"
        else if key = "down"
            if m.returnHomeButton.hasFocus() AND isValid(m.rlProgramList.content) AND isValid(m.rlProgramList.content.getChild(0)) AND m.rlProgramList.content.getChild(0).getChildCount() > 0
                SetFocus(m.rlProgramList)
                m.rlProgramList.rowFocusAnimationStyle = "floatingFocus"
                m.rlProgramList.rowFocusAnimationStyle = "fixedFocus"
                m.rlProgramList.rowFocusAnimationStyle = "floatingFocus"
            end if
            handled = true
        else if key = "up"
            if m.rlProgramList.hasFocus()
                SetFocus(m.returnHomeButton)
            end if
            handled = true
        end if
    end if
    return handled
End Function
