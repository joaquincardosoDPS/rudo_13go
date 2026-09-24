Library "Roku_Ads.brs"

sub init()
    m.top.functionName = "PlayPreroll"
end sub

' getAds() pide el VAST y devuelve los pods; showAds() los reproduce (bloquea
' hasta que terminan) y devuelve false si el usuario salio con back.
sub PlayPreroll()
    ' Sin la libreria (ej: el simulador brs-node no trae RAF) se sigue sin anuncio.
    if type(Roku_Ads) <> "Function" AND type(Roku_Ads) <> "roFunction"
        print "PrerollAdsTask : RAF no disponible, sin anuncio"
        m.top.status = "none"
        return
    end if
    raf = Roku_Ads()
    raf.setDebugOutput(false)
    raf.enableAdMeasurements(true)
    raf.setAdUrl(m.top.adUrl)
    if isValidString(m.top.contentId) then raf.setContentId(m.top.contentId)
    if m.top.contentLength > 0 then raf.setContentLength(m.top.contentLength)
    adPods = raf.getAds()
    if m.top.cancel OR adPods = invalid OR adPods.count() = 0
        print "PrerollAdsTask : sin anuncio"
        m.top.status = "none"
        return
    end if
    print "PrerollAdsTask : reproduciendo anuncio"
    m.top.status = "playing"
    keepPlaying = raf.showAds(adPods, invalid, m.top.view)
    if keepPlaying
        m.top.status = "done"
    else
        m.top.status = "exited"
    end if
end sub

function isValidString(value as dynamic) as boolean
    return value <> invalid AND GetInterface(value, "ifString") <> invalid AND value <> ""
end function
