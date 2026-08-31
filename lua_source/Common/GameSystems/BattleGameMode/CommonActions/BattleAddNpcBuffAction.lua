-----------------------------------------------------
--File Name    : BattleAddNpcBuffAction.lua
--Author       : 
--Create Time  : 
--Description  : 添加npcbuff
-----------------------------------------------------

local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleAddNpcBuffAction = luaclass("BattleAddNpcBuffAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleNpcHelper = require("BattleNpcHelper")
local BattleBlackboard = require("BattleBlackboard")


BattleAddNpcBuffAction.nBuffId = nil
BattleAddNpcBuffAction.bRemoveBuff = nil
BattleAddNpcBuffAction.nOverlapCount = 0
BattleAddNpcBuffAction.szOverlapKey = nil


function BattleAddNpcBuffAction:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    self.nBuffId = tbJsonData.BuffId
    self.nOverlapCount = tbJsonData.OverlapCount
    self.szOverlapKey = tbJsonData.OverlapKey
    self.bRemoveBuff = tbJsonData.RemoveBuff
    return self.nBuffId > 0 
end

function BattleAddNpcBuffAction:Execute()
    BattleOperationHelper:PrintLog(self,
        ", BuffId: "..self.nBuffId..
        ", OverlapCount: "..self.nOverlapCount..
        ", OverlapKey: "..(self.szOverlapKey or "nil")..
        ", RemoveBuff: "..(self.bRemoveBuff and "true" or "false")..
        ", Tag: " ..(self.szTag and self.szTag or "nil")..
        ", TemplateId: " ..(self.nTemplateId and self.nTemplateId or "nil")..
        ", Group: " ..(self.nGroupIndex and self.nGroupIndex or "nil")..
        ", CampType: " ..(self.nCampType and self.nCampType or "nil"))
    
    local nOverlapCount = 1
    if self.nOverlapCount > 1 then 
        nOverlapCount = self.nOverlapCount
    elseif self.szOverlapKey and string.len(self.szOverlapKey) > 0 then
        local nOverlapKey = BattleBlackboard:GetNumber(self.szOverlapKey)
        if nOverlapKey > 1 then
            nOverlapCount = nOverlapKey
        end 
    end
    
    if(not self.bRemoveBuff) then
        local tbObjects = GameObjectSystem:GetAllGameObjects()
        for nId, Object in pairs(tbObjects) do
            if( BattleNpcHelper:CheckIdentifier(self, Object))  then
                Object.BuffComponentServer:AddBuffById(self.nBuffId, nOverlapCount)
            end
        end
    else
        local tbObjects = GameObjectSystem:GetAllGameObjects()
        for nId, Object in pairs(tbObjects) do
            if( BattleNpcHelper:CheckIdentifier(self, Object))  then
                Object.BuffComponentServer:RemoveBuffById(self.nBuffId)
            end
        end
    end

    return true
end

return BattleAddNpcBuffAction

