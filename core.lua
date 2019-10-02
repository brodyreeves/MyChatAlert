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
    local MAX_ALERTS_TO_KEEP = 20
    if #self.alerts == MAX_ALERTS_TO_KEEP then tremove(self.alerts, 1) end -- remove first/oldest alert

    local auth = author
    local realmDelim = auth:find("-") -- nil if not found, otherwise tells where the name ends and realm begins
    if realmDelim ~= nil then -- author includes the realm name, we can trim that
        auth = auth:sub(1, realmDelim - 1) -- don't want to include the '-' symbol
    end

    tinsert(self.alerts, {word = word, author = auth, msg = msg})
end

function MyChatAlert:ClearAlerts()
    self.alerts = {}
end

function MyChatAlert:ShowDisplay()
    if not self.frameOn then
        local alertFrame = AceGUI:Create("Frame")
        alertFrame:SetTitle(L["MyChatAlert"])
        alertFrame:SetStatusText(format(L["Number of alerts: %s"], #self.alerts))
        alertFrame:SetCallback("OnClose", function(widget)
            AceGUI:Release(widget)
            self.frameOn = false
        end)
        alertFrame:SetLayout("Flow")

        -- Column headers
        local alertNum = AceGUI:Create("Label")
        alertNum:SetText(L["Number Header"])
        alertNum:SetColor(255, 255, 0)
        alertNum:SetRelativeWidth(0.04)
        alertFrame:AddChild(alertNum)

        local alertWord = AceGUI:Create("Label")
        alertWord:SetText(L["Keyword"])
        alertWord:SetColor(255, 255, 0)
        alertWord:SetRelativeWidth(0.11)
        alertFrame:AddChild(alertWord)

        local alertAuthor = AceGUI:Create("Label")
        alertAuthor:SetText(L["Author"])
        alertAuthor:SetColor(255, 255, 0)
        alertAuthor:SetRelativeWidth(0.13)
        alertFrame:AddChild(alertAuthor)

        local alertMsg = AceGUI:Create("Label")
        alertMsg:SetText(L["Message"])
        alertMsg:SetColor(255, 255, 0)
        alertMsg:SetRelativeWidth(0.72)
        alertFrame:AddChild(alertMsg)

        -- list alerts
        for k, alert in pairs(self.alerts) do
            local alertNum = AceGUI:Create("Label")
            alertNum:SetText(k .. L["Number delimiter"])
            alertNum:SetRelativeWidth(0.04)
            alertFrame:AddChild(alertNum)

            local alertWord = AceGUI:Create("Label")
            alertWord:SetText(alert.word)
            alertWord:SetRelativeWidth(0.11)
            alertFrame:AddChild(alertWord)

            local alertAuthor = AceGUI:Create("InteractiveLabel")
            alertAuthor:SetText(alert.author)
            alertAuthor:SetRelativeWidth(0.13)
            alertAuthor:SetCallback("OnClick", function(button)
                ChatFrame_OpenChat(format(L["/w %s "], alert.author)) -- api call to open chat with a whisper
            end)
            alertFrame:AddChild(alertAuthor)

            local alertMsg = AceGUI:Create("Label")
            alertMsg:SetText(alert.msg)
            alertMsg:SetRelativeWidth(0.72)
            alertFrame:AddChild(alertMsg)
        end

    end

    self.frameOn = true
end
