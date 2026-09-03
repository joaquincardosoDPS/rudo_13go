Function CreateRegistryManager() as Object
    this = {
        SaveUserData: Sub(data as Object)
            reg = CreateObject("roRegistrySection", "TVCHVAppAuth")
            formatData = FormatJson(data)
            reg.Write("userData", formatData)
            reg.Flush()
        End Sub,

        GetUserData: Function() as Object
            reg = CreateObject("roRegistrySection", "TVCHVAppAuth")
            readValues = reg.Read("userData")
            auth = ParseJSON(readValues)
            Return auth
        End Function,

        ClearAllSettings: Sub()
            Registry = CreateObject("roRegistry")
            For each section in Registry.GetSectionList()
                RegistrySection = CreateObject("roRegistrySection", section)
                For each key in RegistrySection.GetKeyList()
                    Print "RegistryManager : ClearAllSettings : Deleting : Section : " + section + "Key : " key
                    RegistrySection.Delete(key)
                End For
                RegistrySection.Flush()
            End For
        End Sub
        SaveToken: sub(token as String)
            reg = CreateObject("roRegistrySection", "TVCHVAppAuth")
            reg.Write("Usertoken", token)
            reg.Flush()
        end sub,
        GetToken: function() as String
            reg = CreateObject("roRegistrySection", "TVCHVAppAuth")
            readValues = reg.Read("Usertoken")
            return readValues
        end function,
        ClearToken: sub()
            reg = CreateObject("roRegistrySection", "TVCHVAppAuth")
            reg.Delete("Usertoken")
            reg.Flush()
        end sub,
    }

    Return this
End Function
