local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleChangeNpcAIAction = luaclass("BattleChangeNpcAIAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleNpcHelper = require("BattleNpcHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")

BattleChangeNpcAIAction.szTimerName = nil
BattleChangeNpcAIAction.fTime = 0

function BattleChangeNpcAIAction:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    self.nAIId = tbJsonData.AIId
    self.nPathId = tbJsonData.PathId
    return true
end

function BattleChangeNpcAIAction:Execute()
    BattleOperationHelper:PrintLog(self, BattleNpcHelper:GetIdentifierInfo(self) ..
        ", AIId: "..self.nAIId..", PathId: "..self.nPathId)

    local AIComponent
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    for nId, Object in pairs(tbObjects) do
        if(BattleNpcHelper:CheckIdentifier(self, Object)) then
            AIComponent = Object.BattleAIComponent
            if(AIComponent) then
                AIComponent:DestroyAI()
                AIComponent:CreateAI(self.nAIId, self.nPathId)
            end
        end
    end

    return true
end

return BattleChangeNpcAIAction