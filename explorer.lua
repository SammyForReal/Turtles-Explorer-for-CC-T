--Colors 1=bg; 2=fg
selectedItem = { colors.gray, colors.white, colors.cyan, colors.white }
normalItem = { colors.black, colors.cyan }
bar = { colors.blue, colors.gray }

--Variable's
path = ""   --Current path
size = { 1, 1, 1000, 1000000, 1000000000000} -- 1=current; 2=byte; 3=kb; 4=mb; 5=gb
cursorPos = 1 --Current cursorPos
scroll = 0 --Position of the list
items = { } --Current items
w, h = term.getSize()

--Window's
explorer = window.create(term.current(), 1, 2, w, h-2, true)
toolbar = window.create(term.current(), 1, 1, w, 1, true)
infobar = window.create(term.current(), 1, h, w, h, true)
selectedWindow = "explorer"

--Function's
function updateList() --Searches for files/directorys in the current path
    local currentItems = { }
    foundItems = fs.list(string.gsub(path, "\\", "/"))
    items = { }

    for i=1,#foundItems,1 do
        if fs.isDir(string.gsub(path, "\\", "/") .. foundItems[i]) then
            currentItems[i] = { "dir", foundItems[i], "-" }
        else
            currentItems[i] = { "file", foundItems[i], "-" }
        end
    end
 
    items[#items+1] = { "dir", "..", "-" }

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
end

function input() --Handles the inputs
    while true do
        local event, key = os.pullEventRaw( "key" )
        updateList()

        if selectedWindow == "explorer" then
            if key == keys.up and cursorPos > 1 then
                items[cursorPos][3] = "-"
                cursorPos = cursorPos - 1
                items[cursorPos][3] = "+"

                drawList("lastItem")
            elseif key == keys.down and cursorPos < #items then
                items[cursorPos][3] = "-"
                cursorPos = cursorPos + 1
                items[cursorPos][3] = "+"

                drawList("lastItem")
            elseif key == keys.enter then
                if items[cursorPos][2] == ".." then
                    local oldpath = path
                    for i=1,#oldpath,1 do
                        if string.sub(oldpath, #oldpath-i, -i-1) == "/" or string.sub(oldpath, #oldpath-i, -i-1) == "" then
                            path = string.sub(oldpath, 1, -i-1)

                            updateList()
                            cursorPos = 1
                            items[cursorPos][3] = "+"

                            drawList("complete")
                            break
                        end
                    end
                else
                    if items[cursorPos][1] == "dir" then
                       path = path .. items[cursorPos][2] .. "/"

                        updateList()
                        cursorPos = 1
                        items[cursorPos][3] = "+"
                    else
                        shell.run("fg " .. path .. items[cursorPos][2])
                    end
                end

                drawList("complete")
            end
        end

        sleep()
    end
end

--Gui's
function drawToolbar()
    while true do
        toolbar.setBackgroundColor(bar[1])
        toolbar.setTextColor(bar[2])
        toolbar.setCursorPos(1, 1)
        toolbar.clearLine()
        sleep()
    end
end

function drawList(typeList) --draws the current List
    if typeList == "complete" then
        --Clears the screen
        explorer.setBackgroundColor(normalItem[1])
        explorer.setTextColor(normalItem[2])
        explorer.clear()

        explorer.setCursorPos(1, 1)
        explorer.write(fs.getDrive("") .. ":\\" .. string.gsub(path, "/", "\\"))

        if os.getComputerLabel() == nil then
            explorer.setCursorPos(w-8 ,1)
            explorer.write("[PC]")
        else
            explorer.setCursorPos(w-6-#os.getComputerLabel(),1)
            explorer.write("[" .. os.getComputerLabel() .. "]")
        end

        local categorys = (w-4)/4 --Divide's the line by 5 for the categories

        explorer.setBackgroundColor(selectedItem[3])
        explorer.setTextColor(selectedItem[4])
        explorer.setCursorPos(1,2)
        explorer.clearLine()

        for i=1,5,1 do
            if i == 1 then
                explorer.setCursorPos(categorys*i+3-categorys, 2)
                explorer.write(string.sub("filename", 1, categorys))
            elseif i == 2 then
                if size[1] == 1 then
                    explorer.setCursorPos(categorys*i+3-categorys, 2)
                    explorer.write(string.sub("size(B )", 1, categorys-2))
                elseif size[1] == 1000 then
                    explorer.setCursorPos(categorys*i+3-categorys, 2)
                    explorer.write(string.sub("size(KB)", 1, categorys-2))
                elseif size[1] == 1000000 then
                    explorer.setCursorPos(categorys*i+3-categorys, 2)
                    explorer.write(string.sub("size(MB)", 1, categorys-2))
                elseif size[1] == 1000000000000 then
                    explorer.setCursorPos(categorys*i+3-categorys, 2)
                    explorer.write(string.sub("size(GB)", 1, categorys-2))
                end
            elseif i == 3 then
                explorer.setCursorPos(categorys*i+3-categorys-2, 2)
                explorer.write(string.sub("date", 1, categorys-4))
            elseif i == 4 then
                explorer.setCursorPos(categorys*i+3-categorys-4, 2)
                explorer.write(string.sub("about disk & system", 1, categorys+5))
            end
        end

        local filesCount = 0
        local dirsCount = 0
        for i=1,#items,1 do
            if i > h-4 then break end

            if items[i][3] == "-" then
                explorer.setBackgroundColor(normalItem[1])
                explorer.setTextColor(normalItem[2])
            elseif items[i][3] == "+" then
                explorer.setBackgroundColor(selectedItem[1])
                explorer.setTextColor(selectedItem[2])
            end

            if items[i][3] == "+" then
                explorer.setCursorPos(1, i+2+scroll)
                for i=1,categorys*3-2,1 do
                    explorer.write(" ")
                end
            end

            explorer.setCursorPos(1, i+2+scroll)
            if #items[i][2] > categorys-1 then
                explorer.write("  " .. string.sub(items[i][2], 1, categorys-6) .. "." .. string.sub(items[i][2], #items[i][2]-3))
            else
                explorer.write("  " .. items[i][2])
            end

            explorer.setCursorPos(categorys+3, i+2+scroll)
            if fs.isDir(string.gsub(path, "\\", "/") .. items[i][2]) then
                dirsCount = dirsCount + 1
                explorer.write("<DIR>");
            else
                filesCount = filesCount + 1
                if not (items[i][2] == "..") then
                    explorer.write((fs.getSize(string.gsub(path, "\\", "/") .. items[i][2])/size[1]))
                else
                    dirsCount = dirsCount + 1
                    explorer.write("<DIR>");
                end
            end

            explorer.setCursorPos(categorys*2+1, i+2+scroll)
            explorer.write("-")
        end

        explorer.setBackgroundColor(normalItem[1])
        explorer.setTextColor(normalItem[2])

        explorer.setCursorPos(categorys*4-7, 3)
        explorer.write("Disk space")
        explorer.setCursorPos(categorys*4-#tostring(fs.getFreeSpace("hdd")/size[1])-3, 4)
        explorer.write(fs.getFreeSpace("hdd")/size[1] .. " avail")
        explorer.setCursorPos(categorys*4-#tostring(2100000/size[1])-3, 5)
        explorer.write(2000000/size[1] .. " total")
        explorer.setCursorPos(categorys*4-4, 6)
        explorer.write("- used")

        explorer.setCursorPos(categorys*4-6, 8)
        explorer.write("Directory")
        explorer.setCursorPos(categorys*4-#tostring(dirsCount)-3, 9)
        explorer.write(dirsCount .. " dirs")
        explorer.setCursorPos(categorys*4-#tostring(filesCount)-3, 10)
        explorer.write(filesCount .. " files")

        explorer.setCursorPos(categorys*4-9, 12)
        explorer.write("Marked files")
        explorer.setCursorPos(categorys*4-4, 13)
        explorer.write("- files")
        explorer.setCursorPos(categorys*4-4, 14)
        explorer.write("- bytes")

        explorer.setCursorPos(categorys*4-#tostring(textutils.formatTime(os.time("local")))-3, 16)
        explorer.write(textutils.formatTime(os.time("local")) .. " time")
    elseif typeList == "lastItem" then
        drawList("complete")
    end

    sleep()
end 

updateList()
cursorPos = 1
items[cursorPos][3] = "+"

drawList("complete")

--Runtime
parallel.waitForAny( input, drawToolbar )
