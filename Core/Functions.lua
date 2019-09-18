local R, E, L, V, P, G = unpack(select(2, ...))

-- Lua functions
local _G = _G
local assert = assert

-- WoW API / Variables

R.TexCoords = {0, 1, 0, 1}
do
    local modifier = 0.04 * E.db.general.cropIcon
    for i, v in ipairs(R.TexCoords) do
        if i % 2 == 0 then
            R.TexCoords[i] = v - modifier
        else
            R.TexCoords[i] = v + modifier
        end
    end
end

R.Solid = E.Libs.LSM:Fetch('background', 'Solid')

function R:Print(...)
    _G.DEFAULT_CHAT_FRAME:AddMessage("|cFF70B8FFElvUI Rhythm Box:|r ", ...)
end

function R:SetTemplate(frame)
	if _G.AddOnSkins then
		_G.AddOnSkins[1]:SetTemplate(frame)
	elseif frame.SetTemplate then
		frame:SetTemplate('Transparent', true)
	else
		frame:SetBackdrop({ bgFile = R.Solid, edgeFile = R.Solid, tile = false, tileSize = 0, edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
		frame:SetBackdropColor(.08, .08, .08, .8)
		frame:SetBackdropBorderColor(0, 0, 0)
	end
end

function R:CreateShadow(frame)
	if _G.AddOnSkins then
		_G.AddOnSkins[1]:CreateShadow(frame)
	elseif frame.CreateShadow then
		frame:CreateShadow()
	end
end

function R:SetInside(obj, anchor, xOffset, yOffset, anchor2)
	xOffset = xOffset or 1
	yOffset = yOffset or 1
	anchor = anchor or obj:GetParent()

	assert(anchor)
	if obj:GetPoint() then
		obj:ClearAllPoints()
	end

	obj:SetPoint('TOPLEFT', anchor, 'TOPLEFT', xOffset, -yOffset)
	obj:SetPoint('BOTTOMRIGHT', anchor2 or anchor, 'BOTTOMRIGHT', -xOffset, yOffset)
end

function R:SetOutside(obj, anchor, xOffset, yOffset, anchor2)
	xOffset = xOffset or 1
	yOffset = yOffset or 1
	anchor = anchor or obj:GetParent()

	assert(anchor)
	if obj:GetPoint() then
		obj:ClearAllPoints()
	end

	obj:SetPoint('TOPLEFT', anchor, 'TOPLEFT', -xOffset, yOffset)
	obj:SetPoint('BOTTOMRIGHT', anchor2 or anchor, 'BOTTOMRIGHT', xOffset, -yOffset)
end
