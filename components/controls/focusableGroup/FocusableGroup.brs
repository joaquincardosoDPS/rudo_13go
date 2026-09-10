sub init()
    setLocals()
    setControls()
    setObservers()
end sub

sub SetLocals()
    m.libScene = m.top.GetScene().findNode("SDKMainPageScene")
    m.theme = m.global.appTheme
    m.fonts = m.global.Fonts
    m.scene = m.top.getScene()
end sub

sub setControls()
    m.gContainer = m.top.findNode("gContainer")
    m.slideAnimation = m.top.findNode("slideAnimation")
    m.slideVector2D = m.top.findNode("slideVector2D")
    m.focusComponentIndex = 0
    m.isFirstTime = true
    m.isReRenderUI = false
    m.heroSliderNode = invalid
end sub

sub setObservers()
    m.top.observeField("focusedChild", "onFocusedChild")
end sub

sub setTranslation(componentNode as object)
    if isTopHeroNode(componentNode)
        m.heroSliderNode = componentNode
    end if

    if m.gContainer.getChildCount() = 0
        if (isValid(componentNode) AND componentNode.subType() = "SliderView")
            componentNode.translation = [0, m.top.rowSpacing]
        else
            componentNode.translation = [0, 0]
        end if
    else
        totalHeight = 0
        for i = 0 to m.gContainer.getChildCount() - 1
            compNode = m.gContainer.getChild(i)
            if (i = 0 AND compNode.subType() = "SliderView")
                totalHeight += m.top.rowSpacing
            end if
            totalHeight += compNode.componentHeight
            totalHeight += m.top.rowSpacing
        end for
        componentNode.translation = [0, totalHeight]
    end if
    m.gContainer.appendChild(componentNode)
end sub

sub removeNode(componentNode as dynamic)
    if isValid(componentNode)
        m.gContainer.removeChild(componentNode)
    end if
end sub

sub clearNodes()
    m.isReRenderUI = true
    m.gContainer.removeChildrenIndex(m.gContainer.getChildCount(), 0)
    m.heroSliderNode = invalid
end sub

function getContainerChildCount() as integer
    return m.gContainer.getChildCount()
end function

function getFirstContentIndex() as integer
    childCount = getContainerChildCount()
    if childCount <= 0 then return 0

    firstNode = m.gContainer.getChild(0)
    if isTopHeroNode(firstNode) AND childCount > 1
        return 1
    end if

    return 0
end function

function getFocusComponentIndex() as integer
    childCount = getContainerChildCount()
    if childCount <= 0 then return 0

    if m.focusComponentIndex < 0 then m.focusComponentIndex = 0
    maxIndex = childCount - 1
    if m.focusComponentIndex > maxIndex then m.focusComponentIndex = maxIndex

    return m.focusComponentIndex
end function

function focusToFirstRow() as boolean
    if getContainerChildCount() <= 0 then return false
    return focusToIndex(getFirstContentIndex())
end function

function focusToHeroSlider() as boolean
    if getContainerChildCount() <= 0 then return false

    heroIndex = getHeroSliderIndex(true)
    if heroIndex >= 0
        return focusToIndex(heroIndex)
    end if

    return focusToIndex(0)
end function

function focusToIndex(targetIndex as integer) as boolean
    childCount = getContainerChildCount()
    if childCount = 0 then return false

    if targetIndex < 0 then targetIndex = 0
    maxIndex = childCount - 1
    if targetIndex > maxIndex then targetIndex = maxIndex

    targetNode = m.gContainer.getChild(targetIndex)
    if isValid(targetNode) = false then return false

    currentIndex = getFocusComponentIndex()
    currentNode = m.gContainer.getChild(currentIndex)
    if currentIndex <> targetIndex AND isValid(currentNode)
        direction = "down"
        if targetIndex < currentIndex
            direction = "up"
        end if
        slidePanel(direction, targetNode)
    end if

    m.focusComponentIndex = targetIndex
    setFocus(targetNode)
    if isValid(currentNode) AND currentIndex <> targetIndex then setNodeFocusState(currentNode, false)
    setNodeFocusState(targetNode, true)
    return showHideSlider(targetNode)
end function

function showHideSlider(targetNode as dynamic)
    if isTopHeroNode(targetNode)
        setHeroImageHidden(false)
    else
        setHeroImageHidden(true)
    end if
    return true
end function

sub onFocusedChild()
    if (m.top.hasFocus())
        if (m.isFirstTime OR m.isReRenderUI = true)
            m.isFirstTime = false
            m.isReRenderUI = false
            if (m.gContainer.getChildCount() > 0)
                targetIndex = getFirstContentIndex()
                compNode = m.gContainer.getChild(targetIndex)
                setFocus(compNode)
                setNodeFocusState(compNode, true)
                m.focusComponentIndex = targetIndex
                if isTopHeroNode(compNode)
                    setHeroImageHidden(false)
                end if
            end if
        else if not m.isFirstTime
            restoreFocus()
        end if
    end if
end sub

' sub onKeyPress(event as dynamic)
'     key = event.getData()
'     if key = "down"
'         onKeyPressDown()
'     else if key = "up"
'         onKeyPressUp()
'     end if
' end sub

function isTopHeroNode(node as dynamic) as boolean
    return isValid(node) AND node.subType() = "HeroSlider" AND node.variant = "compact"
