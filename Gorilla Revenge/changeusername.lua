module(..., package.seeall)

--***********************************************************************************************--
--***********************************************************************************************--

-- mainmenu

--***********************************************************************************************--
--***********************************************************************************************--

-- Main function - MUST return a display.newGroup()
function new()
	local menuGroup = display.newGroup()
	
	local ui = require("ui")
	local widget = require "widget"
	local json = require "json"
			
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
	
	local myTableView
	local keyboardIsUp = false
	local textField
	local fakeTextField
	local usernameBackground
	local usernameText
	local usernameText2
	local usernameText3
	
	usernameBackground = display.newRect(0,0,480,320)
	usernameBackground:setFillColor(150,150,150)
	menuGroup:insert(usernameBackground)
	function usernameBackground:touch(event)
		if event.phase == "ended" and keyboardIsUp then
			-- Hide keyboard
			native.setKeyboardFocus( nil )
			keyboardIsUp = false
			transition.to(textField, {time = 200, y = textField.y + 20})
			transition.to(usernameText, {time = 200, y = usernameText.y + 20})
			transition.to(usernameText2, {time = 200, y = usernameText2.y + 20})
			transition.to(usernameText3, {time = 200, y = usernameText3.y + 20})
			if not onDevice then
				transition.to(fakeTextField, {time = 200, y = textField.y + 20})
			end
		end
	end
	usernameBackground:addEventListener("touch", usernameBackground)
	
	local function drawScreen()
		--
		usernameText = display.newText("Your username has been deemed inappropriate.", 0,0, "helvetica", 20)
		usernameText.x = 240; usernameText.y = 40
		menuGroup:insert(usernameText)
		usernameText2 = display.newText("Please enter a new username to continue.", 0,0, "helvetica", 20)
		usernameText2.x = 240; usernameText2.y = 70
		menuGroup:insert(usernameText2)
		usernameText3 = display.newText("(Continued innapropriate usernames will lead to a termination without refund)", 0,0, "helvetica", 12)
		usernameText3.x = 240; usernameText3.y = 100
		menuGroup:insert(usernameText3)
		
		-- Handle the textField keyboard input
		--
		local function fieldHandler( event )
			--
			if ( "began" == event.phase ) then
				keyboardIsUp = true
				transition.to(textField, {time = 200, y = textField.y - 20})
				transition.to(usernameText, {time = 200, y = usernameText.y - 20})
				transition.to(usernameText2, {time = 200, y = usernameText2.y - 20})
				transition.to(usernameText3, {time = 200, y = usernameText3.y - 20})
				if not onDevice then
					transition.to(fakeTextField, {time = 200, y = textField.y - 20})
				end
			elseif ( "ended" == event.phase ) then
				-- Hide keyboard
				native.setKeyboardFocus( nil )
				keyboardIsUp = false
				transition.to(textField, {time = 200, y = textField.y + 20})
				transition.to(usernameText, {time = 200, y = usernameText.y + 20})
				transition.to(usernameText2, {time = 200, y = usernameText2.y + 20})
				transition.to(usernameText3, {time = 200, y = usernameText3.y + 20})
				
				if not onDevice then
					transition.to(fakeTextField, {time = 200, y = textField.y + 20})
				end
			elseif ( "submitted" == event.phase ) then
				-- Hide keyboard
				native.setKeyboardFocus( nil )
				keyboardIsUp = false
				transition.to(textField, {time = 200, y = textField.y + 20})
				transition.to(usernameText, {time = 200, y = usernameText.y + 20})
				transition.to(usernameText2, {time = 200, y = usernameText2.y + 20})
				transition.to(usernameText3, {time = 200, y = usernameText3.y + 20})
				if not onDevice then
					transition.to(fakeTextField, {time = 200, y = textField.y + 20})
				end
			end
			--
		end
	
		textField = native.newTextField( 15, 80, 280, 30, fieldHandler )
		textField:setReferencePoint(display.TopLeftReferencePoint)
		textField.x = 240-textField.width/2; textField.y = 120;
		menuGroup:insert(textField)
		
		--FAKE TEXT FIELD
		if onDevice == false then
			fakeTextField = display.newRect(textField.x,textField.y,textField.width, textField.height)
			fakeTextField:setReferencePoint(display.TopLeftReferencePoint)
			menuGroup:insert(fakeTextField)
		end
		
		local saveButton
		local cancelButton
		
		local function onSaveButton (event )
		    if event.phase == "release" then	
					if soundsOn == "yes" then audio.play(clickSound); end
					local usernameValid = true
					local textFieldString = textField.text
					local tempString = textField.text
					if onDevice == false then
						textFieldString = "Simulator"
						tempString = textFieldString
					end
					tempString = tempString:lower()
					tempString = tempString .. "#"
					
					local i = 1
					while(tempString:sub(i,i) ~= "#" and usernameValid)do
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
							letter ~= "_" then
							
							usernameValid = false
						end
						i = i+1
					end
				
					
					local function networkListener( event )
					    if ( event.isError ) then
				            print( "Network error!")
							native.showAlert("Error", "An error has occurred, please make sure you are connected to the internet and try again.", {"Ok"})
				        else
				            print ( "RESPONSE: " .. event.response )
							if event.response == "Post Successful." then
								local function onOkTouch(event)
									director:changeScene("mainmenu")
								end
								if onDevice then
									saveValue("username.data", textField.text)
								else
									saveValue("username.data", "Simulator")
								end
								native.showAlert("Thanks, your username has been added successfully.", "", {"Ok"}, onOkTouch)
							elseif event.response == "username_taken" then
								native.showAlert("That username is already in use, please try again.", "", {"Ok"})
							else
								native.showAlert("Error", "An error has occurred, please make sure you are connected to the internet and try again.", {"Ok"})
							end
				        end
					end

					local postData = "username=" .. textFieldString
					local params = {}
					params.body = postData

					if usernameValid == false then
						native.showAlert("Special Characters", "Special characters are not allowed, please edit your username and try again.", {"Ok"})
					elseif (onDevice and textField.text ~= "") or onDevice == false then
						network.request( "http://chaluxeapps.com/apps/gorilla_revenge/add_user.php", "POST", networkListener, params )
					else
						native.showAlert("Empty Field", "Please enter a username to continue.", {"Ok"})
					end
					
	        end
	    end
		saveButton = widget.newButton{
	        id = "savebutton",
	        x = 270,
	        y = 240,
	        label = "  Save  ",
	        onEvent = onSaveButton
	    }
		menuGroup:insert(saveButton.view)
		local function onCancelButton (event )
		    if event.phase == "release" then
				if soundsOn == "yes" then audio.play(clickSound); end
				director:changeScene("mainmenu")
	        end
	    end
		cancelButton = widget.newButton{
	        id = "cancelbutton",
	        x = 140,
	        y = 240,
	        label = "Cancel",
	        onEvent = onCancelButton
	    }
		menuGroup:insert(cancelButton.view)		
		--
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
		
		--[[REMOVE everything in other groups
		for i = buttonsGroup.numChildren,1,-1 do
			local child = buttonsGroup[i]
			child.parent:remove( child )
			child = nil
		end
		--]]
		
		-- REMOVE EVENT LISTENERS
		Runtime:removeEventListener("system", onSystem)
		usernameBackground:removeEventListener("touch", usernameBackground)
		
	end
	
	-- MUST return a display.newGroup()
	return menuGroup
end
