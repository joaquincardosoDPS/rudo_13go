sub Init()
    print "HomePage Init "
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

    initVar()
end sub

sub SetControls()
    m.gDetails = m.top.findNode("gDetails")
    m.heroSlider = m.top.findNode("heroSlider")
    m.focusableGroup = m.top.findNode("focusableGroup")
    m.noData = m.top.findNode("noData")
    m.pageLoader = m.top.findNode("pageLoader")
end sub 

sub SetupFonts()
    m.noData.font = m.fonts.dmSansBold32
end sub

sub SetupColor()
    m.noData.color = m.theme.white
end sub 

sub SetObservers()
    m.top.observeField("focusedChild", "onFocusedChild")
    m.top.observeField("visible", "onVisibleChange")
    m.scene.observeField("isWatchHistoryFetched", "refreshRowlistContent")
    m.scene.observeField("updatedContinueWatchData", "onAddUpdateContinueWatchingRow")
end sub

sub initVar()
    m.categoriesData = invalid
    m.apiInProgress = 0
    m.heroSlider = invalid
    m.continueWatchingData = invalid

    m.cwSectionIndex = 0
    m.cwDisplayTitle = ""
    m.categoriesNode = []
    m.continteWatchingSliderView = invalid
    m.isReRenderUI = false
    m.isFirstTime = false
end sub

sub onVisibleChange()
    if m.top.visible
        refreshRowlistContent()
    end if
end sub

sub OnFocusedChild()
    if m.top.hasFocus()
        focusRestored = RestoreFocus()
        if focusRestored = false
            if (isValid(m.focusableGroup) AND m.focusableGroup.callFunc("getContainerChildCount") > 0)
                setFocus(m.focusableGroup)
            end if
        end if
    end if
end sub

sub showHidePageLoader(visible as boolean)
    m.pageLoader.visible = visible
end sub

sub onPageDestroy()
    if m.top.isDestroy
        initVar()
        m.scene.isWatchHistoryFetched = false
        m.scene.updatedContinueWatchData = {}
        if isValid(m.focusableGroup) then m.focusableGroup.callFunc("clearNodes")
        if isValid(m.watchHistoryTask)
            m.watchHistoryTask.control = "stop"
            m.watchHistoryTask = invalid
        end if
        if isValid(m.getFeaturedSliderProgramsTask)
            m.getFeaturedSliderProgramsTask.control = "stop"
            m.getFeaturedSliderProgramsTask = invalid
        end if
        if isValid(m.getAllCategoriesTask)
            m.getAllCategoriesTask.control = "stop"
            m.getAllCategoriesTask = invalid
        end if
    end if
end sub

sub Initialize()
    m.rowSpacing = 134
    m.focusableGroup.rowSpacing = m.rowSpacing
    GetHomeSections()
    fetchAndStoreWatchHistory()

end sub

' Continue Watching
sub refreshRowlistContent()
    if m.scene.isWatchHistoryFetched AND m.top.visible
        m.scene.isWatchHistoryFetched = false
        fetchAndStoreWatchHistory()
    end if
end sub

sub fetchAndStoreWatchHistory()
    if m.scene.isUserLoggedIn
        m.apiInProgress++
        if isValid(m.watchHistoryTask)
            m.watchHistoryTask.control = "STOP"
            m.watchHistoryTask = invalid
        end if
        params = {}
        params["client"] = GlobalGet("appConfig").client
        params["token"] = GlobalGet("token")
        params["profile"] = GlobalGet("selectedProfileID")
        params["end"] = 0
        ' params["page"] = 1
        ' params["limit"] = GlobalGet("appConfig").pageSize
        m.watchHistoryTask = CreateObject("roSGNode", "ContentAPIAction")
        m.watchHistoryTask.functionName = "GetAllWatchHistory"
        m.watchHistoryTask.params = params
        m.watchHistoryTask.observeField("result", "onGetAllWatchHistoryResponse")
        m.watchHistoryTask.control = "RUN"
    end if
end sub

