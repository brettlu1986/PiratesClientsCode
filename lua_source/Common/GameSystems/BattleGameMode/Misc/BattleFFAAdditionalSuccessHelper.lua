local BattleFFAAdditionalSuccessHelper = {}

local BattleAdditionalSuccessResultDef = require("BattleAdditionalSuccessResultDef")
local BattleResultSystem = dynamic_require("BattleResultSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local NetworkManager = dynamic_require("NetworkManager")
local GameObjectTypeDef = require("GameObjectTypeDef")
local ProtoDC = require("DungeonCommonProtoNames")
local BotAISystem = dynamic_require("BotAISystem")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local Timer = require("Timer")

BattleFFAAdditionalSuccessHelper.bEnable = false                       -- 是否启用额外胜利
BattleFFAAdditionalSuccessHelper.tbPlayerAdditionalScoreData = nil     -- 玩家额外胜利分数数据
BattleFFAAdditionalSuccessHelper.nAdditionalSuccessRemainCount = 100   -- 额外胜利剩余名额
BattleFFAAdditionalSuccessHelper.nMaxSuccessTeamCount = 5              -- 最多允许同时获胜的队伍数量
BattleFFAAdditionalSuccessHelper.bNotifyChoice = false                 -- 是否已经通过客户端做选择
BattleFFAAdditionalSuccessHelper.nPlayerChoiceBuffId = 33002           -- 做选择时的buffid
BattleFFAAdditionalSuccessHelper.nExitBattleBuffId = 33001             -- 退出竞赛的buffid
BattleFFAAdditionalSuccessHelper.nChoiceTime = 10                      -- 做选择时的时间
BattleFFAAdditionalSuccessHelper.tbAdditionalSuccessTimers = nil       -- 等待额外胜利选择的计时器

local function ClearAdditionalSuccessTimer(self)
    for _,v in pairs(self.tbAdditionalSuccessTimers) do
        if v then
            v:Clear()
        end
    end

    self.tbAdditionalSuccessTimers = nil
end

function BattleFFAAdditionalSuccessHelper:Init()
    self.tbPlayerAdditionalScoreData = {}
    self.tbAdditionalSuccessTimers   = {}
    EventManager:BindEventMethod(CommonEventDef.EV_ADDITIONALSUCCESS_CHOICE , self, self.OnAdditionalSuccessClientChoice)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_TEAM_BATTLE_END , self, self.OnTeamBattleEnd)
    EventManager:BindEventMethod(CommonEventDef.EV_ADDITIONALSUCCESS_ENABLE , self, self.OnEnable)
end

function BattleFFAAdditionalSuccessHelper:Uninit()
    EventManager:UnBindEventMethod(CommonEventDef.EV_ADDITIONALSUCCESS_CHOICE , self, self.OnAdditionalSuccessClientChoice)
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_TEAM_BATTLE_END , self, self.OnTeamBattleEnd)
    EventManager:UnBindEventMethod(CommonEventDef.EV_ADDITIONALSUCCESS_ENABLE , self, self.OnEnable)
    ClearAdditionalSuccessTimer(self)
    self.bNotifyChoice = false
end

--尝试逃出升天
local function TryExitBattleForAdditonalSuccess(self, tbPlayer)
    if self.nAdditionalSuccessRemainCount > 0 then
        self.nAdditionalSuccessRemainCount = self.nAdditionalSuccessRemainCount -1
        EventManager:OnFireEvent(CommonEventDef.EV_ADDITIONALSUCCESS_COUNT_UPDATE, self.nAdditionalSuccessRemainCount)
        log("TryExitBattleForAdditonalSuccess RemainCount:",self.nAdditionalSuccessRemainCount)

        self:ProcessAdditionalSucessResult(tbPlayer, 0, true)

        EventManager:OnFireEvent(CommonEventDef.EV_ADDITIONALSUCCESS_RESULT, BattleAdditionalSuccessResultDef.EXIT_BATTLE, tbPlayer)

    else
        EventManager:OnFireEvent(CommonEventDef.EV_ADDITIONALSUCCESS_RESULT, BattleAdditionalSuccessResultDef.WANT_EXIT_BUT_COUNT_NOT_ENOUGH, tbPlayer)
    end
end

local function OnRemoveChoiceBuff(self, tbPlayer)
    tbPlayer.BuffComponentServer:RemoveBuffById(self.nPlayerChoiceBuffId)
end

--尝试继续战斗
local function TryFightForAdditonalSuccess(self, tbPlayer)
    EventManager:OnFireEvent(CommonEventDef.EV_ADDITIONALSUCCESS_RESULT, BattleAdditionalSuccessResultDef.FIGHTING, tbPlayer)
