function CreateViewStackManager() as object
    instance = {
        ViewStack: [],

        ReplaceScreen: sub(node)
            ' print "ViewStack : ReplaceScreen"
            m.HideAll()
            m.ViewStack = []
            m.ShowScreen(node)
        end sub,

        GetTop: function()
            top = m.ViewStack.peek()
            ' print "ViewStack : GetTop " ' top
            return top
        end function,

        GetTopId: function()
            ' print "ViewStack : GetTopId"
            id = ""
            prev = m.ViewStack.peek()
            if isValid(prev)
                id = prev.id
            end if

            return id
        end function,

        ShowScreen: sub(node)
            ' print "ViewStack : ShowScreen"
            prev = m.ViewStack.peek()
            if isValid(prev)
                prev.visible = false
            end if
            node.visible = true
            ' node.setFocus(true)
            m.ViewStack.push(node)
        end sub,

        ShowScreenWithOutHidePrev: sub(node)
            ' print "ViewStack : ShowScreen"
            node.visible = true
            ' node.setFocus(true)
            m.ViewStack.push(node)
        end sub,

        HideTop: sub()
            ' print "ViewStack : HideTop"
            m.HideScreen(invalid, false)
        end sub,

        FocusTop: sub()
            ' print "ViewStack : FocusTop"
            node = m.ViewStack.peek()
            if isValid(node)
                node.setFocus(true)
            end if
        end sub,

        HideAll: sub()
            ' print "ViewStack : HideAll"
            m.HideScreen(invalid, true)
        end sub,

        HideScreen: sub(node as Object, hideAllViews as boolean)
            ' print "ViewStack : HideScreen"
            if isInvalid(node) OR (isValid(m.ViewStack.peek()) AND m.ViewStack.peek().isSameNode(node))
                last = m.ViewStack.pop()
                if isValid(last)
                    last.visible = false
                end if

                if (hideAllViews)
                    while (m.ViewStack.Count() > 0)
                        last = m.ViewStack.pop()
                        if isValid(last)
                            last.visible = false
                        end if
                    end while
                end if

                prev = m.ViewStack.peek()
                if isValid(prev)
                    prev.visible = true
                    prev.setFocus(true)
                end if
            end if
        end sub,

        GetViewCount: function() as integer
            return m.ViewStack.Count()
        end function
    }

    return instance
end function
