# MyChatAlert

## v2.4.0

- BIG overhaul of backend
  - Keywords are now tied to specific channels
    - You can do something like `dm` for `4. LookingForGroup` and `wtb` for `2. Trade - City`, independent of each other
    - Because of this, the alert frame now displays the channel as well
    - Existing channels and keywords should be transferred into the new version
  - New feature, add filtering words to prevent triggering alertsw
- Author names in the alerts are now clickable (thanks to GH user tg123)
- Support for non-global channels (say, yell, party, etc.)
  - Because of this, the alert frame now displays the channel as well
  - Loot is currently unavailable, until I can look into this and test it
  - System is currently unavailable, until I look into the global strings that Blizzard uses to deliver these messages
- Saw German got some translations done, added it to the Locales (along with placeholders for other locales)
- GlobalIgnoreList is just disabled for now, until I can look into it

## v2.3.1

- Fix the filtering of player's own messages
- Fix the names not being clickable
- Add function for minimap button to toggle alerts

## v2.3.0

- Chat commands added
  - `/msa` opens the options
  - `/msa alerts` shows the alert frame
- Author names in the alert frame are now clickable to open a whisper to the author
- Clicking the minimap button while alert frame is visible now refreshes (some weird-looking behavior if you have the max number of alerts cached and refreshed)

## v2.2.1

- zhCN support and curseforge locale injection

## v2.2.0

- Locale support

## v2.1.3

- Added option to toggle minimap button

## v2.1.2

- Fixed empty channel dropdown

## v2.1.1

- Fixed missing Libs

## v2.1.0

- Filter out messages that you send
- Dropdown to select channels you're a member of when adding watched channels
- Option to filter with GlobalIgnoreFilter

## v2.0.0

- Reworked interface via ace3
- Added an alert frame that will display information of alerted messages

## v1.4.0

- Reworded printed alert

## v1.3.0

- Sound used for alert is now configurable
- New options to toggle sound alerts and printed alerts
- Better string matching logic to eliminate case-sensitivity

## v1.2.0

- Sound used for alert is now an option that you set

## v1.1.0

- SavedVars are now per-character
- Channel to watch is now an option that you set

## v1.0.0

- First working version
