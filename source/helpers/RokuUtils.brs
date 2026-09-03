function GetRokuDeviceInfo() as object
    return CreateObject("roDeviceInfo")
end function

function GetOsVersion() as string
    version = GetRokuDeviceInfo().GetOSVersion()
    return version.major + "." + version.minor + "." + version.revision + "." + version.build
end function

function GetAppVersions() as string
    manifest = GetManifestsAsAA()

    major = manifest.major_version
    minor = manifest.minor_version
    build = manifest.build_version

    return major + "." + minor + "." + build
end function

Function GetAppOsVersion() as string
    version = createObject("roDeviceInfo").GetOSVersion()
    return version.major + "." + version.minor + "." + version.revision + "." + version.build
end Function

function GetDeviceModel() as string
    return GetRokuDeviceInfo().GetModel()
end function

function GetDisplayMode() as string
    return GetRokuDeviceInfo().GetDisplayMode()
end function

function GetChannelClientId() as string
    return GetRokuDeviceInfo().GetChannelClientId()
end function

function GetUserAgent() as string
    osVersion = GetOsVersion()
    appVersion = GetAppVersions()
    deviceModel = GetDeviceModel()
    return "Roku/" + osVersion + " lykstage/" + appVersion + " " + deviceModel
end function

function GetManifestsAsAA() as object
    manifest = {}

    text = ReadAsciiFile("pkg:/manifest")
    lines = text.Tokenize(Chr(10))

    for each line in lines
        line = line.Trim()
        if line.Len() = 0
        else if line.Left(1) = "#"
        else
            sepPos = line.Instr("=")
            if sepPos > 0
                name = line.Mid(0, sepPos)
                value = line.Mid(sepPos + 1)
                manifest.AddReplace(name, value)
            end if
        end if
    end for

    return manifest
end function

function firmwareSupportsCachefs() as Boolean
    return VersionSupported(8, 0, 0)
end function

function VersionSupported(majorRequirement as dynamic, minorRequirement as dynamic, buildRequirement = invalid as dynamic) as Boolean
    version = GetRokuDeviceInfo().GetOsVersion()

    if buildRequirement <> invalid
        buildRequirement = 0
    end if

    major = version.major
    minor = version.minor
    build = version.build

    isSupported = false
    if Val(major) > majorRequirement
        isSupported = true
    else if Val(major) = majorRequirement AND Val(minor) > minorRequirement
        isSupported = true
    else if Val(major) = majorRequirement AND Val(minor) = minorRequirement AND Val(build) >= buildRequirement
        isSupported = true
    end if

    return isSupported
end function

function GetRIDA() as string
    rida = GetRokuDeviceInfo().GetRIDA()
    isRIDADisabled = GetRokuDeviceInfo().IsRIDADisabled()
    if isRIDADisabled = false
        rida = GetUniqueId()
    end if
    return rida
end function

function GetRandomTempUUID() as string
    tempUUID = GetRokuDeviceInfo().GetRandomUUID()
    return tempUUID
end function

function GetUniqueId() as string
    deviceUniqueId = GetRokuDeviceInfo().GetChannelClientId()
    return deviceUniqueId
end function

function GetExternalIpAddress() as string
    return GetRokuDeviceInfo().GetExternalIp()
end function