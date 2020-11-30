local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local DT = E:GetModule('DataTexts')

-- Lua functions
local _G = _G
local format, ipairs, pairs, select, sort, type = format, ipairs, pairs, select, sort, type

-- WoW API / Variables
local GetPlayerAuraBySpellID = GetPlayerAuraBySpellID
local GetTalentInfo = GetTalentInfo
local GetTalentTierInfo = GetTalentTierInfo
local InCombatLockdown = InCombatLockdown
local IsInInstance = IsInInstance
local IsResting = IsResting
local LearnTalent = LearnTalent

local DEFAULT = DEFAULT
local MAX_TALENT_TIERS = MAX_TALENT_TIERS
local TALENTS = TALENTS
local TALENT_TOOLTIP_ADD_COMBAT_ERROR = TALENT_TOOLTIP_ADD_COMBAT_ERROR
local TALENT_TOOLTIP_ADD_REST_ERROR = TALENT_TOOLTIP_ADD_REST_ERROR
local UNKNOWN = UNKNOWN

local set = {
    ['DRUID'] = {
        -- Balance
        [1] = {
            Profiles = {
                [1] = {
                    name = "副本：丛林之魂/星界漂流",
                    talent = {1, 0, 0, 0, 1, 1, 1},
                },
                [2] = {
                    name = "副本：星辰领主/星辰耀斑",
                    talent = {1, 0, 0, 0, 2, 3, 1},
                },
            },
            Checks = {
                ['party'] = {1},
                ['raid'] = {1, 2},
            },
        },
        -- Restoration
        [4] = {
            Profiles = {
                [1] = {
                    name = "副本：结界/栽培/光合作用",
                    talent = {3, 0, 1, 3, 2, 2, 1},
                },
                [2] = {
                    name = "副本：结界/丛林之魂/光合作用",
                    talent = {3, 0, 1, 3, 1, 2, 1},
                },
                [3] = {
                    name = "副本：丰饶/化身/繁盛",
                    talent = {1, 0, 1, 3, 3, 2, 3},
                },
            },
            Checks = {
                ['party'] = {1, 2},
                ['raid'] = {3},
            },
        },
    },
    ['DEMONHUNTER'] = {
        -- Havoc
        [1] = {
            Profiles = {
                [1] = {
                    name = "副本：恶魔食欲/第一滴血/魔化",
                    talent = {2, 2, 3, 0, 2, 0, 1},
                },
                [2] = {
                    name = "副本：盲目之怒/第一滴血/魔化",
                    talent = {1, 2, 3, 0, 2, 0, 1},
                },
                [3] = {
                    name = "副本：盲目之怒/仇恨之轮/弹幕",
                    talent = {1, 2, 3, 0, 1, 0, 3},
                },
            },
            Checks = {
                ['party'] = {2, 3},
                ['raid'] = {1},
            },
        },
        -- Vengeance
        [2] = {
            Profiles = {
                [1] = {
                    name = "副本：锁链咒符",
                    talent = {2, 2, 3, 3, 3, 2, 1},
                },
                [2] = {
                    name = "副本：快速咒符",
                    talent = {2, 2, 3, 3, 2, 2, 1},
                },
            },
            Checks = {
                ['party'] = {1, 2},
                ['raid'] = {1, 2},
            },
        },
    },
    ['MAGE'] = {
        -- Fire
        [2] = {
            Profiles = {
                [1] = {
                    name = "副本：烈焰之地",
                    talent = {3, 0, 3, 1, 0, 1, 1},
                },
                [2] = {
                    name = "副本：洪荒烈火",
                    talent = {3, 0, 3, 1, 0, 2, 1},
                },
            },
            Checks = {
                ['party'] = {1},
                ['raid'] = {2},
            },
        },
        -- Frost
        [3] = {
            Profiles = {
                [1] = {
                    name = "副本：碎冰",
                    talent = {2, 0, 3, 2, 0, 2, 1},
                },
            },
            Checks = {
                ['party'] = {1},
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

local function OnEvent(self)
    currentSet = classSet and classSet[E.myspec]

    if not currentSet or not currentSet.Profiles then
        displayName = DEFAULT
        self.text:SetText(DEFAULT)
        return
    end

    currentProfile = nil
    checkFailed = nil

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

DT:RegisterDatatext('Talent Set', nil, {'PLAYER_ENTERING_WORLD', 'PLAYER_SPECIALIZATION_CHANGED', 'PLAYER_TALENT_UPDATE'}, OnEvent, nil, OnClick, OnEnter, nil, "天赋配置")
