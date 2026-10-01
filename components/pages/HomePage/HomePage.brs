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
end sub

sub initVar()
    m.categoriesData = invalid
    m.apiInProgress = 0
    m.heroSlider = invalid
    m.categoriesNode = []
    ' "Seguir viendo": fila en la posicion del CMS; se vacia/llena al volver al Home
    m.trackingSlider = invalid
    m.trackingTitle = ""
    m.trackingEmpty = true
    m.homeLoaded = false
    m.isReRenderUI = false
    m.isFirstTime = false
end sub

' Al volver al Home (ej. despues de ver un capitulo) se vuelve a pedir el
' historial: en la web el Home se vuelve a montar y lo pide de nuevo.
sub onVisibleChange()
    if m.top.visible AND m.homeLoaded AND isValid(m.trackingSlider)
        GetHomeTracking(m.trackingTitle, true)
    end if
    ' Armada detras de "Quien anda ahi?" y recien mostrada: ya esta lista para usar.
    if m.top.visible AND m.homeLoaded then m.scene.callFunc("SignalLaunchReady", "home")
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
        if isValid(m.focusableGroup) then m.focusableGroup.callFunc("clearNodes")
        if isValid(m.trackingTask)
            m.trackingTask.control = "stop"
            m.trackingTask = invalid
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
end sub

' ===================================================================
' "Seguir viendo" (SeguirViendoSection + TrackingListCarousel + use-home-data.ts)
' -------------------------------------------------------------------
' El historial del perfil (/accountTracking/{uid}/history): solo los
' event_type "progress" con menos del 95% visto, hasta 10. Sin sesion o sin
' items la fila no se muestra (la web devuelve null).
' ===================================================================
sub GetHomeTracking(rowTitle as string, isRefresh = false as boolean)
    m.trackingTitle = rowTitle
    profile = getValueFromProps(m.scene.ProfileData, "profileId", "")
    if m.scene.isUserLoggedIn <> true
        if not isRefresh then ProcessNextHomeSection()
        return
    end if
    ' Con sesion pero sin perfil todavia (la Portada se arma detras de "Quien anda
    ' ahi?"): la fila queda en su lugar vacia y se llena al elegir el perfil
    ' (onVisibleChange la vuelve a pedir, como al volver del reproductor).
    if not isNonEmptyString(profile)
        if not isRefresh then AddTrackingRow(invalid, invalid)
        return
    end if
    if isValid(m.trackingTask) then m.trackingTask.control = "stop"
    m.trackingIsRefresh = isRefresh
    m.trackingTask = CreateObject("roSGNode", "AuthAPIAction")
    m.trackingTask.functionName = "GetTracking"
    m.trackingTask.params = { profile: profile }
    m.trackingTask.ObserveField("result", "OnGetHomeTrackingResponse")
    m.trackingTask.control = "RUN"
end sub

sub OnGetHomeTrackingResponse(event as dynamic)
    m.trackingTask = invalid
    rawItems = getValueFromProps(event.getData(), "data.data", [])
    items = []
    if isNotEmptyArray(rawItems)
        for each raw in rawItems
            fields = getValueFromProps(raw, "fields", {})
            if getValueFromProps(fields, "event_type.stringValue", "") = "progress"
                seconds = convertToNumber(getValueFromProps(fields, "seconds.integerValue", "0"))
                duration = convertToNumber(getValueFromProps(fields, "duration.integerValue", "0"))
                if not (duration > 0 AND seconds / duration >= 0.95)
                    items.Push({
                        key: getValueFromProps(raw, "key_rudo", "")
                        image: getValueFromProps(fields, "image.stringValue", "")
                        show: getValueFromProps(fields, "show.stringValue", "")
                        title: getValueFromProps(fields, "title.stringValue", "")
                        seconds: seconds
                        duration: duration
                        path: getValueFromProps(fields, "path.stringValue", "")
                        restriction: getValueFromProps(fields, "restriction.stringValue", "0")
                    })
                end if
            end if
            if items.count() >= 10 then exit for
        end for
    end if
    catNode = invalid
    catData = invalid
    if items.count() > 0
        catData = {
            title: m.trackingTitle
            format: "tracking"
            image_orientation: "landscape"
            liveCategory: false
            image_background_category: {}
            image_logo_category: {}
            key: "seguirviendo"
            total_display_records: items.count()
            total_records: items.count()
            programs: items
        }
        catNode = rowListDataParser(catData)
    end if
    if m.trackingIsRefresh = true
        ApplyTrackingRefresh(catData, catNode)
        return
    end if
    AddTrackingRow(catData, catNode)
end sub

