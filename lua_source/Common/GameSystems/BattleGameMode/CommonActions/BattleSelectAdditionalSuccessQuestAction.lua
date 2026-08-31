-----------------------------------------------------
--File Name    : BattleSelectAdditionalSuccessQuestAction.lua
--Author       : LiHui
--Create Time  :
--Description  : 选择一个可以逃出升天的任务
-----------------------------------------------------

local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSelectAdditionalSuccessQuestAction = luaclass("BattleSelectAdditionalSuccessQuestAction", BattleActionBase)

local L10N = require("L10N")
local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")
local BattleQuestSystem = dynamic_require("BattleQuestSystem")
local QuestDataTable = require("QuestDataTable")
--local BattleTeamSystem = require("BattleTeamSystem")

BattleSelectAdditionalSuccessQuestAction.szSetQuestIdKey     = nil
BattleSelectAdditionalSuccessQuestAction.szSetQuestNameKey   = nil


function BattleSelectAdditionalSuccessQuestAction:Parse(tbJsonData)
    self.szSetQuestIdKey     = tbJsonData.SetQuestIdKey   or ""
    self.szSetQuestNameKey   = tbJsonData.SetQuestNameKey or ""

    return true
end

function BattleSelectAdditionalSuccessQuestAction:Execute()

    BattleOperationHelper:PrintLog(self,
        "szSetQuestIdKey: "..(self.szSetQuestIdKey or "")..
        "szSetQuestNameKey: "..(self.szSetQuestNameKey or "")
        )

    local nASQuestId = BattleQuestSystem:SelectAdditionalSuccessQuest()
    if nASQuestId then
        BattleBlackboard:SetNumber(self.szSetQuestIdKey,nASQuestId)
        local l10nQuestName = QuestDataTable:GetQuestNameById(nASQuestId)
        BattleBlackboard:SetString(self.szSetQuestNameKey, L10N:ToString(l10nQuestName))
        return true
    end

    return false
end

return BattleSelectAdditionalSuccessQuestAction

