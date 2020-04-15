--Version BETA/04/15/20
--Typos fixed 04/14/20(~14:30) by LeMoonStar
--Colors ([1/3]=bg; [2/4]=fg)
selectedItem = { colors.gray, colors.white, colors.cyan, colors.white }
normalItem = { colors.black, colors.cyan }
bar = { colors.blue, colors.lightGray }
pop = { colors.lightGray, colors.black, colors.gray, colors.red }
textField = { colors.cyan, colors.white, colors.lightGray }

--Variable's
version = 0.5
lastEvent, lastKey = {}
keys_down = {}
path = ""   --Current path
sort = { 3, "nameSmall", "nameBig", "sizeSmall", "sizeBig" } --[1]=selectedType; [2]=SortedByName; [3]=SortedBySize
size = { 2, 1, 1000, 1000000, 1000000000000 } --[1]=selectedType; [2]=B; [3]=KB; [4]=MB; [5]=GB
cursorPos = 1 --Current cursorPos
scroll = 1 --Position of the list
writeScroll = {1, 1}
items = { } --Current items ([1]=type;[2]=name;[3]=state)
w, h = term.getSize() --Screen size
categorys = (w-4)/4 --Divide's the line by 5 for the categorie's
activeinfos = { {keys.f1, "Help"}, {keys.f5, "Reload"}, {keys.f6, "Sort"}, {keys.f9, "Size"}, {"arrowsV", "Scroll"} } --info keys

help = "With this Explorer you can browse, edit and run your files much easier.\nIf you are not yet familiar with the Explorer, we recommend that you read this guide.\nWhen you are finished, press CTRL+C to close the window.\n\nUse the arrow keys to scroll.\n\nThe keys at the bottom perform the action shown next to them.\n\nTo use the tools listed above, press CTRL+<First Letter>."

currentDialog = 0
dialogs = {                                                   |
    { "Open with", "what do you want to do with the  file {0}?", {"Cancel", "See Code", "Execute"}, {} },
    { "Reload", "Update GUI..", {}, {} },
    { "Help", "the help dialog was opened            in a new window.", {"Cancel"}, {} }
}

--Window's
explorer = window.create(term.current(), 1, 2, w, h-2, true) --The main area where the items are listed
toolbar = window.create(term.current(), 1, 1, w, 1, true) --The tools to make everything easier to control
infobar = window.create(term.current(), 1, h, w, h, true) --The Shourtcuts that are currently available for the user
popup = window.create(term.current(), 9, 6, w-16, h-10, false) --The window which always comes to the user for special questions.
selectedWindow = "explorer" --Saves the name of the focused window.
buttons = {}

