
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

    -- editbox to set channel
    local channelEditBox = CreateFrame("EditBox", "MyChatAlertChannelEditBox", frame, "InputBoxTemplate")
    channelEditBox:SetPoint("TOPLEFT", enable, "BOTTOMLEFT", 8, -8)
    channelEditBox:SetHeight(10)
    channelEditBox:SetWidth(150)
    channelEditBox:SetAutoFocus(false)
    if addon.db.channel then channelEditBox:SetText(addon.db.channel) end

    -- set channel button
    local keywordAddButton = CreateFrame("Button", "MyChatAlertChannelSetButton", frame, "UIPanelButtonTemplate")
    keywordAddButton:SetPoint("LEFT", channelEditBox, "RIGHT", 0, 0)
    keywordAddButton:SetText("Set")
    keywordAddButton:SetScript("OnClick", function()
        local channel = channelEditBox:GetText()
        if channel and channel ~= "" then
            addon.db.channel = channel
            channelEditBox:ClearFocus()
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
            tinsert(addon.db.words, keywordEditBox:GetText())
            keywordEditBox:ClearFocus()
            keywordEditBox:SetText("")
        end
    end)

    -- keywords dropdown display
    local ddInfo = {}
    local keywordDropdown = CreateFrame("Frame", "MyChatAlertKeywordDropdown", frame, "UIDropDownMenuTemplate")
    keywordDropdown:SetPoint("LEFT", keywordAddButton, "RIGHT", -14, -2)
    keywordDropdown.initialize = function()
        wipe(ddInfo)
        for _, word in next, addon.db.words do
            ddInfo.text = word
            ddInfo.value = word
            ddInfo.func = function(self)
                MyChatAlertKeywordDropdownText:SetText(self:GetText())
            end
            ddInfo.checked = word == MyChatAlertKeywordDropdownText:GetText()
            UIDropDownMenu_AddButton(ddInfo)
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

    frame:SetScript("OnShow", nil)
end)
InterfaceOptions_AddCategory(frame)
