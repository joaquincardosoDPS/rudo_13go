' Vista de programa calcada de ProgramView.tsx + use-program-data.ts.
' Foco: "Reanudar"/"Favoritos" y la grilla reciben foco real; el selector de
' categoria y su dropdown usan foco virtual sobre gFocusProxy.
sub Init()
    print "ProgramPage Init "
    SetLocals()
    SetControls()
    SetupFonts()
    SetupColor()
    SetupButtons()
    m.top.observeField("focusedChild", "OnFocusedChild")
    m.top.observeField("visible", "OnVisibleChange")
    m.chaptersGrid.observeField("itemFocused", "OnChapterFocused")
    m.chaptersGrid.observeField("itemSelected", "OnChapterSelected")
end sub

sub SetLocals()
    m.scene = m.top.GetScene()
    m.fonts = m.global.fonts
    m.theme = m.global.appTheme
    m.program = invalid
    m.categories = []
    m.selectedCategory = 0
    m.chapters = []
    m.resumeChapter = invalid
    m.resumeSeconds = 0
    m.isFavorite = false
    m.isFavoriteLoading = false
    m.isLoaded = false
    m.cancelled = false
    ' "resume" | "favorite" | "select" | "dropdown" | "grid" | "notfound"
    m.focusArea = "favorite"
    m.dropdownIndex = 0
    m.dropdownScroll = 0
    ' .custom-select-option: padding .8vw 1.2vw + texto de 1.2vw = 61px
    m.dropdownOptionHeight = 61
    m.dropdownMaxHeight = 300
    ' Al bajar de la primera fila de capitulos la pagina sube para que la
    ' grilla quede arriba (index < 5 = scroll al tope, como ChapterCard.tsx).
    m.gridTop = 672
    m.scrolledY = -(m.gridTop - 100)
    m.gridColumns = 5
    m.pageTargetY = 0
end sub

sub SetControls()
    m.gPage = m.top.findNode("gPage")
    m.pBackground = m.top.findNode("pBackground")
    m.lgHeader = m.top.findNode("lgHeader")
    m.lTitle = m.top.findNode("lTitle")
    m.lDescription = m.top.findNode("lDescription")
    m.gActions = m.top.findNode("gActions")
    m.resumeButton = m.top.findNode("resumeButton")
    m.favoriteButton = m.top.findNode("favoriteButton")
    m.lCategory = m.top.findNode("lCategory")
    m.pSelectArrow = m.top.findNode("pSelectArrow")
    m.lSummary = m.top.findNode("lSummary")
    m.chaptersGrid = m.top.findNode("chaptersGrid")
    m.lEmpty = m.top.findNode("lEmpty")
    m.gDropdown = m.top.findNode("gDropdown")
    m.rDropdownBorder = m.top.findNode("rDropdownBorder")
    m.rDropdownBg = m.top.findNode("rDropdownBg")
    m.gDropdownClip = m.top.findNode("gDropdownClip")
    m.gDropdownOptions = m.top.findNode("gDropdownOptions")
    m.gNotFound = m.top.findNode("gNotFound")
    m.lNotFound = m.top.findNode("lNotFound")
    m.backButton = m.top.findNode("backButton")
    m.gFocusProxy = m.top.findNode("gFocusProxy")
    m.scrollAnimation = m.top.findNode("scrollAnimation")
    m.scrollInterpolator = m.top.findNode("scrollInterpolator")
end sub

sub SetupFonts()
    m.lTitle.font = m.fonts.dmSansBold48
    m.lDescription.font = m.fonts.dmSansBold23
    m.lCategory.font = m.fonts.dmSansBold36
    m.lSummary.font = m.fonts.dmSansBold23
    m.lEmpty.font = m.fonts.dmSansMedium23
    m.lNotFound.font = m.fonts.dmSansBold48
end sub

sub SetupColor()
    m.lTitle.color = m.theme.white
    m.lDescription.color = m.theme.white
    m.lCategory.color = m.theme.white
    ' .sumario { color: var(--color-4) }
    m.lSummary.color = "#8C8C8C"
    m.lEmpty.color = "#8C8C8C"
    m.lNotFound.color = m.theme.white
end sub

