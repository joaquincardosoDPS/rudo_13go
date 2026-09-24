' "Editar perfil" calcada de EditProfileView.tsx + use-edit-profile-data.ts.
' Foco virtual sobre gKeyboard para el input de nombre, el teclado y los
' avatares; "Guardar cambios" recibe foco real (CustomButton pinta su estado).
sub Init()
    print "EditProfilePage Init "
    SetLocals()
    SetControls()
    SetupFonts()
    SetupColor()
    m.top.observeField("focusedChild", "OnFocusedChild")
    SetupSaveButton()
    BuildKeyboard()
end sub

sub SetLocals()
    m.scene = m.top.GetScene()
    m.fonts = m.global.fonts
    m.theme = m.global.appTheme
    m.defaultProfileUri = "pkg:/images/other/default_user.png"
    m.name = ""
    m.selectedAvatar = ""
    m.avatarBaseUrl = ""
    m.avatarIds = []
    m.avatarNodes = []
    m.keyDefs = []
    m.keyNodes = []
    m.pendingRequests = 0
    m.isLoaded = false
    m.isSaving = false
    ' "name" | "keys" | "avatars" | "save"
    m.focusArea = "keys"
    m.keyIndex = 0
    m.avatarIndex = 0
    m.avatarScrollRow = 0
    ' Grilla del teclado: 7 columnas en los 21vw (403px) de la columna.
    m.keyCols = 7
    m.keyPitchX = 403 / 7
    m.keyPitchY = 68
    m.keyHeight = 64
    ' Avatares: 5 columnas de 8.5vw (163px), 710px visibles (37vw).
    m.avatarCols = 5
    m.avatarSize = 163
    m.avatarViewHeight = 710
end sub

sub SetControls()
    m.gContent = m.top.findNode("gContent")
    m.lTitle = m.top.findNode("lTitle")
    m.pPreview = m.top.findNode("pPreview")
    m.pPreviewFrame = m.top.findNode("pPreviewFrame")
    m.lNameTitle = m.top.findNode("lNameTitle")
    m.pInput = m.top.findNode("pInput")
    m.lInput = m.top.findNode("lInput")
    m.gKeyboard = m.top.findNode("gKeyboard")
    m.lAvatarTitle = m.top.findNode("lAvatarTitle")
    m.gAvatarClip = m.top.findNode("gAvatarClip")
    m.gAvatars = m.top.findNode("gAvatars")
    m.saveButton = m.top.findNode("saveButton")
end sub

sub SetupFonts()
    m.lTitle.font = m.fonts.dmSansBold48
    m.lNameTitle.font = m.fonts.dmSansBold36
    m.lAvatarTitle.font = m.fonts.dmSansBold36
    m.lInput.font = m.fonts.dmSansMedium23
end sub

sub SetupColor()
    m.lTitle.color = m.theme.white
    m.lNameTitle.color = m.theme.white
    m.lAvatarTitle.color = m.theme.white
end sub

' Mismo pill sin relleno que "Cerrar Sesión"/"Ver ahora" (.btn .btn-reanudar).
sub SetupSaveButton()
    m.saveButton.update({
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.white
        backgroundColor: m.theme.clrSecondaryText
        focusBackgroundColor: m.theme.focPrimary
        focusBorderImage: "pkg:/images/focus/R5T3_35px_outborder_nopadding.9.png"
        fontSize: "dmSansBold23"
        posterImage: "pkg:/images/focus/btnplay.png"
        addColorOnImage: true
        padding: 20
        posterImageSize: 20
        margin: 10
    })
end sub

' RAW_KEYS de EditProfileView.tsx: a-z, ñ, 0-9, Espacio (3 columnas) y borrar (2).
sub BuildKeyboard()
    chars = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "ñ", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "SPACE", "DEL"]
    cursor = 0
    for each char in chars
        span = 1
        if char = "SPACE" then span = 3
        if char = "DEL" then span = 2
        keyDef = { char: char, row: Int(cursor / m.keyCols), col: cursor MOD m.keyCols, span: span }
        m.keyDefs.Push(keyDef)
        node = CreateObject("roSGNode", "SearchKey")
        ' margin: 0 .1vw -> 2px a cada lado de la celda.
        node.keyWidth = (span * m.keyPitchX) - 4
        node.keyHeight = m.keyHeight
        node.keyChar = char
        node.translation = [(keyDef.col * m.keyPitchX) + 2, keyDef.row * m.keyPitchY]
        m.gKeyboard.appendChild(node)
        m.keyNodes.Push(node)
        cursor = cursor + span
    end for
    m.lastKeyRow = m.keyDefs[m.keyDefs.count() - 1].row
