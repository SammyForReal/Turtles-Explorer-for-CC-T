---------------------------------------------------------------
-- Copyright Junue 23 2020, Sammy Koch, All rights reserved. --
---------------------------------------------------------------

--Colors ([1/3]=bg; [2/4]=fg)
local sysColor = { colors.cyan, colors.white }
local borders = { colors.black, colors.gray }
local variables = { colors.black, colors.purple }
local selectedItem = { colors.gray, colors.white }
local normalItem = { colors.black, colors.cyan }

--Variables
local clipboard = { } --Selected files/directories
local fileTypes = {["lua"]=colors.blue, ["txt"]=colors.white, ["nfp"]=colors.orange, [" ?"]=colors.lightGray, [" -"]=colors.gray, ["DIR"]=colors.purple } --File type
local currentTime = textutils.formatTime(os.time()) --Time
local path = "rom/programs/" --Current path
local cursor = { scroll=0, pos=1, posX=1, posY=1,click=0,status=0,marked=0 } --click={0=false, 1=left, 2=right};  status={0=normal, 1=popup, 2=functions, 3=mark}
local items = { } --Current items ([1]=type;[2]=name;[3]=state)
local keys_down = {} --Keys which are held
local w, h = term.getSize() --Screen size

--Windows
local explorer = window.create(term.current(), 1, 4, w-16, h-4, true) --Item List
local sysInfos = window.create(term.current(), w-15, 4, 17, h-4, true) --System Informations
local window = window.create(term.current(), w/4, h/4, w/4*2, h/4*2, true) --PopupWindow
local selectedWindow = explorer --Focused window.

--Sizes
local wExp, hExp = explorer.getSize()
local wSys, hSys = sysInfos.getSize()
local category = { file=3, ext=12, size=(wExp-18)/3+13, date=(wExp-10)/3*2+10, info=w-wSys+2 }
local Nformat = { byte=1, kb=0.001, mb=0.000001, gb=0.000000001 }
local numberSize = Nformat.kb
local date = { created=1,modification=2 }
local dateType = date.created

local function round(num) --Rounds numbers up or down
    numR = num + 0.5 - (num + 0.5) % 1
    if numR == 0 then
        numR = string.sub(num, 1,4)
    end
    return numR
end