function updateList() --Searches for files/directories in the current path and sorts them
    local foundItems = fs.list(string.gsub(path, "\\", "/")) --The items found
    local currentItems = { } --temporary storage for the found items
    items = { } --Clears the current list

    --Goes through the list and saves it so that the program can better assign it later.
    for i=1,#foundItems,1 do
        if fs.isDir(path .. foundItems[i]) then
            currentItems[i] = { "dir", foundItems[i], "-" }
        else
            currentItems[i] = { "file", foundItems[i], "-" }
        end
    end
 
    items[#items+1] = { "dir", "..", "-" } --Is there to jump back one folder and therefore no real file

    if string.sub(sort[sort[1]], 1, 4) == "name" then --Sorts the items from folder to file by alphabet.
        if sort[sort[1]] == "nameSmall" then
            for i=1,#currentItems,1 do
                if currentItems[i][1] == "dir" then
                    items[#items+1] = currentItems[i]
                end
            end
    
            for i=1,#currentItems,1 do
                if currentItems[i][1] == "file" then
                    items[#items+1] = currentItems[i]
                end
            end
        elseif sort[sort[1]] == "nameBig" then
            for i=#currentItems,1,-1 do
                if currentItems[i][1] == "dir" then
                    items[#items+1] = currentItems[i]
                end
            end
    
            for i=#currentItems,1,-1 do
                if currentItems[i][1] == "file" then
                    items[#items+1] = currentItems[i]
                end
            end
        end
    elseif string.sub(sort[sort[1]], 1, 4) == "size" then --Sorts the items from folder to file by size
        for i=1,#currentItems,1 do
            if currentItems[i][1] == "dir" then
                items[#items+1] = currentItems[i]
            end
        end
        
        local files = {}
        for i=1,#currentItems,1 do
            if currentItems[i][1] == "file" then
                files[#files+1] = currentItems[i]
            end
        end

        if sort[sort[1]] == "sizeSmall" then
            table.sort(files, function(a, b)
                return fs.getSize(path .. a[2]) < fs.getSize(path .. b[2])
            end)
        elseif sort[sort[1]] == "sizeBig" then
            table.sort(files, function(a, b)
                return fs.getSize(path .. a[2]) > fs.getSize(path .. b[2])
            end)
        end

        for i=1,#files,1 do
            items[#items+1] = files[i]
        end
    end
end

--Inputs
function keyboard_shortcuts()
    while true do
        local ev = { coroutine.yield() }
        
        if ev[1] == "key" then
            keys_down[ev[2]] = true 
            if keys_down[keys.leftCtrl] then
                if selectedWindow == "popup" then
                    if lastKey == keys.c then
                        openWindow(dialogs[currentDialog], "Cancel")
                        sleep(0.01)
                        selectedWindow = "explorer"
                        drawList("complete")
                    elseif lastKey == keys.s then
                        for i=1,#dialogs[currentDialog][3],1 do
                            if dialogs[currentDialog][3][i] == "See Code" then
                                openWindow(dialogs[currentDialog], "See Code")
                                sleep(0.01)
                                shell.run("fg edit " .. path .. items[cursorPos][2])
                                reload()
                                break
                            end
                        end
                    elseif lastKey == keys.e then
                        for i=1,#dialogs[currentDialog][3],1 do
                            if dialogs[currentDialog][3][i] == "Execute" then
                                openWindow(dialogs[currentDialog], "Execute")
                                sleep(0.01)
                                shell.run("fg " .. path .. items[cursorPos][2])
                                reload()
                                break
                            end
                        end
                    end
                end
            end
        elseif ev[1] == "key_up" then
            keys_down[ev[2]] = false
        end
    end
end

function help_keys()
    while true do
        local event, key = os.pullEventRaw( "key" )
        lastEvent, lastKey = event, key
        --Informations Keys
        for i=1,#activeinfos,1 do
            if key == activeinfos[i][1] then
                if activeinfos[i][2] == "Reload" then
                    selectedWindow = "popup"
                    openWindow(dialogs[2])
                elseif activeinfos[i][2] == "Help" then
                    local f = fs.open(".temp", "w")
                    f.write(help)
                    f.close()
                    shell.run("fg edit .temp")
                    fs.delete(".temp")
                    selectedWindow = "popup"
                    openWindow(dialogs[3])
                elseif activeinfos[i][2] == "Size" then
                    if size[1] > #size-1 then
                        size[1] = 2
                    else
                        size[1] = size[1]+1
                    end
                    reload()
                elseif activeinfos[i][2] == "Sort" then
                    if sort[1] >= #sort then
                        sort[1] = 2
                    else
                        sort[1] = sort[1] + 1
                    end
                    reload()
                end
            end
        end
    end
end

function control() --handles the inputs for example scrolling
    while true do
        local event, key = os.pullEvent( "key" )
        lastEvent, lastKey = event, key

        if selectedWindow == "explorer" then --Processed for the explorer
            if key == keys.up and cursorPos > 1 then --Select's the previous item
                updateList()
                items[cursorPos][3] = "-"
                cursorPos = cursorPos - 1
                items[cursorPos][3] = "+"
                if cursorPos-scroll < 1 and scroll > 1 then
                    scroll = scroll - 1
                    drawList("complete")
                else
                    drawList("lastItem")
                end
            elseif key == keys.down and cursorPos < #items then --Select's the next item
                updateList()
                items[cursorPos][3] = "-"
                cursorPos = cursorPos + 1
                items[cursorPos][3] = "+"
                if cursorPos-scroll > h-6 and scroll < #items then
                    scroll = scroll + 1
                    drawList("complete")
                else
                    drawList("lastItem")
                end
            elseif key == keys.enter then--Select's the element.
                if items[cursorPos][2] == ".." then --Goes one folder further back
                    for i=1,#path,1 do
                        if string.sub(path, #path-i, -i-1) == "/" or string.sub(path, #path-i, -i-1) == "" then
                            path = string.sub(path, 1, -i-1)
                            updateList()
                            cursorPos = 1
                            items[cursorPos][3] = "+"
                            scroll = 1
                            drawList("complete")
                            break
                        end
                    end
                elseif items[cursorPos][1] == "dir" then --Goes into the folder
                       path = path .. items[cursorPos][2] .. "/"
                        updateList()
                        cursorPos = 1
                        items[cursorPos][3] = "+"
                        scroll = 1
                        drawList("complete")
                else --Run's the File
                    selectedWindow = "popup"
                    dialogs[1][4][1] = items[cursorPos][2]
                    currentDialog = 1
                    openWindow(dialogs[1])
                end
            end
        end

        sleep()
    end
end

--Gui's
function update() --updates the verses.
    while true do
        explorer.setCursorPos(categorys*4-#tostring(textutils.formatTime(os.time("local")))-3, 16)
        explorer.write(textutils.formatTime(os.time("local")) .. " time") --The time

        local currentW, currentH = term.getSize()
        if not (w == currentW and h == currentH) then
            reload()
        end

        sleep()
    end
end

function drawToolbar() --draws the toolbar
    while true do --Serves only as placeholder
        toolbar.setBackgroundColor(bar[1])
        toolbar.setTextColor(bar[2])
        toolbar.setCursorPos(1, 1)
        toolbar.clearLine()
        sleep()
    end
end

function drawInfobar() --draws the infobar
    infobar.setBackgroundColor(bar[1])
    infobar.setTextColor(bar[2])
    infobar.setCursorPos(1, 1)
    infobar.clearLine()

    local itemPos = w/#activeinfos
    for i=1,#activeinfos,1 do
        if activeinfos[i][1] == "arrowsV" then
            infobar.setTextColor(colors.white)
            infobar.write(" Up/Dn")
            infobar.setTextColor(bar[2])
            infobar.write("-".. activeinfos[i][2])
        else
            infobar.setTextColor(colors.white)
            infobar.write(" "  .. string.upper(tostring(keys.getName(activeinfos[i][1]))))
            infobar.setTextColor(bar[2])
            infobar.write("-".. activeinfos[i][2])
        end
    end
end

function drawButton(form, text, status, color, x, y) --draws the buttons
    if status == true then
        form.setBackgroundColor(color[3])
    else
        form.setBackgroundColor(color[1])
    end
    
    form.setCursorPos(x, y)
    form.setTextColor(pop[4])
    form.write(string.sub(text, 1, 1))

    form.setTextColor(color[2])
    form.write(string.sub(text, 2, #text))
end

function reload() --reloads the GUI
    cursorPos = 1 --Current cursorPos
    scroll = 1 --Position of the list  
    w, h = term.getSize() --Screen size
    categorys = (w-4)/4 --Divide's the line by 5 for the categorie's
    updateList()
    items[cursorPos][3] = "+"
    explorer = window.create(term.current(), 1, 2, w, h-2, true)
    toolbar = window.create(term.current(), 1, 1, w, 1, true)
    infobar = window.create(term.current(), 1, h, w, h, true)
    popup = window.create(term.current(), 9, 6, w-16, h-10, false)
    selectedWindow = "explorer"
    currentDialog = 0
    drawInfobar()
    drawList("complete")
    explorer.redraw()
end

function openWindow(type, buttonStat) --draws the popup
    local wp, hp = popup.getSize()
    if selectedWindow == "popup" then --Makes the window visible when it is focused.
        popup.setBackgroundColor(pop[1])
        popup.setTextColor(pop[2])
        popup.clear()
        popup.setVisible(true)
        popup.setTextColor(pop[3])
        for i=1,wp,1 do
            popup.setCursorPos(i, 1)
            popup.write("=")
            popup.setCursorPos(i, hp)
            popup.write("=")
        end
        popup.setTextColor(pop[2])
        popup.setCursorPos(1, 1)
        popup.write("[")
        popup.setCursorPos(wp, 1)
        popup.write("]")
        popup.setCursorPos(1, hp)
        popup.write("[")
        popup.setCursorPos(wp, hp)
        popup.write("]")
    else
        popup.setVisible(false)
    end

    local buttonSize = math.floor(wp/#type[3]) --Button distance
    popup.setTextColor(pop[2])
    popup.setCursorPos(3, 1)
    popup.write(type[1])

    for i=1,#type[3],1 do
        local stat = false
        if type[3][i] == buttonStat then
            stat = true
        end

        drawButton(popup, type[3][i], stat, pop, buttonSize*(i-1)+2, hp-1)
    end

    local text = {}
    
    text[1] = type[2]
    if #type[2] > wp-2 then --divides it up between the lines
        for j=1,#type[4],1 do --replaced the {number-1} with the variable[number]
            type[2] = string.gsub(type[2], "{" .. j-1 .. "}", "\"" .. type[4][j] .. "\"")
        end
        
        for i=1,hp-4,1 do
            text[i] = string.sub(type[2], 1+i*(wp-2)-(wp-2), i*(wp-2))
        end
    end

    for i=1,hp-4,1 do
        if text[i] == nil then
            text[i] = ""
        end
    end

    for i=1,#text,1 do
        popup.setCursorPos(2,1+i)
        popup.write(text[i])
    end

    if type == dialogs[2] then
        sleep(0.8)
        reload()
    end   
end

function drawList(typeList) --draws the current List
    if typeList == "complete" then
        --Clears the screen
        explorer.setBackgroundColor(normalItem[1])
        explorer.setTextColor(normalItem[2])
        explorer.clear()

        explorer.setCursorPos(1, 1)
        explorer.write(fs.getDrive("") .. ":\\" .. string.gsub(path, "/", "\\")) --Shows the current path

        if os.getComputerLabel() == nil then --Displays the name of the computer.
            explorer.setCursorPos(w-8 ,1)
            explorer.write("[PC]") --Writes "[PC]" in case the PC has no label.
        else
            explorer.setCursorPos(w-6-#os.getComputerLabel(),1)
            explorer.write("[" .. os.getComputerLabel() .. "]")
        end

        --Clear's the line containing the categorie's
        explorer.setBackgroundColor(selectedItem[3])
        explorer.setTextColor(selectedItem[4])
        explorer.setCursorPos(1,2)
        explorer.clearLine()

        --Draw's the categorie's
        for i=1,5,1 do
            if i == 1 then --categorie for the filenames
                explorer.setCursorPos(categorys*i+3-categorys, 2)
                explorer.write(string.sub("filename", 1, categorys))
            elseif i == 2 then --categorie for the sizes
                if size[1] == 2 then
                    explorer.setCursorPos(categorys*i+3-categorys, 2)
                    explorer.write(string.sub("size(B)", 1, categorys-2))
                elseif size[1] == 3 then
                    explorer.setCursorPos(categorys*i+3-categorys, 2)
                    explorer.write(string.sub("size(KB)", 1, categorys-2))
                elseif size[1] == 4 then
                    explorer.setCursorPos(categorys*i+3-categorys, 2)
                    explorer.write(string.sub("size(MB)", 1, categorys-2))
                elseif size[1] == 5 then
                    explorer.setCursorPos(categorys*i+3-categorys, 2)
                    explorer.write(string.sub("size(GB)", 1, categorys-2))
                end
            elseif i == 3 then --categorie for the date(which is currently not yet supported, 'cause [1.15.2]1.87 isnt out yet) 
                explorer.setCursorPos(categorys*i+3-categorys-2, 2)
                explorer.write(string.sub("date", 1, categorys-4))
            elseif i == 4 then --categories for disk & system information's
                explorer.setCursorPos(categorys*i+3-categorys-4, 2)
                explorer.write(string.sub("about disk & system", 1, categorys+5))
            end
        end

        local filesCount = 0 --Counter for the files in the current path
        local dirsCount = 0 --Counter for the directorys in the current path

        --Number of entries for the list
        local itemCounter = #items
        if itemCounter > h-1 then
            itemCounter = h-2
        end

        for i=1,itemCounter,1 do
            if i > h-4 then break end
            if items[i+scroll-1] == nil then break end

            if items[i+scroll-1][3] == "-" then --Change's the current color for the unmarked item
                explorer.setBackgroundColor(normalItem[1])
                explorer.setTextColor(normalItem[2])
            elseif items[i+scroll-1][3] == "+" then --Change's the current color for the marked item
                explorer.setBackgroundColor(selectedItem[1])
                explorer.setTextColor(selectedItem[2])
            end

            --Draw's the Line in the current color for the item if its selected
            if items[i+scroll-1][3] == "+" then
                explorer.setCursorPos(1, i+2)
                for i=1,categorys*3-2,1 do
                    explorer.write(" ")
                end
            end

            --Draw's the current name of the file
            explorer.setCursorPos(1, i+2)
            if #items[i+scroll-1][2] > categorys-1 then
                explorer.write("  " .. string.sub(items[i+scroll-1][2], 1, categorys-6) .. "." .. string.sub(items[i+scroll-1][2], #items[i+scroll-1][2]-3)) --Here shortened
            else
                explorer.write("  " .. items[i+scroll-1][2]) --Here normally
            end

            --Show's here the size of the file
            explorer.setCursorPos(categorys+3, i+2)
            if fs.isDir(string.gsub(path, "\\", "/") .. items[i+scroll-1][2]) then --Writes only <DIR> if this is a folder
                explorer.write("<DIR>");
            else
                if not (items[i+scroll-1][2] == "..") then --Writes here the size of the file (also compressed to the desired size)
                    explorer.write(math.floor((fs.getSize(string.gsub(path, "\\", "/") .. items[i+scroll-1][2])/size[size[1]])))
                else --Writes only <DIR> if this is a folder
                    explorer.write("<DIR>");
                end
            end

            --Placeholder for the date
            explorer.setCursorPos(categorys*2+1, i+2)
            explorer.write("-")
        end

        for i=1,#items,1 do
            if not (items[i][2] == "..") then
                if fs.isDir(path .. items[i][2]) then
                    dirsCount = dirsCount + 1
                elseif not (fs.isDir(path .. items[i][2])) then
                    filesCount = filesCount + 1
                end
            end
        end

        --Sets the colors back to normal for the column with the information about the disk and the system
        explorer.setBackgroundColor(normalItem[1])
        explorer.setTextColor(normalItem[2])

        explorer.setCursorPos(categorys*4-7, 3)
        explorer.write("Disk space") --Next column
        explorer.setCursorPos(categorys*4-#tostring(math.floor(fs.getFreeSpace("hdd")/size[size[1]]))-3, 4)
        explorer.write(math.floor(fs.getFreeSpace("hdd")/size[size[1]]) .. " avail") --available memory of the system
        explorer.setCursorPos(categorys*4-#tostring(math.floor(2100000/size[size[1]]))-3, 5)
        explorer.write(math.floor(2500000/size[size[1]]) .. " total") --Total memory of the system
        explorer.setCursorPos(categorys*4-4, 6)
        explorer.write("- used") --Placeholder for the used memory

        explorer.setCursorPos(categorys*4-6, 8)
        explorer.write("Directory") --Next column
        explorer.setCursorPos(categorys*4-#tostring(dirsCount)-3, 9)
        explorer.write(dirsCount .. " dirs") --Number of the directorys in the current path
        explorer.setCursorPos(categorys*4-#tostring(filesCount)-3, 10)
        explorer.write(filesCount .. " files") --Number of the files in the current path

        explorer.setCursorPos(categorys*4-9, 12)
        explorer.write("Marked files") --Next column
        explorer.setCursorPos(categorys*4-4, 13)
        explorer.write("- files") --Placeholder for the number of marked files
        if size[1] == 1 then --List's the size of the marked files (which is currently still a placeholder)
            explorer.setCursorPos(categorys*4-4, 14)
            explorer.write(string.sub("- bytes", 1, categorys-2))
        elseif size[1] == 1000 then
            explorer.setCursorPos(categorys*4-1, 14)
            explorer.write(string.sub("- KB", 1, categorys-2))
        elseif size[1] == 1000000 then
            explorer.setCursorPos(categorys*4-1, 14)
            explorer.write(string.sub("- MB", 1, categorys-2))
        elseif size[1] == 1000000000000 then
            explorer.setCursorPos(categorys*4-1, 14)
            explorer.write(string.sub("- GB", 1, categorys-2))
        end


        explorer.setCursorPos(categorys*4-#tostring(textutils.formatTime(os.time("local")))-3, 16)
        explorer.write(textutils.formatTime(os.time("local")) .. " time") --The time
    elseif typeList == "lastItem" then --Redraw's the only Line who is changed in the list
        drawList("complete")
    end

    sleep()
end 

--Setup
updateList()
cursorPos = 1
items[cursorPos][3] = "+"
drawList("complete")

parallel.waitForAll( help_keys, control, keyboard_shortcuts, drawToolbar, drawInfobar, update )
