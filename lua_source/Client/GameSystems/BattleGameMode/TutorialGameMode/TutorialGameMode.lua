-- 新手副本
---------------------------------------------------------------------------------------
-- require

local luaclass = require("luaclass")
local BattleGameModeBaseClass = dynamic_require("BattleCommonGameMode")
local TutorialGameMode = luaclass("TutorialGameMode", BattleGameModeBaseClass)

local TutorialShip1BattleStepClass = require("TutorialShip1BattleStep")
local TutorialOctopusBattleStepClass = require("TutorialOctopusBattleStep")

local TutorialDataTable = require("TutorialDataTable")
-- local HandlerManagerHelper = require("HandlerManagerHelper")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local TutorialStep = require("TutorialStep")

---------------------------------------------------------------------------------------
-- local variable

------------------------------------------------------ 配置信息 begin

-- 玩家进入副本的入口
local nEnterStartGroupId = 0

------------------------------------------------------ 配置信息 end

local function FindPlayerNewJsonStart(self)
    local tbJsonStarts = self.tbJsonTableFile.tbContainer.DungeonPlayerStarts
    if(tbJsonStarts == nil) then
        error("TutorialGameMode:FindPlayerNewJsonStart failed")
        return
    end

    local nCount = #tbJsonStarts
    for i=1, nCount do
        local tbJson = tbJsonStarts[i]
        if tbJson.GroupIndex == nEnterStartGroupId then
            return tbJson
        end
    end
end

---------------------------------------------------------------------------------------
-- iface 

function TutorialGameMode:OnStartStep(tbGameStep)
    TutorialGameMode.super.OnStartStep(self, tbGameStep)
    -- HandlerManagerHelper:SwitchMode(Enum_HandlerMode.ShipCommonMode)
end

function TutorialGameMode:CreatePlayerSelf(tbPrepareInfo, pController, nControllerNetGuid, nControllerUniqueId)
    return TutorialGameMode.super.CreatePlayerSelf(self, tbPrepareInfo, pController, nControllerNetGuid, nControllerUniqueId)
end

function TutorialGameMode:Init(nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)
    TutorialGameMode.super.Init(self, nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)
    local tbTemplateData = TutorialDataTable:GetTemplate(nSubDungonId)
    if(tbTemplateData == nil) then
        logerror("TutorialGameMode init failed, can not find id", nSubDungonId)
        return false
    end
    nEnterStartGroupId = tbTemplateData.nEnterStartGroupId

    self:AddSteps(tbTemplateData, self.tbGameState)
    return true
end

function TutorialGameMode:SpawnPlayerPawn(tbGamePlayer, bPossess)
    TutorialGameMode.super.SpawnPlayerPawn(self, tbGamePlayer, bPossess)
end

function TutorialGameMode:AddSteps(tbTemplateData, tbGameState)
    local tbStep1 = self:CreateStep(TutorialShip1BattleStepClass, tbGameState.nTutorialShip1BattleId)
    tbStep1:SetParams(self.tbJsonTableFile, tbTemplateData.nShipGroupId1, tbTemplateData.nShipGroupIdJack)

    local tbStep2 = self:CreateStep(TutorialOctopusBattleStepClass, tbGameState.nTutorialOctopusBattleId)
    tbStep2:SetParams(self.tbJsonTableFile, tbTemplateData)
end

function TutorialGameMode:Uninit()
    TutorialGameMode.super.Uninit(self)
end

function TutorialGameMode:FindPlayerStartJsonData(tbGamePlayer)
    local tbJsonStart = FindPlayerNewJsonStart(self)
    if(tbJsonStart == nil) then
        error("TutorialGameMode:FindPlayerStartJsonData failed")
        return
    end

    return tbJsonStart
end

function TutorialGameMode:OnAllStepFinished()
    log("TutorialGameMode:OnAllStepFinished")
    TutorialGameMode.super.OnAllStepFinished()
    TutorialStep.STEP_IS_SKIP = false
    UIManager:CloseWnd(UIDef.UI_SKIP_GUIDE)
    UIManager:CloseWnd(UIDef.UI_BATTLE_MAIN)
    UIManager:OpenWnd(UIDef.UI_SET_PLAYER_NAME)
end

return TutorialGameMode