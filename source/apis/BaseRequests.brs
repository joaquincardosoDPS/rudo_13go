' skipEncode: la URL ya viene con sus valores codificados (EncodeUri() volveria
' a codificar los "%" como "%25").
function getRequest(path as string, data as dynamic, headers as dynamic, skipEncode = false as boolean) as object
    req = createRoTransferInstance()

    port = CreateObject("roMessagePort")
    req.SetMessagePort(port)
    req.RetainBodyOnError(true)
    for each key in headers
        req.AddHeader(key, headers[key])
    end for

    compiledData = path
    delimeter = "?"

    for each key in data
        compiledData = compiledData + delimeter + key + "=" + req.Escape(data[key].ToStr())
        delimeter = "&"
    end for
    ' print "BaseRequests : getRequest compiledData : " compiledData

    finalURL = compiledData
    if not skipEncode then finalURL = compiledData.EncodeUri()
    req.SetUrl(finalURL)
    print "BaseRequests : getRequest finalURL : " finalURL

    started = req.AsyncGetToString()

    if (started)
        event = wait(60000, port)
        if type(event) = "roUrlEvent"
            code = event.GetResponseCode()
            if (isSuccess(code))
                successResponse = success(event.GetString())
                ' print "BaseRequests : Success Response : " ' successResponse
                return successResponse
            else
                if code < 0
                    print "*** BaseRequests : Get API Failed. Set cancel request *** "
                    req.asyncCancel()
                end if
                failureResponse = fail(code, event.GetString())
                print "*** BaseRequests : Get API Failed. *** Response : " failureResponse
                return failureResponse
            end if
        end if
    end if

    return fail(-1, "Timeout happen")
end function

function postRequest(path as string, data as dynamic, headers as dynamic, format = false as boolean) as object
    req = createRoTransferInstance()
    port = CreateObject("roMessagePort")
    req.SetMessagePort(port)
    req.RetainBodyOnError(true)
    req.SetUrl(path)
    for each key in headers
        req.AddHeader(key, headers[key])
    end for
    if format
        started = req.AsyncPostFromString(FormatJson(data))
    else
        delimeter = ""
        compiledData = ""
        for each key in data
            compiledData = compiledData + delimeter + key + "=" + req.Escape(data[key].ToStr())
            delimeter = "&"
        end for
        started = req.AsyncPostFromString(compiledData)
    end if
    if (started)
        event = wait(40000, port)
        if type(event) = "roUrlEvent"
            code = event.GetResponseCode()
            if (isSuccess(code))
                response = event.GetString()
                ' print "BaseRequests : postRequest : Success Response : " response
                successResponse = success(response)
                return successResponse
            else
                if code < 0
                    print "*** BaseRequests : Get API Failed. Set cancel request *** "
                    req.asyncCancel()
                end if
                failureResponse = fail(code, event.GetString())
                ' print "BaseRequests : postRequest : Fail Response : " failureResponse
                return failureResponse
            end if
        end if
    end if

    return fail(-1, "Timeout happen")
end function

function deleteRequest(path as string, data as dynamic, headers as dynamic) as object
    req = createRoTransferInstance()
    req.setRequest("DELETE")
    port = CreateObject("roMessagePort")
    req.SetMessagePort(port)

    for each key in headers
        req.AddHeader(key, headers[key])
    end for

    compiledData = path
    delimeter = "?"

    for each key in data
        compiledData = compiledData + delimeter + key + "=" + req.Escape(data[key].ToStr())
        delimeter = "&"
    end for

    req.SetUrl(compiledData)
    print "BaseRequests : deleteRequest url : " compiledData

    started = req.AsyncGetToString()

    if (started)
        event = wait(40000, port)
        if type(event) = "roUrlEvent"
            code = event.GetResponseCode()
            if (isSuccess(code))
                successResponse = success(event.GetString())
                ' print "BaseRequests : Success Response : " ' successResponse
                return successResponse
            else
                if code < 0
                    print "*** BaseRequests : Get API Failed. Set cancel request *** "
                    req.asyncCancel()
                end if
                failureResponse = fail(code, event.GetFailureReason())
                ' print "*** BaseRequests : Get API Failed. *** Response : " failureResponse
                return failureResponse
            end if
        end if
    end if

    return fail(-1, "Timeout happen")
end function

function createRoTransferInstance() as dynamic
    req = CreateObject("roUrlTransfer")
    req.EnablePeerVerification(false)
    req.EnableHostVerification(false)

    return req
end function

function isSuccess(code as integer) as boolean
    return code >= 200 AND code < 300
end function

function success(body as string) as object
    result = {}
    result.isSuccess = true
    result.response = body

    return result
end function

function fail(code as integer, reason as string) as object
    result = {}
    result.isSuccess = false
    result.code = code
    result.reason = reason

    return result
end function
