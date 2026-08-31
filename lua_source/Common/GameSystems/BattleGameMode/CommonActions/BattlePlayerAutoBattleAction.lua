local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattlePlayerAutoBattleAction = luaclass("BattlePlayerAutoBattleAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")

BattlePlayerAutoBattleAction.bEnable = false

function BattlePlayerAutoBattleAction:Parse(tbJsonData)
    self.bEnable = tbJsonData.Enable
    self.nAIId = tbJsonData.AIId ~= nil and tbJsonData.AIId or 0
    self.nPathId = tbJsonData.PathId ~= nil and tbJsonData.PathId or 0
    return true
end

function BattlePlayerAutoBattleAction:Execute()
    BattleOperationHelper:PrintLog(self,
        "Enable: "..(self.bEnable ~= nil and tostring(self.bEnable) or "nil")..
        ", AIId: "..self.nAIId..
        ", PathId: "..self.nPathId)

    local AIComponent = nil
    local nAIId = self.nAIId
    local nPathId = self.nPathId
    local bNewEnable = self.bEnable
    local tbAll = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    local bOldEnable = false
    
    for Object, _ in pairs(tbAll) do
        AIComponent = Object.BattleAIComponent
        if(AIComponent) then
            bOldEnable = AIComponent.bEnable
            if(nAIId > 0) then
                AIComponent.nAIId = nAIId
                AIComponent:DestroyAI() -- AIid改了强制重新生成ai
            end
            if(nPathId > 0) then
                AIComponent.nPathId = nPathId
            end

            if(bNewEnable ~= nil) then
                AIComponent:SetEnable(bNewEnable)
            elseif(bOldEnable) then
                AIComponent:SetEnable(bOldEnable)
            end
        end
    end

    return true
end

return BattlePlayerAutoBattleAction