sub onGetAllWatchHistoryResponse(event as dynamic)
    response = event.getData()
    print "onGetAllWatchHistoryResponse >>>> response : " 'formatjson(response)
    if isValid(response) AND isValid(response.data) AND isValid(response.data.data) AND isValid(response.data.data.count() > 0)
        data = response.data.data
        catData = {}
        catData.title = "Seguir Viendo"
        catData.format = "default"
        catData.image_orientation = "landscape"
        catData.liveCategory = false
        catData.image_background_category = {} 
        catData.image_logo_category = {} 
        catData.key = "Seguir Viendo"
        catData.total_display_records = 10
        catData.total_records = 10
        catData.last_page = 1
        catData.programs = data
        if m.continueWatchingData = invalid
            m.continueWatchingData = catData
        else
            m.scene.updatedContinueWatchData = catData
        end if
    end if
    m.apiInProgress--
    if m.isFirstTime = false then createDynamicRowList()
    m.watchHistoryTask = invalid
end sub

sub CreateSilderViewForContinueWatching()
    if isValid(m.continueWatchingData) AND m.continueWatchingData.count() > 0
        catNode = rowListDataParser(m.continueWatchingData)
        if isValid(catNode) AND isValid(m.continteWatchingSliderView)
            m.continteWatchingSliderView.category = m.continueWatchingData
            m.continteWatchingSliderView.content = catNode
        end if
    end if
end sub

sub onAddUpdateContinueWatchingRow()
    continueWatchingData = m.scene.updatedContinueWatchData
    catNode = invalid
    if isValid(continueWatchingData) AND continueWatchingData.count() > 0
        catNode = rowListDataParser(continueWatchingData)
        if isValid(catNode) AND isValid(m.continteWatchingSliderView)
            m.continteWatchingSliderView.category = continueWatchingData
        end if
    end if
    if isValid(m.continteWatchingSliderView) then checkRefreshNodes(m.continteWatchingSliderView, catNode)
end sub

sub createLastWatchedSlider()
    sliderView = createObject("roSGNode", "SliderView")
    sliderView.ObserveField("itemSelected", "onRowItemSelected")
    sliderView.ObserveField("itemFocused", "onRowItemFocused")
    sliderView.id = "seguirviendo"
    sliderView.componentHeight = 180 + 50
    m.continteWatchingSliderView = sliderView
    m.categoriesNode.push(sliderView)
    CreateSilderViewForContinueWatching()
end sub
' End Continue Watching

sub GetHomeSections()
    m.apiInProgress++
    showHidePageLoader(true)
    m.getHomeSectionsTask = CreateObject("roSGNode", "ContentAPIAction")
    m.getHomeSectionsTask.functionName = "GetHomeConfig"
    m.getHomeSectionsTask.params = {}
    m.getHomeSectionsTask.ObserveField("result", "OnGetHomeSectionsAPIResponse")
    m.getHomeSectionsTask.control = "RUN"
end sub

sub OnGetHomeSectionsAPIResponse(event as dynamic)
    apiResponse = event.getData()
    print "OnGetHomeSectionsAPIResponse : response : " 'FormatJson(apiResponse)
    m.homeSections = getValueFromProps(apiResponse, "data", [])
    m.homeSectionIndex = 0
    m.getHomeSectionsTask = invalid
    ProcessNextHomeSection()

end sub

sub ProcessNextHomeSection()
    if m.homeSections = invalid OR m.homeSectionIndex >= m.homeSections.count()
        m.apiInProgress--
        createDynamicRowList()
        return
    end if
    section = m.homeSections[m.homeSectionIndex]
    m.homeSectionIndex++
    if isInvalid(section) OR section.status <> "1"
        ProcessNextHomeSection()
        return
    end if

    homeConfig = GlobalGet("homeConfig")
    despliegue = section.despliegue

    if despliegue = "destacados"
        url = ""
        if isValid(homeConfig) then url = homeConfig.destacados_principales
        if isNonEmptyString(url)
            GetFeaturedSliderPrograms(url)
        else
            ProcessNextHomeSection()
        end if
    else if despliegue = "categoria_carrusel" OR despliegue = "categoria_destacada"
        if isNonEmptyString(section.categoria)
            GetHomeCategoryPrograms(section.titulo, section.categoria, despliegue)
        else
            ProcessNextHomeSection()
        end if
    else if despliegue = "top10"
        url = ""
        if isValid(homeConfig) then url = homeConfig.masvistos
        if isNonEmptyString(url)
            GetHomeTop10(section.titulo, url)
        else
            ProcessNextHomeSection()
        end if
    else if despliegue = "senales"
        url = ""
        if isValid(homeConfig) then url = homeConfig.senales
        if isNonEmptyString(url)
            GetHomeSenales(section.titulo, url)
        else
            ProcessNextHomeSection()
        end if
    else if despliegue = "radios"
        url = ""
        if isValid(homeConfig) then url = homeConfig.radios
        if isNonEmptyString(url)
            GetHomeRadios(section.titulo, url)
        else
            ProcessNextHomeSection()
        end if
    else
        ' seguirviendo / favoritos / bannerpromo / preguntasfrecuentes: sin fetch propio por ahora
        ProcessNextHomeSection()
    end if
