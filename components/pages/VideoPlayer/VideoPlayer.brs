sub init()
    print "VideoPlayer : Init"
    setLocals()
    setControls()
    setUpColor()
    setUpFonts()
    setObservers()
    setupPageLoaderDetails()
end sub

sub setLocals()
    m.theme = m.global.appTheme
    m.videoContent = {}
    m.pauseAfterBuffering = false
    m.scene = m.top.GetScene()
    m.pollingSeconds = 30
    m.watchDuration = 0
    m.position = 0
    m.adURL = GlobalGet("vastURL")
    m.nextEpisode = invalid
    m.isPopupVisible = false
end sub

sub setControls()
    m.pVideo = m.top.findNode("pVideo")
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.loaderSection = m.top.findNode("loaderSection")
    m.loadingStatus = m.top.findNode("loadingStatus")

    m.PlayerOverlay = m.top.findNode("PlayerOverlay")
    m.hideControlsTimer = m.top.findNode("hideControlsTimer")
    m.fadeOutControls = m.top.findNode("fadeOutControls")
    m.nextEpisodePopup = m.top.findNode("nextEpisodePopup")
    m.bigPlayerAnimation = m.top.findNode("bigPlayerAnimation")
    m.smallPlayerAnimation = m.top.findNode("smallPlayerAnimation")
end sub

sub setUpColor()
end sub

sub setupFonts()
end sub

sub setObservers()
    m.top.observeField("focusedChild", "onFocusedChild")
    m.hideControlsTimer.observeField("fire", "hideControls")

    m.PlayerOverlay.observeField("seekingStatus", "onSeekingStatusChanged")
    m.PlayerOverlay.observeField("pauseVideo", "onVideoPauseCall")
    m.PlayerOverlay.observeField("videoContent", "onVideoContentChanged")
    m.PlayerOverlay.observeField("videoPosition", "onKnobPositionChanged")
    m.PlayerOverlay.observeField("resethidecontrolstimer", "onResethidecontrolstimer")
    m.smallPlayerAnimation.observeField("state", "onAnimationStateChange")
end sub

sub onKnobPositionChanged(event as dynamic)
    position = event.getData()
    ' if m.videoStatus = "buffering"
    '     'At end of playback position with accurate seek mode, Roku player stuck if requested seek position dont have sync frame (i frame) available to play
    '     'Video will play earlier than the requested seek time  based on closest sync frame available in default seek mode.
    '     m.videoPlayer.seek = position
end sub

sub SendAnalyticsToServer()
    if not isValid(m.videoContent) OR m.videoContent.isLive = true OR not isNonEmptyString(getValueFromProps(m.videoContent, "slug", ""))
        return
    end if
    analyticsObj = {}
    selectedProfileID = GlobalGet("selectedProfileID")
    if isNonEmptyString(selectedProfileID) then analyticsObj["profile"] = selectedProfileID
    if isNonEmptyString(m.videoContent.slug) then analyticsObj["vod"] = m.videoContent.slug
    if m.position > 0 then analyticsObj["end"] = m.position
    if m.watchDuration > 0 then analyticsObj["time"] = m.watchDuration
    ' print "Video Player : SendAnalyticsToServer : analyticsObj : " analyticsObj
    if analyticsObj.count() > 0
        sendAnalyticsDataTask = CreateObject("roSGNode", "ContentAPIAction")
        sendAnalyticsDataTask.functionName = "AddWatchHistory"
        sendAnalyticsDataTask.params = analyticsObj
        sendAnalyticsDataTask.ObserveField("result", "OnCallLogAnalyticsVideosResponse")
        sendAnalyticsDataTask.control = "RUN"
    end if
end sub

sub OnCallLogAnalyticsVideosResponse(event as dynamic)
    response = event.GetData()
    print "Video Player : OnCallLogAnalyticsVideosResponse : response : " FormatJson(response)
end sub

