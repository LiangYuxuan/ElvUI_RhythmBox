local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local DT = E:GetModule('DataTexts')

-- Lua functions
local _G = _G
local format, ipairs, next, pairs, select, sort, type = format, ipairs, next, pairs, select, sort, type

-- WoW API / Variables
local C_AzeriteEssence_ActivateEssence = C_AzeriteEssence.ActivateEssence
local C_AzeriteEssence_GetEssenceInfo = C_AzeriteEssence.GetEssenceInfo
local C_AzeriteEssence_GetMilestoneEssence = C_AzeriteEssence.GetMilestoneEssence
local GetTalentInfo = GetTalentInfo
local GetTalentTierInfo = GetTalentTierInfo
local InCombatLockdown = InCombatLockdown
local IsInInstance = IsInInstance
local IsResting = IsResting
local LearnTalent = LearnTalent
local UnitAura = UnitAura

local AZERITE_ESSENCE_ITEM_TYPE = AZERITE_ESSENCE_ITEM_TYPE
local DEFAULT = DEFAULT
local MAX_TALENT_TIERS = MAX_TALENT_TIERS
local TALENTS = TALENTS
local TALENT_TOOLTIP_ADD_COMBAT_ERROR = TALENT_TOOLTIP_ADD_COMBAT_ERROR
local TALENT_TOOLTIP_ADD_REST_ERROR = TALENT_TOOLTIP_ADD_REST_ERROR
local UNKNOWN = UNKNOWN