' .btn .btn-reanudar (play) y .btn .btn-favoritos (estrella): pill sin relleno,
' borde gris que pasa a naranjo con foco.
sub SetupButtons()
    for each item in [{ node: m.resumeButton, icon: "pkg:/images/focus/btnplay.png" }, { node: m.favoriteButton, icon: "pkg:/images/program/icon_favorite.png" }, { node: m.backButton, icon: "" }]
        fields = {
            focusTextColor: m.theme.white
            unfocusTextColor: m.theme.white
            backgroundColor: m.theme.clrSecondaryText
            focusBackgroundColor: m.theme.focPrimary
            focusBorderImage: "pkg:/images/focus/R5T3_35px_outborder_nopadding.9.png"
            fontSize: "dmSansBold23"
            addColorOnImage: true
            padding: 20
            posterImageSize: 20
            margin: 10
        }
        if item.icon <> "" then fields.posterImage = item.icon
        item.node.update(fields)
    end for
    LayoutActions()
end sub

sub LayoutActions()
    x = 0
    if m.resumeButton.visible
        m.resumeButton.translation = [0, 0]
        x = 190 + 10
    end if
    m.favoriteButton.translation = [x, 0]
end sub

' ---- Datos ----

sub OnSlugSet()
    if not isNonEmptyString(m.top.slug) then return
    m.cancelled = false
    ShowLoading(true)
    m.programTask = RunTask("ContentAPIAction", "GetProgramBySlug", { slug: m.top.slug }, "OnProgramResponse")
end sub

' Back (o una pagina encima) mientras todavia carga: las respuestas pendientes
' se descartan y se apaga el spinner, que si no quedaba prendido sobre la
' pagina de abajo. Si la pagina vuelve a mostrarse sin haber cargado, reintenta.
sub OnVisibleChange()
    if not m.top.visible
        if not m.isLoaded
            m.cancelled = true
            ShowLoading(false)
        end if
    else if m.cancelled = true
        OnSlugSet()
    else if m.isLoaded
        LoadTracking()
        ' Volver a /programas/:slug es otra vista para GA4 (en la web ProgramView se vuelve a montar).
        TrackProgramView()
    end if
end sub

function RunTask(taskType as string, functionName as string, params as dynamic, callback as string) as object
    task = CreateObject("roSGNode", taskType)
    task.functionName = functionName
    if isValid(params) then task.params = params
    task.ObserveField("result", callback)
    task.control = "RUN"
    return task
end function

' Respuesta de una carga que ya se cancelo (ver OnVisibleChange).
function IsStale() as boolean
    return m.cancelled = true
end function

sub ShowLoading(flag as boolean)
    m.scene.callFunc("ShowHideLoader", flag)
end sub

sub OnProgramResponse(event as dynamic)
    if IsStale() then return
    m.programTask = invalid
    list = getValueFromProps(event.getData(), "data", [])
    if not isNotEmptyArray(list)
        ShowNotFound()
        return
    end if
    m.program = list[0]
    m.lTitle.text = decodeHtmlEntities(getValueFromProps(m.program, "title", ""))
    m.lDescription.text = StripHtml(getValueFromProps(m.program, "description", ""))
    m.pBackground.uri = getValueFromProps(m.program, "fondo_imagen", "")
    CenterHeader()
    m.categoriesTask = RunTask("ContentAPIAction", "GetProgramCategories", { slug: m.top.slug }, "OnCategoriesResponse")
    if m.scene.isUserLoggedIn
        m.favoritesTask = RunTask("AuthAPIAction", "GetFavorites", { profile: CurrentProfileOrder() }, "OnFavoritesResponse")
    end if
end sub

sub OnCategoriesResponse(event as dynamic)
    if IsStale() then return
    m.categoriesTask = invalid
    list = getValueFromProps(event.getData(), "data", [])
    m.categories = []
    if isNotEmptyArray(list)
        for each cat in list
            if isNonEmptyString(getValueFromProps(cat, "name", "")) then m.categories.Push(cat.name)
        end for
    end if
    RenderCategoryHeader()
    if m.categories.count() > 0
        LoadChapters(0)
    else
        ' La web se queda en el spinner si el programa no tiene categorias;
        ' aca se muestra la pagina con la grilla vacia.
        m.chapters = []
        RenderChapters()
        FinishLoading()
    end if
end sub

sub LoadChapters(index as integer)
    m.selectedCategory = index
    ShowLoading(true)
    m.chaptersTask = RunTask("ContentAPIAction", "GetProgramChapters", { slug: m.top.slug, category: m.categories[index] }, "OnChaptersResponse")
end sub