' Primera carga: la fila queda en su lugar del CMS aunque venga vacia, para
' poder llenarla al volver al Home despues de ver algo.
sub AddTrackingRow(catData as dynamic, catNode as dynamic)
    sliderView = createObject("roSGNode", "SliderView")
    sliderView.ObserveField("itemSelected", "onRowItemSelected")
    sliderView.ObserveField("itemFocused", "onRowItemFocused")
    sliderView.id = "seguirviendo"
    sliderView.componentHeight = 300 + 50
    m.trackingSlider = sliderView
    m.trackingEmpty = not isValid(catNode)
    if isValid(catNode)
        sliderView.category = catData
        sliderView.content = catNode
    end if
    m.categoriesNode.push(sliderView)
    ProcessNextHomeSection()
end sub

' Ya tenia items y sigue teniendo: se reemplazan sin tocar el foco. Si aparece o
' desaparece, se vuelven a acomodar las filas.
sub ApplyTrackingRefresh(catData as dynamic, catNode as dynamic)
    slider = m.trackingSlider
    if not isValid(slider) then return
    hasRowList = isValid(slider.content) AND slider.content.getChildCount() > 0
    if isValid(catNode)
        slider.category = catData
        if hasRowList
            slider.updateContent = catNode
        else
            slider.content = catNode
        end if
        if not m.trackingEmpty then return
        m.trackingEmpty = false
    else
        if m.trackingEmpty then return
        m.trackingEmpty = true
    end if
    RenderHomeRows()
end sub

' La fila de "Seguir viendo" vacia no se dibuja (su RowList queda armado).
function IsRowRenderable(node as dynamic) as boolean
    if not isValid(node) then return false
    if isValid(m.trackingSlider) AND node.isSameNode(m.trackingSlider) AND m.trackingEmpty then return false
    return (isValid(node.content) AND node.content.getChildCount() > 0) OR node.subtype() = "HeroSlider" OR node.subtype() = "MonumentalCard"
end function

sub RenderHomeRows()
    m.focusableGroup.callFunc("clearNodes")
    for each node in m.categoriesNode
        if IsRowRenderable(node) then m.focusableGroup.callFunc("setTranslation", node)
    end for
    manageFocus()
