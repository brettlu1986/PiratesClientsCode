local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSetCaptureFlagInfoAction = luaclass("BattleSetCaptureFlagInfoAction", BattleActionBase)

local GameObjectSystem = dynamic_require("GameObjectSystem")
-- local SpawnerSystem = require("SpawnerSystem")
-- local GameObjectTypeDef = require("GameObjectTypeDef")
-- local SpawnerDef = require("SpawnerDef")
-- local BattleDummyHelper = require("BattleDummyHelper")
local BattleOperationHelper = require("BattleOperationHelper")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

BattleSetCaptureFlagInfoAction.nCampType = false        
BattleSetCaptureFlagInfoAction.nCaptureFlagState = 0               

function BattleSetCaptureFlagInfoAction:Parse(tbJsonData)
    self.nCampType = tbJsonData.CampType
    self.nCaptureFlagState = tbJsonData.CaptureFlagState
    return true
end

local function FindHolderInstanceId(nCampType)
    -- TODO:外面填
    local nBuffId = nCampType == 1 and 20007 or 20008
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    for k, v in pairs(tbObjects) do
        if(v.BuffComponentServer and not v:IsDead()) then
            if(v.BuffComponentServer:IsExistBuffById(nBuffId)) then
                return k
            end
        end
    end
    return nil
end

function BattleSetCaptureFlagInfoAction:Execute()
    BattleOperationHelper:PrintLog(self, 
        "CampType: "..self.nCampType..
        "State: "..self.nCaptureFlagState)

    local tbGameState = BattleGameModeSystem:GetGameState()
    local rBattleFlagState = tbGameState.rBattleFlagState
    if rBattleFlagState.tbStateInfos == nil then
        rBattleFlagState.tbStateInfos = { {nCampType = 0, nState = 0}, {nCampType = 0, nState = 0} }
    end
    local tbStateInfos = rBattleFlagState.tbStateInfos

    local bExist = false
    for _, tbState in ipairs(tbStateInfos) do
        if tbState.nCampType == self.nCampType or tbState.nCampType == 0 then
            tbState.nCampType = self.nCampType
            tbState.nState = self.nCaptureFlagState
            tbState.nHolderInstanceId = FindHolderInstanceId(self.nCampType)
            bExist = true
            break
        end
    end

    if not bExist then
        local StateInfo = {}
        StateInfo.nCampType = self.nCampType
        StateInfo.nState = self.nCaptureFlagState
        StateInfo.nHolderInstanceId = FindHolderInstanceId(self.nCampType)
        table.insert(tbStateInfos, StateInfo)        
    end

    rBattleFlagState.Rep()
    return true

end


return BattleSetCaptureFlagInfoAction