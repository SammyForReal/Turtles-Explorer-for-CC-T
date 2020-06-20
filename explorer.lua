--Colors ([1/3]=bg; [2/4]=fg)
local sysColor = { colors.cyan, colors.white }
local borders = { colors.black, colors.gray }
local variables = { colors.black, colors.purple }
local selectedItem = { colors.gray, colors.white }
local normalItem = { colors.black, colors.cyan }

--Variables
local currentTime = textutils.formatTime(os.time())
local path = "/rom/programs/"   --Current path
local cursor = { scroll=0, pos=1, posX=1, posY=1,click=0 } --click] = {0=false, 1=left, 2=right}
local items = { } --Current items ([1]=type;[2]=name;[3]=state)
local w, h = term.getSize() --Screen size

--Windows
local explorer = window.create(term.current(), 1, 4, w-16, h-4, true) --Item List
local sysInfos = window.create(term.current(), w-15, 4, w-34, h-4, true) --System Informations
local selectedWindow = explorer --Focused window.

--Sizes
local xExp, yExp = explorer.getSize()
local wSys, hSys = sysInfos.getSize()
local Nformat = { byte=1, kb=0.001, mb=0.000001, gb=0.000000001 }
local numberSize = Nformat.kb

--Functions
local function updateList() --Searches for files/directories in the current path and sorts them
    foundItems = fs.list(path) --Found items
    items = { }
    items[1] = { "dir", "..", ">" } --Jump one file back

    for i=1,#foundItems,1 do --Goes through the list and copys them in the item list
        if fs.isDir(path .. foundItems[i]) then
            items[#items+1] = { "dir", foundItems[i], "-" }
        else
            items[#items+1] = { "file", foundItems[i], "-" }
        end
    end
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
    end
end

local function round(num)
    numR = num + 0.5 - (num + 0.5) % 1
    if numR == 0 then
        numR = string.sub(num, 1,4)
    end
    return numR
end

--GUI
local function printf(form, string, x, y)
    form.setCursorPos(x,y)
    form.write(string)
end

local function itemListGUI()
    xExp, yExp = explorer.getSize()

    --Clear
    explorer.setBackgroundColor(normalItem[1])
    explorer.clear()
    explorer.setCursorPos(1,1)

    local border = h-4
    if (h-4)+cursor.scroll > #items then
        border = #items-cursor.scroll
    end

    for i=1,border,1 do --Draws the list
        explorer.setBackgroundColor(normalItem[1])
        explorer.setTextColor(normalItem[2])
        explorer.setCursorPos(3,i)

        if items[i+cursor.scroll][3] == ">" then --Marks the item
            explorer.setBackgroundColor(selectedItem[1])
            explorer.setTextColor(selectedItem[2])
            explorer.clearLine()
        end

        local name = items[i+cursor.scroll][2]
        explorer.write(name)
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
    if variable == "all" then 
        term.setCursorPos(1,2)
        term.setBackgroundColor(normalItem[1])
        term.setTextColor(normalItem[2])
        term.clearLine()
        term.write(path)
    end

    --Category
    if variable == "all" then
        term.setCursorPos(1,3)
        term.setBackgroundColor(sysColor[1])
        term.setTextColor(sysColor[2])
        term.clearLine()
        
        printf(term, "filename", 3,3)
        printf(term, "ext", 13,3)
        printf(term, "size", 17,3)
        printf(term, "date", 22,3)
        printf(term, "sys/disk infos", w-wSys+2,3)

    end

    --Headers
    if variable == "headers" or variable == "all" then 
        
        for i=1,wSys-3,1 do
            sysInfos.setBackgroundColor(borders[1])
            sysInfos.setTextColor(borders[2])

            printf(sysInfos, "-", i,1)
            printf(sysInfos, "-", i,6)
            printf(sysInfos, "-", i,10)
        end

        sysInfos.setBackgroundColor(normalItem[1])
        sysInfos.setTextColor(normalItem[2])

        printf(sysInfos, "Disk-space", wSys-13,1)
        printf(sysInfos, "Direktory", wSys-12,6)
        printf(sysInfos, "Config's", wSys-11,10)
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
        currentTime = textutils.formatTime(os.time())
        local sizeSt = "BYTE"
        if numberSize == 0.001 then sizeSt = "KB"
        elseif numberSize == 0.000001 then sizeSt = "MB"
        elseif numberSize == 0.000000001 then sizeSt = "GB" end

        printf(sysInfos, "size: "..sizeSt, wSys-8-#sizeSt,12)
        printf(sysInfos, currentTime, wSys-2-#currentTime,13)
    end
end

--Inputs
local function keyUserInterface() 
    while true do
        event, key = os.pullEvent( "key" )

        if selectedWindow == explorer then
            listEnd = yExp-1
            if #items < yExp-2 then listEnd = #items end
            
            if key == keys.down and cursor.pos < #items then
                itemListHandler(1)
            elseif key == keys.up and cursor.pos > 1 then
                itemListHandler(-1)
            end
            itemListGUI()
        end
        sleep()
    end
end

function main()
    updateList()
    itemListGUI()
    sysInfosGUI("all")
    while true do
        if not(textutils.formatTime(os.time()) == currentTime) then
            sysInfosGUI("infos")
        end
        sleep()
    end
end

parallel.waitForAll( main, keyUserInterface )
