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
			director:changeScene( "leveleditor" )
		end
		
		theTimer = timer.performWithDelay( 3000, goToLevel, 1 )
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