end sub



sub PushHomeRow(title as string, items as object, format = "default" as string, componentHeight = 626 as integer)
    if isValid(items) AND items.count() > 0
        catData = {}
        catData.title = title
        catData.format = format
        catData.image_orientation = "portrait"
        catData.liveCategory = false
        catData.image_background_category = {}
        catData.image_logo_category = {}
        catData.key = title
        catData.total_display_records = items.count()
        catData.total_records = items.count()
        catData.programs = items

        sliderView = createObject("roSGNode", "SliderView")
        sliderView.ObserveField("itemSelected", "onRowItemSelected")
        sliderView.ObserveField("itemFocused", "onRowItemFocused")
        sliderView.id = title
        sliderView.componentHeight = componentHeight
        catNode = rowListDataParser(catData)
        if isValid(catNode)
            sliderView.category = catData
            sliderView.content = catNode
        end if
        m.categoriesNode.push(sliderView)
    end if
end sub

sub PushMonumentalRow(title as string, items as object)
    if isValid(items) AND items.count() > 0
        monumentalCard = createObject("roSGNode", "MonumentalCard")
        monumentalCard.id = title
        monumentalCard.width = 1920
        monumentalCard.sectionTitle = title
        monumentalCard.componentHeight = 342 + 50
        monumentalCard.items = items
        m.categoriesNode.push(monumentalCard)
    end if
end sub

sub GetHomeCategoryPrograms(rowTitle as string, categoryId as string, despliegue as string)
    m.pendingRowTitle = rowTitle
    m.pendingRowDespliegue = despliegue
    m.getHomeCategoryTask = CreateObject("roSGNode", "ContentAPIAction")
    m.getHomeCategoryTask.functionName = "GetCategoryPrograms"
    m.getHomeCategoryTask.params = { "categoryId": categoryId }
    m.getHomeCategoryTask.ObserveField("result", "OnGetHomeCategoryProgramsAPIResponse")
    m.getHomeCategoryTask.control = "RUN"
end sub

sub OnGetHomeCategoryProgramsAPIResponse(event as dynamic)
    apiResponse = event.getData()
    rawPrograms = getValueFromProps(apiResponse, "data.programs", [])
    if m.pendingRowDespliegue = "categoria_destacada"
        items = []
        for each raw in rawPrograms
            bgUrl = raw.imagen_fondo
            items.push({
                title: stripEmojis(decodeHtmlEntities(raw.title))
                description: stripEmojis(decodeHtmlEntities(raw.bajada))
                description_short: stripEmojis(decodeHtmlEntities(raw.bajada))
                key: raw.id
                image_background: { small: bgUrl, medium: bgUrl, normal: bgUrl, big: bgUrl, default: bgUrl }
            })
        end for
        PushMonumentalRow(m.pendingRowTitle, items)
    else
        items = []
        for each raw in rawPrograms
            imageUrl = raw.image
            items.push({
                title: stripEmojis(decodeHtmlEntities(raw.title))
                description: stripEmojis(decodeHtmlEntities(raw.bajada))
                description_short: stripEmojis(decodeHtmlEntities(raw.bajada))
                key: raw.id
                image_orientation: "portrait"
                format: "default"
                image_port: { small: imageUrl, medium: imageUrl, normal: imageUrl, big: imageUrl, default: imageUrl }
            })
        end for
        PushHomeRow(m.pendingRowTitle, items)
    end if
    m.getHomeCategoryTask = invalid
    ProcessNextHomeSection()
end sub