sub OnChaptersResponse(event as dynamic)
    if IsStale() then return
    m.chaptersTask = invalid
    list = getValueFromProps(event.getData(), "data.data", [])
    m.chapters = []
    ' "viejos primero si es on_air === 0" (allEpisodes.reverse())
    reverse = getValueFromProps(m.program, "on_air", "") = "0"
    if isNotEmptyArray(list)
        for i = 0 to list.count() - 1
            if reverse
                m.chapters.Push(list[list.count() - 1 - i])
            else
                m.chapters.Push(list[i])
            end if
        end for
    end if
    RenderCategoryHeader()
    RenderChapters()
    FinishLoading()
    m.resumeChapter = invalid
    UpdateResumeButton()
    LoadTracking()
end sub

' GA4 a mano, como ProgramView.tsx: trackPage(pathname, program.title || "Programa VOD").
sub TrackProgramView()
    title = getValueFromProps(m.program, "title", "")
    if not isNonEmptyString(title) then title = "Programa VOD"
    m.scene.callFunc("TrackPage", { path: "/programas/" + m.top.slug, title: title })
end sub

' Historial del perfil -> boton "Reanudar". Se vuelve a pedir al volver del
' reproductor (en la web ProgramView se vuelve a montar y lo pide de nuevo).
sub LoadTracking()
    if m.scene.isUserLoggedIn AND m.chapters.count() > 0
        m.trackingTask = RunTask("AuthAPIAction", "GetTracking", { profile: CurrentProfileOrder() }, "OnTrackingResponse")
    end if
end sub

sub FinishLoading()
    ShowLoading(false)
    m.gPage.visible = true
    if not m.isLoaded
        m.isLoaded = true
        TrackProgramView()
        ' Foco inicial: Reanudar si hay, si no Favoritos.
        if m.top.isInFocusChain() then SetFocusArea("favorite")
    end if
end sub

' Busca el primer capitulo con progreso (event_type=progress) entre el 10s y el
' 95% de la duracion, como el efecto de tracking de use-program-data.ts.
sub OnTrackingResponse(event as dynamic)
    if IsStale() then return
    m.trackingTask = invalid
    items = getValueFromProps(event.getData(), "data.data", [])
    resumeChapter = invalid
    resumeSeconds = 0
    if not isNotEmptyArray(items) then items = []
    progress = {}
    for each item in items
        fields = getValueFromProps(item, "fields", {})
        if getValueFromProps(fields, "event_type.stringValue", "") = "progress"
            keyRudo = getValueFromProps(item, "key_rudo", "")
            if isNonEmptyString(keyRudo) AND not progress.DoesExist(keyRudo) then progress[keyRudo] = fields
        end if
    end for
    for each chapter in m.chapters
        fields = progress[getValueFromProps(chapter, "key", "")]
        if isValid(fields)
            seconds = convertToNumber(getValueFromProps(fields, "seconds.integerValue", "0"))
            duration = convertToNumber(getValueFromProps(fields, "duration.integerValue", "0"))
            if seconds > 10 AND seconds < (duration * 0.95)
                resumeChapter = chapter
                resumeSeconds = seconds
                exit for
            end if
        end if
    end for
    m.resumeChapter = resumeChapter
    m.resumeSeconds = resumeSeconds
    UpdateResumeButton()
    ' La web re-enfoca "Reanudar" apenas aparece; solo si el foco sigue en los botones.
    if isValid(m.resumeChapter) AND m.focusArea = "favorite" AND m.top.isInFocusChain() then SetFocusArea("resume")
end sub

sub UpdateResumeButton()
    m.resumeButton.visible = isValid(m.resumeChapter)
    LayoutActions()
    if not m.resumeButton.visible AND m.focusArea = "resume" then SetFocusArea("favorite")
end sub

' Favorito si algun item activo coincide por nid, slug o id_program.
sub OnFavoritesResponse(event as dynamic)
    m.favoritesTask = invalid
    favorites = getValueFromProps(event.getData(), "data.data", {})
    m.isFavorite = false
    configId = getValueFromProps(m.program, "config_id", "")
    slug = getValueFromProps(m.program, "slug", "")
    if isValid(getInterface(favorites, "ifAssociativeArray"))
        for each key in favorites
            fields = getValueFromProps(favorites[key], "fields", {})
            status = getValueFromProps(fields, "status.stringValue", "")
            matches = getValueFromProps(fields, "nid.stringValue", "") = configId OR getValueFromProps(fields, "slug.stringValue", "") = slug OR getValueFromProps(fields, "id_program.stringValue", "") = configId
            if matches AND status <> "inactive"
                m.isFavorite = true
                exit for
            end if
        end for
    end if
    UpdateFavoriteButton()
