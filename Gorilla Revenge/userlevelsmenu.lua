module(..., package.seeall)

--***********************************************************************************************--
-- userlevelsmenu.lua
--***********************************************************************************************--

-- Main function - MUST return a display.newGroup()
function new()
	local tabGroupNew = display.newGroup()
	local tabGroupTop = display.newGroup()
	local tabGroupSearch = display.newGroup()
	local tabGroupSearchField = display.newGroup()
	local tabGroupMyLevels = display.newGroup()
	local menuGroup = display.newGroup()
	local backgroundGroup = display.newGroup()
	
	local ui = require("ui")
	local widget = require "widget"
	local json = require "json"
	local facebook = require "facebook"
			
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
	
	--***************************************************
	-- connectHandler() --> used for facebook posting
	--***************************************************
	local function connectHandler( event )
		local post = "Just created a level on Gorilla Revenge."
		
		local session = event.sender
		if ( session:isLoggedIn() ) then
	
			print( "fbStatus " .. session.sessionKey )
			
			local scoreStatusMessage = "I just posted a level on Gorilla Revenge. Download Gorilla Revenge on iPhone and search my username, \"" .. loadValue("username.data") .. "\", to check it out!"			
			
			local attachment = {
				name="Download Gorilla Revenge To Create Your Own.",
				caption="Lead your gorilla out of danger with Gorilla Revenge.",
				href="http://itunes.apple.com/us/app/gorilla-revenge/id461182384?ls=1&mt=8",--LINK TO ITUNES APP			    LINK TO ITUNES APP
				media= { { type="image", src="http://chaluxeapps.com/favicon.ico", href="http://itunes.apple.com/us/app/gorilla-revenge/id461182384?ls=1&mt=8" } }
			}									    --LINK TO 90X90 ICON
	
			local response = session:call{
				message = scoreStatusMessage,
				method ="stream.publish",
				attachment = json.encode(attachment),
				action_links = json.encode(action_links),
			}
	
			if "table" == type(response ) then
				-- print contents of response upon failure
				printTable( response, "fbStatus response:", 5 )
			end
			
			native.showAlert( "Gorilla Revenge", "Your level has been posted to Facebook.", { "Ok" } )
		end
	end
	----------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------
	
	--MUSIC SETTINGS
	local musicOn = loadValue("music.data")
	local soundsOn = loadValue("sounds.data")
	
	--SOUNDS
	local clickSound = audio.loadSound("sounds/clicksound.caf")
	local backgroundMusic = audio.loadStream("sounds/rock.mp3")
	
	if musicOn == "yes" and audio.usedChannels == 0 then
		audio.stop()
		audio.play(backgroundMusic, {loops = -1})
	end
	
	-- GLOBALS
	local tableViewNew
	local tableViewTop
	local tableViewSearch
	local tableViewMyLevels
	local onTabBarTouch
	local newBtn
	local newBtnPressed
	local topBtn
	local topBtnPressed
	local searchBtn
	local searchBtnPressed
	local myLevelsBtn
	local myLevelsBtnPressed
	local loadingScreen = display.newRect(0,0, 480, 320)
	backgroundGroup:insert(loadingScreen)
	local loadingText = display.newText("Loading..", 220, 150, "helvetica", 20)
	loadingText.x = 240; loadingText.y = 160;
	loadingText:setTextColor(0,0,0)
	backgroundGroup:insert(loadingText)
	local tabBarTouched = false
	local levelsList = {}
	local levelsListIds = {}
	local myLevelsNames = {}
	local itemData = {}
	local onNewRelease
	local onTopRelease
	local onSearchRelease
	local onMyLevelsRelease
	local onMyLevelsLeftSwipe
	local onMyLevelsRightSwipe
	local lastTab = loadValue("last-tab.data")
	local keyboardIsUp = false
	local textField
	local has25MoreButton = false
	
	
	local function drawScreen()
		--SHOW WELCOME SCREEN FOR FIRST TIMER
		if loadValue("user-levels-first-time.data") == "0" then
			-- Show alert
			native.showAlert( "Welcome", "Welcome to the user created levels interface. Here you can view levels created from users across the world.", { "Ok" } )
			saveValue("user-levels-first-time.data", "no")
		end
		
		local function newNetworkListener( event )
			if newBtnPressed.isVisible then
				if ( event.isError ) then
		            print( "Network error!")
					native.showAlert("Error", "An error has occurred, please make sure you are connected to the internet and try again.", {"Ok"})
		        else		
					local responseTable = json.decode(event.response)

					--clear the itemData table
					for j = table.maxn(itemData), 1, -1 do
						table.remove(itemData, j)
					end

					table.insert(itemData,{
			            categoryName = "New Levels"
			        })

					local numberOfLevels = 0
					has25MoreButton = false

					for i=1, table.maxn(responseTable) do
						numberOfLevels = numberOfLevels + 1
						local levelInfoTable = responseTable[i]
						--
						table.insert(itemData, 
						{
				            -- CREATE NEW LEVEL BUTTON:
				            title = { label = levelInfoTable['name'] },
				            subtitle = { label = "By: " ..  levelInfoTable['username']},
				            onRelease = onNewRelease,
				            hideArrow = true
				        })

						levelsList[i+1] = levelInfoTable['level']
						print(levelsList[i+1])
						levelsListIds[i+1] = levelInfoTable['id']
						--
					end
			        -- 25 more..
					if numberOfLevels > 24 then
						has25MoreButton = true
						table.insert(itemData, 
						{
				            title = { label = "Twenty Five More..." },
				            --subtitle = { label = ""},
				            onRelease = onNewRelease,
				            hideArrow = true
				        })	
					end
					
					for i=1,10-numberOfLevels do
						table.insert(itemData, 
						{
				            -- CREATE EMPTY CELL BUTTON:
				            title = { label = " " },
				            hideArrow = true
				        }
						)
					end

					tableViewNew:sync(itemData)

					tabGroupNew.isVisible = true

		        end
			end
		end

		local function newNetworkListener25More( event )
			if newBtnPressed.isVisible then
		    	if ( event.isError ) then
		            print( "Network error!")
					native.showAlert("Error", "An error has occurred, please make sure you are connected to the internet and try again.", {"Ok"})
		        else
					local responseTable = json.decode(event.response)
				
					--clear the 25 more item
					table.remove(itemData)
				
					local numberOfLevels = 0
				
					for i=1, table.maxn(responseTable) do
						numberOfLevels = numberOfLevels + 1
						local levelInfoTable = responseTable[i]
						--
						table.insert(itemData, 
						{
				            -- CREATE NEW LEVEL BUTTON:
				            title = { label = levelInfoTable['name'] },
				            subtitle = { label = "By: " ..  levelInfoTable['username']},
				            onRelease = onNewRelease,
				            hideArrow = true
				        })
			
						table.insert(levelsList, levelInfoTable['level'])
						table.insert(levelsListIds, levelInfoTable['id'])
						--
					end
			        -- 25 more..
					if numberOfLevels > 24 then
						table.insert(itemData, 
						{
				            title = { label = "Twenty Five More..." },
				            --subtitle = { label = ""},
				            onRelease = onNewRelease,
				            hideArrow = true
				        })
					end
				
					tableViewNew:sync(itemData)
		        end
			end
		end
		
		local function topNetworkListener( event )
			if topBtnPressed.isVisible then
		    	if ( event.isError ) then
		            print( "Network error!")
					native.showAlert("Error", "An error has occurred, please make sure you are connected to the internet and try again.", {"Ok"})
		        else
					local responseTable = json.decode(event.response)
				
					--clear the itemData table
					for j = table.maxn(itemData), 1, -1 do
						table.remove(itemData, j)
					end
				
					table.insert(itemData,{
			            categoryName = "Top 25"
			        })
		
					local numberOfLevels = 0
					has25MoreButton = false
				
					for i=1, table.maxn(responseTable) do
						numberOfLevels = numberOfLevels + 1
						local levelInfoTable = responseTable[i]
						--
						table.insert(itemData, 
						{
				            -- CREATE NEW LEVEL BUTTON:
				            title = { label = levelInfoTable['name'] },
				            subtitle = { label = "By: " ..  levelInfoTable['username']},
				            onRelease = onTopRelease,
				            hideArrow = true
				        })
			
						levelsList[i+1] = levelInfoTable['level']
						levelsListIds[i+1] = levelInfoTable['id']
						--
					end
			        -- 25 more..
					if numberOfLevels > 24 then
						has25MoreButton = true
						table.insert(itemData, 
						{
				            title = { label = "Twenty Five More..." },
				            --subtitle = { label = ""},
				            onRelease = onTopRelease,
				            hideArrow = true
				        })
					end
				
					for i=1,10-numberOfLevels do
						table.insert(itemData, 
						{
				            -- CREATE EMPTY CELL BUTTON:
				            title = { label = " " },
				            hideArrow = true
				        }
						)
					end
				
					tableViewTop:sync(itemData)
				
					tabGroupTop.isVisible = true
				
		        end
			end
		end
		
		local function topNetworkListener25More( event )
			if topBtnPressed.isVisible then
		    	if ( event.isError ) then
		            print( "Network error!")
					native.showAlert("Error", "An error has occurred, please make sure you are connected to the internet and try again.", {"Ok"})
		        else
					local responseTable = json.decode(event.response)
			
					--clear the 25 more item
					table.remove(itemData)
			
					local numberOfLevels = 0
			
					for i=1, table.maxn(responseTable) do
						numberOfLevels = numberOfLevels + 1
						local levelInfoTable = responseTable[i]
						--
						table.insert(itemData, 
						{
				            -- CREATE NEW LEVEL BUTTON:
				            title = { label = levelInfoTable['name'] },
				            subtitle = { label = "By: " ..  levelInfoTable['username']},
				            onRelease = onTopRelease,
				            hideArrow = true
				        })
		
						table.insert(levelsList, levelInfoTable['level'])
						table.insert(levelsListIds, levelInfoTable['id'])
						--
					end
			        -- 25 more..
					if numberOfLevels > 24 then
						table.insert(itemData, 
						{
			            	title = { label = "Twenty Five More..." },
			            	--subtitle = { label = ""},
			            	onRelease = onTopRelease,
			            	hideArrow = true
			        	})
					end
			
					tableViewNew:sync(itemData)
		        end
			end
		end
		
		local function searchNetworkListener( event )
			if searchBtnPressed.isVisible then
		    	if ( event.isError ) then
		            print( "Network error!")
					native.showAlert("Error", "An error has occurred, please make sure you are connected to the internet and try again.", {"Ok"})
		        else		
					local responseTable = json.decode(event.response)
				
					tabGroupSearch.isVisible = false
				
					--clear the itemData table
					for j = table.maxn(itemData), 1, -1 do
						table.remove(itemData, j)
					end
				
					table.insert(itemData,{
			            categoryName = "Search Results"
			        })
				
					local numberOfLevels = 0
					for i=1, table.maxn(responseTable) do
						numberOfLevels = numberOfLevels + 1
						local levelInfoTable = responseTable[i]
						--
						table.insert(itemData, 
						{
				            title = { label = levelInfoTable['name'] },
				            subtitle = { label = "By: " ..  levelInfoTable['username']},
				            onRelease = onSearchRelease,
				            hideArrow = true
				        })
			
						levelsList[i+1] = levelInfoTable['level']
						levelsListIds[i+1] = levelInfoTable['id']
						--
					end
				
					
					tabGroupSearch.isVisible = true
					textField.isVisible = true
				
					if numberOfLevels == 0 then
						tabGroupSearch.isVisible = false
						loadingText.text = "No Matches"
					else
						tabGroupSearch.isVisible = true
						for i=1,10-numberOfLevels do
							table.insert(itemData, 
							{
					            -- CREATE EMPTY CELL BUTTON:
					            title = { label = " " },
					            hideArrow = true
					        }
							)
						end
					end
					
					tableViewSearch:sync(itemData)
				
		        end
			end
		end
		
		local function myLevelsNetworkListener( event )
			if myLevelsBtnPressed.isVisible then
		    	if ( event.isError ) then
		            print( "Network error!")
					native.showAlert("Error", "An error has occurred, please make sure you are connected to the internet and try again.", {"Ok"})
		        else		
					local responseTable = json.decode(event.response)
				
					--clear the itemData table
					for j = table.maxn(itemData), 1, -1 do
						table.remove(itemData, j)
					end
				
					table.insert(itemData,{
			            categoryName = "My Levels"
			        })
				
					local numberOfLevels = 0
					for i=1, table.maxn(responseTable) do
						numberOfLevels = numberOfLevels + 1
						local levelInfoTable = responseTable[i]
						--
						table.insert(itemData, 
						{
				            -- CREATE NEW LEVEL BUTTON:
				            title = { label = levelInfoTable['name'] },
				            subtitle = { label = "Up: " .. levelInfoTable['up_votes'] .. ", Down: " .. levelInfoTable['down_votes'] .. " - Left to upload to Facebook - Right to delete"},
				            onRelease = onMyLevelsRelease,
							onLeftSwipe = onMyLevelsLeftSwipe,
							onRightSwipe = onMyLevelsRightSwipe,
				            hideArrow = true
				        })
						
						myLevelsNames[i+1] = levelInfoTable['name']
						levelsList[i+1] = levelInfoTable['level']
						levelsListIds[i+1] = levelInfoTable['id']
						--
					end
				
					tabGroupMyLevels.isVisible = true
				
					if numberOfLevels == 0 then
						tabGroupMyLevels.isVisible = false
						loadingText.text = "Submit a level and see it here."
					else
						for i=1,10-numberOfLevels do
							table.insert(itemData, 
							{
					            -- CREATE EMPTY CELL BUTTON:
					            title = { label = " " },
					            hideArrow = true
					        }
							)
						end
					end
					
					tableViewMyLevels:sync(itemData)
					
		        end
			end
		end
		----------------------------------
		onNewRelease = function(event)
		if soundsOn == "yes" then audio.play(clickSound); end
			local id = event.target.id
			if id == table.maxn(itemData) and has25MoreButton then
				local postData = "limit=" .. table.maxn(itemData)-2
				local params = {}
				params.body = postData
				network.request( "http://chaluxeapps.com/apps/gorilla_revenge/get_new_levels.php", "POST", newNetworkListener25More, params)
			else
				saveValue("level-to-load.data", levelsList[id])
				saveValue("loaded-level-sql-id.data", levelsListIds[id])
				director:changeScene("loaduserlevelslevel")
			end
		end
		----------------------------------
		onTopRelease = function(event)
		if soundsOn == "yes" then audio.play(clickSound); end
			local id = event.target.id	
			if id == table.maxn(itemData) and has25MoreButton then
				local postData = "limit=" .. table.maxn(itemData)-2
				local params = {}
				params.body = postData
				network.request( "http://chaluxeapps.com/apps/gorilla_revenge/get_top_25.php", "POST", topNetworkListener25More, params)
			else
				saveValue("level-to-load.data", levelsList[id])
				saveValue("loaded-level-sql-id.data", levelsListIds[id])
				director:changeScene("loaduserlevelslevel")
			end
		end
		----------------------------------
		onSearchRelease = function(event)
		if soundsOn == "yes" then audio.play(clickSound); end
			local id = event.target.id
			saveValue("level-to-load.data", levelsList[id])
			saveValue("loaded-level-sql-id.data", levelsListIds[id])
			director:changeScene("loaduserlevelslevel")
		end
		----------------------------------
		onMyLevelsRelease = function(event)
		if soundsOn == "yes" then audio.play(clickSound); end
			local id = event.target.id
			saveValue("level-to-load.data", levelsList[id])
			saveValue("loaded-level-sql-id.data", levelsListIds[id])
			director:changeScene("loaduserlevelslevel")
		end
		onMyLevelsLeftSwipe = function(event)
			if soundsOn == "yes" then audio.play(clickSound); end
			local id = event.target.id
				local facebookListener = function( event )			
					if ( "session" == event.type ) then
						-- upon successful login, update their status
						if ( "login" == event.phase ) then

							score = comma_value(score)

							local theMessage = "I just posted a level on Gorilla Revenge called \"" .. myLevelsNames[id] .. "\". Download Gorilla Revenge on iPhone and search my username, \"" .. loadValue("username.data") .. "\", to play it!"

							--the actual facebook post once logged in
							facebook.request( "me/feed", "POST", {
								message = theMessage, 
								name="Download Gorilla Revenge to Create Your Own!", 
								caption="Create your own level and vote on your friends' levels with Gorilla Revenge.",
								link="http://itunes.apple.com/us/app/gorilla-revenge/id461182384?ls=1&mt=8",
								--picture="icon@2x.png"
							})

							native.showAlert("Success", "Post Successful.", {"Ok"})

						end
					end
				end
				-- replace below with your Facebook App ID
				facebook.login( "257649424258254", facebookListener, { "publish_stream" } )
		end
		onMyLevelsRightSwipe = function(event)
		if soundsOn == "yes" then audio.play(clickSound); end
			local id = event.target.id
			
			local function onDeletePress(event2)
				if soundsOn == "yes" then audio.play(clickSound); end
				if event2.index == 2 then -- DELETE
					
					local postData = "id=" .. levelsListIds[id]
					local params = {}
					params.body = postData
					network.request( "http://chaluxeapps.com/apps/gorilla_revenge/delete_level.php", "POST", params)

					tableViewMyLevels:deleteRow( event.target )
				end
			end
			native.showAlert("Are You Sure?", "Are you sure you would like to delete this level?", {"Cancel", "Delete"}, onDeletePress)
			
		end
	    --------------------------------------
		--TOP TABLE VIEW----------------------
	    tableViewNew = widget.newTableView{ width = 480, height = 208, y = 70, rowHeight = 60, backgroundColor = {220,220,220,255} }
	    tabGroupNew.isVisible = false
		tabGroupNew:insert(tableViewNew.view)
		-- END NEW TABLE VIEW ----------------
		--
		--TOP TABLE VIEW----------------------
	    tableViewTop = widget.newTableView{ width = 480, height = 208, y = 70, rowHeight = 60, backgroundColor = {220,220,220,255} }
		tabGroupTop.isVisible = false
		tabGroupTop:insert(tableViewTop.view)
		-- END TOP TABLE VIEW ----------------
		--
		--SEARCH GROUP------------------------
		tableViewSearch = widget.newTableView{ width = 480, height = 176, y = 100, rowHeight = 60, backgroundColor = {220,220,220,255} }
		tabGroupSearch.isVisible = false
		tabGroupSearchField.isVisible = false
		tabGroupSearch:insert(tableViewSearch.view)
		--
		local function fieldHandler( event )
			--
			if ( "began" == event.phase ) then
				keyboardIsUp = true
			elseif ( "ended" == event.phase ) then
				-- Hide keyboard
				native.setKeyboardFocus( nil )
				keyboardIsUp = false
				saveValue("textfield-text.data", textField.text)
			elseif ( "submitted" == event.phase ) then
				loadingText.text = "Loading.."
				local postData = "search_term=" .. textField.text
				if not onDevice then
					postData = "search_term=Simulator"
				end
				local params = {}
				params.body = postData
				network.request( "http://chaluxeapps.com/apps/gorilla_revenge/get_search_results.php", "POST", searchNetworkListener, params)
				-- Hide keyboard
				native.setKeyboardFocus( nil )
				keyboardIsUp = false
				saveValue("textfield-text.data", textField.text)
			end
			--
		end
		textField = native.newTextField( 0, 70, 480, 30, fieldHandler )
		textField:setReferencePoint(display.TopLeftReferencePoint)
		textField.x = 0; textField.y = 70;
		tabGroupSearchField:insert(textField)
		local loadedTextFieldText = loadValue("textfield-text.data")
		if loadedTextFieldText == "0" or loadedTextFieldText == "" then
			textField.text = "Search"
		else
			textField.text = loadedTextFieldText
		end
		textField.isVisible = false
		--fake textfield
		if onDevice == false then
			local fakeTextField = display.newRect(textField.x,textField.y,textField.width, textField.height)
			fakeTextField:setReferencePoint(display.TopLeftReferencePoint)
			fakeTextField:setFillColor(220,220,220)
			fakeTextField.x = textField.x; fakeTextField.y = textField.y;
			tabGroupSearchField:insert(fakeTextField)
			local fakeTextFieldText = display.newText("Simulator", textField.x, textField.y, "helvetica", 16)
			fakeTextFieldText:setTextColor(0,0,0)
			fakeTextFieldText:setReferencePoint(display.CenterLeftReferencePoint)
			fakeTextFieldText.x = textField.x+10; fakeTextFieldText.y = textField.y+15;
			tabGroupSearchField:insert(fakeTextFieldText)
		end
		-- END SEARCH TABLE VIEW -------------
		--
		--MYLEVELS TABLE VIEW-----------------
	    tableViewMyLevels = widget.newTableView{ width = 480, height = 208, y = 70, rowHeight = 60, backgroundColor = {220,220,220,255} }
		tabGroupMyLevels.isVisible = false
		tabGroupMyLevels:insert(tableViewMyLevels.view)
		-- END MY LEVELS TABLE VIEW ----------
		--
		-- create the start of the tableView depending on last touched
		if lastTab == "mylevels" then
			tabGroupMyLevels.isVisible = true
			table.insert(itemData, {categoryName = "My Levels"})
			local postData = "username=" .. loadValue("username.data")
			local params = {}
			params.body = postData
			network.request( "http://chaluxeapps.com/apps/gorilla_revenge/get_my_levels.php", "POST", myLevelsNetworkListener, params)
		elseif lastTab == "search" then
			tabGroupSearch.isVisible = false
			table.insert(itemData, {categoryName = "Search Results"})
			textField.isVisible = true
			loadingText.text = "Loading.."
			local postData = "search_term=" .. textField.text
			local params = {}
			params.body = postData
			network.request( "http://chaluxeapps.com/apps/gorilla_revenge/get_search_results.php", "POST", searchNetworkListener, params)
		elseif lastTab == "top" then
		    table.insert(itemData, {categoryName = "Top 25"})
			network.request( "http://chaluxeapps.com/apps/gorilla_revenge/get_top_25.php", "GET", topNetworkListener)
		else
		    table.insert(itemData, {categoryName = "New Levels"})
			network.request( "http://chaluxeapps.com/apps/gorilla_revenge/get_new_levels.php", "GET", newNetworkListener)
		end
		-----------------------------------------------------------------------------------
		-- BACKGROUND-UPPER
		local backgroundUpper = display.newImageRect("images/userlevelsmenu-top.png",483,71)
		backgroundUpper.x = 239; backgroundUpper.y = 34;
		menuGroup:insert(backgroundUpper)
		function backgroundUpper:touch(event)
			if event.phase == "began" and keyboardIsUp then
				loadingText.text = "Loading.."
				local postData = "search_term=" .. textField.text
				if not onDevice then
					postData = "search_term=Simulator"
				end
				local params = {}
				params.body = postData
				network.request( "http://chaluxeapps.com/apps/gorilla_revenge/get_search_results.php", "POST", searchNetworkListener, params)
				-- Hide keyboard
				native.setKeyboardFocus( nil )
				keyboardIsUp = false
				saveValue("textfield-text.data", textField.text)
			end
		end
		backgroundUpper:addEventListener("touch", backgroundUpper)
		-----------------------------------
		function loadingScreen:touch(event)
			if event.phase == "began" and keyboardIsUp then
				loadingText.text = "Loading.."
				local postData = "search_term=" .. textField.text
				if not onDevice then
					postData = "search_term=Simulator"
				end
				local params = {}
				params.body = postData
				network.request( "http://chaluxeapps.com/apps/gorilla_revenge/get_search_results.php", "POST", searchNetworkListener, params)
				-- Hide keyboard
				native.setKeyboardFocus( nil )
				keyboardIsUp = false
				saveValue("textfield-text.data", textField.text)
			end
		end
		loadingScreen:addEventListener("touch", loadingScreen)
		-----------------------------------
		
		-- MENU BUTTON --
		local menuBtn
		local onMenuTouch = function( event )
			if event.phase == "release" then
				if soundsOn == "yes" then audio.play(clickSound); end
				director:changeScene("levelchooser")
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
		menuGroup:insert(menuBtn)
		-- END MENU BUTTON --	
		
		----------------------------------------------------------------------------------------------------------------
		--TAB BAR
		----------------------------------------------------------------------------------------------------------------
		local tabBar = display.newImageRect("images/tabbar/tabbar.png", 480, 49)
		tabBar.x = 240; tabBar.y = 295.5
		menuGroup:insert(tabBar)
		
		onTabBarTouch = function(event)
			if event.phase == "began" then
				tabBarTouched = true
			elseif event.phase == "ended" then
				if soundsOn == "yes" then audio.play(clickSound); end
				local id = event.target.id
				tabBarTouched = false
				--
				if id == "newbutton" then-------------------------------
					loadingText.text = "Loading.."
					saveValue("last-tab.data", "new")
					tabGroupNew.isVisible = false
					network.request( "http://chaluxeapps.com/apps/gorilla_revenge/get_new_levels.php", "GET", newNetworkListener)
					newBtn.alpha = 0
					topBtn.alpha = 1
					searchBtn.alpha = 1
					myLevelsBtn.alpha = 1
					newBtnPressed.isVisible = true
					topBtnPressed.isVisible = false
					searchBtnPressed.isVisible = false
					myLevelsBtnPressed.isVisible = false
					--tabGroupNew.isVisible = true
					tabGroupTop.isVisible = false
					tabGroupSearch.isVisible = false
					textField.isVisible = false
					tabGroupMyLevels.isVisible = false
				elseif id == "topbutton" then-----------------------------
					loadingText.text = "Loading.."
					saveValue("last-tab.data", "top")
					tabGroupTop.isVisible = false
					network.request( "http://chaluxeapps.com/apps/gorilla_revenge/get_top_25.php", "GET", topNetworkListener)
					newBtn.alpha = 1
					topBtn.alpha = 0
					searchBtn.alpha = 1
					myLevelsBtn.alpha = 1
					newBtnPressed.isVisible = false
					topBtnPressed.isVisible = true
					searchBtnPressed.isVisible = false
					myLevelsBtnPressed.isVisible = false
					tabGroupNew.isVisible = false
					--tabGroupTop.isVisible = true
					tabGroupSearch.isVisible = false
					textField.isVisible = false
					tabGroupMyLevels.isVisible = false
				elseif id == "searchbutton" then-----------------------------
					loadingText.text = "Loading.."
					saveValue("last-tab.data", "search")
					textField.isVisible = true
					local postData = "search_term=" .. textField.text
					if onDevice == false then
						postData = "search_term=Simulator"
					end
					local params = {}
					params.body = postData
					tabGroupSearch.isVisible = false
					network.request( "http://chaluxeapps.com/apps/gorilla_revenge/get_search_results.php", "POST", searchNetworkListener, params)
					newBtn.alpha = 1
					topBtn.alpha = 1
					searchBtn.alpha = 0
					myLevelsBtn.alpha = 1
					newBtnPressed.isVisible = false
					topBtnPressed.isVisible = false
					searchBtnPressed.isVisible = true
					myLevelsBtnPressed.isVisible = false
					tabGroupNew.isVisible = false
					tabGroupTop.isVisible = false
					tabGroupSearch.isVisible = false
					tabGroupMyLevels.isVisible = false
				elseif id == "mylevelsbutton" then----------------------------
					loadingText.text = "Loading.."
					saveValue("last-tab.data", "mylevels")
					local postData = "username=" .. loadValue("username.data")
					local params = {}
					params.body = postData
					tabGroupMyLevels.isVisible = false
					network.request( "http://chaluxeapps.com/apps/gorilla_revenge/get_my_levels.php", "POST", myLevelsNetworkListener, params)
					newBtn.alpha = 1
					topBtn.alpha = 1
					searchBtn.alpha = 1
					myLevelsBtn.alpha = 0
					newBtnPressed.isVisible = false
					topBtnPressed.isVisible = false
					searchBtnPressed.isVisible = false
					myLevelsBtnPressed.isVisible = true
					tabGroupNew.isVisible = false
					tabGroupTop.isVisible = false
					tabGroupSearch.isVisible = false
					textField.isVisible = false
					--tabGroupMyLevels.isVisible = true
				end------------------------------------------------------------
				--
			end
		end
		local function createTabBarButtons()
			newBtn = display.newImageRect("images/tabbar/new.png", 118, 46)
			newBtn.x = 60; newBtn.y = 299;
			menuGroup:insert(newBtn)
			newBtnPressed = display.newImageRect("images/tabbar/new-pressed.png", 118, 50)
			newBtnPressed.x = 61; newBtnPressed.y = 297;
			menuGroup:insert(newBtnPressed)
			newBtnPressed.isVisible = true
			newBtn.id = "newbutton"
			newBtn:addEventListener("touch", onTabBarTouch)
			--
			topBtn = display.newImageRect("images/tabbar/top25.png", 118, 47)
			topBtn.x = 180; topBtn.y = 298;
			menuGroup:insert(topBtn)
			topBtnPressed = display.newImageRect("images/tabbar/top25-pressed.png", 118, 50)
			topBtnPressed.x = 180; topBtnPressed.y = 297;
			menuGroup:insert(topBtnPressed)
			topBtn.id = "topbutton"
			topBtn:addEventListener("touch", onTabBarTouch)
			--
			searchBtn = display.newImageRect("images/tabbar/search.png", 118, 47)
			searchBtn.x = 300; searchBtn.y = 298;
			menuGroup:insert(searchBtn)
			searchBtnPressed = display.newImageRect("images/tabbar/search-pressed.png", 118, 47)
			searchBtnPressed.x = 300; searchBtnPressed.y = 298;
			menuGroup:insert(searchBtnPressed)
			searchBtn.id = "searchbutton"
			searchBtn:addEventListener("touch", onTabBarTouch)
			--
			myLevelsBtn = display.newImageRect("images/tabbar/mylevels.png", 118, 47)
			myLevelsBtn.x = 420; myLevelsBtn.y = 298;
			menuGroup:insert(myLevelsBtn)
			myLevelsBtnPressed = display.newImageRect("images/tabbar/mylevels-pressed.png", 118, 48)
			myLevelsBtnPressed.x = 420; myLevelsBtnPressed.y = 298;
			menuGroup:insert(myLevelsBtnPressed)
			myLevelsBtn.id = "mylevelsbutton"
			myLevelsBtn:addEventListener("touch", onTabBarTouch)
			--
			--depending on last touched show that one first
			if lastTab == "mylevels" then
				newBtnPressed.isVisible = false
				topBtnPressed.isVisible = false
				searchBtnPressed.isVisible = false
				myLevelsBtnPressed.isVisible = true
				myLevelsBtn.alpha = 0
			elseif lastTab == "search" then
				newBtnPressed.isVisible = false
				topBtnPressed.isVisible = false
				searchBtnPressed.isVisible = true
				myLevelsBtnPressed.isVisible = false
				searchBtn.alpha = 0
			elseif lastTab == "top" then
				newBtnPressed.isVisible = false
				topBtnPressed.isVisible = true
				searchBtnPressed.isVisible = false
				myLevelsBtnPressed.isVisible = false
				topBtn.alpha = 0
			else
				newBtnPressed.isVisible = true
				topBtnPressed.isVisible = false
				searchBtnPressed.isVisible = false
				myLevelsBtnPressed.isVisible = false
				newBtn.alpha = 0
			end
			--
		end
		createTabBarButtons()
		----------------------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------
	
		tabGroupNew:toBack()
		tabGroupTop:toBack()
		tabGroupSearch:toBack()
		tabGroupMyLevels:toBack()
		menuGroup:toFront()
		backgroundGroup:toBack()
	end
	drawScreen()
	-- ************************************************************** --
	--	onSystem() -- listener for system events
	-- ************************************************************** --
	local function onSystem( event )
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
		
		display.remove(tableViewNew)
		tableViewNew = nil
		display.remove(tableViewTop)
		tableViewTop = nil
		display.remove(tableViewSearch)
		tableViewSearch = nil
		display.remove(tableViewMyLevels)
		tableViewMyLevels = nil
		display.remove(textField)
		textField = nil
		
		-- REMOVE EVENT LISTENERS
		Runtime:removeEventListener("system", onSystem)
		
		--REMOVE everything in other groups
		for i = tabGroupNew.numChildren,1,-1 do
			local child = tabGroupNew[i]
			child.parent:remove( child )
			child = nil
		end
		for i = tabGroupTop.numChildren,1,-1 do
			local child = tabGroupTop[i]
			child.parent:remove( child )
			child = nil
		end
		for i = tabGroupSearch.numChildren,1,-1 do
			local child = tabGroupSearch[i]
			child.parent:remove( child )
			child = nil
		end
		for i = tabGroupMyLevels.numChildren,1,-1 do
			local child = tabGroupMyLevels[i]
			child.parent:remove( child )
			child = nil
		end
		for i = backgroundGroup.numChildren,1,-1 do
			local child = backgroundGroup[i]
			child.parent:remove( child )
			child = nil
		end
		for i = tabGroupSearchField.numChildren,1,-1 do
			local child = tabGroupSearchField[i]
			child.parent:remove( child )
			child = nil
		end
	
	end
	
	-- MUST return a display.newGroup()
	return menuGroup
end