local set = {
    ['DEATHKNIGHT'] = {
        -- Blood
        [1] = {
            Profiles = {
                [1] = {
                    name = '地下城：生死心能',
                    talent = {1, 2, 2, 1, 1, 2, 3},
                    essence = {[0] = 7, 32, 13, 34},
                },
                [2] = {
                    name = '地下城：烈焰熔炉',
                    talent = {1, 2, 2, 1, 1, 2, 3},
                    essence = {[0] = 12, 32, 13, 37},
                },
                [3] = {
                    name = '地下城：不朽赐福',
                    talent = {1, 2, 2, 1, 1, 2, 3},
                    essence = {[0] = 2, 32, 13, 34},
                },
                [4] = {
                    name = '团队副本',
                    talent = {0, 2, 0, 0, 0, 2, 2},
                    essence = {[0] = 2, 32, 22, 34},
                },
            },
            Checks = {
                ['party'] = {1, 2, 3},
                ['raid'] = 4,
            },
        },
    },
    ['DRUID'] = {
        -- Balance
        [1] = {
            Profiles = {
                [1] = {
                    name = '副本：自然平衡/坠星',
                    talent = {1, 0, 0, 0, 2, 2, 1},
                    essence = {[0] = 22, 5, 32, 35},
                },
                [2] = {
                    name = '副本：自然平衡/轨道炮',
                    talent = {1, 0, 0, 0, 2, 2, 2},
                    essence = {[0] = 5, 22, 32, 35},
                },
                [3] = {
                    name = '野外：树人/轨道炮',
                    talent = {3, 0, 0, 0, 2, 2, 2},
                    essence = {[0] = 5, 22, 32, 35},
                },
            },
            Checks = {
                ['party'] = {1, 2},
                ['raid'] = 1,
            },
        },
        -- Restoration
        [4] = {
            Profiles = {
                [1] = {
                    name = '地下城：光合/熔炉',
                    talent = {3, 0, 0, 0, 2, 3, 1},
                    essence = {[0] = 12, 32, 21, 37},
                },
                [2] = {
                    name = '地下城：光合/无形',
                    talent = {3, 0, 0, 0, 2, 3, 1},
                    essence = {[0] = 37, 32, 21, 27},
                },
                [3] = {
                    name = '地下城：繁盛/梦境',
                    talent = {3, 0, 0, 0, 2, 3, 3},
                    essence = {[0] = 27, 17, 19, 24},
                },
                [4] = {
                    name = '地下城：繁盛/永恒',
                    talent = {3, 0, 0, 0, 2, 3, 3},
                    essence = {[0] = 17, 32, 19, 24},
                },
                [5] = {
                    name = '团队副本：丰饶/繁盛',
                    talent = {1, 0, 0, 0, 2, 3, 3},
                    essence = {[0] = 4, 27, 17, 19},
                },
                [6] = {
                    name = '场景：惊魂幻象',
                    talent = {3, 3, 2, 3, 2, 3, 1},
                    essence = {[0] = 12, 32, 27, 37},
                },
            },
            Checks = {
                ['party'] = {1, 2, 3, 4},
                ['raid'] = 5,
            },
        },
    },
    ['DEMONHUNTER'] = {
        [1] = {
            Profiles = {
                [1] = {
                    name = '地下城：邪能弹幕',
                    talent = {2, 3, 3, 0, 2, 1, 1},
                    essence = {[0] = 5, 22, 32, 35},
                },
                [2] = {
                    name = '地下城：毁灭之痕',
                    talent = {2, 3, 1, 0, 2, 1, 1},
                    essence = {[0] = 5, 22, 32, 35},
                },
                [3] = {
                    name = '团队副本：毁灭之痕',
                    talent = {2, 3, 1, 0, 2, 1, 1},
                    essence = {[0] = 14, 22, 32, 35},
                },
            },
            Checks = {
                ['party'] = {1, 2},
                ['raid'] = 3,
            },
        },
    },
    ['WARRIOR'] = {
        [3] = {
            Profiles = {
                [1] = {
                    name = "副本：完美愿景",
                    talent = {1, 0, 2, 3, 2, 1, 1},
                    essence = {[0] = 22, 32, 13, 34},
                },
                [2] = {
                    name = "副本：清醒梦境之忆",
                    talent = {1, 0, 2, 3, 2, 1, 1},
                    essence = {[0] = 27, 32, 22, 34},
                },
                [3] = {
                    name = "副本：勇卫之力",
                    talent = {1, 0, 2, 3, 2, 1, 1},
                    essence = {[0] = 34, 32, 13, 22},
                },
                [4] = {
                    name = "副本：烈焰熔炉",
                    talent = {1, 0, 2, 3, 2, 1, 1},
                    essence = {[0] = 12, 32, 22, 37},
                },
                [5] = {
                    name = "副本：不朽赐福",
                    talent = {1, 0, 2, 3, 2, 1, 1},
                    essence = {[0] = 2, 22, 13, 37},
                },
            },
            Checks = {
                ['party'] = {1, 2, 3, 4},
                ['raid'] = {4, 5},
            },
        },
    },
    ['MAGE'] = {
        [2] = {
            Profiles = {
                [1] = {
                    name = "清醒：活动炸弹",
                    talent = {3, 0, 3, 1, 0, 3, 3},
                    essence = {[0] = 27, 32, 35, 37},
                },
                [2] = {
                    name = "清醒：洪荒烈火",
                    talent = {3, 0, 3, 1, 0, 2, 3},
                    essence = {[0] = 27, 32, 35, 37},
                },
                [3] = {
                    name = "薪火：活动炸弹",
                    talent = {3, 0, 3, 1, 0, 3, 1},
                    essence = {[0] = 4, 27, 22, 37},
                },
                [4] = {
                    name = "薪火：洪荒烈火",
                    talent = {3, 0, 3, 1, 0, 2, 1},
                    essence = {[0] = 4, 27, 22, 37},
                },
            },
            Checks = {
                ['party'] = {1, 3},
                ['raid'] = {2, 4},
            },
        },
    },
    ['ROGUE'] = {
        [2] = {
            Profiles = {
                [1] = {
                    name = "地下城：精力/灌铅骰子",
                    talent = {2, 1, 1, 0, 3, 1, 1},
                    essence = {[0] = 22, 27, 5, 35},
                },
                [2] = {
                    name = "地下城：精力/敏锐",
                    talent = {2, 1, 1, 0, 3, 2, 1},
                    essence = {[0] = 23, 27, 22, 35},
                },
                [3] = {
                    name = "团队副本",
                    talent = {2, 1, 1, 0, 3, 2, 2},
                    essence = {[0] = 23, 27, 22, 35},
                }
            },
            Checks = {
                ['party'] = {1, 2},
                ['raid'] = {2, 3},
            },
        },
    },
}
local classSet = set[E.myclass]
local currentSet, currentProfile, displayName
local activeSpec = GetActiveSpecGroup()

