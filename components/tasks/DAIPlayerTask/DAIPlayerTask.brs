Library "Roku_Ads.brs"
Library "IMA3.brs"

sub init()
    m.top.functionName = "playContentWithAds"
    m.top.id = "DAIPlayerTask"
    m.top.snapbackTime = -1
    m.top.adPlaying = False
end sub

sub playContentWithAds()
    if not m.top.sdkLoaded
        loadSdk()
    end if
    if not m.top.streamManagerReady
        loadStream()
    end if
    if m.top.streamManagerReady
        runLoop()
    end if
end sub

sub loadSdk()
    if m.sdk = invalid
        m.sdk = New_IMASDK()
    end if
    m.top.sdkLoaded = true
end sub

sub runLoop()
    m.top.video.timedMetaDataSelectionKeys = ["*"]
    m.port = CreateObject("roMessagePort")
    fields = m.top.video.getFields()
    for each field in fields
        m.top.video.observeField(field, m.port)
    end for

    m.lastLoopTime = m.top.video.position
    m.seekThreshold = 2

    interactivePlayer = {
        sgNode: m.top.video,
        port: m.port
    }
    mediaInfo = m.top.mediaInfo
    adIface = Roku_Ads() ' used to enable interactive ads
    if (m.top.setAdsDebugOutput <> invalid AND m.top.setAdsDebugOutput = true)
        adIface.setDebugOutput(false)
    end if
    if (m.top.enableNielsenDAR <> invalid AND m.top.enableNielsenDAR = true)
        adIface.enableNielsenDAR(true)
    end if
    if (mediaInfo.nielsenAppId <> invalid AND mediaInfo.nielsenAppId <> "")
        adIface.setNielsenAppId(mediaInfo.nielsenAppId)
    end if
    if (mediaInfo.nielsenProgramId <> invalid AND mediaInfo.nielsenProgramId <> "")
        adIface.setNielsenProgramId(mediaInfo.nielsenProgramId)
    end if
    contentLength = 99999999
    if (mediaInfo.duration_seg <> invalid AND mediaInfo.duration_seg > 0)
        contentLength = mediaInfo.duration_seg
    end if
    adIface.setContentLength(contentLength)

    if (m.top.setAdMeasurements <> invalid AND m.top.setAdMeasurements = true)
        adIface.enableAdMeasurements(true)
    end if
    if (mediaInfo.contentGenres <> invalid AND mediaInfo.contentGenres <> "")
        adIface.setContentGenre(mediaInfo.contentGenres)
    end if
    adIface.setContentId(mediaInfo.id)
    if (m.top.setJITPods <> invalid AND m.top.setJITPods = true)
        adIface.enableJITPods(true)
    end if

    while True
        msg = wait(1000, m.port)
        if m.top.video = invalid
            print "exiting"
            exit while
        end if

        curAd = adIface.stitchedAdHandledEvent(msg, interactivePlayer)
        if curAd <> invalid AND curAd.evtHandled = true AND curAd.adExited = true
            print "Interactive ad requesting exiting"
            exit while
        end if

        m.streamManager.onMessage(msg)
        m.top.contentTime = m.streamManager.getContentTime(m.top.video.position * 1000) / 1000
        currentTime = m.top.video.position
        if currentTime > 3 AND not m.top.adPlaying
            m.top.video.enableTrickPlay = true
        end if

        if abs(currentTime - m.lastLoopTime) > m.seekThreshold
            print "Seek detected from "; m.lastLoopTime;" to "currentTime
            if m.top.inSnapback
                ' That seek was us snapping back to content
                print "Threshold break was snapback"
                m.top.inSnapback = false
            else
                ' User seeked
                print "Threshold break was user seek - sending to onUserSeek"
                onUserSeek(m.lastLoopTime, currentTime)
            end if
        end if
        m.lastLoopTime = currentTime
    end while
end sub

sub setupVideoPlayer()
    sdk = m.sdk
    m.player = sdk.createPlayer()
    m.player.top = m.top
    m.player.loadUrl = function(urlData)
        if m.top.streamData.type <> "live" then
            bookmarkTime = m.top.streamData.bookmarkTime * 1000
            m.top.bookmarkStreamTime = m.streamManager.getStreamTime(bookmarkTime) / 1000
        else
            m.top.bookmarkStreamTime = 0
        end if
        ' This line prevents users from scanning during buffering or during the first second of the
        ' ad before we have a callback from roku.
        ' If there are no prerolls disabling trickplay isn't needed.
        m.top.video.enableTrickPlay = false
        m.top.urlData = urlData
    end function
    m.player.adBreakStarted = function(adBreakInfo as object)
        print "---- Ad Break Started ---- ";adBreakInfo
        m.top.adPlaying = True
        m.top.video.enableTrickPlay = false
    end function
    m.player.adBreakEnded = function(adBreakInfo as object)
        print "---- Ad Break Ended ---- ";adBreakInfo
        m.top.adPlaying = False
        if m.top.snapbackTime > -1 AND m.top.snapbackTime > m.top.video.position
            m.top.video.seek = m.top.snapbackTime
            m.top.snapbackTime = -1
        end if
        m.top.video.setFocus(true)
        m.top.video.enableTrickPlay = true
    end function
    m.player.seek = function(timeSeconds as float)
        print "---- SDK requested seek to ----" ; timeSeconds
        m.top.video.seekMode = "accurate"
        m.top.video.seek = timeSeconds
    end function
