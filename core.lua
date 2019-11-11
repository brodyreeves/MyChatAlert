MyChatAlert = LibStub("AceAddon-3.0"):NewAddon("MyChatAlert", "AceConsole-3.0", "AceEvent-3.0")

local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("MyChatAlert")

-- declare local functions
local TrimRealmName, interp, rgbToHex, MessageHasTrigger, ColorWord, ClassColorFromGUID

-- localize global functions
local format, pairs, tremove, sub, find, time, gsub, floor, fmod, lower = string.format, pairs, table.remove, string.sub, string.find, time, string.gsub, math.floor, math.fmod, string.lower
local IsInInstance, UnitName, PlaySound, GetPlayerInfoByGUID, GetClassColor, UnitGUID = IsInInstance, UnitName, PlaySound, GetPlayerInfoByGUID, GetClassColor, UnitGUID

-------------------------------------------------------------
----------------------- ACE FUNCTIONS -----------------------
-------------------------------------------------------------

function MyChatAlert:OnInitialize()
    -- Called when the addon is loaded
    self.db = LibStub("AceDB-3.0"):New("MyChatAlertDB", self.defaults, true)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("MyChatAlert", self.options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MyChatAlert", "MyChatAlert")
    self:RegisterChatCommand("mca", "ChatCommand")
    self:CreateAlertFrame()

    -- migrate MyChatAlert Global Keywords -> MyChatAlert Globals if not already done
    if self.db.profile.triggers[L["MyChatAlert Global Keywords"]] then -- MyChatAlert Global Keywords still exists
        if not self.db.profile.triggers[L["MyChatAlert Globals"]] then -- MyChatAlert Globals hasn't been created

            -- create tables for new "MyChatAlert Globals" channel
            self.db.profile.triggers[L["MyChatAlert Globals"]] = {}
            self.db.profile.filterWords[L["MyChatAlert Globals"]] = {}

            -- populate with words from "MyChatAlert Global Keywords"
            for i = 1, #self.db.profile.triggers[L["MyChatAlert Global Keywords"]] do
                -- insert the keyword into the new table
                self.db.profile.triggers[L["MyChatAlert Globals"]][#self.db.profile.triggers[L["MyChatAlert Globals"]] + 1] = self.db.profile.triggers[L["MyChatAlert Global Keywords"]][i]
            end

            -- delete old tables to keep stuff clean
            self.db.profile.triggers[L["MyChatAlert Global Keywords"]] = nil
            self.db.profile.filterWords[L["MyChatAlert Global Keywords"]] = nil
        end
    end
    -- migration complete
end

function MyChatAlert:OnEnable()
    if not self.db.profile.enabled then return false, "disabled via setting" end

    local _, type = IsInInstance()
    if self.db.profile.disableInInstance and type and type ~= "none" then return false, "disabled in instance" end

    local chat_msg_chan = false

    for chan, _ in pairs(self.db.profile.triggers) do -- register all necessary events for added channels
        if self.eventMap[chan] then -- channel is mapped to an event
            self:RegisterEvent(self.eventMap[chan])

        elseif not chat_msg_chan then -- custom/global channels use generic event
            self:RegisterEvent("CHAT_MSG_CHANNEL")
            chat_msg_chan = true
        end
    end

    if self.db.profile.disableInInstance then
        self:RegisterEvent("ZONE_CHANGED")
        self:RegisterEvent("ZONE_CHANGED_INDOORS")
        self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    end

    return true
end

function MyChatAlert:OnDisable()
    if self.db.profile.enabled then return false, "enabled via settings" end

    self:UnregisterEvent("CHAT_MSG_CHANNEL")
    for i = 1, #self.eventMap do self:UnregisterEvent(self.eventMap[i]) end

    -- don't unregister ZONE_CHANGED** events, need them to toggle back on after an instance
    return true
end

-------------------------------------------------------------
----------------------- EVENT HANDLERS ----------------------
-------------------------------------------------------------

MyChatAlert.eventMap = {
    [L["Guild"]] = "CHAT_MSG_GUILD",
    [L["Loot"]] = "CHAT_MSG_LOOT",
    [L["Officer"]] = "CHAT_MSG_OFFICER",
    [L["Party"]] = "CHAT_MSG_PARTY",
    [L["Party Leader"]] = "CHAT_MSG_PARTY_LEADER",
    [L["Raid"]] = "CHAT_MSG_RAID",
    [L["Raid Leader"]] = "CHAT_MSG_RAID_LEADER",
    [L["Raid Warning"]] = "CHAT_MSG_RAID_WARNING",
    [L["Say"]] = "CHAT_MSG_SAY",
    [L["System"]] = "CHAT_MSG_SYSTEM",
    [L["Yell"]] = "CHAT_MSG_YELL",
}

function MyChatAlert:CHAT_MSG_CHANNEL(event, message, author, _, channel, _, _, _, _, _, _, _, authorGUID)
    if self.db.profile.triggers and self.db.profile.triggers[channel] then
        self:CheckAlert(event, message, author, authorGUID, channel)
    end
end

function MyChatAlert:CHAT_MSG_GUILD(event, message, author, _, _, _, _, _, _, _, _, _, authorGUID)
    self:CheckAlert(event, message, author, authorGUID, L["Guild"])
end

function MyChatAlert:CHAT_MSG_LOOT(event, message)
    -- don't want to use global keywords when checking loot messages, no overlap; if people ask then put it in ??
    -- check channel keywords
    local match, coloredMsg = MessageHasTrigger(message, L["Loot"])

    if match then
        self:AddAlert(match:sub(1, 12), UnitName("player"), UnitGUID("player"), L["Loot"], message, coloredMsg) -- :sub() just to help keep display width under control
    end
end

function MyChatAlert:CHAT_MSG_OFFICER(event, message, author, _, _, _, _, _, _, _, _, _, authorGUID)
    self:CheckAlert(event, message, author, authorGUID, L["Officer"])
end

function MyChatAlert:CHAT_MSG_PARTY(event, message, author, _, _, _, _, _, _, _, _, _, authorGUID)
    self:CheckAlert(event, message, author, authorGUID, L["Party"])
end

function MyChatAlert:CHAT_MSG_PARTY_LEADER(event, message, author, _, _, _, _, _, _, _, _, _, authorGUID)
    self:CheckAlert(event, message, author, authorGUID, L["Party Leader"])
end

function MyChatAlert:CHAT_MSG_RAID(event, message, author, _, _, _, _, _, _, _, _, _, authorGUID)
    self:CheckAlert(event, message, author, authorGUID, L["Raid"])
end

function MyChatAlert:CHAT_MSG_RAID_LEADER(event, message, author, _, _, _, _, _, _, _, _, _, authorGUID)
    self:CheckAlert(event, message, author, authorGUID, L["Raid Leader"])
end

function MyChatAlert:CHAT_MSG_RAID_WARNING(event, message, author, _, _, _, _, _, _, _, _, _, authorGUID)
    self:CheckAlert(event, message, author, authorGUID, L["Raid Warning"])
end

function MyChatAlert:CHAT_MSG_SAY(event, message, author, _, _, _, _, _, _, _, _, _, authorGUID)
    self:CheckAlert(event, message, author, authorGUID, L["Say"])
end

function MyChatAlert:CHAT_MSG_SYSTEM(event, message)
    -- uses global strings, see [https://raw.githubusercontent.com/tekkub/wow-globalstrings/master/GlobalStrings/enUS.lua]
    -- keywords still work, don't need to match against the strings, can be browsed to help set alerts though
    local match, coloredMsg = MessageHasTrigger(message, L["System"])

    if match then
        self:AddAlert(match:sub(1, 12), UnitName("player"), UnitGUID("player"), L["System"], message, coloredMsg) -- :sub() just to help keep display width under control
    end
end

function MyChatAlert:CHAT_MSG_YELL(event, message, author, _, _, _, _, _, _, _, _, _, authorGUID)
    self:CheckAlert(event, message, author, authorGUID, L["Yell"])
end

function MyChatAlert:ZONE_CHANGED()
    if self.db.profile.disableInInstance then
        local _, type = IsInInstance()
        if not type then return end

        if type == "none" then self:OnEnable()
        else self:OnDisable()
        end
    end
end

function MyChatAlert:ZONE_CHANGED_INDOORS() self:ZONE_CHANGED() end

function MyChatAlert:ZONE_CHANGED_NEW_AREA() self:ZONE_CHANGED() end

-------------------------------------------------------------
----------------------- CHAT COMMANDS -----------------------
-------------------------------------------------------------

function MyChatAlert:ChatCommand(arg)
    -- MyChatAlert Chat Commands:
    -- 1) `/mca alerts` -> Toggles the alert frame
    -- 2) `/mca ignore {player}` -> Adds `player` to the ignored name list
    -- 3) `/mca` -> Opens the addon's options panel [Default command if nothing else is
    --              matched]

    local arg1, arg2 = self:GetArgs(arg, 2)
    if arg1 == "alerts" then self:ToggleAlertFrame()
    elseif arg1 == "ignore" then
        if arg2 and arg2 ~= "" and not arg2:find("%A") then
            -- want to make sure arg2 (name) exists and only contains letters
            self.db.profile.ignoredAuthors[#self.db.profile.ignoredAuthors + 1] = arg2
        end
    else -- just open the options
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame) -- need two calls
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    end
end

