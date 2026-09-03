sub init()
    m.theme = m.global.appTheme
    m.fonts = m.global.fonts
    m.backgroundPoster = m.top.findNode("backgroundPoster")
    m.titleLabel = m.top.findNode("titleLabel")
    m.avatarGrid = m.top.findNode("avatarGrid")
    m.backButton = m.top.findNode("backButton")
    m.titleLabel.font = m.fonts.dmSansMedium24
    m.titleLabel.color = m.theme.white
    m.backgroundPoster.blendColor = m.theme.clrPrimary
    m.avatarGrid.observeField("itemSelected", "OnAvatarSelected")
    m.top.observeField("visible", "OnVisibleChanged")
    SetupBackButton()
end sub

sub SetupBackButton()
    btnFields = {
        focusTextColor: m.theme.white
        unfocusTextColor: m.theme.white
        backgroundColor: m.theme.clrSecondary
        focusBorderImage: m.theme.filledBackGroundImage
        focusBackgroundColor: m.theme.focPrimary
        fontSize: "dmSansMedium24"
        padding: 20
        posterImageSize: 35
        margin: 18
    }
    m.backButton.update(btnFields)
end sub

sub OnVisibleChanged()
    if m.top.visible
        SetFocus(m.avatarGrid)
        SetSelectedAvatarJumpIndex()
    end if
end sub

sub OnAvatarItemsChanged()
    content = CreateObject("roSGNode", "ContentNode")
    avatarItems = m.top.avatarItems
    if isValid(avatarItems)
        for each itemAA in avatarItems
            itemContent = CreateObject("roSGNode", "ContentNode")
            itemContent.id = itemAA.id
            itemContent.AddFields(itemAA)
            content.appendChild(itemContent)
        end for
    end if
    m.avatarGrid.content = content
    SetSelectedAvatarJumpIndex()
end sub

sub SetSelectedAvatarJumpIndex()
    if not isValid(m.avatarGrid.content) OR m.top.selectedAvatarId = invalid OR m.top.selectedAvatarId = ""
        return
    end if
    for i = 0 to m.avatarGrid.content.getChildCount() - 1
        itemContent = m.avatarGrid.content.getChild(i)
        if isValid(itemContent) AND itemContent.id = m.top.selectedAvatarId
            m.avatarGrid.jumpToItem = i
            exit for
        end if
    end for
end sub

sub OnAvatarSelected(event as dynamic)
    selectedIndex = event.getData()
    if not isValid(m.avatarGrid.content) OR selectedIndex < 0 OR selectedIndex >= m.avatarGrid.content.getChildCount()
        return
    end if
    selectedNode = m.avatarGrid.content.getChild(selectedIndex)
    if not isValid(selectedNode)
        return
    end if
    m.top.selectedAvatar = {
        id: selectedNode.id
        avatarType: selectedNode.avatarType
        profileUri: selectedNode.profileUri
    }
    m.top.selectedAvatarId = selectedNode.id
    m.top.selectionConfirmed = true
    m.top.closeRequested = true
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    result = true
    if press
        if key = "OK" 
            if m.backButton.hasFocus()
                m.top.selectionConfirmed = false
                m.top.closeRequested = true
            end if
        else if key = "up" AND m.avatarGrid.hasFocus()
            SetFocus(m.backButton)
        else if key = "down" AND m.backButton.hasFocus()
            SetFocus(m.avatarGrid)
        else if key = "back"
            m.top.selectionConfirmed = false
            m.top.closeRequested = true
        end if
    end if
    return result
end function