end sub

sub OnProfileIdSet()
    if not isNonEmptyString(m.top.profileId) then return
    m.scene.callFunc("ShowHideLoader", true)
    ' /appData/avatars trae la URL base y la lista (la web lo pide dos veces).
    m.pendingRequests = 2
    m.avatarsTask = RunAuthTask("GetAvatarBaseUrl", "OnGetAvatarsAPIResponse", invalid)
    m.profileTask = RunAuthTask("GetProfileData", "OnGetProfileDataAPIResponse", { profile: m.top.profileId })
end sub

function RunAuthTask(functionName as string, callback as string, params as dynamic) as object
    task = CreateObject("roSGNode", "AuthAPIAction")
    task.functionName = functionName
    if isValid(params) then task.params = params
    task.ObserveField("result", callback)
    task.control = "RUN"
    return task
end function

sub OnGetAvatarsAPIResponse(event as dynamic)
    response = event.getData()
    print "EditProfilePage : OnGetAvatarsAPIResponse : " FormatJson(response)
    m.avatarsTask = invalid
    m.avatarBaseUrl = getValueFromProps(response, "data.data.url.stringValue", "")
    m.avatarIds = FirestoreArray(getValueFromProps(response, "data.data", {}), "list")
    OnRequestFinished()
end sub

sub OnGetProfileDataAPIResponse(event as dynamic)
    response = event.getData()
    print "EditProfilePage : OnGetProfileDataAPIResponse : " FormatJson(response)
    m.profileTask = invalid
    fields = getValueFromProps(response, "data.data", {})
    m.name = FirestoreString(fields, "name")
    m.selectedAvatar = FirestoreString(fields, "avatar")
    OnRequestFinished()
end sub

sub OnRequestFinished()
    m.pendingRequests = m.pendingRequests - 1
    if m.pendingRequests > 0 then return
    m.scene.callFunc("ShowHideLoader", false)
    BuildAvatars()
    UpdateNameInput()
    UpdatePreview()
    m.gContent.visible = true
    m.isLoaded = true
    ' preferredChildFocusKey: la tecla "a".
    SetFocusArea("keys", 0)
end sub

sub BuildAvatars()
    m.gAvatars.removeChildrenIndex(m.gAvatars.getChildCount(), 0)
    m.avatarNodes = []
    for i = 0 to m.avatarIds.count() - 1
        node = CreateObject("roSGNode", "EditAvatarItem")
        node.translation = [(i MOD m.avatarCols) * m.avatarSize, Int(i / m.avatarCols) * m.avatarSize]
        node.uri = AvatarUri(m.avatarIds[i])
        m.gAvatars.appendChild(node)
        m.avatarNodes.Push(node)
    end for
    ' El boton va debajo de la grilla (hasta 37vw de alto), centrado.
    rows = Int((m.avatarNodes.count() + m.avatarCols - 1) / m.avatarCols)
    gridHeight = rows * m.avatarSize
    if gridHeight > m.avatarViewHeight then gridHeight = m.avatarViewHeight
    m.saveButton.translation = [1244 - 145, 204 + gridHeight]
end sub

function AvatarUri(avatarId as string) as string
    if isNonEmptyString(m.avatarBaseUrl) AND isNonEmptyString(avatarId)
        return m.avatarBaseUrl + avatarId + ".jpg"
    end if
    return m.defaultProfileUri
end function

sub UpdatePreview()
    uri = AvatarUri(m.selectedAvatar)
    m.pPreview.uri = uri
    m.pPreviewFrame.visible = uri <> m.defaultProfileUri
end sub

sub UpdateNameInput()
    if m.name = ""
        m.lInput.text = "Ingrese nombre..."
        m.lInput.color = "#FFFFFF80"
    else
        m.lInput.text = m.name
        m.lInput.color = m.theme.white
    end if
