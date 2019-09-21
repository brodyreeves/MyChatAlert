local addonName, addon = ...

_G[addonName] = addon

do
    local alertFrame = CreateFrame("Frame") -- creates frame for alert
    alertFrame:SetScript("OnEvent", function(self, event, message, author, _, channel)
        if not addon.db.enable then
            self:UnregisterEvent("CHAT_MSG_CHANNEL")
            return
        end
        local colorG, colorY, colorW = "|cFF00FF00", "|cFFFFFF00", "|r" -- text color flags

        local channels = addon.db.channels
        local words = addon.db.words

        for k, ch in pairs(channels) do
            if event == "CHAT_MSG_CHANNEL" and channel:lower() == ch:lower() then
                for k2, word in pairs(words) do
                    if message:lower():find(word:lower()) then -- Alert message
                        if addon.db.soundOn then PlaySound(addon.db.sound) end
                        if addon.db.printOn then print(colorG .. "Keyword <" .. colorY .. word .. colorG .. "> seen from " .. colorY .. "[" .. author .. "]" .. colorG .. ": " .. colorY .. message) end
                        break
                    end
                end
            end
        end
    end)

    local eventFrame = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
    eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
        if loadedAddon ~= addonName then return end
        self:UnregisterEvent("ADDON_LOADED")

        if type(MyChatAlertDB) ~= "table" then MyChatAlertDB = {} end
        local sv = MyChatAlertDB
        if type(sv.enable) ~= "boolean" then sv.enable = true end
        if type(sv.soundOn) ~= "boolean" then sv.soundOn = true end
        if type(sv.printOn) ~= "boolean" then sv.printOn = false end
        if type(sv.channels) ~= "table" then sv.channels = {} end
        if type(sv.sound) ~= "string" then sv.sound = "881" end
        if type(sv.words) ~= "table" then sv.words = {} end
        addon.db = sv

        self:SetScript("OnEvent", nil)
    end)

    alertFrame:RegisterEvent("CHAT_MSG_CHANNEL") -- register with chat message event
    addon.alerts = alertFrame
    eventFrame:RegisterEvent("ADDON_LOADED")
    addon.frame = eventFrame
end
