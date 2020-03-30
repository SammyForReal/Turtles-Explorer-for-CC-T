--Version BETA/03/30/20
--Colors ([1/3]=bg; [2/4]=fg)
selectedItem = { colors.gray, colors.white, colors.cyan, colors.white }
normalItem = { colors.black, colors.cyan }
bar = { colors.blue, colors.gray }
pop = { colors.lightGray, colors.black, colors.gray, colors.red }

--Variable's
path = ""   --Current path
size = { 1, 1, 1000, 1000000, 1000000000000} --[1]=selectedType; [2]=B; [3]=KB; [4]=MB; [5]=GB
cursorPos = 1 --Current cursorPos
scroll = 1 --Position of the list
items = { } --Current items ([1]=type;[2]=name;[3]=state)
w, h = term.getSize() --Screen size

--Window's
explorer = window.create(term.current(), 1, 2, w, h-2, true) --The main area where the items are listed
toolbar = window.create(term.current(), 1, 1, w, 1, true) --The tools to make everything easier to control
infobar = window.create(term.current(), 1, h, w, h, true) --The Shourtcuts that are currently available for the user
popup = window.create(term.current(), 9, 6, w-16, h-10, false) --The window which always comes to the user for special questions.
selectedWindow = "explorer" --Saves the name of the focused window.

--shortcuts

--Function's
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

    --Sorts the items from folder to file also automatically by alphabet.
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

function input() --Processe's the entries
    while true do
        local event, key = os.pullEventRaw( "key" )

        if selectedWindow == "explorer" then --Processed for the explorer
            if key == keys.up and cursorPos > 1 then --Select's the previous item
                updateList()

                items[cursorPos][3] = "-"
                cursorPos = cursorPos - 1
                items[cursorPos][3] = "+"

                if cursorPos-scroll < 1 and scroll > 1 then
                    scroll = scroll - 1
                end

                drawList("lastItem")
            elseif key == keys.down and cursorPos < #items then --Select's the next item
                updateList()
                
                items[cursorPos][3] = "-"
                cursorPos = cursorPos + 1
                items[cursorPos][3] = "+"

                if cursorPos-scroll > h-6 and scroll < #items then
                    scroll = scroll + 1
                end

                drawList("lastItem")
            elseif key == keys.enter then--Select's the element.
            --If it is an order, he goes inside.
            --If it is a file, he asks how the user wants to execute it.
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
                    openFile("execute")
                end
            end
        elseif selectedWindow == "popup" then --Processed for the Popup
            if key == keys.r then --Runs the program normally
                shell.run("fg " .. path .. items[cursorPos][2])
                explorer.redraw()
                selectedWindow = "explorer"
                openFile(type, item)
            elseif key == keys.e then --Edit's the program
                shell.run("fg edit " .. path .. items[cursorPos][2])
                explorer.redraw()
                selectedWindow = "explorer"
                openFile(type, item)
            elseif key == keys.c then --Does nothing
                explorer.redraw()
                selectedWindow = "explorer"
                openFile(type, item)
            end
        end

        event, key = nil
        sleep()
    end
end

--Gui's
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
    while true do --Serves only as placeholder
        infobar.setBackgroundColor(bar[1])
        infobar.setTextColor(bar[2])
        infobar.setCursorPos(1, 1)
        infobar.clearLine()
        sleep()
    end
end

function openFile(type) --draws the popup
    if type == "execute" then --Asks how the user wants to execute the seleceted file.
        if selectedWindow == "popup" then --Makes the window visible when it is focused.
            popup.setBackgroundColor(pop[1])
            popup.setTextColor(pop[2])
            popup.clear()

            popup.setVisible(true)
        else
            popup.setVisible(false)
        end

        local wp, hp = popup.getSize()
        local buttonSize = (wp)/3 --Button distance

        popup.setTextColor(pop[3])
        for i=1,wp,1 do
            popup.setCursorPos(i, 1)
            popup.write("=")
            popup.setCursorPos(i, hp)
            popup.write("=")
        end

        popup.setCursorPos(1, 1)
        popup.write("[")
        popup.setCursorPos(wp, 1)
        popup.write("]")
        popup.setCursorPos(1, hp)
        popup.write("[")
        popup.setCursorPos(wp, hp)
        popup.write("]")

        popup.setTextColor(pop[2])
        popup.setCursorPos(2, 2)
        popup.write("How do you want to")

        popup.setCursorPos(2, 3)
        popup.write("execute the file " .. items[cursorPos][2] .. "?")

        popup.setCursorPos(2, h-11)
        popup.setTextColor(pop[4])
        popup.write("C")
        popup.setTextColor(pop[2])
        popup.write("ancel")

        popup.setCursorPos(buttonSize+2, h-11)
        popup.setTextColor(pop[4])
        popup.write("E")
        popup.setTextColor(pop[2])
        popup.write("dit")

        popup.setCursorPos(buttonSize*2+2, h-11)
        popup.setTextColor(pop[4])
        popup.write("R")
        popup.setTextColor(pop[2])
        popup.write("un")
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

        local categorys = (w-4)/4 --Divide's the line by 5 for the categorie's

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
                if size[1] == 1 then
                    explorer.setCursorPos(categorys*i+3-categorys, 2)
                    explorer.write(string.sub("size(B)", 1, categorys-2))
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
                    explorer.write((fs.getSize(string.gsub(path, "\\", "/") .. items[i+scroll-1][2])/size[1]))
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
        explorer.setCursorPos(categorys*4-#tostring(fs.getFreeSpace("hdd")/size[1])-3, 4)
        explorer.write(fs.getFreeSpace("hdd")/size[1] .. " avail") --available memory of the system
        explorer.setCursorPos(categorys*4-#tostring(2100000/size[1])-3, 5)
        explorer.write(2500000/size[1] .. " total") --Total memory of the system
        explorer.setCursorPos(categorys*4-4, 6)
        explorer.write("- used") --Placeholder for the used memory

        explorer.setCursorPos(categorys*4-6, 8)
        explorer.write("Direktory") --Next column
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
        
    end

    sleep()
end 

--Setup
updateList()
cursorPos = 1
items[cursorPos][3] = "+"
drawList("complete")

--Main
parallel.waitForAny( input, drawToolbar, drawInfobar )
