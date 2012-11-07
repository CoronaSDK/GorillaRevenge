module(..., package.seeall)


-- Main function - MUST return a display.newGroup()
function new()	
	local gameGroup = display.newGroup()
	local pauseGroup = display.newGroup()
	local hudGroup = display.newGroup()
	
	-- EXTERNAL MODULES / LIBRARIES
	local movieclip = require "movieclip"
	local physics = require "physics"
	local ui = require "ui"
	local facebook = require "facebook"
	local json = require "json"
	--ACTIVATE MULTITOUCH
	system.activate( "multitouch" )
		
	--ACCELEROMETER
	system.setAccelerometerInterval( 75.0 )
	
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
	-------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------
	
	--STARTING PHYSICS
	physics.start();
	physics.setDrawMode("normal");
	physics.setGravity(0, 30);
		
	--MUSIC SETTINGS
	local musicOn = loadValue("music.data")
	local soundsOn = loadValue("sounds.data")
	local hudControlsOn = loadValue("hud-controls.data")
	local orientation = loadValue("orientation.data")
	
	local clickSound = audio.loadSound("sounds/clicksound.caf")
	local jumpSound = audio.loadSound("sounds/jump.caf")
	local keySound = audio.loadSound("sounds/pickupkey.caf")
	local winSound = audio.loadSound("sounds/gamewin.caf")
	local hurtSound = audio.loadSound("sounds/hurt.caf")
	
	--
	--STEP ONE
	local levelTable = 
	{
		"s#l#",
		"p#990#140#102#10#",
		"bg#960#293#r#",
		"wg#513#293#r#",
		"f#231#263#",
		"w#1212#200#",
		"w#1203#-249#",
		"w#273#-264#",
		"p#876#-223#100#10#",
		"p#618#-319#100#10#",
		"l#m#621#-216#",
		"p#615#-112#184#10#",
		"b#252#-74#",
		"b#177#-74#",
		"b#102#-74#",
		"p#186#-60#372#10#",
		"p#50#-328#100#10#",
		"b#1299#-155#",
		"b#1107#-155#",
		"p#1254#-142#370#10#",
		"k#1404#-252#",
		"d#1371#264#",
		"g#60#-361#",
	}
	--
	--STEP TWO
	local currentLevel = 16
	local threeStarTime = 10
	local twoStarTime = 16
	--
	local gorillaSpeed = 0
	local guardSpeed = 2
	local onGround = true
	local hasKey = true
	local animationDone = false	
	local gamePaused = false
	local backgroundSize
	
	--global items
	local gorilla
	local gorillaLeft
	local JumpRightCover
	local jumpLeftCover
	local platform = {}
	local ladder = {}
	local window = {}
	local guard = {}
	local guardLeft = {}
	local crate = {}
	local bearTrap = {}
	local fullCage = {}
	local bearTrapClosed
	local key
	local lock
	local door
	local t1 = 0
	local hudTime = 0
	local hudTimer
	local timerText
	local background
	local pauseScreen
	local pauseBtn
	local restartBtn
	local menuBtn
	local playBtn
	local pauseText
	local ground
	local leftWall
	local rightWall
	local ceiling
	local resetLevel
	local loadingImage
	local boundaryWidth
	local boundaryHeight
	local zoomAnimation
	local numberOfGroundsTouching = 0
	local animationStartTimer
	local gorillaWasRunning = false
	local rightArrowDown = false
	local leftArrowDown = false
	local fakeAd
	-------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------
	
	-----------------COLLISIONS AND FUNCTIONS--------------------	
	local function callNextLevel()
		local winTime = hudTime/100
		saveValue("lastLevel.data", tostring(currentLevel))
		saveValue("lastLevelTime.data", winTime)
		animationDone = false
		
		if winTime < threeStarTime then
			saveValue("temprating.data", "3")
		elseif winTime < twoStarTime then
			saveValue("temprating.data", "2")
		else
			saveValue("temprating.data", "1")
		end		
		
		timer.performWithDelay(500, director:changeScene("nextLevelScreen"), 1)
	end
	
	local function onGroundCollision(self, event)
		if event.other.myName == "gorilla" and event.phase == "began" then
			numberOfGroundsTouching = numberOfGroundsTouching + 1
		elseif event.other.myName == "gorilla" and event.phase == "ended" then
			numberOfGroundsTouching = numberOfGroundsTouching - 1
		end
		if animationDone then
			if event.phase == "began" and self.myName == "ground" then gameGroup.y = 0; end
			if event.phase == "began" and event.other.myName == "gorilla" then
				onGround = true
				if gorilla.direction == "right" then
					gorilla.isVisible = true
					jumpRightCover.isVisible = false
				elseif gorilla.direction == "left" then
					gorillaLeft.isVisible = true
					jumpLeftCover.isVisible = false
				end
			elseif event.phase == "ended" and event.other.myName == "gorilla" then
				if numberOfGroundsTouching < 1 then
					numberOfGroundsTouching = 0
					onGround = false
					if gorilla.direction == "right" then
						gorilla.isVisible = false
						jumpRightCover.isVisible = true
					elseif gorilla.direction == "left" then
						gorillaLeft.isVisible = false
						jumpLeftCover.isVisible = true
					end
				end
			end
		end
	end
	
	local function onPlatformPreCollision( self, event )
	    if(self.y < event.other.y and event.other.myName == "gorilla")then
			if self.myName == "ladder" then
				self.isSensor = true
				timer.performWithDelay(200, function() self.isSensor = false; end, 1)
			else
				event.other.isSensor = true
				timer.performWithDelay(200, function() event.other.isSensor = false; end, 1)
			end
		end
	end
	
	local function onKeyCollision(self, event)
		if(event.other.myName == "gorilla" and hasKey == false)then
			if soundsOn == "yes" then audio.play(keySound); end
			hasKey = true
			lock.isVisible = false
			self.isVisible = false
		end
	end
	
	local function onDoorCollision(self, event)
		if event.phase == "began" and event.other.myName == "gorilla" and hasKey then
			if soundsOn == "yes" then audio.play(winSound); end
			callNextLevel()
		end
	end
	
	local function whereToZoomInTo()
		if backgroundSize == "l" then
			if(gorilla.x < 360 and gorilla.y > 160)then
				return 0,0
			--
			elseif(gorilla.x >= 360 and gorilla.x <= 1080 and gorilla.y > 160)then
				return (gorilla.x-240)*-1, 0
			--
			elseif(gorilla.x > 1080 and gorilla.y > 160)then
				return -960, 0
			--
			elseif(gorilla.x > 1080 and gorilla.y <= 160 and gorilla.y >= -240)then
				return -960, (gorilla.y-160)*-1
			--
			elseif(gorilla.x > 1080 and gorilla.y < -240)then
				return -960, 640
			--
			elseif(gorilla.x >= 360 and gorilla.x <= 1080 and gorilla.y < -240)then
				return (gorilla.x-240)*-1, 640
			--
			elseif(gorilla.x < 360 and gorilla.y < -240)then
				return 0, 640
			--
			elseif(gorilla.x < 360 and gorilla.y <= 160 and gorilla.y >= -240)then
				return 0, (gorilla.y-160)*-1
			--
			elseif(gorilla.x >= 360 and gorilla.x <= 1080 and gorilla.y <= 160 and gorilla.y >= -240)then
				return (gorilla.x-240)*-1, (gorilla.y-160)*-1
			--
			end
			--
		elseif backgroundSize == "m" then
			if(gorilla.x < 240 and gorilla.y > 160)then
				return 0,0
			--
			elseif(gorilla.x >= 240 and gorilla.x <= 720 and gorilla.y > 160)then
				return (gorilla.x-240)*-1, 0
			--
			elseif(gorilla.x > 720 and gorilla.y > 160)then
				return -480 , 0
			--
			elseif(gorilla.x > 720 and gorilla.y <= 160 and gorilla.y >= -160)then
				return -480, (gorilla.y-160)*-1
			--
			elseif(gorilla.x > 720 and gorilla.y < -160)then
				return -480, 320
			--
			elseif(gorilla.x >= 240 and gorilla.x <= 720 and gorilla.y < -160)then
				return (gorilla.x-240)*-1, 320
			--
			elseif(gorilla.x < 240 and gorilla.y < -160)then
				return 0, 320
			--
			elseif(gorilla.x < 240 and gorilla.y <= 160 and gorilla.y >= -160)then
				return 0, (gorilla.y-160)*-1
			--
			elseif(gorilla.x >= 240 and gorilla.x <= 720 and gorilla.y <= 160 and gorilla.y >= -160)then
				return (gorilla.x-240)*-1, (gorilla.y-160)*-1
			--
			end
			--
		else
			return 0,0
		end
	end
	
	local function onGuardCollision(self, event)
		if event.phase == "began" then
			if event.other.myName == "gorilla" then
				if soundsOn == "yes" then audio.play(hurtSound); end
				loadingImage:toFront()
				transition.to(loadingImage, {time = 1000, alpha = 1})
				timer.performWithDelay(1000, resetLevel, 1)
			elseif event.other.myName == "crate" or event.other.myName == "wall" or 
					event.other.myName == "ladder" or event.other.myName == "guard" or 
					event.other.myName == "beartrap" or event.other.myName == "fullcage" then					
				if self.direction == "right" then
					self.isVisible = false
					self.direction = "left"
					for i=1,table.maxn(guard)do
						if guard[i] == self then
							guardLeft[i].isVisible = true
						end
					end
					
				else
					self.isVisible = true
					self.direction = "right"
					for i=1,table.maxn(guard)do
						if guard[i] == self then
							guardLeft[i].isVisible = false
						end
					end
				end
			end
		end
	end
	
	local function onBearTrapCollision(self, event)
		if event.phase == "began" and event.other.myName == "gorilla" and animationDone then
			if soundsOn == "yes" then audio.play(hurtSound); end
			bearTrapClosed.x = self.x
			bearTrapClosed.y = self.y-20
			self.isVisible = false
			bearTrapClosed.isVisible = true
			animationDone = false
			physics.pause()
			gorilla:stopAtFrame(1)
			gorillaLeft:stopAtFrame(1)
			timer.performWithDelay(1, function() event.other.x = self.x; end, 1)
			timer.performWithDelay(1, function() event.other.y = bearTrapClosed.y; end, 1)
			loadingImage:toFront()
			transition.to(loadingImage, {time = 1000, alpha = 1})
			timer.performWithDelay(1000, resetLevel, 1)
		end
	end
	
	local function createLadder(ladder, size)
		local step = {}
		--
		if size == "l" then
			for i=1,3 do
				step[i] = display.newRect(ladder.x-25,(ladder.y+175)-115*i,35,5)
				gameGroup:insert(step[i])
				physics.addBody(step[i], "static", {bounce = 0, friction = 1})
				step[i].collision = onGroundCollision
				step[i]:addEventListener("collision", step[i])
				step[i].preCollision = onPlatformPreCollision
				step[i]:addEventListener("preCollision", step[i])
				step[i].isVisible = false
				step[i].myName = "ladder"
			end
		elseif size == "m" then
			for i=1,2 do
				step[i] = display.newRect(ladder.x-25,(ladder.y+120)-115*i,35,5)
				gameGroup:insert(step[i])
				physics.addBody(step[i], "static", {bounce = 0, friction = 1})
				step[i].collision = onGroundCollision
				step[i]:addEventListener("collision", step[i])
				step[i].preCollision = onPlatformPreCollision
				step[i]:addEventListener("preCollision", step[i])
				step[i].isVisible = false
				step[i].myName = "ladder"
			end
		--	
		end
	end
	
	local function updateTime()
		hudTime = (system.getTimer() - t1)/10
		timerText = string.format("%02d:%02d", (hudTime/100), hudTime%100)
		hudTimer.text = timerText
		hudTimer:setReferencePoint(TopLeftReferencePoint)
		hudTimer.x = 440; hudTimer.y = 15
	end
	
	local function updateGuards()
		for i=1, table.maxn(guard) do
			if guard[i].direction == "right" then
				guard[i].x = guard[i].x + guardSpeed
			else
				guard[i].x = guard[i].x - guardSpeed
				guardLeft[i].x = guard[i].x; guardLeft[i].y = guard[i].y;
			end
		end
	end
	
	local function finishCreatingPlatforms()
		for i = table.maxn(platform),1,-1 do
			platform[i]:setFillColor(100,100,100)
			gameGroup:insert(platform[i])
			physics.addBody(platform[i], "static", {bounce = 0, friction = 1})
			platform[i].collision = onGroundCollision
			platform[i]:addEventListener("collision", platform[i])
			platform[i].preCollision = onPlatformPreCollision
			platform[i]:addEventListener("preCollision", platform[i])
			local platformEdgeLeft = display.newRect(platform[i].x-platform[i].width/2,platform[i].y-10,5,5)
			local platformEdgeRight = display.newRect(platform[i].x+platform[i].width/2-10,platform[i].y-10,5,5)
			gameGroup:insert(platformEdgeLeft)
			gameGroup:insert(platformEdgeRight)
			physics.addBody(platformEdgeLeft,"static",{isSensor=true})
			physics.addBody(platformEdgeRight,"static",{isSensor=true})
			platformEdgeLeft.myName = "wall"
			platformEdgeRight.myName = "wall"
			platformEdgeLeft.isVisible = false
			platformEdgeRight.isVisible = false
		end	
	end
	
	local function correctLayers()
		if background then background:toFront(); end
		for i=1,table.maxn(window) do
			window[i]:toFront()
		end
		if door then door:toFront(); end
		if lock then lock:toFront(); end
		for i=1,table.maxn(crate) do
			crate[i]:toFront()
		end
		for i=1,table.maxn(ladder) do
			ladder[i]:toFront()
		end
		for i=1,table.maxn(bearTrap) do
			bearTrap[i]:toFront()
		end
		for i=1,table.maxn(fullCage) do
			fullCage[i]:toFront()
		end
		for i=1,table.maxn(guard) do
			guard[i]:toFront()
		end
		for i=1,table.maxn(guardLeft) do
			guardLeft[i]:toFront()
		end
		for i=1,table.maxn(platform) do
			platform[i]:toFront()
		end
		if key then key:toFront(); end
		if jumpLeftCover then jumpLeftCover:toFront(); end
		if jumpRightCover then jumpRightCover:toFront(); end
		if gorillaLeft then gorillaLeft:toFront(); end
		if gorilla then gorilla:toFront(); end
		if bearTrapClosed then bearTrapClosed:toFront(); end
	end
	
	local function performZoomAnimation()
		if backgroundSize == "l" then
			gameGroup.xScale = 1/3; gameGroup.yScale = 1/3;
			gameGroup.y = 213
			animationStartTimer = timer.performWithDelay(1500, 
				--find out where to zoom in to
				function()
					local x,y = whereToZoomInTo()
					--
					zoomAnimation = transition.to(gameGroup, {time = 2000, x = x, y = y, xScale = 1, yScale = 1, 
					onComplete = function() 
							animationDone=true; t1 = system.getTimer();
					end});
					--
				end, 1)
		elseif backgroundSize == "m" then
			gameGroup.xScale = .5; gameGroup.yScale = .5;
			gameGroup.y = 160
			animationStartTimer = timer.performWithDelay(1500, 
				--find out where to zoom in to
				function() 
					local x,y = whereToZoomInTo()
					--
					zoomAnimation = transition.to(gameGroup, {time = 2000, x = x, y = y, xScale = 1, yScale = 1, 
					onComplete = function() 
							animationDone=true; t1 = system.getTimer();
					end});
					--
				end, 1)		
		else
			animationDone = true
			t1 = system.getTimer()
		end
	end
	----------------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------------
	
	-- THESE ITEMS ARE CREATED ON EVERY LEVEL --
	local function createItemsForEveryLevel()
		--HUD CONTROLS
		if hudControlsOn == "yes" then
			-- RIGHT ARROW BUTTON --
			local rightArrowBtn
			local onArrowTouch = function( event )
				if event.phase == "press" then
					if event.id == "rightarrow" and gamePaused == false then
						rightArrowDown = true
					elseif event.id == "leftarrow" and gamePaused == false then
						leftArrowDown = true
					end
				elseif event.phase == "release" then				
					if event.id == "rightarrow" and gamePaused == false then
						rightArrowDown = false
					elseif event.id == "leftarrow" and gamePaused == false then
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
			rightArrowBtn.x = 100; rightArrowBtn.y = 285;
			hudGroup:insert( rightArrowBtn )
			-- END ABOUT BUTTON --
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
			leftArrowBtn.x = 40; leftArrowBtn.y = 285;
			hudGroup:insert( leftArrowBtn )
			rightArrowBtn.alpha = .5
			leftArrowBtn.alpha = .5
			-- END LEFT ARROW BUTTON
		end
		
		--PAUSE GROUP
		pauseScreen = display.newRoundedRect(0,0,300,200,12)
		pauseScreen.x = 240; pauseScreen.y = 160
		pauseScreen:setFillColor(0,0,0)
		pauseGroup:insert(pauseScreen)
		pauseScreen.alpha = 0
		
		
		--PAUSE BUTTON --
		local onPauseRelatedButtonTouch = function( event )
			if event.phase == "release" then	
				if soundsOn == "yes" then audio.play(clickSound); end	
				if event.id == "pausebutton" and gamePaused == false then
					if zoomAnimation then transition.cancel(zoomAnimation); end
					if animationStartTimer then timer.cancel(animationStartTimer); end
					animationDone = true
					if backgroundSize == "l" then
						gameGroup.yScale = 1/3
						gameGroup.xScale = 1/3
						gameGroup.y = 213
						gameGroup.x = 0
					elseif backgroundSize == "m" then
						gameGroup.yScale = .5
						gameGroup.xScale = .5
						gameGroup.y = 160
						gameGroup.x = 0
					end
					gamePaused = true
					physics.pause()
					pauseGroup.isVisible = true
					
					if gorillaSpeed ~= 0 then
						gorilla:stop()
						gorillaLeft:stop()
						gorillaWasRunning = true
					end
					
					for i=table.maxn(guard),1,-1 do
						guard[i]:stop()
						guardLeft[i]:stop()
					end
					
				elseif event.id == "restartbutton" then
					resetLevel()
				elseif event.id == "menubutton" then
					director:changeScene("mainmenu")
				elseif event.id == "playbutton" then
					if gorillaWasRunning then
						gorilla:play()
						gorillaLeft:play()
						gorillaWasRunning = false
					end
					
					for i=table.maxn(guard),1,-1 do
						guard[i]:play()
						guardLeft[i]:play()
					end
					
					timer.performWithDelay(100,
					function()
						gameGroup.yScale = 1
						gameGroup.xScale = 1
						
						gameGroup.x, gameGroup.y = whereToZoomInTo()
						gamePaused = false
						physics.start()
						pauseGroup.isVisible = false
						t1 = system.getTimer() - hudTime*10
					end
					, 1)
				end
			end
		end
		pauseBtn = ui.newButton{
			defaultSrc = "images/pause-button.png",
			defaultX = 36,
			defaultY = 27,
			overSrc = "images/pause-button-pressed.png",
			overX = 36,
			overY = 27,
			onEvent = onPauseRelatedButtonTouch,
			id = "pausebutton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		pauseBtn.x = 25; pauseBtn.y = 20;
		hudGroup:insert( pauseBtn )
		-- END PAUSE BUTTON
		restartBtn = ui.newButton{
			defaultSrc = "images/restart-button.png",
			defaultX = 80,
			defaultY = 44,
			overSrc = "images/restart-button-pressed.png",
			overX = 80,
			overY = 44,
			onEvent = onPauseRelatedButtonTouch,
			id = "restartbutton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		restartBtn.x = 150; restartBtn.y = 200;
		restartBtn.alpha = .7
		pauseGroup:insert( restartBtn )
		menuBtn = ui.newButton{
			defaultSrc = "images/menu-button.png",
			defaultX = 80,
			defaultY = 44,
			overSrc = "images/menu-button-pressed.png",
			overX = 80,
			overY = 44,
			onEvent = onPauseRelatedButtonTouch,
			id = "menubutton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		menuBtn.x = 240; menuBtn.y = 200;
		menuBtn.alpha = .7
		pauseGroup:insert( menuBtn )
		playBtn = ui.newButton{
			defaultSrc = "images/play-button.png",
			defaultX = 80,
			defaultY = 44,
			overSrc = "images/play-button-pressed.png",
			overX = 80,
			overY = 44,
			onEvent = onPauseRelatedButtonTouch,
			id = "playbutton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		playBtn.x = 330; playBtn.y = 200;
		playBtn.alpha = .7
		pauseGroup:insert( playBtn )

		pauseText = display.newText("Game Is Paused.", 0,0,"helvetica",30)
		pauseText.x = 240; pauseText.y = 130
		pauseGroup:insert(pauseText)
		pauseGroup.isVisible = false

	 	hudTimer = display.newText("00:00", 430,25,"helvetica",16)
		hudGroup:insert(hudTimer)
		hudTimer.x = 440; hudTimer.y = 15
		
		loadingImage = display.newRect(0,0, 480, 320 )
		loadingImage.x = 240; loadingImage.y = 160;
		loadingImage:setFillColor(150,150,150)
		hudGroup:insert(loadingImage)
		loadingImage.alpha = 0
		
		lock = display.newImageRect("images/lock.png", 38,43)
		gameGroup:insert(lock)
		lock.isVisible = false
		
		bearTrapClosed = display.newImageRect("images/beartrap-closed.png", 19,37)
		gameGroup:insert(bearTrapClosed)
		bearTrapClosed.isVisible = false
	end
	--CREATE BOUNDARIES
	local function createBoundaries()
		if backgroundSize == "l" then
			ground = display.newRect(0,315,1440,10)
			ground.isVisible = false
			gameGroup:insert(ground)
			physics.addBody(ground, "static", {bounce = 0, friction = 1})
			ground.collision = onGroundCollision
			ground.myName = "ground"
			ground:addEventListener("collision", ground)

			leftWall = display.newRect(-2,-320,6,960)
			leftWall.isVisible = false
			gameGroup:insert(leftWall)
			physics.addBody(leftWall, "static", {bounce = 0, friction = 1})
			leftWall.myName = "wall"

			rightWall = display.newRect(1440,-320,6,960)
			rightWall.isVisible = false
			gameGroup:insert(rightWall)
			physics.addBody(rightWall, "static", {bounce = 0, friction = 1})
			rightWall.myName = "wall"

			ceiling = display.newRect(0,-640,1440,6)
			ceiling.isVisible = false
			gameGroup:insert(ceiling)
			physics.addBody(ceiling, "static", {bounce = 0, friction = 1})
		elseif backgroundSize == "m" then
			ground = display.newRect(0,315,960,10)
			ground.isVisible = false
			gameGroup:insert(ground)
			physics.addBody(ground, "static", {bounce = 0, friction = 1})
			ground.collision = onGroundCollision
			ground.myName = "ground"
			ground:addEventListener("collision", ground)

			leftWall = display.newRect(-2,-320,6,640)
			leftWall.isVisible = false
			gameGroup:insert(leftWall)
			physics.addBody(leftWall, "static", {bounce = 0, friction = 1})
			leftWall.myName = "wall"

			rightWall = display.newRect(960,-320,6,640)
			rightWall.isVisible = false
			gameGroup:insert(rightWall)
			physics.addBody(rightWall, "static", {bounce = 0, friction = 1})
			rightWall.myName = "wall"

			ceiling = display.newRect(0,-320,960,6)
			ceiling.isVisible = false
			gameGroup:insert(ceiling)
			physics.addBody(ceiling, "static", {bounce = 0, friction = 1})
		elseif backgroundSize == "s" then
			ground = display.newRect(0,315,960,10)
			ground.isVisible = false
			gameGroup:insert(ground)
			physics.addBody(ground, "static", {bounce = 0, friction = 1})
			ground.collision = onGroundCollision
			ground.myName = "ground"
			ground:addEventListener("collision", ground)

			leftWall = display.newRect(-2,0,6,320)
			leftWall.isVisible = false
			gameGroup:insert(leftWall)
			physics.addBody(leftWall, "static", {bounce = 0, friction = 1})
			leftWall.myName = "wall"

			rightWall = display.newRect(480,0,6,320)
			rightWall.isVisible = false
			gameGroup:insert(rightWall)
			physics.addBody(rightWall, "static", {bounce = 0, friction = 1})
			rightWall.myName = "wall"

			ceiling = display.newRect(0,0,480,6)
			ceiling.isVisible = false
			gameGroup:insert(ceiling)
			physics.addBody(ceiling, "static", {bounce = 0, friction = 1})
		end
	end
	--CREATE THE GORILLA
	local function createGorilla()
		gorilla = movieclip.newAnim({"images/gorilla/gorillaright1.png","images/gorilla/gorillaright2.png","images/gorilla/gorillaright3.png",
											"images/gorilla/gorillaright4.png","images/gorilla/gorillaright5.png","images/gorilla/gorillaright6.png",
											"images/gorilla/gorillaright7.png",}, 83, 58)
		gorilla.x = 110; gorilla.y = 265;
		gorilla.movingRight = false
		gorilla.movingLeft = false
		gorilla.direction = "right"
		gorilla.myName = "gorilla"
		local gorillaShape = {-25,-25, 25,-25, 25,25, -25,25}
		physics.addBody(gorilla, {bounce = 0, friction = 1, shape = gorillaShape})
		gorilla.isFixedRotation = true

		gorillaLeft = movieclip.newAnim({"images/gorilla/gorillaleft1.png","images/gorilla/gorillaleft2.png","images/gorilla/gorillaleft3.png",
											"images/gorilla/gorillaleft4.png","images/gorilla/gorillaleft5.png","images/gorilla/gorillaleft6.png",
											"images/gorilla/gorillaleft7.png",}, 83, 58)
		gorillaLeft.x = -110; gorillaLeft.y = 265;
		gorillaLeft.isVisible = false
		gorilla:setSpeed(.5)
		gorillaLeft:setSpeed(.5)
		jumpRightCover = display.newImageRect("images/gorilla/gorillaright2.png", 83, 58)
		jumpLeftCover = display.newImageRect("images/gorilla/gorillaleft2.png", 83, 58)
		jumpRightCover.isVisible = false
		jumpLeftCover.isVisible = false
		gameGroup:insert(gorilla)
		gameGroup:insert(gorillaLeft)
		gameGroup:insert(jumpRightCover)
		gameGroup:insert(jumpLeftCover)
	end
	---------------------------------------------------------------------------------------------
	--****************************************************************************************************************************************************************
	-- create level objects from json string
	--****************************************************************************************************************************************************************
	local function createLevel()
		for i = 1,table.maxn(levelTable) do
			--
			if levelTable[i]:sub(1,1) == "s" then
				if levelTable[i]:sub(3,3) == "s" then
					background = display.newImageRect("images/levelbackground-small.png",480,320)
					background.x = 240; background.y = 160;
					gameGroup:insert(background)
					backgroundSize = "s"
					boundaryWidth = 480; boundaryHeight = 160;
				elseif levelTable[i]:sub(3,3) == "m" then
					background = display.newImageRect("images/levelbackground-medium.png",960,640)
					background.x = 480; background.y = 0;
					gameGroup:insert(background)
					backgroundSize = "m"
					boundaryWidth = 960; boundaryHeight = 320;
				elseif levelTable[i]:sub(3,3) == "l" then
					background = display.newImageRect("images/levelbackground-large.png",1440,960)
					background.x = 720; background.y = -160;
					gameGroup:insert(background)
					backgroundSize = "l"
					boundaryWidth = 1440; boundaryHeight = 480;
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
				physics.addBody(crate[c], {bounce = 0.1, friction = .5})
				gameGroup:insert(crate[c])
				crate[c].myName = "crate"
				crate[c].collision = onGroundCollision
				crate[c]:addEventListener("collision", crate[c])
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
				physics.addBody(bearTrap[b], {bounce = 0.1, friction = .5})
				gameGroup:insert(bearTrap[b])
				bearTrap[b].myName = "beartrap"
				bearTrap[b].collision = onBearTrapCollision
				bearTrap[b]:addEventListener("collision", bearTrap[b])
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
				physics.addBody(fullCage[b], {bounce = 0.1, friction = 2, density = 100})
				gameGroup:insert(fullCage[b])
				fullCage[b].myName = "fullcage"
				fullCage[b].collision = onGroundCollision
				fullCage[b]:addEventListener("collision", fullCage[b])
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
				key = display.newImageRect("images/key.png", 45,29)
				key.x = x; key.y = y;
				physics.addBody(key, "static", {isSensor = true})
				gameGroup:insert(key)
				key.collision = onKeyCollision
				key:addEventListener("collision", key)
				hasKey = false
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
				door = display.newImageRect("images/door.png", 56,111)
				door.x = x; door.y = y;
				physics.addBody(door, "static", {isSensor = true})
				gameGroup:insert(door)
				door.collision = onDoorCollision
				door:addEventListener("collision", door)
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
					table.insert(ladder, display.newImageRect("images/ladder-large.png", 60,356))
				else
					table.insert(ladder, display.newImageRect("images/ladder-medium.png", 60,227))
				end
				local l = table.maxn(ladder)
				ladder[l].x = x; ladder[l].y = y;
				gameGroup:insert(ladder[l])				
				createLadder(ladder[l], size)
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
					table.insert(guard, movieclip.newAnim({"images/guard/whiteright1.png", "images/guard/whiteright2.png", 
														"images/guard/whiteright3.png", "images/guard/whiteright4.png", 
														"images/guard/whiteright5.png", "images/guard/whiteright6.png", }, 33, 53))
					table.insert(guardLeft, movieclip.newAnim({"images/guard/whiteleft1.png", "images/guard/whiteleft2.png", 
														"images/guard/whiteleft3.png", "images/guard/whiteleft4.png", 
														"images/guard/whiteleft5.png", "images/guard/whiteleft6.png", }, 33, 53))
				else
					table.insert(guard, movieclip.newAnim({"images/guard/blackright1.png", "images/guard/blackright2.png", 
														"images/guard/blackright3.png", "images/guard/blackright4.png", 
														"images/guard/blackright5.png", "images/guard/blackright6.png", }, 33, 53))
					
					table.insert(guardLeft, movieclip.newAnim({"images/guard/blackleft1.png", "images/guard/blackleft2.png", 
														"images/guard/blackleft3.png", "images/guard/blackleft4.png", 
														"images/guard/blackleft5.png", "images/guard/blackleft6.png", }, 33, 53))
				end
				local g = table.maxn(guard)
				gameGroup:insert(guard[g])
				gameGroup:insert(guardLeft[g])
				guard[g].x = x; guard[g].y = y;
				if direction == "r" then
					guardLeft[g].isVisible = false
					guard[g].direction = "right"
				else
					guard[g].isVisible = false
					guard[g].direction = "left"
				end
				guard[g]:setSpeed(.2)
				guardLeft[g]:setSpeed(.2)
				guard[g]:play()
				guardLeft[g]:play()
				physics.addBody(guard[g], {})
				guard[g].isFixedRotation = true
				guard[g].collision = onGuardCollision
				guard[g]:addEventListener("collision", guard[g])
				guard[g].myName = "guard"
			--
			end
		end
		--
		if hasKey == false then lock.isVisible = true; lock.x = door.x; lock.y = door.y; end
		finishCreatingPlatforms()
		correctLayers()
	end
	--***************************************************************************************************************************************************************
	--
	--****************************************************************************************************************************************************************
	resetLevel = function()
		saveValue("current-level.data", currentLevel)
		director:changeScene("loadlevel")
	end
	-------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------
	
	-- GAME LOOP
	local function gameLoop(event)
		if animationDone and gamePaused == false then
			updateTime()
			
			--move gorilla hud control style
			if hudControlsOn == "yes" then
				if onGround then
					if rightArrowDown then
						if(gorilla.movingRight == false)then
							gorilla.direction = "right"
							gorilla.isVisible = true
							gorillaLeft.isVisible = false
							gorillaLeft:stopAtFrame(1)
							gorilla.movingRight = true
							gorilla.movingLeft = false
							gorilla:play()
						end

						gorillaSpeed = 10
						gorilla.x = gorilla.x + gorillaSpeed

					elseif leftArrowDown then
						if(gorilla.movingLeft == false)then
							gorilla.direction = "left"
							gorilla.isVisible = false
							gorilla:stopAtFrame(1)
							gorilla.movingLeft = true
							gorilla.movingRight = false
							gorillaLeft:play()
							gorillaLeft.isVisible = true
						end

						gorillaSpeed = -10
						gorilla.x = gorilla.x + gorillaSpeed
					else
						if(gorilla.movingRight)then
							gorilla.movingRight = false
							gorilla:stopAtFrame(1)
						elseif(gorilla.movingLeft)then
							gorilla.movingLeft = false
							gorillaLeft:stopAtFrame(1)
						end
						
						gorillaSpeed = 0
					end
				else
					if rightArrowDown then
						if(gorilla.movingRight == false)then
							gorilla.direction = "right"
							jumpLeftCover.isVisible = false
							jumpRightCover.isVisible = true
							gorilla.movingRight = false
							gorilla.movingLeft = false
						end
						gorillaSpeed = 5
						gorilla.x = gorilla.x + gorillaSpeed
					elseif leftArrowDown then
						if(gorilla.movingLeft == false)then
							gorilla.direction = "left"
							jumpLeftCover.isVisible = true
							jumpRightCover.isVisible = false
							gorilla.movingRight = false
							gorilla.movingLeft = false
						end
						gorillaSpeed = -5
						gorilla.x = gorilla.x + gorillaSpeed
					end
				end
			end
		end

		--boundary checks and move camera
		if backgroundSize == "l" then
			if gorilla.y > 320 - 15 then
				gorilla.isSensor = false
				gorilla.y = 320 - 30
			elseif gorilla.x > 1440 - 15 then
				gorilla.isSensor = false
				gorilla.x = 1440 - 30
			elseif gorilla.x < 15 then
				gorilla.isSensor = false
				gorilla.x = 30
			elseif gorilla.y < -640+15 then
				gorilla.isSensor = false
				gorilla.y = -640+30
			end
			
			--move the camera
			if(animationDone and gamePaused == false) then
				if(gorilla.x >= 240 and gorilla.x <= 1440-240)then
					gameGroup.x = (gorilla.x-240)*-1
				elseif gorilla.x < 240 then
					gameGroup.x = 0
				elseif gorilla.x > 1440-240 then
					gameGroup.x = -960
				end
				if(gorilla.y <= 160 and gorilla.y >= -480)then
					gameGroup.y = (gorilla.y-160)*-1
				elseif gorilla.y > 160 then
					gameGroup.y = 0
				elseif gorilla.y < -480 then
					gameGroup.y = 640
				end
				
			end
		elseif backgroundSize == "m" then----------------------------
			if gorilla.y > 320 - 15 then
				gorilla.isSensor = false
				gorilla.y = 320 - 30
			elseif gorilla.x > 960 - 15 then
				gorilla.isSensor = false
				gorilla.x = 960 - 30
			elseif gorilla.x < 15 then
				gorilla.isSensor = false
				gorilla.x = 30
			elseif gorilla.y < -320+15 then
				gorilla.isSensor = false
				gorilla.y = -320+30
			end
			
			--move the camera
			if(animationDone and gamePaused == false) then
				if(gorilla.x >= 238 and gorilla.x <= 722)then
					gameGroup.x = (gorilla.x-240)*-1
				elseif gorilla.x < 238 then
					gameGroup.x = 0
				elseif gorilla.x > 722 then
					gameGroup.x = -480
				end
				if(gorilla.y <= 160 and gorilla.y >= -160)then
					gameGroup.y = (gorilla.y-160)*-1
				elseif gorilla.y > 160 then
					gameGroup.y = 0
				elseif gorilla.y < -160 then
					gameGroup.y = 320
				end
			end
		end

		--move the guards
		if gamePaused == false then
			updateGuards()
		end	
		
		if gorillaLeft.isVisible then
			gorillaLeft.x = gorilla.x
			gorillaLeft.y = gorilla.y
		end

		if jumpRightCover.isVisible then jumpRightCover.x = gorilla.x; jumpRightCover.y = gorilla.y; end
		if jumpLeftCover.isVisible then jumpLeftCover.x = gorilla.x; jumpLeftCover.y = gorilla.y; end
		
	end
	Runtime:addEventListener( "enterFrame", gameLoop )
	
	-- SCREEN TOUCHED
	local function screenTouched(event)
		if animationDone == false and bearTrapClosed.isVisible == false then
			if zoomAnimation then transition.cancel(zoomAnimation); end
			if animationStartTimer then timer.cancel(animationStartTimer); end
			timer.performWithDelay(100, function() animationDone = true; end, 1)
			
			gameGroup.yScale = 1
			gameGroup.xScale = 1
			gameGroup.x, gameGroup.y = whereToZoomInTo()
			t1 = system.getTimer() - hudTime*10
		end
		
		if animationDone and gamePaused == false then
			if(event.phase=="began")then
				
			elseif(event.phase=="ended")then
				if onGround then
					local vx,vy = gorilla:getLinearVelocity()
					if vy > -10 and vy <= 100 and (event.x > 130 or event.y < 250) then
						if soundsOn == "yes" then audio.play(jumpSound); end
						gorilla:applyForce(gorillaSpeed/8, -13, gorilla.x, gorilla.y)
					end
				end
			end
		end
	end
	Runtime:addEventListener("touch", screenTouched)
	
	-- ON TILT
	local function onTilt( event )
		if animationDone and gamePaused == false and hudControlsOn == "no" then
			if onGround then
				if orientation == "landscapeRight" and event.yGravity < -.1 then
					if(gorilla.movingRight == false)then
						gorilla.direction = "right"
						gorilla.isVisible = true
						gorillaLeft.isVisible = false
						gorillaLeft:stopAtFrame(1)
						gorilla.movingRight = true
						gorilla.movingLeft = false
						gorilla:play()
					end
	
					gorillaSpeed = 4 * (event.yGravity-.3)*-1
					gorilla.x = gorilla.x + gorillaSpeed
	
				elseif orientation == "landscapeRight" and event.yGravity > .1 then
					if(gorilla.movingLeft == false)then
						gorilla.direction = "left"
						gorilla.isVisible = false
						gorilla:stopAtFrame(1)
						gorilla.movingLeft = true
						gorilla.movingRight = false
						gorillaLeft:play()
						gorillaLeft.isVisible = true
					end
	
					gorillaSpeed = 4 * (event.yGravity+.3)*-1
					gorilla.x = gorilla.x + gorillaSpeed
					
				elseif orientation == "landscapeLeft" and event.yGravity > .1 then
					if(gorilla.movingRight == false)then
						gorilla.direction = "right"
						gorilla.isVisible = true
						gorillaLeft.isVisible = false
						gorillaLeft:stopAtFrame(1)
						gorilla.movingRight = true
						gorilla.movingLeft = false
						gorilla:play()
					end

					gorillaSpeed = 4 * (event.yGravity+.3)
					gorilla.x = gorilla.x + gorillaSpeed

				elseif orientation == "landscapeLeft" and event.yGravity < -.1 then
					if(gorilla.movingLeft == false)then
						gorilla.direction = "left"
						gorilla.isVisible = false
						gorilla:stopAtFrame(1)
						gorilla.movingLeft = true
						gorilla.movingRight = false
						gorillaLeft:play()
						gorillaLeft.isVisible = true
					end

					gorillaSpeed = 4 * (event.yGravity-.3)
					gorilla.x = gorilla.x + gorillaSpeed
			
				else
					if(gorilla.movingRight)then
						gorilla.movingRight = false
						gorilla:stopAtFrame(1)
					elseif(gorilla.movingLeft)then
						gorilla.movingLeft = false
						gorillaLeft:stopAtFrame(1)
					end
			
					gorillaSpeed = 0
	
				end
			else
				if orientation == "landscapeRight" and event.yGravity < -.1 then
					if(gorilla.movingRight == false)then
						gorilla.direction = "right"
						jumpLeftCover.isVisible = false
						jumpRightCover.isVisible = true
						gorilla.movingRight = false
						gorilla.movingLeft = false
					end
					
					gorillaSpeed = 4 * (event.yGravity-.3)*-1
					gorilla.x = gorilla.x + gorillaSpeed
					
				elseif orientation == "landscapeRight" and event.yGravity > .1 then
					if(gorilla.movingLeft == false)then
						gorilla.direction = "left"
						jumpLeftCover.isVisible = true
						jumpRightCover.isVisible = false
						gorilla.movingRight = false
						gorilla.movingLeft = false
					end
					
					gorillaSpeed = 4 * (event.yGravity+.3)*-1
					gorilla.x = gorilla.x + gorillaSpeed
					
				elseif orientation == "landscapeLeft" and event.yGravity > .1 then
					if(gorilla.movingRight == false)then
						gorilla.direction = "right"
						jumpLeftCover.isVisible = false
						jumpRightCover.isVisible = true
						gorilla.movingRight = false
						gorilla.movingLeft = false
					end

					gorillaSpeed = 4 * (event.yGravity+.3)
					gorilla.x = gorilla.x + gorillaSpeed

				elseif orientation == "landscapeLeft" and event.yGravity < -.1 then
					if(gorilla.movingLeft == false)then
						gorilla.direction = "left"
						jumpLeftCover.isVisible = true
						jumpRightCover.isVisible = false
						gorilla.movingRight = false
						gorilla.movingLeft = false
					end

					gorillaSpeed = 4 * (event.yGravity-.3)
					gorilla.x = gorilla.x + gorillaSpeed
			
				end
			end
		end
	end
	Runtime:addEventListener( "accelerometer", onTilt )
	
	-- ON SYSTEM
	local function onSystem( event )
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
	-------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------
	createItemsForEveryLevel()
	createGorilla()
	createLevel()
	createBoundaries()
	performZoomAnimation()
	-------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------
	
	--UNLOAD THE LEVEL
	unloadMe = function()
		-- STOP PHYSICS ENGINE
		--physics.stop()
				
		-- REMOVE EVENT LISTENERS
		Runtime:removeEventListener("enterFrame", gameLoop)
		Runtime:removeEventListener("touch", screenTouched)
		Runtime:removeEventListener("system", onSystem)
		Runtime:removeEventListener("accelerometer", onTilt)
		Runtime:removeEventListener("orientation", onOrientationChange)
		
		--REMOVE everything in other groups
		for i = pauseGroup.numChildren,1,-1 do
			local child = pauseGroup[i]
			child.parent:remove( child )
			child = nil
		end
		for i = hudGroup.numChildren,1,-1 do
			local child = hudGroup[i]
			child.parent:remove( child )
			child = nil
		end
		--]]
						
		-- Stop any timers
		if timer1 then timer.cancel( timer1 ); end
		
	end
	
	-- MUST return a display.newGroup()
	return gameGroup
end
