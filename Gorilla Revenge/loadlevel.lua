-- 
-- Abstract: Ghosts Vs Monsters sample project 
-- Designed and created by Jonathan and Biffy Beebe of Beebe Games exclusively for Ansca, Inc.
-- http://beebegamesonline.appspot.com/

-- (This is easiest to play on iPad or other large devices, but should work on all iOS and Android devices)
-- 
-- Version: 1.0
-- 
-- Sample code is MIT licensed, see http://developer.anscamobile.com/code/license
-- Copyright (C) 2010 ANSCA Inc. All Rights Reserved.




module(..., package.seeall)

-- Main function - MUST return a display.newGroup()
function new()
	local localGroup = display.newGroup()
	
	local theTimer
	local loadingImage
	local loadingText
	
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
	
	--KILL THE AUDIO
	audio.stop()
	
	local showLoadingScreen = function()
		loadingImage = display.newRect(0,0, 480, 320 )
		loadingImage.x = 240; loadingImage.y = 160;
		loadingImage:setFillColor(150,150,150)
		
		loadingText = display.newText("loading..", 0,0,"helvetica", 30)
		loadingText:setReferencePoint(display.CenterTopReferencePoint)
		loadingText.x = 240; loadingText.y=161;
		
		loadingText2 = display.newText("loading..", 0,0,"helvetica", 30)
		loadingText2:setReferencePoint(display.CenterTopReferencePoint)
		loadingText2.x = 240; loadingText2.y=160;
		loadingText2:setTextColor(100,100,100)
		
		local goToLevel = function()
			director:changeScene( "level" .. loadValue("current-level.data") )
		end
		
		theTimer = timer.performWithDelay(1000, goToLevel, 1 )
	end
	
	showLoadingScreen()
	
	unloadMe = function()
		if theTimer then timer.cancel( theTimer ); end
		
		if loadingImage then
			loadingImage:removeSelf()
			loadingImage = nil
		end
		if loadingText then
			loadingText:removeSelf()
			loadingText = nil
		end
		if loadingText2 then
			loadingText2:removeSelf()
			loadingText2 = nil
		end
	end
	
	-- MUST return a display.newGroup()
	return localGroup
end