end sub

sub UpdateFavoriteButton()
    if m.isFavoriteLoading
        m.favoriteButton.buttonText = "Guardando..."
    else if m.isFavorite
        m.favoriteButton.buttonText = "Quitar de favoritos"
    else
        m.favoriteButton.buttonText = "Agregar a favoritos"
    end if
end sub

sub ToggleFavorite()
    if not m.scene.isUserLoggedIn OR not isValid(m.program) OR m.isFavoriteLoading then return
    m.isFavoriteLoading = true
    UpdateFavoriteButton()
    status = "active"
    if m.isFavorite then status = "inactive"
    m.pendingFavorite = not m.isFavorite
    m.saveFavoriteTask = RunTask("AuthAPIAction", "SaveFavorite", {
        profile: CurrentProfileOrder()
        nid: getValueFromProps(m.program, "config_id", "")
        tid: getValueFromProps(m.program, "tid", "")
        title: getValueFromProps(m.program, "title", "")
        slug: getValueFromProps(m.program, "slug", "")
        imagen_vertical: getValueFromProps(m.program, "imagen_vertical", "")
        url: "/programas/" + getValueFromProps(m.program, "slug", "")
        status: status
    }, "OnSaveFavoriteResponse")
end sub

sub OnSaveFavoriteResponse(event as dynamic)
    m.saveFavoriteTask = invalid
    m.isFavoriteLoading = false
    if getValueFromProps(event.getData(), "ok", false) = true then m.isFavorite = m.pendingFavorite
    UpdateFavoriteButton()
end sub

function CurrentProfileOrder() as string
    return getValueFromProps(m.scene.ProfileData, "profileId", "")
end function

function IsRestricted(chapter as object) as boolean
    return ValidateRestriction(getValueFromProps(chapter, "restriction", "0"), getValueFromProps(chapter, "packs", []))
end function

' ---- Render ----

sub CenterHeader()
    ' .programas-cabecera: min-height 29.17vw con el contenido centrado.
    height = m.lgHeader.boundingRect().height
    y = Int((560 - height) / 2)
    if y < 90 then y = 90
    m.lgHeader.translation = [206, y]
end sub

sub RenderCategoryHeader()
    hasSelect = m.categories.count() > 1
    if m.categories.count() = 0
        m.lCategory.text = "Capítulos"
    else
        m.lCategory.text = m.categories[m.selectedCategory]
    end if
    m.pSelectArrow.visible = hasSelect
    m.lCategory.translation = [0, 0]
    if hasSelect
        ' Un <select> mide lo que su opcion mas larga; la flecha (background
        ' right center) va en el padding-right de 1.9vw (36px).
        selected = m.lCategory.text
        widest = 0
        for each name in m.categories
            m.lCategory.text = name
            w = m.lCategory.boundingRect().width
            if w > widest then widest = w
        end for
        m.lCategory.text = selected
        if widest <= 0 then widest = 300
        m.selectWidth = widest + 36
        m.pSelectArrow.translation = [m.selectWidth - 24, 10]
    end if
    UpdateSelectVisuals()
    m.lSummary.text = m.chapters.count().ToStr() + " videos"
end sub

' select.titulo-2.focus { color: var(--color-1) }: con foco solo el texto pasa
' a naranjo; la flecha es un background blanco y no cambia.
sub UpdateSelectVisuals()
    focused = (m.focusArea = "select" OR m.focusArea = "dropdown") AND m.categories.count() > 1
    if focused
        m.lCategory.color = m.theme.focPrimary
    else
        m.lCategory.color = m.theme.white
    end if
end sub

sub RenderChapters()
    content = CreateObject("roSGNode", "ContentNode")
    for each chapter in m.chapters
        node = content.CreateChild("ContentNode")
        node.title = decodeHtmlEntities(getValueFromProps(chapter, "title", ""))
        node.AddFields({
            image: getValueFromProps(chapter, "image", "")
            duration: getValueFromProps(chapter, "duration", "")
            blocked: IsRestricted(chapter)
        })
    end for
    m.chaptersGrid.content = content
    ' Filas visibles: 3 (la grilla scrollea sola despues de la primera fila).
    m.chaptersGrid.visible = m.chapters.count() > 0
    m.lEmpty.visible = m.chapters.count() = 0
    m.lSummary.text = m.chapters.count().ToStr() + " videos"
end sub

sub ShowNotFound()
    ShowLoading(false)
    m.isLoaded = true
    m.gPage.visible = false
    m.gNotFound.visible = true
    SetFocusArea("notfound")
