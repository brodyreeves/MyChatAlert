# MyChatAlert

## 2.4.6

- New Feature: Loot channel is now functional and can be added for alerts
  - This works just as the prexisting channels and alerts do, with one difference: the loot channel will not check against keywords in the `Global Keywords` channel
  - I did this because I don't expect there to be overlap between what the global keywords are watching for, and what keywords will be used for loot alerts; if this is something that people want to be changed, it can be
- New Feature: System channel is now functional and can be added for alerts
  - Same notes as the loot channel
- Code refactoring

## 2.4.5

- New Feature: Option for class coloring on authors
- Keywords will now be colored in the printed message alerts
  - I noticed some strange coloring behavior when testing this, but I think I got it all fixed. If you notice something behaving weird try to grab a screenshot and let me know ([Github issues](https://github.com/brodyreeves/MyChatAlert/issues) are probably best for this, over curseforge comments, so that it's all grouped together in one post)
  - Messages in the alert frame will not be colored, personally I think it looks better uncolored, is easier to read, and I noticed a lot of weird coloring stuff happening in the frame so it's overall easier. However, some coloring options for the alert frame will probably be coming, given the available time and not an overwhelming amount of issues
- Performance changes + code cleanup

## 2.4.4.3

- Another bug fix, sanity check when checking global keywords
- Also caught potential bug when manually entering a channel name
- Also caught bug with unregistering events when deleting channels
- Added missing default value for disableInInstance

## 2.4.4.2

- Fix bugged default value for printOutput frame

## 2.4.4

- New feature: chat command to ignore names
  - `/mca ignore {name}`
- Color customization for printed alerts

## 2.4.3

- New feature: Time-based duplication filter
  - If the same person sends the same alert-triggering message within `X` seconds and the alert is still in-frame, don't trigger another alert for that message ([discussion over scope of this feature](https://github.com/brodyreeves/MyChatAlert/issues/27))
- New feature: Section for global keywords
  - These keywords will trigger alerts in any channels that you've added
- New feature: Choose where printed alerts will be output to
- New feature: Keywords now support operators:
  - `-` for terms to suppress alerts
  - `+` for additional terms to match
  - ex: `lf+dps-brd` will alert for a message containing `lf`, `dps`, without `brd`
  - ex: in this example, "lf2m dps brd farm" wouldn't trigger an alert, but "lf2m dps hogger farm" would
- New feature: Disable in instance
  - With this option selected, alerts will be toggled off while you are inside an instanced zone (determined via [IsInInstance](https://wow.gamepedia.com/API_IsInInstance))
- `Escape` key will now close the alert frame
- New feature: Customize the printed alert messages
  - Color customization coming soon

## 2.4.2

- Bug: Fixed the issue where alerts would be enabled on log-in, regardless of the option
- Revisited alert frame handling
  - Frame will automatically update when receiving new alerts while showing
  - Minimap buttton now toggles frame on and off, instead of just showing/updating the frame
  - Chat command `/mca alerts` also toggles the frame now
  - Clearing the alerts also removes alerts from the frame

## 2.4.1

- New feature: ignore authors to prevent alerts

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
