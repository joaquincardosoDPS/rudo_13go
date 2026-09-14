sub Init()
end sub

' Sin intercepción: se deja la navegación nativa del MarkupGrid.
' (Se conserva el componente por si hace falta reintroducir ajustes de foco.)
function onKeyEvent(key as string, press as boolean) as boolean
    return false
end function
