---------------- Variables ----------------
local fileTypes = { --File types colors
    ["lua"]=colors.blue,
    ["txt"]=colors.white,
    ["nfp"]=colors.orange,
    [" ?"]=colors.lightGray,
    [" -"]=colors.gray,
    ["DIR"]=colors.purple
}
local currentTime = textutils.formatTime(os.time()) --Time
local path = "rom/programs/" --Current path
local cursor = { scroll=0, pos=1, posX=1, posY=1,click=0,status=0,marked=0 } --click={0=false, 1=left, 2=right};  status={0=normal, 1=popup, 2=functions, 3=mark}
local items = { } --Current items ([1]=type;[2]=name;[3]=state)
local keys_down = {} --Keys which are held
local w, h = term.getSize() --Screen size
local sort = 1 --[0=found order, 1=size, 2=date, 3=type]

--Windows
local explorer = window.create(term.current(), 1, 4, w-16, h-4, true) --Item List
local sysInfos = window.create(term.current(), w-15, 4, 17, h-4, true) --System Informations
local popupWindow = window.create(term.current(), w/4, h/4, w/4*2, h/4*2, true) --PopupWindow
local selectedWindow = explorer --Focused window.

--Sizes
local wExp, hExp = explorer.getSize()
local wSys, hSys = sysInfos.getSize()
local category = { file=3, ext=14, size=(wExp-18)/3+14, date=(wExp-10)/3*2+9, info=w-wSys+2 }
local Nformat = { byte=1, kb=0.001, mb=0.000001, gb=0.000000001 }
local numberSize = Nformat.kb
local date = { created=1,modification=2 }
local dateType = date.created


---------------- Math ----------------
--Returns a number rounded up or down
local function round(num) 
    numR = num + 0.5 - (num + 0.5) % 1
    if numR == 0 then
        numR = string.sub(num, 1,4)
    end
    return numR
end

--Returns the index of an array
local function getIndex(array, value) 
    local index = 1
    for i=1,#array,1 do
        if array[i] == value then return index end
        index = index + 1
    end

    return 0
end


---------------- TUI ----------------
--Writes a string to the selected terminal at x,y
local function printp(form, stringT, x, y, short) 
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
end

--Draws the items of the current folder
local function itemListGUI() 
    local listEnd = h-4
    if (h-4)+cursor.scroll > #items then
        listEnd = #items-cursor.scroll

        explorer.setBackgroundColor(colors.black)
        explorer.clear()
    end

    --Lists the items
    for i=1,listEnd,1 do
        local textColor = colors.cyan
        --draws the background of the current element
        if items[i+cursor.scroll][3] == ">" or items[i+cursor.scroll][3] == "+" then
            explorer.setBackgroundColor(colors.gray)
            textColor = colors.white
        else
            explorer.setBackgroundColor(colors.black)
        end

        explorer.setTextColor(textColor)
        explorer.setCursorPos(3,i)
        explorer.clearLine()

        --print name
        printp(explorer, items[i+cursor.scroll][2], 3,i, category.ext-category.file-1)

        --Print file type
        explorer.setTextColor(textColor)
        if textColor == colors.cyan and fileTypes[items[i+cursor.scroll][4][1]] then
            explorer.setTextColor(fileTypes[items[i+cursor.scroll][4][1]])
        end
        printp(explorer, items[i+cursor.scroll][4][1], category.ext,i)

        explorer.setTextColor(textColor)
        
        --Print size
        if textColor == colors.cyan then
            if items[i+cursor.scroll][4][2] == "DIR" then
                explorer.setTextColor(fileTypes["DIR"])
            end
        end
        printp(explorer, items[i+cursor.scroll][4][2], category.size,i)

        explorer.setTextColor(textColor)
        
        --Print date
        if textColor == colors.cyan and items[i+cursor.scroll][4][3] == "--/--/----" then
            explorer.setTextColor(fileTypes[" -"])
        end
        printp(explorer, items[i+cursor.scroll][4][3], category.date,i)
    end
end

