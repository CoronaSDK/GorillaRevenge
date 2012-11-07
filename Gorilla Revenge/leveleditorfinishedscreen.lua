module(..., package.seeall)

--***********************************************************************************************--
--***********************************************************************************************--

-- mainmenu

--***********************************************************************************************--
--***********************************************************************************************--

-- Main function - MUST return a display.newGroup()
function new()
	local menuGroup = display.newGroup()
	local buttonsGroup = display.newGroup()
	
	local ui = require("ui")
	
		
	---- Check if running on device or simulator ----
	local onDevice = false
	if system.getInfo( "environment" ) == "device" then
		onDevice = true
	else
		onDevice = false
	end
		
	--***************************************************
	-- saveValue() --> used for saving high score, etc.
	--***************************************************
	local function saveValue( strFilename, strValue )
		-- will save specified value to specified file
		local theFile = strFilename
		local theValue = strValue
		
		local path = system.pathForFile( theFile, system.DocumentsDirectory )
		
		-- io.open opens a file at path. returns nil if no file found
		local file = io.open( path, "w+" )
		if file then
		   -- write game score to the text file
		   file:write( theValue )
		   io.close( file )
		end
	end
	
	--***************************************************
	-- loadValue() --> load saved value from file (returns loaded value as string)
	--***************************************************
	local function loadValue( strFilename )
		-- will load specified file, or create new file if it doesn't exist
		
		local theFile = strFilename
		
		local path = system.pathForFile( theFile, system.DocumentsDirectory )
		
		-- io.open opens a file at path. returns nil if no file found
		local file = io.open( path, "r" )
		if file then
		   -- read all contents of file into a string
		   local contents = file:read( "*a" )
		   io.close( file )
		   return contents
		else
		   -- create file b/c it doesn't exist yet
		   file = io.open( path, "w" )
		   file:write( "0" )
		   io.close( file )
		   return "0"
		end
	end
	--------------------	--------------------	--------------------	--------------------
		--------------------	--------------------	--------------------	--------------------
	
	--MUSIC SETTINGS
	local musicOn = loadValue("music.data")
	local soundsOn = loadValue("sounds.data")
	
	local clickSound = audio.loadSound("sounds/clicksound.caf")
	
	local drawScreen = function()
			
		-- BACKGROUND IMAGE COMPILATION
		local background = display.newImageRect("images/nextLevelScreen.png",480,320)
		background.x = 240; background.y = 160;
		menuGroup:insert(background)
		-----------------------------------
		
		--last level stuff		
		local lastTime = loadValue("lastLevelTime.data")
		local lastLevel = loadValue("lastLevel.data")
		local rating = loadValue("level" .. lastLevel .. "rating.data")
		
		-- MENU BUTTON --
		local menuBtn
		local onMenuTouch = function( event )
			if event.phase == "release" then
				if soundsOn == "yes" then audio.play(clickSound); end
				director:changeScene("mainmenu")
			end
		end
		menuBtn = ui.newButton{
			defaultSrc = "images/menu-button.png",
			defaultX = 80,
			defaultY = 44,
			overSrc = "images/menu-button-pressed.png",
			overX = 80,
			overY = 44,
			onEvent = onMenuTouch,
			id = "menubutton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		menuBtn.x = 50; menuBtn.y = 30;
		menuGroup:insert( menuBtn )
		-- END MENU BUTTON --
		
		local transitioning = false
		
		--REPEAT BUTTON --
		local repeatBtn
		local onRepeatOrEditorTouch = function( event )
			if event.phase == "release" then	
				if soundsOn == "yes" then audio.play(clickSound); end			
				if event.id == "repeatbutton" then
					director:changeScene("loadleveleditorlevel")
				elseif event.id == "editorbutton" then
					saveValue("new-or-load.data", "load")
					saveValue("level-to-load.data", loadValue("templevel.data"))
					director:changeScene("loadleveleditor")
				end
			end
		end
		repeatBtn = ui.newButton{
			defaultSrc = "images/repeat-button.png",
			defaultX = 100,
			defaultY = 40,
			overSrc = "images/repeat-button-pressed.png",
			overX = 100,
			overY = 40,
			onEvent = onRepeatOrEditorTouch,
			id = "repeatbutton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		repeatBtn.x = 189; repeatBtn.y = 210;
		buttonsGroup:insert( repeatBtn )
		-- END REPEAT BUTTON
		--EDITOR BUTTON
		local editorBtn = ui.newButton{
			defaultSrc = "images/editor-button-nice.png",
			defaultX = 100,
			defaultY = 40,
			overSrc = "images/editor-button-nice-pressed.png",
			overX = 100,
			overY = 40,
			onEvent = onRepeatOrEditorTouch,
			id = "editorbutton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		editorBtn.x = 290; editorBtn.y = 210;
		buttonsGroup:insert( editorBtn )
		-- END EDITOR BUTTON
		
		lastTime = lastTime*100
		local timerText = string.format("%02d:%02d", (lastTime/100), lastTime%100)
		local timeText = display.newText("Your Time: " .. timerText, 180,90,system.nativeFontBold,30)
		timeText:setReferencePoint(display.CenterCenterReferencePoint)
		timeText.x = 240; timeText.y = 130
		buttonsGroup:insert(timeText)
		
		
		
		
	
	end
	
	drawScreen()
	
	-- ************************************************************** --
	--	onSystem() -- listener for system events
	-- ************************************************************** --
	local onSystem = function( event )
		if event.type == "applicationSuspend" then
				if onDevice then os.exit(); end
		elseif event.type == "applicationExit" then
				if onDevice then os.exit(); end
		end
	end
	
	Runtime:addEventListener("system", onSystem)
	------------------------------------------------------------------
	------------------------------------------------------------------
	
	--THIS IS CALLED WHEN THE DIRECTOR CHANGES SCENE
	unloadMe = function()
		
		-- STOP PHYSICS ENGINE
		--physics.stop()
		
		--REMOVE everything in other groups
		for i = buttonsGroup.numChildren,1,-1 do
			local child = buttonsGroup[i]
			child.parent:remove( child )
			child = nil
		end
		
		-- REMOVE EVENT LISTENERS
		Runtime:removeEventListener("system", onSystem)
	end
	
	-- MUST return a display.newGroup()
	return menuGroup
end
