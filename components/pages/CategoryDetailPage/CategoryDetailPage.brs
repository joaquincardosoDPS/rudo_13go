sub Init()
    print "CategoryDetailPage Init "
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
    m.currentPage = 0
    m.paginationData = {}
    m.isPagination = false
    m.scene.hasTopMenuBackground = false
end sub

sub SetControls()
    m.lCategoryTitle = m.top.findNode("lCategoryTitle")
    m.lTotalCount = m.top.findNode("lTotalCount")
    m.mgPrograms = m.top.findNode("mgPrograms")
    if(m.global.designResolution = "720p")
        m.mgPrograms.focusBitmapUri = "pkg:/images/focus/R5T3_35px_outborder_nopadding.9.png"
    else
        m.mgPrograms.focusBitmapUri = "pkg:/images/focus/R8_T3_50PX_border.9.png"
    end if
    m.pageLoader = m.top.findNode("pageLoader")
    m.cmViewMore = m.top.findNode("cmViewMore")

    btnFields = {
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.white
        backgroundColor: m.theme.clrSecondary
        focusBorderImage: m.theme.filledBackGroundImage
        focusBackgroundColor: m.theme.focPrimary
        fontSize: "dmSansMedium24"
        margin: 20
    }
    m.cmViewMore.update(btnFields)
    boundingRect = m.cmViewMore.BoundingRect()
    xPos = ((1920) - boundingRect.width) / 2
    yPos = (1080 - (boundingRect.height + 50))
    m.cmViewMore.translation = [xPos, yPos]
end sub

sub SetupColor()
    m.lCategoryTitle.color = m.theme.white
    m.lTotalCount.color = "#576872"
    m.mgPrograms.focusBitmapBlendColor = m.theme.focPrimary
end sub

sub SetupFonts()
    m.lCategoryTitle.font = m.fonts.dmSansMedium39
    m.lTotalCount.font = m.fonts.dmSansMedium24
end sub

sub SetObservers()
    m.top.observeField("focusedChild", "OnFocusedChild")
    m.mgPrograms.observeField("itemSelected", "MgItems_ItemSelected")
    m.mgPrograms.observeField("itemFocused", "MgItems_ItemFocused")
end sub

sub ShowLoading(flag as boolean)
    m.pageLoader.visible = flag
end sub

sub Initialize()
end sub

sub onContentInfoChanged()
    print "onContentInfoChanged : contentNode : " m.top.contentNode
    if isValid(m.top.contentNode) AND isValid(m.top.contentNode.itemData.category_key)
        m.lCategoryTitle.text = m.top.contentNode.sliderId
        m.currentPage = 0
        m.isPagination = false
        m.paginationData = {}
        GetAllPrograms()
    end if
end sub

sub GetAllPrograms()
    ShowLoading(true)
    if isValid(m.GetAllProgramsTask) AND m.GetAllProgramsTask.state = "run"
        m.GetAllProgramsTask.control = "STOP"
        m.GetAllProgramsTask = invalid
    end if
    params = {}
    m.currentPage++
    params["client"] = GlobalGet("appConfig").client
    params["category"] = m.top.contentNode.itemData.category_key
    params["page"] = m.currentPage
    params["limit"] = 20
    print "GetAllPrograms : params : " params
    m.GetAllProgramsTask = CreateObject("roSGNode", "ContentAPIAction")
    m.GetAllProgramsTask.functionName = "GetAllPrograms"
    m.GetAllProgramsTask.params = params
    if m.isPagination
        m.GetAllProgramsTask.ObserveField("result", "OnGetAllProgramsPaginationDataResponse")
    else
        m.GetAllProgramsTask.ObserveField("result", "OnGetAllProgramsResponse")
    end if
    m.GetAllProgramsTask.control = "RUN"
end sub

sub OnGetAllProgramsResponse(event as dynamic)
    response = event.getData()
    print "OnGetAllProgramsResponse " 'formatjson(response)
    if isValid(response) AND isValid(response.data) AND isValid(response.data.data) AND response.data.data.count() > 0
        gridItem = CreateObject("roSGNode", "ContentNode")
        programsListData = response.data.data
        m.paginationData = {}
        m.paginationData["total_display_records"] = response.data.total_display_records
        m.paginationData["total_records"] = response.data.total_records
        m.lTotalCount.text = response.data.total_records.toStr() + " programas"
        m.paginationData["last_page"] = response.data.last_page
        for each vid in programsListData
            vid.image_orientation = "landscape"
            programItem = gridItem.CreateChild("ProgramItemNode")
            programItem.setFields(vid)
        end for
        m.mgPrograms.content = gridItem
        SetFocus(m.mgPrograms)
        checkAndShowViewMoreButton()
    end if
    if isInvalid(m.mgPrograms.content) OR m.mgPrograms.content.getChildCount() = 0
        print "ProgramsList content is not avavilable"
        m.mgPrograms.content = invalid
    end if
    m.isPagination = false
    ShowLoading(false)
    print "OnGetAllProgramsResponse : currentPage : " m.currentPage