end

function BattleFFAAdditionalSuccessHelper:OnAdditionalSuccessClientChoice(tbPlayer, tbPacket)
    local nInstanceId = tbPlayer:GetServerInstanceId()
    local bPlayerBattleEnd  = BattleResultSystem:IsPlayerBattleEnd(nInstanceId)

    if self.tbAdditionalSuccessTimers[nInstanceId] and not bPlayerBattleEnd and self.bNotifyChoice then
        self.tbAdditionalSuccessTimers[nInstanceId]:Clear()
        self.tbAdditionalSuccessTimers[nInstanceId] = nil

        OnRemoveChoiceBuff(self, tbPlayer)

        if tbPacket.nASResult == ProtoDC.c2d_AdditionalSuccessChoice_EASResultType.EXIST_BATTLE then
            TryExitBattleForAdditonalSuccess(self,tbPlayer)
        end

        if tbPacket.nASResult == ProtoDC.c2d_AdditionalSuccessChoice_EASResultType.FIGHTING then
            TryFightForAdditonalSuccess(self,tbPlayer)
        end
    end
end

function BattleFFAAdditionalSuccessHelper:OnTeamBattleEnd(nTeamId, nTeamRank)
    if nTeamRank <= (self.nMaxSuccessTeamCount + 1) and not self.bNotifyChoice and self.bEnable then
        self.bNotifyChoice = true

        local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)

        for Object, _ in pairs(tbObjects) do
            local nInstanceId = Object:GetServerInstanceId()
            local bPlayerBattleEnd  = BattleResultSystem:IsPlayerBattleEnd(nInstanceId)
            if not bPlayerBattleEnd and not BotAISystem:IsBot(Object) then
                local tbPlayer = Object
                --给玩家加上buff
                tbPlayer.BuffComponentServer:AddBuffById(self.nPlayerChoiceBuffId, 1)
                --通知玩家做选择
                self:TryAdditionSuccess(tbPlayer, self.nChoiceTime)
            end
        end
    end
end

function BattleFFAAdditionalSuccessHelper:OnEnable(bEnable)
    self.bEnable = bEnable
end

local function OnAdditionalSuccessTimerEnd(self, nInstanceId)
    self.tbAdditionalSuccessTimers[nInstanceId]:Clear()
    self.tbAdditionalSuccessTimers[nInstanceId] = nil

    local tbPlayer = GameObjectSystem:FindByInstanceId(nInstanceId)
    local bPlayerBattleEnd  = BattleResultSystem:IsPlayerBattleEnd(nInstanceId)
    if tbPlayer and not bPlayerBattleEnd then
        OnRemoveChoiceBuff(self, tbPlayer)
        --计时用完没有选择默认让其继续战斗
        TryFightForAdditonalSuccess(self,tbPlayer)
    end
end

--[[
    1. 先尝试判断是否还有剩余额外人数
    2. 如果有，则给玩家发送选择通知，ds启动计时器记录
    3. 如果没有，发送事件说明已经没有名额了
]]
function BattleFFAAdditionalSuccessHelper:TryAdditionSuccess(tbPlayer , nCDTime)
    local bRet = nil
    local nInstanceId = tbPlayer:GetServerInstanceId()
    local bBattleEnd = BattleResultSystem:IsPlayerBattleEnd(nInstanceId)        
    if not bBattleEnd then
        if self.nAdditionalSuccessRemainCount and
           self.nAdditionalSuccessRemainCount > 0 then
             local tbPacket = {}
             tbPacket.nCDTime = nCDTime

             NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_AdditionalSuccessChoice, tbPacket)

             if not self.tbAdditionalSuccessTimers[nInstanceId] then
                 local fnTimerEnd = function()
                    OnAdditionalSuccessTimerEnd(self, nInstanceId)
                 end
                 self.tbAdditionalSuccessTimers[nInstanceId] = Timer.NewTimer(fnTimerEnd,nCDTime,false)
             end
             bRet = true
        else
            EventManager:OnFireEvent(CommonEventDef.EV_ADDITIONALSUCCESS_RESULT, BattleAdditionalSuccessResultDef.REMAIN_COUNT_NOT_ENOUGH, tbPlayer)
            bRet = false
        end
    end

    return bRet
end

function BattleFFAAdditionalSuccessHelper:SetAdditionSuccessCount(nASCount)
    self.nAdditionalSuccessRemainCount = nASCount
    EventManager:OnFireEvent(CommonEventDef.EV_ADDITIONALSUCCESS_COUNT_UPDATE, self.nAdditionalSuccessRemainCount)
