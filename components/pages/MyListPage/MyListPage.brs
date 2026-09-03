sub Init()
    print "MyListPage Init "
    SetLocals()
    SetControls()
    SetupColor()
    SetupFonts()
    SetObservers()
    Initialize()
end sub

sub SetLocals()
    m.scene = m.top.GetScene()
    m.fonts = m.global.fonts
    m.theme = m.global.appTheme
    initVar()
end sub

sub SetControls()

    m.mylistPageTitle = m.top.findNode("mylistPageTitle")
    m.mylistGrid = m.top.findNode("mylistGrid")
    ' if(m.designResolution = "720p")
    '     m.mylistGrid.focusBitmapUri = "pkg:/images/focus/R12_T4_outside_100px_forHD.9.png"
    ' else
    '     m.mylistGrid.focusBitmapUri = "pkg:/images/focus/R12_T4_outside_100px_forHD.9.png"
    ' end if
    m.mylistGrid.focusBitmapUri = "pkg:/images/focus/R5T3_35px_outborder_nopadding.9.png"
    m.mylistTitle = m.top.findNode("mylistTitle")
    m.mylistSubTitle = m.top.findNode("mylistSubTitle")
    m.gAddItem = m.top.findNode("gAddItem")
    m.pageLoader = m.top.findNode("pageLoader")
    m.pAddtoMylist = m.top.findNode("pAddtoMylist")
    m.lgLogin = m.top.findNode("lgLogin")
    m.loginTitle = m.top.findNode("loginTitle")
    m.loginButton = m.top.findNode("loginButton")
end sub

sub SetupColor()
    m.mylistSubTitle.color = m.theme.white
    m.mylistTitle.color = m.theme.white
    m.mylistSubTitle.color = m.theme.clrSecondaryText
    m.loginTitle.color = m.theme.clrSecondaryText
    m.mylistGrid.focusBitmapBlendColor = m.theme.focPrimary
end sub

sub SetupFonts()
    m.mylistPageTitle.font = m.fonts.dmSansMedium39
    m.mylistTitle.font = m.fonts.dmSansMedium31
    m.mylistSubTitle.font = m.fonts.dmSansMedium24
    m.loginTitle.font = m.fonts.dmSansMedium24
end sub

sub SetObservers()
    m.top.observeField("focusedChild", "OnFocusedChild")
    m.top.observeField("visible", "onVisibleChanged")
    m.gAddItem.observeField("focusedChild", "OnFocuseAddtoMylistImage")
    m.mylistGrid.observeField("itemFocused", "OnMylistItemFocused")
    m.mylistGrid.observeField("itemSelected", "OnMylistItemSelected")
end sub

sub onVisibleChanged()
    if m.top.visible
        RefreshContent()
    else
        clearTask()
    end if
end sub

sub clearTask()
    if isValid(m.GetMyListProgramsTask)
        m.GetMyListProgramsTask.control = "stop"
        m.GetMyListProgramsTask = invalid
    end if
end sub

sub RefreshContent()
    if m.scene.refreshMylistPage
        m.scene.refreshMylistPage = false
        ResetPagination()
        m.currentPage = 1
        GetMyListPrograms(m.currentPage)
    end if
end sub

sub ShowLoading(flag as boolean)
    m.pageLoader.visible = flag
end sub

sub initVar()
    m.currentPage = 0
    m.isPagination = false
    m.paginationData = {}
    m.indexValForPagination = 5
end sub

sub onPageDestroy()
    if m.top.isDestroy
        initVar()
        ResetPagination()
        clearTask()
        if isValid(m.mylistGrid) AND isValid(m.mylistGrid.content)
            m.mylistGrid.content.RemoveChildrenIndex(m.mylistGrid.content.GetChildCount(), 0)
        end if
        m.mylistGrid.content = invalid
    end if
end sub

sub Initialize()
    if m.scene.isUserLoggedIn = false
        btnFields = {
            focusTextColor: m.theme.white
            unfocusTextColor: m.theme.white
            backgroundColor: m.theme.clrSecondary
            focusBorderImage: m.theme.filledBackGroundImage
            focusBackgroundColor: m.theme.focPrimary
            fontSize: "dmSansMedium24"
            margin: 20
        }
        m.loginButton.update(btnFields)
        SetFocus(m.loginButton)
        m.lgLogin.visible = true
    else
        ResetPagination()
        m.currentPage = 1
        GetMyListPrograms(m.currentPage)
    end if
end sub

sub ResetPagination()
    m.currentPage = 0
    m.isPagination = false
    m.paginationData = {}
end sub

sub GetMyListPrograms(page = 1 as Integer)
    ShowLoading(true)
    m.GetMyListProgramsTask = CreateObject("roSGNode", "ContentAPIAction")
    m.GetMyListProgramsTask.functionName = "GetMyListPrograms"
    m.GetMyListProgramsTask.params = {
        page: page
        limit: 20
    }
    if m.isPagination
        m.GetMyListProgramsTask.ObserveField("result", "OnGetMyListProgramsPaginationResponse")
    else
        m.GetMyListProgramsTask.ObserveField("result", "OnGetMyListProgramsResponse")
    end if
    m.GetMyListProgramsTask.control = "RUN"
