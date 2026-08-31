-----------------------------------------------------
--File Name    : UPMapObjForGOPath.lua
--Author       : WuJizhou
--Create Time  : 2018-8-13 11:07:32
--Description  : UPMapObjForGOPath
-----------------------------------------------------

local luaclass = require ("luaclass")
local UPMapObj = require("UPMapObj")
local UPMapObjForGOPath = luaclass("UPMapObjForGOPath", UPMapObj)

local PGB_SIZE_Y = 53

--tbData.tbPathInfo = {nStartPosX = , nStartPosY = , nEndPosX = , nEndPosY = }
function UPMapObjForGOPath:ShowContent(tbData)
    self.bIsInUse = true
    self.tbData = tbData
    self.pWidgetRef.cvsPosPanel:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if tbData.UILocation then
        local UIPos = Vector2D{X = tbData.UILocation.X, Y = tbData.UILocation.Y}
        self.pWidgetRef.Slot:SetPosition(UIPos)
    end
    local nDeltaX = tbData.UIStartX - tbData.UIEndX
    local nDeltaY = tbData.UIStartY - tbData.UIEndY
    local nDistance = math.sqrt (nDeltaX * nDeltaX + nDeltaY * nDeltaY)
    local pgbPath = self.pWidgetRef.pgbPath
    pgbPath.Slot:SetSize(Vector2D{X = nDistance, Y = PGB_SIZE_Y})
    self.pWidgetRef:SetRenderTransformAngle(tbData.UIRotation)
end

return UPMapObjForGOPath