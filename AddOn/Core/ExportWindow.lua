local R, E, L, V, P, G = unpack((select(2, ...)))
local S = E:GetModule('Skins')

local function OnMouseDown(self, button)
    if button == 'LeftButton' and not self.isMoving then
        self:StartMoving()
        self.isMoving = true
    elseif button == 'RightButton' and not self.isSizing then
        self:StartSizing()
        self.isSizing = true
    end
end

local function OnMouseUp(self, button)
    if button == 'LeftButton' and self.isMoving then
        self:StopMovingOrSizing()
        self.isMoving = false
    elseif button == 'RightButton' and self.isSizing then
        self:StopMovingOrSizing()
        self.isSizing = false
    end
end

local function OnHide(self)
    if self.isMoving or self.isSizing then
        self:StopMovingOrSizing()
        self.isMoving = false
        self.isSizing = false
    end
end

local function OnSizeChanged(self, width, height)
    local child = self:GetScrollChild()
    if child then
        child:SetSize(width, height)
    end
end

local frame = CreateFrame('Frame', 'RhythmBoxExportWindow', E.UIParent)
frame:SetTemplate('Transparent')
frame:SetFrameStrata('DIALOG')
frame:ClearAllPoints()
frame:SetPoint('CENTER')
frame:SetSize(600, 550)
frame:Hide()

frame:EnableMouse(true)
frame:SetMovable(true)
frame:SetResizable(true)
frame:SetClampedToScreen(true)
frame:SetScript('OnMouseDown', OnMouseDown)
frame:SetScript('OnMouseUp', OnMouseUp)
frame:SetScript('OnHide', OnHide)

table.insert(_G.UISpecialFrames, 'RhythmBoxExportWindow')

local scrollFrame = CreateFrame('ScrollFrame', 'RhythmBoxExportWindowScrollFrame', frame, 'UIPanelScrollFrameTemplate')
scrollFrame:ClearAllPoints()
scrollFrame:SetPoint('LEFT', 16, 0)
scrollFrame:SetPoint('RIGHT', -32, 0)
scrollFrame:SetPoint('TOP', 0, -32)
scrollFrame:SetPoint('BOTTOM', 0, 16)
scrollFrame:SetScript('OnSizeChanged', OnSizeChanged)

local editBox = CreateFrame('EditBox', 'RhythmBoxExportWindowEditBox', scrollFrame)
editBox:SetSize(scrollFrame:GetSize())
editBox:SetMultiLine(true)
editBox:SetAutoFocus(false)
editBox:SetFontObject('ChatFontSmall')
editBox:SetScript('OnEscapePressed', editBox.ClearFocus)
scrollFrame:SetScrollChild(editBox)

local closeButton = CreateFrame('Button', 'RhythmBoxExportWindowCloseButton', frame, 'UIPanelCloseButton')
closeButton:ClearAllPoints()
closeButton:SetPoint('TOPRIGHT')
closeButton:OffsetFrameLevel(1)
closeButton:EnableMouse(true)

local isSkinned = false

function R:ShowExportWindow()
    if not isSkinned then
        S:HandleScrollBar(scrollFrame.ScrollBar)
        S:HandleCloseButton(closeButton)
        isSkinned = true
    end

    editBox:SetText('')
    frame:Show()
end

function R:InsertExportWindow(text)
    editBox:Insert(text)
end
