local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleNpcMoveToAction = luaclass("BattleNpcMoveToAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleNpcHelper = require("BattleNpcHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")

BattleNpcMoveToAction.nPathId = nil

function BattleNpcMoveToAction:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    self.nPathId = tbJsonData.PathId
    return true
end

function BattleNpcMoveToAction:Execute()
    BattleOperationHelper:PrintLog(self, BattleNpcHelper:GetIdentifierInfo(self) ..
        ", PathId: "..self.nPathId)

    local pFinder = CommonShell.GetCommon(GWorld):GetPathNodeFinder()
    if pFinder then
        local bRet, pLocation = pFinder:FindPathNodeLocation(self.nPathId, 0) --todo 目前仅拿第一个，将来如果有别的需求再修改。

        if bRet then
            local tbObjects = GameObjectSystem:GetAllGameObjects()
            for nId, Object in pairs(tbObjects) do
                if(BattleNpcHelper:CheckIdentifier(self, Object)) then
                    local tbNPC = Object
                    local pUEActor = tbNPC.pUEActor
                    if pUEActor then
                        local tbParam = {pLocation}
                        pUEActor:SpawnDefaultController()
                        pUEActor:DirectNavMove(tbParam, 5)
                    end
                end
            end
        end
    end

    return true
end

return BattleNpcMoveToAction