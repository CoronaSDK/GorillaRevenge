--Chaluxe Apps Games
	--Ryne Chaloux - Programmer
	--Ryne Chaloux - Graphic Design
	--Ryne Chaloux - Level Design
	--Ryne Chaloux - Everything Else

-- MAIN.LUA

-- SOME INITIAL SETTINGS
display.setStatusBar( display.HiddenStatusBar ) --Hide status bar from the beginning

-- Import director class
local director = require("director")

-- Create a main group
local mainGroup = display.newGroup()

-- Main function
local function main()
	
	-- Add the group from director class
	mainGroup:insert(director.directorView)
	
	director:changeScene( "mainmenu" )
	
	return true
end

-- Begin
main()