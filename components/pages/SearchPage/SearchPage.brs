sub init()
    print "SearchPage init"
    SetLocals()
    SetControls()
    SetupColor()
    SetupFonts()
    setupPageLoader()
    SetObservers()
    Initialize()
end sub

sub SetLocals()
    m.scene = m.top.GetScene()
    m.fonts = m.global.Fonts
    m.theme = m.global.appTheme
    m.isFirstTime = true
    m.girdTerm = ""
    m.appConfig = m.global.appConfig
    m.cursorText = "|"
    m.cursorVisible = true
    m.term = ""
    m.currentPage = 0
    m.isPagination = false
    m.paginationData = {}
    m.indexValForPagination = 5
end sub

sub SetControls()
    m.searchScene = m.top.findNode("searchScene")
    m.minChar = m.top.findNode("minChar")
    m.resFail = m.top.findNode("resFail")
    m.searchPlaceholderHintText = m.top.findNode("searchPlaceholderHintText")
    m.searchPlaceholderText = m.top.findNode("searchPlaceholderText")
    m.searchGrid = m.top.findNode("searchGrid")
    m.miniKeyboard = m.top.findNode("miniKeyboard")
    m.cursorBlinkTimer = m.top.findNode("cursorBlinkTimer")
    m.miniKeyboard.textEditBox.visible = false
    m.bSearchField = m.top.findNode("bSearchField")
    inputFields = {
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.black 'white
        backgroundColor: m.theme.clrPrimaryButton
        focusBorderImage: m.theme.filledBackGroundImage
        focusBackgroundColor: m.theme.focPrimary
        margin: 20
    }
    m.bSearchField.update(inputFields)
    if(m.global.designResolution = "720p")
        m.searchGrid.focusBitmapUri = "pkg:/images/focus/R5T3_35px_outborder_nopadding.9.png"
    else
        m.searchGrid.focusBitmapUri = "pkg:/images/focus/R8_T3_50PX_border.9.png"
    end if
end sub

sub SetupColor()
    m.searchGrid.focusBitmapBlendColor = m.theme.focPrimary
end sub

sub SetupFonts()
    m.searchPlaceholderHintText.font = m.fonts.dmSansMedium39
    m.searchPlaceholderText.font = m.fonts.dmSansMedium39
    m.searchScene.font = m.fonts.dmSansMedium30
    m.minChar.font = m.fonts.dmSansMedium30
    m.resFail.font = m.fonts.dmSansMedium30
    UpdateSearchFieldText("")
end sub

sub setupPageLoader()
    m.pageLoader = CreateObject("roSGNode", "PageLoader")
    m.pageLoader.id = "pageLoader"
    m.pageLoader.isCenter = "true"
    m.pageLoader.loaderWidth = "100"
    m.pageLoader.pageSpinnerTextTranslation = "[-50,130]" 
    m.pageLoader.showSpinnerText = "CARGANDO..."
    m.pageLoader.textFont = m.fonts.dmSansMedium30
    m.pageLoader.isBackground = "false"
    m.pageLoader.pageTranslation = [1180, 440]
    m.pageLoader.visible = "false"
    m.top.appendChild(m.pageLoader)
end sub

sub SetObservers()
    m.top.observeField("focusedChild", "OnFocusChild")
    m.top.observeField("visible", "onVisibleChange")
    m.miniKeyboard.observeField("text", "OnSearchText")
    m.cursorBlinkTimer.observeField("fire", "OnCursorBlink")
    m.searchGrid.observeField("itemFocused", "OnItemFocus")
    m.searchGrid.observeField("itemSelected", "OnItemVideoSelected")
end sub

sub Initialize()
    ResetVar()
    m.currentPage = 1
    SearchAPICall("")
end sub

sub onVisibleChange()
    if not m.top.visible
        clearTask()
    end if
end sub

