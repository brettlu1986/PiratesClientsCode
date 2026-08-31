-----------------------------------------------------
--File Name    : BattleQuestSystem.lua
--Author       : LiHui
--Create Time  : 
--Description  : Battle任务系统
-----------------------------------------------------

local luaclass = require("luaclass")
local BattleQuestSystem = luaclass("BattleQuestSystem")

local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

--保持各个玩家当前的任务和进度
BattleQuestSystem.tbPlayerQuestState = {}
--保存当前所有的全局任务信息
BattleQuestSystem.tbAllGlobalQuest   = {}
--保存当前哪个任务是额外胜利任务
BattleQuestSystem.nAdditionalSuccessQuestId = nil
--保存额外胜利名额剩余人数
BattleQuestSystem.nAdditionalSuccessCount = 0

--判断是否已经有额外胜利任务，如果有，则直接将信息返回即可
--如果没有，随机一个额外胜利任务，然后广播出去
function BattleQuestSystem:SelectAdditionalSuccessQuest()
    if self.nAdditionalSuccessQuestId then
        return self.nAdditionalSuccessQuestId
    end

    --从全局任务中随机一个
    local nCount = #self.tbAllGlobalQuest
    if nCount <= 0 then
        return nil
    end

    local nRandIndex = math.random(1,nCount)
    self.nAdditionalSuccessQuestId = self.tbAllGlobalQuest[nRandIndex].nQuestId
    
    local tbPacket = {}
    tbPacket.nASQuestId = self.nAdditionalSuccessQuestId
    tbPacket.nASCount = self.nAdditionalSuccessCount
    NetworkManager:GetRPCNetworkProxy():Multicast(ProtoDC.d2c_AdditionalSuccessQuestInfo, tbPacket, false)

    return self.nAdditionalSuccessQuestId
end

--Return True or False
local function AddQuest(tbArr,nQuestId,tbQuestParamArr,tbDescParamArr)
    for _,value in pairs(tbArr) do
        if value.nQuestId == nQuestId then
            return false
        end
    end

    local tbCurQuest = {}
    tbCurQuest.nQuestId = nQuestId
    tbCurQuest.bComplete = false
    tbCurQuest.tbQuestParamArr = tbQuestParamArr
    tbCurQuest.tbDescParamArr = tbDescParamArr

    table.insert(tbArr,tbCurQuest)
    return true
end

--Return curQuest
local function UpdateQuest(tbArr,nQuestId,bComplete,tbQuestParamArr,tbDescParamArr)
    local tbCurQuest = nil

    for _,value in pairs(tbArr) do
        if value.nQuestId == nQuestId then
            tbCurQuest = value
            break
        end
    end

    if tbCurQuest then
        if not tbCurQuest.bComplete then
            tbCurQuest.bComplete = bComplete

            if tbQuestParamArr then
                tbCurQuest.tbQuestParamArr = tbQuestParamArr
            end

            if tbDescParamArr then
                tbCurQuest.tbDescParamArr = tbDescParamArr
            end
        else
            error("UpdateQuest nQuestId has Completed. nQuestId:",nQuestId)
        end
    else
        error("UpdateQuest nQuestId not found. nQuestId:",nQuestId)
    end

    return tbCurQuest
end

function BattleQuestSystem:CheckDoingQuestByPlayer(tbPlayer, nQuestId)
    local nPlayerId = tbPlayer:GetServerInstanceId()
    local tbArr = self.tbPlayerQuestState[nPlayerId]

    if tbArr then
        for _,value in pairs(tbArr) do
            if value.nQuestId == nQuestId then
                return not value.bComplete
            end
        end
    end

    return false
end

--添加全局任务，将此全局任务广播出去;
--给当前已经记录的玩家加上全局任务;
function BattleQuestSystem:AddGlobalQuest(nQuestId,tbQuestParamArr,tbDescParamArr)
    local bFound = false
    for _,value in pairs(self.tbAllGlobalQuest) do
        if value.nQuestId == nQuestId then
            bFound = true
            break
        end
    end

    if bFound then
        error("AddGlobalQuest Error.nQuestId has existed. nQuestId:",nQuestId)
        return
    end

    local tbCurQuestState = {}
    tbCurQuestState.nQuestId        = nQuestId
    tbCurQuestState.tbQuestParamArr = tbQuestParamArr
    tbCurQuestState.tbDescParamArr  = tbDescParamArr
    table.insert(self.tbAllGlobalQuest,tbCurQuestState)

    for _,v in pairs(self.tbPlayerQuestState) do
        AddQuest(v,nQuestId,tbQuestParamArr,tbDescParamArr)
    end

    local tbPacket = {}
    tbPacket.Type = ProtoDC.d2c_ProcessQuest_EPQuestType.ADD_QUEST
    tbPacket.nQuestId = nQuestId
    tbPacket.QuestParamArr = tbQuestParamArr
    tbPacket.DescParamArr = tbDescParamArr

    NetworkManager:GetRPCNetworkProxy():Multicast(ProtoDC.d2c_ProcessQuest, tbPacket, false)
