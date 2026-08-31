--File Name    : UPMapObj.lua
-----------------------------------------------------
--Author       : Ran Jie
--Create Time  : 2016-12-23
--Description  : UPMapObj
-----------------------------------------------------

local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPMapObj = luaclass("UPMapObj", PrefabBase)

-- import require
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")


--member veriable
UPMapObj.bIsInUse = false
UPMapObj.tbData = nil
UPMapObj.szLastIcon = nil
UPMapObj.szLastSmallIcon = nil
UPMapObj.pLastSalteTintColor = nil

--member function
function UPMapObj:ShowContent(tbData)
    self.bIsInUse = true
    self.tbData = tbData
    if(self.pWidgetRef == nil) then
        return
    end
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.cvsPosPanel:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    if pWidgetRef.imgSmallIcon then
        pWidgetRef.imgSmallIcon:SetVisibility(ESlateVisibility_Collapsed)
    end
    self:SetIcon(tbData.szIcon, tbData.Dimension, tbData.SlateColor, tbData.bMatchSize)
    self:SetName(tbData.szName)
    local pWidgetSlot = pWidgetRef.Slot
    if tbData.UILocation then
        local UIPos = Vector2D{X = tbData.UILocation.X, Y = tbData.UILocation.Y}
        pWidgetSlot:SetPosition(UIPos)
    end
    if tbData.UIRotation then
        self.pWidgetRef:SetRenderTransformAngle(tbData.UIRotation)
    else
        self.pWidgetRef:SetRenderTransformAngle(0)
    end
    pWidgetSlot:SetAutoSize(true)
    if tbData.UISize then
        local UISize = Vector2D{X = tbData.UISize.X, Y = tbData.UISize.Y}
        --pWidgetSlot:SetAutoSize(true)
        --pWidgetRef.imgIcon.Slot:SetHorizontalAlignment(EHorizontalAlignment.HAlign_Fill)
        --pWidgetRef.vboxObj.Slot:SetAutoSize(false)
        pWidgetRef.imgIcon.Slot:SetAutoSize(false)
        pWidgetRef.imgIcon.Slot:SetSize(UISize)
    else
        pWidgetRef.imgIcon.Slot:SetAutoSize(true)
    end
end

function UPMapObj:HideContent()
    self.bIsInUse = false
    self.tbData = nil
    if(self.pWidgetRef == nil) then
        return
    end
    self.pWidgetRef.cvsPosPanel:SetVisibility(ESlateVisibility.Collapsed)
end

function UPMapObj:SetIcon(szIcon, pDimension, pSlateColor, bMatchSize)
    if szIcon and szIcon ~= "" then
        self.pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.Collapsed)
        return
    end

    if pSlateColor and pSlateColor ~= self.pLastSalteTintColor then
        self.pLastSalteTintColor = pSlateColor
        UISetUtils.SetImageBrushTint(self.pWidgetRef.imgIcon, pSlateColor)
    elseif not pSlateColor and self.pLastSalteTintColor ~= UIResourceDef.COLOR.WHITE.SLATE_COLOR then
        self.pLastSalteTintColor = UIResourceDef.COLOR.WHITE.SLATE_COLOR
        UISetUtils.SetImageBrushTint(self.pWidgetRef.imgIcon, self.pLastSalteTintColor)
    end

    if self.szLastIcon ~= szIcon then
        self.szLastIcon = szIcon
        UISetUtils.SetAsyncImageBrushFromSprite(self.pWidgetRef.imgIcon, szIcon, pDimension, bMatchSize)
    end
end

function UPMapObj:SetSmallIcon(szIcon, pDimension, pSlateColor, bMatchSize)
    if szIcon and szIcon ~= "" then
        self.pWidgetRef.imgSmallIcon:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    else
        self.pWidgetRef.imgSmallIcon:SetVisibility(ESlateVisibility_Hidden)
        return
    end

    if pSlateColor then
        UISetUtils.SetImageBrushTint(self.pWidgetRef.imgSmallIcon, pSlateColor)
    end
    if self.szLastSmallIcon ~= szIcon then
        self.szLastSmallIcon = szIcon
        UISetUtils.SetAsyncImageBrushFromSprite(self.pWidgetRef.imgSmallIcon, szIcon, pDimension, bMatchSize)
    end
end

function UPMapObj:SetName(szName)
    if szName and szName ~= "" then
        self.pWidgetRef.hboxCity:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.pWidgetRef.txtObjName:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.pWidgetRef.txtObjName:SetText(szName)
    else
        self.pWidgetRef.hboxCity:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPMapObj:GetUseState()
    return self.bIsInUse
end

function UPMapObj:SetUseState(bUse)
    self.bIsInUse = bUse
end


return UPMapObj
