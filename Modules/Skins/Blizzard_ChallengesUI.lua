local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local RS = R:GetModule('Skins')

-- Lua functions
local _G = _G
local pairs, select = pairs, select

-- WoW API / Variables
local C_ChallengeMode_GetMapUIInfo = C_ChallengeMode.GetMapUIInfo
local GetAchievementCriteriaInfo = GetAchievementCriteriaInfo
local GetAchievementNumCriteria = GetAchievementNumCriteria

local CONQUEROR = 14531
local MASTER = 14532

local specialName = {
}

function RS:ChallengesFrame_Update()
    local data = {}
    local length = GetAchievementNumCriteria(MASTER)
    for i = 1, length do
        local name, _, complete = GetAchievementCriteriaInfo(MASTER, i)
        if complete then
            data[name] = 'VignetteKillElite'
        else
            complete = select(3, GetAchievementCriteriaInfo(CONQUEROR, i))
            if complete then
                data[name] = 'VignetteKill'
            end
        end
    end

    for _, icon in pairs(_G.ChallengesFrame.DungeonIcons) do
        local name = specialName[icon.mapID] or C_ChallengeMode_GetMapUIInfo(icon.mapID)
        if not icon.tex then
            local tex = icon:CreateTexture()
            tex:SetWidth(24)
            tex:SetHeight(24)
            tex:ClearAllPoints()
            tex:SetPoint('BOTTOM', icon, 0, 3)
            icon.tex = tex
        end
        if data[name] then
            icon.tex:SetAtlas(data[name])
            icon.tex:Show()
        else
            icon.tex:Hide()
        end
    end
end

function RS:Blizzard_ChallengesUI()
    self:SecureHook('ChallengesFrame_Update')
end

RS:RegisterSkin(RS.Blizzard_ChallengesUI, 'Blizzard_ChallengesUI')
