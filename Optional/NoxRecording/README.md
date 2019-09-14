This is a Nox recording to run MP Apoc, in an instance set to 480x800. It is slower, and not as tolerant to issues as the AHK Script, but it will work while Nox is minimised. I tried to make sure it never clicks an area of the screen that might spend gems/mythril, so provided you stick to that resolution it should be safe. But ultimately I won't make any guarantees, **this script is use at your own risk.**

To integrate this with your Nox.

* Find the records file for your Nox installation.
* Copy the 0db673e1e0744fcaa7aba186f5cd8ff6 file here.
* Open records in a text editor. You will see recordings in JSON format. Add this to the recording, just after the first opening curly bracket

    "0db673e1e0744fcaa7aba186f5cd8ff6": {
        "combination": "false",
        "name": "Rerun MP",
        "needShow": "true",
        "new": "false",
        "playSet": {
            "accelerator": "1",
            "interval": "185",
            "mode": "1",
            "playOnStart": "false",
            "playSeconds": "0#0#0",
            "repeatTimes": "1",
            "restartPlayer": "false",
            "restartTime": "60"
        },
        "priority": "0",
        "time": "1567107295"
    },
	
and save.

This script expects to start at the Battle complete screen (where you see your medals earned). You can therefore set the Loop interval to however long you think the fight will take, but it does require you to complete a battle manually before you can start. The script itself takes about 1m50s to get to the click that starts the battle.

I've only ever used this on my preferred resolution for Nox. I'm not sure if it will work for different resolutions.