sub GetHomeTop10(rowTitle as string, url as string)
    m.pendingRowTitle = rowTitle
    m.getHomeTop10Task = CreateObject("roSGNode", "ContentAPIAction")
    m.getHomeTop10Task.functionName = "GetJsonByUrl"
    m.getHomeTop10Task.params = { "url": url }
    m.getHomeTop10Task.ObserveField("result", "OnGetHomeTop10APIResponse")
    m.getHomeTop10Task.control = "RUN"
end sub

sub OnGetHomeTop10APIResponse(event as dynamic)
    apiResponse = event.getData()
    rawItems = getValueFromProps(apiResponse, "data.data", [])
    items = []
    for each raw in rawItems
        imageUrl = raw.image
        items.push({
            title: stripEmojis(decodeHtmlEntities(raw.title))
            key: raw.id
            image_orientation: "portrait"
            format: "default"
            image_port: { small: imageUrl, medium: imageUrl, normal: imageUrl, big: imageUrl, default: imageUrl }
        })
    end for
    PushHomeRow(m.pendingRowTitle, items, "ranking")
    m.getHomeTop10Task = invalid
    ProcessNextHomeSection()
end sub

sub GetHomeSenales(rowTitle as string, url as string)
    m.pendingRowTitle = rowTitle
    m.getHomeSenalesTask = CreateObject("roSGNode", "ContentAPIAction")
    m.getHomeSenalesTask.functionName = "GetJsonByUrl"
    m.getHomeSenalesTask.params = { "url": url }
    m.getHomeSenalesTask.ObserveField("result", "OnGetHomeSenalesAPIResponse")
    m.getHomeSenalesTask.control = "RUN"
end sub

sub OnGetHomeSenalesAPIResponse(event as dynamic)
    apiResponse = event.getData()
    rawItems = getValueFromProps(apiResponse, "data", [])
    items = []
    for each raw in rawItems
        logoUrl = raw.imagen
        if isNonEmptyString(raw.logo_invertido) AND LCase(Right(raw.logo_invertido, 4)) <> ".svg" then logoUrl = raw.logo_invertido
        if isNonEmptyString(raw.logo_blanco) AND LCase(Right(raw.logo_blanco, 4)) <> ".svg" then logoUrl = raw.logo_blanco
        items.push({
            title: stripEmojis(decodeHtmlEntities(raw.titulo))
            key: raw.nid
            image: logoUrl
            ringColor: raw.color_principal
            format: "circle"
            type: "senal"
        })
    end for
    PushHomeRow(m.pendingRowTitle, items, "circle", 220)
    m.getHomeSenalesTask = invalid
    ProcessNextHomeSection()
end sub

sub GetHomeRadios(rowTitle as string, url as string)
    m.pendingRowTitle = rowTitle
    m.getHomeRadiosTask = CreateObject("roSGNode", "ContentAPIAction")
    m.getHomeRadiosTask.functionName = "GetJsonByUrl"
    m.getHomeRadiosTask.params = { "url": url }
    m.getHomeRadiosTask.ObserveField("result", "OnGetHomeRadiosAPIResponse")
    m.getHomeRadiosTask.control = "RUN"
end sub

sub OnGetHomeRadiosAPIResponse(event as dynamic)
    apiResponse = event.getData()
    rawItems = getValueFromProps(apiResponse, "data", [])
    items = []
    for each raw in rawItems
        items.push({
            title: stripEmojis(decodeHtmlEntities(raw.name))
            key: raw.name
            image: raw.image
            ringColor: m.theme.focPrimary
            format: "circle"
            type: "radio"
        })
    end for
    PushHomeRow(m.pendingRowTitle, items, "circle", 220)
    m.getHomeRadiosTask = invalid
    ProcessNextHomeSection()
end sub

sub GetFeaturedSliderPrograms(url as string)
    m.getFeaturedSliderProgramsTask = CreateObject("roSGNode", "ContentAPIAction")
    m.getFeaturedSliderProgramsTask.functionName = "GetJsonByUrl"
    m.getFeaturedSliderProgramsTask.params = {"url": url}
    m.getFeaturedSliderProgramsTask.ObserveField("result", "OnGetFeaturedSliderProgramsAPIResponse")
    m.getFeaturedSliderProgramsTask.control = "RUN"
end sub

