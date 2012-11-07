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
	
	--**************************************************
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
	----------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------
	
	--MUSIC SETTINGS
	local changingLevel = false
	local musicOn = false
	local soundsOn = false
	musicOn = loadValue("music.data")
	soundsOn = loadValue("sounds.data")	
	
	local clickSound = audio.loadSound("sounds/clicksound.caf")
	
	--GLOBALS
	local lastTime = loadValue("lastLevelTime.data")
	local lastLevel = loadValue("lastLevel.data")
	local sqlID = loadValue("loaded-level-sql-id.data")
	local username = loadValue("username.data")
	local rating
	local downArrowBtn
	local upArrowBtn
	local rateText
	
	local drawScreen = function()
			
		-- BACKGROUND IMAGE COMPILATION
		local background = display.newImageRect("images/nextLevelScreen.png",480,320)
		background.x = 240; background.y = 160;
		menuGroup:insert(background)
		-----------------------------------
		
		-- MENU BUTTON --
		local menuBtn
		local onMenuTouch = function( event )
			if event.phase == "release" then
				if soundsOn == "yes" then audio.play(clickSound); end
				director:changeScene("userlevelsmenu")
			end
		end
		menuBtn = ui.newButton{
			defaultSrc = "images/back-button.png",
			defaultX = 80,
			defaultY = 44,
			overSrc = "images/back-button-pressed.png",
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
		
		-- UP ARROW BUTTON --
		local onArrowTouch = function( event )
			if event.phase == "release" then
				if soundsOn == "yes" then audio.play(clickSound); end				
				transition.to(upArrowBtn,{time = 500, y = 350})
				transition.to(downArrowBtn,{time = 500, y = 350})
				transition.to(rateText,{time = 500, y = 350})
				--
				if event.id == "uparrow" then
					--
					local postData = "vote_up=yes&level_id=" .. sqlID
					local params = {}
					params.body = postData
					network.request( "http://chaluxeapps.com/apps/gorilla_revenge/vote_for_level.php", "POST", params )
					local postData2 = "username=" .. username .. "&level_id=" .. sqlID
					local params2 = {}
					params2.body = postData2
					network.request( "http://chaluxeapps.com/apps/gorilla_revenge/add_voter.php", "POST", params2 )
					--
				elseif event.id == "downarrow" then
					--
					local postData = "vote_up=no&level_id=" .. sqlID
					local params = {}
					params.body = postData
					network.request( "http://chaluxeapps.com/apps/gorilla_revenge/vote_for_level.php", "POST", params )
					local postData2 = "username=" .. username .. "&level_id=" .. sqlID
					local params2 = {}
					params2.body = postData2
					network.request( "http://chaluxeapps.com/apps/gorilla_revenge/add_voter.php", "POST", params2 )
					--
				end
				--
			end
		end
		upArrowBtn = ui.newButton{
			defaultSrc = "images/rightarrow.png",
			defaultX = 55,
			defaultY = 51,
			overSrc = "images/rightarrow-pressed.png",
			overX = 55,
			overY = 51,
			onEvent = onArrowTouch,
			id = "uparrow",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		upArrowBtn.x = 140; upArrowBtn.y = 350;
		upArrowBtn:rotate(-90)
		menuGroup:insert( upArrowBtn )
		-- END UP ARROW BUTTON --
		-- DOWN ARROW BUTTON --
		downArrowBtn = ui.newButton{
			defaultSrc = "images/leftarrow.png",
			defaultX = 55,
			defaultY = 51,
			overSrc = "images/leftarrow-pressed.png",
			overX = 55,
			overY = 51,
			onEvent = onArrowTouch,
			id = "downarrow",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		downArrowBtn.x = 340; downArrowBtn.y = 350;
		downArrowBtn:rotate(-90)
		menuGroup:insert( downArrowBtn )
		-- END DOWN ARROW BUTTON
		rateText = display.newText("Rate This Level", 0,0,"helvetica",20)
		rateText.x = 240; rateText.y = 350;
		menuGroup:insert(rateText)
		
		------------------------------------------------------------------------
		
		local function networkListener( event )
		    if ( event.isError ) then
	            print( "Network error!")
	        else
	            print ( "RESPONSE: " .. event.response )
				if event.response == "ok to vote" then
					transition.to(upArrowBtn,{time = 500, y = 285})
					transition.to(downArrowBtn,{time = 500, y = 285})
					transition.to(rateText,{time = 500, y = 285})
				end
	        end
		end
		
		local postData = "username=" .. username .. "&level_id=" .. sqlID
		local params = {}
		params.body = postData

		print()
		print("Posting: " .. postData)
		print()

		network.request( "http://chaluxeapps.com/apps/gorilla_revenge/has_user_voted.php", "POST", networkListener, params )
		
		------------------------------------------------------------------------
		
		--REPEAT BUTTON --
		local repeatBtn
		local onRepeatOrNextTouch = function( event )
			if event.phase == "release" then	
				if soundsOn == "yes" then audio.play(clickSound); end			
				director:changeScene("loaduserlevelslevel")
			end
		end
		repeatBtn = ui.newButton{
			defaultSrc = "images/repeat-large.png",
			defaultX = 200,
			defaultY = 40,
			overSrc = "images/repeat-large-pressed.png",
			overX = 200,
			overY = 40,
			onEvent = onRepeatOrNextTouch,
			id = "repeatbutton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		repeatBtn.x = 240; repeatBtn.y = 180;
		buttonsGroup:insert( repeatBtn )
		-- END REPEAT BUTTON
		
		lastTime = lastTime*100
		local timerText = string.format("%02d:%02d", (lastTime/100), lastTime%100)
		local timeText = display.newText("Your Time: " .. timerText, 180,90,system.nativeFontBold,30)
		timeText:setReferencePoint(display.CenterCenterReferencePoint)
		timeText.x = 240; timeText.y = 120
		buttonsGroup:insert(timeText)
		
		local bigStars
		
		if rating == "3" then
			bigStars = display.newImageRect("images/3stars.png", 162, 51)
		elseif rating == "2" then
			bigStars = display.newImageRect("images/2stars.png", 106, 51)
		else
			bigStars = display.newImageRect("images/1star.png", 50, 51)
		end
		
		bigStars.x = 240; bigStars.y = 160;
		--change this someday to show the stars
		bigStars.isVisible = false
		buttonsGroup:insert(bigStars)
		
		
	
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
