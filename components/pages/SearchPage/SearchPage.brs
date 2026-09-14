sub init()
    setLocals()
    setControls()
    setupFonts()
    setupColors()
    setObservers()
    initialize()
end sub

sub setLocals()
    m.scene = m.top.GetScene()
    m.theme = m.global.appTheme
    m.fonts = m.global.Fonts
    m.allPrograms = []
    m.term = ""
    m.focusArea = "keyboard"
    m.keyFocus = 0
    m.keyData = []
    m.hasResults = false
    m.maxResults = 50
    m.numColumns = 4
    m.loaded = false
    m.numKeyRows = 7
end sub

sub setControls()
    m.gKeyboard = m.top.findNode("gKeyboard")
    m.gKeys = m.top.findNode("gKeys")
    m.pInputBg = m.top.findNode("pInputBg")
    m.lInput = m.top.findNode("lInput")
    m.lEmpty = m.top.findNode("lEmpty")
    m.lNoResults = m.top.findNode("lNoResults")
    m.lNoResultsHint = m.top.findNode("lNoResultsHint")
    m.searchGrid = m.top.findNode("searchGrid")
    m.bsLoading = m.top.findNode("bsLoading")
end sub

sub setupFonts()
    m.lInput.font = m.fonts.dmSansMedium23
    m.lEmpty.font = m.fonts.dmSansBold36
    m.lNoResults.font = m.fonts.dmSansBold36
    m.lNoResultsHint.font = m.fonts.dmSansMedium23
end sub

sub setupColors()
    m.lInput.color = "#8C8C8C"
    m.lEmpty.color = m.theme.white
    m.lNoResults.color = m.theme.white
    m.lNoResultsHint.color = m.theme.clrSecondaryText
    m.searchGrid.focusBitmapBlendColor = m.theme.focPrimary
end sub

sub setObservers()
    m.top.observeField("focusedChild", "onFocusedChild")
    m.searchGrid.observeField("itemSelected", "onResultSelected")
    m.searchGrid.observeField("exitToKeyboard", "onExitToKeyboard")
end sub

sub initialize()
    buildKeyboard()
    updateInputLabel()
    showLoading(true)
    getSearchData()
end sub

sub onPageDestroy()
    if m.top.isDestroy AND isValid(m.searchTask)
        m.searchTask.control = "stop"
        m.searchTask = invalid
    end if
end sub

sub buildKeyboard()
    m.gKeys.removeChildrenIndex(m.gKeys.getChildCount(), 0)
    m.keyData = []
    keyW = 47
    gap = 7
    keyH = 65
    rowGap = 5
    rows = [
        ["a", "b", "c", "d", "e", "f"],
        ["g", "h", "i", "j", "k", "l"],
        ["m", "n", "ñ", "o", "p", "q"],
        ["r", "s", "t", "u", "v", "w"],
        ["x", "y", "z", "1", "2", "3"],
        ["4", "5", "6", "7", "8", "9"],
        ["0", "SPACE", "DEL"]
    ]
    for r = 0 to rows.count() - 1
        row = rows[r]
        col = 0
        for each char in row
            span = 1
            if char = "SPACE" then span = 3
            if char = "DEL" then span = 2
            keyNode = createObject("roSGNode", "SearchKey")
            keyNode.keyChar = char
            keyNode.keyWidth = span * keyW + (span - 1) * gap
            keyNode.keyHeight = keyH
            keyNode.itemHasFocus = false
            keyNode.translation = [col * (keyW + gap), r * (keyH + rowGap)]
            m.gKeys.appendChild(keyNode)
            m.keyData.push({ char: char, row: r, col: col, span: span, node: keyNode })
            col = col + span
        end for
    end for
    m.keyFocus = 0
    applyKeyFocus()
end sub

sub getSearchData()
    m.searchTask = CreateObject("roSGNode", "ContentAPIAction")
    m.searchTask.functionName = "GetJsonByUrl"
    m.searchTask.params = { "url": m.global.apiEndPoints.GetSearch }
    m.searchTask.observeField("result", "OnSearchDataResponse")
    m.searchTask.control = "RUN"
end sub

sub OnSearchDataResponse(event as dynamic)
    apiResponse = event.getData()
    rawPrograms = getValueFromProps(apiResponse, "data.programs", [])
    m.allPrograms = []
    for each raw in rawPrograms
        if isNonEmptyString(raw.title)
            m.allPrograms.push({
                "title": raw.title
                "image": raw.image
                "id": raw.id
                "url": raw.url
            })
        end if
    end for
    m.searchTask = invalid
    m.loaded = true
    showLoading(false)
    applyFilter()
    setFocusToKeyboard()
end sub

