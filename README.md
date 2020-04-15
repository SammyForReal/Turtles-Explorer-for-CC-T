# Turtles Explorer
This will be an explorer for Computercraft. Turtles Explorer is based on the old Explorers for the [MS-DOS](https://de.wikipedia.org/wiki/MS-DOS)  
and should be easily extendable and customizable.

About
-----
**Turtles Explorer** should make it easier for you to handle files.
when its finished, it should contain **many features** and be able to compete with the explorers of the **MS-DOS** times.

Features
--------
Currently you can only go to folders and start/edit files.
You also have some information about the hard disk and the system, which is listed on the right.
But it will get many patches.
![Alt Text](/example.png "Screenshot of Turtles Explorer")

Download
--------
> 👉Note: the explorer is only for [CC:T](https://github.com/SquidDev-CC/CC-Tweaked)

If you're playing on a singleplayer world, you can easaly download the **.lua** 
file and paste it in the folder `%appdata%\.minecraft\saves\<world>\computercraft\computer\<id>\explorer.lua`  
but if you doesn't have access to this folder, then enter this in **the Interactive Lua promp**  
to download it directly on your CraftOS:

```domain = "raw.github.com/1Turtle/Turtles-Explorer-for-CC-T/NotReady/explorer-<VERSION>.lua"
content = http.get( <Github RAW link> ).readAll()
f = fs.open("<name>.lua", "w")
f.write(content)
f.close()```
