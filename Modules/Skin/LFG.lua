local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local RS = E:GetModule('RhythmBox_Skin')

function RS:Blizzard_ChallengesUI()
    hooksecurefunc('ChallengesFrame_Update', function()
        for i, icon in pairs(ChallengesFrame.DungeonIcons) do
            if not icon.tex then
                local tex = icon:CreateTexture()
                tex:SetWidth(24)
                tex:SetHeight(24)
                tex:ClearAllPoints()
                tex:SetPoint('BOTTOM', icon, 0, 3)
                icon.tex = tex
                icon:HookScript('OnEnter', function()
                        GameTooltip_AddBlankLineToTooltip(GameTooltip);
                        GameTooltip:AddLine("\124TInterface/Minimap/ObjectIconsAtlas:16:16:0:0:1024:512:575:607:205:237\124t 10+ Timed")
                        GameTooltip:AddLine("\124TInterface/Minimap/ObjectIconsAtlas:16:16:0:0:1024:512:575:607:239:271\124t 15+ Timed")
                        GameTooltip:Show()
                end)
            end
            icon.tex:Show()
            local inTimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(icon.mapID);
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
    end)
end

RS:RegisterSkin(RS.Blizzard_ChallengesUI, 'Blizzard_ChallengesUI')
