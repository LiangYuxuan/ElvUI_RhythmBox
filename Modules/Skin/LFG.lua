local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local RS = R:GetModule('Skin')

-- Lua functions
local _G = _G
local pairs = pairs

-- WoW API / Variables
local C_MythicPlus_GetSeasonBestForMap = C_MythicPlus.GetSeasonBestForMap

function RS:ChallengesFrame_Update()
    for _, icon in pairs(_G.ChallengesFrame.DungeonIcons) do
        if not icon.tex then
            local tex = icon:CreateTexture()
            tex:SetWidth(24)
            tex:SetHeight(24)
            tex:ClearAllPoints()
            tex:SetPoint('BOTTOM', icon, 0, 3)
            icon.tex = tex
        end
        icon.tex:Show()
        local inTimeInfo = C_MythicPlus_GetSeasonBestForMap(icon.mapID)
        if inTimeInfo then
            if inTimeInfo.level >= 15 then
                icon.tex:SetAtlas('VignetteKillElite')
            elseif inTimeInfo.level >= 10 then
                icon.tex:SetAtlas('VignetteKill')
            else
                icon.tex:Hide()
            end
        else
            icon.tex:Hide()
        end
    end
end

function RS:Blizzard_ChallengesUI()
    self:SecureHook('ChallengesFrame_Update')
end

-- RS:RegisterSkin(RS.Blizzard_ChallengesUI, 'Blizzard_ChallengesUI')
