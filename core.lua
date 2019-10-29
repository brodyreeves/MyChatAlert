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
    local _, type = IsInInstance()
    if not self.db.profile.enabled or (self.db.profile.disableInInstance and type and type ~= "none") then return end

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
end

function MyChatAlert:OnDisable()
    local _, type = IsInInstance()
    if self.db.profile.enabled and ((type and type == "none") or not self.db.profile.disableInInstance) then return end

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
    if self.db.profile.triggers and self.db.profile.triggers[channel] then
        self:CheckAlert(event, message, author, channel)
    end
end

function MyChatAlert:CHAT_MSG_GUILD(event, message, author)
    self:CheckAlert(event, message, author, L["Guild"])
end

function MyChatAlert:CHAT_MSG_LOOT(event, message)
    -- TODO: test this
    for _, word in pairs(self.db.profile.triggers[L["MyChatAlert Global Keywords"]]) do
        if message:lower():find(word:lower()) then
            self:AddAlert(word, UnitName("player"), message, "*" .. L["Loot"])
            return
        end
    end

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

    if self.db.profile.triggers[L["MyChatAlert Global Keywords"]] then
        for _, word in pairs(self.db.profile.triggers[L["MyChatAlert Global Keywords"]]) do -- check global keywords after matching the channel to ensure channel is added
            local match = true

            if word:find("[-+]") then -- advanced pattern matching
                if not word:sub(1, 1):find("[-+]") then
                    -- the word contains -+ operators, but doesn't start with one
                    -- something along the form of lf+tank-brs
                    local i, _ = word:find("[-+]")
                    if not message:lower():find(word:sub(1, i - 1)) then match = false end
                end

                if match then -- no need to check if we have already determined not a match via first term
                    for subword in word:lower():gmatch("[-+]%a+") do -- split by operators
                        if match then -- no need to check if we have already determined not a match via previous subword
                            if subword:sub(1, 1) == "+" then -- need to find additional terms
                                if not message:lower():find(subword:sub(2, -1)) then match = false end
                            elseif subword:sub(1, 1) == "-" then -- need to not find these terms
                                if message:lower():find(subword:sub(2, -1)) then match = false end
                            else
                                print("[MCA Panic!] (core:167) Unexpected operator found") -- BUG CATCH error 167 #1
                            end
                        end
                    end
                end

            elseif not message:lower():find(word:lower()) then match = false end

            if match then
                self:AddAlert("*" .. word:sub(1, 11), TrimRealmName(author), message, channel:sub(1, 18)) -- :sub() just to help keep display width under control
                return
            end
        end
    end

    -- don't need to check existence here because it's already been checked
    -- named channels with own events have their table created when event is registered
    -- general channels with CHAT_MSG_CHANNEL get checked before entering the function
    for _, word in pairs(self.db.profile.triggers[channel]) do -- find the non-global keywords
        local match = true

        if word:find("[-+]") then -- advanced pattern matching
            if not word:sub(1, 1):find("[-+]") then
                -- the word contains -+ operators, but doesn't start with one
                -- something along the form of lf+tank-brs
                local i, _ = word:find("[-+]")
                if not message:lower():find(word:sub(1, i - 1)) then match = false end
            end

            if match then -- no need to check if we have already determined not a match via first term
                for subword in word:lower():gmatch("[-+]%a+") do -- split by operators
                    if match then -- no need to check if we have already determined not a match via previous subword
                        if subword:sub(1, 1) == "+" then -- need to find additional terms
                            if not message:lower():find(subword:sub(2, -1)) then match = false end
                        elseif subword:sub(1, 1) == "-" then -- need to not find these terms
                            if message:lower():find(subword:sub(2, -1)) then match = false end
                        else
                            print("[MCA Panic!] (core:167) Unexpected operator found") -- BUG CATCH error 167 #2
                        end
                    end
                end
            end

        elseif not message:lower():find(word:lower()) then match = false end

        if match then
            self:AddAlert(word:sub(1, 12), TrimRealmName(author), message, channel:sub(1, 18)) -- :sub() just to help keep display width under control
            return
        end
    end
end

