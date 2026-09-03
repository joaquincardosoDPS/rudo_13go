function IsNullOrEmpty(s as dynamic) as boolean
    return s = invalid OR s = ""
end function

function isValid(obj as dynamic) as boolean
    return (type(obj) <> "<uninitialized>" AND obj <> invalid)
end function

function isInvalid(value as dynamic) as boolean
    return (not isValid(value))
end function

function iif(condition as boolean, thenCb as dynamic, elseCb = invalid as dynamic) as dynamic
    if (condition) then return thenCb
    return elseCb
end function

function isString(obj as dynamic) as boolean
    objType = Type(obj)
    return (objType = "String" OR objType = "roString")
end function

function isNonEmptyString(value as dynamic) as boolean
    return isString(value) AND value <> ""
end function

function isEmptyString(value as dynamic) as boolean
    return isString(value) AND value = ""
end function

function getValueFromProps(obj as object, path as string, placeholder = invalid as dynamic) as dynamic
    if (not (isValid(getInterface(obj, "ifAssociativeArray")) OR isNotEmptyArray(obj)) OR path = "")
        return placeholder
    end if
    keys = path.tokenize(".").toArray()
    for each key in keys
        if isValid(getInterface(obj, "ifAssociativeArray"))
            obj = obj[key]
        else if ((Type(obj) = "roArray") AND not obj.isEmpty())
            obj = obj[convertToNumber(key)]
        else
            return placeholder
        end if
    end for
    if isInvalid(obj) then return placeholder
    return obj
end function

function isAssocArray(obj as dynamic) as boolean
    if (isValid(obj))
        return (type(obj) = "roAssociativeArray")
    end if
    return false
end function

function isNotEmptyArray(value as dynamic) as boolean
    return (type(value) = "roArray" AND not value.isEmpty())
end function

function isNotEmptyAA(value as dynamic) as boolean
    return (isAssocArray(value) AND not value.isEmpty())
end function

function GetAAString(sourceAA as Object, key as String) as String
    if not IsAssocArray(sourceAA)
        return ""
    end if
    if not sourceAA.DoesExist(key)
        return ""
    end if
    if sourceAA[key] = invalid
        return ""
    end if
    return sourceAA[key].ToStr()
end function

function FirstNonEmptyString(values as Object) as String
    for each value in values
        if value <> invalid
            textValue = value.ToStr().Trim()
            if textValue <> "" then return textValue
        end if
    end for
    return ""
end function

function isNumber(obj as dynamic) as boolean
    if (isValid(obj) AND isValid(getInterface(obj, "ifInt"))) then return true
    if (isValid(obj) AND isValid(getInterface(obj, "ifLongInt"))) then return true
    if (isValid(obj) AND isValid(getInterface(obj, "ifFloat"))) then return true
    if ((type(obj) = "Double") OR (type(obj) = "roDouble") OR (type(obj) = "roIntrinsicDouble")) then return true
    return false
end function

function convertToNumber(value as dynamic) as dynamic
    if isNumber(value)
        return value
    else if (type(value) = "Boolean" OR type(value) = "roBoolean")
        if value then return 1
        return 0
    end if
    if (type(value) = "String" OR type(value) = "roString")
        if (value.Instr(".") > -1)
            return val(value)
        else
            return val(value, 10)
        end if
    end if
    return 0
end function

function ok(data as dynamic) as object
    result = {}
    result.ok = true
    result.data = data
    return result
end function

function error(data as string) as object
    result = {}
    result.ok = false
    result.error = data
    return result
end function

function getErrorReason(response as dynamic) as string
    unknown = "Unknown error. Please check your input, internet connection and try again"
    ' print "HelpFuncs : getErrorReason : ResponseError : " response
    if (response.reason.Len() = 0)
        return unknown
    else
        if (response.code = 422 OR response.code = 403 OR response.code = 404)
            data = ParseJSON(response.reason)
            if isInvalid(data) 'If, this is not json
                return response.reason
            end if
            msg = ""
            if isValid(data.message)
                msg = data.message
            else if isValid(data.detail)
                msg = data.detail
            end if
            return msg
        else
            return response.reason
        end if
    end if
end function

function doubleCheck(condition as boolean, result1 as dynamic, result2 as dynamic) as dynamic
    if condition then
        return result1
    else
        return result2
    end if
end function

function checkAndReturnSecond(dateString = "" as String) as integer
    if isEmptyString(dateString) then return 300
    dateFormat = CreateObject("roDateTime")
    currentTime = dateFormat.asSeconds()
    dateStringFormat = CreateObject("roDateTime")
    if dateString <> invalid AND dateString <> ""
        dateStringFormat.fromISO8601String(dateString)
    end if
    dateToSecond = dateStringFormat.asSeconds()
    return dateToSecond - currentTime
