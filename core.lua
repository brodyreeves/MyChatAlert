MyChatAlert = LibStub("AceAddon-3.0"):NewAddon("MyChatAlert", "AceConsole-3.0", "AceEvent-3.0")

local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("MyChatAlert")

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

    -- Migrate SVs if needed
    if self.db.profile.channels and self.db.profile.words then
        if not self.db.profile.triggers then self.db.profile.triggers = {} end
        if not self.db.profile.filterWords then self.db.profile.filterWords = {} end

        -- main part of migration is moving from a list of words for all channels to a list of words for each individual channel
        for _, channel in pairs(self.db.profile.channels) do
            local words = {}
            for _, word in pairs(self.db.profile.words) do
                tinsert(words, word)
            end
            self.db.profile.triggers[channel] = words
        end

        -- once migrated, delete the old ones
        self.db.profile.channels = nil
        self.db.profile.words = nil
    end
end

function MyChatAlert:OnEnable()
    if not self.db.profile.enabled then return end

    local chat_msg_chan = false

    for chan, _ in pairs(self.db.profile.triggers) do -- register all necessary events for added channels
        if self.eventMap[chan] then -- channel is mapped to an event
            self:RegisterEvent(self.eventMap[chan])

        elseif not chat_msg_chan then -- custom/global channels use generic event
            self:RegisterEvent("CHAT_MSG_CHANNEL")
            chat_msg_chan = true
        end
    end
end

function MyChatAlert:OnDisable()
    if self.db.profile.enabled then return end

    self:UnregisterEvent("CHAT_MSG_CHANNEL")
    for _, event in pairs(self.eventMap) do self:UnregisterEvent(event) end
end

-------------------------------------------------------------
----------------------- EVENT HANDLERS ----------------------
-------------------------------------------------------------

MyChatAlert.eventMap = {
    [L["Guild"]] = "CHAT_MSG_GUILD",
    -- [L["Loot"]] = "CHAT_MSG_LOOT",
    [L["Officer"]] = "CHAT_MSG_OFFICER",
    [L["Party"]] = "CHAT_MSG_PARTY",
    [L["Party Leader"]] = "CHAT_MSG_PARTY_LEADER",
    [L["Raid"]] = "CHAT_MSG_RAID",
    [L["Raid Leader"]] = "CHAT_MSG_RAID_LEADER",
    [L["Raid Warning"]] = "CHAT_MSG_RAID_WARNING",
    [L["Say"]] = "CHAT_MSG_SAY",
    -- [L["System"]] = "CHAT_MSG_SYSTEM",
    [L["Yell"]] = "CHAT_MSG_YELL",
}

function MyChatAlert:CHAT_MSG_CHANNEL(event, message, author, _, channel)
    if self:AuthorIgnored(TrimRealmName(author)) then return end
    if self:MessageIgnored(message, channel) then return end
    if self:IsDuplicateMessage(message, TrimRealmName(author)) then return end

    for ch, words in pairs(self.db.profile.triggers) do -- find the channel
        if channel:lower() == ch:lower() then
            for _, word in pairs(words) do -- find the word
                if message:lower():find(word:lower()) then -- Alert message
                    self:AddAlert(word, TrimRealmName(author), message, channel)
                    return -- matched the message, stop
                end
            end
            break -- matched the channel so stop looping
        end
    end
end

function MyChatAlert:CHAT_MSG_GUILD(event, message, author)
    self:CheckAlert(event, message, author, L["Guild"])
end

function MyChatAlert:CHAT_MSG_LOOT(event, message)
    -- TODO: test this
    for _, word in pairs(self.db.profile.triggers[L["Loot"]]) do -- find the word
        if message:lower():find(word:lower()) then -- Alert message
            self:AddAlert(word, UnitName("player"), message, L["Loot"])
            return -- matched the message, stop
        end
    end
end

function MyChatAlert:CHAT_MSG_OFFICER(event, message, author)
    self:CheckAlert(event, message, author, L["Officer"])
end

function MyChatAlert:CHAT_MSG_PARTY(event, message, author)
    self:CheckAlert(event, message, author, L["Party"])
end

function MyChatAlert:CHAT_MSG_PARTY_LEADER(event, message, author)
    self:CheckAlert(event, message, author, L["Party Leader"])
end

