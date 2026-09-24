' Persistencia local entre lanzamientos del canal (roRegistrySection).
' Guarda la sesion del gateway de 13go (el equivalente al localStorage
' "@auth_session" de c13_reloaded) y el perfil elegido ("currentProfile").
Function CreateRegistryManager() as Object
    this = {
        SECTION: "Canal13GoAuth",

        ' authData = { userId, accessToken, refreshToken, expiresIn, tokenType, deviceId }
        SaveAuthData: Sub(data as Object)
            reg = CreateObject("roRegistrySection", m.SECTION)
            reg.Write("authData", FormatJson(data))
            reg.Flush()
        End Sub,

        GetAuthData: Function() as Object
            reg = CreateObject("roRegistrySection", m.SECTION)
            if not reg.Exists("authData") then return invalid
            return ParseJSON(reg.Read("authData"))
        End Function,

        ClearAuthData: Sub()
            reg = CreateObject("roRegistrySection", m.SECTION)
            reg.Delete("authData")
            reg.Delete("currentProfile")
            reg.Flush()
        End Sub,

        ' currentProfile = { profileId, profileName, profileUri }
        SaveSelectedProfile: Sub(profile as Object)
            reg = CreateObject("roRegistrySection", m.SECTION)
            reg.Write("currentProfile", FormatJson(profile))
            reg.Flush()
        End Sub,

        GetSelectedProfile: Function() as Object
            reg = CreateObject("roRegistrySection", m.SECTION)
            if not reg.Exists("currentProfile") then return invalid
            return ParseJSON(reg.Read("currentProfile"))
        End Function,

        ClearAllSettings: Sub()
            Registry = CreateObject("roRegistry")
            For each section in Registry.GetSectionList()
                RegistrySection = CreateObject("roRegistrySection", section)
                For each key in RegistrySection.GetKeyList()
                    Print "RegistryManager : ClearAllSettings : Deleting : Section : " + section + " Key : " key
                    RegistrySection.Delete(key)
                End For
                RegistrySection.Flush()
            End For
        End Sub
    }

    Return this
End Function
