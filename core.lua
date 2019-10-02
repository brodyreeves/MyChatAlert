MyChatAlert = LibStub("AceAddon-3.0"):NewAddon("MyChatAlert", "AceConsole-3.0", "AceEvent-3.0")

local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("MyChatAlert")

function MyChatAlert:OnInitialize()
    -- Called when the addon is loaded
    self.db = LibStub("AceDB-3.0"):New("MyChatAlertDB", self.defaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable("MyChatAlert", self.options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MyChatAlert", "MyChatAlert")

    self:RegisterChatCommand("mca", "ChatCommand")
end

function MyChatAlert:OnEnable()
    if self.db.profile.enabled then self:RegisterEvent("CHAT_MSG_CHANNEL") end
end

function MyChatAlert:OnDisable()
    self:UnregisterEvent("CHAT_MSG_CHANNEL")
end

-- Event Handlers
function MyChatAlert:CHAT_MSG_CHANNEL(event, message, author, _, channel)
    if author == UnitName("player") then return end -- don't do anything if it's your own message

    -- optional globalignorelist check
    if self.db.profile.globalignorelist then
        for i = 1, #GlobalIgnoreDB.ignoreList do
            if author == GlobalIgnoreDB.ignoreList[i] then -- found in ignore list
                return
            end
        end
    end

    for k, ch in pairs(self.db.profile.channels) do
        if event == "CHAT_MSG_CHANNEL" and channel:lower() == ch:lower() then
            for k2, word in pairs(self.db.profile.words) do
                if message:lower():find(word:lower()) then -- Alert message
                    if self.db.profile.soundOn then PlaySound(self.db.profile.sound) end
                    if self.db.profile.printOn then
                        LibStub("AceConsole-3.0"):Print(format(L["Printed alert"], word, author, message))
                    end
                    self:AddAlert(word, author, message)
                    break -- matched the message so stop looping
                end
            end
            break -- matched the channel so stop looping
        end
    end
end

-- Chat Command
function MyChatAlert:ChatCommand(arg)
    if arg == "alerts" then -- open alerts frame
        self:ShowDisplay()
    else -- just open the options
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame) -- need two calls
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    end
end

-- Alert Frame
MyChatAlert.frameOn = false
MyChatAlert.alerts = {}

function MyChatAlert:AddAlert(word, author, msg) -- makes sure no more than 15 alerts are stored
    local MAX_ALERTS_TO_KEEP = 30
    if #self.alerts == MAX_ALERTS_TO_KEEP then tremove(self.alerts, 1) end -- remove first/oldest alert

    local auth = author
    local realmDelim = auth:find("-") -- nil if not found, otherwise tells where the name ends and realm begins
    if realmDelim ~= nil then -- author includes the realm name, we can trim that
        auth = auth:sub(1, realmDelim - 1) -- don't want to include the '-' symbol
    end

    tinsert(self.alerts, {word = word, author = auth, msg = msg, displayed = false})
end

function MyChatAlert:ClearAlerts()
    self.alerts = {}
end

function MyChatAlert:ShowDisplay()
    local function newLabel(text, width, parent)
        local frame = AceGUI:Create("Label")
        frame:SetText(text)
        frame:SetRelativeWidth(width)
        parent:AddChild(frame)
        return frame
    end

    local function newIntLabel(text, width, callback, parent)
        local frame = AceGUI:Create("Label")
        frame:SetText(text)
        frame:SetRelativeWidth(width)
        frame:SetCallback("OnClick", callback)
        parent:AddChild(frame)
        return frame
    end

    if not self.frameOn then -- display new frame
        local alertFrame = AceGUI:Create("Frame")
        alertFrame:SetTitle(L["MyChatAlert"])
        alertFrame:SetStatusText(format(L["Number of alerts: %s"], #self.alerts))
        alertFrame:SetCallback("OnClose", function(widget)
            AceGUI:Release(widget)
            self.frameOn = false
            MyChatAlert.alertFrame = nil
        end)
        alertFrame:SetLayout("Flow")

        -- Column headers
        local alertNum = newLabel(L["Number Header"], 0.04, alertFrame)
        alertNum:SetColor(255, 255, 0)

        local alertWord = newLabel(L["Keyword"], 0.11, alertFrame)
        alertWord:SetColor(255, 255, 0)

        local alertAuthor = newLabel(L["Author"], 0.13, alertFrame)
        alertAuthor:SetColor(255, 255, 0)

        local alertMsg = newLabel(L["Message"], 0.72, alertFrame)
        alertMsg:SetColor(255, 255, 0)

        -- list alerts
        for k, alert in pairs(self.alerts) do
            local alertNum = newLabel(k .. L["Number delimiter"], 0.04, alertFrame)
            local alertWord = newLabel(alert.word, 0.11, alertFrame)
            local alertAuthor = newIntLabel(alert.author, 0.13, function(button) ChatFrame_OpenChat(format(L["/w %s "], alert.author)) end, alertFrame)
            local alertMsg = newLabel(alert.msg, 0.72, alertFrame)

            alert.displayed = true
        end

        MyChatAlert.alertFrame = alertFrame
        self.frameOn = true

    else -- frame already showing
        MyChatAlert.alertFrame:SetStatusText(format(L["Number of alerts: %s"], #self.alerts))
        for k, alert in pairs(self.alerts) do
            if alert.displayed == false then -- only display new alerts
                local alertNum = newLabel(k .. L["Number delimiter"], 0.04, MyChatAlert.alertFrame)
                local alertWord = newLabel(alert.word, 0.11, MyChatAlert.alertFrame)
                local alertAuthor = newIntLabel(alert.author, 0.13, function(button) ChatFrame_OpenChat(format(L["/w %s "], alert.author)) end, MyChatAlert.alertFrame)
                local alertMsg = newLabel(alert.msg, 0.72, MyChatAlert.alertFrame)

                alert.displayed = true
            end
        end
    end
end
