local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local DT = E:GetModule('DataTexts')

-- Lua functions
local _G = _G
local format, ipairs, next, pairs, select, sort, type = format, ipairs, next, pairs, select, sort, type

-- WoW API / Variables
local C_Covenants_GetActiveCovenantID = C_Covenants.GetActiveCovenantID
local C_Covenants_GetCovenantData = C_Covenants.GetCovenantData
local C_Soulbinds_ActivateSoulbind = C_Soulbinds.ActivateSoulbind
local C_Soulbinds_GetActiveSoulbindID = C_Soulbinds.GetActiveSoulbindID
local C_Soulbinds_GetConduitCollectionData = C_Soulbinds.GetConduitCollectionData
local C_Soulbinds_GetNode = C_Soulbinds.GetNode
local C_Soulbinds_GetSoulbindData = C_Soulbinds.GetSoulbindData
local C_Soulbinds_SelectNode = C_Soulbinds.SelectNode
local GetItemInfo = GetItemInfo
local GetPlayerAuraBySpellID = GetPlayerAuraBySpellID
local GetSpellInfo = GetSpellInfo
local GetTalentInfo = GetTalentInfo
local GetTalentTierInfo = GetTalentTierInfo
local InCombatLockdown = InCombatLockdown
local IsInInstance = IsInInstance
local IsResting = IsResting
local LearnTalent = LearnTalent

local Enum_SoulbindNodeState_Selected = Enum.SoulbindNodeState.Selected
local Enum_SoulbindNodeState_Unselected = Enum.SoulbindNodeState.Unselected

local CONDUIT_POTENCY = CONDUIT_POTENCY
local CONDUIT_FINESSE = CONDUIT_FINESSE
local CONDUIT_ENDURANCE = CONDUIT_ENDURANCE
local COVENANT_PREVIEW_SOULBINDS = COVENANT_PREVIEW_SOULBINDS
local DEFAULT = DEFAULT
local MAX_TALENT_TIERS = MAX_TALENT_TIERS
local TALENTS = TALENTS
local TALENT_TOOLTIP_ADD_COMBAT_ERROR = TALENT_TOOLTIP_ADD_COMBAT_ERROR
local TALENT_TOOLTIP_ADD_REST_ERROR = TALENT_TOOLTIP_ADD_REST_ERROR
local UNKNOWN = UNKNOWN
local UNUSED = UNUSED

