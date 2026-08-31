-----------------------------------------------------
--Author       : Ran Jie
--Create Time  : 2019-01-29
--Description  : UPFFAFlagPoint
-----------------------------------------------------

local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPFFAFlagPoint = luaclass("UPFFAFlagPoint", PrefabBase)

-- import require
local UIResourceDef = require("UIResourceDef")


--member veriable
UPFFAFlagPoint.bIsInUse = false
UPFFAFlagPoint.tbData = nil
UPFFAFlagPoint.szLastIcon = nil 
UPFFAFlagPoint.pLastSalteTintColor = nil

--member function
function UPFFAFlagPoint:ShowContent(tbData)
    self.bIsInUse = true
    self.tbData = tbData
    if(self.pWidgetRef == nil) then
        return
    end
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local pLinearColor = UIResourceDef.TEAM_INDEX_COLOR[tbData.nIndex]
    if not pLinearColor then
        log("UPFFAFlagPoint:SetData no color index, use default, index, ", tbData.nIndex)
        pLinearColor = UIResourceDef.COLOR.WHITE.LINEAR_COLOR
    end
    pWidgetRef.imgNaviEnd:SetColorAndOpacity(pLinearColor)
    if tbData.UILocation then
        local UIPos = Vector2D{X = tbData.UILocation.X, Y = tbData.UILocation.Y}
        self.pWidgetRef.Slot:SetPosition(UIPos)
    end
    if tbData.UIRotation then
        self.pWidgetRef:SetRenderTransformAngle(tbData.UIRotation)
    else
        self.pWidgetRef:SetRenderTransformAngle(0)
    end
end

function UPFFAFlagPoint:HideContent()
    self.bIsInUse = false
    self.tbData = nil
    if(self.pWidgetRef == nil) then
        return
    end    
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end

function UPFFAFlagPoint:GetUseState()
    return self.bIsInUse
end


---------------

return UPFFAFlagPoint
