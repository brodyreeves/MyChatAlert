# MyChatAlert

Alerts the player when designated keywords are found in specified chat channels

![alert frame pic]
![chat alert pic]

## Using the Addon

Download it and install as a typical wow addon. Customization can be found in the interface/addons panel. Clicking on an author's name in the alert frame or printed alerts will open a whisper to that player.

### Chat Commands

- `/mca` opens the addon options panel
- `/mca alerts` opens the alert frame
- `/mca ignore {player}` adds the player to the addon's ignore list

### Minimap Functionality

- `Left Click` Toggles the alert frame to show/hide
- `Control + Left Click` Opens the interface options panel for the addon
- `Right Click` Clears stored alerts in the alert frame
- `Control Right Click` Toggles the `Enable` setting, controls whether alerts are enabled or disabled

### Creating a Basic Alert

1) Open the addon's options

2) In the `Channels` section, select a `channel` from the dropdown, or manually type in the name

3) In the `Keywords` section, select the `channel` you want to add an alert to

4) Type in the `keyword` that you want to be alerted for

5) You now have a functioning alert! Further configuration can be done, the settings section below will explain each setting

## Settings Walkthrough

### General Section

![general section pic]

- `Enable` - Toggles alerts on or off
- `Disable in instance` - If checked, suppress alerts while inside of an instance
- `Minimap` - Toggle the minimap button on or off
- `Time to wait` - Controls how long to prevent duplicate messages from repeat authors from triggering a second alert (in seconds, `0` to disable the feature)

### Sound Section

![sound section pic]

- `Enable` - Whether to play a sound when alert is triggered
- `Alert Sound` - The soundID (number) to play, this can be browsed on [Wowhead][wowhead sound link]
  - There is a GitHub issue regarding a [quick-add list][github sound issue link] of sounds, similar to the channels, and I'm trying to build a list of some good sounds to use; if you have some favorite alerts sounds please comment them!

### Printing Section

![printing section pic]

- `Enable` - Whether to print alerts to the screen
- `Destination` - Where should the printed alerts be displayed
- `Print Message` - If you want to override the default printed message, what you enter here is used as the format
  - `${keyword}`, `${author}`, `${message}` will be replaced with the respective fields when an alert is triggered
  - E.g. `[${author}]: ${message}` will output an alert of the format: `[Name]: Something said to trigger an alert`
- `Base Text Color` - The base color of the alert text (anything that isn't a replacement)
- `Keyword Color` - The color to use for the keyword, colors both `${keyword}` replacements and the keyword within ${message} replacements
- `Author Color` - The color to use for the author
- `Message Color` - The color to use for the message that triggered the alert

### Trigger Section

![trigger section pic]

#### Channels

- `Select New Channel` - Quick-add list of channels you can add to be watched
- `Remove Channel` - Selectable list of added channels, pick one to be removed
- `Remove Channel (Button)` - Press the button after selecting a channel to remove it (along with associated keywords and filter words)
- `Add Channel` - You can manually type in a channel name if you want to add something not in the quick-add list

#### Keywords

- `Select Channel` - Selectable list of added channels, pick one to add keywords too
  - `MyChatAlert Globals` is for keywords to watch for in every added channel
- `Add Keyword` - Type in the keyword you want to be alerted for
  - Simple keyword: `dm` - Alerts if `dm` is found in a message
  - Advanced keyword: `dm+west-east` - Alerts if `dm` is found in a message that also contains `west` and does not contain `east`
- `Remove Keyword` - Selectable list of added keywords, pick one to be removed
- `Remove Keyword (Button)` - Press the button after selecting a keyword to remove it

### Filter Section

![filter section pic]

#### Filter Words

- `Select Channel` - Selectable list of added channels, pick one to add filter words to
  - `MyChatAlert Globals` is for words to filter from every added channel
- `Add Filter` - Type in a word if you don't want to receive alerts for messages containing the word
  - E.g. `guild` - Don't alert for messages that contain `guild`, even if the message contains a keyword
- `Remove Filter` - Selectable list of added filter words, pick one to be removed
- `Remove Filter (Button)` - Press the button after selecting a filter word to remove it

#### Ignore Authors

- `Add Name` - Type in the name of a player you don't want to receive alerts from
  - E.g. `GuildRecruiter`: Don't alert for messages sent by `GuildRecruiter`, even if the message contains a keyword
- `Remove Name` - Selectable list of added names, pick one to be removed
- `Remove Name (Button)` - Press the button after selecting a name to remove it

## Missing Localization

If you want to help translate the addon to your locale, you can view what phrases are missing on [Curseforge][curseforge localization link]

## Support the Dev

Donation info was requested, so I added it to the Curseforge project. The side panel has a button with this [PayPal][paypal link] link, or you can also use [Venmo][venmo link] if you prefer that

[alert frame pic]: https://raw.githubusercontent.com/brodyreeves/MyChatAlert/v2.5.0/Addon_Images/ss-alert-frame.png "Alert Frame"
[chat alert pic]: https://raw.githubusercontent.com/brodyreeves/MyChatAlert/v2.5.0/Addon_Images/ss-chat-alert.png "Printed Alert"
[general section pic]: https://raw.githubusercontent.com/brodyreeves/MyChatAlert/v2.5.0/Addon_Images/ss-settings-general.png "General Settings"
[sound section pic]: https://raw.githubusercontent.com/brodyreeves/MyChatAlert/v2.5.0/Addon_Images/ss-settings-sound.png "Sound Settings"
[printing section pic]: https://raw.githubusercontent.com/brodyreeves/MyChatAlert/v2.5.0/Addon_Images/ss-settings-printing.png "Printing Settings"
[trigger section pic]: https://raw.githubusercontent.com/brodyreeves/MyChatAlert/v2.5.0/Addon_Images/ss-settings-trigger.png "Trigger Settings"
[filter section pic]: https://raw.githubusercontent.com/brodyreeves/MyChatAlert/v2.5.0/Addon_Images/ss-settings-filter.png "Filter Settings"

[wowhead sound link]: https://classic.wowhead.com/sounds
[github sound issue link]: https://github.com/brodyreeves/MyChatAlert/issues/6
[curseforge localization link]: https://www.curseforge.com/wow/addons/mychatalert/localization
[paypal link]: https://www.paypal.com/cgi-bin/webscr?return=https://www.curseforge.com/projects/341693&cn=Add+special+instructions+to+the+addon+author()&business=brodyreeves%40gmail.com&bn=PP-DonationsBF:btn_donateCC_LG.gif:NonHosted&cancel_return=https://www.curseforge.com/projects/341693&lc=US&item_name=MyChatAlert+(from+curseforge.com)&cmd=_donations&rm=1&no_shipping=1&currency_code=USD
[venmo link]: https://venmo.com/BrodyReeves