sub setupPageLoaderDetails()
    m.loadingStatus.poster.uri = "pkg:/images/loader/loader.png"
    m.loadingStatus.poster.width = "100"
    m.loadingStatus.poster.height = "100"
    m.loadingStatus.poster.loadwidth = "100"
    m.loadingStatus.poster.loadheight = "100"
    m.loadingStatus.poster.blendColor = m.theme.focPrimary
    m.loadingStatus.poster.loadDisplayMode = "scaleToFit"
end sub

sub showLoading(flag as boolean)
    m.loaderSection.visible = flag
end sub

sub resetPlayerLayout()
    m.videoPlayer.translation = [0, 0]
    m.videoPlayer.width = 1920
    m.videoPlayer.height = 1080
    m.PlayerOverlay.translation = [0, 0]
    m.PlayerOverlay.scale = [1, 1]
    m.loaderSection.translation = [910, 485]
    m.loaderSection.scale = [1, 1]
end sub

sub onContentChange(event as dynamic)
    m.videoContent = event.getData()
    print "VideoPlayer : OnContentChange : m.videoContent : " m.videoContent
    if (isNotEmptyAA(m.videoContent))
        showLoading(true)
        triggerHideControlsTimer(false, false)
        fadeOutControls(true)
        showOverlay(false)
        getResumePostion()
        ' getMediaDetail()
        GetNextEpisode()
    else
        closePlayer()
    end if
end sub

sub GetNextEpisode()
    params = {}
    params["client"] = GlobalGet("appConfig").client
    params["program"] = m.videoContent.key_program
    params["segment"] = m.videoContent.key_segment
    params["season"] = m.videoContent.season
    params["chapter"] = m.videoContent.chapter + 1
    m.getEpisodeDetailsTask = CreateObject("roSGNode", "ContentAPIAction")
    m.getEpisodeDetailsTask.functionName = "GetEpisodeDetails"
    m.getEpisodeDetailsTask.params = params
    m.getEpisodeDetailsTask.ObserveField("result", "onGetNextEpisodeResponse")
    m.getEpisodeDetailsTask.control = "RUN"
end sub

sub onGetNextEpisodeResponse(event as dynamic)
    response = event.getData()
    print "Video player: onGetNextEpisodeResponse : response : " 'FormatJson(response)
    if isValid(response) AND isValid(response.data) AND isValid(response.data.data)
        m.nextEpisode = response.data.data
    else
        m.nextEpisode = invalid
    end if
end sub

sub getResumePostion()
    params = {}
    params["vod_slugs[0]"] = m.videoContent.slug
    m.getResumePostionTask = CreateObject("roSGNode", "ContentAPIAction")
    m.getResumePostionTask.functionName = "GetWatchHistory"
    m.getResumePostionTask.params = params
    m.getResumePostionTask.ObserveField("result", "OnGetResumePostionAPIResponse")
    m.getResumePostionTask.control = "RUN"
end sub

sub OnGetResumePostionAPIResponse(event as dynamic)
    response = event.getData()
    print "VideoPlayer : OnGetResumePostionAPIResponse : response : " 'FormatJson(response)
    isResume = false
    resumePos = 0
    if isValid(response) AND isValid(response.data) AND isValid(response.data.data) AND isValid(response.data.data[0]) AND isValid(response.data.data[0].time)
        resumePos = response.data.data[0].time
        isResume = true
    end if
    if isValid(m.videoContent)
        m.videoContent.time = resumePos
        playVideo(m.videoContent, m.adUrl, isResume)
    end if
end sub

