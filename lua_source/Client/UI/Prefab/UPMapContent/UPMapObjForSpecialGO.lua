-----------------------------------------------------
--File Name    : UPMapObjForSpecialGO.lua
--Author       : WuJizhou
--Create Time  : 2018-8-13 11:07:32
--Description  : UPMapObjForSpecialGO
-----------------------------------------------------

local luaclass = require ("luaclass")
local UPMapObj = require("UPMapObj")
local UPMapObjForSpecialGO = luaclass("UPMapObjForSpecialGO", UPMapObj)


function UPMapObjForSpecialGO:ShowContent(tbData)
    self.bIsInUse = true
    self.tbData = tbData
    self.pWidgetRef.cvsPosPanel:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local pDimension = Vector2D{X=128,Y=108}
    self:SetIcon(tbData.szRes, pDimension, nil, false)
end

return UPMapObjForSpecialGO