end

--个人任务，仅仅是本人的任务
--发送给该玩家新增任务
function BattleQuestSystem:AddPrivateQuest(tbPlayer,nQuestId,tbQuestParamArr,tbDescParamArr)
    local nPlayerId = tbPlayer:GetServerInstanceId()

    local curArr = {}
    if self.tbPlayerQuestState[nPlayerId] ~= nil then
        curArr = self.tbPlayerQuestState[nPlayerId]
    else
        self.tbPlayerQuestState[nPlayerId] = curArr
    end

    local bRet = AddQuest(curArr,nQuestId,tbQuestParamArr,tbDescParamArr)

    if bRet then
        local tbPacket = {}
        tbPacket.Type = ProtoDC.d2c_ProcessQuest_EPQuestType.ADD_QUEST
        tbPacket.nQuestId = nQuestId
        tbPacket.QuestParamArr = tbQuestParamArr
        tbPacket.DescParamArr = tbDescParamArr
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(),ProtoDC.d2c_ProcessQuest,tbPacket)
    end
end

--更新任务进度信息;将进度信息同步给指定玩家
function BattleQuestSystem:UpdateQuestProgress(tbPlayer,nQuestId,bComplete,tbDescParamArr)
    local nPlayerId = tbPlayer:GetServerInstanceId()
    local curArr = self.tbPlayerQuestState[nPlayerId]
    if curArr == nil then
        error("UpdateQuestProgress error.")
        return false
    end

    local tbCurQuest = UpdateQuest(curArr,nQuestId,bComplete,nil,tbDescParamArr)

    if tbCurQuest then
        local tbPacket = {}
        tbPacket.Type = ProtoDC.d2c_ProcessQuest_EPQuestType.UPDATE_QUEST

        if tbCurQuest.bComplete then
            tbPacket.Type = ProtoDC.d2c_ProcessQuest_EPQuestType.COMPLETE_QUEST
        end
        tbPacket.nQuestId = nQuestId
        tbPacket.QuestParamArr = tbCurQuest.tbQuestParamArr
        tbPacket.DescParamArr = tbCurQuest.tbDescParamArr
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(),ProtoDC.d2c_ProcessQuest,tbPacket)
    end
end

--发送给新登录的玩家所有的全局任务;
local function OnPlayerPostLogin(self, tbPlayer)
    local nPlayerId = tbPlayer:GetServerInstanceId()

    
    local curArr = {}
    if self.tbPlayerQuestState[nPlayerId] ~= nil then
        curArr = self.tbPlayerQuestState[nPlayerId]
    else
        self.tbPlayerQuestState[nPlayerId] = curArr
    end

    --todo 需要处理重连进去玩家发送信息的细节，先保证不崩溃再说
    for _,value in pairs(self.tbAllGlobalQuest) do
        local bRet = AddQuest(curArr,value.nQuestId,value.tbQuestParamArr,value.tbDescParamArr)

        if bRet then
            local tbPacket = {}
            tbPacket.Type = ProtoDC.d2c_ProcessQuest_EPQuestType.ADD_QUEST
            tbPacket.nQuestId = value.nQuestId
            tbPacket.QuestParamArr = value.tbQuestParamArr
            tbPacket.DescParamArr = value.tbDescParamArr
            NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(),ProtoDC.d2c_ProcessQuest,tbPacket)
        end
    end

    if self.nAdditionalSuccessQuestId then
        local tbPacket = {}
        tbPacket.nASQuestId = self.nAdditionalSuccessQuestId
        tbPacket.nASCount = self.nAdditionalSuccessCount
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(),ProtoDC.d2c_AdditionalSuccessQuestInfo, tbPacket)
    end
end

local function OnAdditionalSuccessCountUpdate(self,nASCount)
    self.nAdditionalSuccessCount = nASCount

    if self.nAdditionalSuccessQuestId then
        local tbPacket = {}
        tbPacket.nASQuestId = self.nAdditionalSuccessQuestId
        tbPacket.nASCount = self.nAdditionalSuccessCount
        NetworkManager:GetRPCNetworkProxy():Multicast(ProtoDC.d2c_AdditionalSuccessQuestInfo, tbPacket, false)
    end
end

function BattleQuestSystem:Init()
    if GlobalVariableSystem:IsServerLogic() then
        self.tbPlayerQuestState = {}
        self.tbAllGlobalQuest   = {}
        EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerPostLogin)
        EventManager:BindEventMethod(CommonEventDef.EV_ADDITIONALSUCCESS_COUNT_UPDATE, self, OnAdditionalSuccessCountUpdate)
    end

    return true
end

function BattleQuestSystem:Uninit()
    if GlobalVariableSystem:IsServerLogic() then
        self.tbPlayerQuestState = nil
        self.tbAllGlobalQuest   = nil
        EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerPostLogin)
        EventManager:UnBindEventMethod(CommonEventDef.EV_ADDITIONALSUCCESS_COUNT_UPDATE, self, OnAdditionalSuccessCountUpdate)
    end

    return true
end

return BattleQuestSystem()