-------------------------------------------------------------
------------------------ ALERT FRAME ------------------------
-------------------------------------------------------------

MyChatAlert.alertFrame = {
    frame = nil,
    alerts = {},
    MAX_ALERTS_TO_KEEP = 30,
}

function MyChatAlert.alertFrame.NewLabel(text, width, parent)
    local frame = AceGUI:Create("Label")
    frame:SetText(text)
    frame:SetRelativeWidth(width)
    parent:AddChild(frame)

    return frame
end

function MyChatAlert.alertFrame.NewIntLabel(text, width, callback, parent)
    local frame = AceGUI:Create("InteractiveLabel")
    frame:SetText(text)
    frame:SetRelativeWidth(width)
    frame:SetCallback("OnClick", callback)
    parent:AddChild(frame)

    return frame
end

function MyChatAlert.alertFrame.AddHeaders(parent)
    local alertNum = MyChatAlert.alertFrame.NewLabel(L["Number Header"], 0.04, parent)
    alertNum:SetColor(255, 255, 0)
    local alertChan = MyChatAlert.alertFrame.NewLabel(L["Channel"], 0.17, parent)
    alertChan:SetColor(255, 255, 0)
    local alertWord = MyChatAlert.alertFrame.NewLabel(L["Keyword"], 0.11, parent)
    alertWord:SetColor(255, 255, 0)
    local alertAuthor = MyChatAlert.alertFrame.NewLabel(L["Author"], 0.13, parent)
    alertAuthor:SetColor(255, 255, 0)
    local alertMsg = MyChatAlert.alertFrame.NewLabel(L["Message"], 0.55, parent)
    alertMsg:SetColor(255, 255, 0)
