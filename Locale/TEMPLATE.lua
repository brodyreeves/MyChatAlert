local L = LibStub("AceLocale-3.0"):NewLocale("MyChatAlert", "enUS", false) -- change 'enUS' to your locale
if not L then return end

local C_G, C_R, C_Y, C_W = "|cFF00FF00", "|cffff0000", "|cFFFFFF00", "|r" -- text color flags

-- The phrases below are what need to be translated to support a new locale
-- L["DON'T TOUCH THIS"] = "THIS IS THE PHRASE TO TRANSLATE"
-- C_G/Y/R/W are the color tags, don't change those, only stuff within quotes
-- if a phrase has '%s' in it, that's used to formatting and a translation must have the same number of '%s's

L["Add Channel"] = "Add Channel"
L["Add Keyword"] = "Add Keyword"
L["Add a channel to watch from Ex: '4. LookingForGroup'"] = "Add a channel to watch from Ex: '4. LookingForGroup'"
L["Add a keyword to watch for"] = "Add a keyword to watch for"
L["Alert Sound"] = "Alert Sound"
L["Author"] = "Author"
L["Channels"] = "Channels"
L["Clear alerts"] = "Clear alerts"
L["Control+Right-Click"] = "Control+Right-Click"
L["Enable"] = "Enable"
L["Enable/disable printed alerts"] = "Enable/disable printed alerts"
L["Enable/disable sound alerts"] = "Enable/disable sound alerts"
L["Enable/disable the addon"] = "Enable/disable the addon"
L["Enable/disable the minimap button"] = "Enable/disable the minimap button"
L["Filter with GlobalIgnoreList"] = "Filter with GlobalIgnoreList"
L["Ignore messages from players on your ignore list"] = "Ignore messages from players on your ignore list"
L["Keyword"] = "Keyword"
L["Keywords"] = "Keywords"
L["Left-Click"] = "Left-Click"
L["Message"] = "Message"
L["Minimap"] = "Minimap"
L["Misc Options"] = "Misc Options"
L["MyChatAlert"] = "MyChatAlert"
L["Number delimiter"] = "."
L["Number Header"] = "#."
L["Number of alerts"] = "Number of alerts: "
L["Open options"] = "Open options"
--"Printed alert" replacement order is word, author, message
L["Printed alert"] = C_G .. "Keyword <" .. C_Y .. "%s" .. C_G .. "> seen from " .. C_Y .. "[%s]" .. C_G .. ": " .. C_Y .. "%s"
L["Printing"] = "Printing"
L["Remove Channel"] = "Remove Channel"
L["Remove Keyword"] = "Remove Keyword"
L["Remove selected channel from being watched"] = "Remove selected channel from being watched"
L["Remove selected keyword from being watched for"] = "Remove selected keyword from being watched for"
L["Right-Click"] = "Right-Click"
L["Select a channel to remove from being watched"] = "Select a channel to remove from being watched"
L["Select a channel to watch"] = "Select a channel to watch"
L["Select a keyword to remove from being watched for"] = "Select a keyword to remove from being watched for"
L["Select New Channel"] = "Select New Channel"
L["Show alert frame"] = "Show alert frame"
L["Sound"] = "Sound"
L["Sound id to play (can be browsed on Wowhead.com)"] = "Sound id to play (can be browsed on Wowhead.com)"
L["You have no alerts"] = "You have no alerts"
-- You have %s alert/alerts replacements are number of alerts
L["You have %s alert"] = "You have |cFF00FF00%s|cFFCFCFCF alert" -- 1 alert
L["You have %s alerts"] = "You have |cFF00FF00%s|cFFCFCFCF alerts" --- more than one alerts
