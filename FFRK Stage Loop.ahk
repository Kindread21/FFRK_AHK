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

; How often to check if the app crashed/is waiting for retry connect/daily mission/etc.
recoveryCheckInterval := 30000

; How long since the last AHK mouseclick (manual clicks don't count!) to assume 
; the app is frozen and should be restarted.
idleRestartCheckInterval := 600000

; How long since the last AHK mouseclick (manual clicks don't count!) to assume 
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

FindImage( byRef imgX, byRef imgY, FullImage, searchWholeScreen:=false)
{
	global winX, winY, winW, winH
	
	searchWholeScreen := searchWholeScreen or forceFullScreenScan
	
	if (!searchWholeScreen)
	{
		x2 := winX +winW
		y2 := winY +winH
		
		ImageSearch, imgX, imgY, %winX%, %winY%, %x2%, %y2%, *100 %FullImage%
		
		return ErrorLevel
	}
	else
	{
		ImageSearch, imgX, imgY, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *100 %FullImage%
		
		return ErrorLevel
	}
}

ClickImage(type, imageName, sleepIfFound:=500, xOffset:=10, yOffset:=10, wholeScreen:=false)
{
	global ImageFolder, lastClickTick, giveBackControl, forceFullScreenScan

	FullImage = %ImageFolder%\%type%\%imageName%
	
	FindImage(imgX, imgY, FullImage, wholeScreen)

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

CheckForImageBeforeClickImage(typeImageToCheck, imageToCheck, typeImageToClick, imageToClick)
{
	global ImageFolder, forceFullScreenScan
  
	FullImage = %ImageFolder%\%typeImageToCheck%\%imageToCheck%   
	
	FindImage(imgX, imgY, FullImage, forceFullScreenScan)
	
	if (!ErrorLevel)
	{	
		ClickImage(typeImageToClick, imageToClick)	
	}
}

DragRightIfImageFound(typeImageToCheck, imageToCheck)
{
	global AppName, ImageFolder, forceFullScreenScan, winX, winY, winW, winH
   
    FullImage = %ImageFolder%\%typeImageToCheck%\%imageToCheck%
	
	FindImage(imgX, imgY, FullImage, forceFullScreenScan)
	
	dragFromX := winX + winWidth - 10
	dragToX := winX + 20
	dragY := winY + winHeight - 200
	
	MouseMove, %dragX%, %dragY%
	
	; Change mode so movement isn't instant
	SendMode Event
	MouseClickDrag, left, %dragFromX%, %dragY%, %dragToX%, %dragY%, 1
	
	; Change back
	SendMode Input
}

; Only click close if we're not in the DungeonStartScreen
SpecialClickCloseIfNotDungeonStart()
{
	global ImageFolder, forceFullScreenScan
   
	FullImage = %ImageFolder%\Basic\Enter.PNG
	FindImage(imgX, imgY, FullImage, forceFullScreenScan)
	
	if (ErrorLevel)
	{
		ClickImage("Recover", "Close.PNG")
	}
}

RunRecoverySteps(fncHomeToDungeon)
{
	ClickImage("Recover", "FFRKIcon.PNG", 20000)
	ClickImage("Nox", "NoxOpenAppAgain.PNG", 15000)
	ClickImage("Nox", "NoxOk.PNG", 15000)
	ClickImage("Nox", "NoxAccountError.PNG", 5000)

	ClickImage("Recover", "ConnectionRetry.PNG", 5000)
	
	ClickImage("Recover", "SoulbreakMasteredOk.PNG")

	;13h00 GMT reset. Acknowledge Reset Ok ->(Play)->2 Oks->Roaming Ok(brown)
	ClickImage("Recover", "OkReset.PNG", 15000)
	ClickImage("Recover", "PlayGame.PNG", 10000)
	ClickImage("Recover", "OKBattle.PNG", 5000)
	ClickImage("Recover", "OkReset.PNG", 5000)
	ClickImage("Recover", "OkReset.PNG", 5000)
	ClickImage("Recover", "OKRoamingReward.PNG", 10000)
	
	%fncHomeToDungeon%()
		
	;For Daily Mission Box. Could hit close while starting a missing.
	SpecialClickCloseIfNotDungeonStart()
		
	ClickImage("Basic", "GameOverNext.PNG")	
}

RunHomeToApocSteps()
{
	ClickImage("Recover", "EventAnchor1.PNG", 5000, 10, 100)
	ClickImage("Recover", "EventAnchor2.PNG", 5000, 10, 100)
	ClickImage("Recover", "EventDungeonsAnchor.PNG", 10000, 350)
	
	;Weekly Image Changes
	ClickImage("Weekly", "WeeklyApoc.PNG")
}

RunHomeToMagicite()
{
	DragRightIfImageFound("Recover", "EventAnchor1.PNG")
	ClickImage("Recover", "NightmareMagiciteAnchor.PNG", 5000, 10, 100)
}

RunHomeToMagiciteOdinSteps()
{
	RunHomeToMagicite()
	ClickImage("Magicite", "LordOfKnightsVortex.PNG", 5000, 10, 100)
}

RunRestartSteps()
{
	global ImageFolder, canCloseNoxInstance
   
    FullImage = %ImageFolder%\Nox\NoxMiMFFRK.PNG
	FindImage(imgX, imgY, FullImage, true)
	
	foundNoxMiM := !ErrorLevel
	
	FullImage = %ImageFolder%\Nox\NoxMiMStopButton.PNG
	FindImage(imgX2, imgY2, FullImage, true)
	
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
	ClickImage("Nox", "NoxMiMFFRK.PNG", 2000, 500, 10, true)
	ClickImage("Nox", "NoxMiMCloseInstanceConfirmation.PNG", 15000, 300, 100, true)
	ClickImage("Nox", "NoxMiMFFRK.PNG", 30000, 500, 10, true)
}

RunRestartAppSteps()
{
	ClickImage("Nox", "NoxAppsList.PNG", 3000, 10, 10, true)
	ClickImage("Nox", "NoxCloseApp.PNG", 2000, 140, 25)
	ClickImage("Nox", "NoxHome.PNG", 500, 10, 10, true)
}

ChooseFabulaRaider()
{
	ClickImage("Magicite", "FabulaRaider.PNG", 800, 400, 20)	
	CheckForImageBeforeClickImage("Magicite", "FabulaRaiderChosen.PNG", "Basic", "GoToDungeon.PNG")
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
	global lastClickTick, idleCheckInterval, closeOnIdle
	
	checkTick := A_TickCount - lastClickTick
	if checkTick > %idleCheckInterval%
	{
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

Loop,
{
	; Basic battle loop
	WinGetPos, winX, winY, winWidth, winHeight, %AppName%
	
	ClickImage("Basic", "AfterBattleNext.PNG")
	ClickImage("Apoc", "Apocalypse.PNG", 1000)
	ClickImage("Basic", "Enter.PNG")
	ClickImage("Basic", "SoloRaid.PNG")
	ClickImage("Basic", "BeforeBattleNext.PNG")	
	ClickImage("Basic", "RemoveRW.PNG",300)
	
	; Checks if 'Friend' Image is empty (RW deselected) before continuing
	CheckForImageBeforeClickImage("Basic", "NoFriend.PNG", "Basic", "GoToDungeon.PNG")
	
	; comment out the above and enable the below to use RWs (whatever is default chosen)
	; ClickImage("Basic", "GoToDungeon.PNG")	
	
	ClickImage("Apoc", "ApocStart.PNG", 800)
	ClickImage("Basic", "BeginBattle.PNG")	

	ClickImage("Basic", "GameOverNext.PNG")

	CheckForRecoverySteps(Func("RunHomeToApocSteps"))
	
	CheckForIdleRestart()
	
	Sleep 100
}

; Dark Odin Auto (I wish!). 
; Run from the screen AFTER Magicite stage select (ie, after clicking the vortex).
; Will retry on gameover, so if you have a really luck based auto run you can 
; leave this running to bruteforce it.
^2::

lastRecoverCheckTick := A_TickCount
lastClickTick := A_TickCount

idleCheckLongInterval := idleRestartLongCheckInterval

Loop,
{
	; Basic battle loop
	WinGetPos, winX, winY, winWidth, winHeight, %AppName%
	
	ClickImage("Basic", "AfterBattleNext.PNG")
	ClickImage("Odin", "Odin.PNG", 1000, 20, 200)
	ClickImage("Basic", "Enter.PNG")
	ClickImage("Basic", "BeforeBattleNext.PNG")	
	
	ChooseFabulaRaider()
	
	ClickImage("Odin", "DarkOdinStartAnchor.PNG", 800, 100)
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