local canChangeTalentBuffs = {
    -- Tome and Codex
    -- Warlords of Draenor
    [226234] = true, -- Codex of the Tranquil Mind
    [227041] = true, -- Tome of the Tranquil Mind
    -- Legion
    [227563] = true, -- Tome of the Clear Mind
    [227565] = true, -- Codex of the Clear Mind
    [234415] = true, -- Allow Talent Swapping
    -- Battle for Azeroth
    [256229] = true, -- Codex of the Quiet Mind
    [256231] = true, -- Tome of the Quiet Mind

    -- Preparation
    [32727]  = true, -- Arena Preparation
    [44521]  = true, -- Preparation
    [228128] = true, -- Dungeon Preparation
    [248473] = true, -- Battleground Insight
    [279737] = true, -- Prepare for Battle! (Island Preparation) (Debuff)
}
local essenceMilestoneIDs = {
    [0] = 115,
    [1] = 116,
    [2] = 117,
    [3] = 119,
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
                distance = distance + 1
            end
        end
    end

    if profile.essence then
        local requirePool = {}
        local selectedPool = {}

        for slotID, milestoneID in pairs(essenceMilestoneIDs) do
            if slotID == 0 then
                -- Major Slot
                if (
                    profile.essence[slotID] and
                    profile.essence[slotID] ~= C_AzeriteEssence_GetMilestoneEssence(milestoneID)
                ) then
                    distance = distance + 1
                end
            else
                local essenceID = C_AzeriteEssence_GetMilestoneEssence(milestoneID)
                if essenceID then
                    selectedPool[essenceID] = true
                end
                if profile.essence[slotID] then
                    requirePool[profile.essence[slotID]] = true
                end
            end
        end

        -- remove all selected in require pool
        for essenceID in pairs(selectedPool) do
            requirePool[essenceID] = nil
        end

        -- find any require not matched
        for _ in pairs(requirePool) do
            distance = distance + 1
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

    if profile.essence then
        for slot, essenceID in pairs(profile.essence) do
            C_AzeriteEssence_ActivateEssence(essenceID, essenceMilestoneIDs[slot])
        end
    end
end

local menuFrame = CreateFrame('Frame', 'TalentSetDatatextClickMenu', E.UIParent, 'UIDropDownMenuTemplate')
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
                DT.tooltip:AddLine(AddTexture(icon) .. ' ' .. name)
            else
                -- not matched
                local _, targetName, targetIcon = GetTalentInfo(i, currentProfile.talent[i], activeSpec)
                DT.tooltip:AddLine(
                    AddTexture(icon) .. ' |cffff5100' .. name .. '|r (' ..
                    AddTexture(targetIcon) .. ' ' .. targetName .. ')'
                )
            end
        else
            -- not fixed
            DT.tooltip:AddLine(AddTexture(icon) .. ' |cff606060' .. name .. '|r')
        end
    end

    DT.tooltip:AddLine(' ')
    DT.tooltip:AddLine(AZERITE_ESSENCE_ITEM_TYPE, 0.69, 0.31, 0.31)

    local pendingSlot = {}
    if currentProfile and currentProfile.essence then
        local requirePool = {}
        local selectedPool = {}
        local prevEssence

        for slotID, milestoneID in pairs(essenceMilestoneIDs) do
            if slotID > 0 then
                local essenceID = C_AzeriteEssence_GetMilestoneEssence(milestoneID)
                if essenceID then
                    selectedPool[C_AzeriteEssence_GetMilestoneEssence(milestoneID)] = slotID
                end
                if currentProfile.essence[slotID] then
                    requirePool[currentProfile.essence[slotID]] = true
                end
            end
        end
        -- remove all required and selected
        for essenceID in pairs(requirePool) do
            if selectedPool[essenceID] then
                pendingSlot[selectedPool[essenceID]] = true -- record matched slot

                requirePool[essenceID] = nil
                selectedPool[essenceID] = nil
            end
        end
        for _, slotID in pairs(selectedPool) do
            pendingSlot[slotID] = next(requirePool, prevEssence)
            prevEssence = pendingSlot[slotID]
        end
    end

    for slotID, milestoneID in pairs(essenceMilestoneIDs) do
        local essenceID = C_AzeriteEssence_GetMilestoneEssence(milestoneID)
        local info = essenceID and C_AzeriteEssence_GetEssenceInfo(essenceID)

        if info then
            if slotID == 0 then
                if currentProfile and currentProfile.essence and currentProfile.essence[slotID] then
                    -- fixed
                    if currentProfile.essence[slotID] == essenceID then
                        -- matched
                        DT.tooltip:AddLine(AddTexture(info.icon) .. ' ' .. info.name)
                    else
                        -- not matched
                        local targetInfo = C_AzeriteEssence_GetEssenceInfo(currentProfile.essence[slotID])
                        DT.tooltip:AddLine(
                            AddTexture(info.icon) .. ' |cffff5100' .. info.name .. '|r (' ..
                            AddTexture(targetInfo.icon) .. ' ' .. targetInfo.name .. ')'
                        )
                    end
                else
                    -- not fixed
                    DT.tooltip:AddLine(AddTexture(info.icon) .. ' |cff606060' .. info.name .. '|r')
                end
            else
                if not pendingSlot[slotID] then
                    -- not fixed
                    DT.tooltip:AddLine(AddTexture(info.icon) .. ' |cff606060' .. info.name .. '|r')
                elseif type(pendingSlot[slotID]) == 'boolean' then
                    -- matched
                    DT.tooltip:AddLine(AddTexture(info.icon) .. ' ' .. info.name)
                else
                    -- not matched
                    local targetInfo = C_AzeriteEssence_GetEssenceInfo(pendingSlot[slotID])
                    DT.tooltip:AddLine(
                        AddTexture(info.icon) .. ' |cffff5100' .. info.name .. '|r (' ..
                        AddTexture(targetInfo.icon) .. ' ' .. targetInfo.name .. ')'
                    )
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
        for i = 1, 255 do
            local spellID = select(10, UnitAura('player', i, 'HELPFUL'))
            if not spellID then break end

            if spellID and canChangeTalentBuffs[spellID] then
                flag = true
                break
            end
        end
        if not flag then
            -- not able to use UnitAura without filter due to blizzard bug
            -- https://github.com/WeakAuras/WeakAuras2/issues/1734
            for i = 1, 255 do
                local spellID = select(10, UnitAura('player', i, 'HARMFUL'))
                if not spellID then break end

                if spellID and canChangeTalentBuffs[spellID] then
                    flag = true
                    break
                end
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

local function OnEvent(self)
    currentSet = classSet and classSet[E.myspec]

    if not currentSet or not currentSet.Profiles then
        displayName = DEFAULT
        self.text:SetText(DEFAULT)
        return
    end

    currentProfile = nil
    local checkFailed = nil

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

DT:RegisterDatatext('Talent Set', nil, {'PLAYER_ENTERING_WORLD', 'PLAYER_SPECIALIZATION_CHANGED', 'PLAYER_TALENT_UPDATE', 'AZERITE_ESSENCE_ACTIVATED'}, OnEvent, nil, OnClick, OnEnter, nil, "天赋配置")
