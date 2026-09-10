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

    ' Salta nodos que no son filas focusables (ej. el header de la vista de
    ' Programas) y el hero compacto del Home.
    for i = 0 to childCount - 1
        if isFocusableContentNode(m.gContainer.getChild(i)) then return i
    end for

    return 0
end function

function isFocusableContentNode(node as dynamic) as boolean
    if not isValid(node) then return false
    subType = node.subType()
    if subType = "SliderView" OR subType = "MonumentalCard" then return true
    if subType = "HeroSlider"
        if node.variant <> "compact" then return true
    end if
    return false
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
        slidePanel(direction, targetNode, targetIndex <= getFirstContentIndex())
    end if

    m.focusComponentIndex = targetIndex
    setFocus(targetNode)
    if isValid(currentNode) AND currentIndex <> targetIndex then setNodeFocusState(currentNode, false)
    setNodeFocusState(targetNode, true)
    return showHideSlider(targetNode)
end function

function showHideSlider(targetNode as dynamic)
    setHeroImageHidden(not keepsHeroImageVisible(targetNode))
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
                setHeroImageHidden(not keepsHeroImageVisible(compNode))
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

' El hero de arriba y la fila de "destacados" son una sola unidad: mientras el
' foco esté en cualquiera de los dos, la imagen del hero debe seguir visible.
function keepsHeroImageVisible(node as dynamic) as boolean
    if isTopHeroNode(node) then return true
    if isValid(node) AND node.subType() = "SliderView"
        if node.keepHeroVisible = true then return true
    end if
    return false
end function

sub setNodeFocusState(node as dynamic, focused as boolean)
    if isValid(node) AND (node.subType() = "HeroSlider" OR node.subType() = "MonumentalCard" OR node.subType() = "SliderView")
        node.callFunc("setFocusState", focused)
    end if
end sub

function onKeyPressDown() as boolean
    nextCompNode = m.gContainer.getChild(m.focusComponentIndex + 1)
    currentFocusNode = m.gContainer.getChild(m.focusComponentIndex)
    if isValid(nextCompNode)
        m.focusComponentIndex += 1
        slidePanel("down", nextCompNode, m.focusComponentIndex <= getFirstContentIndex())
        setFocus(nextCompNode)
        setNodeFocusState(currentFocusNode, false)
        setNodeFocusState(nextCompNode, true)
        setHeroImageHidden(not keepsHeroImageVisible(nextCompNode))
        return true
    end if
    return false
end function

function onKeyPressUp() as boolean
    ' La primera fila de contenido es el límite superior del Home: no se sube al hero.
    if m.focusComponentIndex <= getFirstContentIndex() then return false
    prevCompNode = m.gContainer.getChild(m.focusComponentIndex - 1)
    currentFocusNode = m.gContainer.getChild(m.focusComponentIndex)
    if isValid(prevCompNode) AND isValid(currentFocusNode)
        m.focusComponentIndex -= 1
        slidePanel("up", prevCompNode, m.focusComponentIndex <= getFirstContentIndex())
        setFocus(prevCompNode)
        setNodeFocusState(currentFocusNode, false)
        setNodeFocusState(prevCompNode, true)
        setHeroImageHidden(not keepsHeroImageVisible(prevCompNode))
        return true
    end if
    return false
end function

sub setHeroImageHidden(hidden as boolean)
    heroNode = getHeroSliderNode()
    ' Solo las páginas con hero (Home) usan el degradado del TopMenu; en la
    ' vista de Programas no hay hero y el header no debe oscurecerse.
    if isValid(heroNode)
        m.scene.hasTopMenuBackground = hidden
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

function slidePanel(key, nextFocusNode, isTopContent = false as boolean)
    if isValid(m.slideAnimation) AND m.slideAnimation.state = "running" then m.slideAnimation.control = "finish"
    currentX = m.gContainer.translation[0]
    if (isValid(nextFocusNode))
        newY = 0
        if not isTopContent
            ' Centra verticalmente la fila enfocada en la pantalla
            screenHeight = 1080
            targetTop = (screenHeight - nextFocusNode.componentHeight) / 2
            newY = targetTop - nextFocusNode.translation[1]
            if newY > 0 then newY = 0
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