end sub

sub OnGetAllProgramsPaginationDataResponse(event as dynamic)
    response = event.getData()
    print "OnGetAllProgramsPaginationDataResponse " 'formatjson(response)
    if isValid(response) AND isValid(response.data) AND isValid(response.data.data) AND response.data.data.count() > 0
        programsListData = response.data.data
        m.paginationData["total_display_records"] = response.data.total_display_records
        m.paginationData["total_records"] = response.data.total_records
        m.paginationData["last_page"] = response.data.last_page
        totalItems = programsListData.count() - 1
        paginationData = []
        for i = 0 to totalItems
            item = programsListData[i]
            item.image_orientation = "landscape"
            programItem = CreateObject("roSGNode", "ProgramItemNode")
            programItem.setFields(item)
            paginationData.push(programItem)
        end for
        if isValid(m.mgPrograms) AND isValid(m.mgPrograms.content)
            m.mgPrograms.content.insertChildren(paginationData, m.mgPrograms.content.getChildCount())
        end if
        SetFocus(m.mgPrograms)
        checkAndShowViewMoreButton()
    end if
    if isInvalid(m.mgPrograms.content) OR m.mgPrograms.content.getChildCount() = 0
        print "ProgramsList content is not avavilable"
        m.mgPrograms.content = invalid
    end if
    m.isPagination = false
    ShowLoading(false)
end sub

sub checkAndShowViewMoreButton()
    if isValid(m.paginationData) AND m.paginationData.count() > 0 AND m.paginationData.total_records > 0 AND m.paginationData.total_display_records > 0
        if m.currentPage <= m.paginationData.last_page AND hasValidGrid() AND m.mgPrograms.content.getChildCount() < m.paginationData.total_records
            m.cmViewMore.visible = true
        else
            m.cmViewMore.visible = false
        end if
    end if
end sub

sub OnFocusedChild()
    if m.top.hasFocus()
        focusRestored = RestoreFocus()
        if focusRestored = false
            if hasValidGrid()
                SetFocus(m.mgPrograms)
            end if
        end if
    end if
end sub

sub MgItems_ItemFocused(event as dynamic)
    index = event.GetData()
    if isValid(index) AND hasValidGrid()
        ' gridCount = m.mgPrograms.content.getChildCount()
    end if
end sub

function hasValidGrid()
    return isValid(m.mgPrograms) AND isValid(m.mgPrograms.content) AND m.mgPrograms.content.getChildCount() > 0
end function

function hasFocusOnMGGrid() as boolean
    return hasValidGrid() AND (m.mgPrograms.hasFocus() OR m.mgPrograms.isInFocusChain())
end function

sub MgItems_ItemSelected(event as dynamic)
    index = event.getData()
    print "OnProgramsListItemSelected : childNode = " index
    if isValid(index) AND hasValidGrid() AND isValid(m.mgPrograms.content.getChild(index))
        childNode = m.mgPrograms.content.getChild(index)
        itemSelected = {
            "itemData": childNode
            "sliderId": m.top.id
            "lastSelectedNodeIndex": index
        }
        m.scene.callFunc("showDetailPage", itemSelected, false)
    end if
end sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false
    if press
        print " Page : CategoryDetailPage : onKeyEvent : key = " key " press = " press
        if key = "back"
            m.scene.hasTopMenuBackground = true
        else if key = "OK"
            if isValid(m.cmViewMore) AND m.cmViewMore.visible AND m.cmViewMore.hasFocus() AND m.isPagination = false
                m.isPagination = true
                GetAllPrograms()
            end if
            handled = true
        else if key = "up"
            if isValid(m.cmViewMore) AND m.cmViewMore.visible AND m.cmViewMore.hasFocus() AND hasValidGrid()
                SetFocus(m.mgPrograms)
            end if
            handled = true
        else if key = "down"
            if isValid(m.cmViewMore) AND m.cmViewMore.visible AND hasFocusOnMGGrid()
                SetFocus(m.cmViewMore)
            end if
            handled = true
        end if
    end if
    return handled
End Function