sub playVideo(videoInfo as dynamic, adUrl as string, fromResumeBack = false as boolean)
    videoUrl = getValueFromProps(videoInfo, "m3u8", "")
    if not isNonEmptyString(videoUrl)
        print "VideoPlayer : playVideo : Missing m3u8 URL."
        closePlayer()
        return
    end if
    m.isPopupVisible = false
    m.pauseAfterBuffering = false
    if m.videoPlayer.control = "play"
        m.videoPlayer.control = "stop"
    end if
    m.watchDuration = 0
    m.videoPlayer.observeField("state", "onVideoPlayerStatusChange")
    m.videoPlayer.observeField("position", "onVideoPositionChanged")
    videoContent = createObject("RoSGNode", "ContentNode")
    videoContent.streamformat = "auto"
    videoContent.url = videoUrl
    videoContent.title = getValueFromProps(videoInfo, "title", "")
    if isValid(videoInfo.key) AND isNonEmptyString(videoInfo.key)
        adUrl = adUrl.replace("{{key_rudo}}", videoInfo.key)
    end if
    if isNonEmptyString(adUrl)
        videoContent.addFields({ "ad_url": adUrl, "length": getValueFromProps(videoInfo, "duration", 0) })
    end if
    m.PlayerOverlay.videoParams = videoInfo
    m.videoPlayer.content = videoContent
    m.videoPlayer.enableTrickPlay = false
    m.videoPlayer.enableUI = false
    m.PlayerOverlay.duration = getValueFromProps(videoInfo, "duration", 0)
    m.videoPlayer.retrievingBar.filledBarBlendColor = m.theme.focPrimary
    m.videoPlayer.trickPlayBar.filledBarBlendColor = m.theme.focPrimary
    m.videoPlayer.bufferingBar.filledBarBlendColor = m.theme.focPrimary
    if isValid(videoInfo.time) AND fromResumeBack
        m.videoPlayer.seek = videoInfo.time
        m.videoPlayer.seekMode = "accurate"
    end if
    m.videoPlayer.visible = true
    if isNonEmptyString(adUrl)
        PlayerTask()
    else
        m.videoPlayer.control = "play"
    end if
    showOverlay(true)
    setFocusOnPlayerOverlay()
end sub

sub PlayerTask()
    if m.PlayerTask <> invalid
        m.PlayerTask.unobserveField("state")
        m.PlayerTask.unobserveField("currentState")
        m.PlayerTask.unobserveField("currentPosition")
        m.PlayerTask.control = "stop"
        m.PlayerTask = invalid
    end if
    m.PlayerTask = CreateObject("roSGNode", "PlayerTask")
    m.PlayerTask.observeField("state", "taskStateChanged")
    m.PlayerTask.observeField("currentState", "onVideoPlayerStatusChange")
    m.PlayerTask.observeField("currentPosition", "OnVideoPositionChanged")
    m.PlayerTask.video = m.videoPlayer
    m.PlayerTask.functionName = "playContentWithAds"
    m.PlayerTask.control = "RUN"
end sub

sub taskStateChanged(event as Object)
    print "Player: taskStateChanged(), id = "; event.getNode(); ", "; event.getField(); " = "; event.getData()
    state = event.GetData()
    if (state = "done" OR state = "stop")
        closePlayer()
    end if
end sub

