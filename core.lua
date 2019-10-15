MyChatAlert = LibStub("AceAddon-3.0"):NewAddon("MyChatAlert", "AceConsole-3.0", "AceEvent-3.0")

local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("MyChatAlert")

function MyChatAlert:OnInitialize()
    -- Called when the addon is loaded
    self.db = LibStub("AceDB-3.0"):New("MyChatAlertDB", self.defaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable("MyChatAlert", self.options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MyChatAlert", "MyChatAlert")

    self:RegisterChatCommand("mca", "ChatCommand")

    -- Migrate SVs if needed
    if self.db.profile.channels and self.db.profile.words then
        if not self.db.profile.triggers then self.db.profile.triggers = {} end

        --[[ main part of migration, moving from single list of words for every channel in the list to a list of words for each individual channel in the list
            old scheme:
            db.channels = {"chan1", "chan2", ...}
            db.words = {"word1", "word2", ...}

            new scheme:
            db.triggers = {
                "chan1" = {"word1", "word2"},
                "chan2" = {"word1", "word3"},
            }
        ]]--

        for _, channel in pairs(self.db.profile.channels) do
            local words = {}
            for _, word in pairs(self.db.profile.words) do
                tinsert(words, word)
            end
            self.db.profile.triggers[channel] = words
        end
        -- once moved, delete the old ones
        self.db.profile.channels = nil
        self.db.profile.words = nil

        if not self.db.profile.filterWords then self.db.profile.filterWords = {} end
    end
end

MyChatAlert.eventMap = {
    [L["Guild"]] = "CHAT_MSG_GUILD",
    --[L["Loot"]] = "CHAT_MSG_LOOT",
    [L["Officer"]] = "CHAT_MSG_OFFICER",
    [L["Party"]] = "CHAT_MSG_PARTY",
    [L["Party Leader"]] = "CHAT_MSG_PARTY_LEADER",
    [L["Raid"]] = "CHAT_MSG_RAID",
    [L["Raid Leader"]] = "CHAT_MSG_RAID_LEADER",
    [L["Raid Warning"]] = "CHAT_MSG_RAID_WARNING",
    [L["Say"]] = "CHAT_MSG_SAY",
    --[L["System"]] = "CHAT_MSG_SYSTEM",
    [L["Yell"]] = "CHAT_MSG_YELL",
}

function MyChatAlert:OnEnable()
    local msg_chan_reg = false

    for chan, _ in pairs(self.db.profile.triggers) do -- register all necessary events for added channels
        if self.eventMap[chan] then -- channel is mapped to an event
            self:RegisterEvent(self.eventMap[chan])
        elseif not msg_chan_reg then -- custom/global channels use generic event
            self:RegisterEvent("CHAT_MSG_CHANNEL")
            msg_chan_reg = true
        end
    end
end

function MyChatAlert:OnDisable()
    self:UnregisterEvent("CHAT_MSG_CHANNEL")

    for _, event in pairs(self.eventMap) do
        self:UnregisterEvent(event)
    end
end

-- Event Handlers
function MyChatAlert:CHAT_MSG_CHANNEL(event, message, author, _, channel)
    if self:AuthorIgnored(self:TrimRealmName(author)) then return end
    if self:MessageIgnored(message, channel) then return end

    for ch, words in pairs(self.db.profile.triggers) do -- find the channel
        if channel:lower() == ch:lower() then
            for _, word in pairs(words) do -- find the word
                if message:lower():find(word:lower()) then -- Alert message
                    self:AddAlert(word, self:TrimRealmName(author), message, channel)
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
    if self:AuthorIgnored(self:TrimRealmName(author)) then return end
    if self:MessageIgnored(message, channel) then return end

    for _, word in pairs(self.db.profile.triggers[channel]) do -- find the word
        if message:lower():find(word:lower()) then -- Alert message
            self:AddAlert(word, self:TrimRealmName(author), message, channel)
            return -- matched the message, stop
        end
    end
end

-- Chat Commands
function MyChatAlert:ChatCommand(arg)
    if arg == "alerts" then -- open alerts frame
        self:ShowAlertFrame()
    else -- just open the options
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame) -- need two calls
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    end
end

-- Alert Frame
MyChatAlert.frameOn = false
MyChatAlert.alertCache = {}

function MyChatAlert:AddAlert(word, author, msg, channel) -- makes sure no more than 15 alerts are stored
    local MAX_ALERTS_TO_KEEP = 30
    if #self.alertCache == MAX_ALERTS_TO_KEEP then tremove(self.alertCache, 1) end -- remove first/oldest alert

    tinsert(self.alertCache, {word = word, author = author, msg = msg, channel = channel, displayed = false})

    if self.db.profile.soundOn then PlaySound(self.db.profile.sound) end
    if self.db.profile.printOn then
        LibStub("AceConsole-3.0"):Print(format(L["Printed alert"], word, "|Hplayer:" .. author .. ":0|h" .. author .. "|h", msg)) -- link api thanks to GH:'tg123'
    end
end

function MyChatAlert:ClearAlerts()
    self.alertCache = {}
end

function MyChatAlert:ShowAlertFrame()
    local function newLabel(text, width, parent)
        local frame = AceGUI:Create("Label")
        frame:SetText(text)
        frame:SetRelativeWidth(width)
        parent:AddChild(frame)
        return frame
    end

    local function newIntLabel(text, width, callback, parent)
        local frame = AceGUI:Create("InteractiveLabel")
        frame:SetText(text)
        frame:SetRelativeWidth(width)
        frame:SetCallback("OnClick", callback)
        parent:AddChild(frame)
        return frame
    end

    local function addEntry(num, alert, parent)
        local alertNum = newLabel(num .. L["Number delimiter"], 0.04, parent)
        local alertChan = newLabel(alert.channel, 0.17, parent)
        local alertWord = newLabel(alert.word, 0.11, parent)
        local alertAuthor = newIntLabel(alert.author, 0.13, function(button) ChatFrame_OpenChat(format(L["/w %s "], alert.author)) end, parent)
        local alertMsg = newLabel(alert.msg, 0.55, parent)

        alert.displayed = true
    end

    if not self.frameOn then -- display new frame
        local alertFrame = AceGUI:Create("Frame")
        alertFrame:SetTitle(L["MyChatAlert"])
        alertFrame:SetStatusText(format(L["Number of alerts: %s"], #self.alertCache))
        alertFrame:SetCallback("OnClose", function(widget)
            AceGUI:Release(widget)
            self.frameOn = false
            self.alertFrame = nil
        end)
        alertFrame:SetLayout("Flow")

        -- Column headers
        local alertNum = newLabel(L["Number Header"], 0.04, alertFrame)
        alertNum:SetColor(255, 255, 0)

        local alertChan = newLabel(L["Channel"], 0.17, alertFrame)
        alertChan:SetColor(255, 255, 0)

        local alertWord = newLabel(L["Keyword"], 0.11, alertFrame)
        alertWord:SetColor(255, 255, 0)

        local alertAuthor = newLabel(L["Author"], 0.13, alertFrame)
        alertAuthor:SetColor(255, 255, 0)

        local alertMsg = newLabel(L["Message"], 0.55, alertFrame)
        alertMsg:SetColor(255, 255, 0)

        -- list alerts
        for k, alert in pairs(self.alertCache) do addEntry(k, alert, alertFrame) end

        self.alertFrame = alertFrame
        self.frameOn = true

    else -- frame already showing
        self.alertFrame:SetStatusText(format(L["Number of alerts: %s"], #self.alertCache))
        for k, alert in pairs(self.alertCache) do
            if not alert.displayed then -- only display alerts new since opening the frame
                addEntry(k, alert, self.alertFrame)
            end
        end
    end
end

-- helpers
function MyChatAlert:TrimRealmName(author)
    local name = author
    local realmDelim = name:find("-") -- nil if not found, otherwise tells where the name ends and realm begins
    if realmDelim ~= nil then -- name includes the realm name, we can trim that
        name = name:sub(1, realmDelim - 1) -- don't want to include the '-' symbol
    end
    return name
end

function MyChatAlert:AuthorIgnored(author)
    if author == UnitName("player") then return true end -- don't do anything if it's your own message

    -- TODO: ignore users feature

    --[[ FIXME: GlobalIgnoreList filter not working
        -- optional globalignorelist check
        if self.db.profile.globalignorelist then
            for i = 1, #GlobalIgnoreDB.ignoreList do
                if author == GlobalIgnoreDB.ignoreList[i] then -- found in ignore list
                    return
                end
            end
        end
    ]]--
    return false
end

function MyChatAlert:MessageIgnored(message, channel) -- TODO: finsh filter
    if self.db.profile.filterWords and self.db.profile.filterWords[channel] then
        for _, word in pairs(self.db.profile.filterWords[channel]) do
            if message:lower():find(word:lower()) then return true end
        end
    end
    return false
end
