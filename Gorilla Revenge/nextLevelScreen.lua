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
	local store = require("store")
			
	---- Check if running on device or simulator ----
	local onDevice = false
	if system.getInfo( "environment" ) == "device" then
		onDevice = true
	else
		onDevice = false
	end
	
	--GLOBAL VARIABLES
	local changingLevel = false
	local musicOn = false
	local soundsOn = false
	
	
	local clickSound = audio.loadSound("sounds/clicksound.caf")
	
	
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
		
	local fullVersion = loadValue("full-version-purchased") == "yes"
	
	--TEMPTEMPTEMPTMEP TODO
	if not onDevice then
		fullVersion = true
	end
	
	local drawScreen = function()
	
		-- BACKGROUND IMAGE COMPILATION
		local background = display.newImageRect("images/nextLevelScreen.png",480,320)
		background.x = 240; background.y = 160;
		menuGroup:insert(background)
		-----------------------------------
		
		--MUSIC SETTINGS
		 musicOn = loadValue("music.data")
		 soundsOn = loadValue("sounds.data")
		
		--last level stuff		
		local lastTime = loadValue("lastLevelTime.data")
		local lastLevel = loadValue("lastLevel.data")
		local rating = loadValue("level" .. lastLevel .. "rating.data")
		local tempRating = loadValue("temprating.data")
		
		--BIG STARS TEMP RATING
		local bigStars
		
		if tempRating == "3" then
			bigStars = display.newImageRect("images/3stars.png", 162, 51)
			if rating < tempRating then
				saveValue("level" .. lastLevel .. "rating.data", tempRating)
			end
		elseif tempRating == "2" then
			bigStars = display.newImageRect("images/2stars.png", 106, 51)
			if rating < tempRating then
				saveValue("level" .. lastLevel .. "rating.data", tempRating)
			end
		else
			bigStars = display.newImageRect("images/1star.png", 50, 51)
			if rating < tempRating then
				saveValue("level" .. lastLevel .. "rating.data", tempRating)
			end
		end
		
		bigStars.x = 240; bigStars.y = 160;
		buttonsGroup:insert(bigStars)
		--
		
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
		
		local levelButton = {}
		local starRating = {}
		
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
		
		if fullVersion then
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
			fullVersionBtn.x = 240+960; fullVersionBtn.y = 160;
			buttonsGroup:insert( fullVersionBtn )
			-- END FULLVERSION BUTTON --
		end
		
		local transitioning = false
		
		-- RIGHT ARROW BUTTON --
		local rightArrowBtn
		local onArrowTouch = function( event )
			if event.phase == "release" then	
				if soundsOn == "yes" then audio.play(clickSound); end			
				if event.id == "rightarrow" and buttonsGroup.x > -960 and transitioning == false then
					transitioning = true
					transition.to(buttonsGroup, {time = 1000, x = buttonsGroup.x - 480, onComplete = function() transitioning = false; end})
				elseif event.id == "leftarrow" and buttonsGroup.x < 0 and transitioning == false then
					transitioning = true
					transition.to(buttonsGroup, {time = 1000, x = buttonsGroup.x + 480, onComplete = function() transitioning = false; end})
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
		rightArrowBtn.x = 270; rightArrowBtn.y = 285;
		menuGroup:insert( rightArrowBtn )
		-- END RIGHTARROW BUTTON --
		-- LEFT ARROW BUTTON --
		local leftArrowBtn = ui.newButton{
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
		leftArrowBtn.x = 210; leftArrowBtn.y = 285;
		menuGroup:insert( leftArrowBtn )
		-- END LEFT ARROW BUTTON
		
		--REPEAT BUTTON --
		local repeatBtn
		local onRepeatOrNextTouch = function( event )
			if event.phase == "release" then
				if soundsOn == "yes" then audio.play(clickSound); end				
				if event.id == "repeatbutton" then
					saveValue("current-level.data", lastLevel)
					director:changeScene("loadlevel")
				elseif event.id == "nextbutton" then					
					local nextLevel = tonumber(lastLevel)+1
					saveValue("current-level.data", nextLevel)
					director:changeScene("loadlevel")
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
			onEvent = onRepeatOrNextTouch,
			id = "repeatbutton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		repeatBtn.x = 189; repeatBtn.y = 220;
		buttonsGroup:insert( repeatBtn )
		-- END REPEAT BUTTON
		--NEXT BUTTON
		local nextBtn
		if fullVersion and tonumber(lastLevel) == 20 then
			native.showAlert("Congrats!", "You have successfully completed all the levels currently available. More levels are due out soon so be on the lookout! Also, new levels are being added to the user created levels interface every day.", {"Ok"})
		elseif not fullVersion and tonumber(lastLevel) == 10 then
			local function alertListener99(event99)
				if event99.action == "clicked" then
					if soundsOn == "yes" then audio.play(clickSound); end
					if event99.index == 2 then
						store.purchase({"com.chaluxeapps.gorillarevenge.grfull"})
					end
				end
			end
			native.showAlert("Congrats!", "You have successfully completed all the levels in the free version. Would you like to purchase the full version and gain access to more levels as well as an unlimited number of levels in the user created levels interface?", {"Cancel", "Purchase"}, alertListener99)
		else
			nextBtn = ui.newButton{
				defaultSrc = "images/next-button.png",
				defaultX = 100,
				defaultY = 40,
				overSrc = "images/next-button-pressed.png",
				overX = 100,
				overY = 40,
				onEvent = onRepeatOrNextTouch,
				id = "nextbutton",
				text = "",
				font = "Helvetica",
				textColor = { 255, 255, 255, 255 },
				size = 16,
				emboss = false
			}
			nextBtn.x = 290; nextBtn.y = 220;
			buttonsGroup:insert( nextBtn )
			-- END NEXT BUTTON
		end
		
		
		lastTime = lastTime*100
		local timerText = string.format("%02d:%02d", (lastTime/100), lastTime%100)
		local timeText = display.newText("Your Time: " .. timerText, 180,90,system.nativeFontBold,30)
		timeText:setReferencePoint(display.CenterCenterReferencePoint)
		timeText.x = 240; timeText.y = 100
		buttonsGroup:insert(timeText)
		
		
		
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
	local function onSystem( event )
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