sub applyFilter()
    m.lEmpty.visible = false
    m.lNoResults.visible = false
    m.lNoResultsHint.visible = false
    m.searchGrid.visible = false
    if m.term = ""
        m.searchGrid.content = invalid
        m.hasResults = false
        m.lEmpty.visible = true
        return
    end if
    query = LCase(m.term)
    content = createObject("roSGNode", "ContentNode")
    count = 0
    for each program in m.allPrograms
        if count >= m.maxResults then exit for
        if Instr(1, LCase(program.title), query) > 0
            itemNode = content.createChild("ContentNode")
            itemNode.setFields({ "title": program.title })
            itemNode.addFields({ "image": program.image, "key": program.id })
            count = count + 1
        end if
    end for
    m.hasResults = (count > 0)
    if count = 0
        m.searchGrid.content = invalid
        m.lNoResults.visible = true
        m.lNoResultsHint.visible = true
    else
        m.searchGrid.content = content
        m.searchGrid.visible = true
        m.searchGrid.jumpToItem = 0
    end if
    if m.focusArea = "results" AND not m.hasResults
        setFocusToKeyboard()
    end if
end sub

sub updateInputLabel()
    if m.term = ""
        m.lInput.text = "Buscar..."
        m.lInput.color = "#8C8C8C"
    else
        m.lInput.text = m.term
        m.lInput.color = m.theme.white
    end if
end sub

sub handleKeyPress(char as string)
    if char = "DEL"
        if Len(m.term) > 0 then m.term = Left(m.term, Len(m.term) - 1)
    else if char = "SPACE"
        m.term = m.term + " "
    else
        m.term = m.term + char
    end if
    updateInputLabel()
    applyFilter()
end sub

sub showLoading(flag as boolean)
    m.bsLoading.visible = flag
end sub

sub applyKeyFocus()
    for i = 0 to m.keyData.count() - 1
        m.keyData[i].node.itemHasFocus = (i = m.keyFocus)
    end for
end sub

sub setFocusToKeyboard()
    m.focusArea = "keyboard"
    m.gKeyboard.setFocus(true)
    applyKeyFocus()
end sub

sub setFocusToResults()
    if not m.hasResults then return
    m.focusArea = "results"
    m.searchGrid.setFocus(true)
end sub

sub onFocusedChild()
    if not m.loaded then return
    if m.top.hasFocus() AND m.top.isInFocusChain()
        if m.focusArea = "results" AND m.hasResults
            m.searchGrid.setFocus(true)
        else
            setFocusToKeyboard()
        end if
    else if not m.top.isInFocusChain()
        clearKeyFocus()
    end if
end sub

sub clearKeyFocus()
    for i = 0 to m.keyData.count() - 1
        m.keyData[i].node.itemHasFocus = false
    end for
end sub

sub onExitToKeyboard()
    setFocusToKeyboard()
end sub

sub onResultSelected(event as dynamic)
    index = event.getData()
    if isValid(m.searchGrid.content) AND index >= 0 AND index < m.searchGrid.content.getChildCount()
        childNode = m.searchGrid.content.getChild(index)
        data = { "itemData": childNode }
        m.scene.callFunc("showDetailPage", data, false)
    end if
end sub

function findKeyInRow(row as integer, col as integer) as integer
    for i = 0 to m.keyData.count() - 1
        k = m.keyData[i]
        if k.row = row AND col >= k.col AND col < k.col + k.span then return i
    end for
    return -1
end function

function findNearestInRow(row as integer, center as float) as integer
    best = -1
    bestDist = 999
    for i = 0 to m.keyData.count() - 1
        k = m.keyData[i]
        if k.row = row
            kc = k.col + Int((k.span - 1) / 2)
            d = Abs(kc - center)
            if d < bestDist
                bestDist = d
                best = i
            end if
        end if
    end for
    return best
end function

function moveKeyLeft() as boolean
    k = m.keyData[m.keyFocus]
    if k.col = 0 then return false
    idx = findKeyInRow(k.row, k.col - 1)
    if idx >= 0
        m.keyFocus = idx
        applyKeyFocus()
    end if
    return true
end function

function moveKeyRight() as boolean
    k = m.keyData[m.keyFocus]
    endCol = k.col + k.span
    if endCol >= 6
        if m.hasResults then setFocusToResults()
        return true
    end if
    idx = findKeyInRow(k.row, endCol)
    if idx >= 0
        m.keyFocus = idx
        applyKeyFocus()
    end if
    return true
end function

function moveKeyVertical(direction as integer) as boolean
    k = m.keyData[m.keyFocus]
    targetRow = k.row + direction
    if targetRow < 0 OR targetRow >= m.numKeyRows then return true
    center = k.col + (k.span - 1) / 2
    idx = findKeyInRow(targetRow, Int(center))
    if idx < 0 then idx = findNearestInRow(targetRow, center)
    if idx >= 0
        m.keyFocus = idx
        applyKeyFocus()
    end if
    return true
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if not m.loaded then return false
    if m.focusArea = "results" then return false
    if key = "OK"
        if m.keyFocus >= 0 AND m.keyFocus < m.keyData.count()
            handleKeyPress(m.keyData[m.keyFocus].char)
        end if
        return true
    else if key = "left"
        return moveKeyLeft()
    else if key = "right"
        return moveKeyRight()
    else if key = "up"
        return moveKeyVertical(-1)
    else if key = "down"
        return moveKeyVertical(1)
    end if
    return false
end function
