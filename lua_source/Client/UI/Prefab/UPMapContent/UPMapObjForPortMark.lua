-----------------------------------------------------
--File Name    : UPMapObjForPortMark.lua
--Author       : Ran Jie
--Create Time  : 2019-11-27
--Description  : UPMapObjForPortMark
-----------------------------------------------------

local luaclass = require ("luaclass")
local UPMapObj = require("UPMapObj")
local UPMapObjForPortMark = luaclass("UPMapObjForPortMark", UPMapObj)

-- import require

local ALIGNMENT_MARK = Vector2D{X = 0.5, Y = 1}


--member function
function UPMapObjForPortMark:ShowContent(tbData)
    self.bIsInUse = true
    self.tbData = tbData
    if(self.pWidgetRef == nil) then
        return
    end
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    --pWidgetRef.cvsPosPanel:SetVisibility(ESlateVisibility_SelfHitTestInvisible)

    -- if pWidgetRef.imgSmallIcon then
    --     pWidgetRef.imgSmallIcon:SetVisibility(ESlateVisibility_Collapsed)
    -- end
    -- self:SetIcon(tbData.szIcon, tbData.Dimension, tbData.SlateColor, tbData.bMatchSize)
    -- self:SetName(tbData.szName)
    local pWidgetSlot = pWidgetRef.Slot
    -- if tbData.UILocation then
    --     local UIPos = Vector2D{X = tbData.UILocation.X, Y = tbData.UILocation.Y}
    --     pWidgetSlot:SetPosition(UIPos)
    -- end
    -- if tbData.UIRotation then
    --     self.pWidgetRef:SetRenderTransformAngle(tbData.UIRotation)
    -- else
    --     self.pWidgetRef:SetRenderTransformAngle(0)
    -- end
    --pWidgetSlot:SetAutoSize(false)
    pWidgetSlot:SetAlignment(ALIGNMENT_MARK)
    if tbData.UISize then
        local UISize = Vector2D{X = tbData.UISize.X, Y = tbData.UISize.Y}
        pWidgetRef.Slot:SetAutoSize(false)
        pWidgetRef.Slot:SetSize(UISize)
    else
        pWidgetRef.Slot:SetAutoSize(true)
    end
    self:PlayAnimation("animLanding", 0, 0, EUMGSequencePlayMode.Forward, 1)
end

function UPMapObjForPortMark:HideContent()
    self.bIsInUse = false
    self.tbData = nil
    if(self.pWidgetRef == nil) then
        return
    end
    --self.pWidgetRef.cvsPosPanel:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end

function UPMapObjForPortMark:SetIcon(szIcon, pDimension, pSlateColor, bMatchSize)
    
end


function UPMapObjForPortMark:SetName(szName)
    
end




return UPMapObjForPortMark
