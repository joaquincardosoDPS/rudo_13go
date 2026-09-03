sub Init()
end sub

sub Login()
    response = ContentAPI().Login(m.top.params)
    if(isValid(response))
        m.top.result = response
    end if
end sub

sub SignUp()
    response = ContentAPI().SignUp(m.top.params)
    if(isValid(response))
        m.top.result = response
    end if
end sub

sub CheckValidToken()
    response = ContentAPI().CheckValidToken(m.top.params)
    if(isValid(response))
        m.top.result = Ok(response)
    Else
        m.top.result = response
    End If
end sub

sub GetProfilesData()
    response = ContentAPI().GetProfilesData()
    if(isValid(response))
        m.top.result = Ok(response)
    Else
        m.top.result = response
    End If
end sub

sub GetAllAvatar()
    response = ContentAPI().GetAllAvatar()
    if(isValid(response))
        m.top.result = Ok(response)
    Else
        m.top.result = response
    End If
end sub

sub ProfileManagement()
    response = ContentAPI().ProfileManagement(m.top.action, m.top.params)
    if(isValid(response))
        m.top.result = Ok(response)
    Else
        m.top.result = response
    End If
end sub

sub GetDeviceCodeAPI()
    response = ContentAPI().GetDeviceCodeAPI()
    if(isValid(response))
        m.top.result = Ok(response)
    Else
        m.top.result = response
    End If
end sub

sub VerifyDevice()
    response = ContentAPI().VerifyDevice(m.top.params)
    if(isValid(response))
        m.top.result = Ok(response)
    Else
        m.top.result = response
    End If
end sub