sub init()
    print "ProgramsPage Init "
    setLocals()
    setControls()
    setupColor()
    setupFonts()
    setObservers()
    initialize()
end sub

sub setLocals()
    m.scene = m.top.GetScene()
    m.fonts = m.global.fonts
    m.config = m.global.appConfig
    m.theme = m.global.appTheme
    m.isPagination = false
    m.indexValForPagination = 5
end sub

sub setControls()
    m.shortDetailsViewControl = m.top.findNode("shortDetailsViewControl")
    m.rlProgramList = m.top.findNode("rlProgramList")
    m.pageLoader = m.top.findNode("pageLoader")
    if(m.global.designResolution = "720p")
        m.rlProgramList.focusBitmapUri = "pkg:/images/focus/R5T3_35px_outborder_nopadding.9.png"
    else
        m.rlProgramList.focusBitmapUri = "pkg:/images/focus/R8_T3_50PX_border.9.png"
    end if
    m.noData = m.top.findNode("noData")
end sub

sub setupColor()
    m.rlProgramList.rowLabelColor = m.theme.white
    m.rlProgramList.focusFootprintBlendColor = m.theme.white
    m.rlProgramList.focusBitmapBlendColor = m.theme.focPrimary
    m.noData.color = m.theme.white
end sub

sub setupFonts()
    m.rlProgramList.rowLabelFont = m.fonts.poppinsMedium26
    m.noData.font = m.fonts.poppinsBold32
end sub

sub setObservers()
    m.top.observeField("focusedChild", "OnFocusedChild")
    m.top.observeField("visible", "onVisibleChanged")
    m.rlProgramList.observeField("rowItemSelected", "RlSItems_RowItemSelected")
    m.rlProgramList.observeField("rowItemFocused", "RlsItems_RowItemFocused")
end sub

sub onVisibleChanged()
    if not m.top.visible
        clearTask()
    end if
end sub

sub onPageDestroy()
    if m.top.isDestroy
        clearTask()
        if(m.rlProgramList <> invalid AND m.rlProgramList.content <> invalid AND m.rlProgramList.content.GetChildCount() > 0)
            for i = 0 to m.rlProgramList.content.GetChildCount() - 1
                childRow = m.rlProgramList.content.getChild(i)
                childRow.RemoveChildrenIndex(childRow.GetChildCount(), 0)
            end for
            m.rlProgramList.content.RemoveChildrenIndex(m.rlProgramList.content.GetChildCount(), 0)
            m.rlProgramList.content = invalid
        end if
    end if
end sub

sub clearTask()
    if isValid(m.GetProgramsTask)
        m.GetProgramsTask.control = "stop"
        m.GetProgramsTask = invalid
    end if
end sub

sub OnFocusedChild()
    if m.top.hasFocus()
        focusRestored = RestoreFocus()
        if focusRestored = false
            if isValid(m.rlProgramList.content) AND m.rlProgramList.content.getChild(0).getChildCount() > 0
                SetFocus(m.rlProgramList)
            end if
        end if
    end if
end sub

sub initialize()
    ResetPagination()
    m.currentPage = 1
    callGetProgramsAPI(m.currentPage)
end sub

sub ResetPagination()
    m.currentPage = 0
    m.isPagination = false
    m.paginationData = {}
end sub

sub ShowLoading(flag as boolean)
    m.pageLoader.visible = flag
end sub

sub callGetProgramsAPI(page = 1 as Integer)
    ShowLoading(true)
    m.GetProgramsTask = CreateObject("roSGNode", "ContentAPIAction")
    m.GetProgramsTask.functionName = "GetPrograms"
    m.GetProgramsTask.params = {
        page: page
        limit: 10
    }
    if m.isPagination
        m.GetProgramsTask.ObserveField("result", "OnProgramsPaginationResult")
    else
        m.GetProgramsTask.ObserveField("result", "OnProgramsResult")
    end if
    m.GetProgramsTask.control = "RUN"
end sub

sub OnProgramsResult(event as dynamic)
    programsAPIRes = event.getData()
    programsRes = getValueFromProps(programsAPIRes, "data.data", [])
    if isValid(programsAPIRes) AND programsRes.count() > 0
        UpdatePaginationData(programsAPIRes.data)
        mainContent = CreateObject("roSGNode", "ContentNode")
        for each item in programsRes
            if ((isValid(item.format) AND item.format = "default") OR isInvalid(item.format))
                if isValid(item) AND isValid(item.key) AND isValid(item.programs) AND item.programs.count() > 0
                    rowContent = mainContent.CreateChild("ContentNode")
                    rowContent.title = item.title
                    for each program in item.programs
                        program.image_orientation = "landscape"
                        itemContent = rowContent.CreateChild("ProgramItemNode")
                        itemContent.setFields(program)
                        if rowContent.getChildCount() > 10
                            itemAA = {}
                            itemAA.image_orientation = "landscape"
                            itemAA.category_key = rowContent.key
                            itemAA.format = program.format
                            itemAA.title = "Ver Más"
                            itemAA.isViewMoreCard = true
                            itemContent = CreateObject("roSGNode", "ProgramItemNode")
                            itemContent.setFields(itemAA)
                            rowContent.appendChild(itemContent)
                            exit for
                        end if
                    end for
                end if
            end if
        end for
        m.rlProgramList.content = mainContent
        if isValid(m.rlProgramList.content) AND m.rlProgramList.content.getChild(0).getChildCount() > 0
            SetFocus(m.rlProgramList)
        else
            m.noData.visible = true
            SetFocus(m.noData)
        end if
    else
        m.noData.visible = true
        SetFocus(m.noData)
    end if
    ShowLoading(false)
    clearTask()