function MyChatAlert:CHAT_MSG_RAID(event, message, author)
    self:CheckAlert(event, message, author, L["Raid"])
end

function MyChatAlert:CHAT_MSG_RAID_LEADER(event, message, author)
    self:CheckAlert(event, message, author, L["Raid Leader"])
end

function MyChatAlert:CHAT_MSG_RAID_WARNING(event, message, author)
    self:CheckAlert(event, message, author, L["Raid Warning"])
end

function MyChatAlert:CHAT_MSG_SAY(event, message, author)
    self:CheckAlert(event, message, author, L["Say"])
end

function MyChatAlert:CHAT_MSG_SYSTEM(event, message, author, _, channel)
    -- uses global strings
    -- TODO: finish this
end

function MyChatAlert:CHAT_MSG_YELL(event, message, author)
    self:CheckAlert(event, message, author, L["Yell"])
end

function MyChatAlert:CheckAlert(event, message, author, channel)
    if self:AuthorIgnored(TrimRealmName(author)) then return end
    if self:MessageIgnored(message, channel) then return end
    if self:IsDuplicateMessage(message, TrimRealmName(author)) then return end

    for _, word in pairs(self.db.profile.triggers[channel]) do -- find the word
        if message:lower():find(word:lower()) then -- Alert message
            self:AddAlert(word, TrimRealmName(author), message, channel)
            return -- matched the message, stop
        end
    end
end

-------------------------------------------------------------
----------------------- CHAT COMMANDS -----------------------
-------------------------------------------------------------

function MyChatAlert:ChatCommand(arg)
    if arg == "alerts" then self:ToggleAlertFrame()
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
        for i, alert in pairs(self.alertFrame.alerts) do self.alertFrame.AddEntry(i, alert, self.alertFrame.frame) end
        self.alertFrame.frame:SetStatusText(format(L["Number of alerts: %s"], #self.alertFrame.alerts))
    end)
end

function MyChatAlert:ToggleAlertFrame()
    if self.alertFrame.frame:IsVisible() then self.alertFrame.frame:Hide()
    else self.alertFrame.frame:Show()
    end
end

function MyChatAlert:AddAlert(word, author, msg, channel) -- makes sure no more than 15 alerts are stored
    if #self.alertFrame.alerts == self.alertFrame.MAX_ALERTS_TO_KEEP then tremove(self.alertFrame.alerts, 1) end -- remove first/oldest alert
    tinsert(self.alertFrame.alerts, {word = word, author = author, msg = msg, channel = channel, time = time()}) -- insert alert

    if self.alertFrame.frame:IsVisible() then -- reload frame
        self.alertFrame.frame:Hide()
        self.alertFrame.frame:Show()
    end

    if self.db.profile.soundOn then PlaySound(self.db.profile.sound) end
    if self.db.profile.printOn then
        LibStub("AceConsole-3.0"):Print(format(L["Printed alert"], word, "|Hplayer:" .. author .. ":0|h" .. author .. "|h", msg)) -- link api thanks to GH:'tg123'
    end
end

-------------------------------------------------------------
-------------------------- HELPERS --------------------------
-------------------------------------------------------------

function TrimRealmName(author)
    local name = author
    local realmDelim = name:find("-") -- nil if not found, otherwise tells where the name ends and realm begins
    if realmDelim ~= nil then -- name includes the realm name, we can trim that
        name = name:sub(1, realmDelim - 1) -- don't want to include the '-' symbol
    end

    return name
end

-------------------------------------------------------------
-------------------------- FILTERS --------------------------
-------------------------------------------------------------

function MyChatAlert:AuthorIgnored(author)
    if author == UnitName("player") then return true end -- don't do anything if it's your own message

    for _, name in pairs(self.db.profile.ignoredAuthors) do
        if author == name then return true end
    end

    --[[ FIXME: GlobalIgnoreList filter not working (test after fixing return value)
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
    if self.db.profile.filterWords and self.db.profile.filterWords[channel] then
        for _, word in pairs(self.db.profile.filterWords[channel]) do
            if message:lower():find(word:lower()) then return true end
        end
    end

    return false
end

function MyChatAlert:IsDuplicateMessage(message, author)
    for i, alert in pairs(self.alertFrame.alerts) do
        if message == alert.msg and author == alert.author and time() - alert.time < self.db.profile.dedupTime then return true end
    end

    return false
end
