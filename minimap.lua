local addonName, addon = ...

local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true)
if not ldb then return end

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
        MyChatAlert:ShowDisplay()
    else -- RightButton
        if IsControlKeyDown() then
            InterfaceOptionsFrame_OpenToCategory(addonName)
            InterfaceOptionsFrame_OpenToCategory(addonName) -- needs two calls
        else
            MyChatAlert:ClearAlerts()
        end
    end
end
function plugin.OnTooltipShow(tt)
    tt:AddLine(format(TT_HEAD, addonName))

    if #MyChatAlert.alerts == 0 then tt:AddLine(format(TT_LINE, "You have no alerts"))
    elseif #MyChatAlert.alerts == 1 then tt:AddLine(format(TT_LINE, "You have |cFF00FF00" .. #MyChatAlert.alerts .. "|cFFCFCFCF alert"))
    else tt:AddLine(format(TT_LINE, "You have |cFF00FF00" .. #MyChatAlert.alerts .. "|cFFCFCFCF alerts")) end

    tt:AddLine(" ") -- line break
    tt:AddLine(format(TT_HINT, "Left-Click", "Show alert frame"))
    tt:AddLine(format(TT_HINT, "Right-Click", "Clear alerts"))
    tt:AddLine(format(TT_HINT, "Control+Right-Click", "Open options"))
end

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function()
    local icon = LibStub("LibDBIcon-1.0", true)
    if not icon then return end
    if not MyChatAlertLDBIconDB then
        MyChatAlertLDBIconDB = {}
        MyChatAlertLDBIconDB.hide = false
    end
    icon:Register(addonName, plugin, MyChatAlertLDBIconDB)
end)
f:RegisterEvent("PLAYER_LOGIN")

function MyChatAlert:MinimapToggle(val)
    MyChatAlertLDBIconDB.hide = not val
    if MyChatAlertLDBIconDB.hide then
        LibStub("LibDBIcon-1.0"):Hide(addonName)
    else
        LibStub("LibDBIcon-1.0"):Show(addonName)
    end
end
