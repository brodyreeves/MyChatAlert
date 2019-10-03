local L = LibStub("AceLocale-3.0"):GetLocale("MyChatAlert", false)

MyChatAlert.defaults = {
    profile = {
        enabled = true,
        soundOn = true,
        sound = "881",
        printOn = true,
        channels = {},
        words = {},
        globalIgnoreListFilter = false,
    }
}

local channelToDelete, wordToDelete = nil, nil -- used to store which respective table item to delete
local availableChannels = {} -- cache available channels to quick-add

MyChatAlert.options = {
    name = L["MyChatAlert"],
    handler = MyChatAlert,
    type = "group",
    args = {
        enable = {
            name = L["Enable"],
            desc = L["Enable/disable the addon"],
            type = "toggle", order = 1, width = "half",
            get = function(info) return MyChatAlert.db.profile.enabled end,
            set = function(info, val)
                MyChatAlert.db.profile.enabled = val
                if val then MyChatAlert:OnEnable()
                else MyChatAlert:OnDisable() end
            end,
        },
        minimap = {
            name = L["Minimap"],
            desc = L["Enable/disable the minimap button"],
            type = "toggle", order = 2, width = "half",
            get = function(info) return not MyChatAlertLDBIconDB.hide end,
            set = function(info, val) MyChatAlert:MinimapToggle(val) end,
            disabled = function() return not MyChatAlert.db.profile.enabled end,
        },
        sound = {
            name = L["Sound"],
            type = "group", inline = true, order = 3,
            args = {
                soundOn = {
                    name = L["Enable"],
                    desc = L["Enable/disable sound alerts"],
                    type = "toggle", order = 1, width = "half",
                    get = function(info) return MyChatAlert.db.profile.soundOn end,
                    set = function(info, val) MyChatAlert.db.profile.soundOn = val end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
                sound = {
                    name = L["Alert Sound"],
                    desc = L["Sound id to play (can be browsed on Wowhead.com)"],
                    type = "input", order = 2,
                    get = function(info) return MyChatAlert.db.profile.sound end,
                    set = function(info, val) if val and val ~= "" then MyChatAlert.db.profile.sound = val end end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                }
            },
        },
        printing = {
            name = L["Printing"],
            type = "group", inline = true, order = 4,
            args = {
                printOn = {
                    name = L["Enable"],
                    desc = L["Enable/disable printed alerts"],
                    type = "toggle", order = 1, width = "half",
                    get = function(info) return MyChatAlert.db.profile.printOn end,
                    set = function(info, val) MyChatAlert.db.profile.printOn = val end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
            },
        },
        channels = {
            name = L["Channels"],
            type = "group", inline = true, order = 5,
            args = {
                pickChannel = {
                    name = L["Select New Channel"],
                    desc = L["Select a channel to watch"],
                    type = "select", order = 1, width = 1,
                    values = function()
                        availableChannels = {} -- flush for recreation
                        for i = 1, NUM_CHAT_WINDOWS do
                            local num, name = GetChannelName(i)
                            if num > 0 then -- number channel, e.g. 2. Trade - City
                                local channel = num .. ". " .. name
                                tinsert(availableChannels, channel)
                            else
                                tinsert(availableChannels, name)
                            end
                        end
                        return availableChannels
                    end,
                    set = function(info, val) tinsert(MyChatAlert.db.profile.channels, availableChannels[val]) end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
                removeChannel = {
                    name = L["Remove Channel"],
                    desc = L["Select a channel to remove from being watched"],
                    type = "select", order = 2, width = 1,
                    values = function() return MyChatAlert.db.profile.channels end,
                    get = function(info) return channelToDelete end,
                    set = function(info, val) channelToDelete = val end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
                removeChannelButton = {
                    name = L["Remove Channel"],
                    desc = L["Remove selected channel from being watched"],
                    type = "execute", order = 3, width = 0.8,
                    func = function()
                        if channelToDelete then
                            tremove(MyChatAlert.db.profile.channels, channelToDelete)
                            channelToDelete = nil
                        end
                    end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
                addChannel = {
                    name = L["Add Channel"],
                    desc = L["Add a channel to watch from Ex: '4. LookingForGroup'"],
                    type = "input", order = 4,
                    set = function(info, val) if val and val ~= "" then tinsert(MyChatAlert.db.profile.channels, val) end end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
            },
        },
        keywords = {
            name = L["Keywords"],
            type = "group", inline = true, order = 6,
            args = {
                addKeyword = {
                    name = L["Add Keyword"],
                    desc = L["Add a keyword to watch for"],
                    type = "input", order = 5,
                    set = function(info, val) if val and val ~= "" then tinsert(MyChatAlert.db.profile.words, val) end end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
                removeKeyword = {
                    name = L["Remove Keyword"],
                    desc = L["Select a keyword to remove from being watched for"],
                    type = "select", order = 6, width = 1,
                    values = function() return MyChatAlert.db.profile.words end,
                    get = function(info) return wordToDelete end,
                    set = function(info, val) wordToDelete = val end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
                removeKeywordButton = {
                    name = L["Remove Keyword"],
                    desc = L["Remove selected keyword from being watched for"],
                    type = "execute", order = 7, width = 0.8,
                    func = function()
                        if wordToDelete then
                            tremove(MyChatAlert.db.profile.words, wordToDelete)
                            wordToDelete = nil
                        end
                    end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
            },
        },
        miscOptions = {
            name = L["Misc Options"],
            type = "group", inline = true, order = 7,
            args = {
                globalIgnoreListFilter = {
                    name = L["Filter with GlobalIgnoreList"],
                    desc = L["Ignore messages from players on your ignore list"],
                    type = "toggle", order = 1, width = 1.15,
                    get = function(info) return MyChatAlert.db.profile.globalIgnoreListFilter end,
                    set = function(info, val) MyChatAlert.db.profile.globalIgnoreListFilter = val end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
            },
        },
    },
}
