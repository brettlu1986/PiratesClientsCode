-----------------------------------------------------
--File Name    : UPMapObjForBotPoint.lua
--Author       : Chen Jing
--Create Time  : 2019-05-06
--Description  : 用于在地图上标识Bot
-----------------------------------------------------

local luaclass = require ("luaclass")
local UPMapObj = require("UPMapObj")
local UPMapObjForBotPoint = luaclass("UPMapObjForBotPoint", UPMapObj)
--local UISetUtils    = require("UISetUtils")
local pDimension = Vector2D{X=16,Y=16}
local szIcon = "PaperSprite'/Game/UI/Textures/Common/Frames/Spr_RemindRed.Spr_RemindRed'"



function UPMapObjForBotPoint:ShowContent(tbData)
    self.bIsInUse = true
    self.pWidgetRef.cvsPosPanel:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    self:SetIcon(szIcon, pDimension)
    self:SetName(tbData.szTag)
    self.pWidgetRef.Slot:SetPosition(Vector2D{X = tbData.nX, Y = tbData.nY})
end

return UPMapObjForBotPoint

