# Turtles Explorer
This will be a explorer for ComputerCraft. Turtles Explorer is inspired by the old  [MS-DOS](https://en.wikipedia.org/wiki/MS-DOS) Explorer and should be easily expandable and adaptable.

About
-----
The **Turtles Explorer** is intended to make it easier for users to handle files.   
When completed, it should contain **many features** and be able to compete with the explorers of the **MS-DOS** era.

Features
--------
Currently you can only open folders and execute/edit files.  
You also have some information about the hard disk and the system, which are listed on the right side.  
despite that it has few features so far, there will be many patches and therefore new features.
![Alt Text](/screenshot.png "Screenshot of Turtles Explorer")

Download
--------
> 👉Note: the explorer is only for [CC:T](https://github.com/SquidDev-CC/CC-Tweaked) and is not tested on other versions of ComputerCraft

to download the Explorer directly to your ComputerCraft computer, type this in **the interactive Lua prompt**:

```
domain = "https://raw.githubusercontent.com/1Turtle/Turtles-Explorer-for-CC-T/NotReady/explorer.lua"
content = http.get(domain).readAll()
f = fs.open("explorer.lua", "w")
f.write(content)
f.close()
```
