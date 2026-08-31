-----------------------------------------------------
--File Name    : UPMapObjForFFAStaticPoint.lua
--Author       : Ran Jie
--Create Time  : 2017-03-20
--Description  : UPMapObjForFFAStaticPoint
-----------------------------------------------------

local luaclass = require ("luaclass")
local UPMapObj = require("UPMapObj")
local UPMapObjForFFAStaticPoint = luaclass("UPMapObjForFFAStaticPoint", UPMapObj)

-- import require
local MiniMapSystem = require("MiniMapSystem")

local function SetNameFontSize(self)
    local txtObjName = self.pWidgetRef.txtObjName
    local pFontInfo = txtObjName.Font
    pFontInfo.Size = self.tbData.nFontSize
    --logdebug("SetNameFontSize,pFontInfo.Size=",pFontInfo.Size)
    txtObjName:SetFont(pFontInfo)
end

--member function
function UPMapObjForFFAStaticPoint:ShowContent(tbData)
    self.bIsInUse = true
    self.tbData = tbData
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.cvsPosPanel:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    
    if tbData.UILocation then
        local UIPos = Vector2D{X = tbData.UILocation.X, Y = tbData.UILocation.Y}
        --logdebug("UPMapObjForFFAStaticPoint:ShowContent,UIPos=",UIPos.X, UIPos.Y)
        self.pWidgetRef.Slot:SetPosition(UIPos)
    end
    if tbData.UIRotation then
        self.pWidgetRef:SetRenderTransformAngle(tbData.UIRotation)
    else
        self.pWidgetRef:SetRenderTransformAngle(0)
    end
    if tbData.UISize then
        local pWidgetSlot = pWidgetRef.Slot
        local UISize = Vector2D{X = tbData.UISize.X, Y = tbData.UISize.Y}
        pWidgetSlot:SetAutoSize(true)
        pWidgetRef.imgSmallIcon.Slot:SetSize(UISize)
    end
    if tbData.szIcon then
        self:SetSmallIcon(tbData.szIcon)
    else
        self:SetSmallIcon()
    end
    if MiniMapSystem:GetMapSymbolVisible(tbData.nCategory) then
        self:ShowSmallIcon(true)
    else
        self:ShowSmallIcon(false)
    end
    self:SetName(tbData.szName)
    --self:SetIcon(tbData.szIcon)
    self:SetIcon(nil)
    SetNameFontSize(self)
end

function UPMapObjForFFAStaticPoint:ShowSmallIcon(bShow)
    local pVisibility = bShow and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Collapsed
    self.pWidgetRef.imgSmallIcon:SetVisibility(pVisibility)
    -- if bShow then
    --     self:SetSmallIcon(self.tbData.szIcon)
    -- else
    --     self:SetSmallIcon()
    -- end
    
end

return UPMapObjForFFAStaticPoint
