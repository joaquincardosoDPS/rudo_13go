sub init()
    SetLocals()
    SetControls()
    SetupColor()
    SetupFonts()
    SetObservers()
    Initlization()
end sub

sub SetLocals()
    m.theme = m.global.appTheme
    m.fonts = m.global.Fonts
    m.scene = m.top.getScene()
    m.isMenuExpanded = false
    ' Seleccion "fantasma" ("Bug real #4"): la grilla dispara itemSelected del
    ' item enfocado al entrar al riel, sin que el usuario apriete OK. Se ignora
    ' toda seleccion que llegue antes o hasta 500 ms despues de que la grilla
    ' gane el foco; un OK real siempre llega despues.
    m.clock = CreateObject("roTimespan")
    m.gridFocused = false
    m.gridFocusMs = 0
    m.defaultAvatarUri = "pkg:/images/other/default_user.png"
    m.lastSelectedMenu = invalid
    m.accountMenuNode = invalid
    ' "Inicio" es el item que queda seleccionado al arrancar (indice 1, porque
    ' el 0 es "Mi cuenta").
    m.defaultMenuIndex = 1
end sub

sub SetControls()
    m.pExpandGradient = m.top.findNode("pExpandGradient")
    m.pLogoImage = m.top.findNode("pLogoImage")
    m.topMenuGrid = m.top.findNode("topMenuGrid")
    m.lHidden = m.top.findNode("lHidden")
end sub

sub SetupColor()
end sub

sub SetupFonts()
    m.lHidden.font = m.fonts.dmSansMedium24
end sub

sub SetObservers()
    m.top.observeField("focusedChild", "OnFocusChild")
    m.topMenuGrid.observeField("itemSelected", "OnItemSelected")
    m.scene.observeField("ProfileData", "OnProfileDataChanged")
    m.scene.observeField("isUserLoggedIn", "OnProfileDataChanged")
    m.pLogoImage.observeField("loadStatus", "OnLogoLoadStatusChanged")
    logoImage = GlobalGet("logo")
    if isNonEmptyString(logoImage)
        m.pLogoImage.uri = logoImage
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

sub Initlization()
    menuList = m.global.menuList.items

    menuIcons = {
        "Inicio": "pkg:/images/icons/sidebar/icon_home.png"
        "On Demand": "pkg:/images/icons/sidebar/icon_vod.png"
        "En vivo": "pkg:/images/icons/sidebar/icon_live.png"
        "Radios": "pkg:/images/icons/sidebar/icon_radios.png"
        "Buscador": "pkg:/images/icons/sidebar/icon_search.png"
    }

    m.content = createObject("roSGNode", "ContentNode")
    for each menu in menuList
        menuContent = createObject("roSGNode", "MenuContent")
        menuContent.title = menu
        menuContent.isSelected = false
        if menu = "Mi cuenta"
            menuContent.isAvatar = true
            m.accountMenuNode = menuContent
        else
            iconUri = ""
            If menuIcons.DoesExist(menu) then iconUri = menuIcons[menu]
            menuContent.iconUri = iconUri
        end if
        m.content.appendChild(menuContent)
    end for
    SetupContent()
    OnProfileDataChanged()
end sub

' El avatar del riel sigue al perfil activo, igual que el
' `currentProfile` que lee el Sidebar.tsx de c13_reloaded.
sub OnProfileDataChanged()
    if not isValid(m.accountMenuNode) then return
    avatarUri = ""
    if m.scene.isUserLoggedIn
        avatarUri = getValueFromProps(m.scene.ProfileData, "profileUri", "")
    end if
    if not isNonEmptyString(avatarUri) then avatarUri = m.defaultAvatarUri
    m.accountMenuNode.avatarUri = avatarUri
    isPremium = false
    if m.scene.isUserLoggedIn then isPremium = GlobalGet("isPremiumUser") = true
    m.accountMenuNode.isPremium = isPremium
end sub

sub OnFocusChild()
    if m.top.hasFocus()
        focusRestored = RestoreFocus()
        if focusRestored = false AND m.top.isInFocusChain()
            setFocus(m.topMenuGrid)
        end if
    end if
    isGridFocused = isValid(m.topMenuGrid) AND (m.topMenuGrid.hasFocus() OR m.topMenuGrid.isInFocusChain())
    if isGridFocused AND not m.gridFocused then m.gridFocusMs = m.clock.TotalMilliseconds()
    m.gridFocused = isGridFocused
    SetMenuExpanded(isGridFocused)
