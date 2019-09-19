#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

;---------------------------------------------;
;--------------- Configuration ---------------;

; The window Name. For Nox this is the same as the name of the instance. You can also use 
; WindowSpy, which comes with AHK, to check a window name.
AppName = FFRK_AHK

; The base folder where images to match are kept
ImageFolder := "C:\AHKSearch\FFRK"

; Experimental. After each image click it gives focus back to whatever window was open 
; before and moves the mouse back.
; Seems to rarely cause issues where the wrong place gets clicked at times. 
; To enable change the false to true. 
; It is toggle-able at runtime with ctrl+9 (this stops the ctrl+1 loop, so you will have
; to hit ctrl+1 again after).
giveBackControl := false

; How often, in milliseconds, to check if the app crashed/is waiting for retry connect/daily mission/etc.
recoveryCheckInterval := 30000

; How long, in milliseconds, since the last AHK mouseclick (manual clicks don't count!) to assume 
; the app is frozen and should be restarted.
idleRestartCheckInterval := 600000
;600000

; How long, in milliseconds, since the last AHK mouseclick (manual clicks don't count!) to assume 
; the app is frozen and should be restarted. For long battles
idleRestartLongCheckInterval := 1200000

; If true, and no clicks have been done for 10 minutes, this will attempt to restart the 
; nox instance or the app (depending on canCloseNoxInstance). 
; After that the normal recovery recovery from home should kick in and start the game.
closeOnIdle := true

; If this is true, and Nox MultiInstanceManager is completely visible, this will attempt
; to restart the instance if idle is detected.
; If both conditions aren't met then it will attempt to restart the app instead.
canCloseNoxInstance := true

; If true, this will force a scan of the whole screen for images. Can be noticably slower, 
; but avoids any issue with AHK not finding the window.
forceFullScreenScan := false

; If true, this allows ClickImage to search only a specified section of the app
allowSectionedSearch := true

; What it says on the tin.
allowStaminaRefresh := false

; Allowed Values: Potion Mythril Gems
staminaRefreshType := "Potion"

;---------------------------------------------;

;---------------------------------------------;
;bitflag values for sectioning. Don't change these if you don't understand bitflags
TopHalf := 1
BottomHalf := 2
LeftHalf := 4
RightHalf := 8
;---------------------------------------------;

SetMouseDelay 100
SetControlDelay 100

winX := 0
winY := 0
WinGetPos, winX, winY, winW, winH, %AppName%

CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

lastRecoverCheckTick := A_TickCount
lastClickTick := A_TickCount

idleCheckInterval := idleRestartCheckInterval

if forceFullScreenScan
{
	allowSectionedSearch = false
}

AdjustWindowCoordinatesToSpecifiedSection(section, byRef x1, byRef y1, byRef x2, byRef y2)
{
	global TopHalf, BottomHalf, LeftHalf, RightHalf, winW, winH
	
	; section is a bitflag
	
	if section = 0
	{
		return
	}

	if section & TopHalf
	{
		y2 := y2 - Round(winH/2)
	}
	else if section & BottomHalf
	{
		y1 := y1 + Round(winH/2)
	}
	
	if section & LeftHalf
	{
		x2 := x2 - Round(winW/2)
	}
	else if section & RightHalf
	{
		x1 := x1 + Round(winW/2)
	}
}

FindImage( byRef imgX, byRef imgY, section, FullImage, searchWholeScreen:=false)
{
	global winX, winY, winW, winH, allowSectionedSearch, forceFullScreenScan
	
	searchWholeScreen := searchWholeScreen or forceFullScreenScan
	
	x1 := winX
	y1 := winY
	
	x2 := winX +winW
	y2 := winY +winH
	
	if (!allowSectionedSearch)
	{
		section := 0
	}
		
	if searchWholeScreen
	{
		section := 0
		
		x1 := 0
		y1 := 0
		
		x2 := A_ScreenWidth
		y2 := A_ScreenHeight
	}

	AdjustWindowCoordinatesToSpecifiedSection(section, x1, y1, x2, y2)
	
	ImageSearch, imgX, imgY, %x1%, %y1%, %x2%, %y2%, *100 %FullImage%
	
	return ErrorLevel

}

ClickImage(type, imageName, section := 0, sleepIfFound:= 500, xOffset:= 10, yOffset:= 10, wholeScreen:=false)
{
	global ImageFolder, lastClickTick, giveBackControl, forceFullScreenScan

	FullImage = %ImageFolder%\%type%\%imageName%
	
	FindImage(imgX, imgY, section, FullImage, wholeScreen)

	if (!ErrorLevel)
	{
		if (giveBackControl)
		{
			
			; Save current window and mouse pos
			WinGet, ActiveId, ID, A
			MouseGetPos, lastMouseX, lastMouseY
		}

		MouseClick, left,  imgX+xOffset, imgY+yOffset
	  	
		if (giveBackControl)
		{
			Sleep 20
			; reactivate window and mouse pos before image click		
			MouseMove, %lastMouseX%, %lastMouseY%
			WinWaitNotActive, ahk_id %ActiveId%
			WinActivate, ahk_id %ActiveId%
		}
		
		Sleep %sleepIfFound%
	  
		lastClickTick := A_TickCount
	  
		return true
	}
	return false
}

CheckForImageBeforeClickImage(typeImageToCheck, imageToCheck, checkSection, typeImageToClick, imageToClick, clickSection, clickIfFound:=true, sleepIfClicked:= 500)
{
	global ImageFolder, forceFullScreenScan
  
	FullImage = %ImageFolder%\%typeImageToCheck%\%imageToCheck%   
	
	FindImage(imgX, imgY, checkSection, FullImage, forceFullScreenScan)
	
	mustClick = true;
	
	if clickIfFound
	{
		mustClick := ErrorLevel = 0
	}
	else
	{
		; Assume if the image file doesn't exist that this check shouldn't be done. 
		; IE, if ErrorLevel is 1, meaning image not found on screen, or 2, meaning
		; file could not be loaded.
		mustClick := ErrorLevel > 0
	}
	
	if (mustClick)
	{	
		return ClickImage(typeImageToClick, imageToClick, clickSection, sleepIfClicked)	
	}
	
	return 1
}

DragRightIfImageFound(typeImageToCheck, imageToCheck)
{
	global AppName, ImageFolder, forceFullScreenScan, winX, winY, winW, winH
   
    FullImage = %ImageFolder%\%typeImageToCheck%\%imageToCheck%
	
	FindImage(imgX, imgY, 0, FullImage, forceFullScreenScan)
	
	if (!ErrorLevel)
	{
		dragFromX := winX + winW - 10
		dragToX := winX + 20
		dragY := winY + winH - 200
	
		MouseMove, %dragX%, %dragY%
	
		; Change mode so movement isn't instant
		SendMode Event
		MouseClickDrag, left, %dragFromX%, %dragY%, %dragToX%, %dragY%, 1
	
		; Change back
		SendMode Input
	}
}

; Only click close if we're not in the DungeonStartScreen
SpecialClickCloseIfNotDungeonStart()
{
	global ImageFolder, forceFullScreenScan
   
	FullImage = %ImageFolder%\Basic\Enter.PNG
	FindImage(imgX, imgY, 0, FullImage, forceFullScreenScan)
	
	if (ErrorLevel)
	{
		ClickImage("Recover", "Close.PNG")
	}
}

RunRecoverySteps(fncHomeToDungeon)
{
	global allowStaminaRefresh, staminaRefreshType
	
	ClickImage("Recover", "FFRKIcon.PNG", 0, 20000)
	ClickImage("Nox", "NoxOpenAppAgain.PNG", 0,  15000)
	ClickImage("Nox", "NoxOk.PNG", 0, 15000)
	ClickImage("Nox", "NoxAccountError.PNG", 0, 5000)

	ClickImage("Recover", "ConnectionRetry.PNG", 0, 5000)
	
	ClickImage("Recover", "SoulbreakMasteredOk.PNG", BottomHalf)

	;13h00 GMT reset. Acknowledge Reset Ok ->(Play)->2 Oks->Roaming Ok(brown)
	CheckForImageBeforeClickImage("Recover", "AnotherDevice.PNG", 0, "Recover", "OkReset.PNG", 0, false, 15000)
	ClickImage("Recover", "PlayGame.PNG", BottomHalf, 10000)
	CheckForImageBeforeClickImage("Recover", "AnotherDevice.PNG", 0, "Recover", "OKBattle.PNG", 0, false, 5000)
	CheckForImageBeforeClickImage("Recover", "AnotherDevice.PNG", 0, "Recover", "OkReset.PNG", 0, false, 5000)
	CheckForImageBeforeClickImage("Recover", "AnotherDevice.PNG", 0, "Recover", "OkReset.PNG", 0, false, 5000)
	ClickImage("Recover", "OKRoamingReward.PNG", 0, 10000)
	
	%fncHomeToDungeon%()
		
	;For Daily Mission Box. Could hit close while starting a missing.
	SpecialClickCloseIfNotDungeonStart()
	
	if allowStaminaRefresh
	{
		refreshImageName = %staminaRefreshType%.PNG
		ClickImage("Refresh", refreshImageName, 0, 1000)
		ClickImage("Refresh", "Confirm.PNG", 0, 2000)
		CheckForImageBeforeClickImage("Recover", "AnotherDevice.PNG", 0, "Recover", "OkReset.PNG", 0, false, 1000)
	}	

	ClickImage("Refresh", "Back.PNG")
	
	ClickImage("Basic", "GameOverNext.PNG")	
}

RunHomeToApocSteps()
{
	ClickImage("Recover", "EventAnchor1.PNG", 0, 5000, 10, 100)
	ClickImage("Recover", "EventAnchor2.PNG", 0, 5000, 10, 100)
	ClickImage("Recover", "EventDungeonsAnchor.PNG", 0, 10000, 350)
	
	;Weekly Image Changes
	ClickImage("Weekly", "WeeklyApoc.PNG")
}

RunHomeToMagicite()
{
	DragRightIfImageFound("Recover", "EventAnchor1.PNG")
	ClickImage("Recover", "NightmareMagiciteAnchor.PNG", 0, 5000, 10, 100)
}

RunHomeToMagiciteOdinSteps()
{
	RunHomeToMagicite()
	ClickImage("Magicite", "LordOfKnightsVortex.PNG", 0, 5000, 10, 100)
}

RunRestartSteps()
{
	global ImageFolder, canCloseNoxInstance
   
    FullImage = %ImageFolder%\Nox\NoxMiMFFRK.PNG
	FindImage(imgX, imgY, 0, FullImage, true)
	
	foundNoxMiM := !ErrorLevel
	
	FullImage = %ImageFolder%\Nox\NoxMiMStopButton.PNG
	FindImage(imgX2, imgY2, 0, FullImage, true)
	
	foundNoxMiMStop := !ErrorLevel
	
	if (canCloseNoxInstance and foundNoxMiM and foundNoxMiMStop)
	{
		RunRestartInstanceSteps()
	}
	else
	{
		RunRestartAppSteps()
	}
}

RunRestartInstanceSteps()
{
	ClickImage("Nox", "NoxMiMFFRK.PNG", 0, 2000, 500, 10, true)
	ClickImage("Nox", "NoxMiMCloseInstanceConfirmation.PNG", 0, 15000, 300, 100, true)
	ClickImage("Nox", "NoxMiMFFRK.PNG", 0, 30000, 500, 10, true)
}

RunRestartAppSteps()
{
	ClickImage("Nox", "NoxAppsList.PNG", 0, 3000, 10, 10, true)
	ClickImage("Nox", "NoxCloseApp.PNG", 0, 2000, 140, 25)
	ClickImage("Nox", "NoxHome.PNG", 0, 500, 10, 10, true)
}

ChooseFabulaRaider()
{
	ClickImage("Magicite", "FabulaRaider.PNG", 0, 800, 400, 20)	
	CheckForImageBeforeClickImage("Magicite", "FabulaRaiderChosen.PNG", 0, "Basic", "GoToDungeon.PNG", 0)
}

; Gets from Nox home to a FFRK dungeon
CheckForRecoverySteps(fncHomeToDungeon)
{
	global lastRecoverCheckTick, recoveryCheckInterval
	
	checkTick := A_TickCount - lastRecoverCheckTick
	if checkTick > %recoveryCheckInterval% 
	{
		lastRecoverCheckTick := A_TickCount

		RunRecoverySteps(fncHomeToDungeon)
	}
}

CheckForIdleRestart()
{
	global lastClickTick, idleCheckInterval, closeOnIdle, ImageFolder
	
	checkTick := A_TickCount - lastClickTick
	if checkTick > %idleCheckInterval%
	{
		FullImage = %ImageFolder%\Recover\AnotherDevice.PNG
		FindImage(imgX, imgY, 0, FullImage)
		if ErrorLevel = 0
		{
		  return
		}
		lastClickTick := A_TickCount
		if (closeOnIdle)
		{
		  RunRestartSteps()
		}
	}
}

; Apocaplypse MP
^1::

lastRecoverCheckTick := A_TickCount
lastClickTick := A_TickCount

idleCheckInterval := idleRestartCheckInterval

#Include *i CheckForVPN.ahk

Loop,
{
	; Basic battle loop
	WinGetPos, winX, winY, winW, winH, %AppName%

	ClickImage("Basic", "AfterBattleNext.PNG", BottomHalf)
	ClickImage("Apoc", "Apocalypse.PNG", 0, 700)
	ClickImage("Basic", "Enter.PNG", BottomHalf)
	ClickImage("Basic", "SoloRaid.PNG", LeftHalf)
	ClickImage("Basic", "BeforeBattleNext.PNG", BottomHalf)	
	ClickImage("Basic", "RemoveRW.PNG", RightHalf, 300)
	
	; Checks if 'Friend' Image is empty (RW deselected) before continuing
	CheckForImageBeforeClickImage("Basic", "NoFriend.PNG", TopHalf | LeftHalf, "Basic", "GoToDungeon.PNG", BottomHalf)
	
	; comment out the above and enable the below to use RWs (whatever is default chosen)
	; ClickImage("Basic", "GoToDungeon.PNG")	
	
	ClickImage("Apoc", "ApocStart.PNG", 0, 800)
	ClickImage("Basic", "BeginBattle.PNG")	

	CheckForRecoverySteps(Func("RunHomeToApocSteps"))
	
	CheckForIdleRestart()
	
	Sleep 100
}

; Dark Odin Auto (I wish!). 
; Optimally, run from the screen AFTER Magicite stage select (ie, after clicking 
; the vortex). But it is able to pickup from any screen along the route.
; Will retry on gameover, so if you have a really luck based auto run you can 
; leave this running to bruteforce it.
^2::

lastRecoverCheckTick := A_TickCount
lastClickTick := A_TickCount

idleCheckLongInterval := idleRestartLongCheckInterval

Loop,
{
	; Basic battle loop
	WinGetPos, winX, winY, winW, winH, %AppName%
	
	ClickImage("Basic", "AfterBattleNext.PNG", BottomHalf)
	ClickImage("Odin", "Odin.PNG", 0, 1000, 20, 200)
	ClickImage("Basic", "Enter.PNG", BottomHalf)
	ClickImage("Basic", "BeforeBattleNext.PNG", BottomHalf)	
	
	ChooseFabulaRaider()
	
	ClickImage("Odin", "DarkOdinStartAnchor.PNG", 0, 800, 100)
	ClickImage("Basic", "BeginBattle.PNG")
	
	CheckForRecoverySteps(Func("RunHomeToMagiciteOdinSteps"))

	CheckForIdleRestart()
	
	Sleep 200
}

^9::
	giveBackControl := !giveBackControl
	msgBox giveBackControl = %giveBackControl%
	return


^`::reload
