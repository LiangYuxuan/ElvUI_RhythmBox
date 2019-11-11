local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local DT = E:GetModule('DataTexts')

-- Lua functions
local _G = _G
local ipairs, pairs, select = ipairs, pairs, select

-- WoW API / Variables
local C_AzeriteEssence_ActivateEssence = C_AzeriteEssence.ActivateEssence
local C_AzeriteEssence_GetMilestoneEssence = C_AzeriteEssence.GetMilestoneEssence
local C_AzeriteEssence_GetMilestones = C_AzeriteEssence.GetMilestones
local GetTalentInfo = GetTalentInfo
local GetTalentTierInfo = GetTalentTierInfo
local IsInInstance = IsInInstance
local LearnTalent = LearnTalent

local WrapTextInColorCode = WrapTextInColorCode

local DEFAULT = DEFAULT
local MAX_TALENT_TIERS = MAX_TALENT_TIERS
local TALENT = TALENT
local UNKNOWN = UNKNOWN

local set = {
    ['DEATHKNIGHT'] = {
        -- Blood
        [1] = {
            Profiles = {
                [1] = {
                    name = '地下城/大米',
                    talent = {1, 2, 2, 1, 1, 2, 3},
                },
                [2] = {
                    name = '团队副本',
                    talent = {0, 2, 0, 0, 0, 2, 2},
                },
            },
            Checks = {
                ['party'] = 1,
                ['raid'] = 2,
            },
        },
    },
    ['DRUID'] = {
        -- Balance
        [1] = {
            Profiles = {
                [1] = {
                    name = '地下城/大米',
                    talent = {3, 0, 0, 0, 3, 2, 2},
                },
                [2] = {
                    name = '团队副本',
                    talent = {1, 0, 0, 0, 3, 2, 1},
                },
            },
            Checks = {
                ['party'] = 1,
                ['raid'] = 2,
            },
        },
        -- Restoration
        [4] = {
            Profiles = {
                [1] = {
                    name = '地下城/大米',
                    talent = {1, 0, 0, 0, 3, 2, 3},
                },
                [2] = {
                    name = '团队副本',
                    talent = {3, 0, 0, 0, 2, 1, 3},
                },
            },
            Checks = {
                ['party'] = 1,
                ['raid'] = 2,
            },
        },
    },
    ['DEMONHUNTER'] = {
        [1] = {
            Profiles = {
                [1] = {
                    name = DEFAULT,
                    talent = {1, 3, 1, 1, 2, 1, 1},
                },
            },
        },
    },
    ['WARRIOR'] = {
        [1] = {
            Profiles = {
                [1] = {
                    name = DEFAULT,
                    talent = {1, 1, 2, 3, 2, 1, 1},
                },
            },
        },
    },
}
local classSet = set[E.myclass]
local currentSet, currentProfile
local activeSpec = GetActiveSpecGroup()

local function applySet(_, index)
    local profile = currentSet and currentSet.Profiles and currentSet.Profiles[index]
    if not profile then return end

    if profile.talent then
        for tier, column in ipairs(profile.talent) do
            if column ~= '0' then
                local talentID = GetTalentInfo(tier, column, activeSpec)
                LearnTalent(talentID)
            end
        end
    end

    if profile.essence then
        for milestoneID, essenceID in pairs(profile.essence) do
            C_AzeriteEssence_ActivateEssence(essenceID, milestoneID)
        end
    end
end

local menuFrame = CreateFrame('Frame', 'TalentSetDatatextClickMenu', E.UIParent, 'UIDropDownMenuTemplate')
local profileList = {}
if classSet then
    for specID, specSet in pairs(classSet) do
        if specSet.Profiles then
            local profiles = {
                { text = TALENT, isTitle = true, notCheckable = true },
            }
            for index, profile in ipairs(specSet.Profiles) do
                tinsert(profiles, { text = profile.name, arg1 = index, func = applySet, notCheckable = true })
            end
            profileList[specID] = profiles
        end
    end
end

local function checkProfile(profile)
    if not profile then return end

    if profile.talent then
        for i = 1, MAX_TALENT_TIERS do
            if profile.talent[i] ~= 0 and profile.talent[i] ~= select(2, GetTalentTierInfo(i, activeSpec)) then
                return
            end
        end
    end

    if profile.essence then
        local milestones = C_AzeriteEssence_GetMilestones()
        for _, milestone in ipairs(milestones) do
            if (
                profile.essence[milestone.ID] and
                profile.essence[milestone.ID] ~= C_AzeriteEssence_GetMilestoneEssence(milestone.ID)
            ) then
                return
            end
        end
    end

    return true
end

local function OnClick(self, button)
    if not currentSet then return end

    _G.EasyMenu(profileList[E.myspec], menuFrame, 'CURSOR', -15, -7, 'MENU', 2)
end

local function OnEvent(self)
    currentSet = classSet and classSet[E.myspec]

    if not currentSet or not currentSet.Profiles then
        self:SetText(DEFAULT)
        return
    end

    -- apply checks
    local checkFailed
    if currentSet.Checks then
        local inInstance, instanceType = IsInInstance()
        if inInstance and currentSet.Checks[instanceType] then
            if checkProfile(currentSet.Profiles[currentSet.Checks[instanceType]]) then
                -- check success
                currentProfile = currentSet.Profiles[currentSet.Checks[instanceType]]
            else
                checkFailed = true
            end
        end
    end

    if not currentProfile then
        for _, profile in ipairs(currentSet.Profiles) do
            if checkProfile(profile) then
                currentProfile = profile
            end
        end
    end

    local displayName = currentProfile and currentProfile.name or UNKNOWN
    self:SetText(checkFailed and WrapTextInColorCode(displayName, "ee4735") or displayName)
end

DT:RegisterDatatext('Talent Set', {'PLAYER_ENTERING_WORLD', 'PLAYER_SPECIALIZATION_CHANGED', 'PLAYER_TALENT_UPDATE'}, OnEvent, nil, OnClick, nil, nil, "天赋配置")