sub onVideoPlayerStatusChange(event as dynamic)
    m.videoStatus = event.GetData()
    print "m.videoStatus >>>>>>>> : " m.videoStatus
    m.PlayerOverlay.videoPlayerState = m.videoStatus
    if m.videoStatus = "stopped" then
        if m.videoPlayer.position <> 0 then
            m.PlayerOverlay.seekPosition = m.videoPlayer.position
        end if
    end if
    if m.videoStatus = "buffering"
        showLoading(true)
    else if m.videoStatus = "playing"
        showLoading(false)
        if m.videoPlayer.visible = false
            m.videoPlayer.visible = true
        end if
        m.PlayerOverlay.duration = Abs(m.videoPlayer.duration)
        if not m.pauseAfterBuffering
            setFocusOnVideoPlayer()
            m.PlayerOverlay.action = {
                userAction: "PLAYED",
                videoPosition: m.videoPlayer.position
            }
            triggerHideControlsTimer(false, false)
            fadeOutControls(true)
            ' if m.PlayerOverlay.videoPosition <> m.videoPlayer.position
            '     m.videoPlayer.seek = m.PlayerOverlay.videoPosition
            ' end if
        else
            m.pauseAfterBuffering = false
            m.PlayerOverlay.action = {
                userAction: "PAUSED",
                videoPosition: m.videoPlayer.position
            }
            m.videoPlayer.control = "pause"
            triggerHideControlsTimer(false)
        end if
    else if m.videoStatus = "error"
        print "*** VideoPlayer : OnVideoPlayerStatusChange : Video Playback error : " m.videoPlayer.errorCode
        print "*** VideoPlayer : OnVideoPlayerStatusChange : Video Playback error : " m.videoPlayer.errorInfo
        print "*** VideoPlayer : OnVideoPlayerStatusChange : Video Playback error : " m.videoPlayer.errorMsg
        print "*** VideoPlayer : OnVideoPlayerStatusChange : Video Playback error : " m.videoPlayer.errorStr
    else if m.videoStatus = "finished"
        if m.isPopupVisible AND m.nextEpisode <> invalid
            PlayAutoNextEpisode()
        else
            showLoading(false)
            showOverlay(false)
            SendAnalyticsToServer()
            closePlayer()
        end if
    else if m.videoStatus = "paused"
        fadeOutControls(false)
        triggerHideControlsTimer(false)
        setFocusOnPlayerOverlay()
    end if
end sub

sub onVideoPositionChanged()
    videoPos = m.videoPlayer.position \ 1
    if videoPos > 0
        if m.isPopupVisible AND m.videoPlayer.duration > 0 AND videoPos > 0 AND videoPos <= m.videoPlayer.duration AND isValid(m.nextEpisodePopup)
            m.nextEpisodePopup.leftPosition = m.videoPlayer.duration - videoPos
        end if
        m.watchDuration = videoPos
        if (m.videoPlayer.duration <> 0 AND videoPos mod 30 = 0)
            SendAnalyticsToServer()
        end if
        m.videoPosition = videoPos
        m.PlayerOverlay.videoPosition = videoPos
    end if
    m.PlayerOverlay.duration = m.videoPlayer.duration
    if videoPos > 0 AND m.videoPlayer.duration > 0 AND (videoPos >= (m.videoPlayer.duration - 30)) AND m.isPopupVisible = false
        m.isPopupVisible = true
        ShowNextEpisodePopup()
    end if
end sub

sub ShowNextEpisodePopup()
    bgImage = GetImageURL(m.videoContent.image_land, "small")
    contentNode = {
        image: bgImage
        title: m.videoContent.title
        logoTitle: m.videoContent.logoTitle
        isShowNextEpisode: false
    }
    if isValid(m.nextEpisode)
        m.episodeImage = ""
        if isValid(m.nextEpisode.image_land) AND m.nextEpisode.image_land.count() > 0
            m.episodeImage = GetImageURL(m.nextEpisode.image_land, "medium")
        else if isNonEmptyString(m.nextEpisode.image)
            m.episodeImage = m.nextEpisode.image
        end if
        if m.episodeImage = "" then m.episodeImage = bgImage
        contentNode["episodeTitle"] = m.nextEpisode.title
        contentNode["description"] = m.nextEpisode.description
        contentNode["episodeImage"] = m.episodeImage
        contentNode["isShowNextEpisode"] = true
    end if
    m.nextEpisodePopup.contentNode = contentNode
    m.nextEpisodePopup.observeField("showNextEpisode", "onButtonselection")
    m.nextEpisodePopup.observeField("showEpisodeList", "onButtonselection")
    m.nextEpisodePopup.visible = true
    m.smallPlayerAnimation.control = "start"
    SetFocus(m.nextEpisodePopup)
end sub

sub onButtonselection()
    if m.nextEpisodePopup.showNextEpisode AND isValid(m.nextEpisode)
        PlayAutoNextEpisode()
    else if m.nextEpisodePopup.showEpisodeList
        closePlayer()
    end if