end function

sub setNodeFocusState(node as dynamic, focused as boolean)
    if isValid(node) AND (node.subType() = "HeroSlider" OR node.subType() = "MonumentalCard")
        node.callFunc("setFocusState", focused)
    end if
end sub

function onKeyPressDown() as boolean
    nextCompNode = m.gContainer.getChild(m.focusComponentIndex + 1)
    currentFocusNode = m.gContainer.getChild(m.focusComponentIndex)
    if isValid(nextCompNode)
        m.focusComponentIndex += 1
        slidePanel("down", nextCompNode)
        setFocus(nextCompNode)
        setNodeFocusState(currentFocusNode, false)
        setNodeFocusState(nextCompNode, true)
        if isTopHeroNode(currentFocusNode) AND nextCompNode.subType() <> "HeroSlider"
            setHeroImageHidden(true)
        end if
        return true
    end if
    return false
end function

function onKeyPressUp() as boolean
    prevCompNode = m.gContainer.getChild(m.focusComponentIndex - 1)
    currentFocusNode = m.gContainer.getChild(m.focusComponentIndex)
    if isValid(prevCompNode) AND isValid(currentFocusNode)
        m.focusComponentIndex -= 1
        slidePanel("up", prevCompNode)
        setFocus(prevCompNode)
        setNodeFocusState(currentFocusNode, false)
        setNodeFocusState(prevCompNode, true)
        if isTopHeroNode(prevCompNode) AND currentFocusNode.subType() <> "HeroSlider"
            setHeroImageHidden(false)
        end if
        return true
    end if
    return false
end function

sub setHeroImageHidden(hidden as boolean)
    heroNode = getHeroSliderNode()
    m.scene.hasTopMenuBackground = hidden
    if isValid(heroNode)
        heroNode.callFunc("setScrollStateImageVisibility", hidden)
    end if
end sub

function getHeroSliderNode() as dynamic
    if isValid(m.heroSliderNode) then return m.heroSliderNode
    if m.gContainer = invalid then return invalid

    compNode = m.gContainer.getChild(0)
    if isTopHeroNode(compNode)
        m.heroSliderNode = compNode
        return m.heroSliderNode
    else
        for i = 0 to m.gContainer.getChildCount() - 1
            compNode = m.gContainer.getChild(i)
            if isTopHeroNode(compNode)
                m.heroSliderNode = compNode
                return m.heroSliderNode
            end if
        end for
    end if
    return invalid
end function

function getHeroSliderIndex(visibleOnly = false as boolean) as integer
    if m.gContainer = invalid then return -1
    compNode = m.gContainer.getChild(0)
    if isTopHeroNode(compNode)
        if visibleOnly AND compNode.visible = false
            ' skip hidden hero
        else
            return 0
        end if
    else
        for i = 0 to m.gContainer.getChildCount() - 1
            compNode = m.gContainer.getChild(i)
            if isTopHeroNode(compNode)
                if visibleOnly AND compNode.visible = false
                    ' skip hidden hero
                else
                    return i
                end if
            end if
        end for
    end if

    return -1
end function

function slidePanel(key, nextFocusNode)
    if isValid(m.slideAnimation) AND m.slideAnimation.state = "running" then m.slideAnimation.control = "finish"
    currentX = m.gContainer.translation[0]
    currentY = m.gContainer.translation[1]
    viewPortHeight = 990
    extraoffset = 0
    yOffset = 0
    if (isValid(nextFocusNode)) then
        isTopRow = (nextFocusNode.translation[1] <= 0)
        if key = "up" then
            ' Up key: align focused row to same viewport baseline used by down movement.
            if isTopRow
                newY = 0
            else
                targetBottom = viewPortHeight - m.top.rowSpacing
                newY = targetBottom - (nextFocusNode.translation[1] + nextFocusNode.componentHeight)
                if newY > 0 then newY = 0
            end if
        else
            ' Down key'
            remainingViewPortion = viewPortHeight - nextFocusNode.translation[1] - currentY
            nextYTranslation = 0
            if nextFocusNode.componentHeight > remainingViewPortion
                nextYTranslation = nextFocusNode.componentHeight - remainingViewPortion + yOffset
            end if
            if isTopRow
                newY = currentY - (nextFocusNode.translation[1] - Abs(currentY)) + yOffset
            else
                newY = currentY - nextYTranslation - extraoffset
            end if
            newY -= m.top.rowSpacing
        end if
        translationAnimation([m.gContainer.translation, [currentX, newY]])
    end if
end function

sub translationAnimation(value)
    m.slideVector2D.keyValue = value
    m.slideVector2D.fieldToInterp = "gContainer.translation"
    distance = Abs(value[0][1] - value[1][1])
    if(distance < 360)
        m.slideAnimation.duration = "0.3"
    else if(distance >= 360 AND distance < 720)
        m.slideAnimation.duration = "0.275"
    else
        m.slideAnimation.duration = "0.25"
    end if
    m.slideAnimation.control = "start"
end sub

function onkeyEvent(key as string, press as boolean) as boolean
    result = false
    if(press)
        if key = "down"
            result = onKeyPressDown()
        else if key = "up"
            result = onKeyPressUp()
        else if (key = "right" OR key = "left")
            result = false
        end if
    end if
    return result
end function
