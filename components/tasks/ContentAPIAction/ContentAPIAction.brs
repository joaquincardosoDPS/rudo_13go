sub Init()
end sub

function GetAllCategories() as void
    response = ContentAPI().GetAllCategories(m.top.params)
    m.top.result = response
end function

function GetFeaturedSliderPrograms() as void
    response = ContentAPI().GetFeaturedSliderPrograms(m.top.params)
    m.top.result = response
end function

sub GetSearchPrograms()
    response = ContentAPI().GetSearchPrograms(m.top.params)
    if(isValid(response))
        m.top.result = response
    end if
end sub

function GetMyListPrograms() as void
    print "ContentAPIAction : GetMyListPrograms"
    response = ContentAPI().GetMyListPrograms(m.top.params)
    if(isValid(response))
        m.top.result = response
    end if
end function

function GetPrograms() as void
    print "ContentAPIAction : GetPrograms"
    response = ContentAPI().GetPrograms(m.top.params)
    if(isValid(response))
        m.top.result = response
    end if
end function

function GetAllPrograms() as void
    print "ContentAPIAction : GetAllPrograms"
    response = ContentAPI().GetAllPrograms(m.top.params)
    if(isValid(response))
        m.top.result = response
    end if
end function

function GetProgramDetails() as void
    print "ContentAPIAction : GetProgramDetails"
    response = ContentAPI().GetProgramDetails(m.top.params)
    if(isValid(response))
        m.top.result = response
    end if
end function

function GetSeasonEpisodeDetails() as void
    print "ContentAPIAction : GetSeasonEpisodeDetails"
    response = ContentAPI().GetSeasonEpisodeDetails(m.top.params)
    if(isValid(response))
        m.top.result = response
    end if
end function

function GetEpisodeDetails() as void
    print "ContentAPIAction : GetEpisodeDetails"
    response = ContentAPI().GetEpisodeDetails(m.top.params)
    if(isValid(response))
        m.top.result = response
    end if
end function

function GetProgramEventsDetails() as void
    print "ContentAPIAction : GetProgramEventsDetails"
    response = ContentAPI().GetProgramEventsDetails(m.top.params)
    if(isValid(response))
        m.top.result = response
    end if
end function

function GetEventSeasonEpisodeDetails() as void
    print "ContentAPIAction : GetEventSeasonEpisodeDetails"
    response = ContentAPI().GetEventSeasonEpisodeDetails(m.top.params)
    if(isValid(response))
        m.top.result = response
    end if
end function

function GetEPGData() as void
    print "ContentAPIAction : GetEPGData"
    response = ContentAPI().GetEPGData()
    if(isValid(response))
        m.top.result = response
    end if
end function

function GetEPGPrograms() as void
    print "ContentAPIAction : GetEPGPrograms"
    response = ContentAPI().GetEPGPrograms()
    if(isValid(response))
        m.top.result = response
    end if
end function

function GetConfig() as void
    print "ContentAPIAction : GetConfig"
    response = ContentAPI().GetConfig()
    if(isValid(response))
        m.top.result = response
    end if
end function

function GetHomeConfig() as void
    response = ContentAPI().GetHomeConfig()
    m.top.result = response
end function

function GetRecommendedPrograms() as void
    print "ContentAPIAction : GetRecommendedPrograms"
    response = ContentAPI().GetRecommendedPrograms()
    if(isValid(response))
        m.top.result = response
    end if
end function

function CheckItemInFavourite() as void
    print "ContentAPIAction : CheckItemInFavourite"
    response = ContentAPI().CheckItemInFavourite(m.top.params)
    if(isValid(response))
        m.top.result = response
    end if
end function

function AddRemoveFavourite() as void
    print "ContentAPIAction : AddRemoveFavourite"
    response = ContentAPI().AddRemoveFavourite(m.top.params)
    if(isValid(response))
        m.top.result = response
    end if
end function

function GetWatchHistory() as void
    print "ContentAPIAction : GetWatchHistory"
    response = ContentAPI().GetWatchHistory(m.top.params)
    if(isValid(response))
        m.top.result = response
    end if
end function

function GetAllWatchHistory() as void
    print "ContentAPIAction : GetAllWatchHistory"
    response = ContentAPI().GetAllWatchHistory(m.top.params)
    if(isValid(response))
        m.top.result = response
    end if
end function

function AddWatchHistory() as void
    print "ContentAPIAction : AddWatchHistory"
    response = ContentAPI().AddWatchHistory(m.top.params)
    if(isValid(response))
        m.top.result = response
    end if
end function