end sub

sub SetMenuExpanded(expanded as boolean)
    if m.isMenuExpanded = expanded then return
    m.isMenuExpanded = expanded
    m.pExpandGradient.visible = expanded
    if isValid(m.content)
        for i = 0 to m.content.getChildCount() - 1
            m.content.getChild(i).isExpanded = expanded
        end for
    end if
end sub

sub SetupContent()
    m.topMenuGrid.content = m.content
    ' Se marca "Inicio" como seleccionada SIN tocar itemSelected: asignar ese
    ' campo dispara el observer y haria navegar sola a la app al arrancar
    ' (ahora el indice 0 es "Mi cuenta", que ademas abriria el login).
    m.topMenuGrid.jumpToItem = m.defaultMenuIndex
    if m.content.getChildCount() > m.defaultMenuIndex
        m.lastSelectedMenu = m.content.getChild(m.defaultMenuIndex)
        m.lastSelectedMenu.isSelected = true
    end if
end sub

' MainScene la llama justo antes de darle el foco al riel: la grilla salta a la
' seccion marcada (preferredChildFocusKey de la web) y desde ahora corre la
' ventana de 500 ms en la que se ignora la seleccion "fantasma" de entrada. No
' depende del observer de focusedChild, que en el Roku no siempre llega a tiempo.
sub PrepareEnter()
    m.gridFocusMs = m.clock.TotalMilliseconds()
    if isValid(m.lastSelectedMenu) AND isValid(m.content)
        for i = 0 to m.content.getChildCount() - 1
            if m.content.getChild(i).isSameNode(m.lastSelectedMenu)
                m.topMenuGrid.jumpToItem = i
                exit for
            end if
        end for
    end if
end sub

sub OnItemSelected(event as dynamic)
    index = event.getData()
    ' La grilla tiene que tener el foco ahora (no la marca guardada).
    gridFocused = m.topMenuGrid.hasFocus() OR m.topMenuGrid.isInFocusChain()
    elapsed = m.clock.TotalMilliseconds() - m.gridFocusMs
    print "TopMenu : itemSelected "; index; " gridFocused="; gridFocused; " ms desde que entro="; elapsed
    if not gridFocused OR elapsed < 500
        print "TopMenu : seleccion ignorada al entrar al riel : " index
        return
    end if
    UpdateSelectedTopMenu(index)
end sub

sub UpdateSelectedTopMenu(selectedIndex as integer, isFromMainScene = false as boolean)
    if not isValid(m.topMenuGrid) OR not isValid(m.topMenuGrid.content) then return
    if m.topMenuGrid.content.getChildCount() = 0 then return
    if selectedIndex < 0 OR selectedIndex >= m.topMenuGrid.content.getChildCount() then return

    selectedNode = m.topMenuGrid.content.getChild(selectedIndex)
    if not isValid(selectedNode) then return

    ' "Mi cuenta" solo avisa a MainScene: sin sesion abre el login (pantalla
    ' completa, no queda activa); con sesion MainScene abre la cuenta y recien
    ' ahi la marca como activa llamando con isFromMainScene = true.
    if selectedNode.title = "Mi cuenta" AND not isFromMainScene
        m.top.selectedItem = { title: selectedNode.title }
        return
    end if

    if isValid(m.lastSelectedMenu) then m.lastSelectedMenu.isSelected = false
    selectedNode.isSelected = true
    m.lastSelectedMenu = selectedNode
    ' isFromMainScene = la navegacion ya ocurrio y solo hay que reflejarla en el
    ' riel; emitir selectedItem aca volveria a disparar la navegacion.
    if not isFromMainScene
        print "TopMenu : emite seleccion " selectedNode.title
        m.top.selectedItem = { title: selectedNode.title }
    end if
    ' Al entrar al riel el foco tiene que caer en la seccion actual (el
    ' preferredChildFocusKey de la web), no en el ultimo item enfocado.
    if isFromMainScene AND not (m.topMenuGrid.hasFocus() OR m.topMenuGrid.isInFocusChain()) then m.topMenuGrid.jumpToItem = selectedIndex
end sub
