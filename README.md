# FFRK_AHK
Autohotkey Scripts for playing FFRK

This is a Auto Hot Key Script (https://www.autohotkey.com/) developed mainly for farming MP Apoc using Nox. The basic run loop constantly checks the state of the game by looking for images, and clicking them. The advantage of this script over Nox recordings is that it is reactive, so it should be able to navigate the screens much quicker. It is also able to recover from crashes.

Every 30 seconds, the script checks if the app has crashed (specifically, if it is on Home), or is on one of the less common dialogs (such as Daily mission, or Connection Retry). If detected, it will attempt to navigate back to the dungeon so the loop can continue.

If no AHK driven mouse click has happened in 10 minutes, the script assumes the app is frozen. Depending on whether Nox MultiInstanceManager is visible, the script will attempt to either close the instance and restart (you can also disable this option in config, as it can be fragile), or just kill the FFRK app to return to home page. Then on the next 30 second check the 'get back to dungeon' routine will kick in.

## Basic Instructions:
If you have the setup described below, this should be all you need to do to get up and running.

Download and install AHK. Ensure it can run as Administrator.

Copy the images, with hierarchy intact, to C:\. You should end up with (note you can also change the directory in the config region of the script)
  
  C:\AHKSearch\FFRK

with folders named Apoc, Basic, Magicite, and others in it. You can copy the AHK script file whereever its convenient.

Open your Nox Instance. Ensure you have a Party that can autobattle the MP Apoc, with autobattle enabled. Navigate to the MP Apoc battle (Silver Dragon at the time of writing). You should be on the screen where you select the D180 or D220 battle. 

Run the script.

Press **Control and 1** together to start the script. If nothing happens you might need to tweak your setup, or bite the bullet and Get it to work for your setup.

Press **Control and Tilde (~)** to stop (it actually reloads the script).

## Upkeep
For Recovery to work, when a new Apoc comes out, you will have to overwrite AHKSearch\FFRK\Weekly\WeeklyApoc.PNG with a new image. If the home icon for FFRK changes, you will have to get a new pic of it and overwrite AHKSearch\FFRK\Recover\FFRKIcon.PNG.


## Setup:
This was developed and tested using the below setup. 

  * Nox instance name to FFRK_AHK (or change AppName in the script to match yours), with FFRK installed with your account.
  * Desktop scaling set to 125% (rightclick on desktop, Display Settings -> Display -> Scaling and Layout). If you change it to 125%, you should restart your PC as not all apps (Nox included) scale properly without a reboot.
  * AHK must be running as administrator to be allowed to Click. Find the exe in Program files\Autohotkeys and change it to always run as admin.
  * Nox 6.2.8.0
  * Android instance 7.1.2
  * Pin to Top enabled


If your setup is different, you should be able to get most of the features after about a half hour of work (mostly just using Snipping Tool to get your own images). 

If you would like to use a different emulator, you can try using the provided images. First have the emulator setup to the same resolution, and have the same Window Title (FFRK_AHK). If it renders pictures similarly to Nox it might just work.

### Emulator Settings

Resolution:
  Width: 480		Height: 800		DPI: 160		

Even if you use another emulator, you will have to use resolutions similar to this. If your emulator doesn't provide the option, but lets you resize the window, try to resize it to a 480x800 window (using Paint to make a 480x800 square as guide will help).

Interface Settings:

	Fixed Window size checked (to not accidentally drag the size)
	Remember Size and Position checked (If the script attempts to restart the instance this ensures the instance appears in the same place) and doesn't cover anything.

---------------------------------------------------------------------
  
## Getting it to work for a different Setup
Most functionality should work as long as you have correctly matching images for the scripts to use. If your setup doesn't match the test configuration exactly, capturing your own images should solve things.

But before going down that path, if you're happy with leaving your desktop scaling at 125%, see if you can get the provided images to work, even if you're not using Nox. If your emulator allows you to set the resolution to 480x800, and you can name the instance FFRK_AHK, its worth a try. If you still aren't seeing any clicks, open the script in a text editor, find 

  forceFullScreenScan := false
 
and change it to
  
  forceFullScreenScan := true
  
**Don't forget to save and restart the script after this. Ctrl + ~ t to reload from disk, Ctrl + 1 to start again.** This flag tells AHK to search the entire screen instead of trying to find the emulator window and search there. Its a fair bit slower though. 

If this now works when it didn't before, the issue was with AHK detecting the app. If you're happy with the speed you can use it like this. Otherwise you can try to investigate further, using WindowSpy (installed with AHK) to try to figure out what the Window Name is, and changing AppName in the script to match this.

If you still aren't getting clicks, you'll have to capture your own images. Leave forceFullScreenScan to true for now, and if you had to track down the Window Name note it somewhere. How much work you put into it depends on how robust you want the script to be.


### Fixing the Basic Run Loop
To start with, get the basic run loop working. Your first goal should be to get the script clicking *something*. I think the easiest place to start would be to get the script to click the D220 button (the image to replace is Apoc\Apocalypse.PNG). Once you know the script can do this click, completing the rest should go relatively quickly.

* Open your emu to the D180/D220 selection screen and leave it off to the side of the screen. 
* Open Snipping Tool (Window Key, type Snipping Tool), and open \AHKSearch\FFRK\Basic and  \AHKSearch\FFRK\Apoc in explorer. There are about 12 PNGs here. Looking at the images, together with their names, should be enough to know what you need to make snippets off. 
* Go through the steps to start a fight and get back to the selection screen, taking and saving snippets to replace the images as you go. Just take the next snippet, restart the script, and see if it clicks the image. Its best to do this one image at a time. You should aim to make images similar to the existing images, but they don't have to be pixel perfect. Be careful not to get any animations in your images.

Once you have replaced all of these images, the basic run loop should work. Leave it running for a few iterations to be certain. You might want to replace the Recovery\ConnectionRetry image as well, in case the game times out on a connection. The only thing that should stop the loop now is crashes, Emulator dialogs, Daily Missions, and the 13h00 GMT reset.

If its working now, try changing forceFullScreenScan back to false. If it now stops working you likely still need to figure out the window's name and change AppName to match (or you can leave it in the slower fullScreenScan mode).


### Fixing Recovery steps ###
Start from Home for your android emulation. Go through the process of logging in, and navigating to the MP selection screen, replace all the remaining images in \Recovery, as well as the image in \Weekly, as you go. Be careful not to make an image with an animation or particle effects in it. Some of these have to be made pretty similarly to the existing images, as the script uses some as a reference point rather than trying to click directly on them. You still don't need pixel perfection though. 

To test it out, just close the app, so you're back at Home, make sure the script is running, and wait a minute.

For some of the images, you'll have to wait for the Daily Mission confirmation screen, or RW rewards. If you leave the script running, and assuming it doesn't hit a freeze issue, it'll eventually come to a stop at one of these dialogs, so you can then take the image at your convenience.

### Fixing Hard recovery and emulator errors ###
Replace all the images in \Nox. Unfornuately some of them might be difficult to reproduce. But by this point you can just leave the emulator running, and when it hits an issue it should remain waiting there, for you to easily take a picture.

This step should allow clicking away temporary errors like Nox detecting a connection loss. It also drives the idle timeout functionality. Unfortunately these are pretty specific to Nox. If you're using a different emulator, but they have analogous buttons and dialogs, you can try replacing the images with those, but no guarantees. Do not change the folder name from Nox however, as the script is currently expecting in these directories. If you make a new folder or change a filename you'll have to edit the script to match.

	
