' SplashView.tsx: reproduce splash_tv; onEnded/onError -> handleNavigate.
sub Init()
    m.video = m.top.findNode("video")
    m.startTimeout = m.top.findNode("startTimeout")
    m.done = false
    m.started = false
    m.video.observeField("state", "OnVideoState")
    m.startTimeout.observeField("fire", "OnStartTimeout")
end sub

sub OnUrlSet()
    url = m.top.url
    if url = invalid OR url = ""
        Finish()
        return
    end if
    content = CreateObject("roSGNode", "ContentNode")
    content.url = url
    content.streamFormat = "mp4"
    m.video.content = content
    m.video.control = "play"
    m.startTimeout.control = "start"
end sub

sub OnVideoState()
    state = m.video.state
    print "SplashScreen : state : " state
    if state = "playing"
        m.started = true
        m.startTimeout.control = "stop"
    else if state = "finished"
        Finish()
    else if state = "error"
        print "SplashScreen : el video no se pudo reproducir, se sigue : " m.video.errorMsg
        Finish()
    end if
end sub

sub OnStartTimeout()
    if not m.started
        print "SplashScreen : el video no arranco a tiempo, se sigue"
        Finish()
    end if
end sub

sub Finish()
    if m.done then return
    m.done = true
    m.startTimeout.control = "stop"
    m.video.control = "stop"
    m.top.finished = true
end sub

' Como en la web, el splash no se puede saltar: se queda con todas las teclas
' (si no, back abriria el dialogo de salida sobre el video).
function onKeyEvent(key as string, press as boolean) as boolean
    return true
end function