sub clearTask()
    if isValid(m.GetSearchProgramsTask)
        m.GetSearchProgramsTask.control = "stop"
        m.GetSearchProgramsTask = invalid
    end if
end sub

sub OnFocusChild()
    if m.top.hasFocus()
        if m.isFirstTime
            SetFocus(m.miniKeyboard)
            m.isFirstTime = false
        else
            RestoreFocus()
        end if
    end if
end sub

sub ResetVar()
    m.minChar.visible = false
    m.searchScene.visible = false
    m.resFail.visible = false
    m.currentPage = 0
    m.isPagination = false
    m.paginationData = {}
end sub

sub OnSearchText()
    m.term = m.miniKeyboard.text
    m.cursorVisible = true
    UpdateSearchFieldText(m.term)
    ClearContentNode()
    if(m.term <> m.lastterm AND m.term <> "")
        if (Len(m.term) >= 3)
            ShowLoading(false)
            if (m.girdTerm = m.term OR m.resFail.visible = false)
                ResetVar()
                m.currentPage = 1
                SearchAPICall(m.term)
            end if
        else if (Len(m.term) >= 1 OR Len(m.term) <= 2)
            ShowLoading(false)
            m.searchScene.visible = false
            m.resFail.visible = false
            m.minChar.visible = true
        else
            ShowLoading(false)
            m.minChar.visible = false
            m.searchScene.visible = true
        end if
    else
        ShowLoading(false)
        m.resFail.visible = false
        m.minChar.visible = false
        m.searchScene.visible = true
        Initialize()
    end if
    m.lastterm = m.term
end sub

sub UpdateSearchFieldText(searchText = "" as string)
    cursor = ""
    if m.cursorVisible then cursor = m.cursorText
    if searchText <> ""
        m.searchPlaceholderHintText.text = ""
        m.searchPlaceholderText.text = searchText + cursor
        m.searchPlaceholderText.color = m.theme.white
    else
        m.searchPlaceholderHintText.text = "Ingresa tu búsqueda"
        m.searchPlaceholderText.text = + cursor
        m.searchPlaceholderText.color = m.theme.clrSecondaryText
    end if
end sub

sub OnCursorBlink()
    m.cursorVisible = not m.cursorVisible
    UpdateSearchFieldText(m.term)
end sub

sub ClearContentNode()
    if isValid(m.searchGrid) AND hasValidGrid()
        m.searchGrid.content.removeChildrenIndex(m.searchGrid.content.getChildCount(), 0)
        m.searchGrid.content = invalid
    end if
end sub

sub SearchAPICall(term as string, page = 1)
    ShowLoading(true)
    params = {}
    params["page"] = page
    if term <> "" then params["search"] = term
    params["client"] = GlobalGet("appConfig").client
    params["limit"] = 12
    m.GetSearchProgramsTask = CreateObject("roSGNode", "ContentAPIAction")
    m.GetSearchProgramsTask.functionName = "GetSearchPrograms"
    m.GetSearchProgramsTask.params = params
    if m.isPagination
        m.GetSearchProgramsTask.ObserveField("result", "onSearchAPIPaginationDataResponse")
    else
        m.GetSearchProgramsTask.ObserveField("result", "onSearchAPIResponse")
    end if
    m.GetSearchProgramsTask.control = "RUN"
end sub

sub onSearchAPIResponse(event as dynamic)
    response = event.getData()
    node = event.getRoSGNode()
    print "onSearchAPIResponse : searchRes : " 'formatjson(response)
    if isValid(response) AND isValid(response.data) AND isValid(response.data.data) AND response.data.data.count() > 0
        programs = response.data.data
        if (programs.count() > 0)
            m.paginationData = {}
            m.paginationData["total_display_records"] = response.data.total_display_records
            m.paginationData["total_records"] = response.data.total_records
            m.paginationData["last_page"] = response.data.last_page
            gridItem = createObject("roSGNode", "contentNode")
            for each vid in programs
                vid.image_orientation = "landscape"
                programItem = gridItem.CreateChild("ProgramItemNode")
                programItem.setFields(vid)
            end for
            m.searchGrid.content = gridItem
            m.girdTerm = m.term
        end if
    else if isInvalid(node.params.search) OR isEmptyString(node.params.search)
        m.searchScene.visible = true
        m.minChar.visible = false
        m.resFail.visible = false
    else
        m.searchScene.visible = false
        m.minChar.visible = false
        m.resFail.visible = true
    end if
    ShowLoading(false)
    m.isPagination = false
    clearTask()