local set = {
    ['DRUID'] = {
        -- Balance
        [1] = {
            Profiles = {
                [1] = {
                    name = "AoE：自然平衡",
                    talent = {1, 0, 0, 0, 1, 2, 2},
                    soulbind = 1,
                    conduit = {
                        [1] = {279, 264},
                    },
                    node = {859},
                },
                [2] = {
                    name = "AoE：自然之力",
                    talent = {3, 0, 0, 0, 1, 2, 2},
                    soulbind = 1,
                    conduit = {
                        [1] = {279, 264},
                    },
                    node = {859},
                },
                [3] = {
                    name = "团本单体：耀斑",
                    talent = {1, 0, 0, 0, 3, 3, 2},
                    soulbind = 1,
                    conduit = {
                        [1] = {279},
                    },
                    node = {858},
                },
                [4] = {
                    name = "团本AoE：漂流",
                    talent = {1, 0, 0, 0, 3, 2, 2},
                    soulbind = 1,
                    conduit = {
                        [1] = {279},
                    },
                    node = {858},
                },
            },
            Checks = {
                ['party'] = {1, 2},
                ['raid'] = {3, 4},
            },
        },
        -- Restoration
        [4] = {
            Profiles = {
                [1] = {
                    name = "结界/野心/丛林之魂",
                    talent = {3, 0, 1, 3, 1, 2, 3},
                    soulbind = 2,
                    conduit = {
                        [1] = {279, 273},
                    },
                },
                [2] = {
                    name = "结界/群缠/丛林之魂",
                    talent = {3, 0, 1, 2, 1, 2, 3},
                    soulbind = 2,
                    conduit = {
                        [1] = {279, 273},
                    },
                },
                [3] = {
                    name = "丰饶/野心/丛林之魂",
                    talent = {1, 0, 1, 3, 1, 2, 3},
                    soulbind = 2,
                    conduit = {
                        [1] = {279, 273},
                    },
                },
                [4] = {
                    name = "丰饶/野心/化身",
                    talent = {1, 0, 1, 3, 3, 2, 3},
                    soulbind = 2,
                    conduit = {
                        [1] = {279, 273},
                    },
                },
            },
            Checks = {
                ['party'] = {1, 2},
                ['raid'] = {3, 4},
            },
        },
    },
    ['DEMONHUNTER'] = {
        -- Havoc
        [1] = {
            Profiles = {
                [1] = {
                    name = "盲目之怒/魔化/尼娅",
                    talent = {1, 1, 2, 0, 1, 0, 1},
                    soulbind = 1,
                },
                [2] = {
                    name = "盲目之怒/魔化/柯莱恩",
                    talent = {1, 1, 2, 0, 1, 0, 1},
                    soulbind = 6,
                },
                [3] = {
                    name = "邪刃/势如破竹/尼娅",
                    talent = {3, 3, 2, 3, 3, 2, 2},
                    soulbind = 1,
                },
                [4] = {
                    name = "邪刃/势如破竹/柯莱恩",
                    talent = {3, 3, 2, 3, 3, 2, 2},
                    soulbind = 6,
                },
            },
            Checks = {
                ['party'] = {1, 2},
                ['raid'] = 1,
            },
        },
        -- Vengeance
        [2] = {
            Profiles = {
                [1] = {
                    name = "幽魂炸弹/尼娅",
                    talent = {2, 2, 3, 3, 3, 2, 1},
                    soulbind = 1,
                },
                [2] = {
                    name = "火刑/尼娅",
                    talent = {2, 3, 2, 3, 3, 2, 1},
                    soulbind = 1,
                },
                [3] = {
                    name = "幽魂炸弹/柯莱恩",
                    talent = {2, 2, 3, 3, 3, 2, 1},
                    soulbind = 6,
                },
                [4] = {
                    name = "火刑/柯莱恩",
                    talent = {2, 3, 2, 3, 3, 2, 1},
                    soulbind = 6,
                },
            },
            Checks = {
                ['party'] = {1, 2, 3, 4},
                ['raid'] = 2,
            },
        },
    },
    ['MAGE'] = {
        -- Fire
        [2] = {
            Profiles = {
                [1] = {
                    name = "烈焰之地/织梦者",
                    talent = {3, 0, 3, 1, 0, 1, 1},
                    soulbind = 2,
                    conduit = {
                        [1] = {30, 38},
                    },
                },
                [2] = {
                    name = "洪荒烈火/织梦者",
                    talent = {3, 0, 3, 1, 0, 2, 1},
                    soulbind = 2,
                    conduit = {
                        [1] = {30, 38},
                    },
                },
                [3] = {
                    name = "烈焰之地/柯莱恩",
                    talent = {3, 0, 3, 1, 0, 1, 1},
                    soulbind = 6,
                    conduit = {
                        [1] = {30, 38},
                    },
                },
                [4] = {
                    name = "洪荒烈火/柯莱恩",
                    talent = {3, 0, 3, 1, 0, 2, 1},
                    soulbind = 6,
                    conduit = {
                        [1] = {30, 38},
                    },
                },
            },
            Checks = {
                ['party'] = {1, 3},
                ['raid'] = {2, 4},
            },
        },
    },
    ['DEATHKNIGHT'] = {
        -- Blood
        [1] = {
            Profiles = {
                [1] = {
                    name = "鲜血禁闭/白骨风暴",
                    talent = {1, 2, 3, 1, 1, 1, 3},
                    soulbind = 3,
                },
                [2] = {
                    name = "鲜血禁闭/赤红渴望",
                    talent = {1, 2, 3, 1, 1, 1, 2},
                    soulbind = 3,
                },
            },
            Checks = {
                ['party'] = 1,
                ['raid'] = 2,
            },
        },
    },
    ['PALADIN'] = {
        -- Holy
        [1] = {
            Profiles = {
                [1] = {
                    name = "美德道标",
                    talent = {1, 2, 0, 1, 1, 3, 3},
                    soulbind = 18,
                },
            },
            Checks = {
                ['party'] = 1,
            },
        },
        -- Retribution
        [3] = {
            Profiles = {
                [1] = {
                    name = "入门级",
                    talent = {1, 2, 0, 0, 1, 0, 1},
                    soulbind = 7,
                },
            },
        },
    },
}
local classSet = set[E.myclass]
local currentSet, currentProfile, checkFailed, displayName
local activeSpec = GetActiveSpecGroup()