end sub

sub PlayAutoNextEpisode()
    if isValid(m.nextEpisode) AND m.nextEpisode.count() > 0
        if isNonEmptyString(m.episodeImage)
            m.videoPlayer.visible = false
            m.pVideo.uri = m.episodeImage
        end if
        m.videoPlayer.control = "stop"
        m.videoPlayer.unobserveField("state")
        m.videoPlayer.unobserveField("position")
        HideNextEpisodePopup()
        m.top.content = m.nextEpisode
    end if
end sub

sub HideNextEpisodePopup()
    m.isPopupVisible = false
    m.nextEpisodePopup.visible = false
    m.bigPlayerAnimation.control = "start"
    resetPlayerLayout()
end sub

sub onSmallAnimationStateChange(event as dynamic)
    state = event.getData()
    if state = "stopped"
        m.smallPlayerAnimation.control = "stop"
    end if
end sub

sub onResethidecontrolstimer()
    'While buffering only : stop hide controlls if user have row item focused.
    if m.PlayerOverlay.resethidecontrolstimer
        triggerHideControlsTimer(false)
        resetHideControlsTimer()
    end if
end sub

sub resetHideControlsTimer()
    m.hideControlsTimer.control = "stop"
    m.hideControlsTimer.control = "start"
end sub

sub stopRunningVideo()
    m.videoPlayer.control = "stop"
end sub
' Overlay
sub triggerHideControlsTimer(value as boolean, isShowOverlay = true as boolean)
    if (isShowOverlay)
        showOverlay(true)
    end if
    if not value
        m.hideControlsTimer.control = "stop"
    else
        m.hideControlsTimer.control = "start"
    end if
end sub

sub hideControls()
    fadeOutControls(true)
end sub

sub showOverlay(visible as boolean)
    m.PlayerOverlay.visible = visible
    m.PlayerOverlay.opacity = 1.0
end sub

sub fadeOutControls(value as boolean)
    if m.PlayerOverlay.visible
        if not value
            m.fadeOutControls.control = "stop"
        else
            m.fadeOutControls.control = "start"
            setFocusOnVideoPlayer()
        end if
    end if
end sub

sub onVideoPauseCall()
    m.PlayerOverlay.action = {
        userAction: "PAUSED",
        videoPosition: m.videoPlayer.position
    }
    if (m.videoPlayer.state = "buffering")
        m.pauseAfterBuffering = true
    else
        m.videoPlayer.control = "pause"
    end if
end sub

function onSeekingStatusChanged(event as dynamic)
    status = event.getData()
    if status = "STARTED" then
        if m.videoPlayer.state <> "buffering"
            m.videoPlayer.control = "pause"
        end if
        triggerHideControlsTimer(false)
    else if status = "STOPPED" then
        if m.PlayerOverlay.seekPosition <> -1 'AND m.videoStatus <> "buffering" then
            m.videoPlayer.seekMode = "accurate"
            m.videoPlayer.seek = m.PlayerOverlay.seekPosition
        end if
        m.pauseAfterBuffering = false
        m.PlayerOverlay.action = {
            userAction: "PLAYED",
            videoPosition: m.PlayerOverlay.seekPosition
        }
        m.videoPlayer.control = "resume"
    end if
end function

sub closePlayer()
    showLoading(false)
    showOverlay(false)
    m.pauseAfterBuffering = false
    if m.mediaDetailTask <> invalid
        m.mediaDetailTask.control = "stop"
        m.mediaDetailTask = invalid
    end if
    if m.updateMediaDetailTask <> invalid
        m.updateMediaDetailTask.control = "stop"
        m.updateMediaDetailTask = invalid
    end if
    if m.PlayerTask <> invalid
        m.PlayerTask.control = "stop"
        m.PlayerTask = invalid
    end if
    m.videoPlayer.control = "stop"
    m.videoPlayer.content = invalid
    m.videoPlayer.visible = false
    m.scene.isWatchHistoryFetched = true
    if m.nextEpisodePopup.visible then m.nextEpisodePopup.visible = false
    resetPlayerLayout()
    m.top.isVideoPlayerStopped = true