end function

function getBadgeText(content as dynamic, isPageDetail = false as boolean) as dynamic
    if isInvalid(content) then return ""
    if content.gmt0_unlocked = invalid OR content.gmt0_unlocked = "" then return ""
    date = CreateObject("roDateTime")
    date.FromISO8601String(content.gmt0_unlocked)
    startTimeInSec = date.AsSeconds()
    currentTimeInSec = CreateObject("roDateTime").AsSeconds()
    if startTimeInSec <= currentTimeInSec
        return "EN VIVO"
    else if isPageDetail
        return "PRÓXIMAMENTE - " + GetFormattedLocalTime(startTimeInSec)
    else
        return "PRÓXIMAMENTE"
    end if
end function

' Converts seconds into "DD-MM-YYYY, HH:MM" format
Function GetFormattedLocalTime(seconds As Integer) As String
    dateTime = CreateObject("roDateTime")
    dateTime.FromSeconds(seconds)
    dateTime.ToLocalTime()
    day = dateTime.GetDayOfMonth().ToStr()
    month = dateTime.GetMonth().ToStr()
    year = dateTime.GetYear().ToStr()
    hours = dateTime.GetHours().ToStr()
    minutes = dateTime.GetMinutes().ToStr()
    If day.Len() = 1 Then day = "0" + day
    If month.Len() = 1 Then month = "0" + month
    If hours.Len() = 1 Then hours = "0" + hours
    If minutes.Len() = 1 Then minutes = "0" + minutes
    Return day + "-" + month + "-" + year + ", " + hours + ":" + minutes
End Function


Sub GlobalSet(key as String, entity as Dynamic)
    If(type(entity) = invalid) then
        Print "*** Utilities ERROR *** GlobalSet"
    Else
        If(m.global.HasField(key)) then
            m.global.setField(key, entity)
        Else
            obj = {}
            obj[key] = entity
            m.global.AddFields(obj)
        End If
    End If
End Sub

Function GlobalGet(key as String, default = invalid as Dynamic) as Dynamic
    If(m.global.HasField(key)) then
        Return m.global.GetField(key)
    Else
        Return default
    End If
End Function

function getSpanishFormattedDate(dateStr as String) as String
    if dateStr = invalid OR dateStr = "" then return ""
    parts = dateStr.split("-")
    if parts.count() <> 3 then return dateStr
    year = parts[0]
    month = val(parts[1])
    day = val(parts[2])
    months = [
        "enero", "febrero", "marzo", "abril", "mayo", "junio",
        "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
    ]
    if month < 1 OR month > 12 then return dateStr
    return day.toStr() + " " + months[month - 1] + " " + year
end function

function getSpanishEventDateTimeText(dateStr as String) as String
    if not isNonEmptyString(dateStr) then return ""
    dateTime = CreateObject("roDateTime")
    dateTime.FromISO8601String(dateStr)
    dateTime.ToLocalTime()
    weekdays = ["DOM", "LUN", "MAR", "MIÉ", "JUE", "VIE", "SÁB"]
    months = [
        "ENERO", "FEBRERO", "MARZO", "ABRIL", "MAYO", "JUNIO",
        "JULIO", "AGOSTO", "SEPTIEMBRE", "OCTUBRE", "NOVIEMBRE", "DICIEMBRE"
    ]
    weekdayIndex = dateTime.GetDayOfWeek()
    monthIndex = dateTime.GetMonth() - 1
    if weekdayIndex < 0 OR weekdayIndex >= weekdays.count() then return ""
    if monthIndex < 0 OR monthIndex >= months.count() then return ""
    day = getTwoDigitDatePart(dateTime.GetDayOfMonth())
    hours = getTwoDigitDatePart(dateTime.GetHours())
    minutes = getTwoDigitDatePart(dateTime.GetMinutes())
    return weekdays[weekdayIndex] + ", " + day + " DE " + months[monthIndex] + ", " + hours + ":" + minutes + " HRS"
end function

function getTwoDigitDatePart(value as Integer) as String
    text = value.ToStr()
    if text.Len() = 1 then text = "0" + text
    return text
end function

function getMaskSize(posterNode as dynamic)
    maskSize = [posterNode.BoundingRect().width, posterNode.BoundingRect().height]
    if m.global.designresolution = "720p"
        maskSize = [maskSize[0] / 1.5, maskSize[1] / 1.5]
    end if
    return maskSize
end function