end sub

' ---- Dropdown del selector de categoria (CategorySelect.tsx) ----

sub OpenDropdown()
    m.dropdownIndex = m.selectedCategory
    m.gDropdownOptions.removeChildrenIndex(m.gDropdownOptions.getChildCount(), 0)
    width = m.selectWidth
    for i = 0 to m.categories.count() - 1
        option = CreateObject("roSGNode", "Group")
        option.translation = [0, i * m.dropdownOptionHeight]
        bg = option.CreateChild("Rectangle")
        bg.width = width - 2
        bg.height = m.dropdownOptionHeight
        bg.color = m.theme.focPrimary
        bg.visible = false
        label = option.CreateChild("Label")
        label.text = m.categories[i]
        label.font = m.fonts.dmSansMedium23
        label.color = m.theme.white
        label.width = width - 2 - 46
        label.height = m.dropdownOptionHeight
        label.vertAlign = "center"
        label.translation = [23, 0]
        m.gDropdownOptions.appendChild(option)
    end for
    height = m.categories.count() * m.dropdownOptionHeight
    if height > m.dropdownMaxHeight then height = m.dropdownMaxHeight
    ' Arriba del select, con 0.5vw de separacion.
    m.gDropdown.translation = [206, 560 + m.pageTargetY - height - 2 - 10]
    m.rDropdownBorder.width = width
    m.rDropdownBorder.height = height + 2
    m.rDropdownBg.width = width - 2
    m.rDropdownBg.height = height
    m.gDropdownClip.translation = [1, 1]
    m.gDropdownClip.clippingRect = [0, 0, width - 2, height]
    m.dropdownVisibleRows = Int(height / m.dropdownOptionHeight)
    m.dropdownScroll = 0
    m.gDropdown.visible = true
    SetFocusArea("dropdown")
    UpdateDropdown()
end sub

sub UpdateDropdown()
    if m.dropdownIndex < m.dropdownScroll then m.dropdownScroll = m.dropdownIndex
    if m.dropdownIndex > m.dropdownScroll + m.dropdownVisibleRows - 1 then m.dropdownScroll = m.dropdownIndex - m.dropdownVisibleRows + 1
    m.gDropdownOptions.translation = [0, -m.dropdownScroll * m.dropdownOptionHeight]
    for i = 0 to m.gDropdownOptions.getChildCount() - 1
        m.gDropdownOptions.getChild(i).getChild(0).visible = (i = m.dropdownIndex)
    end for
end sub

sub CloseDropdown()
    m.gDropdown.visible = false
    SetFocusArea("select")
end sub

' ---- Foco ----

sub SetFocusArea(area as string)
    if area = "resume" AND not m.resumeButton.visible then area = "favorite"
    if area = "select" AND m.categories.count() < 2 then area = "favorite"
    m.focusArea = area
    if area = "resume"
        m.resumeButton.setFocus(true)
    else if area = "favorite"
        m.favoriteButton.setFocus(true)
    else if area = "grid"
        m.chaptersGrid.setFocus(true)
    else if area = "notfound"
        m.backButton.setFocus(true)
    else
        m.gFocusProxy.setFocus(true)
    end if
    if area <> "grid" then ScrollPageTo(0)
    UpdateSelectVisuals()
end sub

' Anima desde donde este la pagina en ese momento (aunque vaya a mitad de otra
' animacion), asi un cambio de direccion no salta.
sub ScrollPageTo(y as integer)
    if m.pageTargetY = y then return
    m.pageTargetY = y
    if m.scrollAnimation.state = "running" then m.scrollAnimation.control = "stop"
    m.scrollInterpolator.keyValue = [m.gPage.translation, [0, y]]
    m.scrollAnimation.control = "start"
end sub

sub OnChapterFocused(event as dynamic)
    if m.focusArea <> "grid" then return
    ScrollForChapter(event.getData())
end sub

sub ScrollForChapter(index as integer)
    if index < m.gridColumns
        ScrollPageTo(0)
    else
        ScrollPageTo(m.scrolledY)
    end if
end sub

sub OnFocusedChild()
    if m.top.hasFocus() AND m.isLoaded
        ' Vuelta desde el sidebar (FocusTop) o desde otra pagina apilada.
        area = m.focusArea
        if area = "dropdown" then area = "select"
        m.gDropdown.visible = false
        SetFocusArea(area)
    else if not m.top.isInFocusChain()
        m.gDropdown.visible = false
        UpdateSelectVisuals()
    end if
