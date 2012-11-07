module(..., package.seeall)

--***********************************************************************************************--
--***********************************************************************************************--

-- leveleditormenu.lua

--***********************************************************************************************--
--***********************************************************************************************--

-- Main function - MUST return a display.newGroup()
function new()
	local menuGroup = display.newGroup()
	local buttonsGroup = display.newGroup()
	
	local ui = require("ui")
	local widget = require "widget"
	local json = require "json"
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
	
	--SOUNDS
	local clickSound = audio.loadSound("sounds/clicksound.caf")
	local backgroundMusic = audio.loadStream("sounds/rock.mp3")
	
	if musicOn == "yes" and audio.usedChannels == 0 then
		audio.stop()
		audio.play(backgroundMusic, {loops = -1})
		audio.setVolume(1)
	end
	
	--GLOBALS
	local myTableView
	local posting = false
	local fullVersion = loadValue("full-version-purchased") == "yes"
	
	if not onDevice then
		fullVersion = true
	end
	
	local function drawScreen()
		
		local showInstructionsAlert = true
		local numberOfSavedLevels = table.maxn(json.decode(loadValue("saved-levels-table.data")))
		
		if numberOfSavedLevels > 0 and loadValue("show-how-to-delete.data") == "0" then
			-- Show alert with one buttons
			local alert = native.showAlert( "New Level Created", "Congrats on creating your first level! To delete a level, simply swipe it's row to the right.", { "OK" } )
			saveValue("show-how-to-delete.data", "nomore")
		end
		
		--THE TABLE VIEW--
		local function onItemRelease( event )
			if posting == false then
				if soundsOn == "yes" then audio.play(clickSound); end
				if event.target.id == 2 then
					--create new level from scratch
					transition.to(buttonsGroup, {time = 500, x = buttonsGroup.x-480})
					--
					local untitledCounter = loadValue("untitled-counter.data")
					untitledCounter = untitledCounter + 1
					saveValue("untitled-counter.data", untitledCounter)
					saveValue("loaded-level-name.data", "untitled" .. untitledCounter)
				else
					local id = event.target.id - 4
					--
					if id == 0 then
						if loadValue("there-is-a-most-recent.data") == "yes" then
							local levelToLoad = loadValue("templevel.data")
							local untitledCounter = loadValue("untitled-counter.data")
							untitledCounter = untitledCounter + 1
							saveValue("untitled-counter.data", untitledCounter)
							saveValue("loaded-level-name.data", "untitled" .. untitledCounter)
							saveValue("new-or-load.data", "load")
							saveValue("level-to-load.data", levelToLoad)
							director:changeScene("loadleveleditor")
						else
							native.showAlert(": /", "There is no recent level to load because you have yet to create one. Once you have edited a new level, the most recent one will be temporarily saved here as a draft.", {" Ok "})
						end
				
					else
						local savedLevelsTable = json.decode(loadValue("saved-levels-table.data"))
						if table.maxn(savedLevelsTable) >= id then
							id = table.maxn(savedLevelsTable)+1-id
							local levelToLoad = savedLevelsTable[id]
							saveValue("loaded-level-name.data", loadValue("created-level-" .. id .. "-name.data"))
							saveValue("new-or-load.data", "load")
							saveValue("level-to-load.data", levelToLoad)
							director:changeScene("loadleveleditor")
						end
					end
					--
				end
			end
		end
		--
		local function onRightSwipeListener( event )
			if posting == false then
				if soundsOn == "yes" then audio.play(clickSound); end
				local function onDeletePress(event2)
					if soundsOn == "yes" and event2.action == "clicked" then audio.play(clickSound); end
					if event2.index == 2 then -- DELETE
						local savedLevelsTable = json.decode(loadValue("saved-levels-table.data"))
					    local id = table.maxn(savedLevelsTable)+5 - event.target.id

						table.remove(savedLevelsTable, id)
						myTableView:deleteRow( event.target )
						saveValue("saved-levels-table.data", json.encode(savedLevelsTable))

						for i=id,table.maxn(savedLevelsTable) do
							saveValue("created-level-" .. i .. "-name.data", loadValue("created-level-" .. (i+1) .. "-name.data"))
							saveValue("created-level-" .. i .. "-date.data", loadValue("created-level-" .. (i+1) .. "-date.data"))
						end					
					end
				end

				native.showAlert("Are You Sure?", "Are you sure you would like to delete this level?", {"Cancel", "Delete"}, onDeletePress)
			end
		
		    return true
		end
		--
		local function onLeftSwipeListener(event)
			if posting == false then
				if soundsOn == "yes" then audio.play(clickSound); end
				
				if fullVersion then
					if loadValue("username.data") == "0" then
						director:changeScene("getusername")
					else
						
						local savedLevelsTable = json.decode(loadValue("saved-levels-table.data"))
					    local id = table.maxn(savedLevelsTable)+5 - event.target.id

						local function onShareAlertTouch(event)
							if soundsOn == "yes" and event.action == "clicked" then audio.play(clickSound); end
							if event.index == 2 then -- SHARE WITH GLOBAL
								posting = true
								local loadingScreen = display.newRoundedRect(0,0,400,250,12)
								loadingScreen.x = 240; loadingScreen.y = 160;
								loadingScreen:setFillColor(0,0,0,255)
								menuGroup:insert(loadingScreen)
								local loadingText2 = display.newText("Posting..", 0,0,"helvetica",30)
								loadingText2.x = 240; loadingText2.y = 161;
								loadingText2:setTextColor(50,50,50,255)
								menuGroup:insert(loadingText2)
								local loadingText = display.newText("Posting..", 0,0,"helvetica",30)
								loadingText.x = 240; loadingText.y = 160;
								loadingText:setTextColor(255,255,255,255)
								menuGroup:insert(loadingText)

								loadingScreen.alpha = 0
								loadingText.alpha = 0
								loadingText2.alpha = 0

								transition.to(loadingScreen, {time = 200, alpha = .8})
								transition.to(loadingText, {time = 200, alpha = 1})
								transition.to(loadingText2, {time = 200, alpha = 1})
								
								
								local function networkListener8( event8 )
								    if ( event8.isError ) then
							            print( "Network error!")
										native.showAlert("Error", "An error has occurred, please make sure you are connected to the internet and try again.", {"Ok"})
							        else
							            print ( "RESPONSE: " .. event8.response )
										if event8.response == "valid" then
											local function networkListener2( event )							
											    if ( event.isError ) then
										            print( "Network error!")
													posting = false
													loadingScreen:removeSelf()
													loadingText:removeSelf()
													loadingText2:removeSelf()
													native.showAlert("Error", "An error has occurred, please make sure you are connected to the internet and try again.", {"Ok"})
										        else
										            print ( "RESPONSE: " .. event.response )
													if event.response == "ok to post" then -- post level
														local function networkListener( event )
														    if ( event.isError ) then
													            print( "Network error!")
																posting = false
																loadingScreen:removeSelf()
																loadingText:removeSelf()
																loadingText2:removeSelf()
																native.showAlert("Error", "An error has occurred, please make sure you are connected to the internet and try again.", {"Ok"})
													        else
													            print ( "RESPONSE: " .. event.response )
																if event.response == "Post Successful." then
																	posting = false
																	loadingScreen:removeSelf()
																	loadingText:removeSelf()
																	loadingText2:removeSelf()
																	native.showAlert("Post Successful.", "", {"Ok"})
																else
																	native.showAlert("Error", "An error has occurred, please make sure you are connected to the internet and try again.", {"Ok"})
																end
													        end
														end
														local levelString = savedLevelsTable[id]
														local postData = "name=" .. loadValue("created-level-" .. id .. "-name.data") .. "&username=" .. loadValue("username.data") .. "&level=" .. levelString .. "&date=" .. string.format("%d", os.time())
														local params = {}
														params.body = postData
														network.request( "http://chaluxeapps.com/apps/gorilla_revenge/post_level.php", "POST", networkListener, params )
													else -- warn about too soon to post
														posting = false
														loadingScreen:removeSelf()
														loadingText:removeSelf()
														loadingText2:removeSelf()
														native.showAlert("Sorry", "To avoid over-posting, users must wait at least five minutes between posts.", {"Ok"})
													end
										        end
											end

											local postData2 = "username=" .. loadValue("username.data") .. "&name=" .. loadValue("created-level-" .. id .. "-name.data")
											local params2 = {}
											params2.body = postData2
											network.request( "http://chaluxeapps.com/apps/gorilla_revenge/get_last_post_date.php", "POST", networkListener2, params2 )
										else
											director:changeScene("changeusername")
										end
							        end
								end

								local postData8 = "username=" .. loadValue("username.data")
								local params8 = {}
								params8.body = postData8

								network.request( "http://chaluxeapps.com/apps/gorilla_revenge/is_user_valid.php", "POST", networkListener8, params8 )
								
								
								
								

								
								------------------------------------------------------------------------------------------------------------------
							end
						end

						native.showAlert("Share", "Are you sure you would like to share this level?", {"Cancel", "Share"}, onShareAlertTouch)
					end
				else
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
		
			return true
		end
	    --
		local totalLevels = table.maxn(json.decode(loadValue("saved-levels-table.data")))
	
	    local itemData = {
	        ----------------------------------------------------------
	        {
	            -- CATEGORY (just one key)
	            categoryName = "New Level"
	        },
	        ----------------------------------------------------------
	        {
	            -- CREATE NEW LEVEL BUTTON:
	            title = { label = "Create New Level.." },
	            subtitle = { label = "Create a new level from scratch." },
	            onRelease = onItemRelease,
	            hideArrow = true
	        },
			----------------------------------------------------------
	        {
	            -- CATEGORY (just one key)
	            categoryName = "Load Level"
	        },
	        ----------------------------------------------------------
			{
	            -- CREATE NEW LEVEL BUTTON:
	            title = { label = "Most Recent" },
	            subtitle = { label = "You're last edited level." },
	            onRelease = onItemRelease,
	            hideArrow = true
	        },
			----------------------------------------------------------
	    }
		
		--ADD ALL OF THE CURRENT SAVED LEVELS
		if fullVersion then
			for i=totalLevels,1,-1 do
				local filename = loadValue("created-level-" .. i .. "-name.data")
				if filename == "" then 
					local untitledCounter = loadValue("untitled-counter.data")
					untitledCounter = untitledCounter + 1
					saveValue("untitled-counter.data", untitledCounter)
					filename = "untitled" .. untitledCounter
					saveValue("created-level-" .. i .. "-name.data", filename)
				end
				local dateValue = loadValue("created-level-" .. i .. "-date.data")

				table.insert(itemData, 
				{
		            -- CREATE NEW LEVEL BUTTON:
		            title = { label = filename },
		            subtitle = { label = dateValue .. " - Swipe right to delete - Swipe left to share" },
		            onRelease = onItemRelease,
		            onRightSwipe = onRightSwipeListener,
					onLeftSwipe = onLeftSwipeListener,
		            hideArrow = true
		        }
				)
			end
		else
			for i=totalLevels,1,-1 do
				local filename = loadValue("created-level-" .. i .. "-name.data")
				if filename == "" then 
					local untitledCounter = loadValue("untitled-counter.data")
					untitledCounter = untitledCounter + 1
					saveValue("untitled-counter.data", untitledCounter)
					filename = "untitled" .. untitledCounter
					saveValue("created-level-" .. i .. "-name.data", filename)
				end
				local dateValue = loadValue("created-level-" .. i .. "-date.data")

				table.insert(itemData, 
				{
		            -- CREATE NEW LEVEL BUTTON:
		            title = { label = filename },
		            subtitle = { label = dateValue .. " - Right to delete - Left for Full Version" },
		            onRelease = onItemRelease,
		            onRightSwipe = onRightSwipeListener,
					onLeftSwipe = onLeftSwipeListener,
		            hideArrow = true
		        }
				)
			end
		end
		
		--ADD EMPTY LEVELS,, NOT FULL VERSION GOES FIRST HERE
		if not fullVersion then
			for i=1,3-totalLevels do
				table.insert(itemData, 
				{
		            -- CREATE EMPTY CELL BUTTON:
		            title = { label = "Empty" },
		            subtitle = { label = "Create a level to populate this item." },
		            hideArrow = true
		        }
				)
			end
			for i=1,10-totalLevels-3 do
				table.insert(itemData, 
				{
		            -- CREATE EMPTY CELL BUTTON:
		            title = { label = " " },
		            subtitle = { label = " " },
		            hideArrow = true
		        }
				)
			end
		else
			for i=1,20-totalLevels do
				table.insert(itemData, 
				{
		            -- CREATE EMPTY CELL BUTTON:
		            title = { label = "Empty" },
		            subtitle = { label = "Create a level to populate this item." },
		            hideArrow = true
		        }
				)
			end
		end
		
		
		-------
	    --
	    myTableView = widget.newTableView{ width = 480, y = 70, height=200,  rowHeight = 60 }
	    -- populate list from table:
	    myTableView:sync( itemData )
		buttonsGroup:insert(myTableView.view)	
		-----------------------------------------------------------------------------------
		-- BACKGROUND-UPPER
		local backgroundUpper = display.newImageRect("images/leveleditormenu-upper.png",483,71)
		backgroundUpper.x = 239; backgroundUpper.y = 34;
		menuGroup:insert(backgroundUpper)
		-----------------------------------
		-- BACKGROUND-LOWER
		local backgroundLower = display.newImageRect("images/leveleditormenu-lower.png",483,70)
		backgroundLower.x = 239; backgroundLower.y = 300;
		menuGroup:insert(backgroundLower)
		
		
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
	
		local welcomeScreen = display.newRect(480,0,480,320)
		welcomeScreen:setFillColor(120,120,120)
		buttonsGroup:insert(welcomeScreen)
		local welcomeText = display.newText("To get started,", 0,0,"helvetica",30)
		welcomeText:setReferencePoint(display.CenterTopReferencePoint)
		welcomeText.x = 720; welcomeText.y = 100;
		buttonsGroup:insert(welcomeText)
		local welcomeText2 = display.newText("please select a level size.", 0,0,"helvetica",30)
		welcomeText2:setReferencePoint(display.CenterTopReferencePoint)
		welcomeText2.x = 720; welcomeText2.y = 140;
		buttonsGroup:insert(welcomeText2)

		local mediumBtn
		local largeBtn

		--MEDIUM NEW LEVEL BUTTON --
		local function onWelcomeButton( event )
			if event.phase == "release" then
				if soundsOn == "yes" then audio.play(clickSound); end
				if event.id == "largebutton" then
					saveValue("levelsize.data", "l")
				elseif event.id == "mediumbutton" then
					saveValue("levelsize.data", "m")
				end
				saveValue("new-or-load.data", "new")
				director:changeScene("loadleveleditor")
			end
		end
		mediumBtn = ui.newButton{
			defaultSrc = "images/medium-button-rounded.png",
			defaultX = 100,
			defaultY = 40,
			overSrc = "images/medium-button-rounded-pressed.png",
			overX = 100,
			overY = 40,
			onEvent = onWelcomeButton,
			id = "mediumbutton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		mediumBtn.x = 190+480; mediumBtn.y = 200;
		buttonsGroup:insert( mediumBtn )
		-- LARGE NEW LEVEL BUTTON BUTTON
		largeBtn = ui.newButton{
			defaultSrc = "images/large-button.png",
			defaultX = 100,
			defaultY = 40,
			overSrc = "images/large-button-pressed.png",
			overX = 100,
			overY = 40,
			onEvent = onWelcomeButton,
			id = "largebutton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		largeBtn.x = mediumBtn.x+101; largeBtn.y = mediumBtn.y;
		buttonsGroup:insert( largeBtn )
		-- END BUTTON

		menuGroup:toBack()
		buttonsGroup:toBack()
		
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
			native.showAlert("Success!", "Full Version Purchased Successfully!", {"Ok"}, myAlertListener)
		elseif transaction.state == "restored" then
			print("Transaction Restored.")
			saveValue("full-version-purchased", "yes")
			native.showAlert("Success!", "Full Version has been restored.", {"Ok"}, myAlertListener)
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
	
		display.remove(myTableView)
		myTableView = nil
				
		--REMOVE everything in other groups
		for i = buttonsGroup.numChildren,1,-1 do
			local child = buttonsGroup[i]
			child.parent:remove( child )
			child = nil
		end
		--]]
		
		-- REMOVE EVENT LISTENERS
		Runtime:removeEventListener("system", onSystem)
	end
	
	-- MUST return a display.newGroup()
	return menuGroup
end