local canChangeTalentBuffs = {
    -- Tome and Codex
    -- Warlords of Draenor
    [226234] = true, -- Codex of the Tranquil Mind
    [227041] = true, -- Tome of the Tranquil Mind
    -- Legion
    [227563] = true, -- Tome of the Clear Mind
    [227565] = true, -- Codex of the Clear Mind
    -- Battle for Azeroth
    [256229] = true, -- Codex of the Quiet Mind
    [256231] = true, -- Tome of the Quiet Mind
    -- Shadowlands
    [321923] = true, -- Tome of the Still Mind
    [324028] = true, -- Codex of the Still Mind

    -- Preparation
    [32727]  = true, -- Arena Preparation
    [44521]  = true, -- Preparation
    [228128] = true, -- Dungeon Preparation
    [234415] = true, -- Allow Talent Swapping
    [248473] = true, -- Battleground Insight
    [279737] = true, -- Prepare for Battle! (Island Preparation) (Debuff)
    [325012] = true, -- Time to Reflect
}

local conduitTypes = {
    1, -- Potency
    0, -- Finesse
    2, -- Endurance
}

local function AddTexture(texture)
    texture = texture and '|T'..texture..':16:16:0:0:50:50:4:46:4:46|t' or ''
    return texture
end

local function profileDistance(index)
    local profile = currentSet and currentSet.Profiles and currentSet.Profiles[index]
    if not profile then return end

    local distance = 0

    if profile.talent then
        for i = 1, MAX_TALENT_TIERS do
            if profile.talent[i] ~= 0 and profile.talent[i] ~= select(2, GetTalentTierInfo(i, activeSpec)) then
                distance = distance + 10
            end
        end
    end

    local soulbindID = (profile.soulbind or profile.conduit or profile.node) and C_Soulbinds_GetActiveSoulbindID()
    local soulbindData = (profile.conduit or profile.node) and C_Soulbinds_GetSoulbindData(soulbindID)

    if profile.soulbind then
        if soulbindID ~= profile.soulbind then
            distance = distance + 1
        end
    end

    if profile.conduit then
        local required = {}
        for _, conduitType in ipairs(conduitTypes) do
            if profile.conduit[conduitType] then
                for _, conduitID in ipairs(profile.conduit[conduitType]) do
                    required[conduitID] = true
                end
            end
        end

        if soulbindData and soulbindData.tree and soulbindData.tree.nodes then
            for _, node in ipairs(soulbindData.tree.nodes) do
                if node.conduitID ~= 0 and node.state == Enum_SoulbindNodeState_Selected then
                    required[node.conduitID] = nil
                end
            end
        end

        for _ in pairs(required) do
            distance = distance + 1
        end
    end

    if profile.node then
        local required = {}
        for _, nodeID in ipairs(profile.node) do
            required[nodeID] = false
        end

        if soulbindData and soulbindData.tree and soulbindData.tree.nodes then
            for _, node in ipairs(soulbindData.tree.nodes) do
                if type(required[node.ID]) == 'boolean' then
                    if node.state == Enum_SoulbindNodeState_Selected then
                        required[node.ID] = nil
                    elseif node.state == Enum_SoulbindNodeState_Unselected then
                        required[node.ID] = true
                    end
                end
            end
        end

        -- status in table `required`
        -- true:  available and not selected
        -- false: not available (not in active soulbind or not enough Renown or not active yet)
        -- nil:   selected or not required

        for _, status in pairs(required) do
            if status == true then
                distance = distance + 1
            end
        end
    end

    return distance
end

local function apply(index)
    local profile = currentSet and currentSet.Profiles and currentSet.Profiles[index]
    if not profile then return end

    if profile.talent then
        for tier, column in ipairs(profile.talent) do
            if column ~= 0 then
                local talentID, _, _, selected = GetTalentInfo(tier, column, activeSpec)
                if not selected then
                    LearnTalent(talentID)
                end
            end
        end
    end

    if profile.soulbind then
        C_Soulbinds_ActivateSoulbind(profile.soulbind)
    end

    if profile.node then
        for _, nodeID in ipairs(profile.node) do
            C_Soulbinds_SelectNode(nodeID)
        end
    end