end sub

function GoUpFromGrid() as boolean
    if m.categories.count() > 1
        SetFocusArea("select")
    else if m.resumeButton.visible
        SetFocusArea("resume")
    else
        SetFocusArea("favorite")
    end if
    return true
end function

function GoDownFromButtons() as boolean
    if m.categories.count() > 1
        SetFocusArea("select")
    else if m.chapters.count() > 0
        FocusGrid(0)
    end if
    return true
end function

sub FocusGrid(index as integer)
    m.chaptersGrid.jumpToItem = index
    SetFocusArea("grid")
    ScrollForChapter(index)
end sub

' ---- Capitulos ----

sub OnChapterSelected(event as dynamic)
    index = event.getData()
    if index >= 0 AND index < m.chapters.count() then ChapterClick(m.chapters[index], 0)
end sub

' handleChapterClick de ProgramView.tsx.
sub ChapterClick(chapter as object, initialSeconds as integer)
    restriction = getValueFromProps(chapter, "restriction", "0")
    requiresLogin = restriction <> "0" AND restriction <> "2" AND m.scene.isUserLoggedIn <> true
    if requiresLogin
        m.scene.callFunc("ShowOnboardingPage", false)
        return
    end if
    if restriction = "1" AND IsRestricted(chapter)
        ' /suscribe (SuscribeView) todavia no esta portada.
        print "ProgramPage : ChapterClick : capitulo bloqueado (requiere suscripcion) : " getValueFromProps(chapter, "link", "")
        return
    end if
    ' navigate(chapter.link, { state: { initialSeconds } })
    m.scene.callFunc("ShowPlayerPage", {
        link: getValueFromProps(chapter, "link", "")
        slug: m.top.slug
        initialSeconds: initialSeconds
    })
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if not m.isLoaded then return false
    area = m.focusArea
    if area = "notfound"
        if key = "OK"
            m.scene.callFunc("HandleBackKey")
            return true
        end if
        return key <> "left" AND key <> "back"
    else if area = "resume"
        if key = "OK"
            if isValid(m.resumeChapter) then ChapterClick(m.resumeChapter, m.resumeSeconds)
            return true
        else if key = "right"
            SetFocusArea("favorite")
            return true
        else if key = "down"
            return GoDownFromButtons()
        else if key = "left"
            return false
        end if
        return key = "up"
    else if area = "favorite"
        if key = "OK"
            ToggleFavorite()
            return true
        else if key = "left"
            if m.resumeButton.visible
                SetFocusArea("resume")
                return true
            end if
            return false
        else if key = "down"
            return GoDownFromButtons()
        end if
        return key = "up" OR key = "right"
    else if area = "select"
        if key = "OK"
            OpenDropdown()
            return true
        else if key = "down"
            if m.chapters.count() > 0 then FocusGrid(0)
            return true
        else if key = "up"
            if m.resumeButton.visible
                SetFocusArea("resume")
            else
                SetFocusArea("favorite")
            end if
            return true
        else if key = "left"
            return false
        end if
        return key = "right"
    else if area = "dropdown"
        if key = "up"
            if m.dropdownIndex > 0 then m.dropdownIndex = m.dropdownIndex - 1
            UpdateDropdown()
        else if key = "down"
            if m.dropdownIndex < m.categories.count() - 1 then m.dropdownIndex = m.dropdownIndex + 1
            UpdateDropdown()
        else if key = "OK"
            selected = m.dropdownIndex
            CloseDropdown()
            if selected <> m.selectedCategory then LoadChapters(selected)
        else if key = "back"
            CloseDropdown()
        end if
        return true
    else if area = "grid"
        ' El MarkupGrid ya consumio las flechas que puede resolver: lo que
        ' llega aca es un borde de la grilla.
        index = m.chaptersGrid.itemFocused
        if key = "up"
            if index < m.gridColumns then return GoUpFromGrid()
            return true
        else if key = "left"
            return false
        end if
        return key = "right" OR key = "down"
    end if
    return false
end function

' La bajada del CMS trae HTML (<br />, entidades); la web la muestra tal cual,
' en la TV se limpia a texto plano.
function StripHtml(value as dynamic) as string
    if not isNonEmptyString(value) then return ""
    tags = CreateObject("roRegex", "<[^>]*>", "")
    text = tags.ReplaceAll(value, " ")
    spaces = CreateObject("roRegex", "\s+", "")
    text = spaces.ReplaceAll(text, " ")
    return decodeHtmlEntities(text.Trim())
end function
