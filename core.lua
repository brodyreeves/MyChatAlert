MyChatAlert = LibStub("AceAddon-3.0"):NewAddon("MyChatAlert", "AceConsole-3.0", "AceEvent-3.0")

local AceGUI = LibStub("AceGUI-3.0")
local colorG, colorR, colorY, colorW = "|cFF00FF00", "|cffff0000", "|cFFFFFF00", "|r" -- text color flags

function MyChatAlert:OnInitialize()
    -- Called when the addon is loaded
    self.db = LibStub("AceDB-3.0"):New("MyChatAlertDB", self.defaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable("MyChatAlert", self.options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MyChatAlert", "MyChatAlert")
end

function MyChatAlert:OnEnable()
    if self.db.profile.enabled then self:RegisterEvent("CHAT_MSG_CHANNEL") end
end

function MyChatAlert:OnDisable()
    self:UnregisterEvent("CHAT_MSG_CHANNEL")
end

-- Event Handlers
function MyChatAlert:CHAT_MSG_CHANNEL(event, message, author, _, channel)
    for k, ch in pairs(self.db.profile.channels) do
        if event == "CHAT_MSG_CHANNEL" and channel:lower() == ch:lower() then
            for k2, word in pairs(self.db.profile.words) do
                if message:lower():find(word:lower()) then -- Alert message
                    if self.db.profile.soundOn then PlaySound(self.db.profile.sound) end
                    if self.db.profile.printOn then
                        LibStub("AceConsole-3.0"):Print(colorG .. "Keyword <" .. colorY .. word .. colorG .. "> seen from " .. colorY .. "[" .. author .. "]" .. colorG .. ": " .. colorY .. message)
                    end
                    self:AddAlert(word, author, message)
                    break -- matched the message so stop looping
                end
            end
            break -- matched the channel so stop looping
        end
    end
end

MyChatAlert.frameOn = false
MyChatAlert.alerts = {}

function MyChatAlert:AddAlert(word, author, msg) -- makes sure no more than 15 alerts are stored
    if #self.alerts == 15 then tremove(self.alerts, 1) end -- remove first/oldest alert
    tinsert(self.alerts, {word = word, author = author, msg = msg})
end

function MyChatAlert:ClearAlerts()
    self.alerts = {}
end

function MyChatAlert:ShowDisplay()
    if not self.frameOn then
        local alertFrame = AceGUI:Create("Frame")
        alertFrame:SetTitle("MyChatAlert")
        alertFrame:SetStatusText("Number of alerts: " .. #self.alerts)
        alertFrame:SetCallback("OnClose", function(widget)
            AceGUI:Release(widget)
            self.frameOn = false
        end)
        alertFrame:SetLayout("Flow")

        -- Column headers
        local alertNum = AceGUI:Create("Label")
        alertNum:SetText("#.")
        alertNum:SetRelativeWidth(0.04)
        alertFrame:AddChild(alertNum)

        local alertWord = AceGUI:Create("Label")
        alertWord:SetText("Keyword")
        alertWord:SetRelativeWidth(0.13)
        alertFrame:AddChild(alertWord)

        local alertAuthor = AceGUI:Create("Label")
        alertAuthor:SetText("Author")
        alertAuthor:SetRelativeWidth(0.13)
        alertFrame:AddChild(alertAuthor)

        local alertMsg = AceGUI:Create("Label")
        alertMsg:SetText("Message")
        alertMsg:SetRelativeWidth(0.70)
        alertFrame:AddChild(alertMsg)

        -- list alerts
        for k, alert in pairs(self.alerts) do
            local alertNum = AceGUI:Create("Label")
            alertNum:SetText(k .. ".")
            alertNum:SetRelativeWidth(0.04)
            alertFrame:AddChild(alertNum)

            local alertWord = AceGUI:Create("Label")
            alertWord:SetText(alert.word)
            alertWord:SetRelativeWidth(0.13)
            alertFrame:AddChild(alertWord)

            local alertAuthor = AceGUI:Create("EditBox")
            alertAuthor:SetText(alert.author)
            alertAuthor:SetRelativeWidth(0.13)
            alertAuthor:DisableButton(true)
            alertFrame:AddChild(alertAuthor)

            local alertMsg = AceGUI:Create("Label")
            alertMsg:SetText(alert.msg)
            alertMsg:SetRelativeWidth(0.7)
            alertFrame:AddChild(alertMsg)
        end
    end

    self.frameOn = true
end
