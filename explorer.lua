--Colors ([1/3]=bg; [2/4]=fg)
local sysColor = { colors.cyan, colors.white }
local borders = { colors.black, colors.gray }
local variables = { colors.black, colors.purple }
local selectedItem = { colors.gray, colors.white }
local normalItem = { colors.black, colors.cyan }

--Variables
local fileTypes = {["lua"]=colors.blue, ["txt"]=colors.white, ["nfp"]=colors.orange, [" ?"]=colors.lightGray, [" -"]=colors.gray, ["DIR"]=colors.purple }
local currentTime = textutils.formatTime(os.time())
local path = "/rom/programs/"   --Current path
local date = { created=1,modification=2 }
local dateType = date.created
local cursor = { scroll=0, pos=1, posX=1, posY=1,click=0 } --click] = {0=false, 1=left, 2=right}
local items = { } --Current items ([1]=type;[2]=name;[3]=state)
local w, h = term.getSize() --Screen size

--Windows
local explorer = window.create(term.current(), 1, 4, w-16, h-4, true) --Item List
local sysInfos = window.create(term.current(), w-15, 4, 17, h-4, true) --System Informations
local selectedWindow = explorer --Focused window.

--Sizes
local xExp, yExp = explorer.getSize()
local wSys, hSys = sysInfos.getSize()
local category = { file=3, ext=12, size=(xExp-18)/3+13, date=(xExp-10)/3*2+10, info=w-wSys+2 }
local Nformat = { byte=1, kb=0.001, mb=0.000001, gb=0.000000001 }
local numberSize = Nformat.kb

local function round(num)
    numR = num + 0.5 - (num + 0.5) % 1
    if numR == 0 then
        numR = string.sub(num, 1,4)
    end
    return numR
end

--GUI
local function printf(form, stringT, x, y, short)
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

local function itemListGUI()
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
        if items[i+cursor.scroll][3] == ">" then --Marks the item
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
end

local function sysInfosGUI(variable)
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
        term.write(path)
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
            printf(sysInfos, "-", i,10)
        end

        sysInfos.setBackgroundColor(normalItem[1])
        sysInfos.setTextColor(normalItem[2])

        printf(sysInfos, "Disk-space", wSys-13,1)
        printf(sysInfos, "Directory", wSys-12,6)
        printf(sysInfos, "Configs", wSys-11,10)
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
        printf(sysInfos, dateT.." date", wSys-7-#dateT,11)

        --Size status
        local sizeSt = "BYTE"
        if numberSize == 0.001 then sizeSt = "KB"
        elseif numberSize == 0.000001 then sizeSt = "MB"
        elseif numberSize == 0.000000001 then sizeSt = "GB" end
        printf(sysInfos, "size: "..sizeSt, wSys-8-#sizeSt,12)
        
        --Time
        printf(sysInfos, currentTime, wSys-2-#currentTime,13)
    end
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
                ext = string.sub(name, string.find(name, ".", -4)+1)
                name = string.sub(name, 1,string.find(name, ".", -4)-1)
            end

            items[#items+1] = { "file", name, "-", {ext, size, date} }
        end
    end
    cursor.pos = 1
    cursor.scroll = 0
    sysInfosGUI("path")
end

local function itemListHandler(action) --Handles the item list
    if action == -1 then --Scroll down
        items[cursor.pos][3] = "-"
        cursor.pos = cursor.pos-1
        items[cursor.pos][3] = ">"

        if cursor.pos-cursor.scroll < 2 and cursor.scroll > 0 then
            cursor.scroll = cursor.scroll - 1
        end
    elseif action == 1 then --Scroll up
        items[cursor.pos][3] = "-"
        cursor.pos = cursor.pos+1
        items[cursor.pos][3] = ">"

        if cursor.pos-cursor.scroll > h-5 then
            cursor.scroll = cursor.scroll + 1
        end
    elseif action == 2 then --Enter Folder / run program
        if items[cursor.pos][2] == ".." then --Goes one folder further back
            for i=1,#path,1 do
                if string.sub(path, #path-i, -i-1) == "/" or string.sub(path, #path-i, -i-1) == "" then
                    path = string.sub(path, 1, -i-1)
                    break
                end
            end
            updateList()
        elseif items[cursor.pos][1] == "dir" then --Goes into the folder
            path = path .. items[cursor.pos][2] .. "/"
            updateList()
        else --Run's the File
            shell.run("fg " .. path .. items[cursor.pos][2])
        end
    end
end

--Inputs
local function keyUserInterface() 
    while true do
        event, key = os.pullEvent( "key" )

        if selectedWindow == explorer then
            listEnd = yExp-1
            if #items < yExp-2 then listEnd = #items end
            
            if key == keys.down and cursor.pos < #items then --Move down
                itemListHandler(1)
            elseif key == keys.up and cursor.pos > 1 then --Move up
                itemListHandler(-1)
            elseif key == keys.enter then --Select's the element.
                itemListHandler(2)
            end
            itemListGUI()
        end
    end
end

function main()
    updateList()
    itemListGUI()
    sysInfosGUI("all")
    while true do
        if not(textutils.formatTime(os.time()) == currentTime) then
            currentTime = textutils.formatTime(os.time())
            sysInfosGUI("infos")
        end
        sleep()
    end
end

parallel.waitForAll( main, keyUserInterface )