end sub

sub OnProgramsPaginationResult(event as dynamic)
    response = event.getData()
    print "ProgramsPage OnGetMyListProgramsPaginationResponse " 'formatjson(response)
    if isValid(response) AND isValid(response.data) AND isValid(response.data.data) AND response.data.data.count() > 0
        programsData = response.data.data
        UpdatePaginationData(response.data)
        paginationData = []
        for each item in programsData
            if ((isValid(item.format) AND item.format = "default") OR isInvalid(item.format))
                if isValid(item) AND isValid(item.key) AND isValid(item.programs) AND item.programs.count() > 0
                    rowContent = CreateObject("roSGNode", "ContentNode")
                    rowContent.title = item.title
                    for each program in item.programs
                        program.image_orientation = "landscape"
                        itemContent = rowContent.CreateChild("ProgramItemNode")
                        itemContent.setFields(program)
                        if rowContent.getChildCount() > 10
                            itemAA = {}
                            itemAA.image_orientation = "landscape"
                            itemAA.category_key = rowContent.key
                            itemAA.format = program.format
                            itemAA.title = "Ver Más"
                            itemAA.isViewMoreCard = true
                            itemContent = CreateObject("roSGNode", "ProgramItemNode")
                            itemContent.setFields(itemAA)
                            rowContent.appendChild(itemContent)
                            exit for
                        end if
                    end for
                    paginationData.push(rowContent)
                end if
            end if
        end for
        if hasValidRowlist()
            m.rlProgramList.content.insertChildren(paginationData, m.rlProgramList.content.getChildCount())
        end if
    end if
    m.isPagination = false
    ShowLoading(false)
    clearTask()
end sub

sub UpdatePaginationData(responseData as Object)
    m.paginationData = {}
    if isValid(responseData.total_display_records) then m.paginationData["total_display_records"] = responseData.total_display_records
    if isValid(responseData.total_records) then m.paginationData["total_records"] = responseData.total_records
    if isValid(responseData.last_page) then m.paginationData["last_page"] = responseData.last_page
end sub

function hasValidRowlist() as Boolean
    return isValid(m.rlProgramList) AND isValid(m.rlProgramList.content) AND m.rlProgramList.content.getChildCount() > 0
end function

sub RlsItems_RowItemSelected(event as object)
    data = event.GetData()
    childNode = m.rlProgramList.content.getChild(data[0]).getChild(data[1])
    if isValid(childNode)
        print "rlProgramList : RlsItems_RowItemSelected : childNode" childNode
        data = {}
        data.itemData = childNode
        if childNode.isViewMoreCard
            m.scene.callFunc("showCategoryDetailPage", data, false)
        else
            m.scene.callFunc("ShowDetailPage", data, false)
        end if
    end if
end sub

sub RlsItems_RowItemFocused(event as object)
    data = event.GetData()
    print "ProgramsPage : RlsItems_RowItemFocused : data : " 'data
    childNode = m.rlProgramList.content.getChild(data[0]).getChild(data[1])
    if isValid(childNode)
        print "rlProgramList : RlsItems_RowItemFocused : childNode" childNode
        m.shortDetailsViewControl.contentNode = childNode
        m.shortDetailsViewControl.visible = true
    end if
    if isValid(data) AND hasValidRowlist()
        gridCount = m.rlProgramList.content.getChild(data[0]).getChildCount()
        if m.isPagination = false AND isValid(m.paginationData) AND m.paginationData.count() > 0 AND m.paginationData.total_records > 0 AND m.paginationData.total_display_records > 0
            if gridCount - data[0] <= m.indexValForPagination AND m.currentPage <= m.paginationData.last_page AND m.rlProgramList.content.getChild(data[0]).getChildCount() < m.paginationData.total_records
                m.isPagination = true
                m.currentPage++
                callGetProgramsAPI(m.currentPage)
            end if
        end if
    end if
end sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false
    if press
        print " Page : MyListPage : onKeyEvent : key = " key " press = " press
        if key = "OK"
            handled = true
        else if key = "back"
            if (m.rlProgramList.IsInFocusChain() OR m.rlProgramList.hasFocus()) AND m.rlProgramList.rowItemFocused <> invalid
                if m.rlProgramList.rowItemFocused[0] > 0
                    m.rlProgramList.jumpToRowItem = [0, 0]
                    handled = true
                end if
            end if
        end if
    end if
    return handled
End Function