Function Main(args as Dynamic)
    m.screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    m.screen.setMessagePort(port)
    m.scene = m.screen.CreateScene("MainScene")
    m.scene.id = "MainScene"
    inputObject = CreateObject("roInput")
    inputObject.SetMessagePort(port)
    if args.contentId <> invalid AND args.mediaType <> invalid
        print "Main : Deeplink Args : " args
        m.scene.deepLinkingContentId = LCase(args.contentId)
        m.scene.deepLinkingMediaType = LCase(args.mediaType)
        m.scene.deepLinkingLand = true
    else
        print "Main : No Launch Deeplinking..."
    end if

    setMemoryWarnings()

    m.screen.show()
    m.scene.observeField("outRequest", port)
    m.scene.setFocus(true)
    while(true)
        msg = wait(0, port)
        msgType = type(msg)

        If msgType = "roSGScreenEvent"
            If msg.isScreenClosed()
                Exit While
            End If
        Else If msgType = "roSGNodeEvent"
            Print "Main : Message Type : " msgType
            Print "Main : Message Field : " msg.GetField()
            ' When The AppManager want to send command back to Main
            If(msg.GetField() = "outRequest")
                request = msg.GetData()
                Print "Main : Request : " request
                If(request <> invalid)
                    If(request.DoesExist("ExitApp") AND (request.ExitApp = true))
                        Print "Main : Closing Screen."
                        m.screen.close()
                    End If
                End If
            End If
        else if msgType = "roInputEvent"
            if (msg.isInput() = true)
                messageInfo = msg.GetInfo()
                if (messageInfo.contentId <> invalid AND messageInfo.mediaType <> invalid)
                    print "Main : Input DeepLinking"
                    m.scene.callFunc("HandleInputEvent", messageInfo)
                end if
            end if
        end if
    end while
end function

sub setMemoryWarnings()
    deviceMemoryInfo = CreateObject("roAppMemoryMonitor")
    deviceMemoryInfo.EnableMemoryWarningEvent(true)
    deviceInfo = CreateObject("roDeviceInfo")
    deviceInfo.enableLowGeneralMemoryEvent(true)
    if deviceMemoryInfo <> invalid
        deviceMemoryInfo.GetMemoryLimitPercent()
        deviceMemoryInfo.GetChannelAvailableMemory()
        deviceMemoryInfo.GetChannelMemoryLimit()
    end if
end sub