sub OnGetFeaturedSliderProgramsAPIResponse(event as dynamic)
    apiResponse = event.getData()
    print "OnGetFeaturedSliderProgramsAPIResponse : response : " 'FormatJson(apiResponse)
    rawItems = getValueFromProps(apiResponse, "data.data", [])
    if isValid(rawItems) AND rawItems.count() > 0
        items = []
        for each raw in rawItems
            imageUrl = raw.image
            items.push({
                title: stripEmojis(decodeHtmlEntities(raw.title))
                description: stripEmojis(decodeHtmlEntities(raw.bajada))
                description_short: stripEmojis(decodeHtmlEntities(raw.bajada))
                epigrafe: stripEmojis(decodeHtmlEntities(raw.show))
                llamado: raw.llamado
                duration: raw.duration
                key: raw.nid
                image_land: {
                    small: imageUrl,
                    medium: imageUrl,
                    normal: imageUrl,
                    big: imageUrl,
                    default: imageUrl
                }
                image_background: {
                    small: imageUrl,
                    medium: imageUrl,
                    normal: imageUrl,
                    big: imageUrl,
                    default: imageUrl
                }
            })
        end for
        if isValid(m.heroSlider)
            heroSlider = m.heroSlider
            heroSlider.variant = "compact"
            heroSlider.items = [items[0]]
            heroSlider.componentHeight = 660
            heroSlider.visible = true
            m.gDetails.translation = [106,0]
            m.categoriesNode.push(heroSlider)
        end if
        if items.count() > 0
            catData = {}
            catData.title = "Destacados"
            catData.format = "default"
            catData.image_orientation = "landscape"
            catData.liveCategory = false
            catData.image_background_category = {}
            catData.image_logo_category = {}
            catData.key = "Destacados"
            catData.total_display_records = items.count()
            catData.total_records = items.count()
            catData.programs = items

            sliderView = createObject("roSGNode", "SliderView")
            sliderView.ObserveField("itemSelected", "onRowItemSelected")
            sliderView.ObserveField("itemFocused", "onRowItemFocused")
            sliderView.id = "destacados"
            sliderView.componentHeight = 180 + 50
            catNode = rowListDataParser(catData)
            if isValid(catNode)
                sliderView.category = catData
                sliderView.content = catNode
            end if
            m.categoriesNode.push(sliderView)
        end if
    else
        m.gDetails.translation = [106,150]
    end if
    m.getFeaturedSliderProgramsTask = invalid
    ProcessNextHomeSection()
end sub

sub createDynamicRowList()
    print "apiInProgress : " m.apiInProgress
    if m.apiInProgress > 0
        return
    end if
    m.isFirstTime = true
    ' catData = MergedCategoriesData()
    if isValid(m.categoriesData) AND m.categoriesData.count() > 0
        bufferSize = 50
        createLastWatchedSlider()
        for each catData in m.categoriesData
            componentHeight = 180
            if catData.image_orientation = "landscape"
                componentHeight = 180
            else if catData.image_orientation = "portrait"
                componentHeight = 576
            end if
            isLiveCategory = false
            if catData.format = "event" AND catData.image_orientation = "portrait" AND isValid(catData.programs) AND isValid(catData.programs[0]) AND isValid(catData.programs[0].type) AND catData.programs[0].type = "live"
                isLiveCategory = true
                componentHeight = 706
            end if
            catData.liveCategory = isLiveCategory
            mainContentNode = rowListDataParser(catData)
            if isValid(mainContentNode) AND mainContentNode.getChildCount() > 0
                sliderView = createObject("roSGNode", "SliderView")
                sliderView.id = catData.title
                sliderView.ObserveField("itemSelected", "onRowItemSelected")
                sliderView.ObserveField("itemFocused", "onRowItemFocused")
                sliderView.category = catData
                sliderView.componentHeight = componentHeight + bufferSize
                sliderView.content = mainContentNode
                m.categoriesNode.push(sliderView)
            end if
        end for
    end if
    for each node in m.categoriesNode
        if (isValid(node) AND ((isValid(node.content) AND node.content.getChildCount() > 0) OR node.subtype() = "HeroSlider" OR node.subtype() = "MonumentalCard"))
            m.focusableGroup.callFunc("setTranslation", node)
        end if
    end for
    manageFocus()
    if (isNonEmptyString(m.scene.deepLinkingContentId) AND isValid(m.scene.deeplinkingData) AND isValid(m.scene.deeplinkingData.programid) AND isNonEmptyString(m.scene.DeeplinkingMediaType))
        m.scene.isDeeplinking = true
        item = {}
        item.key = m.scene.deeplinkingData.programid
        item.category_key = m.scene.deeplinkingData.programid
        item.format = "default"
        item.image_orientation = "landscape"
        itemContent = CreateObject("roSGNode", "ProgramItemNode")
        itemContent.setFields(item)
        itemSelected = {
            "itemData": itemContent
            "sliderId": "deeplinking"
        }
        print "itemSelected : " itemSelected
        m.scene.callFunc("showDetailPage", itemSelected, false)
    else
        m.scene.DeeplinkMsg = "No result found"
        m.scene.deepLinkingContentId = ""
    end if
    showHidePageLoader(false)
