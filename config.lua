local L = LibStub("AceLocale-3.0"):GetLocale("MyChatAlert", false)

MyChatAlert.defaults = {
    profile = {
        enabled = true,
        soundOn = true,
        sound = "881",
        printOn = true,
        printOutput = "DEFAULT_CHAT_FRAME",
        triggers = {},
        filterWords = {},
        ignoredAuthors = {},
        dedupTime = 0,
        globalIgnoreListFilter = false,
    }
}

MyChatAlert.outputFrames = {
    [1] = {readable = L["Default Chat Frame"], frame = "DEFAULT_CHAT_FRAME"},
    [2] = {readable = L["Error Frame"], frame = "UIErrorsFrame"},
    [3] = {readable = format(L["Chat Frame %i"], 1), frame = "ChatFrame1"},
    [4] = {readable = format(L["Chat Frame %i"], 2), frame = "ChatFrame2"},
    [5] = {readable = format(L["Chat Frame %i"], 3), frame = "ChatFrame3"},
    [6] = {readable = format(L["Chat Frame %i"], 4), frame = "ChatFrame4"},
    [7] = {readable = format(L["Chat Frame %i"], 5), frame = "ChatFrame5"},
    [8] = {readable = format(L["Chat Frame %i"], 6), frame = "ChatFrame6"},
    [9] = {readable = format(L["Chat Frame %i"], 7), frame = "ChatFrame7"},
    [10] = {readable = format(L["Chat Frame %i"], 8), frame = "ChatFrame8"},
    [11] = {readable = format(L["Chat Frame %i"], 9), frame = "ChatFrame9"},
    [12] = {readable = format(L["Chat Frame %i"], 10), frame = "ChatFrame10"},
}