end sub

' ---- Foco ----

sub SetFocusArea(area as string, index as integer)
    if area = "avatars" AND m.avatarNodes.count() = 0 then area = "save"
    m.focusArea = area
    if area = "keys"
        m.keyIndex = index
    else if area = "avatars"
        m.avatarIndex = index
        ScrollAvatarsTo(Int(index / m.avatarCols))
    end if
    if area = "save"
        m.saveButton.setFocus(true)
    else
        m.gKeyboard.setFocus(true)
    end if
    ApplyFocusVisuals()
end sub

sub ApplyFocusVisuals()
    for i = 0 to m.keyNodes.count() - 1
        m.keyNodes[i].itemHasFocus = (m.focusArea = "keys") AND (i = m.keyIndex)
    end for
    for i = 0 to m.avatarNodes.count() - 1
        m.avatarNodes[i].itemHasFocus = (m.focusArea = "avatars") AND (i = m.avatarIndex)
    end for
    if m.focusArea = "name"
        m.pInput.uri = "pkg:/images/account/input_pill_focus.png"
    else
        m.pInput.uri = "pkg:/images/account/input_pill.png"
    end if
end sub

sub ClearFocusVisuals()
    for each node in m.keyNodes
        node.itemHasFocus = false
    end for
    for each node in m.avatarNodes
        node.itemHasFocus = false
    end for
    m.pInput.uri = "pkg:/images/account/input_pill.png"
end sub

sub OnFocusedChild()
    if not m.top.isInFocusChain()
        ClearFocusVisuals()
    else if m.top.hasFocus() AND m.isLoaded
        SetFocusArea(m.focusArea, CurrentIndex())
    end if
end sub

function CurrentIndex() as integer
    if m.focusArea = "avatars" then return m.avatarIndex
    return m.keyIndex
end function

' scrollIntoView({ block: "nearest" }): mueve la grilla solo lo justo para
' que la fila enfocada entre completa en los 710px visibles.
sub ScrollAvatarsTo(row as integer)
    visibleRows = Int(m.avatarViewHeight / m.avatarSize)
    if row < m.avatarScrollRow
        m.avatarScrollRow = row
    else if row > m.avatarScrollRow + visibleRows - 1
        m.avatarScrollRow = row - visibleRows + 1
    end if
    m.gAvatars.translation = [0, -m.avatarScrollRow * m.avatarSize]
end sub

' Tecla de la fila "row" que cubre la columna "col" (Espacio y borrar ocupan varias).
function KeyAt(row as integer, col as integer) as integer
    for i = 0 to m.keyDefs.count() - 1
        k = m.keyDefs[i]
        if k.row = row AND col >= k.col AND col < k.col + k.span then return i
    end for
    return -1
end function

' ---- Acciones ----

sub PressKey(index as integer)
    char = m.keyDefs[index].char
    if char = "DEL"
        if Len(m.name) > 0 then m.name = Left(m.name, Len(m.name) - 1)
    else if char = "SPACE"
        m.name = m.name + " "
    else
        m.name = m.name + char
    end if
    UpdateNameInput()
end sub

sub SelectAvatar(index as integer)
    m.selectedAvatar = m.avatarIds[index]
    UpdatePreview()
end sub

sub SaveProfile()
    if m.isSaving then return
    m.isSaving = true
    m.saveButton.buttonText = "Guardando..."
    m.saveTask = RunAuthTask("UpdateProfile", "OnUpdateProfileAPIResponse", {
        profile: m.top.profileId
        name: m.name
        avatar: m.selectedAvatar
    })
end sub

' Como la web (navigate('/mi-cuenta') si el POST no falla): vuelve a la
' cuenta, que recarga sus datos.
sub OnUpdateProfileAPIResponse(event as dynamic)
    response = event.getData()
    print "EditProfilePage : OnUpdateProfileAPIResponse : " FormatJson(response)
    m.saveTask = invalid
    m.isSaving = false
    m.saveButton.buttonText = "Guardar cambios"
    if getValueFromProps(response, "ok", false) = true
        m.scene.callFunc("UpdateCurrentProfile", {
            profileId: m.top.profileId
            profileName: m.name
            profileUri: AvatarUri(m.selectedAvatar)
        })
        m.scene.callFunc("CloseEditProfilePage", true)
    end if