function MyChatAlert:ZONE_CHANGED()
    local _, type = IsInInstance()

    if type == "none" then self:OnEnable()
    elseif self.db.profile.disableInInstance and type and type ~= "none" then self:OnDisable()
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
            tinsert(self.db.profile.ignoredAuthors, arg2)
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
        for i, alert in pairs(self.alertFrame.alerts) do self.alertFrame.AddEntry(i, alert, self.alertFrame.frame) end
        self.alertFrame.frame:SetStatusText(format(L["Number of alerts: %s"], #self.alertFrame.alerts))
    end)

    self.alertFrame.frame.frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" and self:IsVisible() then self:Hide() end
    end)

    self.alertFrame.frame.frame:SetPropagateKeyboardInput(true)
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
        local dest = self.outputFrames[self.db.profile.printOutput].frame

        local baseColor = rgbToHex({self.db.profile.baseColor.r, self.db.profile.baseColor.g, self.db.profile.baseColor.b})
        local keywordColor = rgbToHex({self.db.profile.keywordColor.r, self.db.profile.keywordColor.g, self.db.profile.keywordColor.b})
        local authorColor = rgbToHex({self.db.profile.authorColor.r, self.db.profile.authorColor.g, self.db.profile.authorColor.b})
        local messageColor = rgbToHex({self.db.profile.messageColor.r, self.db.profile.messageColor.g, self.db.profile.messageColor.b})

        local replacement = {
            keyword = keywordColor .. word .. baseColor,
            author = authorColor .. "|Hplayer:" .. author .. ":0|h" .. author .. "|h" .. baseColor,
            message = messageColor .. msg .. baseColor,
        }

        local message = baseColor .. interp(self.db.profile.printedMessage or L["Printed alert"], replacement)

        if dest == "DEFAULT_CHAT_FRAME" then
            DEFAULT_CHAT_FRAME:AddMessage(message, 1.0, 1.0, 1.0)
        elseif dest == "UIErrorsFrame" then
            UIErrorsFrame:AddMessage(message, 1.0, 1.0, 1.0)
        elseif dest == "ChatFrame1" then
            ChatFrame1:AddMessage(message, 1.0, 1.0, 1.0)
        elseif dest == "ChatFrame2" then
            ChatFrame2:AddMessage(message, 1.0, 1.0, 1.0)
        elseif dest == "ChatFrame3" then
            ChatFrame3:AddMessage(message, 1.0, 1.0, 1.0)
        elseif dest == "ChatFrame4" then
            ChatFrame4:AddMessage(message, 1.0, 1.0, 1.0)
        elseif dest == "ChatFrame5" then
            ChatFrame5:AddMessage(message, 1.0, 1.0, 1.0)
        elseif dest == "ChatFrame6" then
            ChatFrame6:AddMessage(message, 1.0, 1.0, 1.0)
        elseif dest == "ChatFrame7" then
            ChatFrame7:AddMessage(message, 1.0, 1.0, 1.0)
        elseif dest == "ChatFrame8" then
            ChatFrame8:AddMessage(message, 1.0, 1.0, 1.0)
        elseif dest == "ChatFrame9" then
            ChatFrame9:AddMessage(message, 1.0, 1.0, 1.0)
        elseif dest == "ChatFrame10" then
            ChatFrame10:AddMessage(message, 1.0, 1.0, 1.0)
        else
            print("[MCA Panic!] (core:332) Unrecognized printOutput selection") -- BUG CATCH error 332
        end
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

function interp(s, tab) -- named format replacement [http://lua-users.org/wiki/StringInterpolation]
    return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end

function rgbToHex(rgb) -- color form converter [https://gist.github.com/marceloCodget/3862929]
    -- local hexadecimal = '0X'
    local hexadecimal = '|cFF' -- prefix for wow coloring escape is |c, FF is the alpha portion

    for key, value in pairs(rgb) do
        local hex = ''
        value = math.floor(value * 255) -- uses rgb on a scale of 0-1, scale it up for this conversion

        while(value > 0)do
            local index = math.fmod(value, 16) + 1
            value = math.floor(value / 16)
            hex = string.sub('0123456789ABCDEF', index, index) .. hex
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

-------------------------------------------------------------
-------------------------- FILTERS --------------------------
-------------------------------------------------------------

function MyChatAlert:AuthorIgnored(author)
    if author == UnitName("player") then return true end -- don't do anything if it's your own message

    for _, name in pairs(self.db.profile.ignoredAuthors) do
        if author == name then return true end
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
    -- ignore message due to containing a filtered word
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
