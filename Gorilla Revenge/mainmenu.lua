module(..., package.seeall)

--***********************************************************************************************--
--***********************************************************************************************--

-- mainmenu

--***********************************************************************************************--
--***********************************************************************************************--

-- Main function - MUST return a display.newGroup()
function new()
	local menuGroup = display.newGroup()
	local settingsGroup = display.newGroup()
	local areYouSureGroup = display.newGroup()
	
	local ui = require("ui")
	local physics = require("physics")
	local widget = require "widget"
	local movieclip = require "movieclip"
	local json = require "json"
	--ACTIVATE MULTITOUCH
	system.activate( "multitouch" )
	
	system.setAccelerometerInterval( 75.0 )
	
	physics.start()
	physics.setGravity(0,8)
	
	-- whether or not the about screen is up
	local aboutScreenIsShowing = false
	local settingsShowing = false
	
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
	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------
	
	local beatTheGame = loadValue("level" .. 20 .. "rating.data") ~= "0"
	
	--SOUNDS
	local clickSound = audio.loadSound("sounds/clicksound.caf")
	local backgroundMusic = audio.loadStream("sounds/rock.mp3")
	
	--GLOBAL VARIABLES
	local aboutScreen
	local changingLevel = false
	local musicOn = false
	local soundsOn = false
	local hudControlsOn = false
	local rightArrowBtn
	local leftArrowBtn
	local totalLevels = 20
	
	local drawScreen = function()
	
		--MUSIC SETTINGS
		 musicOn = loadValue("music.data")
		 soundsOn = loadValue("sounds.data")
		 hudControlsOn = loadValue("hud-controls.data")
		if(musicOn == "0")then musicOn = "yes"; end
		if(soundsOn == "0")then soundsOn = "yes"; end
		if(hudControlsOn == "0")then hudControlsOn = "no"; end
		saveValue("music.data", musicOn)
		saveValue("sounds.data", soundsOn)
		saveValue("hud-controls.data", hudControlsOn)
		
		local function checkMusicAndPlay()
			if musicOn == "yes" and audio.usedChannels == 0 then
				audio.stop()
				audio.play(backgroundMusic, {loops = -1})
			end
		end
		timer.performWithDelay(200, checkMusicAndPlay, 1)
	
		-- BACKGROUND IMAGE
		local backgroundImage = display.newImageRect( "images/mainmenubackground.png", 480, 320 )
		backgroundImage.x = 240; backgroundImage.y = 160
		menuGroup:insert( backgroundImage )
		
		-- ABOUT SCREEN
		aboutScreen = display.newImageRect("images/about-screen.png", 400, 250 )
		aboutScreen.x = 240; aboutScreen.y = 160
		menuGroup:insert( aboutScreen )
		aboutScreen.alpha = 0
		
		--****************************************************************************************
		--SETTINGS SCREEN
		--****************************************************************************************
		local settingsBackground = display.newRoundedRect(0,0,440,280,12)
		settingsBackground.x = 240; settingsBackground.y = 160;
		settingsBackground:setFillColor(0,0,0)
		settingsBackground.alpha = .8
		settingsGroup:insert(settingsBackground)
		
		
		local function resetFiles()
			saveValue("show-how-to-delete.data", "0")
			saveValue("untitled-counter.data", 0)
			saveValue("loaded-level-name.data", "0")
			saveValue("loaded-level-id.data", "0")
			saveValue("saved-levels-table.data", "0")
			saveValue("levelsize.data", "0")
			saveValue("new-or-load.data", "0")
			saveValue("level-to-load.data", "0")
			saveValue("there-is-a-most-recent.data", "0")
			saveValue("templevel.data", "0")
			saveValue("hud-controls.data", "0")
			saveValue("user-levels-first-time.data", "0")
			saveValue("username.data", "0")
			saveValue("full-version-purchased", "0")
			for i = 1,10 do
				saveValue("level" .. i .. "rating.data", "0")
			end
			--
			print()
			print()
			print("-- files reset --")
			print()
		end
		--resetFiles()	
				
		if loadValue("total-saved-levels.data") == "0" then
			saveValue("total-saved-levels.data", 0)
		end
		if loadValue("saved-levels-table.data") == "0" then
			local t = {}
			saveValue("saved-levels-table.data", json.encode(t))
		end
		
		local function buttonHandler( event )
		    local id = event.target.id

	        if id == "music-on" then
				if soundsOn == "yes" then audio.play(clickSound); end
	            saveValue("music.data", "yes")
				if musicOn == "no" then
					musicOn = "yes"
				end
				audio.stop()
				audio.play(backgroundMusic, {loops = -1})
	        elseif id == "music-off" then
				if soundsOn == "yes" then audio.play(clickSound); end
	            saveValue("music.data", "no")
				if musicOn == "yes" then
					musicOn = "no"
				end
				audio.stop()
			elseif id == "sounds-on" then
            	saveValue("sounds.data", "yes")
				soundsOn = "yes"
				if soundsOn == "yes" then audio.play(clickSound); end
			elseif id == "sounds-off" then
				saveValue("sounds.data", "no")
				soundsOn = "no"
			elseif id == "hudcontrols-on" then
				if soundsOn == "yes" then audio.play(clickSound); end
            	saveValue("hud-controls.data", "yes")
				hudControlsOn = "yes"
				rightArrowBtn.isVisible = true
				leftArrowBtn.isVisible = true
			elseif id == "hudcontrols-off" then
				if soundsOn == "yes" then audio.play(clickSound); end
				saveValue("hud-controls.data", "no")
				hudControlsOn = "no"
				rightArrowBtn.isVisible = false
				leftArrowBtn.isVisible = false
	        end
	    end
			
		local musicBottonTable
		local soundsButtonTable
		local hudControlsButtonTable

		if musicOn == "yes" then
			 musicButtonTable = {
		        { id="music-on", label="Music On", onPress=buttonHandler, isDown=true },
		        { id="music-off", label="Music Off", onPress=buttonHandler }
		    }
		else
			 musicButtonTable = {
		        { id="music-on", label="Music On", onPress=buttonHandler },
		        { id="music-off", label="Music Off", onPress=buttonHandler, isDown = true }
		    }
		end
		if soundsOn == "yes" then
			 soundsButtonTable = {
		        { id="sounds-on", label="Sound On", onPress=buttonHandler, isDown=true },
		        { id="sounds-off", label="Sound Off", onPress=buttonHandler }
		    }
		else
			 soundsButtonTable = {
		        { id="sounds-on", label="Sound On", onPress=buttonHandler },
		        { id="sounds-off", label="Sound Off", onPress=buttonHandler, isDown = true }
		    }
		end
		if hudControlsOn == "yes" then
			 hudControlsButtonTable = {
		        { id="hudcontrols-on", label="HUD Controls", onPress=buttonHandler, isDown=true },
		        { id="hudcontrols-off", label="Tilt Controls", onPress=buttonHandler }
		    }
		else
			 hudControlsButtonTable = {
		        { id="hudcontrols-on", label="HUD Controls", onPress=buttonHandler },
		        { id="hudcontrols-off", label="Tilt Controls", onPress=buttonHandler, isDown = true }
		    }
		end
		

		local musicText = widget.newEmbossedText( "Music", 90, 50, "HelveticaNeue-Bold", 24, { 255, 255, 255 } )
		local soundsText = widget.newEmbossedText( "Sounds", 100, 140, "HelveticaNeue-Bold", 24, { 255, 255, 255 } )
		local hudControlsText = widget.newEmbossedText( "Controls", 100, 230, "HelveticaNeue-Bold", 24, { 255, 255, 255 } )
		
	    local musicButtons = widget.newSegmentedControl( musicButtonTable, { x=50, y=70 } )
		local soundsButtons = widget.newSegmentedControl( soundsButtonTable, { x=50, y=160 } )
		local hudControlsButtons = widget.newSegmentedControl( hudControlsButtonTable, { x=50, y=250 } )
		
		local onDoneButton = function (event )
		    if event.phase == "release" and settingsShowing then
				if soundsOn == "yes" then audio.play(clickSound); end
	            settingsShowing = false
				areYouSureGroup.isVisible = false
				transition.to(settingsGroup, {time = 500, alpha = 0})
	        end
	    end

		local doneButton = widget.newButton{
	        id = "donebutton",
	        x = 350,
	        y = 250,
	        label = "  Done  ",
	        onEvent = onDoneButton
	    }
		
		local yesBtn
		local noBtn
		local areYouSureText
	
		local onDeleteButton = function (event)
		    if event.phase == "release" and settingsShowing then
				if soundsOn == "yes" then audio.play(clickSound); end
				areYouSureGroup.isVisible = true
				areYouSureGroup:toFront()
	        end
	    end
	
		local deleteButton = widget.newButton{
	        id = "deletebutton",
	        x = 287,
	        y = 70,
	        label = "Reset HighScores",
	        onEvent = onDeleteButton
	    }
	
		areYouSureText = widget.newEmbossedText( "Are You Sure?", 360, 130, "HelveticaNeue-Bold", 16, { 255, 255, 255 } )
	
		local onYesTouch = function(event)
			if event.phase == "release" then
				if soundsOn == "yes" then audio.play(clickSound); end				
				--delete file
				for i=1,totalLevels do
					os.remove(system.pathForFile( "level" .. i .. "rating.data", system.DocumentsDirectory ))						
				end
				
				areYouSureGroup.isVisible = false
				--SELF CREATED toast MESSAGE :)
				local toast = display.newText("HighScores Reset.", 240,160,native.systemFont,12)
				toast.x = 362; toast.y = 115;
				settingsGroup:insert(toast)
				toast.alpha = 0
				toast:toFront()

				transition.to(toast,{time = 500, alpha = 1, 
					onComplete = function() timer.performWithDelay(1000,
					function()
						transition.to(toast, {time=500, alpha = 0,
							onComplete= function() 
								toast:removeSelf()
								toast:toFront()
							end}); 
					end, 1); 
				end})	
			end
		end
		
		local onNoTouch = function(event)
			if event.phase == "release" then
				if soundsOn == "yes" then audio.play(clickSound); end
				areYouSureGroup.isVisible = false
			end
		end
	
	
		yesBtn = widget.newButton{
			id = "yesbutton",
	        x = 287,
	        y = 150,
	        label = "Yes",
	        onEvent = onYesTouch
		}
		noBtn = widget.newButton{
			id = "nobutton",
	        x = 380,
	        y = 150,
	        label = " No ",
	        onEvent = onNoTouch
		}
		
		areYouSureGroup.isVisible = false
		
		-- Insert items into a group:
		areYouSureGroup:insert(yesBtn.view)
		areYouSureGroup:insert(noBtn.view)
		areYouSureGroup:insert(areYouSureText)
		settingsGroup:insert(doneButton.view )
		settingsGroup:insert(deleteButton.view)
		settingsGroup:insert(musicText)
		settingsGroup:insert(soundsText)
		settingsGroup:insert(hudControlsText)
		settingsGroup:insert(musicButtons)
		settingsGroup:insert(hudControlsButtons)
		settingsGroup:insert(soundsButtons)
		
		settingsGroup.alpha = 0
	------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------
				
		-- ABOUT BUTTON --
		local aboutBtn
		local onAboutTouch = function( event )
			if event.phase == "release" and aboutScreenIsShowing == false and settingsShowing == false then
				if soundsOn == "yes" then audio.play(clickSound); end
				aboutScreenIsShowing = true
				aboutScreen:toFront()
				transition.to( aboutScreen, { time=500, alpha=.9, --[[onComplete=hideBannerAndText--]] })
			end
		end
		aboutBtn = ui.newButton{
			defaultSrc = "images/about-button.png",
			defaultX = 60,
			defaultY = 33,
			overSrc = "images/about-button-pressed.png",
			overX = 60,
			overY = 33,
			onEvent = onAboutTouch,
			id = "aboutbutton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		aboutBtn.x = 530; aboutBtn.y = 105;
		menuGroup:insert( aboutBtn )
		-- END ABOUT BUTTON --
		-- RATE BUTTON --
		local rateBtn
		local onRateTouch = function( event )
			if event.phase == "release" and settingsShowing == false then
				if soundsOn == "yes" then audio.play(clickSound); end
				local itunesID = 461182384
				local itmsURL = "http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=" .. itunesID
				system.openURL( itmsURL )
			end
		end
		rateBtn = ui.newButton{
			defaultSrc = "images/rate-button.png",
			defaultX = 60,
			defaultY = 33,
			overSrc = "images/rate-button-pressed.png",
			overX = 60,
			overY = 33,
			onEvent = onRateTouch,
			id = "ratebutton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		rateBtn.x = 530; rateBtn.y = 65;
		menuGroup:insert( rateBtn )
		-- END RATE BUTTON --
		-- SETTINGS BUTTON --
		local settingsBtn
		local onSettingsTouch = function( event )
			if event.phase == "release" and settingsShowing == false then
				if soundsOn == "yes" then audio.play(clickSound); end
				settingsShowing = true
				settingsGroup:toFront()
				transition.to(settingsGroup, {time = 500, alpha = 1})
			end
		end
		settingsBtn = ui.newButton{
			defaultSrc = "images/settings-button.png",
			defaultX = 60,
			defaultY = 33,
			overSrc = "images/settings-button-pressed.png",
			overX = 60,
			overY = 33,
			onEvent = onSettingsTouch,
			id = "settingsbutton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		settingsBtn.x = 530; settingsBtn.y = 25;
		menuGroup:insert( settingsBtn )
		-- END SETTINGS BUTTON --
		-- START BUTTON --
		local startBtn
		local onStartTouch = function( event )
			if event.phase == "release" and settingsShowing == false then
				if soundsOn == "yes" then audio.play(clickSound); end
				director:changeScene("levelchooser")
			end
		end
		startBtn = ui.newButton{
			defaultSrc = "images/start-button.png",
			defaultX = 80,
			defaultY = 44,
			overSrc = "images/start-button-pressed.png",
			overX = 80,
			overY = 44,
			onEvent = onStartTouch,
			id = "startbutton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		startBtn.x = -160; startBtn.y = 90;
		menuGroup:insert( startBtn )
		-- END START BUTTON --
		-- LEVEL EDITOR BUTTON --
		local levelEditorBtn
		local onLevelEditorTouch = function( event )
			if event.phase == "release" and settingsShowing == false then
				if soundsOn == "yes" then audio.play(clickSound); end
				director:changeScene("leveleditormenu")
			end
		end
		levelEditorBtn = ui.newButton{
			defaultSrc = "images/leveleditor-button.png",
			defaultX = 131,
			defaultY = 45,
			overSrc = "images/leveleditor-button-pressed.png",
			overX = 131,
			overY = 45,
			onEvent = onLevelEditorTouch,
			id = "leveleditor",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 14,
			emboss = true
		}
		levelEditorBtn.x = -160; levelEditorBtn.y = 150;
		menuGroup:insert( levelEditorBtn )
		-- END START BUTTON --
		
		-- SLIDE IN THE RATE AND ABOUT BUTTONS FROM THE LEFT SIDE
		transition.to( aboutBtn, { time=2000, x=440})
		transition.to( rateBtn, { time=2000, x=440})
		transition.to( settingsBtn, { time=2000, x=440})
		transition.to( startBtn, { time=2000, x=65, transition=easing.inOutExpo})
		transition.to( levelEditorBtn, { time=2000, x=91, transition=easing.inOutExpo})
		--				--
		
		-- CREATE AND BRING IN THE TITLE AND THE MENU INSTRUCTIONS --
		local title = display.newImageRect( "images/title.png", 234, 41 )
		title.x = -150; title.y = 30
		menuGroup:insert( title )
		transition.to( title, { time=2000, x=140, transition=easing.inOutExpo})
		--				--
		
	end
	drawScreen()
	------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------
	
	--CREATE THE GORILLA
	 gorilla = movieclip.newAnim({"images/gorilla/gorillaright1.png","images/gorilla/gorillaright2.png","images/gorilla/gorillaright3.png",
										"images/gorilla/gorillaright4.png","images/gorilla/gorillaright5.png","images/gorilla/gorillaright6.png",
										"images/gorilla/gorillaright7.png",}, 83, 58)
	gorilla.movingRight = false
	gorilla.movingLeft = false
	menuGroup:insert(gorilla)
	physics.addBody(gorilla, {bounce = 0})
	
	gorillaLeft = movieclip.newAnim({"images/gorilla/gorillaleft1.png","images/gorilla/gorillaleft2.png","images/gorilla/gorillaleft3.png",
										"images/gorilla/gorillaleft4.png","images/gorilla/gorillaleft5.png","images/gorilla/gorillaleft6.png",
										"images/gorilla/gorillaleft7.png",}, 83, 58)
	gorillaLeft.x = -110; gorillaLeft.y = 265;
	menuGroup:insert(gorillaLeft)
	
	gorilla:setSpeed(.5)
	gorillaLeft:setSpeed(.5)
	
	if not beatTheGame then
		gorilla.x = 110; gorilla.y = 265;
	else
		gorilla.x = 400; gorilla.y = 265;
	end
	
	--CREATE THE CAGE OVER THE GORILLA
	local cage = display.newImageRect("images/cage.png", 184, 114)
	cage.x = 110; cage.y = 252;
	menuGroup:insert(cage)
	
	--CREATE THE CAGE PHYSICS
	local ground = display.newRect(20,297, 500, 10)
	ground:setFillColor(0,0,0,0)
	local rightWall = display.newRect(190,200, 10, 100)
	rightWall:setFillColor(0,0,0,0)
	local leftWall = display.newRect(20,200, 10, 100)
	leftWall:setFillColor(0,0,0,0)
	local ceiling = display.newRect(20,195, 180, 10)
	ceiling:setFillColor(0,0,0,0)
	
	local rightOuterWall = display.newRect(480,0, 10, 300)
	rightOuterWall:setFillColor(0,0,0,0)
	local leftOuterWall = display.newRect(-10,0, 10, 300)
	leftOuterWall:setFillColor(0,0,0,0)
	
	menuGroup:insert(ground)
	menuGroup:insert(rightWall)
	menuGroup:insert(leftWall)
	menuGroup:insert(rightOuterWall)
	menuGroup:insert(leftOuterWall)
	menuGroup:insert(ceiling)
	physics.addBody(ground, "static", {density = 1.0, friction = 0.3, bounce = 0.2 } )
	physics.addBody(rightWall, "static", {density = 1.0, friction = 0.3, bounce = 0.2 } )
	physics.addBody(leftWall, "static", {density = 1.0, friction = 0.3, bounce = 0.2 } )
	physics.addBody(rightOuterWall, "static", {density = 1.0, friction = 0.3, bounce = 0.2 } )
	physics.addBody(leftOuterWall, "static", {density = 1.0, friction = 0.3, bounce = 0.2 } )
	physics.addBody(ceiling, "static", {density = 1.0, friction = 0.3, bounce = 0.2 } )
	
	
	local whiteGuard
	local whiteGuardLeft
	local blackGuard
	local blackGuardLeft
	
	if not beatTheGame then
		--CREATE THE GUARDS PACING BACK AND FORTH
		 whiteGuard = movieclip.newAnim({"images/guard/whiteright1.png", "images/guard/whiteright2.png", 
											"images/guard/whiteright3.png", "images/guard/whiteright4.png", 
											"images/guard/whiteright5.png", "images/guard/whiteright6.png", }, 33, 53)

		 whiteGuardLeft = movieclip.newAnim({"images/guard/whiteleft1.png", "images/guard/whiteleft2.png", 
												"images/guard/whiteleft3.png", "images/guard/whiteleft4.png", 
												"images/guard/whiteleft5.png", "images/guard/whiteleft6.png", }, 33, 53)
		menuGroup:insert(whiteGuard)
		menuGroup:insert(whiteGuardLeft)

		whiteGuard.x = 390; whiteGuard.y = 285;
		whiteGuardLeft.x = -100; whiteGuardLeft.y = 285;
		whiteGuard:setSpeed(.2)
		whiteGuardLeft:setSpeed(.2)
		whiteGuard:play()
		whiteGuard.direction = "right"

		 blackGuard = movieclip.newAnim({"images/guard/blackright1.png", "images/guard/blackright2.png", 
											"images/guard/blackright3.png", "images/guard/blackright4.png", 
											"images/guard/blackright5.png", "images/guard/blackright6.png", }, 33, 53)

		 blackGuardLeft = movieclip.newAnim({"images/guard/blackleft1.png", "images/guard/blackleft2.png", 
												"images/guard/blackleft3.png", "images/guard/blackleft4.png", 
												"images/guard/blackleft5.png", "images/guard/blackleft6.png", }, 33, 53)

		menuGroup:insert(blackGuard)
		menuGroup:insert(blackGuardLeft)	

		blackGuard.x = 300; blackGuard.y = 270;
		blackGuardLeft.x = -100; blackGuardLeft.y = 270;
		blackGuard:setSpeed(.2)
		blackGuardLeft:setSpeed(.2)
		blackGuardLeft:play()
		blackGuard.alpha = 0
		blackGuard.direction = "left"

		--just make sure white guy passes in front
		whiteGuard:toFront()
		whiteGuardLeft:toFront()
	else
		whiteGuard = display.newImageRect("images/guard/whiteright1.png", 33, 53)
		whiteGuard.x = 93; whiteGuard.y = 270;
		blackGuard = display.newImageRect("images/guard/blackright1.png", 33, 53)
		blackGuard.x = 150; blackGuard.y = 270;
		menuGroup:insert(whiteGuard)
		menuGroup:insert(blackGuard)
		cage:toFront()
	end
	
	local rightArrowDown = false
	local leftArrowDown = false
	
	--HUD CONTROLS
	local onArrowTouch = function( event )
		if event.phase == "press" then
			if event.id == "rightarrow" then
				rightArrowDown = true
			elseif event.id == "leftarrow" then
				leftArrowDown = true
			end
		elseif event.phase == "release" then				
			if event.id == "rightarrow" then
				rightArrowDown = false
			elseif event.id == "leftarrow" then
				leftArrowDown = false
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
	rightArrowBtn.x = 110; rightArrowBtn.y = 285;
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
	leftArrowBtn.x = 50; leftArrowBtn.y = 285;
	menuGroup:insert( leftArrowBtn )
	rightArrowBtn.alpha = .4
	leftArrowBtn.alpha = .4
	if hudControlsOn == "no" then
		rightArrowBtn.isVisible = false
		leftArrowBtn.isVisible = false
	end
	-- END LEFT ARROW BUTTON
	
	
	
	
	local function resetCover(cover)
		cover.x = -100
	end
	
	local function updateGuard(mainGuard, guardCover, leftBorder, rightBorder)
		if(mainGuard.direction == "right")then
			mainGuard.x = mainGuard.x + 1
		elseif(mainGuard.direction == "left")then
			mainGuard.x = mainGuard.x - 1
			guardCover.x = mainGuard.x
		end
		
		if(mainGuard.x >= rightBorder)then
			mainGuard.direction = "pause"
			mainGuard:stopAtFrame(1)
			guardCover:play()
			timer.performWithDelay(2000, 
				function() 
					mainGuard.direction = "left"
					mainGuard.alpha = 0
					guardCover.x = mainGuard.x
				end, 1)
		elseif(mainGuard.x <= leftBorder)then
			mainGuard.direction = "pause"
			guardCover:stopAtFrame(1)
			mainGuard:play()
			timer.performWithDelay(2000, 
				function() 
					mainGuard.direction = "right" 
					mainGuard.alpha = 1 
					resetCover(guardCover)
				end, 1)
		end
	end
	
	------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------
	
	local orientation = loadValue("orientation.data")
	if orientation == "0" then
		orientation = "landscapeLeft"
		saveValue("orientation.data", "landscapeLeft")
	end
	
	--THE GAME LOOP CALLED ON THE ENTRANCE OF EVERY FRAME
	local function gameLoop(event)
		
		--move gorilla hud control style
		if hudControlsOn == "yes" then
			if rightArrowDown then
			
				if(gorilla.movingRight == false)then
					gorilla.direction = "right"
					gorilla.alpha = 1
					resetCover(gorillaLeft)
					gorillaLeft:stopAtFrame(1)
					gorilla.movingRight = true
					gorilla.movingLeft = false
					gorilla:play()
				end
			
				gorilla.x = gorilla.x + 4
			
			elseif leftArrowDown then
				if(gorilla.movingLeft == false)then
					gorilla.direction = "left"
					gorilla.alpha = 0
					gorilla:stopAtFrame(1)
					gorilla.movingLeft = true
					gorilla.movingRight = false
					gorillaLeft:play()
				end
			
				gorilla.x = gorilla.x - 4
				gorillaLeft.x = gorilla.x
			
			else
				if(gorilla.movingRight)then
					gorilla.movingRight = false
					gorilla:stopAtFrame(1)
				elseif(gorilla.movingLeft)then
					gorilla.movingLeft = false
					gorillaLeft:stopAtFrame(1)
				end
			
			end
		end
		
		
		--move the guards
		
		if not beatTheGame then
			updateGuard(whiteGuard, whiteGuardLeft, 250, 400)
			updateGuard(blackGuard, blackGuardLeft, 300, 450)
		end
		
	end
	
	--ADD THE GAME LOOP AND ACCELEROMETER LISTENERS
	Runtime:addEventListener( "enterFrame", gameLoop )
	
	--***********
	--TOUCH EVENT
	local function screenTouched(event)
		-- SCREEN TOUCH
		
		if(aboutScreenIsShowing == false and settingsShowing == false)then
			if(event.phase=="began")then
				
			elseif(event.phase=="ended")then
				
			end
		else
			if(event.phase == "began")then
				if aboutScreenIsShowing then
					aboutScreenIsShowing = false
					transition.to( aboutScreen, { time=500, alpha=0, --[[onComplete=hideBannerAndText--]] })
				end
			end
		end
	end
	
	Runtime:addEventListener("touch", screenTouched)
	--TOUCH EVENT
	--***********
	
	-- ************************************************************** --
	--	onTilt() -- Accelerometer Code for Player Movement	
	-- ************************************************************** --	
	local onTilt = function( event )
		if(aboutScreenIsShowing == false and settingsShowing == false and hudControlsOn == "no")then
			
			if orientation == "landscapeRight" and event.yGravity < -.2 then
				if(gorilla.movingRight == false)then
					gorilla.direction = "right"
					gorilla.alpha = 1
					resetCover(gorillaLeft)
					gorillaLeft:stopAtFrame(1)
					gorilla.movingRight = true
					gorilla.movingLeft = false
					gorilla:play()
				end
				
				
				gorilla.x = gorilla.x + 2
				
			elseif orientation == "landscapeRight" and event.yGravity > .2 then
				if(gorilla.movingLeft == false)then
					gorilla.direction = "left"
					gorilla.alpha = 0
					gorilla:stopAtFrame(1)
					gorilla.movingLeft = true
					gorilla.movingRight = false
					gorillaLeft:play()
				end
			
				gorilla.x = gorilla.x - 2
				gorillaLeft.x = gorilla.x
			
			elseif orientation == "landscapeLeft" and event.yGravity > .2 then
				if(gorilla.movingRight == false)then
					gorilla.direction = "right"
					gorilla.alpha = 1
					resetCover(gorillaLeft)
					gorillaLeft:stopAtFrame(1)
					gorilla.movingRight = true
					gorilla.movingLeft = false
					gorilla:play()
				end


				gorilla.x = gorilla.x + 2

			elseif orientation == "landscapeLeft" and event.yGravity < -.2 then
				if(gorilla.movingLeft == false)then
					gorilla.direction = "left"
					gorilla.alpha = 0
					gorilla:stopAtFrame(1)
					gorilla.movingLeft = true
					gorilla.movingRight = false
					gorillaLeft:play()
				end

				gorilla.x = gorilla.x - 2
				gorillaLeft.x = gorilla.x
		
			else
				if(gorilla.movingRight)then
					gorilla.movingRight = false
					gorilla:stopAtFrame(1)
				elseif(gorilla.movingLeft)then
					gorilla.movingLeft = false
					gorillaLeft:stopAtFrame(1)
				end
				
			end
						
		end
	end
	
	Runtime:addEventListener( "accelerometer", onTilt )
	
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
	
	
	local function onOrientationChange( event )
		if event.type == "landscapeRight" or event.type == "landscapeLeft" then
			orientation = event.type
			saveValue("orientation.data", orientation)
		end
	end
	Runtime:addEventListener( "orientation", onOrientationChange )
	------------------------------------------------------------------
	------------------------------------------------------------------
	
	unloadMe = function()
		
		--REMOVE everything in other groups
		for i = settingsGroup.numChildren,1,-1 do
			local child = settingsGroup[i]
			child.parent:remove( child )
			child = nil
		end
		for i = areYouSureGroup.numChildren,1,-1 do
			local child = areYouSureGroup[i]
			child.parent:remove( child )
			child = nil
		end
		
		-- STOP PHYSICS ENGINE
		--physics.stop()
		
		-- REMOVE EVENT LISTENERS
		Runtime:removeEventListener("enterFrame", gameLoop)
		Runtime:removeEventListener("touch", screenTouched)
		Runtime:removeEventListener("system", onSystem)
		Runtime:removeEventListener( "accelerometer", onTilt )
		Runtime:removeEventListener("orientation", onOrientationChange)
		
	end
	
	-- MUST return a display.newGroup()
	return menuGroup
end