end

local profileList = {}
if classSet then
    local menuOnClick = function(_, arg1)
        apply(arg1)
    end
    for specID, specSet in pairs(classSet) do
        if specSet.Profiles then
            local profiles = {
                { text = TALENTS, isTitle = true, notCheckable = true },
            }
            for index, profile in ipairs(specSet.Profiles) do
                local rowProfile = profile
                tinsert(profiles, {
                    text = profile.name, arg1 = index, func = menuOnClick,
                    checked = function()
                        return not checkFailed and rowProfile == currentProfile
                    end
                })
            end
            profileList[specID] = profiles
        end
    end
end

local function OnEnter(self)
    DT:SetupTooltip(self)

    DT.tooltip:AddLine(format("|cffFFFFFF%s:|r %s", "当前配置", displayName))

    DT.tooltip:AddLine(' ')
    DT.tooltip:AddLine(TALENTS, 0.69, 0.31, 0.31)
    for i = 1, _G.MAX_TALENT_TIERS do
        local unlock, column = GetTalentTierInfo(i, activeSpec)
        if not unlock then break end

        local _, name, icon = GetTalentInfo(i, column, activeSpec)
        if currentProfile and currentProfile.talent and currentProfile.talent[i] ~= 0 then
            -- fixed
            if column == currentProfile.talent[i] then
                -- matched
                DT.tooltip:AddLine(AddTexture(icon or 134400) .. ' ' .. (name or UNUSED))
            else
                -- not matched
                local _, targetName, targetIcon = GetTalentInfo(i, currentProfile.talent[i], activeSpec)
                DT.tooltip:AddLine(
                    AddTexture(icon or 134400) .. ' |cffff5100' .. (name or UNUSED) .. '|r (' ..
                    AddTexture(targetIcon) .. ' ' .. targetName .. ')'
                )
            end
        else
            -- not fixed
            DT.tooltip:AddLine(AddTexture(icon or 134400) .. ' |cff606060' .. (name or UNUSED) .. '|r')
        end
    end

    local covenantID = C_Covenants_GetActiveCovenantID()
    local covenantData = covenantID and C_Covenants_GetCovenantData(covenantID)
    if covenantData then
        DT.tooltip:AddLine(' ')
        DT.tooltip:AddLine(COVENANT_PREVIEW_SOULBINDS, 0.69, 0.31, 0.31)

        local soulbindID = C_Soulbinds_GetActiveSoulbindID()
        local soulbindData = soulbindID and C_Soulbinds_GetSoulbindData(soulbindID)
        if soulbindData then
            local covenantIcon = AddTexture('Interface/Icons/Ui_Sigil_' .. covenantData.textureKit)
            if currentProfile and currentProfile.soulbind then
                -- fixed
                if soulbindID == currentProfile.soulbind then
                    -- matched
                    DT.tooltip:AddLine(covenantIcon .. ' ' .. soulbindData.name)
                else
                    -- not matched
                    local targetSoulbindData = C_Soulbinds_GetSoulbindData(currentProfile.soulbind)
                    DT.tooltip:AddLine(
                        covenantIcon .. ' |cffff5100' .. targetSoulbindData.name .. '|r (' ..
                        covenantIcon .. ' ' .. soulbindData.name .. ')'
                    )
                end
            else
                -- not fixed
                DT.tooltip:AddLine(covenantIcon .. ' |cff606060' .. soulbindData.name .. '|r')
            end
        end

        if soulbindData then
            local required = {}
            local selected = {}
            local pending = {}

            for _, conduitType in ipairs(conduitTypes) do
                required[conduitType] = {}
                selected[conduitType] = {}
                pending[conduitType] = {}
            end

            if currentProfile and currentProfile.conduit then
                for _, conduitType in ipairs(conduitTypes) do
                    if currentProfile.conduit[conduitType] then
                        for _, conduitID in ipairs(currentProfile.conduit[conduitType]) do
                            required[conduitType][conduitID] = true
                        end
                    end
                end
            end

            if soulbindData and soulbindData.tree and soulbindData.tree.nodes then
                for _, node in ipairs(soulbindData.tree.nodes) do
                    if node.conduitID ~= 0 and node.state == Enum_SoulbindNodeState_Selected then
                        selected[node.conduitType][node.conduitID] = true
                        if required[node.conduitType][node.conduitID] then
                            required[node.conduitType][node.conduitID] = nil
                            pending[node.conduitType][node.conduitID] = true
                        else
                            pending[node.conduitType][node.conduitID] = false
                        end
                    end
                end
            end

            for _, conduitType in ipairs(conduitTypes) do
                for conduitID, status in pairs(pending[conduitType]) do
                    if status == false then
                        -- require replace
                        local replace = next(required[conduitType])
                        pending[conduitType][conduitID] = replace
                        if replace then
                            required[conduitType][replace] = nil
                        end
                    end
                end
            end

            -- status in table `pending`
            -- true:      fixed & matched
            -- conduitID: fixed & not matched & replaced
            -- nil:       not fixed

            for _, conduitType in ipairs(conduitTypes) do
                if next(selected[conduitType]) then
                    local conduitTypeName = conduitType == 1 and CONDUIT_POTENCY or (conduitType == 0 and CONDUIT_FINESSE or CONDUIT_ENDURANCE)
                    DT.tooltip:AddLine(' ')
                    DT.tooltip:AddLine(conduitTypeName, 0.69, 0.31, 0.31)

                    for conduitID in pairs(selected[conduitType]) do
                        local conduitData = C_Soulbinds_GetConduitCollectionData(conduitID)
                        local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(conduitData.conduitItemID)
                        itemName = itemName or conduitData.conduitItemID

                        if not pending[conduitType][conduitID] then
                            -- not fixed
                            DT.tooltip:AddLine(AddTexture(itemIcon or 134400) .. ' |cff606060' .. itemName .. '|r')
                        elseif pending[conduitType][conduitID] == true then
                            -- fixed & matched
                            DT.tooltip:AddLine(AddTexture(itemIcon or 134400) .. ' ' .. itemName)
                        else
                            -- fixed & not matched & replaced
                            local targetConduitData = C_Soulbinds_GetConduitCollectionData(pending[conduitType][conduitID])
                            local targetItemName, _, _, _, _, _, _, _, _, targetItemIcon = GetItemInfo(targetConduitData.conduitItemID)
                            targetItemName = targetItemName or conduitData.conduitItemID

                            DT.tooltip:AddLine(
                                AddTexture(itemIcon or 134400) .. ' |cffff5100' .. itemName .. '|r (' ..
                                AddTexture(targetItemIcon or 134400) .. ' ' .. targetItemName .. ')'
                            )
                        end
                    end

                    for conduitID in pairs(required[conduitType]) do
                        -- fixed & not matched & not enough place
                        local conduitData = C_Soulbinds_GetConduitCollectionData(conduitID)
                        local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(conduitData.conduitItemID)
                        itemName = itemName or conduitData.conduitItemID

                        DT.tooltip:AddLine(AddTexture(itemIcon or 134400) .. ' |cffa335ee' .. itemName .. '|r')
                    end
                end
            end

            if (
                currentProfile and currentProfile.node and
                soulbindData and soulbindData.tree and soulbindData.tree.nodes
            ) then
                DT.tooltip:AddLine(' ')
                DT.tooltip:AddLine("能力", 0.69, 0.31, 0.31)

                for _, nodeID in ipairs(currentProfile.node) do
                    local currentNode = C_Soulbinds_GetNode(nodeID)
                    local spellID = currentNode.spellID
                    local spellName, _, spellIcon = GetSpellInfo(spellID)
                    spellName = spellName or spellID

                    if currentNode.state == Enum_SoulbindNodeState_Selected then
                        DT.tooltip:AddLine(AddTexture(spellIcon or 134400) .. ' ' .. spellName)
                    elseif currentNode.state ~= Enum_SoulbindNodeState_Unselected then
                        -- Unavailable or Selectable
                        DT.tooltip:AddLine(AddTexture(spellIcon or 134400) .. ' |cffa335ee' .. spellName .. '|r')
                    else
                        -- Unselected
                        local inTree, selectedSpellID
                        local rowID = currentNode.row
                        for _, node in ipairs(soulbindData.tree.nodes) do
                            if node.ID == nodeID then
                                inTree = true
                            elseif node.row == rowID and node.state == Enum_SoulbindNodeState_Selected then
                                selectedSpellID = node.spellID
                            end
                        end

                        if not inTree or not selectedSpellID then
                            DT.tooltip:AddLine(AddTexture(spellIcon or 134400) .. ' |cffa335ee' .. spellName .. '|r')
                        else
                            local selectedSpellName, _, selectedSpellIcon = GetSpellInfo(selectedSpellID)
                            selectedSpellName = selectedSpellName or selectedSpellIcon

                            DT.tooltip:AddLine(
                                AddTexture(selectedSpellIcon or 134400) .. ' |cffff5100' .. selectedSpellName .. '|r (' ..
                                AddTexture(spellIcon or 134400) .. ' ' .. spellName .. ')'
                            )
                        end
                    end
                end
            end
        end
    end

    DT.tooltip:Show()
