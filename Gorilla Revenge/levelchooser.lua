module(..., package.seeall)

--***********************************************************************************************--
--***********************************************************************************************--

-- levelchooser.lua

--***********************************************************************************************--
--***********************************************************************************************--

-- Main function - MUST return a display.newGroup()
function new()
	local menuGroup = display.newGroup()
	local buttonsGroup = display.newGroup()
	
	local ui = require("ui")
	local http = require("socket.http")
	local json = require("json")
	local store = require("store")
		
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
	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------
		
		
	--SOUNDS
	local clickSound = audio.loadSound("sounds/clicksound.caf")	
		
	--GLOBALS
	local changingLevel = false
	local musicOn = false
	local soundsOn = false
	local rightArrowBtn
	local leftArrowBtn
	local transitioning = false
	local levelButton = {}
	local starRating = {}
	local fullVersion = loadValue("full-version-purchased") == "yes"
	
	--TEMPTEMPTEMPTMEP TODO
	if not onDevice then
		fullVersion = true
	end
	
	local drawScreen = function()
	
		-- BACKGROUND IMAGE COMPILATION
		local background = display.newImageRect("images/levelchooserbackground.png",480,320)
		background.x = 240; background.y = 160;
		menuGroup:insert(background)
		-----------------------------------
		
		
		--MUSIC SETTINGS
		 musicOn = loadValue("music.data")
		 soundsOn = loadValue("sounds.data")
		
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
		
		local onLevelButtonTouch = function( event )
			if event.phase == "release" then
				if soundsOn == "yes" then audio.play(clickSound); end
				if tonumber(event.id) ~= 1 and loadValue("level" .. event.id-1 .. "rating.data") == "0" then
					native.showAlert("Level is locked.","Complete previous levels to have this level unlocked.",{"Ok"})
				else
					print()
					print("changing level to loadlevel" .. event.id .. ".lua")
					print()
					saveValue("current-level.data", event.id)
					director:changeScene("loadlevel")
				end
			end
		end
		
		--IF THE FULL VERSION IS PAID FOR
		if fullVersion then
			-- USER LEVELS BUTTON --
			local userLevelsBtn
			local onUserLevelsTouch = function( event )
				if event.phase == "release" then
					if soundsOn == "yes" then audio.play(clickSound); end
					if loadValue("username.data") == "0" then
						director:changeScene("getusername")
					else
						director:changeScene("userlevelsmenu")
					end
				end
			end
			userLevelsBtn = ui.newButton{
				defaultSrc = "images/userlevel-button.png",
				defaultX = 150,
				defaultY = 120,
				overSrc = "images/userlevel-button-pressed.png",
				overX = 150,
				overY = 120,
				onEvent = onUserLevelsTouch,
				id = "userlevelsbutton",
				text = "",
				font = "Helvetica",
				textColor = { 255, 255, 255, 255 },
				size = 16,
				emboss = false
			}
			userLevelsBtn.x = 120; userLevelsBtn.y = 160;
			buttonsGroup:insert( userLevelsBtn )
			-- END USER LEVELS BUTTON --
			
			--EXTENDED LEVEL BUTTONS
			for i=11, 20 do
				levelButton[i] = ui.newButton{
					defaultSrc = "images/button.png",
					defaultX = 45,
					defaultY = 45,
					overSrc = "images/button-pressed.png",
					overX = 45,
					overY = 45,
					onEvent = onLevelButtonTouch,
					id = "" .. i,
					text = "" .. i,
					font = "Helvetica",
					textColor = { 60, 60, 60, 255 },
					size = 16,
					emboss = true
				}

				if i == 11 then
					levelButton[i].x = 90+960; levelButton[i].y = 110;
				elseif i > 11 and i < 16 then
					levelButton[i].x = levelButton[i-1].x + 75; levelButton[i].y = levelButton[11].y;
				elseif i >= 16 then
					levelButton[i].x = levelButton[i-5].x; levelButton[i].y = levelButton[11].y + 90;
				end
				
				if loadValue("level" .. i-1 .. "rating.data") == "0" then
					levelButton[i].alpha = .5
				end


				local levelRating = loadValue("level" .. i .. "rating.data")

				if levelRating == "3" then
					starRating[i] = display.newImageRect("images/threestars.png", 38, 12)
				elseif levelRating == "2" then
					starRating[i] = display.newImageRect("images/twostars.png", 38, 12)
				elseif levelRating == "1" then
					starRating[i] = display.newImageRect("images/onestar.png", 38, 12)
				else
					starRating[i] = display.newImageRect("images/threestars.png", 38, 12)
					starRating[i].alpha = 0
				end

				starRating[i].x = levelButton[i].x; starRating[i].y = levelButton[i].y+30;
				buttonsGroup:insert(starRating[i])

				buttonsGroup:insert(levelButton[i])
			end
		else
			-- FULLVERSION BUTTON --
			local fullVersionBtn
			local onFullVersionTouch = function( event )
				if event.phase == "release" then
					if soundsOn == "yes" then audio.play(clickSound); end
					
					local function alertListener(event)
						if event.action == "clicked" then
							if soundsOn == "yes" then audio.play(clickSound); end
							if event.index == 2 then
								store.purchase({"com.chaluxeapps.gorillarevenge.grfull"})
							end
						end
					end
					native.showAlert("Full Version", "Purchase the full version?", {"Cancel", "Purchase"}, alertListener)
					
					
				end
			end
			fullVersionBtn = ui.newButton{
				defaultSrc = "images/fullversion1-button.png",
				defaultX = 150,
				defaultY = 120,
				overSrc = "images/fullversion1-button-pressed.png",
				overX = 150,
				overY = 120,
				onEvent = onFullVersionTouch,
				id = "fullversionbutton",
				text = "",
				font = "Helvetica",
				textColor = { 255, 255, 255, 255 },
				size = 16,
				emboss = false
			}
			fullVersionBtn.x = 120; fullVersionBtn.y = 160;
			buttonsGroup:insert( fullVersionBtn )
			-- END FULLVERSION BUTTON --
			
			-- FULLVERSION2 BUTTON --
			local fullVersionBtn2
			fullVersionBtn2 = ui.newButton{
				defaultSrc = "images/fullversion1-button.png",
				defaultX = 150,
				defaultY = 120,
				overSrc = "images/fullversion1-button-pressed.png",
				overX = 150,
				overY = 120,
				onEvent = onFullVersionTouch,
				id = "fullversionbutton2",
				text = "",
				font = "Helvetica",
				textColor = { 255, 255, 255, 255 },
				size = 16,
				emboss = false
			}
			fullVersionBtn2.x = 240+960; fullVersionBtn2.y = 160;
			buttonsGroup:insert( fullVersionBtn2 )
			-- END FULLVERSION2 BUTTON --
		end
		
		-- STORYMODE BUTTON --
		local storyBtn
		local onStoryTouch = function( event )
			if event.phase == "release" then
				if transitioning == false then
					if soundsOn == "yes" then audio.play(clickSound); end
					transition.to(buttonsGroup, {time = 750, x = buttonsGroup.x - 480})
					transition.to(rightArrowBtn, {time = 750, x = rightArrowBtn.x - 480})
					transition.to(leftArrowBtn, {time = 750, x = leftArrowBtn.x - 480})
				end
			end
		end
		storyBtn = ui.newButton{
			defaultSrc = "images/story-button.png",
			defaultX = 150,
			defaultY = 120,
			overSrc = "images/story-button-pressed.png",
			overX = 150,
			overY = 120,
			onEvent = onStoryTouch,
			id = "storybutton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		storyBtn.x = 360; storyBtn.y = 160;
		buttonsGroup:insert( storyBtn )
		-- END STORYMODE BUTTON --
		
		--LEVEL BUTTONS
		for i=1, 10 do
			levelButton[i] = ui.newButton{
				defaultSrc = "images/button.png",
				defaultX = 45,
				defaultY = 45,
				overSrc = "images/button-pressed.png",
				overX = 45,
				overY = 45,
				onEvent = onLevelButtonTouch,
				id = "" .. i,
				text = "" .. i,
				font = "Helvetica",
				textColor = { 60, 60, 60, 255 },
				size = 16,
				emboss = true
			}
			
			if i == 1 then
				levelButton[i].x = 90+480; levelButton[i].y = 110;
			elseif i > 1 and i < 6 then
				levelButton[i].x = levelButton[i-1].x + 75; levelButton[i].y = levelButton[1].y;
			elseif i >= 6 then
				levelButton[i].x = levelButton[i-5].x; levelButton[i].y = levelButton[1].y + 90;
			end
						
			if i ~= 1 and loadValue("level" .. i-1 .. "rating.data") == "0" then
				levelButton[i].alpha = .5
			end
			
			
			local levelRating = loadValue("level" .. i .. "rating.data")
			
			if levelRating == "3" then
				starRating[i] = display.newImageRect("images/threestars.png", 38, 12)
			elseif levelRating == "2" then
				starRating[i] = display.newImageRect("images/twostars.png", 38, 12)
			elseif levelRating == "1" then
				starRating[i] = display.newImageRect("images/onestar.png", 38, 12)
			else
				starRating[i] = display.newImageRect("images/threestars.png", 38, 12)
				starRating[i].alpha = 0
			end
			
			starRating[i].x = levelButton[i].x; starRating[i].y = levelButton[i].y+30;
			buttonsGroup:insert(starRating[i])
									
			buttonsGroup:insert(levelButton[i])
		end
		
		-- RIGHT ARROW BUTTON --
		local onArrowTouch = function( event )
			if event.phase == "release" then	
				if soundsOn == "yes" then audio.play(clickSound); end			
				if event.id == "rightarrow" and buttonsGroup.x > -960 and transitioning == false then
					transitioning = true
					transition.to(buttonsGroup, {time = 750, x = buttonsGroup.x - 480, onComplete = function() transitioning = false; end})
				
				elseif event.id == "leftarrow" and buttonsGroup.x < 0 and transitioning == false then
					transitioning = true
					transition.to(buttonsGroup, {time = 750, x = buttonsGroup.x + 480, onComplete = function() transitioning = false; end})
					if buttonsGroup.x == -480 then
						transition.to(rightArrowBtn, {time = 750, x = rightArrowBtn.x + 480})
						transition.to(leftArrowBtn, {time = 750, x = leftArrowBtn.x + 480})
					end
				end
			end
		end
		rightArrowBtn = ui.newButton{
			defaultSrc = "images/rightarrow.png",
			defaultX = 55,
			defaultY = 51,
			overSrc = "images/rightarrow-pressed.png",
			overX = 55,
			overY = 51,
			onEvent = onArrowTouch,
			id = "rightarrow",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		rightArrowBtn.x = 270+480; rightArrowBtn.y = 285;
		menuGroup:insert( rightArrowBtn )
		-- END ABOUT BUTTON --
		leftArrowBtn = ui.newButton{
			defaultSrc = "images/leftarrow.png",
			defaultX = 55,
			defaultY = 51,
			overSrc = "images/leftarrow-pressed.png",
			overX = 55,
			overY = 51,
			onEvent = onArrowTouch,
			id = "leftarrow",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		leftArrowBtn.x = 210+480; leftArrowBtn.y = 285;
		menuGroup:insert( leftArrowBtn )
		-- END LEFT ARROW BUTTON
	
	end
	
	drawScreen()
	
	--IN APP PURCHASES STUFF----------------------------------------------------------------------------------------------------
	
	local function storeCallback(event)
		local transaction = event.transaction
		
		print();print("Transaction Callback Initiated.");print();
		
		local function myAlertListener(event)
			if event.action == "clicked" then
				if soundsOn == "yes" then audio.play(clickSound); end
				director:changeScene("mainmenu")
			end
		end
		
		if transaction.state == "purchased" then
			print("Transaction Successful!")
			saveValue("full-version-purchased", "yes")
			native.showAlert("Success!", "Full Version Purchased Successfully!", {"Ok"},myAlertListener)
		elseif transaction.state == "restored" then
			print("Transaction Restored.")
			saveValue("full-version-purchased", "yes")
			native.showAlert("Success!", "Full Version has been restored.", {"Ok"},myAlertListener)
		elseif transaction.state == "cancelled" then
			print("Transaction Cancelled by user.")
		elseif transaction.state == "failed" then
			print("Transaction Failed!")
		else
			print("??unknown event on transaction callback??")
		end
		
		print()
		
		store.finishTransaction(transaction)
	end
	
	store.init(storeCallback)
	
	--IN APP PURCHASES STUFF------------------------------------------------------------------------------------------------------
	
	-- ************************************************************** --
	--	onSystem() -- listener for system events
	-- ************************************************************** --
	local onSystem = function( event )
		if event.type == "applicationSuspend" then
				--if onDevice then os.exit(); end
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
