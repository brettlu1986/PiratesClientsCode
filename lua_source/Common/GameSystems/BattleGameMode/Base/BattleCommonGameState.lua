local luaclass = require("luaclass")
local BattleGameStateBase = require("BattleGameStateBase")
local BattleCommonGameState = luaclass("BattleCommonGameState", BattleGameStateBase)

local Proto = require("DungeonRepProtoNames")
local CampDefine = require("CampDefine")
local CampSystem = require("CampSystem")
local BaseUtil = require("BaseUtil")

local function InitBPCampMatrix(self)
    local pGameState = self.pGameState
    local nCampCount = BaseUtil:GetTableCount(CampDefine.Type)
    local tbCampMatrix = {}
    for i=0, (nCampCount - 1) do
        for j=0, (nCampCount - 1) do
            table.insert(tbCampMatrix,CampSystem:GetRelation(i, j) == CampDefine.Relation.RELATION_FRIEND)
        end
    end
    pGameState:SetCampRelationMatrix(nCampCount, tbCampMatrix)
end

function BattleCommonGameState:Init(pGameState)
    BattleCommonGameState.super.Init(self, pGameState)
    InitBPCampMatrix(self)
end

function BattleCommonGameState:DefineProperties()
    BattleCommonGameState.super.DefineProperties(self)

    self:DefineProtoProperty(Proto.rCurrentStatisticsDatas)
    local rCurrentObjective = self:DefineProtoProperty(Proto.rCurrentObjective)
    rCurrentObjective.nStepId = 0

    self:DefineProtoProperty(Proto.rNeededResources)
    self:DefineProtoProperty(Proto.rTargetTrackInfoAndIsShow)
    self:DefineProtoProperty(Proto.rBattleSpecialToast)
    self:DefineProtoProperty(Proto.rBattleNpcInteraction)
    
    self:DefineProtoProperty(Proto.rBotInfo)
    
end

function BattleCommonGameState:DefineStepIds()
    BattleCommonGameState.super.DefineStepIds(self)
end

return BattleCommonGameState