--Writes all important informations
local function sysInfosGUI(variable) 
    --Clear
    if variable == nil then 
        sysInfos.setBackgroundColor(colors.black)
        sysInfos.setTextColor(colors.cyan)
        sysInfos.clear()
    end

    --Path
    if variable == "path" or variable == nil then 
        local label = "nil"
        if os.getComputerLabel() then label = os.getComputerLabel() end

        --Clear
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.cyan)
        term.setCursorPos(1,2)
        term.clearLine()

        --Current Path
        if #path+2 >= w-#label-5 then
            printp(term, "/" .. string.sub(path, 1, w-#label-10) .. ".../", 1, 2)
        else
            printp(term, "/" .. path, 1, 2)
        end

        --Computers Label
        if not(label == "nil") then
            term.setCursorPos(w-#label-3, 2)

            term.setTextColor(colors.yellow)
            term.write("[")
            
            term.setTextColor(colors.white)
            term.write(label)

            term.setTextColor(colors.yellow)
            term.write("]")

            term.setCursorPos(2+#path,2)
        end

        --Current file
        if cursor.status == 0 then
            term.setTextColor(colors.gray)
            term.write(items[cursor.pos][2])
            if items[cursor.pos][1] == "file" and not(items[cursor.pos][4][1] == " ?") then
                term.write("." .. items[cursor.pos][4][1])
            end
        end
    end

    --Toolbar
    if variable == "toolbar" or variable == nil then
        term.setBackgroundColor(colors.blue)
        term.setCursorPos(1,1)
        term.clearLine()

        term.setTextColor(colors.white)
        printp(term, "X", w,1)
    end

    --Category
    if variable == nil then
        term.setBackgroundColor(colors.cyan)
        term.setTextColor(colors.white)
        term.setCursorPos(1,3)
        term.clearLine()

        printp(term, "filename", category.file,3)
        printp(term, "ext", category.ext,3)
        printp(term, "size", category.size,3)
        printp(term, "date", category.date,3)
        printp(term, "sys/disk infos", category.info,3)

    end

    --Headers
    if variable == "headers" or variable == nil then 
        for i=1,wSys-3,1 do --Border
            sysInfos.setBackgroundColor(colors.black)
            sysInfos.setTextColor(colors.gray)

            printp(sysInfos, "-", i,1)
            printp(sysInfos, "-", i,6)
            printp(sysInfos, "-", i,10)
        end

        local dirName = "Directory"
        if cursor.status == 3 then
            dirName = "Selected"
        end

        sysInfos.setBackgroundColor(colors.black)
        sysInfos.setTextColor(colors.cyan)

        printp(sysInfos, "Disk-space", wSys-14,1)
        printp(sysInfos, dirName, wSys-14,6)
        printp(sysInfos, "Configs", wSys-14,10)
    end

    --Values
    if variable == "values" or variable == nil then 
        --Disk-space
        local free = tostring( round(fs.getFreeSpace("/")*numberSize) )
        local used = tostring( round((fs.getCapacity("/")-fs.getFreeSpace("/"))*numberSize) )
        local total = tostring( round(fs.getCapacity("/")*numberSize) )

        sysInfos.setBackgroundColor(colors.black)
        sysInfos.setTextColor(colors.purple)

        printp(sysInfos, free.." avail", wSys-#free-8,2)
        printp(sysInfos, used.." used ", wSys-#used-8,3)
        printp(sysInfos, total.." total", wSys-#total-8,4)
        
        --Directory
        local dirs = -1
        local files = 0
        if cursor.status == 3 then
            for i=1,#items,1 do
                if items[i][1] == "dir" then
                    dirs = dirs + 1
                else
                    files = files + 1
                end
            end
        else
            for i=1,#items,1 do
                if items[i][1] == "dir" then
                    dirs = dirs + 1
                else
                    files = files + 1
                end
            end
        end

        dirs = tostring(dirs)
        files = tostring(files)

        printp(sysInfos, dirs.." dirs", wSys-#dirs-8,7)
        printp(sysInfos, files.." files", wSys-#files-8,8)
    end

    --config's information
    if variable == "infos" or variable == nil then
        --Date status
        local dateT = "?"
        if dateType == 1 then dateT = "create"
        else dateT = "modified" end
        printp(sysInfos, " date: "..dateT, wSys-9-#dateT,11)

        --Size
        local sizeSt = "BYTE"
        if numberSize == 0.001 then sizeSt = "KB"
        elseif numberSize == 0.000001 then sizeSt = "MB"
        elseif numberSize == 0.000000001 then sizeSt = "GB" end
        printp(sysInfos, "size: "..sizeSt, wSys-8-#sizeSt,12)     

        --Sort
        local type
        if sort == 1 then --from big to small
            type = "BIG"
        elseif sort == 2 then -- from small to big
            type = "SMALL"
        elseif sort == 3 then --type
            type = "TYPE"
        else --none method
            type = "NONE"
        end

        printp(sysInfos, "sort: "..type, wSys-8-#type,13)
        
        --Time
        printp(sysInfos, currentTime, wSys-2-#currentTime,14)
    end
end


---------------- Function ----------------
--Saves all files and folders with the necessary information
local function updateList() 
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

            --Names 
            if not(string.sub(name, 1, 1) == ".") then
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

    if sort == 1 then
        table.sort(items,
            function(a,b)
                if a[2] == ".." then return true
                elseif b[2] == ".." then return false
                elseif fs.isDir(path..a[2]) then return true
                elseif fs.isDir(path..b[2]) then return false
                else 
                    local aT = "." .. a[4][1]
                    local bT = "." .. b[4][1]
                    if a[4][1] == " -" then aT = "" end
                    if b[4][1] == " -" then bT = "" end
                    return fs.getSize(path..b[2]..bT)<fs.getSize(path..a[2]..aT)
                end
            end
        )
    elseif sort == 2 then
        table.sort(items,
            function(a,b)
                if a[2] == ".." then return true
                elseif b[2] == ".." then return false
                elseif a[4][3] == "--/--/----" then return true
                elseif b[4][3] == "--/--/----" then return false
                 end

                local aT = "." .. a[4][1]
                if a[4][1] == " -" then aT = "" end
                attributes = fs.attributes(path .. a[2]..aT)
                if dateType == 1 then date = os.date("*t", attributes.created/1000)
                else date = os.date("*t", attributes.modification/1000) end
                dateA = tonumber(date.year .. date.month .. date.day) 
            
                local bT = "." .. b[4][1]
                if b[4][1] == " -" then bT = "" end
                attributes = fs.attributes(path .. b[2]..bT)
                if dateType == 1 then date = os.date("*t", attributes.created/1000)
                else date = os.date("*t", attributes.modification/1000) end
                dateB = tonumber(date.year .. date.month .. date.day) 

                return dateA<dateB
            end
        )
    
    elseif sort == 3 then
        table.sort(items,
            function(a,b)
                if a[2] == ".." then return true
                elseif b[2] == ".." then return false
                end

                if a[4][1] == " -" then return true
                elseif b[4][1] == " -" then return false
                end

                return getIndex(fileTypes, a[4][1])<getIndex(fileTypes, b[4][1])
            end
        )
    end

    cursor.pos = 1
    cursor.scroll = 0
    sysInfosGUI("path")
    return
end

---------------- Item handler ----------------
local item = { ["run"]=nil, ["back"]=nil, ["enter"]=nil, ["remove"]=nil, ["copy"]=nil }

item.run = function() 
    cursor.status = 1

    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.green)
    term.setCursorPos(1,h)
    term.clearLine()

    printp(term, "How do you want to open the file? (Run/Edit/Cancel)", 1,h)

    while true do
        local Qevent, Qkey = os.pullEvent("key")

        if Qkey == keys.r then
            shell.run("fg " .. path .. items[cursor.pos][2])
            break
        elseif Qkey == keys.e then
            shell.run("fg edit " .. path .. items[cursor.pos][2])
            break
        elseif Qkey == keys.c then
            break
        end
    end

    cursor.status = 0
end

item.back = function() 
    for i=1,#path,1 do
        if string.sub(path, #path-i, -i-1) == "/" or string.sub(path, #path-i, -i-1) == "" then
            path = string.sub(path, 1, -i-1)
            break
        end
    end

    updateList()
    sysInfosGUI("path")
    itemListGUI()
end

item.enter = function() 
    if items[cursor.pos][2] == ".." then --Goes one folder further back
        item.back()
    elseif items[cursor.pos][1] == "dir" then --Goes into the folder
        path = path .. items[cursor.pos][2] .. "/"
        updateList()
        sysInfosGUI("path")
        itemListGUI()
    end
end

item.remove = function() 
    cursor.status = 1

    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.red)
    term.setCursorPos(1,h)
    term.clearLine()

    printp(term, "Do you want to remove the items? ([Y]/[N])", 1,h)
    local Qevent, Qkey = os.pullEvent("key")

    while true do
        if Qkey == keys.y then
            break
        elseif Qkey == keys.n then
            break
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
                if fs.isReadOnly("/" .. path .. items[i][2]) then
                    printp(term, string.format("folder %s cannot be deleted!", items[i][2]), 1,h)
                else
                    printp(term, string.format("Remove item %s", items[i][2]), 1,h)
                    fs.delete("/" .. path .. items[i][2])

                    table.remove(items, i)
                    cursor.pos = cursor.pos-1
                end
            else
                if fs.isReadOnly("/" .. path .. items[i][2] .. "." .. items[i][4][1]) then
                    printp(term, string.format("file %s cannot be deleted!", items[i][2]), 1,h)
                else
                    printp(term, string.format("Remove item %s", items[i][2] .. "." .. items[i][4][1]), 1,h)
                    fs.delete("/" .. path .. items[i][2] .. "." .. items[i][4][1])

                    table.remove(items, i)
                    cursor.pos = cursor.pos-1
                end
            end
        end
    end

    term.setCursorPos(1,h)
    term.clearLine()

    items[cursor.pos][3] = ">"

    itemListGUI()
    cursor.status = 0
end

item.copy = function() 
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
end

item.paste = function() 
    cursor.status = 1

    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.orange)
    term.setCursorPos(1,h)
    term.clearLine()
    printp(term, "Do you want to Copy the items? ([y]/[n])", 1,h)
    local Qevent, Qkey = os.pullEvent("key")
    while true do
        if Qkey == keys.y then
            break
        elseif Qkey == keys.n then
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

        if fs.isReadOnly(path) then
            printp(term, "nothing can be written in this folder!", 1,h)
            clipboard = { }
            
            break
        else
            printp(term, string.format("Copy items %s/%s (%s)", i, #clipboard, fileName .. clipboard[#clipboard][3]), 1,h)

            fs.copy( clipboard[#clipboard][1] ..  clipboard[#clipboard][2] .. clipboard[#clipboard][3], name)
        end
        
        table.remove(clipboard, #clipboard)
    end

    updateList()
    itemListGUI()

    cursor.status = 0
end

local function cursorHandler(action) --Handles the item list
    if action == -1 then --Scroll up
        if keys_down[keys.leftCtrl] or keys_down[keys.rightCtrl] then
            cursorHandler(4)
            return
        elseif keys_down[keys.leftShift] or keys_down[keys.rightShift] then
            items[cursor.pos][3] = "+"
            clipboard = { }
            cursor.marked = cursor.marked + 1
            cursor.status = 3
        else
            items[cursor.pos][3] = "-"
            if cursor.status == 3 then cursorHandler(5) end
        end

        cursor.pos = cursor.pos-1
        items[cursor.pos][3] = ">"

        if cursor.pos-cursor.scroll < 2 and cursor.scroll > 0 then
            cursor.scroll = cursor.scroll - 1
        end
    elseif action == 1 then --Scroll down
        if keys_down[keys.leftCtrl] or keys_down[keys.rightCtrl] then
            cursorHandler(-4)
            return
        elseif keys_down[keys.leftShift] or keys_down[keys.rightShift] then
            items[cursor.pos][3] = "+"
            clipboard = { }
            cursor.status = 3
        else
            items[cursor.pos][3] = "-"
            if cursor.status == 3 then cursorHandler(5) end
        end

        cursor.pos = cursor.pos+1
        items[cursor.pos][3] = ">"

        if cursor.pos-cursor.scroll > h-5 then
            cursor.scroll = cursor.scroll + 1
        end
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
    end

    itemListGUI()
    return
end


---------------- Loops ----------------
local finishNormally = false

--Handles keys inptus
local function keyUserInterface() --Handles all Key Inputs 
    while not(finishNormally) do
        local event, key = os.pullEvent( "key" )

        if selectedWindow == explorer then
            local listEnd = hExp-1
            if #items < hExp-2 then listEnd = #items end
            
            if key == keys.up and cursor.pos > 1 then --Move up
                cursorHandler(-1)
            elseif key == keys.down and cursor.pos < #items then --Move down
                cursorHandler(1)          
            elseif key == keys.home then
                cursorHandler(4)
            elseif key == 207 then --207 == end key
                cursorHandler(-4)
            elseif key == keys.enter then --Select's the element.
                if items[cursor.pos][1] == "dir" then
                    item.enter() else item.run()
                end
            elseif key == keys.backspace then --Jumps one folder back
                item.back()
            elseif key == keys.delete then --Removes all selected items
                item.remove()
            elseif key == keys.pageUp then --Moves the cursor to the top of the screen
                cursorHandler(-7)
            elseif key == keys.pageDown then --Moves the cursor to the bottom of the screen
                cursorHandler(7)
            elseif key == keys.insert then --Pastes the items from the clipboard in the current path
                item.paste()
            elseif keys_down[keys.leftCtrl] or keys_down[keys.rightCtrl] then
                if key == keys.c then
                    item.copy()
                elseif keey == keys.v then
                    item.paste()
                end
            end
        end
    end

    finishNormally = true
    return 0
end

--Handle key combinations
local function keyboard_shortcuts() 
    while not(finishNormally) do
        local ev = { coroutine.yield() }
        
        if ev[1] == "key" then
            keys_down[ev[2]] = true 
        elseif ev[1] == "key_up" then
            keys_down[ev[2]] = false
        end
    end
    
    finishNormally = true
    return 0
end

--Handle Mouse Interactions
local function mouseUserInterface() 
    while not(finishNormally) do
        local event, button, xPos, yPos = os.pullEvent("mouse_click")

        --Checks if the user clicks on an item
        if xPos < wSys and yPos > 3 and yPos < h then
            if yPos < #items-cursor.scroll+4 then
                --Enter/Run Item
                if cursor.pos-cursor.scroll == yPos-3 then
                    if items[cursor.pos][1] == "dir" then
                        item.enter() else item.run()
                    end
                else --Set position
                    items[cursor.pos][3] = "-"
                    cursor.pos = yPos-3+cursor.scroll
                    items[cursor.pos][3] = ">"
                    itemListGUI()
                end
            end
        elseif yPos == 1 then
            if xPos == w then
                finishNormally = true
            end
        end
    end

    finishNormally = true
    return 0
end

--Scroll handler
local function scrollUserInterface() 
    while not(finishNormally) do
        local event, scrollWay, xPos, yPos = os.pullEvent("mouse_scroll")
        if selectedWindow == explorer then
                if scrollWay == -1 and cursor.pos > 1 or scrollWay == 1 and cursor.pos < #items then
                    cursorHandler(scrollWay)
                end
        else
            selectedWindow = explorer
        end
    end

    finishNormally = true
    return 0
end

--Main loop
function main()
    updateList()
    itemListGUI()
    sysInfosGUI()
    while not(finishNormally) do
        if not(cursor.status == 1 or cursor.status == 2) then
            for i=1,w,1 do
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.gray)
                printp(term, "\127", i,h)
            end
        end

        if not(textutils.formatTime(os.time()) == currentTime) then
            currentTime = textutils.formatTime(os.time())
            sysInfosGUI("infos")
        end
        sleep()
    end

    finishNormally = true
    return 0
end


parallel.waitForAny( main, keyUserInterface, keyboard_shortcuts, mouseUserInterface, scrollUserInterface )

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1,1)
term.setCursorBlink(true)

--Error Dialog
if not(finishNormally) then
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.red)
    printp(term, ":(  Oops! Something went wrong!", 1,2)

    term.setTextColor(colors.orange)
    printp(term, "if you have discovered a bug,", 1,3)
    printp(term, "please report it under:", 1,4)
    term.setTextColor(colors.white)
    printp(term, "github.com/1Turtle/Turtles-Explorer-for-CC-T/issues", 1,5)
end
