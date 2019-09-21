MyChatAlert.defaults = {
    profile = {
        enabled = true,
        soundOn = true,
        sound = "881",
        printOn = true,
        channels = {},
        words = {},
    }
}

local channelToDelete, wordToDelete = nil, nil -- used to store which respective table item to delete

MyChatAlert.options = {
    name = "MyChatAlert",
    handler = MyChatAlert,
    type = "group",
    args = {
        enable = {
            name = "Enable",
            desc = "Enable/disable the addon",
            type = "toggle", order = 1, width = "half",
            get = function(info) return MyChatAlert.db.profile.enabled end,
            set = function(info, val)
                MyChatAlert.db.profile.enabled = val
                if val then MyChatAlert:OnEnable()
                else MyChatAlert:OnDisable() end
            end,
        },
        sound = {
            name = "Sound",
            type = "group", inline = true, order = 2,
            args = {
                soundOn = {
                    name = "Enable",
                    desc = "Enable/disable sound alerts",
                    type = "toggle", order = 1, width = "half",
                    get = function(info) return MyChatAlert.db.profile.soundOn end,
                    set = function(info, val) MyChatAlert.db.profile.soundOn = val end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
                sound = {
                    name = "Alert Sound",
                    desc = "Sound id to play (can be browsed on Wowhead.com)",
                    type = "input", order = 2,
                    get = function(info) return MyChatAlert.db.profile.sound end,
                    set = function(info, val) if val and val ~= "" then MyChatAlert.db.profile.sound = val end end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                }
            },
        },
        printing = {
            name = "Printing",
            type = "group", inline = true, order = 3,
            args = {
                printOn = {
                    name = "Enable",
                    desc = "Enable/disable printed alerts",
                    type = "toggle", order = 1, width = "half",
                    get = function(info) return MyChatAlert.db.profile.printOn end,
                    set = function(info, val) MyChatAlert.db.profile.printOn = val end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
            },
        },
        alerts = {
            name = "Alerts",
            type = "group", inline = true, order = 4,
            args = {
                addChannel = {
                    name = "Add Channel",
                    desc = "Add a channel to watch from Ex: '4. LookingForGroup'",
                    type = "input", order = 1,
                    set = function(info, val) if val and val ~= "" then tinsert(MyChatAlert.db.profile.channels, val) end end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
                removeChannel = {
                    name = "Remove Channel",
                    desc = "Select a channel to remove from being watched",
                    type = "select", order = 2, width = 1,
                    values = function() return MyChatAlert.db.profile.channels end,
                    get = function(info) return channelToDelete end,
                    set = function(info, val) channelToDelete = val end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
                removeChannelButton = {
                    name = "Remove Channel",
                    desc = "Remove selected channel from being watched",
                    type = "execute", order = 3, width = 0.8,
                    func = function()
                        if channelToDelete then
                            tremove(MyChatAlert.db.profile.channels, channelToDelete)
                            channelToDelete = nil
                        end
                    end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
                addKeyword = {
                    name = "Add Keyword",
                    desc = "Add a keyword to watch for",
                    type = "input", order = 4,
                    set = function(info, val) if val and val ~= "" then tinsert(MyChatAlert.db.profile.words, val) end end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
                removeKeyword = {
                    name = "Remove Keyword",
                    desc = "Select a keyword to remove from being watched for",
                    type = "select", order = 5, width = 1,
                    values = function() return MyChatAlert.db.profile.words end,
                    get = function(info) return wordToDelete end,
                    set = function(info, val) wordToDelete = val end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
                removeKeywordButton = {
                    name = "Remove Keyword",
                    desc = "Remove selected keyword from being watched for",
                    type = "execute", order = 6, width = 0.8,
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
    }
}
