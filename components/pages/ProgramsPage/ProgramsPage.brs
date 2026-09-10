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
    m.homeConfig = m.global.homeConfig
    m.rowSpacing = 134
end sub

sub setControls()
    m.focusableGroup = m.top.findNode("focusableGroup")
    m.focusableGroup.rowSpacing = m.rowSpacing
    m.pageLoader = m.top.findNode("pageLoader")
    m.noData = m.top.findNode("noData")
end sub

sub setupColor()
    m.noData.color = m.theme.white
    ' La vista de Programas no tiene hero: el header es contenido scrolleable,
    ' así que no se oscurece la barra superior.
    m.scene.hasTopMenuBackground = false
end sub

sub setupFonts()
    m.noData.font = m.fonts.dmSansBold32
end sub

sub setObservers()
    m.top.observeField("focusedChild", "OnFocusedChild")
    m.top.observeField("visible", "onVisibleChanged")
end sub

sub onVisibleChanged()
    if not m.top.visible
        clearTask()
    end if
end sub

sub onPageDestroy()
    if m.top.isDestroy
        clearTask()
        if isValid(m.focusableGroup) then m.focusableGroup.callFunc("clearNodes")
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
            if isValid(m.focusableGroup) AND m.focusableGroup.callFunc("getContainerChildCount") > 0
                SetFocus(m.focusableGroup)
            end if
        end if
    end if
end sub

sub initialize()
    setupHeader()
    callGetProgramsAPI()
end sub

sub setupHeader()
    header = createObject("roSGNode", "VodHeader")
    header.id = "vodHeader"
    header.componentHeight = 420
    header.title = "On Demand"
    header.description = "Revive lo mejor del 13." + Chr(10) + "Teleseries, realities, programas de entretención, documentales y más."
    if isValid(m.homeConfig)
        if isNonEmptyString(m.homeConfig.fondo_corporativo)
            header.backgroundImage = m.homeConfig.fondo_corporativo
        end if
    end if
    m.focusableGroup.callFunc("setTranslation", header)
end sub

sub ShowLoading(flag as boolean)
    m.pageLoader.visible = flag
end sub

sub callGetProgramsAPI()
    ShowLoading(true)
    m.GetProgramsTask = CreateObject("roSGNode", "ContentAPIAction")
    m.GetProgramsTask.functionName = "GetPrograms"
    m.GetProgramsTask.params = {}
    m.GetProgramsTask.observeField("result", "OnProgramsResult")
    m.GetProgramsTask.control = "RUN"
end sub

sub OnProgramsResult(event as dynamic)
    apiResponse = event.getData()
    categoriesByName = getValueFromProps(apiResponse, "data", {})
    print "ProgramsPage : OnProgramsResult : categories : " categoriesByName.count()
    if isValid(categoriesByName) AND categoriesByName.count() > 0
        for each categoryName in categoriesByName
            rawPrograms = categoriesByName[categoryName]
            if isValid(rawPrograms) AND rawPrograms.count() > 0
                items = []
                for each raw in rawPrograms
                    imageUrl = raw.imagen_vertical
                    items.push({
                        title: raw.titulo
                        key: raw.id
                        image_orientation: "portrait"
                        format: "default"
                        image_port: { small: imageUrl, medium: imageUrl, normal: imageUrl, big: imageUrl, default: imageUrl }
                    })
                end for
                PushCategoryRow(categoryName, items)
            end if
        end for
    end if
    manageFocus()
    ShowLoading(false)
    clearTask()
end sub

sub PushCategoryRow(title as string, items as object)
    if isValid(items) AND items.count() > 0
        catData = {}
        catData.title = title
        catData.format = "default"
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
        sliderView.componentHeight = 361
        catNode = buildCategoryContent(title, items)
        if isValid(catNode)
            sliderView.category = catData
            sliderView.content = catNode
        end if
        m.focusableGroup.callFunc("setTranslation", sliderView)
    end if
end sub

function buildCategoryContent(title as string, items as object) as dynamic
    mainContent = CreateObject("roSGNode", "ContentNode")
    rowNode = mainContent.CreateChild("ContentNode")
    rowNode.title = title
    rowNode.AddFields({ image_orientation: "portrait", liveCategory: false, format: "default", key: title })
    for each itemAA in items
        itemContent = CreateObject("roSGNode", "ProgramItemNode")
        itemContent.setFields(itemAA)
        rowNode.appendChild(itemContent)
    end for
    return mainContent
end function

sub manageFocus()
    m.noData.visible = false
    if isValid(m.focusableGroup) AND m.focusableGroup.callFunc("getContainerChildCount") > 0
        SetFocus(m.focusableGroup)
        ' Si la página ya tenía foco (el header se agrega en init, antes de que
        ' lleguen los datos), el SetFocus de arriba es no-op y el foco queda en el
        ' header. Forzar la primera fila de contenido.
        m.focusableGroup.callFunc("focusToFirstRow")
    else
        m.noData.visible = true
        SetFocus(m.noData)
    end if
end sub

sub onRowItemSelected(event as dynamic)
    selectedItem = event.getData()
    if isValid(selectedItem) AND isValid(selectedItem.itemData)
        item = {}
        item.itemData = selectedItem.itemData
        if isValid(selectedItem.itemData.isViewMoreCard) AND selectedItem.itemData.isViewMoreCard
            m.scene.callFunc("showCategoryDetailPage", item, false)
        else
            m.scene.callFunc("ShowDetailPage", item, false)
        end if
    end if
end sub

sub onRowItemFocused(event as dynamic)
    ' La vista web (VODView) no muestra detalle al enfocar; solo el carrusel.
end sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false
    if press
        if key = "back"
            if isValid(m.focusableGroup) AND (m.focusableGroup.hasFocus() OR m.focusableGroup.isInFocusChain())
                focusIndex = m.focusableGroup.callFunc("getFocusComponentIndex")
                firstContentIndex = m.focusableGroup.callFunc("getFirstContentIndex")
                if focusIndex > firstContentIndex
                    handled = m.focusableGroup.callFunc("focusToFirstRow")
                end if
            end if
        end if
    end if
    return handled
End Function