end sub

sub onFocusedChild()
    if m.top.hasFocus()
        if not RestoreFocus()
            setFocusOnVideoPlayer()
        end if
    end if
end sub

sub doPause(key as string)
    m.PlayerOverlay.action = {
        userAction: "PAUSED"
    }
    if m.videoPlayer.state = "buffering"
        if key = "play" OR key = "OK"
            if m.pauseAfterBuffering
                m.pauseAfterBuffering = false
                m.PlayerOverlay.action = {
                    userAction: "PLAYED"
                }
                if m.PlayerOverlay.seekingStatus = "STARTED"
                    m.videoPlayer.seek = m.PlayerOverlay.seekPosition
                    m.videoPlayer.seekMode = "accurate"
                    m.PlayerOverlay.seekingStatus = "STOPPED"
                end if
            else
                m.pauseAfterBuffering = true
            end if
        else
            m.pauseAfterBuffering = true
        end if
    end if
    if m.videoPlayer.state <> "buffering"
        m.videoPlayer.control = "pause"
    end if
end sub

function onOkPress(key as string)
    m.PlayerOverlay.videoPlayerState = m.videoPlayer.state
    if (m.videoPlayer.state = "playing" OR m.videoPlayer.state = "buffering") then
        doPause(key)
    else if m.videoPlayer.state <> "none"
        m.PlayerOverlay.action = {
            userAction: "PLAYED",
            videoPosition: m.videoPlayer.position
        }
        m.videoPlayer.seekMode = "accurate"
        m.videoPlayer.seek = m.PlayerOverlay.videoPosition
    end if
end function

function onReplay()
    position = ((m.videoPlayer.position \ 1) - 20)
    if (position > 0)
        m.videoPlayer.seek = position
        m.videoPlayer.seekMode = "accurate"
        m.videoPlayer.control = "resume"
    end if
end function

function onVideoPositionStore()
    m.currentVideoPos = m.videoPlayer.position
    triggerHideControlsTimer(false)
    if m.PlayerTask <> invalid
        m.PlayerTask.control = "stop"
        m.PlayerTask = invalid
    end if
    m.videoPlayer.control = "stop"
end function

sub setFocusOnPlayerOverlay()
    if not m.isPopupVisible
        setFocus(m.PlayerOverlay)
    end if
end sub

sub setFocusOnVideoPlayer()
    if not m.isPopupVisible
        setFocus(m.videoPlayer)
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    result = true
    if (press) AND not m.isPopupVisible
        print "VideoPlayer : onKeyEvent : key = " key " press = " press
        if (key = "back")
            if m.PlayerOverlay.visible = true
                showOverlay(false)
                setFocusOnVideoPlayer()
                result = true
            else
                closePlayer()
                result = false
            end if
        else if key = "down"
            fadeOutControls(false)
            triggerHideControlsTimer(true)
            setFocusOnPlayerOverlay()
        else if key = "up"
            fadeOutControls(false)
            triggerHideControlsTimer(true)
            setFocusOnPlayerOverlay()
        else if (key = "play" OR key = "OK") then
            onOkPress(key)
            result = true
        else if (key = "replay") then
            onReplay()
            result = true
        else if ((key = "left" OR key = "right" OR key = "fastforward" OR key = "rewind") AND m.videoPlayer.state <> "none")
            fadeOutControls(false)
            triggerHideControlsTimer(false)
            setFocusOnPlayerOverlay()
            m.PlayerOverlay.key = { "key": key, "press": press }
            result = true
        end if
    else if m.isPopupVisible AND key = "back"
        closePlayer()
    end if
    return result
end function