end sub

sub OnGetMyListProgramsResponse(event as dynamic)
    response = event.getData()
    print "MyListPage OnGetMyListProgramsResponse " 'formatjson(response)
    ClearContentNode()
    if isValid(response) AND isValid(response.data) AND isValid(response.data.data) AND response.data.data.count() > 0
        gridItem = CreateObject("roSGNode", "ContentNode")
        myListData = response.data.data
        UpdatePaginationData(response.data)
        for each vid in myListData
            vid.image_orientation = "landscape"
            programItem = gridItem.CreateChild("ProgramItemNode")
            programItem.setFields(vid)
        end for
        m.mylistGrid.content = gridItem
        m.gAddItem.visible = false
        SetFocus(m.mylistGrid)
    end if
    if not hasValidGrid()
        print "MyList content is not avavilable"
        m.mylistGrid.content = invalid
        m.gAddItem.visible = true
        SetFocus(m.gAddItem)
    end if
    m.isPagination = false
    ShowLoading(false)
    clearTask()
end sub

sub OnGetMyListProgramsPaginationResponse(event as dynamic)
    response = event.getData()
    print "MyListPage OnGetMyListProgramsPaginationResponse " 'formatjson(response)
    if isValid(response) AND isValid(response.data) AND isValid(response.data.data) AND response.data.data.count() > 0
        myListData = response.data.data
        UpdatePaginationData(response.data)
        paginationData = []
        for each vid in myListData
            vid.image_orientation = "landscape"
            programItem = CreateObject("roSGNode", "ProgramItemNode")
            programItem.setFields(vid)
            paginationData.push(programItem)
        end for
        if hasValidGrid()
            m.mylistGrid.content.insertChildren(paginationData, m.mylistGrid.content.getChildCount())
        end if
    end if
    m.isPagination = false
    ShowLoading(false)
    clearTask()
end sub

sub ClearContentNode()
    if isValid(m.mylistGrid) AND hasValidGrid()
        m.mylistGrid.content.removeChildrenIndex(m.mylistGrid.content.getChildCount(), 0)
        m.mylistGrid.content = invalid
    end if
end sub

sub UpdatePaginationData(responseData as Object)
    m.paginationData = {}
    if isValid(responseData.total_display_records) then m.paginationData["total_display_records"] = responseData.total_display_records
    if isValid(responseData.total_records) then m.paginationData["total_records"] = responseData.total_records
    if isValid(responseData.last_page) then m.paginationData["last_page"] = responseData.last_page
end sub

sub OnFocusedChild()
    if m.top.hasFocus()
        focusRestored = RestoreFocus()
        if focusRestored = false
            if m.scene.isUserLoggedIn = false
                SetFocus(m.loginButton)
                m.lgLogin.visible = true
            else 
                if hasValidGrid()
                    SetFocus(m.mylistGrid)
                end if
            end if
        end if
    end if
end sub

sub OnFocuseAddtoMylistImage()
    if m.gAddItem.hasFocus()
        m.pAddtoMylist.blendColor = m.theme.focPrimary
    else
        m.pAddtoMylist.blendColor = m.theme.white
    end if
end sub

sub OnMylistItemSelected(event as dynamic)
    index = event.getData()
    if isValid(m.mylistGrid.content)
        childNode = m.mylistGrid.content.getChild(index)
        print "OnMylistItemSelected : childNode = " childNode
        if isValid(childNode)
            data = {}
            data.itemData = childNode
            m.scene.callFunc("ShowDetailPage", data, false)
        end if
    end if
end sub

sub OnMylistItemFocused(event as dynamic)
    index = event.getData()
    if isValid(index) AND hasValidGrid()
        gridCount = m.mylistGrid.content.getChildCount()
        if m.isPagination = false AND isValid(m.paginationData) AND m.paginationData.count() > 0 AND m.paginationData.total_records > 0 AND m.paginationData.total_display_records > 0
            if gridCount - index <= m.indexValForPagination AND m.currentPage <= m.paginationData.last_page AND m.mylistGrid.content.getChildCount() < m.paginationData.total_records
                m.isPagination = true
                m.currentPage++
                GetMyListPrograms(m.currentPage)
            end if
        end if
    end if
end sub

function hasValidGrid() as Boolean
    return isValid(m.mylistGrid) AND isValid(m.mylistGrid.content) AND m.mylistGrid.content.getChildCount() > 0
end function

Function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false
    if press
        print " Page : MyListPage : onKeyEvent : key = " key " press = " press
        if key = "OK"
            if m.gAddItem.hasFocus()
                m.scene.callFunc("UpdateSelectedTopMenu", 1)
            else if m.loginButton.hasFocus()
                m.scene.callFunc("ShowOnboardingPage", false)
            end if
            handled = true
        end if
    end if
    return handled
End Function