local channelToDelete, selectedChannel, wordToDelete, filterToDelete, authorToDelete = nil, nil, nil, nil, nil
local availableChannels = {} -- cache available channels for quick-add
local addedChannels = {} -- cache added channels for removal
local addedWords = {} -- cache added words for removal
local addedFilters = {} -- cache added filters for removal
local addedAuthors = {} -- cache added authors for removal

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
                else MyChatAlert:OnDisable()
                end
            end,
        },
        inInstance = {
            name = L["Disable in instance"],
            desc = L["Disable alerts while in an instance"],
            type = "toggle", order = 2, width = 0.85,
            get = function(info) return MyChatAlert.db.profile.disableInInstance end,
            set = function(info, val)
                MyChatAlert.db.profile.disableInInstance = val
                if val then
                    MyChatAlert:UnregisterEvent("ZONE_CHANGED")
                    MyChatAlert:UnregisterEvent("ZONE_CHANGED_INDOORS")
                    MyChatAlert:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
                else
                    MyChatAlert:RegisterEvent("ZONE_CHANGED")
                    MyChatAlert:RegisterEvent("ZONE_CHANGED_INDOORS")
                    MyChatAlert:RegisterEvent("ZONE_CHANGED_NEW_AREA")
                end
            end,
            disabled = function() return not MyChatAlert.db.profile.enabled end,
        },
        minimap = {
            name = L["Minimap"],
            desc = L["Enable/disable the minimap button"],
            type = "toggle", order = 2, width = "half",
            get = function(info) return not MyChatAlertLDBIconDB.hide end,
            set = function(info, val) MyChatAlert:MinimapToggle() end,
            disabled = function() return not MyChatAlert.db.profile.enabled end,
        },
        dedup = {
            name = L["Time to wait"],
            desc = L["Amount of time to ignore duplicate messages for, in seconds (0 to disable)"],
            type = "input", order = 3, width = 0.4,
            get = function(info) return "" .. MyChatAlert.db.profile.dedupTime end,
            set = function(info, val) if tonumber(val) ~= nil then MyChatAlert.db.profile.dedupTime = tonumber(val) end end,
            disabled = function() return not MyChatAlert.db.profile.enabled end,
        },
        sound = {
            name = L["Sound"],
            type = "group", inline = true, order = 4,
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
                    type = "input", order = 2, width = 0.4,
                    get = function(info) return MyChatAlert.db.profile.sound end,
                    set = function(info, val) if tonumber(val) ~= nil then MyChatAlert.db.profile.sound = val end end,
                    disabled = function() return not MyChatAlert.db.profile.enabled or not MyChatAlert.db.profile.soundOn end,
                }
            },
        },
        printing = {
            name = L["Printing"],
            type = "group", inline = true, order = 5,
            args = {
                printOn = {
                    name = L["Enable"],
                    desc = L["Enable/disable printed alerts"],
                    type = "toggle", order = 1, width = "half",
                    get = function(info) return MyChatAlert.db.profile.printOn end,
                    set = function(info, val) MyChatAlert.db.profile.printOn = val end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
                printOutput = {
                    name = L["Destination"],
                    desc = L["Where to output printed alerts"],
                    type = "select", order = 2, width = 1,
                    values = function()
                        local availableOutputs = {}

                        for k, option in pairs(MyChatAlert.outputFrames) do
                            availableOutputs[k] = option.readable
                        end

                        return availableOutputs
                    end,
                    get = function(info) return MyChatAlert.db.profile.printOutput end,
                    set = function(info, val) MyChatAlert.db.profile.printOutput = val end,
                    disabled = function() return not MyChatAlert.db.profile.enabled or not MyChatAlert.db.profile.printOn end,
                },
            },
        },
        channels = {
            name = L["Channels"],
            type = "group", inline = true, order = 6,
            args = {
                pickChannel = {
                    name = L["Select New Channel"],
                    desc = L["Select a channel to watch"],
                    type = "select", order = 1, width = 1,
                    values = function()
                        availableChannels = {} -- flush for recreation

                        availableChannels[#availableChannels + 1] = L["MyChatAlert Global Keywords"]

                        for i = 1, NUM_CHAT_WINDOWS do
                            local num, name = GetChannelName(i)
                            if num > 0 then -- number channel, e.g. 2. Trade - City
                                local channel = num .. L["Number delimiter"] .. " " .. name
                                availableChannels[#availableChannels + 1] = channel
                            else
                                availableChannels[#availableChannels + 1] = name
                            end
                        end

                        -- standard, non-numbered channels
                        -- TODO: check if these are the actual channel names
                        availableChannels[#availableChannels + 1] = L["Guild"]
                        --availableChannels[#availableChannels + 1] = L["Loot"]
                        availableChannels[#availableChannels + 1] = L["Officer"]
                        availableChannels[#availableChannels + 1] = L["Party"]
                        availableChannels[#availableChannels + 1] = L["Party Leader"]
                        availableChannels[#availableChannels + 1] = L["Raid"]
                        availableChannels[#availableChannels + 1] = L["Raid Leader"]
                        availableChannels[#availableChannels + 1] = L["Raid Warning"]
                        availableChannels[#availableChannels + 1] = L["Say"]
                        --availableChannels[#availableChannels + 1] = L["System"]
                        availableChannels[#availableChannels + 1] = L["Yell"]

                        return availableChannels
                    end,
                    set = function(info, val)
                        if not MyChatAlert.db.profile.triggers[availableChannels[val]] then -- only add if not already added
                            MyChatAlert.db.profile.triggers[availableChannels[val]] = {}
                            MyChatAlert.db.profile.filterWords[availableChannels[val]] = {}
                            if MyChatAlert.eventMap[availableChannels[val]] then -- channel is mapped to an event
                                MyChatAlert:RegisterEvent(MyChatAlert.eventMap[availableChannels[val]])
                            else
                                MyChatAlert:RegisterEvent("CHAT_MSG_CHANNEL")
                            end
                        end
                    end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
                removeChannel = {
                    name = L["Remove Channel"],
                    desc = L["Select a channel to remove from being watched"],
                    type = "select", order = 2, width = 1,
                    values = function()
                        addedChannels = {}
                        for chan, _ in pairs(MyChatAlert.db.profile.triggers) do addedChannels[#addedChannels + 1] = chan end
                        return addedChannels
                    end,
                    get = function(info) return channelToDelete end,
                    set = function(info, val) channelToDelete = val end,
                    disabled = function() return not MyChatAlert.db.profile.enabled or not MyChatAlert.db.profile.triggers or next(MyChatAlert.db.profile.triggers) == nil end,
                },
                removeChannelButton = {
                    name = L["Remove Channel"],
                    desc = L["Remove selected channel from being watched"],
                    type = "execute", order = 3, width = 0.8,
                    func = function()
                        if not channelToDelete then return end

                        MyChatAlert:UnregisterEvent(addedChannels[channelToDelete])

                        MyChatAlert.db.profile.triggers[addedChannels[channelToDelete]] = nil
                        MyChatAlert.db.profile.filterWords[addedChannels[channelToDelete]] = nil
                        tremove(addedChannels, channelToDelete)

                        if selectedChannel and selectedChannel >= channelToDelete then -- messes up index accessing
                            selectedChannel = nil
                            wordToDelete = nil
                        end
                        channelToDelete = nil
                    end,
                    disabled = function() return not MyChatAlert.db.profile.enabled or not channelToDelete end,
                },
                addChannel = {
                    name = L["Add Channel"],
                    desc = L["Add a channel to watch from Ex: '4. LookingForGroup'"],
                    type = "input", order = 4,
                    set = function(info, val)
                        if val ~= "" and not MyChatAlert.db.profile.triggers[val] then
                            MyChatAlert.db.profile.triggers[val] = {}
                            MyChatAlert.db.profile.filterWords[availableChannels[val]] = {}
                        end
                    end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
            },
        },
        keywords = {
            name = L["Keywords"],
            type = "group", inline = true, order = 7,
            args = {
                selectChannel = {
                    name = L["Select Channel"],
                    desc = L["Select a channel to add keywords to"],
                    type = "select", order = 1, width = 1,
                    values = function()
                        addedChannels = {}
                        for chan, _ in pairs(MyChatAlert.db.profile.triggers) do addedChannels[#addedChannels + 1] = chan end
                        return addedChannels
                    end,
                    get = function(info) return selectedChannel end,
                    set = function(info, val) selectedChannel = val end,
                    disabled = function() return not MyChatAlert.db.profile.enabled or not MyChatAlert.db.profile.triggers or next(MyChatAlert.db.profile.triggers) == nil end,
                },
                addKeyword = {
                    name = L["Add Keyword"],
                    desc = L["Add a keyword to watch for"],
                    type = "input", order = 2, width = 0.5,
                    set = function(info, val) if val ~= "" then tinsert(MyChatAlert.db.profile.triggers[addedChannels[selectedChannel]], val) end end,
                    disabled = function() return not MyChatAlert.db.profile.enabled or not selectedChannel end,
                },
                removeKeyword = {
                    name = L["Remove Keyword"],
                    desc = L["Select a keyword to remove from being watched for"],
                    type = "select", order = 3, width = 1, width = 0.6,
                    values = function()
                        addedWords = {}
                        if selectedChannel and MyChatAlert.db.profile.triggers[addedChannels[selectedChannel]] and #MyChatAlert.db.profile.triggers[addedChannels[selectedChannel]] > 0 then
                            for _, word in pairs(MyChatAlert.db.profile.triggers[addedChannels[selectedChannel]]) do tinsert(addedWords, word) end
                        end
                        return addedWords
                    end,
                    get = function(info) return wordToDelete end,
                    set = function(info, val) wordToDelete = val end,
                    disabled = function() return not MyChatAlert.db.profile.enabled or not selectedChannel or not MyChatAlert.db.profile.triggers[addedChannels[selectedChannel]] or next(MyChatAlert.db.profile.triggers[addedChannels[selectedChannel]]) == nil end,
                },
                removeKeywordButton = {
                    name = L["Remove Keyword"],
                    desc = L["Remove selected keyword from being watched for"],
                    type = "execute", order = 4, width = 0.8,
                    func = function()
                        if wordToDelete then
                            tremove(MyChatAlert.db.profile.triggers[addedChannels[selectedChannel]], wordToDelete)
                            tremove(addedWords, wordToDelete)
                            wordToDelete = nil
                        end
                    end,
                    disabled = function() return not MyChatAlert.db.profile.enabled or not selectedChannel or not wordToDelete end,
                },
            },
        },
        filterWords = {
            name = L["Filter Words"],
            type = "group", inline = true, order = 8,
            args = {
                selectChannel = {
                    name = L["Select Channel"],
                    desc = L["Select a channel to add filters to"],
                    type = "select", order = 1, width = 1,
                    values = function()
                        addedChannels = {}
                        for chan, _ in pairs(MyChatAlert.db.profile.triggers) do addedChannels[#addedChannels + 1] = chan end
                        return addedChannels
                    end,
                    get = function(info) return selectedChannel end,
                    set = function(info, val) selectedChannel = val end,
                    disabled = function() return not MyChatAlert.db.profile.enabled or not MyChatAlert.db.profile.triggers or next(MyChatAlert.db.profile.triggers) == nil end,
                },
                addFilter = {
                    name = L["Add Filter"],
                    desc = L["Add a word to filter out"],
                    type = "input", order = 2, width = 0.5,
                    set = function(info, val)
                        if val ~= "" then
                            if not MyChatAlert.db.profile.filterWords[addedChannels[selectedChannel]] then
                                MyChatAlert.db.profile.filterWords[addedChannels[selectedChannel]] = {} end
                            tinsert(MyChatAlert.db.profile.filterWords[addedChannels[selectedChannel]], val)
                        end
                    end,
                    disabled = function() return not MyChatAlert.db.profile.enabled or not selectedChannel end,
                },
                removeFilter = {
                    name = L["Remove Filter"],
                    desc = L["Select a keyword to remove from being filtered"],
                    type = "select", order = 3, width = 1, width = 0.6,
                    values = function()
                        addedFilters = {}
                        if selectedChannel and MyChatAlert.db.profile.filterWords and MyChatAlert.db.profile.filterWords[addedChannels[selectedChannel]] and next(MyChatAlert.db.profile.filterWords[addedChannels[selectedChannel]]) ~= nil then
                            for _, word in pairs(MyChatAlert.db.profile.filterWords[addedChannels[selectedChannel]]) do tinsert(addedFilters, word) end
                        end
                        return addedFilters
                    end,
                    get = function(info) return filterToDelete end,
                    set = function(info, val) filterToDelete = val end,
                    disabled = function() return not MyChatAlert.db.profile.enabled or not selectedChannel or not MyChatAlert.db.profile.filterWords or not MyChatAlert.db.profile.filterWords[addedChannels[selectedChannel]] or next(MyChatAlert.db.profile.filterWords[addedChannels[selectedChannel]]) == nil end,
                },
                removeFilterButton = {
                    name = L["Remove Filter"],
                    desc = L["Remove selected keyword from being filtered"],
                    type = "execute", order = 4, width = 0.8,
                    func = function()
                        if filterToDelete then
                            tremove(MyChatAlert.db.profile.filterWords[addedChannels[selectedChannel]], filterToDelete)
                            tremove(addedFilters, filterToDelete)
                            filterToDelete = nil
                        end
                    end,
                    disabled = function() return not MyChatAlert.db.profile.enabled or not selectedChannel or not filterToDelete end,
                },
            },
        },
        ignoreAuthor = {
            name = L["Ignore Authors"],
            type = "group", inline = true, order = 9,
            args = {
                addName = {
                    name = L["Add Name"],
                    desc = L["Add a name to ignore"],
                    type = "input", order = 1, width = 0.5,
                    set = function(info, val) if val ~= "" then tinsert(MyChatAlert.db.profile.ignoredAuthors, val) end end,
                    disabled = function() return not MyChatAlert.db.profile.enabled end,
                },
                removeName = {
                    name = L["Remove Name"],
                    desc = L["Select a name to remove from being ignored"],
                    type = "select", order = 2, width = 0.6,
                    values = function()
                        addedAuthors = {}
                        for _, name in pairs(MyChatAlert.db.profile.ignoredAuthors) do tinsert(addedAuthors, name) end
                        return addedAuthors
                    end,
                    get = function(info) return authorToDelete end,
                    set = function(info, val) authorToDelete = val end,
                    disabled = function() return not MyChatAlert.db.profile.enabled or not MyChatAlert.db.profile.ignoredAuthors or next(MyChatAlert.db.profile.ignoredAuthors) == nil end,
                },
                removeNameButton = {
                    name = L["Remove Name"],
                    desc = L["Remove selected name from being ignored"],
                    type = "execute", order = 3, width = 0.8,
                    func = function()
                        if authorToDelete then
                            tremove(MyChatAlert.db.profile.ignoredAuthors, authorToDelete)
                            tremove(addedAuthors, authorToDelete)
                            authorToDelete = nil
                        end
                    end,
                    disabled = function() return not MyChatAlert.db.profile.enabled or not authorToDelete end,
                },
            },
        },
        miscOptions = {
            name = L["Misc Options"],
            type = "group", inline = true, order = 99,
            args = {
                globalIgnoreListFilter = {
                    -- FIXME: filter currently not working
                    name = L["Filter with GlobalIgnoreList"],
                    desc = L["Ignore messages from players on your ignore list"],
                    type = "toggle", order = 1, width = 1.15,
                    get = function(info) return MyChatAlert.db.profile.globalIgnoreListFilter end,
                    set = function(info, val) MyChatAlert.db.profile.globalIgnoreListFilter = val end,
                    --disabled = function() return not MyChatAlert.db.profile.enabled end,
                    disabled = true,
                },
            },
        },
    },
}