end

function MyChatAlert.alertFrame.AddEntry(num, alert, parent)
    local alertNum = MyChatAlert.alertFrame.NewLabel(num .. L["Number delimiter"], 0.04, parent)
    local alertChan = MyChatAlert.alertFrame.NewLabel(alert.channel, 0.17, parent)
    local alertWord = MyChatAlert.alertFrame.NewLabel(alert.word, 0.11, parent)
    local alertAuthor = MyChatAlert.alertFrame.NewIntLabel(alert.author, 0.13, function(button) ChatFrame_OpenChat(format(L["/w %s "], alert.author)) end, parent)
    local alertMsg = MyChatAlert.alertFrame.NewLabel(alert.msg, 0.55, parent)
end

function MyChatAlert.alertFrame.ClearAlerts()
    MyChatAlert.alertFrame.alerts = {}
    if MyChatAlert.alertFrame.frame:IsVisible() then -- reload frame
        MyChatAlert.alertFrame.frame:Hide()
        MyChatAlert.alertFrame.frame:Show()
    end
end

function MyChatAlert:CreateAlertFrame()
    self.alertFrame.frame = AceGUI:Create("Frame")
    self.alertFrame.frame:SetTitle(L["MyChatAlert"])
    self.alertFrame.frame:SetStatusText(format(L["Number of alerts: %s"], #self.alertFrame.alerts))
    self.alertFrame.frame:SetLayout("Flow")
    self.alertFrame.frame:Hide()

    self.alertFrame.frame:SetCallback("OnClose", function(widget)
        self.alertFrame.frame:ReleaseChildren()
    end)

    self.alertFrame.frame:SetCallback("OnShow", function(widget)
        self.alertFrame.AddHeaders(self.alertFrame.frame)
        for i = 1, #self.alertFrame.alerts do self.alertFrame.AddEntry(i, self.alertFrame.alerts[i], self.alertFrame.frame) end
        self.alertFrame.frame:SetStatusText(format(L["Number of alerts: %s"], #self.alertFrame.alerts))
    end)

    MCAalertFrame = self.alertFrame.frame.frame
    table.insert(UISpecialFrames, "MCAalertFrame")

    self.alertFrame.frame.frame:SetPropagateKeyboardInput(true)
end

function MyChatAlert:ToggleAlertFrame()
    if self.alertFrame.frame:IsVisible() then self.alertFrame.frame:Hide()
    else self.alertFrame.frame:Show()
    end
end

-------------------------------------------------------------
----------------------- ALERT HANDLING ----------------------
-------------------------------------------------------------

function MyChatAlert:CheckAlert(event, message, author, authorGUID, channel)
    if self:AuthorIgnored(TrimRealmName(author)) then return false, "author ignored" end
    if self:MessageIgnored(message, channel) then return false, "message ignored" end
    if self:IsDuplicateMessage(message, TrimRealmName(author)) then return false, "message is duplicate" end

    local match, coloredMsg = nil, nil

    if self.db.profile.triggers[L["MyChatAlert Globals"]] then -- need to check global keywords
        match, coloredMsg = MessageHasTrigger(message, L["MyChatAlert Globals"])
        if match then
            self:AddAlert("*" .. match:sub(1, 11), TrimRealmName(author), authorGUID, channel:sub(1, 18), message, coloredMsg) -- :sub() just to help keep display width under control
            return true
        end
    end

    -- now check channel keywords
    match, coloredMsg = MessageHasTrigger(message, channel)
    if match then
        self:AddAlert(match:sub(1, 12), TrimRealmName(author), authorGUID, channel:sub(1, 18), message, coloredMsg) -- :sub() just to help keep display width under control
        return true
    end
end

function MyChatAlert:AddAlert(word, author, authorGUID, channel, msg, coloredMsg) -- makes sure no more than 15 alerts are stored
    if #self.alertFrame.alerts == self.alertFrame.MAX_ALERTS_TO_KEEP then tremove(self.alertFrame.alerts, 1) end -- remove first/oldest alert

    self.alertFrame.alerts[#self.alertFrame.alerts + 1] = {word = word, author = author, msg = msg, channel = channel, time = time()}

    if self.alertFrame.frame:IsVisible() then -- reload frame
        self.alertFrame.frame:Hide()
        self.alertFrame.frame:Show()
    end

    if self.db.profile.soundOn then PlaySound(self.db.profile.sound) end

    if self.db.profile.printOn then
        -- separate and combine these, noticed inconsistent colors if changed to something like:
        -- rgbToHex(self.db.profile.baseColor)
        local baseColor = rgbToHex({self.db.profile.baseColor.r, self.db.profile.baseColor.g, self.db.profile.baseColor.b})
        local keywordColor = rgbToHex({self.db.profile.keywordColor.r, self.db.profile.keywordColor.g, self.db.profile.keywordColor.b})
        local authorColor = rgbToHex({self.db.profile.authorColor.r, self.db.profile.authorColor.g, self.db.profile.authorColor.b})
        local messageColor = rgbToHex({self.db.profile.messageColor.r, self.db.profile.messageColor.g, self.db.profile.messageColor.b})

        if self.db.profile.printClassColor then -- overwrite author color with class color
            authorColor = ClassColorFromGUID(authorGUID)
        end

        local replacement = {
            keyword = keywordColor .. word .. baseColor,
            author = authorColor .. "|Hplayer:" .. author .. ":0|h" .. author .. "|h" .. baseColor,
            message = messageColor .. coloredMsg .. baseColor,
            channel = messageColor .. channel .. baseColor,
        }

        local message = baseColor .. interp(self.db.profile.printedMessage or L["Printed alert"], replacement)

        local printFrame = self.outputFrames[self.db.profile.printOutput].frame
        printFrame:AddMessage(message, 1.0, 1.0, 1.0)
    end
end

-------------------------------------------------------------
-------------------------- HELPERS --------------------------
-------------------------------------------------------------

TrimRealmName = function(author)
    local name = author
    local realmDelim = name:find("-") -- nil if not found, otherwise tells where the name ends and realm begins
    if realmDelim ~= nil then -- name includes the realm name, we can trim that
        name = name:sub(1, realmDelim - 1) -- don't want to include the '-' symbol
    end

    return name
end

interp = function(s, tab) -- named format replacement [http://lua-users.org/wiki/StringInterpolation]
    return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end

rgbToHex = function(rgb) -- color form converter [https://gist.github.com/marceloCodget/3862929]
    -- local hexadecimal = '0X'
    local hexadecimal = '|cFF' -- prefix for wow coloring escape is |c, FF is the alpha portion

    for key, value in pairs(rgb) do
        local hex = ''
        value = floor(value * 255) -- uses rgb on a scale of 0-1, scale it up for this conversion

        while(value > 0)do
            local index = fmod(value, 16) + 1
            value = floor(value / 16)
            hex = sub('0123456789ABCDEF', index, index) .. hex
        end

        if(string.len(hex) == 0)then
            hex = '00'

        elseif(string.len(hex) == 1)then
            hex = '0' .. hex
        end

        hexadecimal = hexadecimal .. hex
    end

    return hexadecimal
end

MessageHasTrigger = function(message, channel)
    -- don't need to check existence here because it's already been checked
    -- named channels with own events have their table created when event is registered
    -- general channels with CHAT_MSG_CHANNEL get checked before entering the function
    for i = 1, #MyChatAlert.db.profile.triggers[channel] do
        local word = MyChatAlert.db.profile.triggers[channel][i]

        if word:find("[-+]") then -- advanced pattern matching
            local msg = message
            local haveMatch = true

            if not word:sub(1, 1):find("[-+]") then
                -- the word contains -+ operators, but doesn't start with one
                -- something along the form of lf+tank-brs
                local firstOp, _ = word:find("[-+]") -- find first operator to split first term off
                local wordStart, wordEnd = message:lower():find(word:lower():sub(1, firstOp - 1)) -- try to find first term in message

                if not wordStart then haveMatch = false -- didnt find it
                else -- surround term with color flags and continue matching terms
                    msg = ColorWord(wordStart, wordEnd, msg)
                end
            end

            for subword in word:lower():gmatch("[-+]%a+") do -- split by operators
                if haveMatch then
                    local wordStart, wordEnd = message:lower():find(subword:sub(2, -1)) -- try to find term in message

                    if subword:sub(1, 1) == "+" then -- want term to be in the message
                        if wordStart then -- found the term, surround with color flags and continue matching terms
                            msg = ColorWord(wordStart, wordEnd, msg)
                        else haveMatch = false -- didn't find it
                        end
                    else -- '-' operator, don't want term to be in message
                        if wordStart then haveMatch = false end
                    end
                end
            end

            if haveMatch then return word, msg end -- found the keyword, msg has been colored on the way

        else -- simple word matching
            local wordStart, wordEnd = message:lower():find(word:lower()) -- try to find keyword in message

            if wordStart then return word, ColorWord(wordStart, wordEnd, message) end -- found the keyword, surround with color flags
        end
    end

    return false, "no matching keywords"
end

ColorWord = function(wordStart, wordEnd, message)
    -- split message apart like: {Message before word}, {Word}, {Message after word}
    -- and insert color flags around {Word} portion
    -- same coloring behavior described in MyChatAlert:AddAlert()
    local keywordColor = rgbToHex({MyChatAlert.db.profile.keywordColor.r, MyChatAlert.db.profile.keywordColor.g, MyChatAlert.db.profile.keywordColor.b})
    local messageColor = rgbToHex({MyChatAlert.db.profile.messageColor.r, MyChatAlert.db.profile.messageColor.g, MyChatAlert.db.profile.messageColor.b})

    return message:sub(1, wordStart - 1) ..
        keywordColor .. message:sub(wordStart, wordEnd) .. messageColor ..
        message:sub(wordEnd + 1, -1)
end

ClassColorFromGUID = function(guid)
    local _, class = GetPlayerInfoByGUID(guid) -- using englishClass for following api call
    local _, _, _, classColor = GetClassColor(class) -- api returns r%, g%, b%, argbHex

    return "|c" .. classColor
end

-------------------------------------------------------------
-------------------------- FILTERS --------------------------
-------------------------------------------------------------

function MyChatAlert:AuthorIgnored(author)
    if author == UnitName("player") then return true, "author is player" end -- don't do anything if it's your own message

    for i = 1, #self.db.profile.ignoredAuthors do
        if author == self.db.profile.ignoredAuthors[i] then return true, "author is ignored" end
    end

    --[[ Disabled due to not working, no demand/no plans to fix it 10/28/19
        -- optional globalignorelist check
        if self.db.profile.globalignorelist then
            for i = 1, #GlobalIgnoreDB.ignoreList do
                if author == GlobalIgnoreDB.ignoreList[i] then -- found in ignore list
                    return true
                end
            end
        end
    ]]--

    return false
end

function MyChatAlert:MessageIgnored(message, channel)
    if self.db.profile.filterWords then
        -- ignore message due to containing a global filtered word
        if self.db.profile.filterWords[L["MyChatAlert Globals"]] then
            for i = 1, #self.db.profile.filterWords[L["MyChatAlert Globals"]] do
                if message:lower():find(self.db.profile.filterWords[L["MyChatAlert Globals"]][i]:lower()) then return true, "message has global filter" end
            end
        end

        -- ignore message due to containing a channel filtered word
        if self.db.profile.filterWords[channel] then
            for i = 1, #self.db.profile.filterWords[channel] do
                if message:lower():find(self.db.profile.filterWords[channel][i]:lower()) then return true, "message has channel filter" end
            end
        end
    end

    return false
end

function MyChatAlert:IsDuplicateMessage(message, author)
    for i = 1, #self.alertFrame.alerts do
        if message == self.alertFrame.alerts[i].msg and author == self.alertFrame.alerts[i].author
        and time() - self.alertFrame.alerts[i].time < self.db.profile.dedupTime then
            return true
        end
    end

    return false
end
