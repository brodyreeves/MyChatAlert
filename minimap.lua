local addonName, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale("MyChatAlert", false)

local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true)
if not ldb then return end

-- local consts
local TT_HEAD = "|cFF00FF00%s|r"
local TT_LINE = "|cFFCFCFCF%s|r"
local TT_HINT = "|r%s:|cFFCFCFCF %s"

local plugin = ldb:NewDataObject(addonName, {
    type = "data source",
    text = "0",
    icon = "Interface\\AddOns\\MyChatAlert\\Media\\icon",
})

function plugin.OnClick(self, button)
    if button == "LeftButton" then
        if IsControlKeyDown() then
            InterfaceOptionsFrame_OpenToCategory(addonName)
            InterfaceOptionsFrame_OpenToCategory(addonName) -- needs two calls

        else
            MyChatAlert:ToggleAlertFrame()
        end

    elseif button == "RightButton" then
        if IsControlKeyDown() then
            MyChatAlert.db.profile.enabled = not MyChatAlert.db.profile.enabled

            if MyChatAlert.db.profile.enabled then MyChatAlert:OnEnable()
            else MyChatAlert:OnDisable() end

        else
            MyChatAlert.alertFrame.ClearAlerts()
        end
    end
end

function plugin.OnTooltipShow(tt)
    tt:AddLine(format(TT_HEAD, addonName))

    local numAlerts = #MyChatAlert.alertFrame.alerts

    if numAlerts == 0 then tt:AddLine(format(TT_LINE, L["You have no alerts"]))
    elseif numAlerts == 1 then tt:AddLine(format(TT_LINE, format(L["You have %s alert"], numAlerts)))
    else tt:AddLine(format(TT_LINE, format(L["You have %s alerts"], numAlerts)))
    end

    tt:AddLine(" ") -- line break
    tt:AddLine(format(TT_HINT, L["Left-Click"], L["Toggle alert frame"]))
    tt:AddLine(format(TT_HINT, L["Control+Left-Click"], L["Open options"]))
    tt:AddLine(format(TT_HINT, L["Right-Click"], L["Clear alerts"]))
    tt:AddLine(format(TT_HINT, L["Control+Right-Click"], MyChatAlert.db.profile.enabled and L["Toggle alerts off"] or L["Toggle alerts on"]))
end

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function()
    local icon = LibStub("LibDBIcon-1.0", true)
    if not icon then return end
    if icon:IsRegistered(addonName) then return end

    if not MyChatAlertLDBIconDB then
        MyChatAlertLDBIconDB = {}
        MyChatAlertLDBIconDB.hide = false
    end

    MyChatAlert:UpdateMMIcon()

    icon:Register(addonName, plugin, MyChatAlertLDBIconDB)
end)
f:RegisterEvent("PLAYER_ENTERING_WORLD")

function MyChatAlert:MinimapToggle()
    MyChatAlertLDBIconDB.hide = not MyChatAlertLDBIconDB.hide

    if MyChatAlertLDBIconDB.hide then LibStub("LibDBIcon-1.0"):Hide(addonName)
    else LibStub("LibDBIcon-1.0"):Show(addonName)
    end
end

function MyChatAlert:UpdateMMIcon()
    if not self.db then return "Interface\\AddOns\\MyChatAlert\\Media\\icon" end -- fallback if SVs aren't loaded

    plugin.icon = self.db.profile.enabled and "Interface\\AddOns\\MyChatAlert\\Media\\icon" or "Interface\\AddOns\\MyChatAlert\\Media\\icon-disabled"
end
