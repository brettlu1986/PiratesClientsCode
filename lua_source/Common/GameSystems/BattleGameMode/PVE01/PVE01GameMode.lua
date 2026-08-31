local luaclass = require("luaclass")
local BattleGameModeBaseClass = dynamic_require("BattleCommonGameMode")
local PVE01GameMode = luaclass("PVE01GameMode", BattleGameModeBaseClass)

local BattlePlayerResultStepClass = dynamic_require("BattlePVEResultStep")
local BattleMatineeStepClass = require("BattleMatineeStep")
local PVE01BattleStep = require("PVE01BattleStep")
local PVE01DataTable = require("PVE01DataTable")
local DungeonQuitDialogType = require("DungeonQuitDialogType")

PVE01GameMode.tbFreePlayerStartList = nil   -- 未使用的玩家开始位置
PVE01GameMode.tbUsedPlayerStartList = nil   -- 已使用的玩家开始位置

local function AddSteps(self, tbTemplateData, tbGameState)    
    local tbStep = nil
--[[
    -- 进入场景动画
    local nEnterSceneMatineeId = tbTemplateData.nEnterSceneMatineeId
    if nEnterSceneMatineeId ~= -1 then
        tbStep = self:CreateStep(BattleMatineeStepClass, tbGameState.nEnterSceneMatineeId)
        tbStep:SetParams(nEnterSceneMatineeId)
    end
]]
    -- Boss出场动画
--    local nBossBornMatineeId = tbTemplateData.nBossBornMatineeId

    -- 针对这个玩法，我们战斗只分一个step，三波怪，分多个target
    -- 因为该玩法不能做成一波怪一个step，因为目前step的设计为当一个setp全部结束后才能走到下一个setp
    -- 但是该玩法里不是这样的
    local fnGetPlayerStartJsonData = function (GamePlayer)
        return self:FindPlayerStartJsonData(GamePlayer)
    end
    tbStep = self:CreateStep(PVE01BattleStep, tbGameState.nBattleStepId)
    tbStep:SetParams(tbGameState, tbTemplateData, self.tbJsonTableFile, fnGetPlayerStartJsonData)
    
    -- Boss死亡动画
    local nBossDieMatineeId = tbTemplateData.nBossDieMatineeId
    if nBossDieMatineeId ~= -1 then
        tbStep = self:CreateStep(BattleMatineeStepClass, tbGameState.nBossDieMatineeId)
        tbStep:SetParams(nBossDieMatineeId)
    end

    -- 战斗结算阶段
    tbStep = self:CreateStep(BattlePlayerResultStepClass, tbGameState.nShowResultStepId)
    tbStep:SetParams(tbGameState.rBattlePlayerResultStep, tbTemplateData.nShowResultTime, self.tbJsonTableFile)
end

function PVE01GameMode:Init(nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)
    PVE01GameMode.super.Init(self, nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)

    local tbTemplateData = PVE01DataTable:GetTemplate(nSubDungonId)
    if(tbTemplateData == nil) then
        logerror("PVE01GameMode init failed, can not find id : " .. nSubDungonId)
        return false
    end

    self.tbFreePlayerStartList = self.tbJsonTableFile.tbContainer.DungeonPlayerStarts
    self.tbUsedPlayerStartList = {}

    local function fnSort(a, b)
        return a.GroupIndex < b.GroupIndex
    end
    table.sort(self.tbFreePlayerStartList, fnSort)

    AddSteps(self, tbTemplateData, self.tbGameState)

    return true
end

function PVE01GameMode:Uninit()
    self.tbUsedPlayerStarts = nil
    PVE01GameMode.super.Uninit(self)
end

-- 自己死亡后重生
function PVE01GameMode:OnPostDestroyPlayerPawn(GamePlayerSelf)

end

function PVE01GameMode:FindPlayerStartJsonData(tbGamePlayer)
    local DEFAULT_PLAYER_START = 1
    if self.tbFreePlayerStartList == nil then
        error('PVE01GameMode:FindPlayerStartJsonData() tbFreePlayerStartList is nil.')
        return nil
    end

    local nFreePlayerStartCount = #self.tbFreePlayerStartList
    local nUsedPlayerStartCount = #self.tbUsedPlayerStartList
    if nFreePlayerStartCount == 0 and nUsedPlayerStartCount == 0 then
        error('PVE01GameMode:FindPlayerStartJsonData() nFreePlayerStartCount and nUsedPlayerStartCount both are zero.')
        return nil
    -- 这种情况有可能是重生
    elseif nFreePlayerStartCount == 0 and nUsedPlayerStartCount > 0 then
        for i, _ in ipairs(self.tbUsedPlayerStartList) do
            self.tbFreePlayerStartList[i] = self.tbUsedPlayerStartList[i]
        end
    end

    local tbNextFreePlayerStart = self.tbFreePlayerStartList[DEFAULT_PLAYER_START]

    table.remove(self.tbFreePlayerStartList, DEFAULT_PLAYER_START)
    table.insert(self.tbUsedPlayerStartList,  tbNextFreePlayerStart)

    return tbNextFreePlayerStart
end

function PVE01GameMode:GetQuitDungeonDialogType()
    log("PVE01GameMode:GetQuitDungeonDialogType")
    return DungeonQuitDialogType.PVE01
end

return PVE01GameMode