end sub

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
    else if despliegue = "seguirviendo"
        title = section.titulo
        if not isNonEmptyString(title) then title = "Seguir viendo"
        GetHomeTracking(title)
    else
        ' favoritos / bannerpromo / preguntasfrecuentes: sin fetch propio por ahora
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
                url: raw.url
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
                url: raw.url
                image_orientation: "portrait"
                format: "default"
                image_port: { small: imageUrl, medium: imageUrl, normal: imageUrl, big: imageUrl, default: imageUrl }
            })
        end for
        PushHomeRow(m.pendingRowTitle, items, "default", 361)
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
            url: raw.url
            image_orientation: "portrait"
            format: "default"
            image_port: { small: imageUrl, medium: imageUrl, normal: imageUrl, big: imageUrl, default: imageUrl }
        })
    end for
    PushHomeRow(m.pendingRowTitle, items, "ranking", 360)
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
            ' El id del feed es el key_live de la senal (13cl, t13...): va en el campo
            ' url nativo de ContentNode para abrir En vivo en esa senal.
            url: raw.id
            image: logoUrl
            ringColor: raw.color_principal
            format: "circle"
            type: "senal"
            ' PlaylistItemCarousel: candado si validateRestriction(restriction, packs)
            blocked: ValidateRestriction(getValueFromProps(raw, "restriction", "0"), getValueFromProps(raw, "packs", []))
        })
    end for
    PushHomeRow(m.pendingRowTitle, items, "circle", 270)
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
            ' liveUrl va en el campo url nativo de ContentNode (ProgramItemNode no
            ' declara liveUrl y setFields lo descartaria).
            url: raw.liveUrl
            ringColor: m.theme.focPrimary
            format: "circle"
            type: "radio"
        })
    end for
    PushHomeRow(m.pendingRowTitle, items, "circle", 270)
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
                link: getValueFromProps(raw, "link", "")
                type: getValueFromProps(raw, "type", "")
                rudoKey: getValueFromProps(raw, "key", "")
                restriction: getValueFromProps(raw, "restriction", "0")
                packs: getValueFromProps(raw, "packs", [])
                ' FeaturedItem.tsx: clase "bloqueado" (velo + candado) si validateRestriction
                ' dice que el plan no alcanza (capitulos y senales en vivo).
                blocked: ValidateRestriction(getValueFromProps(raw, "restriction", "0"), getValueFromProps(raw, "packs", []))
                vastUrl: getValueFromProps(raw, "vast_app", "")
                daiAssetKey: getValueFromProps(raw, "DPSDAIAssetKey", "")
                image: imageUrl
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
            ' Alto que ocupa el banner antes de la fila de Destacados. Con 660 la fila
            ' quedaba en y=794 y los titulos de las tarjetas salian de pantalla al abrir
            ' el Home; con 540 la fila sube 120px (pisa el degradado inferior del banner).
            heroSlider.componentHeight = 540
            heroSlider.visible = true
            m.gDetails.translation = [106,0]
            ' Mientras cargan las secciones el banner es hijo directo de la pagina; al
            ' terminar, FocusableGroup lo mueve dentro de gDetails (corrido 106, el margen
            ' del sidebar) con translation [0,0]. Se lo ubica ya en esa posicion para que
            ' no salte 106px a la derecha cuando desaparece el spinner.
            heroSlider.translation = [106, 0]
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
            sliderView.keepHeroVisible = true
            ' Tarjeta de 180 + programa y capitulo (hasta 2 lineas cada uno, ~120).
            sliderView.componentHeight = 180 + 110
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
        if IsRowRenderable(node) then m.focusableGroup.callFunc("setTranslation", node)
    end for
    m.homeLoaded = true
    manageFocus()
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
    ' El Home sigue cargando secciones en segundo plano aunque ya no sea la
    ' pantalla activa (ej. StartApp() + ShowEditorProfilesPage() justo despues
    ' de vincular). Sin este chequeo, cada seccion que termina de cargar le
    ' robaba el foco de vuelta al Home aunque el usuario ya estuviera en otra
    ' pantalla encima (bug real: ViewStackManager pone m.top.visible=false al
    ' pasar a otra pantalla, hay que respetarlo).
    if not m.top.visible then return
    m.scene.callFunc("SignalLaunchReady", "home")
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
            ' PlaylistListCarousel.tsx: una senal que el plan no incluye va a /suscribe.
            if selectedItem.itemData.blocked = true
                m.scene.callFunc("ShowSuscribePage", {})
            else
                ' PlaylistListCarousel.tsx: navigate("/en-vivo", { state: { initialChannelKey: key_live } }).
                m.scene.callFunc("OpenLive", selectedItem.itemData.url)
            end if
        else if isValid(selectedItem.itemData.type) AND selectedItem.itemData.type = "radio"
            ' RadioListCarousel.tsx: navigate('/radio', { state: { initialRadio: item } }).
            m.scene.callFunc("OpenRadio", { name: selectedItem.itemData.key, liveUrl: selectedItem.itemData.url })
        else if isValid(selectedItem.itemData.format) AND selectedItem.itemData.format = "tracking"
            OpenChapterLink(selectedItem.itemData.path, Int(convertToNumber(selectedItem.itemData.seconds)))
        else if selectedItem.sliderId = "destacados"
            OpenFeaturedItem(selectedItem.itemData)
        else
            m.scene.callFunc("showDetailPage", selectedItem)
        end if
    end if
end sub

' Abre un capitulo por su link (/programas/{slug}/{categoria}/{capitulo}),
' opcionalmente desde un segundo ("Seguir viendo"). La restriccion la valida el
' reproductor. Se apila la vista del programa debajo, porque en la web back
' desde el reproductor va a /programas/{slug}.
sub OpenChapterLink(link as dynamic, initialSeconds = 0 as integer)
    if not isNonEmptyString(link) then return
    parts = link.Split("/")
    if parts.count() < 4 OR parts[1] <> "programas" then return
    slug = parts[2]
    m.scene.callFunc("showDetailPage", { itemData: { url: "/programas/" + slug } })
    m.scene.callFunc("ShowPlayerPage", { link: link, slug: slug, initialSeconds: initialSeconds })
end sub

' Tarjetas de Destacados (FeaturedItem.tsx handleClick): si es en vivo (type
' "live" o un link que no es /programas/...) se reproduce directo con la key de
' rudo, como /player/live (back vuelve al Home); si no, es un capitulo.
sub OpenFeaturedItem(item as object)
    link = item.link
    isLive = item.type = "live" OR not isNonEmptyString(link) OR Instr(1, link, "programas/") = 0
    if isLive
        if not isNonEmptyString(item.rudoKey) then return
        m.scene.callFunc("ShowPlayerPage", {
            live: {
                key: item.rudoKey
                title: item.title
                restriction: item.restriction
                packs: item.packs
                vastUrl: item.vastUrl
                daiAssetKey: item.daiAssetKey
                image: item.image
            }
        })
    else
        OpenChapterLink(link)
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
        ' back: lo maneja MainScene (dialogo de salida, como la web)
    end if
    return handled
End Function