--GUI
local function printf(form, stringT, x, y, short) --Writes to a specified window
    if not (short == nil) then --Shortens the string
        if #stringT > short then
            local removeChars = 2
            if (#string.sub(stringT, short-2)-1) > 10 then
                removeChars = 3
            end
            stringT = string.sub(stringT, 1, short-removeChars) .. "~" .. #string.sub(stringT, short-2)-1
        end
    end

    form.setCursorPos(x,y)
    form.write(stringT)
    return
end

local function itemListGUI() --The item list
    local border = h-4
    if (h-4)+cursor.scroll > #items then
        border = #items-cursor.scroll

        --Clear list
        explorer.setBackgroundColor(normalItem[1])
        explorer.clear()
        explorer.setCursorPos(1,1)
    end

    for i=1,border,1 do --Draws the list
        local customColor = true
        if items[i+cursor.scroll][3] == ">" or items[i+cursor.scroll][3] == "+" then --Marks the item
            customColor = false
            explorer.setBackgroundColor(selectedItem[1])
            explorer.setTextColor(selectedItem[2])
        else
            explorer.setBackgroundColor(normalItem[1])
            explorer.setTextColor(normalItem[2])
        end

        explorer.setCursorPos(3,i)
        explorer.clearLine()

        --Name
        printf(explorer, items[i+cursor.scroll][2], 3,i, category.ext-category.file-1)

        --File type
        if customColor and not (fileTypes[items[i+cursor.scroll][4][1]] == nil) then
            explorer.setTextColor(fileTypes[items[i+cursor.scroll][4][1]])
        end
        printf(explorer, items[i+cursor.scroll][4][1], category.ext,i)
        if customColor then explorer.setTextColor(normalItem[2]) else explorer.setTextColor(selectedItem[2]) end

        --Size
        if customColor and items[i+cursor.scroll][4][2] == "DIR" then
            explorer.setTextColor(fileTypes["DIR"])
        end
        printf(explorer, items[i+cursor.scroll][4][2], category.size,i)
        if customColor then explorer.setTextColor(normalItem[2]) else explorer.setTextColor(selectedItem[2]) end
        
        --Date
        if customColor and items[i+cursor.scroll][4][3] == "--/--/----" then
            explorer.setTextColor(fileTypes[" -"])
        end
        printf(explorer, items[i+cursor.scroll][4][3], category.date,i)
    end
    return
end

local function sysInfosGUI(variable) --All informations
    if variable == nil then variable = "all" end

    --Clear
    if variable == "all" then 
        sysInfos.setBackgroundColor(normalItem[1])
        sysInfos.setTextColor(normalItem[2])
        sysInfos.clear()
    end

    --Path
    if variable == "path" or variable == "all" then 
        term.setBackgroundColor(normalItem[1])
        term.setTextColor(normalItem[2])
        term.setCursorPos(1,2)
        term.clearLine()
        term.write("/" .. path)

        if cursor.status == 0 then
            term.setTextColor(colors.gray)
            term.write(items[cursor.pos][2])
            if items[cursor.pos][1] == "file" then
                term.write("." .. items[cursor.pos][4][1])
            end
        end
    end

    --Category
    if variable == "all" then
        term.setBackgroundColor(sysColor[1])
        term.setTextColor(sysColor[2])
        term.setCursorPos(1,3)
        term.clearLine()
        
        printf(term, "filename", category.file,3)
        printf(term, "ext", category.ext,3)
        printf(term, "size", category.size,3)
        printf(term, "date", category.date,3)
        printf(term, "sys/disk infos", category.info,3)

    end

    --Headers
    if variable == "headers" or variable == "all" then 
        
        for i=1,wSys-3,1 do --Border
            sysInfos.setBackgroundColor(borders[1])
            sysInfos.setTextColor(borders[2])

            printf(sysInfos, "-", i,1)
            printf(sysInfos, "-", i,6)
            printf(sysInfos, "-", i,11)
        end

        sysInfos.setBackgroundColor(normalItem[1])
        sysInfos.setTextColor(normalItem[2])

        printf(sysInfos, "Disk-space", wSys-13,1)
        printf(sysInfos, "Directory", wSys-12,6)
        printf(sysInfos, "Configs", wSys-11,11)
    end

    sysInfos.setBackgroundColor(variables[1])
    sysInfos.setTextColor(variables[2])

    --Values
    if variable == "values" or variable == "all" then 
        free = tostring( round(fs.getFreeSpace("/")*numberSize) )
        used = tostring( round((fs.getCapacity("/")-fs.getFreeSpace("/"))*numberSize) )
        total = tostring( round(fs.getCapacity("/")*numberSize) )

        printf(sysInfos, free.." avail", wSys-#free-8,2)
        printf(sysInfos, used.." used ", wSys-#used-8,3)
        printf(sysInfos, total.." total", wSys-#total-8,4)
    end

    --Infos
    if variable == "infos" or variable == "all" then
        --Date status
        local dateT = "?"
        if dateType == 1 then dateT = "creation"
        else dateT = "modified" end
        printf(sysInfos, dateT.." date", wSys-7-#dateT,12)

        --Size status
        local sizeSt = "BYTE"
        if numberSize == 0.001 then sizeSt = "KB"
        elseif numberSize == 0.000001 then sizeSt = "MB"
        elseif numberSize == 0.000000001 then sizeSt = "GB" end
        printf(sysInfos, "size: "..sizeSt, wSys-8-#sizeSt,13)
        
        --Time
        printf(sysInfos, currentTime, wSys-2-#currentTime,14)
    end
    return
end

--Functions
local function updateList() --Searches for files/directories in the current path and sorts them
    foundItems = fs.list(path) --Found items
    items = { }
    items[1] = { "dir", "..", ">", {" -", "DIR", "--/--/----"} } --Jump one file back

    for i=1,#foundItems,1 do --Goes through the list and copys them in the item list
        local attributes = nil
        local name = foundItems[i]
        local ext = " ?"
        local size = "DIR"
        local date = "--/--/----"

        if fs.isDir(path .. foundItems[i]) then --DIR
            items[#items+1] = { "dir", foundItems[i], "-", {" -", size, date} }
        else --FILE
            --Date
            attributes = fs.attributes(path .. foundItems[i])
            if dateType == 1 then date = os.date("*t", attributes.created/1000)
            else date = os.date("*t", attributes.modification/1000) end
            date = date.month .. "/" .. date.day .. "/" .. date.year
            
            --Size
            size = round(attributes.size*numberSize)
            if string.sub(name, 1, 1) == "." then --"invisible" file
                name = string.sub(name, 2)
            else --Normal file
                if not (string.find(name, "%.") == nil) then
                    ext = string.sub(name, string.find(name, "%.")+1)
                    name = string.sub(name, 1,string.find(name, "%.")-1)
                else
                    name = name
                end
                
            end

            items[#items+1] = { "file", name, "-", {ext, size, date} }
        end
    end
    cursor.pos = 1
    cursor.scroll = 0
    sysInfosGUI("path")
    return
end

local function itemHandler(action) --Handles the item list
    if action == -1 then --Scroll up
        if keys_down[keys.leftCtrl] or keys_down[keys.rightCtrl] then
            itemHandler(4)
            return
        elseif keys_down[keys.leftShift] or keys_down[keys.rightShift] then
            items[cursor.pos][3] = "+"
            clipboard = { }
            cursor.marked = cursor.marked + 1
            cursor.status = 3
        else
            items[cursor.pos][3] = "-"
            if cursor.status == 3 then itemHandler(5) end
        end

        cursor.pos = cursor.pos-1
        items[cursor.pos][3] = ">"

        if cursor.pos-cursor.scroll < 2 and cursor.scroll > 0 then
            cursor.scroll = cursor.scroll - 1
        end
    elseif action == 1 then --Scroll down
        if keys_down[keys.leftCtrl] or keys_down[keys.rightCtrl] then
            itemHandler(-4)
            return
        elseif keys_down[keys.leftShift] or keys_down[keys.rightShift] then
            items[cursor.pos][3] = "+"
            clipboard = { }
            cursor.status = 3
        else
            items[cursor.pos][3] = "-"
            if cursor.status == 3 then itemHandler(5) end
        end

        cursor.pos = cursor.pos+1
        items[cursor.pos][3] = ">"

        if cursor.pos-cursor.scroll > h-5 then
            cursor.scroll = cursor.scroll + 1
        end
    
    elseif action == 2 then --Enter Folder / run program
        if items[cursor.pos][2] == ".." then --Goes one folder further back
            itemHandler(3)
        elseif items[cursor.pos][1] == "dir" then --Goes into the folder
            path = path .. items[cursor.pos][2] .. "/"
            updateList()
        else --Run's the File
            shell.run("fg " .. path .. items[cursor.pos][2])
        end
    elseif action == 3 then --Goes into the folder
        for i=1,#path,1 do
            if string.sub(path, #path-i, -i-1) == "/" or string.sub(path, #path-i, -i-1) == "" then
                path = string.sub(path, 1, -i-1)
                break
            end
        end
        updateList()
    elseif action == -4 then --Skip to the end
        items[cursor.pos][3] = "-"
        cursor.pos = #items
        items[cursor.pos][3] = ">"
        
        if #items > h-4 then
            cursor.scroll = #items-h+5
        end
    elseif action == 4 then --Jump to the start
        items[cursor.pos][3] = "-"
        cursor.pos = 1
        items[cursor.pos][3] = ">"
        cursor.scroll = 0
    
    elseif action == 5 then --Removes the marks
        for i=1,#items,1 do
            if items[i][3] == "+" then
                items[i][3] = "-"
            end
        end

        cursor.marked = 0
        cursor.status = 0
        itemListGUI()
    elseif action == 6 then --Removes the selected items
        cursor.status = 1
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.red)
        term.setCursorPos(1,h)
        term.clearLine()
        printf(term, "Do you want to remove the items? (y/n)", 1,h)
        local Qevent, Qkey = os.pullEvent("key")
        while true do
            if Qkey == keys.y then
                cursor.status = 0
                break
            elseif Qkey == keys.n then
                term.setCursorPos(1,h)
                term.clearLine()
                cursor.status = 0
                return
            else
                Qevent, Qkey = os.pullEvent("key")
            end
        end

        for i=#items,1,-1 do
            if items[i][3] == "+" or items[i][3] == ">" and not (items[i][2] == "..") then
                term.setCursorPos(1,h)
                term.clearLine()
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.red)

                if items[i][1] == "dir" then
                    printf(term, string.format("Remove item %s", items[i][2]), 1,h)
                    fs.delete("/" .. path .. items[i][2])
                else
                    printf(term, string.format("Remove item %s", items[i][2] .. "." .. items[i][4][1]), 1,h)
                    fs.delete("/" .. path .. items[i][2] .. "." .. items[i][4][1])
                end

                table.remove(items, i)
                cursor.pos = cursor.pos-1
            end
        end

        term.setCursorPos(1,h)
        term.clearLine()

        if cursor.pos < 2 then
            cursor.pos = 1
            cursor.scroll = 0
        end
        items[cursor.pos][3] = ">"
    elseif action == -7 then --Moves the cursor to the top of the screen
        items[cursor.pos][3] = "-"
        if #items < h-4 then
            cursor.pos = 1
        else
            cursor.pos = cursor.scroll+2
        end
        items[cursor.pos][3] = ">"
    elseif action == 7 then --Moves the cursor to the bottom of the screen
        items[cursor.pos][3] = "-"
        if #items > h-5 then
            cursor.pos = cursor.scroll+h-5
        else
            cursor.pos = #items
        end
        items[cursor.pos][3] = ">"
    elseif action == 8 then --Moves the selected files to the clipboard
        clipboard = { }
        for i=1,#items,1 do
            if items[i][3] == "+" or items[i][3] == ">" and not(items[i][2] == "..") then
                if items[i][1] == "dir" then
                    clipboard[#clipboard+1] = { "/" .. path, items[i][2], "" }
                else
                    clipboard[#clipboard+1] = { "/" .. path, items[i][2], "." .. items[i][4][1] }
                end
            end
        end
    elseif action == 9 then --Copys the selected items
        cursor.status = 1
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.orange)
        term.setCursorPos(1,h)
        term.clearLine()
        printf(term, "Do you want to Copy the items? (y/n)", 1,h)
        local Qevent, Qkey = os.pullEvent("key")
        while true do
            if Qkey == keys.y then
                cursor.status = 0
                break
            elseif Qkey == keys.n then
                term.setCursorPos(1,h)
                term.clearLine()
                cursor.status = 0
                return
            else
                Qevent, Qkey = os.pullEvent("key")
            end
        end

        for i=1,#clipboard,1 do
            local fileName = clipboard[#clipboard][2]
            if not(string.find(clipboard[#clipboard][2], "%(") == nil) then
                fileName = string.sub(clipboard[#clipboard][2], 1, string.find(clipboard[#clipboard][2], "%(")-1)
            end
            local name = "/" .. path .. fileName .. clipboard[#clipboard][3]
            local j = 1
            while fs.exists(name) do
                if not(fs.exists(name)) then break end
                name = "/" .. path .. fileName .. "(" ..j.. ")" .. clipboard[#clipboard][3]
                j = j + 1
            end

            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.orange)
            term.setCursorPos(1,h)
            term.clearLine()
            printf(term, string.format("Copy items %s/%s (%s)", i, #clipboard, fileName .. clipboard[#clipboard][3]), 1,h)

            fs.copy( clipboard[#clipboard][1] ..  clipboard[#clipboard][2] .. clipboard[#clipboard][3], name)
            table.remove(clipboard, #clipboard)
        end

        term.setCursorPos(1,h)
        term.clearLine()
        updateList()
    end

    sysInfosGUI("path")
    itemListGUI()
    return
end

--Inputs
local function keyUserInterface() --Handles all Key Inputs 
    while true do
        event, key = os.pullEvent( "key" )

        if selectedWindow == explorer then
            listEnd = hExp-1
            if #items < hExp-2 then listEnd = #items end
            
            if key == keys.up and cursor.pos > 1 then --Move up
                itemHandler(-1)
            elseif key == keys.down and cursor.pos < #items then --Move down
                itemHandler(1)          
            elseif key == keys.home then
                itemHandler(4)
            elseif key == 207 then --207 == end key
                itemHandler(-4)
            elseif key == keys.enter then --Select's the element.
                itemHandler(2)
            elseif key == keys.backspace then --Jumps one folder back
                itemHandler(3)
            elseif key == keys.delete then --Removes all selected items
                itemHandler(6)
            elseif key == keys.pageUp then --Moves the cursor to the top of the screen
                itemHandler(-7)
            elseif key == keys.pageDown then --Moves the cursor to the bottom of the screen
                itemHandler(7)
            
            elseif key == keys.insert then --Pastes the items from the clipboard in the current path
                itemHandler(9)
            elseif keys_down[keys.leftCtrl] or keys_down[keys.rightCtrl] then
                if key == keys.c then
                    itemHandler(8)
                end
            end
        end
    end
    return 0
end

local function keyboard_shortcuts() --Remembers the keys that are held down.
    while true do
        local ev = { coroutine.yield() }
        
        if ev[1] == "key" then
            keys_down[ev[2]] = true 
        elseif ev[1] == "key_up" then
            keys_down[ev[2]] = false
        end
    end
    return 0
end

function main()
    updateList()
    itemListGUI()
    sysInfosGUI("all")
    while true do
        if not(cursor.status == 1) then
            for i=1,w,1 do
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.gray)
                printf(term, "\127", i,h)
            end
        end

        if not(textutils.formatTime(os.time()) == currentTime) then
            currentTime = textutils.formatTime(os.time())
            sysInfosGUI("infos")
        end
        sleep()
    end
    return 0
end

parallel.waitForAll( main, keyUserInterface, keyboard_shortcuts )