end sub

sub onUserSeek(seekStartTime as integer, seekEndTime as integer)
    previousCuePoint = m.streamManager.getPreviousCuePoint(seekEndTime)
    if previousCuePoint = invalid OR previousCuePoint.hasPlayed
        print "Previous cuepoint was invalid or played"
        return
    else
        ' Add a second to make sure we hit the keyframe at the start of the ad
        print "Seeking to ";previousCuepoint.start + 1
        m.top.video.seek = previousCuePoint.start + 1
        m.top.snapbackTime = seekEndTime
        m.top.inSnapback = true
    end if
end sub

function daiGetPpidFallback(mi as dynamic) as string
    if mi <> invalid
        if mi.googleImaPpid <> invalid AND mi.googleImaPpid <> ""
            return mi.googleImaPpid
        end if
        if mi.addAdCustomAttribute <> invalid AND mi.addAdCustomAttribute.ppid <> invalid AND mi.addAdCustomAttribute.ppid <> ""
            return mi.addAdCustomAttribute.ppid
        end if
        if mi.customerID <> invalid AND mi.customerID <> ""
            return mi.customerID
        end if
        if mi.MDSTRMUID <> invalid AND mi.MDSTRMUID <> ""
            return mi.MDSTRMUID
        end if
    end if
    return ""
end function

function daiGetIsLatForDAI() as string
    di = CreateObject("roDeviceInfo")
    if di.IsRIDADisabled() then
        return "1"
    else
        return "0"
    end if
end function

sub loadStream()
    sdk = m.sdk
    sdk.initSdk()
    setupVideoPlayer()

    request = {}
    ' Handle both "live" and "live-stream" for live streams
    if m.top.streamData.type = "live" OR m.top.streamData.type = "live-stream"
        print "DAIPlayerTask: Creating LIVE stream request"
        request = sdk.CreateLiveStreamRequest(m.top.streamData.assetKey, m.top.streamData.apiKey)
    else if m.top.streamData.type = "vod" OR m.top.streamData.type = "video"
        print "DAIPlayerTask: Creating VOD stream request"
        request = sdk.CreateVodStreamRequest(m.top.streamData.contentSourceId, m.top.streamData.videoId, m.top.streamData.apiKey)
    else
        print "DAIPlayerTask: Creating generic stream request (type=" ; m.top.streamData.type ; ")"
        request = sdk.CreateStreamRequest()
    end if

    request.player = m.player
    request.adUiNode = m.top.video

    requestResult = sdk.requestStream(request)
    if requestResult <> invalid
        print "Error requesting stream ";requestResult
    else
        m.streamManager = invalid
        while m.streamManager = invalid
            sleep(50)
            m.streamManager = sdk.getStreamManager()
        end while
        if m.streamManager = invalid OR m.streamManager["type"] <> invalid OR m.streamManager["type"] = "error"
            errors = CreateObject("roArray", 1, True)
            print "error ";m.streamManager["info"]
            errors.push(m.streamManager["info"])
            m.top.errors = errors
        else
            m.top.streamManagerReady = True
            addCallbacks()
            m.player.streamManager = m.streamManager
            m.streamManager.start()
        end if
    end if
end sub

function addCallbacks() as void
    m.streamManager.addEventListener(m.sdk.AdEvent.ERROR, errorCallback)
    m.streamManager.addEventListener(m.sdk.AdEvent.START, startCallback)
    m.streamManager.addEventListener(m.sdk.AdEvent.FIRST_QUARTILE, firstQuartileCallback)
    m.streamManager.addEventListener(m.sdk.AdEvent.MIDPOINT, midpointCallback)
    m.streamManager.addEventListener(m.sdk.AdEvent.THIRD_QUARTILE, thirdQuartileCallback)
    m.streamManager.addEventListener(m.sdk.AdEvent.COMPLETE, completeCallback)
end function

function startCallback(ad as object) as void
    print "Callback from SDK -- Start called - "; ad
    ' Allows raf control in case of interactive ads
    if ad.companions <> invalid AND ad.companions.count() > 0
        rafStructure = convertToRaf(ad, m.top.video.position)
        logStructure(rafStructure, "") ' Uncomment to see RAF structure
        adIface = Roku_Ads()
        if (m.top.setAdsDebugOutput <> invalid AND m.top.setAdsDebugOutput = true)
            adIface.setDebugOutput(false)
        end if
        if (m.top.enableNielsenDAR <> invalid AND m.top.enableNielsenDAR = true)
            adIface.enableNielsenDAR(true)
        end if
        if (m.top.setAdMeasurements <> invalid AND m.top.setAdMeasurements = true)
            adIface.enableAdMeasurements(true)
        end if
        adIface.stitchedAdsInit(rafStructure)
    end if
end function

function firstQuartileCallback(ad as object) as void
    print "Callback from SDK -- First quartile called - "
end function

function midpointCallback(ad as object) as void
    print "Callback from SDK -- Midpoint called - "
end function

function thirdQuartileCallback(ad as object) as void
    print "Callback from SDK -- Third quartile called - "
end function

function completeCallback(ad as object) as void
    print "Callback from SDK -- Complete called - "
end function

function errorCallback(error as object) as void
    print "Callback from SDK -- Error called - "; error
    ' errors are critical and should terminate the stream.
    m.errorState = True
end function
