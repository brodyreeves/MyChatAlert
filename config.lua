
local addonName, addon = ...

local frame = addon.frame
frame.name = addonName
frame:Hide()

frame:SetScript("OnShow", function(frame)
    -- checkbox constructor
    local function newCheckbox(label, description, onClick)
        local check = CreateFrame("CheckButton", "MyChatAlertCheck" .. label, frame, "InterfaceOptionsCheckButtonTemplate")
        check:SetScript("OnClick", function(self)
            local tick = self:GetChecked()
            onClick(self, tick and true or false)
            if tick then
                PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
            else
                PlaySound(857) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
            end
        end)
        check.label = _G[check:GetName() .. "Text"]
        check.label:SetText(label)
        check.tooltipText = label
        check.tooltipRequirement = description
        return check
    end

    -- title for options section
    local title = frame:CreateFontString(nil, "Overlay", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 10, -15)
    title:SetText(addonName)

    -- enable checkbox
    local enable = newCheckbox(
        "Enable",
        "Enable/disable chat alerts",
        function(self, value)
            addon.db.enable = value
            if value then -- just enabled
                addon.alerts:RegisterEvent("CHAT_MSG_CHANNEL")
            else -- just disabled
                addon.alerts:UnregisterEvent("CHAT_MSG_CHANNEL")
            end
        end)
    enable:SetChecked(addon.db.enable)
    enable:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -16)

    -- sound checkbox
    local soundOn = newCheckbox(
        "Sound",
        "Enable/disable sounds for alerts",
        function(self, value)
            addon.db.soundOn = value
        end)
    soundOn:SetChecked(addon.db.soundOn)
    soundOn:SetPoint("LEFT", enable, "RIGHT", 100, 0)

    -- print checkbox
    local printOn = newCheckbox(
        "Printing",
        "Enable/disable printed alerts",
        function(self, value)
            addon.db.printOn = value
        end)
    printOn:SetChecked(addon.db.printOn)
    printOn:SetPoint("LEFT", soundOn, "RIGHT", 100, 0)

    -- editbox to set channel
    local channelEditBox = CreateFrame("EditBox", "MyChatAlertChannelEditBox", frame, "InputBoxTemplate")
    channelEditBox:SetPoint("TOPLEFT", enable, "BOTTOMLEFT", 8, -8)
    channelEditBox:SetHeight(10)
    channelEditBox:SetWidth(150)
    channelEditBox:SetAutoFocus(false)
    channelEditBox:SetText("Ex: 4. LookingForGroup")

    -- add channel button
    local channelAddButton = CreateFrame("Button", "MyChatAlertChannelAddButton", frame, "UIPanelButtonTemplate")
    channelAddButton:SetPoint("LEFT", channelEditBox, "RIGHT", 0, 0)
    channelAddButton:SetText("Add")
    channelAddButton:SetScript("OnClick", function()
        local channel = channelEditBox:GetText()
        if channel and channel ~= "" then
            tinsert(addon.db.channels, channel)
            channelEditBox:ClearFocus()
            channelEditBox:SetText("Ex: 4. LookingForGroup")
        end
    end)

    -- keywords dropdown display
    local ddInfo = {}
    local channelDropdown = CreateFrame("Frame", "MyChatAlertChannelDropdown", frame, "UIDropDownMenuTemplate")
    channelDropdown:SetPoint("LEFT", channelAddButton, "RIGHT", -14, -2)
    channelDropdown.initialize = function()
        wipe(ddInfo)
        for _, channel in next, addon.db.channels do
            ddInfo.text = channel
            ddInfo.value = channel
            ddInfo.func = function(self)
                MyChatAlertChannelDropdownText:SetText(self:GetText())
            end
            ddInfo.checked = channel == MyChatAlertChannelDropdownText:GetText()
            UIDropDownMenu_AddButton(ddInfo)
        end
    end
    MyChatAlertChannelDropdownText:SetText("Channels")

    -- delete channel button
    local channelDelButton = CreateFrame("Button", "MyChatAlertChannelDeleteButton", frame, "UIPanelButtonTemplate")
    channelDelButton:SetPoint("LEFT", channelAddButton, "RIGHT", 138, 0)
    channelDelButton:SetSize(54 , 22)
    channelDelButton:SetText("Delete")
    channelDelButton:SetScript("OnClick", function()
        channel = MyChatAlertChannelDropdownText:GetText()
        for i = 1, #addon.db.channels do
            if addon.db.channels[i] == channel then
                tremove(addon.db.channels, i)
                MyChatAlertChannelDropdownText:SetText("Channels")
                break
            end
        end
    end)

    -- editbox to add words
    local keywordEditBox = CreateFrame("EditBox", "MyChatAlertKeywordEditBox", frame, "InputBoxTemplate")
    keywordEditBox:SetPoint("TOPLEFT", channelEditBox, "BOTTOMLEFT", 0, -15)
    keywordEditBox:SetHeight(10)
    keywordEditBox:SetWidth(150)
    keywordEditBox:SetAutoFocus(false)

    -- add button
    local keywordAddButton = CreateFrame("Button", "MyChatAlertKeywordAddButton", frame, "UIPanelButtonTemplate")
    keywordAddButton:SetPoint("LEFT", keywordEditBox, "RIGHT", 0, 0)
    keywordAddButton:SetText("Add")
    keywordAddButton:SetScript("OnClick", function()
        local word = keywordEditBox:GetText()
        if word and word ~= "" then
            tinsert(addon.db.words, word)
            keywordEditBox:ClearFocus()
            keywordEditBox:SetText("")
        end
    end)

    -- keywords dropdown display
    local dd2Info = {}
    local keywordDropdown = CreateFrame("Frame", "MyChatAlertKeywordDropdown", frame, "UIDropDownMenuTemplate")
    keywordDropdown:SetPoint("LEFT", keywordAddButton, "RIGHT", -14, -2)
    keywordDropdown.initialize = function()
        wipe(dd2Info)
        for _, word in next, addon.db.words do
            dd2Info.text = word
            dd2Info.value = word
            dd2Info.func = function(self)
                MyChatAlertKeywordDropdownText:SetText(self:GetText())
            end
            dd2Info.checked = word == MyChatAlertKeywordDropdownText:GetText()
            UIDropDownMenu_AddButton(dd2Info)
        end
    end
    MyChatAlertKeywordDropdownText:SetText("Keywords")

    -- delete button
    local keywordDelButton = CreateFrame("Button", "MyChatAlertKeywordDeleteButton", frame, "UIPanelButtonTemplate")
    keywordDelButton:SetPoint("LEFT", keywordAddButton, "RIGHT", 138, 0)
    keywordDelButton:SetSize(54 , 22)
    keywordDelButton:SetText("Delete")
    keywordDelButton:SetScript("OnClick", function()
        word = MyChatAlertKeywordDropdownText:GetText()
        for i = 1, #addon.db.words do
            if addon.db.words[i] == word then
                tremove(addon.db.words, i)
                MyChatAlertKeywordDropdownText:SetText("Keywords")
                break
            end
        end
    end)

    -- editbox to set sound
    local soundEditBox = CreateFrame("EditBox", "MyChatAlertSoundEditBox", frame, "InputBoxTemplate")
    soundEditBox:SetPoint("TOPLEFT", keywordEditBox, "BOTTOMLEFT", 0, -15)
    soundEditBox:SetHeight(10)
    soundEditBox:SetWidth(150)
    soundEditBox:SetAutoFocus(false)
    soundEditBox:SetText(addon.db.sound)

    -- set sound button
    local soundSetButton = CreateFrame("Button", "MyChatAlertSoundSetButton", frame, "UIPanelButtonTemplate")
    soundSetButton:SetPoint("LEFT", soundEditBox, "RIGHT", 0, 0)
    soundSetButton:SetText("Set")
    soundSetButton:SetScript("OnClick", function()
        local sound = soundEditBox:GetText()
        if sound and sound ~= "" then
            addon.db.sound = sound
            soundEditBox:ClearFocus()
        end
    end)

    -- test sound button
    local soundTestButton = CreateFrame("Button", "MyChatAlertSoundTestButton", frame, "UIPanelButtonTemplate")
    soundTestButton:SetPoint("LEFT", soundSetButton, "RIGHT", 0, 0)
    soundTestButton:SetText("Test")
    soundTestButton:SetScript("OnClick", function()
        local sound = soundEditBox:GetText()
        if sound and sound ~= "" then
            PlaySound(sound)
        end
    end)

    frame:SetScript("OnShow", nil)
end)
InterfaceOptions_AddCategory(frame)