end

local function OnClick(self)
    if not currentSet then return end

    if InCombatLockdown() then
        return _G.UIErrorsFrame:AddMessage(E.InfoColor .. TALENT_TOOLTIP_ADD_COMBAT_ERROR)
    elseif not IsResting() then
        local flag
        for spellID in pairs(canChangeTalentBuffs) do
            local spellName = GetPlayerAuraBySpellID(spellID)
            if spellName then
                flag = true
                break
            end
        end
        if not flag then
            return _G.UIErrorsFrame:AddMessage(E.InfoColor .. TALENT_TOOLTIP_ADD_REST_ERROR)
        end
    end

    DT.tooltip:Hide()
    DT:SetEasyMenuAnchor(DT.EasyMenu, self)
    _G.EasyMenu(profileList[E.myspec], DT.EasyMenu, nil, nil, nil, 'MENU')
end

local delayedOnEvent
local function OnEvent(self, event)
    currentSet = classSet and classSet[E.myspec]

    if not currentSet or not currentSet.Profiles then
        displayName = DEFAULT
        self.text:SetText(DEFAULT)
        return
    end

    currentProfile = nil
    checkFailed = nil

    -- xxx: conduit workaround, not available right after PLAYER_ENTERING_WORLD
    if event and not delayedOnEvent then
        E:Delay(2, OnEvent, self)
        delayedOnEvent = true
    elseif delayedOnEvent then
        delayedOnEvent = nil
    end

    -- apply checks
    if currentSet.Checks then
        local inInstance, instanceType = IsInInstance()
        if inInstance and currentSet.Checks[instanceType] then
            local checks = currentSet.Checks[instanceType]
            if type(checks) == 'number' then
                currentProfile = currentSet.Profiles[checks]
                if currentProfile and profileDistance(checks) > 0 then
                    checkFailed = true
                end
            else
                local list = {}
                for i, index in ipairs(checks) do
                    list[i] = {
                        index = index,
                        distance = profileDistance(index)
                    }
                end
                sort(list, function(left, right)
                    return left.distance < right.distance
                end)

                currentProfile = currentSet.Profiles[list[1].index]
                if currentProfile and list[1].distance > 0 then
                    checkFailed = true
                end
            end
        end
    end

    if not currentProfile then
        for index, profile in ipairs(currentSet.Profiles) do
            if profileDistance(index) == 0 then
                currentProfile = profile
            end
        end
    end

    displayName = currentProfile and currentProfile.name or UNKNOWN
    displayName = checkFailed and ("|cffee4735" .. displayName .. "|r") or displayName
    self.text:SetText(displayName)
end

DT:RegisterDatatext('Talent Set', nil, {
    'PLAYER_ENTERING_WORLD', 'PLAYER_SPECIALIZATION_CHANGED', 'PLAYER_TALENT_UPDATE',
    'SOULBIND_ACTIVATED', 'SOULBIND_CONDUIT_INSTALLED', 'SOULBIND_CONDUIT_UNINSTALLED', 'SOULBIND_PATH_CHANGED'
}, OnEvent, nil, OnClick, OnEnter, nil, "天赋配置")
