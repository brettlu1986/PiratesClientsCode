local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSetFactionPointAction = luaclass("BattleSetFactionPointAction", BattleActionBase)
local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")
local BattleOperationDef = dynamic_require("BattleOperationDef")

BattleSetFactionPointAction.szTag = nil
BattleSetFactionPointAction.nPiont = nil

function BattleSetFactionPointAction:Parse(tbJsonData)
    self.szTag = tbJsonData.Tag
    self.nPiont = tbJsonData.Piont
    return true
end

function BattleSetFactionPointAction:Execute()
    BattleOperationHelper:PrintLog(self, "")
    
    local tbFactionPoint = BattleBlackboard:GetTable(BattleOperationDef.FactionPoint)
    if tbFactionPoint == nil then
        tbFactionPoint = {}
    end  
    tbFactionPoint[self.szTag] = self.nPiont
    BattleBlackboard:SetTable(BattleOperationDef.FactionPoint, tbFactionPoint)
    
    return true
end

return BattleSetFactionPointAction