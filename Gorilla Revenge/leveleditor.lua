module(..., package.seeall)


-- Main function - MUST return a display.newGroup()
function new()	
	local gameGroup = display.newGroup()
	local settingsGroup = display.newGroup()
	local hudGroup = display.newGroup()
	local inventoryGroup = display.newGroup()
	
	-- EXTERNAL MODULES / LIBRARIES
	local movieclip = require "movieclip"
	local physics = require "physics"
	local ui = require "ui"
	local facebook = require "facebook"
	local json = require "json"
	local ads = require("ads")
	-- activate multitouch
	system.activate( "multitouch" )
	
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
	-------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------
		
	--MUSIC SETTINGS
	local musicOn = loadValue("music.data")
	local soundsOn = loadValue("sounds.data")
	
	--SOUNDS
	local clickSound = audio.loadSound("sounds/clicksound.caf")
	local backgroundMusic = audio.loadStream("sounds/hiphop.mp3")
	
	if musicOn == "yes" then
		audio.stop()
		audio.play(backgroundMusic, {loops = -1})
		audio.setVolume(.4)
	end
	
	--LOADED VALUES
	local loadedLevelName = loadValue("loaded-level-name.data")
	local savedLevelsTable = json.decode(loadValue("saved-levels-table.data"))
	local backgroundSize = loadValue("levelsize.data")
	local newOrLoad = loadValue("new-or-load.data")
	local jsonLevel
	local levelTable
	local hasPlayedLevelEditor = loadValue("has-played-level-editor.data")
	
	if newOrLoad == "load" then
		jsonLevel = loadValue("level-to-load.data")
		levelTable = json.decode(jsonLevel)
	end
	
	if hasPlayedLevelEditor ~= "yes" then
		native.showAlert("Level Editor", "Welcome to the level editor! Here you can create your own levels using inventory located by pressing the \"i\" button in the top right. If you need a closer view just simply pinch to zoom in and out. When zoomed in, feel free to pan the screen with your finger. When you're ready, simply tap on the gear in the top left corner to give your level a name and save it or test it out. Have fun!", {" Ok "})
		saveValue("has-played-level-editor.data", "yes")
	end
	
	--flags
	
	--global items
	local gorilla
	local platform = {}
	local largeLadder = {}
	local mediumLadder = {}
	local window = {}
	local whiteGuard = {}
	local blackGuard = {}
	local crate = {}
	local bearTrap = {}
	local fullCage = {}
	local key
	local door
	local lock
	local background
	local settingsBackground
	local gearBtn
	local inventoryBtn
	local platformBtn
	local crateBtn
	local keyBtn
	local doorBtn
	local windowBtn
	local whiteGuardBtn
	local blackGuardBtn
	local largeLadderBtn
	local mediumLadderBtn
	local bearTrapBtn
	local gorillaBtn
	local inventoryBackground
	local selectedRightArrow
	local selectedLeftArrow
	local selectedMove
	local tempObject
	local inventorySelected = false
	local objectSelected = false
	local worldTouchX = 0
	local worldTouchY = 0
	local worldToScreenX
	local worldToScreenY
	local screenToWorldX
	local screenToWorldY
	local leftArrowIsSelected = false
	local rightArrowIsSelected = false
	local moveIsSelected = false
	local exportedLevel = {}
	local keyboardIsUp = false
	local textField
	local okToZoom = true
	local lastX
	local lastY
	local deleteIcon
	local simulatorTextFieldText = "Simulator Level"
	local onObjectTouch
	local simulatorTextFieldTextLabel
	local objectCount = 0
	local objectCountText
	local doorSelected = false
	local fullVersion = loadValue("full-version-purchased") == "yes"
	if not fullVersion then ads.init( "inmobi", "4028cba631d63df1013218ab6552046e"); end
	-- inmobi iOS test ID: 4028cb962895efc50128fc99d4b7025b
	-- Gorilla Revenge ID: 4028cba631d63df1013218ab6552046e
	local lastObjectSelected = 0
	-------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------
	
	------------------------------------------FUNCTIONS----------------------------------------------
	--EXPORT LEVEL DATA JSON
	local function exportLevel()
		print()
		print("Exporting Level..")
		print("--")
		table.insert(exportedLevel, "s#" .. backgroundSize .. "#")
		print("\"s#" .. backgroundSize .. "#\",")
		--ADDING OBJECTS: STEP THREE
		for i=gameGroup.numChildren,1,-1 do
			local object = gameGroup[i]
			--
			if object.myName == "platform" then
				local string = string.format("%s%d%s%d%s%d%s%d%s", "p#",object.x,"#",object.y,"#",object.width,"#",object.height,"#")
				table.insert(exportedLevel, string)
				print("\"" .. string..",")
			--
			elseif object.myName == "crate" then
				local string = string.format("%s%d%s%d%s", "c#",object.x,"#",object.y,"#")
				table.insert(exportedLevel, string)
				print("\"" .. string .. "\",")
			--
			elseif object.myName == "key" and object.inUse then
				local string = string.format("%s%d%s%d%s", "k#",object.x,"#",object.y,"#")
				table.insert(exportedLevel, string)
				print("\"" .. string .. "\",")
			--
			elseif object.myName == "door" then
				local string = string.format("%s%d%s%d%s", "d#",object.x,"#",object.y,"#")
				table.insert(exportedLevel, string)
				print("\"" .. string .. "\",")
			--
			elseif object.myName == "window" then
				local string = string.format("%s%d%s%d%s", "w#",object.x,"#",object.y,"#")
				table.insert(exportedLevel, string)
				print("\"" .. string .. "\",")
			--
			elseif object.myName == "fullcage" then
				local string = string.format("%s%d%s%d%s", "f#",object.x,"#",object.y,"#")
				table.insert(exportedLevel, string)
				print("\"" .. string .. "\",")
			--
			elseif object.myName == "beartrap" then
				local string = string.format("%s%d%s%d%s", "b#",object.x,"#",object.y,"#")
				table.insert(exportedLevel, string)
				print("\"" .. string .. "\",")
			--
			elseif object.myName == "ladder-large" then
				local string = string.format("%s%d%s%d%s", "l#l#",object.x,"#",object.y,"#")
				table.insert(exportedLevel, string)
				print("\"" .. string .. "\",")
			--
			elseif object.myName == "ladder-medium" then
				local string = string.format("%s%d%s%d%s", "l#m#",object.x,"#",object.y,"#")
				table.insert(exportedLevel, string)
				print("\"" .. string .. "\",")
			--
			elseif object.myName == "whiteguard" then
				if object.direction == "right" then
					table.insert(exportedLevel, string.format("%s%d%s%d%s", "wg#",object.x,"#",object.y,"#r#"))
					print(string.format("%s%d%s%d%s", "\"wg#",object.x,"#",object.y,"#r#\","))
				else
					table.insert(exportedLevel, string.format("%s%d%s%d%s", "wg#",object.x,"#",object.y,"#l#"))
					print(string.format("%s%d%s%d%s", "\"wg#",object.x,"#",object.y,"#l#\","))
				end
			--
			elseif object.myName == "blackguard" then
				if object.direction == "right" then
					table.insert(exportedLevel, string.format("%s%d%s%d%s", "bg#",object.x,"#",object.y,"#r#"))
					print(string.format("%s%d%s%d%s", "\"bg#",object.x,"#",object.y,"#r#\","))
				else
					table.insert(exportedLevel, string.format("%s%d%s%d%s", "bg#",object.x,"#",object.y,"#l#"))
					print(string.format("%s%d%s%d%s", "\"bg#",object.x,"#",object.y,"#l#\","))
				end
			--
			elseif object.myName == "gorilla/gorillaright1" then
				local string = string.format("%s%d%s%d%s", "g#",object.x,"#",object.y,"#")
				table.insert(exportedLevel, string)
				print("\"" .. string .. "\",")
			--
			end
			
			object:removeEventListener("touch", onObjectTouch)
			object:removeSelf()
			object = nil
		--
		end
		--
		print("--")
		print("Level Exported Successfully.")
		print()
		saveValue("templevel.data", json.encode(exportedLevel))
		saveValue("there-is-a-most-recent.data", "yes")
		
		return json.encode(exportedLevel)
	end
	
	-- CREATE ITEMS FOR EVERY LEVEL
	local function createItemsForEveryLevel()
		--SETTINGS GROUP
		-----------------------------------------------------------------------------------------------------------------------------------
		settingsBackground = display.newRoundedRect(0,0,400,250,12)
		settingsBackground.x = 240; settingsBackground.y = 160
		settingsBackground:setFillColor(170,170,170)
		settingsGroup:insert(settingsBackground)
		settingsBackground.alpha = .9
		settingsGroup.isVisible = false
		
		local levelNameText = widget.newEmbossedText( "Level Name", 110, 50, "HelveticaNeue-Bold", 22, { 0, 0, 0 } )
		levelNameText:setReferencePoint(display.TopLeftReferencePoint)
		levelNameText.x = 61; levelNameText.y = 60;
		
		-- Handle the textField keyboard input
		--
		local function fieldHandler( event )
			--
			if ( "began" == event.phase ) then
				keyboardIsUp = true

			elseif ( "ended" == event.phase ) then
				-- This event is called when the user stops editing a field: for example, when they touch a different field
				-- Hide keyboard
				native.setKeyboardFocus( nil )
				keyboardIsUp = false
			elseif ( "submitted" == event.phase ) then
				-- This event occurs when the user presses the "return" key (if available) on the onscreen keyboard

				-- Hide keyboard
				native.setKeyboardFocus( nil )
				keyboardIsUp = false
			end
			--
		end
	
		textField = native.newTextField( 15, 80, 280, 30, fieldHandler )
		textField:setReferencePoint(display.TopLeftReferencePoint)
		textField.x = 60; textField.y = 90;
		textField.isVisible = false
		
		if onDevice then
			textField.text = loadedLevelName
		else
			simulatorTextFieldTextLabel = widget.newEmbossedText( simulatorTextFieldText, 110, 50, "HelveticaNeue-Bold", 22, { 0, 0, 0 } )
			simulatorTextFieldTextLabel:setReferencePoint(display.TopLeftReferencePoint)
			simulatorTextFieldTextLabel.x = 61; simulatorTextFieldTextLabel.y = textField.y;
			settingsGroup:insert(simulatorTextFieldTextLabel)
		end
		
		--FAKE TEXT FIELD
		if onDevice == false then
			local fakeTextField = display.newRect(0,0,textField.width, textField.height)
			fakeTextField:setReferencePoint(display.TopLeftReferencePoint)
			fakeTextField.x = textField.x; fakeTextField.y = textField.y;
			settingsGroup:insert(fakeTextField)
			simulatorTextFieldTextLabel:toFront()
		end
		
		local function onDiscardButton (event )
		    if event.phase == "release" and settingsGroup.isVisible then
				if soundsOn == "yes" then audio.play(clickSound); end
			
				--KILL THE AUDIO
				audio.stop()
			
				for i=gameGroup.numChildren,1,-1 do
					gameGroup[i]:removeEventListener("touch", onObjectTouch)
					gameGroup[i]:removeSelf()
					gameGroup[i] = nil
				end
				display.remove(textField)
				director:changeScene("leveleditormenu")
	        end
	    end
		local discardButton = widget.newButton{
	        id = "discardbutton",
	        x = 257,
	        y = 183,
	        label = "Discard",
	        onEvent = onDiscardButton
	    }
		discardButton.x = 340-discardButton.width/2;
		local function onClearButton (event )
		    if event.phase == "release" and settingsGroup.isVisible then
				if soundsOn == "yes" then audio.play(clickSound); end
					for i=gameGroup.numChildren,1,-1 do
						local name = gameGroup[i].myName
						if name ~= "gorilla/gorillaright1" and name ~= "door" and name ~= "background" then
							if name == "key" then
								gameGroup[i].inUse = false
								lock.isVisible = false
								gameGroup[i].x = -100
							else
								gameGroup[i]:removeEventListener("touch", onObjectTouch)
								gameGroup[i]:removeSelf()
								gameGroup[i] = nil
							end
						end 
					end
	        end
	    end
		local clearButton = widget.newButton{
	        id = "clearbutton",
	        x = 110,
	        y = 183,
	        label = "Clear",
	        onEvent = onClearButton
	    }
		clearButton.x = 140-clearButton.width/2;
	
		local line1 = display.newLine(40,170,440,170)
		line1:setColor(100,100,100,100)
		local line2 = display.newLine(40,225,440,225)
		line2:setColor(100,100,100,100)
		local line3 = display.newLine(240,170,240,285)
		line3:setColor(100,100,100,100)
	
		local function onSaveButton (event )
		    if event.phase == "release" and settingsGroup.isVisible then
				local levelId = 0
				if soundsOn == "yes" then audio.play(clickSound); end
				--KILL THE AUDIO
				audio.stop()
				
				local levelNameValid = true
				local textFieldString = textField.text
				local tempString = textField.text
				if onDevice == false then
					textFieldString = simulatorTextFieldText
					tempString = textFieldString
					simulatorTextFieldTextLabel.text = tempString
				end
				tempString = tempString:lower()
				tempString = tempString .. "#"
				
				--special character's check
				local i = 1
				while(tempString:sub(i,i) ~= "#" and levelNameValid)do
					local letter = tempString:sub(i,i)
					if letter ~= "a" and
						letter ~= "b" and
						letter ~= "c" and
						letter ~= "d" and
						letter ~= "e" and
						letter ~= "f" and
						letter ~= "g" and
						letter ~= "h" and
						letter ~= "i" and
						letter ~= "j" and
						letter ~= "k" and
						letter ~= "l" and
						letter ~= "m" and
						letter ~= "n" and
						letter ~= "o" and
						letter ~= "p" and
						letter ~= "q" and
						letter ~= "r" and
						letter ~= "s" and
						letter ~= "t" and
						letter ~= "u" and
						letter ~= "v" and
						letter ~= "w" and
						letter ~= "x" and
						letter ~= "y" and
						letter ~= "z" and
						letter ~= "1" and 
						letter ~= "2" and 
						letter ~= "3" and 
						letter ~= "4" and 
						letter ~= "5" and 
						letter ~= "6" and 
						letter ~= "7" and 
						letter ~= "8" and 
						letter ~= "9" and
						letter ~= " " then
						
						levelNameValid = false
					end
					i = i+1
				end
				
				--profanity check
				if string.find(tempString, "ass") or string.find(tempString, "cunt") or string.find(tempString, "fuck") or 
				   string.find(tempString, "shit") or string.find(tempString, "dick") or string.find(tempString, "fag") or 
				   string.find(tempString, "slut") or string.find(tempString, "bitch") or string.find(tempString, "pussy") then
					levelNameValid = false
				end
				--
				
				if levelNameValid == false then
					native.showAlert( "Invalid Name", "Special Characters are not allowed in level names, please edit your name and try again.", { "OK" })
				else
					--find out if the file already exists
					for i=table.maxn(savedLevelsTable), 1, -1 do
						if textFieldString == loadValue("created-level-" .. i .. "-name.data") then
							levelId = i
						end
					end
					display.remove(textField)
					-- if the level id is greater than zero than the name already exists so we overwrite
					if levelId > 0 then
						print("overwriting level file")
						savedLevelsTable[levelId] = exportLevel()
						saveValue("saved-levels-table.data", json.encode(savedLevelsTable))
						saveValue("created-level-" .. levelId .. "-name.data", textFieldString)
						saveValue("created-level-" .. levelId .. "-date.data", os.date("%c"))
						director:changeScene("leveleditormenu")
					--
					-- else than the levelId is at the default zero and we create a new file for the level
					else
						if fullVersion then
							if table.maxn(savedLevelsTable) <= 19 then
								print("saving on new file")
								table.insert(savedLevelsTable, exportLevel())
								saveValue("saved-levels-table.data", json.encode(savedLevelsTable))
								saveValue("created-level-" .. table.maxn(savedLevelsTable) .. "-name.data", textFieldString)
								saveValue("created-level-" .. table.maxn(savedLevelsTable) .. "-date.data", os.date("%c"))
								director:changeScene("leveleditormenu")
							else
								local function onOkTouch( event )
								        if "clicked" == event.action then
											if soundsOn == "yes" then audio.play(clickSound); end
											exportLevel()
								            director:changeScene("leveleditormenu")
								        end
								end
								local alert = native.showAlert( ": /", "Sorry, you are currently at the max capacity for saved levels. Please delete a level to be able to save this one. Don't worry, this level will be temporarily saved as 'Most Recent'.", { "OK" }, onOkTouch )
							end
						else
							if table.maxn(savedLevelsTable) <= 2 then
								print("saving on new file")
								table.insert(savedLevelsTable, exportLevel())
								saveValue("saved-levels-table.data", json.encode(savedLevelsTable))
								saveValue("created-level-" .. table.maxn(savedLevelsTable) .. "-name.data", textFieldString)
								saveValue("created-level-" .. table.maxn(savedLevelsTable) .. "-date.data", os.date("%c"))
								director:changeScene("leveleditormenu")
							else
								local function onOkTouch( event )
								        if "clicked" == event.action then
											if soundsOn == "yes" then audio.play(clickSound); end
											exportLevel()
								            director:changeScene("leveleditormenu")
								        end
								end
								local alert = native.showAlert( ": /", "Sorry, you are currently at the max capacity for saved levels with the free version. Please upgrade to the full version to be able to save more levels. Don't worry, this level will be temporarily saved as 'Most Recent'.", { "OK" }, onOkTouch )
							end
						end
						
						
					end
				end
	        end
	    end
		local saveButton = widget.newButton{
	        id = "savebutton",
	        x = 115,
	        y = 240,
	        label = "Save and Exit",
	        onEvent = onSaveButton
	    }
		saveButton.x = 140-saveButton.width/2;
	
		local function onTestButton (event )
		    if event.phase == "release" and settingsGroup.isVisible then
				if soundsOn == "yes" then audio.play(clickSound); end
				--kill the audio
				audio.stop()
				--
				saveValue("loaded-level-name.data", textField.text)
				exportLevel()
				display.remove(textField)
				director:changeScene("loadleveleditorlevel")
	        end
	    end
		local testButton = widget.newButton{
	        id = "testbutton",
	        x = 245,
	        y = 240,
	        label = "  Test Level ",
	        onEvent = onTestButton
	    }
		testButton.x = 340-testButton.width/2;
	
		settingsGroup:insert(levelNameText)
		settingsGroup:insert(textField)
		settingsGroup:insert(saveButton.view)		
		settingsGroup:insert(testButton.view)
		settingsGroup:insert(clearButton.view)
		settingsGroup:insert(discardButton.view)
		settingsGroup:insert(line1)
		settingsGroup:insert(line2)	
		settingsGroup:insert(line3)
		
		--ZOOM BUTTON FOR SIMULATOR SIMULATED MULTI-TOUCH
		if onDevice == false then
			local function onZoomTouch (event )
			    if event.phase == "release" then
					if soundsOn == "yes" then audio.play(clickSound); end	
		        end
		    end
			local zoomButton = widget.newButton{
		        id = "zoominbutton",
		        x = 210,
		        y = 45,
		        label = "Zoom",
		        onEvent = onZoomTouch
		    }
			hudGroup:insert(zoomButton.view)
		end	
		
		--OBJECT COUNT LABEL
		if fullVersion then
			objectCountText = display.newText("0/40", 0,0, "helvetica", 18)
			objectCountText:setReferencePoint(display.CenterCenterReferencePoint)
			objectCountText.x = 240; objectCountText.y = 20;
			objectCountText:setTextColor(255,255,255,255)
			hudGroup:insert(objectCountText)
		else
			objectCountText = display.newText("0/40", 0,0, "helvetica", 18)
			objectCountText:setReferencePoint(display.CenterCenterReferencePoint)
			objectCountText.x = 240; objectCountText.y = 60;
			objectCountText:setTextColor(255,255,255,255)
			hudGroup:insert(objectCountText)
		end
		
		-------------------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------------------------------------------------
		
		--GEAR BUTTON --
		local onGearTouch = function( event )
			if event.phase == "release" then
				if soundsOn == "yes" then audio.play(clickSound); end
				if inventoryGroup.isVisible then inventoryGroup.isVisible = false; end
				if settingsGroup.isVisible then
					textField.isVisible = false
					transition.to(settingsGroup,{time = 500, alpha = 0, onComplete = function() settingsGroup.isVisible = false; settingsGroup.alpha = 1; end})
					transition.to(gearBtn, {time = 1000, rotation = gearBtn.rotation-360})
				else
					okToZoom = false
					textField.isVisible = true
					settingsGroup.isVisible = true
					settingsGroup.alpha = 0
					transition.to(settingsGroup,{time = 500, alpha = 1})
					transition.to(gearBtn, {time = 1000, rotation = gearBtn.rotation+360})
				end
				--exportLevel()
				--director:changeScene("loadleveleditorlevel")
			end
		end
		gearBtn = ui.newButton{
			defaultSrc = "images/gear.png",
			defaultX = 40,
			defaultY = 40,
			overSrc = "images/gear.png",
			overX = 40,
			overY = 40,
			onEvent = onGearTouch,
			id = "gearbutton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		gearBtn.x = 30; gearBtn.y = 30;
		hudGroup:insert( gearBtn )
		-- END GEAR BUTTON
		--INVENTORY BUTTON --
		local onInventoryTouch = function( event )
			if event.phase == "release" then
				if soundsOn == "yes" then audio.play(clickSound); end
				if objectCount < 40 then
					if settingsGroup.isVisible then settingsGroup.isVisible = false; textField.isVisible = false; end
					if inventoryGroup.isVisible then
						inventoryGroup.isVisible = false
					else
						inventoryGroup.isVisible = true	
						okToZoom = false
					end
				else
					native.showAlert( "Max Capacity", "You have reached the maximum number of objects allowed. Please delete an object to be able to add more.", { "OK" })
				end
			end
		end
		inventoryBtn = ui.newButton{
			defaultSrc = "images/inventory-button.png",
			defaultX = 40,
			defaultY = 40,
			overSrc = "images/inventory-button-pressed.png",
			overX = 40,
			overY = 40,
			onEvent = onInventoryTouch,
			id = "inventorybutton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		inventoryBtn.x = 450; inventoryBtn.y = 30;
		hudGroup:insert( inventoryBtn )
		-- END INVENTORY BUTTON
		
		deleteIcon = display.newImageRect("images/delete.png", 60,60)
		deleteIcon.x = 510; deleteIcon.y = 350;
		hudGroup:insert(deleteIcon)
		deleteIcon.alpha = .8
		
		inventoryGroup.isVisible = false
	end
	createItemsForEveryLevel()
	
	--TOUCH FUNCTION FOR THE SETTINGS BACKGROUND
	function settingsBackground:touch(event)
		-- Hide keyboard
		native.setKeyboardFocus( nil )
		keyboardIsUp = false
	end
	settingsBackground:addEventListener("touch", settingsBackground)

	--UPDATE OBJECT COUNT TEXT	
	local function updateObjectCountText()
		if objectCount > 40 then objectCount = 40; end
		if objectCount < 0 then objectCount = 0; end
		objectCountText.text = objectCount .. "/40"
		objectCountText:setReferencePoint(display.CenterCenterReferencePoint)
		if fullVersion then
			objectCountText.x = 240; objectCountText.y = 20;
		else
			objectCountText.x = 240; objectCountText.y = 60;
		end
	end

	--CREATE THE HUD GROUP
	local function createHudGroup()
		--LOAD THE CORRECT BACKGROUND
		if newOrLoad == "new" then
			if backgroundSize == "l" then
				background = display.newImageRect("images/levelbackground-large.png",1440,960)
				background.x = 720; background.y = -160;
				gameGroup:insert(background)
				background.myName = "background"
				gameGroup.xScale = 1/3; gameGroup.yScale = 1/3;
				gameGroup.y = 213
				gameGroup.x = 0
			elseif backgroundSize == "m" then
				background = display.newImageRect("images/levelbackground-medium.png",960,640)
				background.x = 480; background.y = 0;
				gameGroup:insert(background)
				background.myName = "background"
				gameGroup.xScale = .5; gameGroup.yScale = .5;
				gameGroup.y = 160
				gameGroup.x = 0
			else
				background = display.newImageRect("images/levelbackground-small.png",480,320)
				background.x = 240; background.y = 160;
				gameGroup:insert(background)
				background.myName = "z"
			end
		end
		
		--INVENTORY BUTTONS --
		local function createInventoryButtons()
			inventoryBackground = display.newRoundedRect(0,0,400,250,12)
			inventoryBackground:setFillColor(50,50,50)
			inventoryBackground.x = 240; inventoryBackground.y = 160;
			inventoryGroup:insert(inventoryBackground)
			--
			platformBtn = display.newImageRect("images/platform-button.png",50,50)
			platformBtn.x = 120; platformBtn.y = 80;
			inventoryGroup:insert( platformBtn )
			--
			crateBtn = display.newImageRect("images/crate-button.png",50,50)
			crateBtn.x = 200; crateBtn.y = 80;
			inventoryGroup:insert( crateBtn )
			--
			bearTrapBtn = display.newImageRect("images/beartrap-button.png",50,50)
			bearTrapBtn.x = 280; bearTrapBtn.y = 80;
			inventoryGroup:insert( bearTrapBtn )
			--
			doorBtn = display.newImageRect("images/door-button.png",50,50)
			doorBtn.x = 360; doorBtn.y = 80;
			inventoryGroup:insert( doorBtn )
			--
			windowBtn = display.newImageRect("images/window-button.png",50,50)
			windowBtn.x = 120; windowBtn.y = 160;
			inventoryGroup:insert( windowBtn )
			--
			mediumLadderBtn = display.newImageRect("images/ladder-medium-button.png",50,50)
			mediumLadderBtn.x = 200; mediumLadderBtn.y = 160;
			inventoryGroup:insert( mediumLadderBtn )
			--
			largeLadderBtn = display.newImageRect("images/ladder-large-button.png",50,50)
			largeLadderBtn.x = 280; largeLadderBtn.y = 160;
			inventoryGroup:insert( largeLadderBtn )
			--
			keyBtn = display.newImageRect("images/key-button.png",50,50)
			keyBtn.x = 360; keyBtn.y = 160;
			inventoryGroup:insert( keyBtn )
			--
			cageBtn = display.newImageRect("images/cage-button.png",50,50)
			cageBtn.x = 120; cageBtn.y = 240;
			inventoryGroup:insert( cageBtn )
			--
			whiteGuardBtn = display.newImageRect("images/whiteguard-button.png",50,50)
			whiteGuardBtn.x = 200; whiteGuardBtn.y = 240;
			inventoryGroup:insert( whiteGuardBtn )
			--
			blackGuardBtn = display.newImageRect("images/blackguard-button.png",50,50)
			blackGuardBtn.x = 280; blackGuardBtn.y = 240;
			inventoryGroup:insert( blackGuardBtn )
			--
			gorillaBtn = display.newImageRect("images/gorilla-button.png",50,50)
			gorillaBtn.x = 360; gorillaBtn.y = 240;
			inventoryGroup:insert( gorillaBtn )
			--
			selectedRightArrow = display.newImageRect("images/selected-rightarrow.png", 30,61)
			selectedRightArrow.x = -20; selectedRightArrow.y = 100;
			hudGroup:insert(selectedRightArrow)
			--
			selectedLeftArrow = display.newImageRect("images/selected-leftarrow.png", 30,61)
			selectedLeftArrow.x = -20; selectedLeftArrow.y = 100;
			hudGroup:insert(selectedLeftArrow)
			--
			selectedMove = display.newImageRect("images/selected-move.png", 31,74)
			selectedMove.x = -20; selectedMove.y = 100;
			hudGroup:insert(selectedMove)
			--
		end
		createInventoryButtons()
		
	end
	createHudGroup()
	
	local function worldToScreenX(x)
		return (x*gameGroup.xScale + (gameGroup.x))
	end
	
	local function worldToScreenY(y)
		return ((y+gameGroup.y/gameGroup.yScale)*gameGroup.yScale)
	end
		
	local function screenToWorldX(x)
		return x/gameGroup.xScale + ((gameGroup.x*-1)/gameGroup.xScale)
	end
	
	local function screenToWorldY(y)
		return (y-gameGroup.y)/gameGroup.yScale
	end
		
	local function isTouchingInventoryButton(x,y,button)
		return x >= button.x-button.width/2 and x <= button.x+button.width/2 and
			y >= button.y-button.height/2 and y <= button.y+button.height/2
	end
	
	local function isTouchingLeftArrowButton(x,y)
		return x >= selectedLeftArrow.x-selectedLeftArrow.width/2 and x <= selectedLeftArrow.x+selectedLeftArrow.width/2 and
			y >= selectedLeftArrow.y-selectedLeftArrow.height/2 and y <= selectedLeftArrow.y+selectedLeftArrow.height/2 and
			selectedLeftArrow.isVisible
	end
	
	local function isTouchingRightArrowButton(x,y)
		return x >= selectedRightArrow.x-selectedRightArrow.width/2 and x <= selectedRightArrow.x+selectedRightArrow.width/2 and
			y >= selectedRightArrow.y-selectedRightArrow.height/2 and y <= selectedRightArrow.y+selectedRightArrow.height/2 and
			selectedRightArrow.isVisible
	end
	
	local function isTouchingMoveButton(x,y)
		return x >= selectedMove.x-selectedMove.width/2 and x <= selectedMove.x+selectedMove.width/2 and
			y >= selectedMove.y-selectedMove.height/2 and y <= selectedMove.y+selectedMove.height/2 and
			selectedMove.isVisible
	end
			
	onObjectTouch = function(event)
		if event.phase == "began" and settingsGroup.isVisible == false and inventoryGroup.isVisible == false then
			local function performTouchEvent()
				if soundsOn == "yes" then audio.play(clickSound); end
				
				if tempObject and event.target ~= tempObject then
					--ADDING OBJECTS: STEP TWO
					if tempObject.myName == "platform" then
						table.insert(platform, display.newRect(tempObject.x,tempObject.y,tempObject.width,tempObject.height))
						local p = table.maxn(platform)	
						platform[p]:setFillColor(100,100,100)
						platform[p]:addEventListener("touch",onObjectTouch)
						platform[p].x = tempObject.x; platform[p].y = tempObject.y;
						platform[p].myName = "platform"
						gameGroup:insert(platform[p])
					--
					elseif tempObject.myName == "crate" then
						table.insert(crate, display.newImageRect("images/crate.png",tempObject.width,tempObject.height))
						local p = table.maxn(crate)	
						crate[p]:addEventListener("touch",onObjectTouch)
						crate[p].x = tempObject.x; crate[p].y = tempObject.y;
						crate[p].myName = "crate"
						gameGroup:insert(crate[p])
					--
					elseif tempObject.myName == "key" then
						key.x = tempObject.x; key.y = tempObject.y;
					--
					elseif tempObject.myName == "door" then
						door.x = tempObject.x; door.y = tempObject.y;
					--
					elseif tempObject.myName == "window" then
						table.insert(window, display.newImageRect("images/window.png",tempObject.width,tempObject.height))
						local p = table.maxn(window)	
						window[p]:addEventListener("touch",onObjectTouch)
						window[p].x = tempObject.x; window[p].y = tempObject.y;
						window[p].myName = "window"
						gameGroup:insert(window[p])
					--
					elseif tempObject.myName == "beartrap" then
						table.insert(bearTrap, display.newImageRect("images/beartrap.png",tempObject.width,tempObject.height))
						local p = table.maxn(bearTrap)	
						bearTrap[p]:addEventListener("touch",onObjectTouch)
						bearTrap[p].x = tempObject.x; bearTrap[p].y = tempObject.y;
						bearTrap[p].myName = "beartrap"
						gameGroup:insert(bearTrap[p])
					--
					elseif tempObject.myName == "fullcage" then
						table.insert(fullCage, display.newImageRect("images/fullcage.png",tempObject.width,tempObject.height))
						local p = table.maxn(fullCage)	
						fullCage[p]:addEventListener("touch",onObjectTouch)
						fullCage[p].x = tempObject.x; fullCage[p].y = tempObject.y;
						fullCage[p].myName = "fullcage"
						gameGroup:insert(fullCage[p])
					--
					elseif tempObject.myName == "ladder-large" then
						table.insert(largeLadder, display.newImageRect("images/ladder-large.png",tempObject.width,tempObject.height))
						local p = table.maxn(largeLadder)	
						largeLadder[p]:addEventListener("touch",onObjectTouch)
						largeLadder[p].x = tempObject.x; largeLadder[p].y = tempObject.y;
						largeLadder[p].myName = "ladder-large"
						gameGroup:insert(largeLadder[p])
					--
					elseif tempObject.myName == "ladder-medium" then
						table.insert(mediumLadder, display.newImageRect("images/ladder-medium.png",tempObject.width,tempObject.height))
						local p = table.maxn(mediumLadder)	
						mediumLadder[p]:addEventListener("touch",onObjectTouch)
						mediumLadder[p].x = tempObject.x; mediumLadder[p].y = tempObject.y;
						mediumLadder[p].myName = "ladder-medium"
						gameGroup:insert(mediumLadder[p])
					--
					elseif tempObject.myName == "whiteguard" then
						if tempObject.direction == "right" then
							table.insert(whiteGuard, display.newImageRect("images/guard/whiteright1.png",tempObject.width,tempObject.height))
						else
							table.insert(whiteGuard, display.newImageRect("images/guard/whiteleft1.png",tempObject.width,tempObject.height))
						end
						local p = table.maxn(whiteGuard)	
						whiteGuard[p]:addEventListener("touch",onObjectTouch)
						whiteGuard[p].x = tempObject.x; whiteGuard[p].y = tempObject.y;
						whiteGuard[p].myName = "whiteguard"
						whiteGuard[p].direction = tempObject.direction
						whiteGuard[p].index = p
						gameGroup:insert(whiteGuard[p])
					--
					elseif tempObject.myName == "blackguard" then
						if tempObject.direction == "right" then
							table.insert(blackGuard, display.newImageRect("images/guard/blackright1.png",tempObject.width,tempObject.height))
						else
							table.insert(blackGuard, display.newImageRect("images/guard/blackleft1.png",tempObject.width,tempObject.height))
						end
						local p = table.maxn(blackGuard)	
						blackGuard[p]:addEventListener("touch",onObjectTouch)
						blackGuard[p].x = tempObject.x; blackGuard[p].y = tempObject.y;
						blackGuard[p].myName = "blackguard"
						blackGuard[p].direction = tempObject.direction
						blackGuard[p].index = p
						gameGroup:insert(blackGuard[p])
					--
					elseif tempObject.myName == "gorilla/gorillaright1" then
						gorilla.x = tempObject.x; gorilla.y = tempObject.y;
					--
					end
					--
					tempObject:removeEventListener("touch", onObjectTouch) tempObject:removeSelf(); tempObject = nil;
				--
				end
				--
								
				if event.target.myName == "platform" then
					selectedLeftArrow.x = worldToScreenX(event.target.x - event.target.width/2 - (selectedLeftArrow.width/2)/gameGroup.xScale)
					selectedLeftArrow.y = worldToScreenY(event.target.y - (selectedLeftArrow.height/2)/gameGroup.yScale)
					selectedRightArrow.x = worldToScreenX(event.target.x + event.target.width/2 + (selectedRightArrow.width/2)/gameGroup.xScale)
					selectedRightArrow.y = worldToScreenY(event.target.y - (selectedRightArrow.height/2)/gameGroup.yScale)
					selectedRightArrow.isVisible = true
					selectedLeftArrow.isVisible = true
				end
				selectedMove.x = worldToScreenX(event.target.x)
				selectedMove.y = worldToScreenY(event.target.y - event.target.height/2 - (selectedMove.height/2)/gameGroup.yScale)
				selectedMove.isVisible = true	
				objectSelected = true	
				
				--selector animations
				selectedRightArrow.alpha = 0
				selectedLeftArrow.alpha = 0
				selectedMove.alpha = 0
				--end
				if event.target.myName == "platform" then
					tempObject = display.newRect(0,0,event.target.width,event.target.height)
				--
				elseif event.target.myName == "whiteguard" then
					if event.target.direction == "right" then
						tempObject = display.newImageRect("images/guard/whiteright1.png", 33,53)
						tempObject.direction = "right"
					else
						tempObject = display.newImageRect("images/guard/whiteleft1.png", 33,53)
						tempObject.direction = "left"
					end
				--
				elseif event.target.myName == "blackguard" then
					if event.target.direction == "right" then
						tempObject = display.newImageRect("images/guard/blackright1.png", 33,53)
						tempObject.direction = "right"
					else
						tempObject = display.newImageRect("images/guard/blackleft1.png", 33,53)
						tempObject.direction = "left"
					end
				--
				else
					tempObject = display.newImageRect("images/" .. event.target.myName .. ".png",event.target.width,event.target.height)
				end
				if event.target.myName == "door" or event.target.myName == "gorilla/gorillaright1" then
					if event.target.myName == "door" then
						doorSelected = true
					end
					transition.to(deleteIcon, {time = 500, x = 510, y = 350})
				end
				if event.target.myName == "platform" then
					tempObject.x = event.target.x; tempObject.y = event.target.y;
					tempObject:setFillColor(100,100,100)
					gameGroup:insert(tempObject)
					tempObject:addEventListener("touch", onObjectTouch)
					tempObject.myName = event.target.myName
					event.target:removeEventListener("touch", onObjectTouch)
					event.target:removeSelf()
					event.target = nil
				elseif event.target.myName == "door" or event.target.myName == "key" or event.target.myName == "gorilla/gorillaright1" then
					tempObject.x = event.target.x; tempObject.y = event.target.y;
					gameGroup:insert(tempObject)
					tempObject:addEventListener("touch", onObjectTouch)
					tempObject.myName = event.target.myName
					event.target.x = -100
					selectedRightArrow.isVisible = false
					selectedLeftArrow.isVisible = false
					lock:toFront()
				else
					tempObject.x = event.target.x; tempObject.y = event.target.y;
					gameGroup:insert(tempObject)
					tempObject:addEventListener("touch", onObjectTouch)
					tempObject.myName = event.target.myName
					event.target:removeEventListener("touch", onObjectTouch)
					event.target:removeSelf()
					event.target = nil
					selectedRightArrow.isVisible = false
					selectedLeftArrow.isVisible = false
				end
				
			end
			if isTouchingMoveButton(event.x, event.y) == false and isTouchingLeftArrowButton(event.x,event.y) == false and isTouchingRightArrowButton(event.x,event.y) == false then
					okToZoom = false
					objectSelected = true
					timer.performWithDelay(5,performTouchEvent,1)	
			end
		end
	end

	local function createInitialGorillaAndDoorAndKey()
		gorilla = display.newImageRect("images/gorilla/gorillaright1.png",83,58)
		gorilla.x = 100; gorilla.y = 290;
		gorilla.myName = "gorilla/gorillaright1"
		gameGroup:insert(gorilla)
		gorilla:addEventListener("touch", onObjectTouch)
		
		door = display.newImageRect("images/door.png",56,111)
		door:addEventListener("touch",onObjectTouch)
		door.x = 750; door.y = 320-door.height/2;
		door.myName = "door"
		gameGroup:insert(door)
		
		key = display.newImageRect("images/key.png",45,29)
		key:addEventListener("touch",onObjectTouch)
		key.x = -100; key.y = 100;
		key.myName = "key"
		gameGroup:insert(key)
		key.inUse = false	
			
		lock = display.newImageRect("images/lock.png", 38, 43)
		lock.x = -100; lock.y = 0;
		lock.isVisible = false
		gameGroup:insert(lock)
	end
	createInitialGorillaAndDoorAndKey()

	--CORRECT LAYERS
	local function correctLayers()
		if background then background:toFront(); end
		--
		for i=1,table.maxn(window) do
			window[i]:toFront()
		end
		if door then door:toFront(); end
		for i=1,table.maxn(crate) do
			crate[i]:toFront()
		end
		for i=1,table.maxn(largeLadder) do
			largeLadder[i]:toFront()
		end
		for i=1,table.maxn(mediumLadder) do
			mediumLadder[i]:toFront()
		end
		for i=1,table.maxn(bearTrap) do
			bearTrap[i]:toFront()
		end
		for i=1,table.maxn(fullCage) do
			fullCage[i]:toFront()
		end
		for i=1,table.maxn(whiteGuard) do
			whiteGuard[i]:toFront()
		end
		for i=1,table.maxn(blackGuard) do
			blackGuard[i]:toFront()
		end
		for i=1,table.maxn(platform) do
			platform[i]:toFront()
		end
		--
		if key then key:toFront(); end
		if gorilla then gorilla:toFront(); end
	end

	-- CREATE THE LEVEL FROM FILE
	local function createLevel()
		for i = 1,table.maxn(levelTable) do
			--
			if levelTable[i]:sub(1,1) == "s" then
			--
				if levelTable[i]:sub(3,3) == "l" then
					background = display.newImageRect("images/levelbackground-large.png",1440,960)
					background.x = 720; background.y = -160;
					gameGroup:insert(background)
					background.myName = "background"
					gameGroup.xScale = 1/3; gameGroup.yScale = 1/3;
					gameGroup.y = 213
					gameGroup.x = 0
					backgroundSize = "l"
				elseif levelTable[i]:sub(3,3) == "m" then
					background = display.newImageRect("images/levelbackground-medium.png",960,640)
					background.x = 480; background.y = 0;
					gameGroup:insert(background)
					background.myName = "background"
					gameGroup.xScale = .5; gameGroup.yScale = .5;
					gameGroup.y = 160
					gameGroup.x = 0
					backgroundSize = "m"
				else
					background = display.newImageRect("images/levelbackground-small.png",480,320)
					background.x = 240; background.y = 160;
					gameGroup:insert(background)
					background.myName = "z"
					backgroundSize = "s"
				end
			--
			elseif levelTable[i]:sub(1,1) == "p" then
				local j = 3
				local x,y,w,h = "","","",""
				while levelTable[i]:sub(j,j) ~= "#" do
					x = x .. levelTable[i]:sub(j,j)
					j = j+1
				end
				j = j+1
				while levelTable[i]:sub(j,j) ~= "#" do
					y = y .. levelTable[i]:sub(j,j)
					j = j+1
				end
				j = j+1
				while levelTable[i]:sub(j,j) ~= "#" do
					w = w .. levelTable[i]:sub(j,j)
					j = j+1
				end
				j = j+1
				while levelTable[i]:sub(j,j) ~= "#" do
					h = h .. levelTable[i]:sub(j,j)
					j = j+1
				end
				x,y,w,h = tonumber(x),tonumber(y),tonumber(w),tonumber(h)
				table.insert(platform, display.newRect(x,y,w,h))
				local p = table.maxn(platform)
				platform[p].x = x; platform[p].y = y;
				platform[p]:setFillColor(100,100,100)
				gameGroup:insert(platform[p])
				platform[p]:addEventListener("touch", onObjectTouch)
				platform[p].myName = "platform"	
				objectCount = objectCount + 1			
			--
			elseif levelTable[i]:sub(1,1) == "c" then
				local j = 3
				local x,y = "",""
				while levelTable[i]:sub(j,j) ~= "#" do
					x = x .. levelTable[i]:sub(j,j)
					j = j+1
				end
				j = j+1
				while levelTable[i]:sub(j,j) ~= "#" do
					y = y .. levelTable[i]:sub(j,j)
					j = j+1
				end
				x,y = tonumber(x),tonumber(y)
				table.insert(crate, display.newImageRect("images/crate.png", 62,62))
				local c = table.maxn(crate)
				crate[c].x = x; crate[c].y = y;
				gameGroup:insert(crate[c])
				crate[c].myName = "crate"
				crate[c]:addEventListener("touch", onObjectTouch)
				objectCount = objectCount + 1
			--
			elseif levelTable[i]:sub(1,1) == "b" and levelTable[i]:sub(2,2) == "#" then
				local j = 3
				local x,y = "",""
				while levelTable[i]:sub(j,j) ~= "#" do
					x = x .. levelTable[i]:sub(j,j)
					j = j+1
				end
				j = j+1
				while levelTable[i]:sub(j,j) ~= "#" do
					y = y .. levelTable[i]:sub(j,j)
					j = j+1
				end
				x,y = tonumber(x),tonumber(y)
				table.insert(bearTrap, display.newImageRect("images/beartrap.png", 71,13))
				local b = table.maxn(bearTrap)
				bearTrap[b].x = x; bearTrap[b].y = y;
				gameGroup:insert(bearTrap[b])
				bearTrap[b].myName = "beartrap"
				bearTrap[b]:addEventListener("touch", onObjectTouch)
				objectCount = objectCount + 1
			--
			elseif levelTable[i]:sub(1,1) == "f" then
				local j = 3
				local x,y = "",""
				while levelTable[i]:sub(j,j) ~= "#" do
					x = x .. levelTable[i]:sub(j,j)
					j = j+1
				end
				j = j+1
				while levelTable[i]:sub(j,j) ~= "#" do
					y = y .. levelTable[i]:sub(j,j)
					j = j+1
				end
				x,y = tonumber(x),tonumber(y)
				table.insert(fullCage, display.newImageRect("images/fullcage.png", 184,113))
				local b = table.maxn(fullCage)
				fullCage[b].x = x; fullCage[b].y = y;
				gameGroup:insert(fullCage[b])
				fullCage[b].myName = "fullcage"
				fullCage[b]:addEventListener("touch", onObjectTouch)
				objectCount = objectCount + 1
			--
			elseif levelTable[i]:sub(1,1) == "k" then
				local j = 3
				local x,y = "",""
				while levelTable[i]:sub(j,j) ~= "#" do
					x = x .. levelTable[i]:sub(j,j)
					j = j+1
				end
				j = j+1
				while levelTable[i]:sub(j,j) ~= "#" do
					y = y .. levelTable[i]:sub(j,j)
					j = j+1
				end
				x,y = tonumber(x),tonumber(y)
				key.x = x; key.y = y;
				key.inUse = true
				objectCount = objectCount + 1
			--
			elseif levelTable[i]:sub(1,1) == "d" then
				local j = 3
				local x,y = "",""
				while levelTable[i]:sub(j,j) ~= "#" do
					x = x .. levelTable[i]:sub(j,j)
					j = j+1
				end
				j = j+1
				while levelTable[i]:sub(j,j) ~= "#" do
					y = y .. levelTable[i]:sub(j,j)
					j = j+1
				end
				x,y = tonumber(x),tonumber(y)
				door.x = x; door.y = y;
			--
			elseif levelTable[i]:sub(1,1) == "w" and levelTable[i]:sub(2,2) == "#" then
				local j = 3
				local x,y = "",""
				while levelTable[i]:sub(j,j) ~= "#" do
					x = x .. levelTable[i]:sub(j,j)
					j = j+1
				end
				j = j+1
				while levelTable[i]:sub(j,j) ~= "#" do
					y = y .. levelTable[i]:sub(j,j)
					j = j+1
				end
				--x,y = tonumber(x),tonumber(y)
				table.insert(window, display.newImageRect("images/window.png", 71,71))
				local w = table.maxn(window)
				window[w].x = x; window[w].y = y;
				gameGroup:insert(window[w])
				window[w].myName = "window"
				window[w]:addEventListener("touch", onObjectTouch)
				objectCount = objectCount + 1
			--
			elseif levelTable[i]:sub(1,1) == "l" then
				local size = levelTable[i]:sub(3,3)
				local j = 5
				local x,y = "",""
				while levelTable[i]:sub(j,j) ~= "#" do
					x = x .. levelTable[i]:sub(j,j)
					j = j+1
				end
				j = j+1
				while levelTable[i]:sub(j,j) ~= "#" do
					y = y .. levelTable[i]:sub(j,j)
					j = j+1
				end
				x,y = tonumber(x),tonumber(y)
				if size == "l" then
					table.insert(largeLadder, display.newImageRect("images/ladder-large.png", 60,356))
					local l = table.maxn(largeLadder)
					largeLadder[l].x = x; largeLadder[l].y = y;
					gameGroup:insert(largeLadder[l])
					largeLadder[l].myName = "ladder-large"	
					largeLadder[l]:addEventListener("touch", onObjectTouch)
					objectCount = objectCount + 1			
				else
					table.insert(mediumLadder, display.newImageRect("images/ladder-medium.png", 60,227))
					local l = table.maxn(mediumLadder)
					mediumLadder[l].x = x; mediumLadder[l].y = y;
					gameGroup:insert(mediumLadder[l])
					mediumLadder[l].myName = "ladder-medium"
					mediumLadder[l]:addEventListener("touch", onObjectTouch)
					objectCount = objectCount + 1
				end
			--
			elseif levelTable[i]:sub(1,1) == "g" then
				local j = 3
				local x,y = "",""
				while levelTable[i]:sub(j,j) ~= "#" do
					x = x .. levelTable[i]:sub(j,j)
					j = j+1
				end
				j = j+1
				while levelTable[i]:sub(j,j) ~= "#" do
					y = y .. levelTable[i]:sub(j,j)
					j = j+1
				end
				x,y = tonumber(x),tonumber(y)
				gorilla.x = x; gorilla.y = y;
			--
			elseif ((levelTable[i]:sub(1,1) == "w" and levelTable[i]:sub(2,2) == "g") or (levelTable[i]:sub(1,1) == "b" and levelTable[i]:sub(2,2) == "g"))  then								
				local j = 4
				local x,y,direction = "","",""
				while levelTable[i]:sub(j,j) ~= "#" do
					x = x .. levelTable[i]:sub(j,j)
					j = j+1
				end
				j = j+1
				while levelTable[i]:sub(j,j) ~= "#" do
					y = y .. levelTable[i]:sub(j,j)
					j = j+1
				end
				j = j+1
				while levelTable[i]:sub(j,j) ~= "#" do
					direction = direction .. levelTable[i]:sub(j,j)
					j = j+1
				end
				x,y = tonumber(x),tonumber(y)

				if levelTable[i]:sub(1,1) == "w" then
					if direction == "r" then
						table.insert(whiteGuard, display.newImageRect("images/guard/whiteright1.png",33,53))
					else
						table.insert(whiteGuard, display.newImageRect("images/guard/whiteleft1.png",33,53))
					end
					local g = table.maxn(whiteGuard)
					gameGroup:insert(whiteGuard[g])
					whiteGuard[g].x = x; whiteGuard[g].y = y;
					if direction == "r" then
						whiteGuard[g].direction = "right"
					else
						whiteGuard[g].direction = "left"
					end
					whiteGuard[g]:addEventListener("touch", onObjectTouch)
					whiteGuard[g].myName = "whiteguard"
					objectCount = objectCount + 1
				else
					if direction == "r" then
						table.insert(blackGuard, display.newImageRect("images/guard/blackright1.png",33,53))
					else
						table.insert(blackGuard, display.newImageRect("images/guard/blackleft1.png",33,53))
					end
					local g = table.maxn(blackGuard)
					gameGroup:insert(blackGuard[g])
					blackGuard[g].x = x; blackGuard[g].y = y;
					if direction == "r" then
						blackGuard[g].direction = "right"
					else
						blackGuard[g].direction = "left"
					end
					blackGuard[g]:addEventListener("touch", onObjectTouch)
					blackGuard[g].myName = "blackguard"
					objectCount = objectCount + 1
				end
			--
			end
		end
		--
		correctLayers()
		updateObjectCountText()
	end
	
	-- GAME LOOP
	local function gameLoop(event)
		--game logic stuff
	end
	Runtime:addEventListener( "enterFrame", gameLoop )
	
	--TOUCH EVENT
	local function screenTouched(event)
		worldTouchX = screenToWorldX(event.x)
		worldTouchY = screenToWorldY(event.y)
		
		--
		if event.phase == "began" and settingsGroup.isVisible and (event.x < 40 or event.x > 440 or event.y < 35 or event.y > 285) then 
			-- Hide keyboard
			native.setKeyboardFocus( nil )
			keyboardIsUp = false
			textField.isVisible = false
			transition.to(settingsGroup,{time = 500, alpha = 0, onComplete = function() settingsGroup.isVisible = false; settingsGroup.alpha = 1; end})
			transition.to(gearBtn, {time = 1000, rotation = gearBtn.rotation-360})
		elseif event.phase == "began" and keyboardIsUp then
			-- Hide keyboard
			native.setKeyboardFocus( nil )
			keyboardIsUp = false
		end
		--
		if event.phase == "began" and inventoryGroup.isVisible then
			--ADDING OBJECTS: STEP ONE
			if isTouchingInventoryButton(event.x,event.y,platformBtn) then
				if soundsOn == "yes" then audio.play(clickSound); end
				inventoryGroup.isVisible = false
				tempObject = display.newRect(event.x, event.y,100,10)
				tempObject:setFillColor(100,100,100)
				tempObject.x = worldTouchX; tempObject.y = screenToWorldY((event.y + selectedMove.height/2) + selectedMove.height/2 + (tempObject.height/2)*gameGroup.yScale);
				tempObject.myName = "platform"
				inventorySelected = true
				gameGroup:insert(tempObject)
				transition.to(deleteIcon, {time = 500, x = 450, y = 290})
				selectedMove.isVisible = true
				moveIsSelected = true
				objectCount = objectCount + 1
			--
			elseif isTouchingInventoryButton(event.x,event.y,crateBtn) then
				if soundsOn == "yes" then audio.play(clickSound); end
				inventoryGroup.isVisible = false
				tempObject = display.newImageRect("images/crate.png",62,62)
				tempObject.x = worldTouchX; tempObject.y = screenToWorldY((event.y + selectedMove.height/2) + selectedMove.height/2 + (tempObject.height/2)*gameGroup.yScale);
				tempObject.myName = "crate"
				inventorySelected = true
				gameGroup:insert(tempObject)
				transition.to(deleteIcon, {time = 500, x = 450, y = 290})
				selectedMove.isVisible = true
				moveIsSelected = true
				objectCount = objectCount + 1
			--
			elseif isTouchingInventoryButton(event.x,event.y,keyBtn) then
				if soundsOn == "yes" then audio.play(clickSound); end
				key.x = -100
				key.inUse = true
				inventoryGroup.isVisible = false
				lock.isVisible = true
				lock.x = door.x; lock.y = door.y;
				lock:toFront()
				tempObject = display.newImageRect("images/key.png",45,29)
				tempObject.x = worldTouchX; tempObject.y = screenToWorldY((event.y + selectedMove.height/2) + selectedMove.height/2 + (tempObject.height/2)*gameGroup.yScale);
				tempObject.myName = "key"
				inventorySelected = true
				gameGroup:insert(tempObject)
				transition.to(deleteIcon, {time = 500, x = 450, y = 290})
				selectedMove.isVisible = true
				moveIsSelected = true
				objectCount = objectCount + 1
			--
			elseif isTouchingInventoryButton(event.x,event.y,doorBtn) then
				if soundsOn == "yes" then audio.play(clickSound); end
				door.x = -100
				inventoryGroup.isVisible = false
				tempObject = display.newImageRect("images/door.png",56,111)
				tempObject.x = worldTouchX; tempObject.y = screenToWorldY((event.y + selectedMove.height/2) + selectedMove.height/2 + (tempObject.height/2)*gameGroup.yScale);
				lock.x = tempObject.x; lock.y = tempObject.y;
				lock:toFront()
				tempObject.myName = "door"
				inventorySelected = true
				gameGroup:insert(tempObject)
				selectedMove.isVisible = true
				moveIsSelected = true
				doorSelected = true
			--	
			elseif isTouchingInventoryButton(event.x,event.y,windowBtn) then
				if soundsOn == "yes" then audio.play(clickSound); end
				inventoryGroup.isVisible = false
				tempObject = display.newImageRect("images/window.png",71,71)
				tempObject.x = worldTouchX; tempObject.y = screenToWorldY((event.y + selectedMove.height/2) + selectedMove.height/2 + (tempObject.height/2)*gameGroup.yScale);
				tempObject.myName = "window"
				inventorySelected = true
				gameGroup:insert(tempObject)
				transition.to(deleteIcon, {time = 500, x = 450, y = 290})
				selectedMove.isVisible = true
				moveIsSelected = true
				objectCount = objectCount + 1
			--	
			elseif isTouchingInventoryButton(event.x,event.y,largeLadderBtn) then
				if soundsOn == "yes" then audio.play(clickSound); end
				inventoryGroup.isVisible = false
				tempObject = display.newImageRect("images/ladder-large.png",60,356)
				tempObject.x = worldTouchX; tempObject.y = screenToWorldY((event.y + selectedMove.height/2) + selectedMove.height/2 + (tempObject.height/2)*gameGroup.yScale);
				tempObject.myName = "ladder-large"
				inventorySelected = true
				gameGroup:insert(tempObject)
				transition.to(deleteIcon, {time = 500, x = 450, y = 290})
				selectedMove.isVisible = true
				moveIsSelected = true
				objectCount = objectCount + 1
			--	
			elseif isTouchingInventoryButton(event.x,event.y,mediumLadderBtn) then
				if soundsOn == "yes" then audio.play(clickSound); end
				inventoryGroup.isVisible = false
				tempObject = display.newImageRect("images/ladder-medium.png",60,227)
				tempObject.x = worldTouchX; tempObject.y = screenToWorldY((event.y + selectedMove.height/2) + selectedMove.height/2 + (tempObject.height/2)*gameGroup.yScale);
				tempObject.myName = "ladder-medium"
				inventorySelected = true
				gameGroup:insert(tempObject)
				transition.to(deleteIcon, {time = 500, x = 450, y = 290})
				selectedMove.isVisible = true
				moveIsSelected = true
				objectCount = objectCount + 1
			--	
			elseif isTouchingInventoryButton(event.x,event.y,whiteGuardBtn) then
				if soundsOn == "yes" then audio.play(clickSound); end
				inventoryGroup.isVisible = false
				tempObject = display.newImageRect("images/guard/whiteright1.png",33,53)
				tempObject.x = worldTouchX; tempObject.y = screenToWorldY((event.y + selectedMove.height/2) + selectedMove.height/2 + (tempObject.height/2)*gameGroup.yScale);
				tempObject.myName = "whiteguard"
				tempObject.direction = "right"
				inventorySelected = true
				gameGroup:insert(tempObject)
				transition.to(deleteIcon, {time = 500, x = 450, y = 290})
				selectedMove.isVisible = true
				moveIsSelected = true
				objectCount = objectCount + 1
			--	
			elseif isTouchingInventoryButton(event.x,event.y,blackGuardBtn) then
				if soundsOn == "yes" then audio.play(clickSound); end
				inventoryGroup.isVisible = false
				tempObject = display.newImageRect("images/guard/blackright1.png",33,53)
				tempObject.x = worldTouchX; tempObject.y = screenToWorldY((event.y + selectedMove.height/2) + selectedMove.height/2 + (tempObject.height/2)*gameGroup.yScale);
				tempObject.myName = "blackguard"
				tempObject.direction = "right"
				inventorySelected = true
				gameGroup:insert(tempObject)
				transition.to(deleteIcon, {time = 500, x = 450, y = 290})
				selectedMove.isVisible = true
				moveIsSelected = true
				objectCount = objectCount + 1
			--	
			elseif isTouchingInventoryButton(event.x,event.y,bearTrapBtn) then
				if soundsOn == "yes" then audio.play(clickSound); end
				inventoryGroup.isVisible = false
				tempObject = display.newImageRect("images/beartrap.png",71,13)
				tempObject.x = worldTouchX; tempObject.y = screenToWorldY((event.y + selectedMove.height/2) + selectedMove.height/2 + (tempObject.height/2)*gameGroup.yScale);
				tempObject.myName = "beartrap"
				inventorySelected = true
				gameGroup:insert(tempObject)
				transition.to(deleteIcon, {time = 500, x = 450, y = 290})
				selectedMove.isVisible = true
				moveIsSelected = true
				objectCount = objectCount + 1
			--	
			elseif isTouchingInventoryButton(event.x,event.y,cageBtn) then
				if soundsOn == "yes" then audio.play(clickSound); end
				inventoryGroup.isVisible = false
				tempObject = display.newImageRect("images/fullcage.png",184,113)
				tempObject.x = worldTouchX; tempObject.y = screenToWorldY((event.y + selectedMove.height/2) + selectedMove.height/2 + (tempObject.height/2)*gameGroup.yScale);
				tempObject.myName = "fullcage"
				inventorySelected = true
				gameGroup:insert(tempObject)
				transition.to(deleteIcon, {time = 500, x = 450, y = 290})
				selectedMove.isVisible = true
				moveIsSelected = true
				objectCount = objectCount + 1
			--	
			elseif isTouchingInventoryButton(event.x,event.y,gorillaBtn) then
				if soundsOn == "yes" then audio.play(clickSound); end
				gorilla.x = -100
				inventoryGroup.isVisible = false
				tempObject = display.newImageRect("images/gorilla/gorillaright1.png",83,58)
				tempObject.x = worldTouchX; tempObject.y = screenToWorldY((event.y + selectedMove.height/2) + selectedMove.height/2 + (tempObject.height/2)*gameGroup.yScale);
				tempObject.myName = "gorilla/gorillaright1"
				inventorySelected = true
				gameGroup:insert(tempObject)
				selectedMove.isVisible = true
				moveIsSelected = true
			--	
			elseif event.x < 40 or event.x > 440 or event.y < 35 or event.y > 285 then 
				transition.to(inventoryGroup,{time = 500, alpha = 0, onComplete = function() inventoryGroup.isVisible = false; inventoryGroup.alpha = 1; end})
			end
			--update the object count text
			updateObjectCountText()
			--location of selected move
			if tempObject then
				selectedMove.x = worldToScreenX(tempObject.x)
				selectedMove.y = worldToScreenY(tempObject.y - tempObject.height/2 - (selectedMove.height/2)/gameGroup.yScale)
			end
		--
		elseif event.phase == "began" and objectSelected == false then
			if isTouchingLeftArrowButton(event.x,event.y) and selectedLeftArrow.isVisible then
				leftArrowIsSelected = true
				selectedMove.isVisible = false
				transition.to(deleteIcon, {time = 500, x = 510, y = 350})
				if tempObject and (tempObject.myName == "whiteguard" or tempObject.myName == "blackguard") and tempObject.direction == "right" then
					local x,y,name = tempObject.x, tempObject.y, tempObject.myName
					tempObject:removeEventListener("touch", onObjectTouch)
					tempObject:removeSelf()
					if name == "whiteguard" then
						tempObject = display.newImageRect("images/guard/whiteleft1.png", 33,53)
						tempObject.myName = "whiteguard"
					else
						tempObject = display.newImageRect("images/guard/blackleft1.png", 33,53)
						tempObject.myName = "blackguard"
					end
					tempObject:addEventListener("touch",onObjectTouch)
					tempObject.x = x; tempObject.y = y;
					gameGroup:insert(tempObject)
					tempObject.direction = "left"
				end
			--
			elseif isTouchingRightArrowButton(event.x,event.y) and selectedRightArrow.isVisible then
				rightArrowIsSelected = true
				selectedMove.isVisible = false
				transition.to(deleteIcon, {time = 500, x = 510, y = 350})
				if tempObject and (tempObject.myName == "whiteguard" or tempObject.myName == "blackguard") and tempObject.direction == "left" then
					local x,y,name = tempObject.x, tempObject.y, tempObject.myName
					tempObject:removeEventListener("touch", onObjectTouch)
					tempObject:removeSelf()
					if name == "whiteguard" then
						tempObject = display.newImageRect("images/guard/whiteright1.png", 33,53)
						tempObject.myName = "whiteguard"
					else
						tempObject = display.newImageRect("images/guard/blackright1.png", 33,53)
						tempObject.myName = "blackguard"
					end
					tempObject:addEventListener("touch",onObjectTouch)
					tempObject.x = x; tempObject.y = y;
					gameGroup:insert(tempObject)
					tempObject.direction = "right"
				end
			--	
			elseif isTouchingMoveButton(event.x,event.y) and selectedMove.isVisible then
				moveIsSelected = true
				selectedLeftArrow.isVisible = false
				selectedRightArrow.isVisible = false
			--	
			else
				okToZoom = true
				if doorSelected then doorSelected = false; end
				selectedRightArrow.isVisible = false
				selectedLeftArrow.isVisible = false
				selectedMove.isVisible = false
				transition.to(deleteIcon, {time = 500, x = 510, y = 350})
				--
				if tempObject then					
					--ADDING OBJECTS: STEP TWO
					if tempObject.myName == "platform" then
						table.insert(platform, display.newRect(tempObject.x,tempObject.y,tempObject.width,tempObject.height))
						local p = table.maxn(platform)	
						platform[p]:setFillColor(100,100,100)
						platform[p]:addEventListener("touch",onObjectTouch)
						platform[p].x = tempObject.x; platform[p].y = tempObject.y;
						platform[p].myName = "platform"
						gameGroup:insert(platform[p])
					--
					elseif tempObject.myName == "crate" then
						table.insert(crate, display.newImageRect("images/crate.png",tempObject.width,tempObject.height))
						local p = table.maxn(crate)	
						crate[p]:addEventListener("touch",onObjectTouch)
						crate[p].x = tempObject.x; crate[p].y = tempObject.y;
						crate[p].myName = "crate"
						gameGroup:insert(crate[p])
					--
					elseif tempObject.myName == "key" then
						key.x = tempObject.x; key.y = tempObject.y;
					--
					elseif tempObject.myName == "door" then
						door.x = tempObject.x; door.y = tempObject.y;
					--
					elseif tempObject.myName == "window" then
						table.insert(window, display.newImageRect("images/window.png",tempObject.width,tempObject.height))
						local p = table.maxn(window)	
						window[p]:addEventListener("touch",onObjectTouch)
						window[p].x = tempObject.x; window[p].y = tempObject.y;
						window[p].myName = "window"
						gameGroup:insert(window[p])
					--
					elseif tempObject.myName == "beartrap" then
						table.insert(bearTrap, display.newImageRect("images/beartrap.png",tempObject.width,tempObject.height))
						local p = table.maxn(bearTrap)	
						bearTrap[p]:addEventListener("touch",onObjectTouch)
						bearTrap[p].x = tempObject.x; bearTrap[p].y = tempObject.y;
						bearTrap[p].myName = "beartrap"
						gameGroup:insert(bearTrap[p])
					--
					elseif tempObject.myName == "fullcage" then
						table.insert(fullCage, display.newImageRect("images/fullcage.png",tempObject.width,tempObject.height))
						local p = table.maxn(fullCage)	
						fullCage[p]:addEventListener("touch",onObjectTouch)
						fullCage[p].x = tempObject.x; fullCage[p].y = tempObject.y;
						fullCage[p].myName = "fullcage"
						gameGroup:insert(fullCage[p])
					--
					elseif tempObject.myName == "ladder-large" then
						table.insert(largeLadder, display.newImageRect("images/ladder-large.png",tempObject.width,tempObject.height))
						local p = table.maxn(largeLadder)	
						largeLadder[p]:addEventListener("touch",onObjectTouch)
						largeLadder[p].x = tempObject.x; largeLadder[p].y = tempObject.y;
						largeLadder[p].myName = "ladder-large"
						gameGroup:insert(largeLadder[p])
					--
					elseif tempObject.myName == "ladder-medium" then
						table.insert(mediumLadder, display.newImageRect("images/ladder-medium.png",tempObject.width,tempObject.height))
						local p = table.maxn(mediumLadder)	
						mediumLadder[p]:addEventListener("touch",onObjectTouch)
						mediumLadder[p].x = tempObject.x; mediumLadder[p].y = tempObject.y;
						mediumLadder[p].myName = "ladder-medium"
						gameGroup:insert(mediumLadder[p])
					--
					elseif tempObject.myName == "whiteguard" then
						if tempObject.direction == "right" then
							table.insert(whiteGuard, display.newImageRect("images/guard/whiteright1.png",tempObject.width,tempObject.height))
						else
							table.insert(whiteGuard, display.newImageRect("images/guard/whiteleft1.png",tempObject.width,tempObject.height))
						end
						local p = table.maxn(whiteGuard)	
						whiteGuard[p]:addEventListener("touch",onObjectTouch)
						whiteGuard[p].x = tempObject.x; whiteGuard[p].y = tempObject.y;
						whiteGuard[p].myName = "whiteguard"
						whiteGuard[p].direction = tempObject.direction
						whiteGuard[p].index = p
						gameGroup:insert(whiteGuard[p])
					--
					elseif tempObject.myName == "blackguard" then
						if tempObject.direction == "right" then
							table.insert(blackGuard, display.newImageRect("images/guard/blackright1.png",tempObject.width,tempObject.height))
						else
							table.insert(blackGuard, display.newImageRect("images/guard/blackleft1.png",tempObject.width,tempObject.height))
						end
						local p = table.maxn(blackGuard)	
						blackGuard[p]:addEventListener("touch",onObjectTouch)
						blackGuard[p].x = tempObject.x; blackGuard[p].y = tempObject.y;
						blackGuard[p].myName = "blackguard"
						blackGuard[p].direction = tempObject.direction
						blackGuard[p].index = p
						gameGroup:insert(blackGuard[p])
					--
					elseif tempObject.myName == "gorilla/gorillaright1" then
						gorilla.x = tempObject.x; gorilla.y = tempObject.y;
					--
					end
				--
				end
				--
				if tempObject then tempObject:removeEventListener("touch", onObjectTouch) tempObject:removeSelf(); tempObject = nil; end
			--
			end
		--
		elseif event.phase == "moved" and (moveIsSelected or inventorySelected) then
			selectedMove.x = worldToScreenX(worldTouchX)
			selectedMove.y = event.y + selectedMove.height/2
			tempObject.x = screenToWorldX(selectedMove.x); tempObject.y = screenToWorldY(selectedMove.y + selectedMove.height/2 + (tempObject.height/2)*gameGroup.yScale);
			if doorSelected then
				lock.x = screenToWorldX(selectedMove.x); lock.y = screenToWorldY(selectedMove.y + selectedMove.height/2 + (tempObject.height/2)*gameGroup.yScale);				
			end
		--
		elseif event.phase == "moved" and (rightArrowIsSelected or leftArrowIsSelected) and tempObject.myName == "platform" then
			if rightArrowIsSelected then
				tempObject.width = tempObject.width + (screenToWorldX(event.x) - screenToWorldX(selectedRightArrow.x));
			else
				tempObject.width = tempObject.width + (screenToWorldX(selectedLeftArrow.x) - screenToWorldX(event.x));
			end
			if tempObject.width < 50 then tempObject.width = 50; end
			selectedLeftArrow.x = worldToScreenX(tempObject.x - tempObject.width/2 - (selectedLeftArrow.width/2)/gameGroup.xScale)
			selectedLeftArrow.y = worldToScreenY(tempObject.y - (selectedLeftArrow.height/2)/gameGroup.yScale)
			selectedRightArrow.x = worldToScreenX(tempObject.x + tempObject.width/2 + (selectedRightArrow.width/2)/gameGroup.xScale)
			selectedRightArrow.y = worldToScreenY(tempObject.y - (selectedRightArrow.height/2)/gameGroup.yScale)
		--
		elseif event.phase == "ended" and okToZoom == false then
			--
			if tempObject then
				--
				--DELETE THE TEMP OBJECT IF DRAGGED TO THE TRASH CAN
				if worldToScreenX(tempObject.x) > 435 and worldToScreenY(tempObject.y) > 275 and 
						tempObject.myName ~= "gorilla/gorillaright1" and tempObject.myName ~= "door" then
					--
					if tempObject.myName == "key" then
						key.inUse = false
						lock.isVisible = false
					end
					--
					tempObject:removeEventListener("touch", onObjectTouch)
					tempObject:removeSelf()
					tempObject = nil
					selectedMove.isVisible = false
					transition.to(deleteIcon, {time = 500, x = 510, y = 350})
					objectCount = objectCount - 1
					updateObjectCountText()
				end
				--
				--
				if tempObject then
					--
					if tempObject.y + tempObject.height/2 > 320 then tempObject.y = 320 - tempObject.height/2; end
					if tempObject.x - tempObject.width/2 < 0 then tempObject.x = 0 + tempObject.width/2; end
					if backgroundSize == "l" then
						if tempObject.y - tempObject.height/2 < -640 then tempObject.y = -640 + tempObject.height; end
						if tempObject.x + tempObject.width/2 > 1440 then tempObject.x = 1440 - tempObject.width/2; end
					elseif backgroundSize == "m" then
						if tempObject.y - tempObject.height/2 < -320 then tempObject.y = -320 + tempObject.height; end
						if tempObject.x + tempObject.width/2 > 960 then tempObject.x = 960 - tempObject.width/2; end
					end
					if tempObject.myName == "door" then lock.x = tempObject.x; lock.y = tempObject.y; end
					--
					if tempObject.myName == "platform" then
						if tempObject.y > 250 then tempObject.y = 250; end
						selectedLeftArrow.x = worldToScreenX(tempObject.x - tempObject.width/2 - (selectedLeftArrow.width/2)/gameGroup.xScale)
						selectedLeftArrow.y = worldToScreenY(tempObject.y - (selectedLeftArrow.height/2)/gameGroup.yScale)
						selectedRightArrow.x = worldToScreenX(tempObject.x + tempObject.width/2 + (selectedRightArrow.width/2)/gameGroup.xScale)
						selectedRightArrow.y = worldToScreenY(tempObject.y - (selectedRightArrow.height/2)/gameGroup.yScale)
						selectedMove.x = worldToScreenX(tempObject.x)
						selectedMove.y = worldToScreenY(tempObject.y - tempObject.height/2 - (selectedMove.height/2)/gameGroup.yScale)
						selectedRightArrow.isVisible = true
						selectedLeftArrow.isVisible = true
						selectedMove.isVisible = true
						transition.to(deleteIcon, {time = 500, x = 450, y = 290})
					--
					elseif tempObject.myName == "whiteguard" or tempObject.myName == "blackguard" then
						selectedLeftArrow.x = worldToScreenX(tempObject.x - tempObject.width/2 - (selectedLeftArrow.width/2)/gameGroup.xScale)
						selectedLeftArrow.y = worldToScreenY(tempObject.y - (selectedLeftArrow.height/2)/gameGroup.yScale)
						selectedRightArrow.x = worldToScreenX(tempObject.x + tempObject.width/2 + (selectedRightArrow.width/2)/gameGroup.xScale)
						selectedRightArrow.y = worldToScreenY(tempObject.y - (selectedRightArrow.height/2)/gameGroup.yScale)
						selectedMove.x = worldToScreenX(tempObject.x)
						selectedMove.y = worldToScreenY(tempObject.y - tempObject.height/2 - (selectedMove.height/2)/gameGroup.yScale)
						selectedRightArrow.isVisible = true
						selectedLeftArrow.isVisible = true
						selectedMove.isVisible = true
						transition.to(deleteIcon, {time = 500, x = 450, y = 290})
					--
					else
						selectedMove.x = worldToScreenX(tempObject.x)
						selectedMove.y = worldToScreenY(tempObject.y - tempObject.height/2 - (selectedMove.height/2)/gameGroup.yScale)
						selectedMove.isVisible = true
						if tempObject.myName ~= "door" and tempObject.myName ~= "gorilla/gorillaright1" then
							transition.to(deleteIcon, {time = 500, x = 450, y = 290})
						end
					--
					end
				end
				--
				--selector animations
				if moveIsSelected == false then
					selectedMove.alpha = 0
					transition.to(selectedMove, {time = 500, alpha = 1})
				end
				if leftArrowIsSelected == false and rightArrowIsSelected == false then
					selectedLeftArrow.alpha = 0
					transition.to(selectedLeftArrow, {time = 500, alpha = 1})
					selectedRightArrow.alpha = 0
					transition.to(selectedRightArrow, {time = 500, alpha = 1})
				end	
				--end
			--
			end
			inventorySelected = false
			objectSelected = false
			leftArrowIsSelected = false
			rightArrowIsSelected = false
			moveIsSelected = false
		--
		end
	end
	Runtime:addEventListener("touch", screenTouched)
	
	------------------------------------------------------------------------------------------------------------------------------
	--STUFF FOR PINCH TO ZOOM
	local function calculateDelta( previousTouches, event )
	        local id,touch = next( previousTouches )
	        if event.id == id then
	                id,touch = next( previousTouches, id )
	                assert( id ~= event.id )
	        end

	        local dx = touch.x - event.x
	        local dy = touch.y - event.y
	        return dx, dy
	end

	-- create a table listener object for the bkgd image
	function gameGroup:touch( event )
		if okToZoom then
	        local result = true
	        local phase = event.phase

	        local previousTouches = self.previousTouches

	        local numTotalTouches = 1
	        if ( previousTouches ) then
	                -- add in total from previousTouches, subtract one if event is already in the array
	                numTotalTouches = numTotalTouches + self.numPreviousTouches
	                if previousTouches[event.id] then
	                        numTotalTouches = numTotalTouches - 1
	                end
	        end

	        if "began" == phase then
	                -- Very first "began" event
	                if ( not self.isFocus ) then
							lastX = event.x
							lastY = event.y
	                        -- Subsequent touch events will target button even if they are outside the stageBounds of button
	                        display.getCurrentStage():setFocus( self )
	                        self.isFocus = true

	                        previousTouches = {}
	                        self.previousTouches = previousTouches
	                        self.numPreviousTouches = 0
	                elseif ( not self.distance ) then
	                        local dx,dy

	                        if previousTouches and ( numTotalTouches ) >= 2 then
	                                dx,dy = calculateDelta( previousTouches, event )
	                        end

	                        -- initialize to distance between two touches
	                        if ( dx and dy ) then
	                                local d = math.sqrt( dx*dx + dy*dy )
	                                if ( d > 0 ) then
	                                        self.distance = d
	                                        self.xScaleOriginal = self.xScale
	                                        self.yScaleOriginal = self.yScale
	                                end
	                        end
	                end

	                if not previousTouches[event.id] then
	                        self.numPreviousTouches = self.numPreviousTouches + 1
	                end
	                previousTouches[event.id] = event

			elseif phase == "moved" and self.numPreviousTouches == 1 then
				self.x = self.x + (event.x - lastX)
				self.y = self.y + (event.y - lastY)
				lastX = event.x
				lastY = event.y
				
				--boundaries
				if backgroundSize == "l" then
					if self.x > 0 then
						self.x = 0
					elseif self.x < 480 - (1440*self.xScale) then
						self.x = 480 - (1440*self.xScale)
					end
					if self.y < 320 - 320*self.yScale then
						self.y = 320 - 320*self.yScale
					elseif self.y > 640*self.yScale then
						self.y = 640*self.yScale
					end
				elseif backgroundSize == "m" then
					if self.x > 0 then
						self.x = 0
					elseif self.x < 480 - (960*self.xScale) then
						self.x = 480 - (960*self.xScale)
					end
					
					if self.y < 320 - 320*self.yScale then
						self.y = 320 - 320*self.yScale
					elseif self.y > 320*self.yScale then
						self.y = 320*self.yScale
					end
				end
				--
	        elseif self.isFocus then
	                if "moved" == phase then
	                        if ( self.distance ) then
	                                local dx,dy
	                                if previousTouches and ( numTotalTouches ) >= 2 then
	                                        dx,dy = calculateDelta( previousTouches, event )
	                                end

	                                if ( dx and dy ) then
	                                        local newDistance = math.sqrt( dx*dx + dy*dy )
	                                        local scale = newDistance / self.distance
	                                        
											if ( scale > 0 ) then
	                                                self.xScale = self.xScaleOriginal * scale
	                                                self.yScale = self.yScaleOriginal * scale
	                                        end
	
											if backgroundSize == "l" then
												if self.x > 0 then
													self.x = 0
												elseif self.x < 480 - (1440*self.xScale) then
													self.x = 480 - (1440*self.xScale)
												end
												if self.y < 320 - 320*self.yScale then
													self.y = 320 - 320*self.yScale
												elseif self.y > 640*self.yScale then
													self.y = 640*self.yScale
												end
											elseif backgroundSize == "m" then
												if self.x > 0 then
													self.x = 0
												elseif self.x < 480 - (960*self.xScale) then
													self.x = 480 - (960*self.xScale)
												end

												if self.y < 320 - 320*self.yScale then
													self.y = 320 - 320*self.yScale
												elseif self.y > 320*self.yScale then
													self.y = 320*self.yScale
												end
											end
	
	
											if backgroundSize == "l" then
												--
												if self.xScale < 1/3 then 
													self.xScale = 1/3
												elseif self.xScale > 1 then
													self.xScale = 1
												end
												if self.yScale < 1/3 then 
													self.yScale = 1/3
												elseif self.yScale > 1 then
													self.yScale = 1
												end
												--
												if self.x > 0 then
													self.x = 0
												elseif self.x < 480 - (1440*self.xScale) then
													self.x = 480 - (1440*self.xScale)
												end
												if self.y < 320 - 320*self.yScale then
													self.y = 320 - 320*self.yScale
												elseif self.y > 640*self.yScale then
													self.y = 640*self.yScale
												end
												--
											elseif backgroundSize == "m" then
												--
												if self.xScale < .5 then 
													self.xScale = .5
												elseif self.xScale > 1 then
													self.xScale = 1
												end
												if self.yScale < .5 then 
													self.yScale = .5
												elseif self.yScale > 1 then
													self.yScale = 1
												end
												--
												if self.x > 0 then
													self.x = 0
												elseif self.x < 480 - (960*self.xScale) then
													self.x = 480 - (960*self.xScale)
												end

												if self.y < 320 - 320*self.yScale then
													self.y = 320 - 320*self.yScale
												elseif self.y > 320*self.yScale then
													self.y = 320*self.yScale
												end
												--
											end
	                                end
	                        end

	                        if not previousTouches[event.id] then
	                                self.numPreviousTouches = self.numPreviousTouches + 1
	                        end
	                        previousTouches[event.id] = event

	                elseif "ended" == phase or "cancelled" == phase then
	                        if previousTouches[event.id] then
	                                self.numPreviousTouches = self.numPreviousTouches - 1
	                                previousTouches[event.id] = nil
	                        end

	                        if ( #previousTouches > 0 ) then
	                                -- must be at least 2 touches remaining to pinch/zoom
	                                self.distance = nil
	                        else
	                                -- previousTouches is empty so no more fingers are touching the screen
	                                -- Allow touch events to be sent normally to the objects they "hit"
	                                display.getCurrentStage():setFocus( nil )

	                                self.isFocus = false
	                                self.distance = nil
	                                self.xScaleOriginal = nil
	                                self.yScaleOriginal = nil

	                                -- reset array
	                                self.previousTouches = nil
	                                self.numPreviousTouches = nil
	                        end
	                end
	        end
	        return result
		end
	end
	gameGroup:addEventListener("touch", gameGroup)
	------------------------------------------------------------------------------------------------------------------------------
	
	-- ON SYSTEM
	local function onSystem( event )
		if event.type == "applicationSuspend" then
			exportLevel()
			if onDevice then os.exit(); end
		elseif event.type == "applicationExit" then
			exportLevel()
			if onDevice then os.exit(); end
		end
	end
	Runtime:addEventListener("system", onSystem)
	---------------------------------------------------------------------------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------------------------------------------------------------------------
	if newOrLoad == "load" then
		createLevel()
		if key.inUse then
			lock.isVisible = true
			lock.x = door.x; lock.y = door.y;
			lock:toFront()
		end
	end
	
	--ADS
	if not fullVersion then
		ads.show( "banner320x48", { x=240-160, y=0, interval=20, testMode=false } )
		if not onDevice then
			local fakeAd = display.newRect(240-160,0,320,48)
			hudGroup:insert(fakeAd)
		end
	end
		
	--UNLOAD THE LEVEL
	unloadMe = function()
		-- STOP PHYSICS ENGINE
		--physics.stop()
		
		if not fullVersion then ads.hide(); end
		
		-- REMOVE EVENT LISTENERS
		Runtime:removeEventListener("enterFrame", gameLoop)
		Runtime:removeEventListener("touch", screenTouched)
		Runtime:removeEventListener("system", onSystem)
		gameGroup:removeEventListener("touch", gameGroup)
		settingsBackground:removeEventListener("touch", settingsBackground)
		if tempObject then tempObject:removeEventListener("touch", onObjectTouch); end
		for i = gameGroup.numChildren,1,-1 do
			local child = gameGroup[i]
			if child.myName ~= "background" then
				child:removeEventListener("touch", onObjectTouch)
			end
		end
		for i = settingsGroup.numChildren,1,-1 do
			local child = settingsGroup[i]
			child.parent:remove( child )
			child = nil
		end
		for i = hudGroup.numChildren,1,-1 do
			local child = hudGroup[i]
			child.parent:remove( child )
			child = nil
		end
		for i = inventoryGroup.numChildren,1,-1 do
			local child = inventoryGroup[i]
			child.parent:remove( child )
			child = nil
		end
		--]]
				
		-- Stop any timers
		
	end
	
	-- MUST return a display.newGroup()
	return gameGroup
end

