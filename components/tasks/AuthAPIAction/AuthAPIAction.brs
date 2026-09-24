' Task de red para todo lo que pasa por el gateway de 13go (auth y perfiles).
' Cada sub despacha hacia ContentAPI.brs y deja la respuesta cruda en
' m.top.result, con la forma { ok: true, data: <json del gateway> } o
' { ok: false, error: "..." }. Sin envolver de nuevo: la respuesta del
' gateway ya viene como { status, message, data }.
sub Init()
end sub

sub GetDeviceCode()
    m.top.result = ContentAPI().GetDeviceCode()
end sub

sub VerifyDevice()
    m.top.result = ContentAPI().VerifyDevice(m.top.params)
end sub

sub RefreshToken()
    m.top.result = ContentAPI().RefreshToken(m.top.params)
end sub

sub GetUserProfile()
    m.top.result = ContentAPI().GetUserProfile()
end sub

sub GetUserInfo()
    m.top.result = ContentAPI().GetUserInfo()
end sub

sub GetProfilesData()
    m.top.result = ContentAPI().GetProfilesData()
end sub

sub GetAvatarBaseUrl()
    m.top.result = ContentAPI().GetAvatarBaseUrl()
end sub

sub UpdateProfile()
    m.top.result = ContentAPI().UpdateProfile(m.top.params)
end sub

sub GetProfileData()
    m.top.result = ContentAPI().GetProfileData(m.top.params)
end sub

sub GetTracking()
    m.top.result = ContentAPI().GetTracking(m.top.params)
end sub

sub UpdateTracking()
    m.top.result = ContentAPI().UpdateTracking(m.top.params)
end sub

sub GetFavorites()
    m.top.result = ContentAPI().GetFavorites(m.top.params)
end sub

sub SaveFavorite()
    m.top.result = ContentAPI().SaveFavorite(m.top.params)
end sub

sub AuthenticateContent()
    m.top.result = ContentAPI().AuthenticateContent(m.top.params)
end sub