end sub

sub checkRefreshNodes(compNode as dynamic, mainContent as dynamic)
    if isValid(compNode)
        if (isValid(compNode) AND mainContent = invalid)
            m.isReRenderUI = true
            deleteFromArray(m.categoriesNode, compNode)
            m.focusableGroup.callFunc("removeNode", compNode)
            m.focusableGroup.callFunc("clearNodes")
        else if (isInvalid(compNode.content) OR compNode.content.getChildCount() = 0)
            compNode.content = mainContent
            m.isReRenderUI = true
            m.focusableGroup.callFunc("clearNodes")
        else
            compNode.updateContent = mainContent
        end if
    end if
    if m.isReRenderUI
        for each node in m.categoriesNode
            if (isValid(node) AND ((isValid(node.content) AND node.content.getChildCount() > 0) OR node.subtype() = "HeroSlider" OR node.subtype() = "MonumentalCard"))
                m.focusableGroup.callFunc("setTranslation", node)
            end if
        end for
    end if
    manageFocus()
end sub

sub manageFocus()
    m.noData.visible = false
    if (m.focusableGroup.callFunc("getContainerChildCount") > 0)
        setFocus(m.focusableGroup)
    else
        m.noData.text = "No hay datos disponibles"
        m.noData.visible = true
        setFocus(m.noData)
    end if
end sub

sub onRowItemFocused(event as dynamic)
    focusedItem = event.getData()
    if isValid(focusedItem) AND isValid(focusedItem.itemData)
        if focusedItem.sliderId = "destacados" AND isValid(m.heroSlider)
            m.heroSlider.focusedItem = focusedItem.itemData
        end if
    end if
end sub

sub onRowItemSelected(event as dynamic)
    selectedItem = event.getData()
    print "onRowItemSelected : selectedItem : " selectedItem.itemData
    if isValid(selectedItem) AND isValid(selectedItem.itemData)
        if isValid(selectedItem.itemData.isViewMoreCard) AND selectedItem.itemData.isViewMoreCard
            m.scene.callFunc("showCategoryDetailPage", selectedItem, false)
        else if isValid(selectedItem.itemData.format) AND selectedItem.itemData.format = "event"
            m.scene.callFunc("showEventDetailPage", selectedItem, false)
        else if isValid(selectedItem.itemData.type) AND selectedItem.itemData.type = "senal"
            m.scene.callFunc("ShowLivePage", false)
        else
            m.scene.callFunc("showDetailPage", selectedItem, false)
        end if
    end if
end sub

function hasFocusOnFocusableGroup() as boolean
    return isValid(m.focusableGroup) AND m.focusableGroup.visible = true AND (m.focusableGroup.hasFocus() OR m.focusableGroup.isInFocusChain())
end function

function validFocusableGroup() as boolean
    return isValid(m.focusableGroup) AND m.focusableGroup.visible = true AND (m.focusableGroup.callFunc("getContainerChildCount") > 0)
end function

Function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false
    if press
        print " Page : HomePage : onKeyEvent : key = " key " press = " press
        if key = "back"
            if hasFocusOnFocusableGroup() AND validFocusableGroup()
                focusIndex = m.focusableGroup.callFunc("getFocusComponentIndex")
                firstContentIndex = m.focusableGroup.callFunc("getFirstContentIndex")
                if focusIndex > firstContentIndex
                    handled = m.focusableGroup.callFunc("focusToFirstRow")
                else if focusIndex = firstContentIndex AND firstContentIndex > 0
                    handled = m.focusableGroup.callFunc("focusToHeroSlider")
                end if
            end if
        end if
    end if
    return handled
End Function