end sub

sub onSearchAPIPaginationDataResponse(event as dynamic)
    response = event.getData()
    if (response.ok AND isValid(response.data) AND isValid(response.data.data) AND response.data.data.count() > 0)
        searchPaginationData = response.data.data
        m.paginationData = {}
        if isValid(response.data.total_display_records) then m.paginationData["total_display_records"] = response.data.total_display_records
        if isValid(response.data.total_records) then m.paginationData["total_records"] = response.data.total_records
        if isValid(response.data.last_page) then m.paginationData["last_page"] = response.data.last_page
        paginationData = []
        for each vid in searchPaginationData
            vid.image_orientation = "landscape"
            programItem = CreateObject("roSGNode", "ProgramItemNode")
            programItem.setFields(vid)
            paginationData.push(programItem)
        end for
        if hasValidGrid()
            m.searchGrid.content.insertChildren(paginationData, m.searchGrid.content.getChildCount())
        end if
    end if
    showLoading(false)
    m.isPagination = false
    clearTask()
end sub

sub OnItemVideoSelected(event as dynamic)
    data = event.GetData()
    childNode = m.searchGrid.content.getChild(data)
    IF (isValid(childNode))
        data = {}
        data.itemData = childNode
        m.scene.callFunc("ShowDetailPage", data, false)
    end if
end sub

sub OnItemFocus(event as dynamic)
    index = event.getData()
    if isValid(index) AND hasValidGrid()
        gridCount = m.searchGrid.content.getChildCount()
        if m.isPagination = false AND isValid(m.paginationData) AND m.paginationData.count() > 0 AND m.paginationData.total_records > 0 AND m.paginationData.total_display_records > 0
            if gridCount - index <= m.indexValForPagination AND m.currentPage <= m.paginationData.last_page AND m.searchGrid.content.getChildCount() < m.paginationData.total_records
                m.isPagination = true
                m.currentPage++
                SearchAPICall(m.term, m.currentPage)
            end if
        end if
    end if
end sub

sub ShowLoading(flag as boolean)
    m.pageLoader.visible = flag
end sub

function hasValidGrid()
    return isValid(m.searchGrid) AND isValid(m.searchGrid.content) AND m.searchGrid.content.getChildCount() > 0
end function

function hasFocusOnMGGrid() as boolean
    return hasValidGrid() AND (m.searchGrid.hasFocus() OR m.searchGrid.isInFocusChain())
end function

function RightKeyEvent()
    result = false
    if (m.miniKeyboard.hasFocus() OR m.miniKeyboard.isInFocusChain())
        SetFocus(m.searchGrid)
        result = true
    end if
    return result
end function

function LeftKeyEvent()
    result = false
    if hasFocusOnMGGrid()
        SetFocus(m.miniKeyboard)
        result = true
    end if
    return result
end function

function BackKeyEvent()
    result = false
    if hasFocusOnMGGrid()
        SetFocus(m.miniKeyboard)
        result = true
    end if
    return result
end function

function OnkeyEvent(key as string, press as boolean) as boolean
    print "SearchPage :onKeyEvent : key" key "press" press
    result = false
    if press
        if key = "right"
            result = RightKeyEvent()
        else if key = "left"
            result = LeftKeyEvent()
        else if key = "back"
            result = BackKeyEvent()
        end if
    end if
    return result
end function
