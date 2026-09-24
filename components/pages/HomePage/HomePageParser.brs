function rowListDataParser(rowData as object) as dynamic
    mainContent = invalid
    if isValid(rowData) AND rowData.count() > 0 AND isValid(rowData.programs) AND rowData.programs.count() > 0
        mainContent = CreateObject("roSGNode", "ContentNode")
        rowNode = mainContent.CreateChild("ContentNode")
        rowNode.title = rowData.title
        rowNode.AddFields({ image_orientation: rowData.image_orientation, liveCategory: rowData.liveCategory, format: rowData.format, image_background_category: rowData.image_background_category, image_logo_category: rowData.image_logo_category, key: rowData.key, total_display_records: rowData.total_display_records, total_records: rowData.total_records })
        createChildNode(rowNode, rowData.programs, rowData.image_orientation, rowData.format)
    end if
    return mainContent
end function

function createChildNode(rowNode as dynamic, programs as dynamic, image_orientation = "landscape" as string, format = "default" as string)
    if isValid(programs) AND programs.count() > 0
        counter = 1
        for each itemAA in programs
            if isValid(itemAA)
                if counter <= 10 OR ((format = "event" AND image_orientation = "portrait") OR rowNode.title = "Seguir Viendo")
                    itemAA.image_orientation = image_orientation
                    itemAA.format = format
                    itemAA.category_key = rowNode.key
                    if format = "tracking"
                        ' "Seguir viendo": los campos de /accountTracking (seconds, show, path...)
                        ' no estan declarados en ProgramItemNode; update(, true) los crea.
                        itemContent = CreateObject("roSGNode", "ContentNode")
                        itemContent.update(itemAA, true)
                    else
                        itemContent = CreateObject("roSGNode", "ProgramItemNode")
                        itemContent.setFields(itemAA)
                    end if
                    if format = "ranking"
                        itemContent.AddFields({ number: counter })
                    end if
                    ' isProgerss = false
                    ' if rowNode.title = "Seguir Viendo" AND isValid(itemAA.duration_seg) AND itemAA.duration_seg > 0 AND isValid(itemAA.time) AND itemAA.time > 0
                    '     progressPercentage = getProgressPercent(itemAA.time, itemAA.duration_seg)
                    '     if hasResumeProgress(progressPercentage) then isProgerss = true
                    '     if isProgerss then rowNode.appendChild(itemContent)
                    ' else
                    rowNode.appendChild(itemContent)
                    ' end if
                    counter++
                end if
            end if
        end for
        if rowNode.total_records > 10 AND (format <> "event" AND image_orientation <> "portrait")
            itemAA = {}
            itemAA.image_orientation = image_orientation
            itemAA.category_key = rowNode.key
            itemAA.format = format
            itemAA.title = "Ver Más"
            itemAA.isViewMoreCard = true
            itemContent = CreateObject("roSGNode", "ProgramItemNode")
            itemContent.setFields(itemAA)
            rowNode.appendChild(itemContent)
        end if
    end if
end function