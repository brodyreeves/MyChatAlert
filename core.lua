MyChatAlert = LibStub("AceAddon-3.0"):NewAddon("MyChatAlert", "AceConsole-3.0", "AceEvent-3.0")

local colorG, colorR, colorY, colorW = "|cFF00FF00", "|cffff0000", "|cFFFFFF00", "|r" -- text color flags

function MyChatAlert:OnInitialize()
    -- Called when the addon is loaded
    self.db = LibStub("AceDB-3.0"):New("MyChatAlertDB", self.defaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable("MyChatAlert", self.options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MyChatAlert", "MyChatAlert")
end

function MyChatAlert:OnEnable()
    self:RegisterEvent("CHAT_MSG_CHANNEL")
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
                    break -- matched the message so stop looping
                end
            end
            break -- matched the channel so stop looping
        end
    end
end
