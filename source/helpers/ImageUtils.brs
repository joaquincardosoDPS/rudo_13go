function GetImageURL(imageObject as Object, imgType = "normal" as String) as String
    if imageObject = invalid OR imageObject.Count() = 0 then return ""
    url = imageObject[imgType]
    if url <> invalid AND url <> "" then return url
    ' if isValid(url) AND not isEmptyString(url) then return url
    fallbackTypes = ["small", "medium", "normal", "big", "default"]
    for each imageType in fallbackTypes
        url = imageObject[imageType]
        if url <> invalid AND url <> "" then return url
    end for
    return ""
end function