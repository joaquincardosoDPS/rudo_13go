function GetAvatarImageUri(images as Dynamic, imgType = "normal" as String) as String
    if not isValid(images) OR Type(images) <> "roAssociativeArray" then return ""
    url = images[imgType]
    if isNonEmptyString(url) then return url
    fallbackTypes = ["small", "medium", "normal", "big", "default"]
    for each imageType in fallbackTypes
        url = images[imageType]
        if isNonEmptyString(url) then return url
    end for
    return ""
end function

function BuildAvatarData(avatarGroups as dynamic) as Object
    avatarData = {
        avatarImagesById: {}
        avatarInfoById: {}
        avatarListItems: []
    }
    if not isValid(avatarGroups)
        return avatarData
    end if
    for each groupAA in avatarGroups
        if Type(groupAA) <> "roAssociativeArray"
            continue for
        end if
        avatarType = ""
        if groupAA.DoesExist("name") AND groupAA.name <> invalid
            avatarType = groupAA.name
        end if
        if not groupAA.DoesExist("avatars") OR not isValid(groupAA.avatars)
            continue for
        end if
        for each avatarAA in groupAA.avatars
            if Type(avatarAA) <> "roAssociativeArray" OR not avatarAA.DoesExist("id")
                continue for
            end if
            avatarId = avatarAA.id
            images = invalid
            if avatarAA.DoesExist("images")
                images = avatarAA.images
            end if
            avatarItem = {
                id: avatarId
                avatarType: avatarType
                images: images
                profileUri: GetAvatarImageUri(images)
            }
            avatarData.avatarImagesById[avatarId] = images
            avatarData.avatarInfoById[avatarId] = avatarItem
            avatarData.avatarListItems.Push(avatarItem)
        end for
    end for
    return avatarData
end function

function GetImageFromObject(imageObject as Object, imgType = "small" as String) as String
    if imageObject = invalid OR imageObject.Count() = 0 then return ""
    url = imageObject[imgType]
    if isValid(url) AND not isEmptyString(url) then return url
    fallbackTypes = ["small", "medium", "normal", "big", "default"]
    for each imageType in fallbackTypes
        url = imageObject[imageType]
        if isValid(url) AND not isEmptyString(url) then return url
    end for
    return ""
end function
