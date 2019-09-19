#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


;msgbox, %A_IPAddress1%`n%A_IPAddress2%`n%A_IPAddress3%`n%A_IPAddress4%

if (A_IPAddress2 != A_IPAddress4)
msgBox VPN Is Enabled!