end sub

' ---- Teclas (navegacion calcada de KeyboardButton/AvatarItem/ProfileEditDisplay) ----

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if not m.isLoaded then return false
    if m.focusArea = "keys"
        return HandleKeysKey(key)
    else if m.focusArea = "name"
        if key = "down"
            SetFocusArea("keys", 0)
            return true
        else if key = "right"
            SetFocusArea("avatars", 0)
            return true
        else if key = "left"
            return false
        end if
        return true
    else if m.focusArea = "avatars"
        return HandleAvatarsKey(key)
    else if m.focusArea = "save"
        if key = "OK"
            SaveProfile()
            return true
        else if key = "up"
            if m.avatarNodes.count() > 0
                lastRow = Int((m.avatarNodes.count() - 1) / m.avatarCols)
                target = lastRow * m.avatarCols + 2
                if target > m.avatarNodes.count() - 1 then target = m.avatarNodes.count() - 1
                SetFocusArea("avatars", target)
            else
                SetFocusArea("keys", m.keyDefs.count() - 1)
            end if
            return true
        else if key = "left"
            SetFocusArea("keys", m.keyDefs.count() - 1)
            return true
        end if
        return true
    end if
    return false
end function

' Izquierda en la primera columna sale al sidebar; derecha en la ultima va al
' primer avatar; arriba en la primera fila va al nombre; abajo en la ultima
' fila va a "Guardar cambios".
function HandleKeysKey(key as string) as boolean
    k = m.keyDefs[m.keyIndex]
    if key = "OK"
        PressKey(m.keyIndex)
        return true
    else if key = "left"
        if k.col = 0 then return false
        SetFocusArea("keys", KeyAt(k.row, k.col - 1))
        return true
    else if key = "right"
        if k.col + k.span - 1 >= m.keyCols - 1
            SetFocusArea("avatars", 0)
        else
            SetFocusArea("keys", KeyAt(k.row, k.col + k.span))
        end if
        return true
    else if key = "up"
        if k.row = 0
            SetFocusArea("name", 0)
        else
            SetFocusArea("keys", KeyAt(k.row - 1, k.col))
        end if
        return true
    else if key = "down"
        if k.row = m.lastKeyRow
            SetFocusArea("save", 0)
        else
            SetFocusArea("keys", KeyAt(k.row + 1, k.col))
        end if
        return true
    end if
    return false
end function

' Izquierda en la columna 0 vuelve al fin de la fila equivalente del teclado
' (KEYBOARD_RETURN_KEYS: g, n, t, 0, 7, borrar); abajo desde la ultima fila
' va a "Guardar cambios".
function HandleAvatarsKey(key as string) as boolean
    count = m.avatarNodes.count()
    row = Int(m.avatarIndex / m.avatarCols)
    col = m.avatarIndex MOD m.avatarCols
    lastRow = Int((count - 1) / m.avatarCols)
    if key = "OK"
        SelectAvatar(m.avatarIndex)
        return true
    else if key = "left"
        if col = 0
            returnKeys = ["g", "n", "t", "0", "7", "DEL"]
            target = returnKeys[MinInt(row, returnKeys.count() - 1)]
            for i = 0 to m.keyDefs.count() - 1
                if m.keyDefs[i].char = target then SetFocusArea("keys", i)
            end for
        else
            SetFocusArea("avatars", m.avatarIndex - 1)
        end if
        return true
    else if key = "right"
        if col < m.avatarCols - 1 AND m.avatarIndex + 1 < count then SetFocusArea("avatars", m.avatarIndex + 1)
        return true
    else if key = "up"
        if row > 0 then SetFocusArea("avatars", m.avatarIndex - m.avatarCols)
        return true
    else if key = "down"
        if m.avatarIndex + m.avatarCols < count
            SetFocusArea("avatars", m.avatarIndex + m.avatarCols)
        else if row < lastRow
            SetFocusArea("avatars", count - 1)
        else
            SetFocusArea("save", 0)
        end if
        return true
    end if
    return false
end function

function MinInt(a as integer, b as integer) as integer
    if a < b then return a
    return b
end function