end

--Return True: 成功处理完毕 False: 失败
function BattleFFAAdditionalSuccessHelper:ProcessAdditionalSucessResult(tbPlayer, nAdditionalAward, bStopGame)
    log("ProcessAdditionalSucessResult name:",tbPlayer.szName)
    --先给这个队伍的玩家增加额外分
    --local nTeamId = BattleTeamSystem:FindTeamId(tbPlayer)
    local nInstanceId = tbPlayer:GetServerInstanceId()
    if self.tbPlayerAdditionalScoreData[nInstanceId] == nil then
        self.tbPlayerAdditionalScoreData[nInstanceId] = 0
    end

    self.tbPlayerAdditionalScoreData[nInstanceId] = self.tbPlayerAdditionalScoreData[nInstanceId] + nAdditionalAward

    local tbASResultPacket = {
        nASResult = ProtoDC.d2c_AdditionalSuccessResult_EASResultType.FIGHTING,
    }

    if bStopGame then
        tbASResultPacket.nASResult = ProtoDC.d2c_AdditionalSuccessResult_EASResultType.EXIST_BATTLE
        tbPlayer.BuffComponentServer:AddBuffById(self.nExitBattleBuffId, 1)
    end

    NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_AdditionalSuccessResult, tbASResultPacket)

    --如果需要StopGame则需要给客户端发送协议，同时也需要发送数据给Lobby
    --如果当前这个队伍已经额外胜利并且通知退出游戏，则将该队伍加入到额外胜利组的表中，其他队伍是否吃鸡判断需要剔除掉该队伍
--[[ todo 代码整理需要，先暂时禁用下，如果将来需要额外胜利，再打开这里
    if bStopGame then
        --相当于移除，计数-1
        local nPlayerRank = 1
        UpdateAlivePlayerCount(self)
        tbPlayer.BuffComponentServer:RemoveAllBuff()

        local bTeamDead= self:TryGetTeamRankAfterPlayerBattleEnd(tbPlayer)
        SavePlayerResultData(self, tbPlayer, bTeamDead, true, nPlayerRank, nTeamId)

        local tbWinPacket = {}
        -- 队伍数据
        tbWinPacket.nMode = self.nTeamModeId
        tbWinPacket.bTeamDead = bTeamDead
        tbWinPacket.nTeamRank = 1
        tbWinPacket.nPlayerCount = self.nPlayerCount
        tbWinPacket.nTeamCount  = self.nTeamCount

        tbWinPacket.FFATeamResult = {}
        local tbTeamdata = tbPlayer.BattleTeamComponent.tbTeamdata
        for _, tbData in ipairs(tbTeamdata) do
            local nPlayerInstanceId = tbData.nInstanceId
            local tbGameObject = GameObjectSystem:FindByInstanceId(nPlayerInstanceId)
            if nInstanceId ~= nPlayerInstanceId then
                SavePlayerResultData(self, tbGameObject, bTeamDead, false, nPlayerRank, nTeamId)
            end
            local tbResultData = BattleResultSystem:GetPlayerResultData(nPlayerInstanceId)
            if tbResultData then
                table.insert(tbWinPacket.FFATeamResult, tbResultData)
            end
        end

        local nMVPInstanceId, nMVPPlayerId = self:GetTeamMVP(tbPlayer)
        if bTeamDead then
            tbWinPacket.nMVPInstanceId = nMVPInstanceId
            tbWinPacket.nMVPPlayerId = nMVPPlayerId
        end

        NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_FFAKillBossResult, tbWinPacket)

        if bTeamDead then
            --TODO 队友1先死亡然后观战我，我逃出升天，队伍排名是第一名，如果这数据同步给队友的话，队友结算会变成"称王"
            --如果不同步会导致队友的结算数据是旧的 这是策划设计上的问题
            --WatchPlayerResult(tbPlayer,tbWinPacket)
            BattleFFAD2SStatisticHelper:SendTeamStatisticsDataToLobby(tbTeamdata, nTeamId, 1, nMVPPlayerId, self.nPlayerCount, self.nTeamCount)
        end

        --最后进行吃鸡判定
        PlayerWin(self)

        MarkPlayerBattleEnd(self,tbPlayer)
    end
]]
    return true
end

function BattleFFAAdditionalSuccessHelper:GetPlayerAdditionalScoreByInstanceId(nPlayerInstanceId)
    return self.tbPlayerAdditionalScoreData[nPlayerInstanceId] and self.tbPlayerAdditionalScoreData[nPlayerInstanceId] or 0
end

return BattleFFAAdditionalSuccessHelper