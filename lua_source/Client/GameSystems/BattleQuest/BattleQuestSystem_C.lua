-----------------------------------------------------
--File Name    : BattleQuestSystem_C.lua
--Author       : LiHui
--Create Time  : 
--Description  : Battle任务系统
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleQuestSystem = require("BattleQuestSystem")
local BattleQuestSystem_C = luaclass("BattleQuestSystem_C", BattleQuestSystem)

local Proto = require("DungeonCommonProtoNames")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

local QuestDataTable = require("QuestDataTable")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local L10N = require("L10N")
--TODO 将来数据需要移到Component中
BattleQuestSystem_C.tbPlayerQuests = nil
BattleQuestSystem_C.nAdditionalSuccessQuestId = nil
BattleQuestSystem_C.nAdditionalSuccessCount = 0
BattleQuestSystem_C.bAdditionalSuccessFighting = nil

function BattleQuestSystem_C:Init()
    BattleQuestSystem_C.super.Init(self)
    self.tbPlayerQuests = {}
    return true
end

function BattleQuestSystem_C:Uninit()
    BattleQuestSystem_C.super.Uninit(self)
    self.tbPlayerQuests = nil
    return true
end

function BattleQuestSystem_C:ReceiveASQuestPacket(tbPacket)
    self.nAdditionalSuccessQuestId = tbPacket.nASQuestId
    self.nAdditionalSuccessCount = tbPacket.nASCount
    EventManager:OnFireEvent(ClientEventDef.EV_QUEST_UPDATE)
end

function BattleQuestSystem_C:ReceiveASResultPacket(tbPacket)
    self.bAdditionalSuccessFighting = (tbPacket.nASResult == Proto.d2c_AdditionalSuccessResult_EASResultType.FIGHTING)
    EventManager:OnFireEvent(ClientEventDef.EV_QUEST_UPDATE)
end

function BattleQuestSystem_C:ReceivePacket(tbPacket)
    local tbCurQuest = nil

    for _,v in pairs(self.tbPlayerQuests) do
        if v.nQuestId == tbPacket.nQuestId then
            tbCurQuest = v
            break
        end
    end

    local szQuestInfoDesc = L10N:FormatFromTable(QuestDataTable:GetTextById(tbPacket.nQuestId),tbPacket.QuestParamArr)
    local szQuestProcessDesc = L10N:FormatFromTable(QuestDataTable:GetProgressDescById(tbPacket.nQuestId),tbPacket.DescParamArr)
    if tbCurQuest then
        tbCurQuest.szQuestInfoDesc = szQuestInfoDesc
        tbCurQuest.szQuestProcessDesc = szQuestProcessDesc
        tbCurQuest.bCompleted = (tbPacket.Type == Proto.d2c_ProcessQuest_EPQuestType.COMPLETE_QUEST)
        if tbCurQuest.bCompleted then
           UIUtils.ShowToast(L10N:Format(UITextDef.FFA_QUEST_COMPLETE_QUEST, tbCurQuest.szQuestNameDesc,tbCurQuest.szQuestAwardsDesc))
        end
    else
        local szQuestAwardsDesc = QuestDataTable:GetAwardsDescById(tbPacket.nQuestId)
        local szQuestNameDesc   = QuestDataTable:GetQuestNameById(tbPacket.nQuestId)
        tbCurQuest = {}
        tbCurQuest.nQuestId = tbPacket.nQuestId
        tbCurQuest.szQuestNameDesc = szQuestNameDesc
        tbCurQuest.szQuestInfoDesc = szQuestInfoDesc
        tbCurQuest.szQuestProcessDesc = szQuestProcessDesc
        tbCurQuest.szQuestAwardsDesc = szQuestAwardsDesc
        tbCurQuest.bCompleted = (tbPacket.Type == Proto.d2c_ProcessQuest_EPQuestType.COMPLETE_QUEST)
        table.insert(self.tbPlayerQuests,tbCurQuest)
        EventManager:OnFireEvent(ClientEventDef.EV_QUEST_NEW)

        UIUtils.ShowToast(L10N:Format(UITextDef.FFA_QUEST_RECEIVE_QUEST, szQuestNameDesc))
    end

    EventManager:OnFireEvent(ClientEventDef.EV_QUEST_UPDATE)
end

function BattleQuestSystem_C:GetQuestData()
    return self.tbPlayerQuests
end

function BattleQuestSystem_C:GetAdditionalSuccessQuestId()
    return self.nAdditionalSuccessQuestId
end

function BattleQuestSystem_C:GetAdditionalSuccessCount()
    return self.nAdditionalSuccessCount
end

function BattleQuestSystem_C:IsAdditionalSuccessFighting()
    return self.bAdditionalSuccessFighting
end

return BattleQuestSystem_C()