Function FormatTime(timeInSecond as integer, fullTimeFormat = false as boolean) as String
    if (timeInSecond <> invalid)
        timeInSecond = timeInSecond
        timeInSecond = timeInSecond MOD (24 * 3600)
        hours = timeInSecond \ 3600
        timeInSecond = timeInSecond MOD 3600
        minutes = timeInSecond \ 60
        timeInSecond = timeInSecond MOD 60
        seconds = timeInSecond

        hrStr = hours.toStr()
        minutesStr = minutes.toStr()
        secondsStr = seconds.toStr()

        if (hours < 10)
            hrStr = "0" + hrStr
        end if
        if (minutes < 10)
            minutesStr = "0" + minutesStr
        end if
        if (seconds < 10)
            secondsStr = "0" + secondsStr
        end if
        if(fullTimeFormat = false)
            if(hrStr = "00" AND minutesStr = "00")
                return minutesStr + ":" + secondsStr
            else if hrStr = "00" AND minutesStr <> "00"
                return minutesStr + ":" + secondsStr
            else
                return hrStr + ":" + minutesStr + ":" + secondsStr
            end if
        else
            return hrStr + ":" + minutesStr + ":" + secondsStr
        end if
    else
        return ""
    end if
End Function

function getValue(val as dynamic) as string
    if val = invalid OR val = "" then
        return "-"
    end if
    return val
end function

function isBoolean(value as dynamic) as boolean
    return isValid(value) AND GetInterface(value, "ifBoolean") <> invalid
end function

function insertArrayValue(arr as object, index as integer, value as dynamic) as object
    newArr = []
    arrCount = arr.count()
    for i = 0 to arrCount
        if i = index then newArr.push(value)
        if i < arrCount then newArr.push(arr[i])
    end for
    return newArr
end function

function getProgressPercent(progress as integer, duration as integer) as integer
    if progress <= 0 OR duration <= 0 then return 0
    percent = (progress * 100.0) / duration
    return Cint(percent)
end function

function hasResumeProgress(progressPercent as integer) as boolean
    return progressPercent >= 0 AND progressPercent <= 98
end function

function createDateLabel(dateStart, dateEnd, badgeObj = invalid as dynamic)
    dateTimeString = ""
    startDate = CreateObject("roDateTime")
    startDate.FromISO8601String(dateStart)
    startDate.ToLocalTime()
    startDateSeconds = startDate.AsSeconds()
    dateTimeString += formatTimeStringInHHMM(startDateSeconds)

    endDate = CreateObject("roDateTime")
    endDate.FromISO8601String(dateEnd)
    endDate.ToLocalTime()
    endDateSeconds = endDate.AsSeconds()
    dateTimeString += " - " + formatTimeStringInHHMM(endDateSeconds)

    dateTimeString += " (" + getDurationFormated(endDateSeconds - startDateSeconds) + ")"

    dateText = CreateObject("roSGNode", "Label")
    dateText.color = m.theme.white
    dateText.font = m.fonts.poppinsMedium18
    dateText.text = dateTimeString
    if isValid(badgeObj)
        dateText.height = badgeObj.boundingRect().height
    end if
    dateText.vertAlign = "center"
    return dateText
end function

function formatTimeStringInHHMM(timeInSecond as integer) as string
    if (timeInSecond <> invalid)
        timeInSecond = timeInSecond mod (24 * 3600)
        hours = timeInSecond \ 3600
        timeInSecond = timeInSecond mod 3600
        minutes = timeInSecond \ 60

        hrStr = hours.toStr()
        minutesStr = minutes.toStr()

        if (hours < 10)
            hrStr = "0" + hrStr
        end if
        if (minutes < 10)
            minutesStr = "0" + minutesStr
        end if
        return hrStr + ":" + minutesStr
    else
        return ""
    end if
end function

function getDurationFormated(durationSeconds)
    durationMinutes = Fix(durationSeconds / 60)
    if (durationMinutes = 0)
        secString = durationSeconds.toStr()
        if (durationSeconds > 1)
            secString += " " + "seconds"
        else
            secString += " " + "second"
        end if
        return secString
    end if
    if (durationMinutes >= 60)
        durationHours = Fix(durationMinutes / 60)
        remainMinutes = durationMinutes mod 60
        if remainMinutes = 0
            if (durationHours > 1)
                text = "hrs"
            else
                text = "hr"
            end if
            return durationHours.toStr() + " " + text
        else
            return durationHours.toStr() + "H " + remainMinutes.toStr() + "M"
        end if
    end if
    minString = durationMinutes.toStr()
    if(durationMinutes > 1)
        return minString + " " + "mins"
    else
        return minString + " " + "min"
    end if
end function

sub deleteFromArray(array as object, item as dynamic) as object
    for i = 0 to array.count() - 1
        id = getValueFromProps(array[i], "id", "")
        if (id = item.id)
            array.delete(i)
            exit for
        end if
    end for
end sub
