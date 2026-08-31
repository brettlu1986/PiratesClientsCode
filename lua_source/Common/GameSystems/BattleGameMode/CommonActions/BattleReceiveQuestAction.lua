-----------------------------------------------------
--File Name    : BattleReceiveQuestAction.lua
--Author       : LiHui
--Create Time  : 
--Description  : 接收任务
-----------------------------------------------------

local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleReceiveQuestAction = luaclass("BattleReceiveQuestAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")
local BattleQuestSystem = dynamic_require("BattleQuestSystem")
local BattleTeamSystem = require("BattleTeamSystem")

BattleReceiveQuestAction.szGetObjKey      = nil
BattleReceiveQuestAction.nQuestId         = 0
BattleReceiveQuestAction.bGlobalQuest     = nil
BattleReceiveQuestAction.szQuestParam1    = nil
BattleReceiveQuestAction.szQuestParam2    = nil
BattleReceiveQuestAction.szDescParam1     = nil
BattleReceiveQuestAction.szDescParam2     = nil


function BattleReceiveQuestAction:Parse(tbJsonData)
    self.szGetObjKey      = tbJsonData.GetObjKey or ""
    self.nQuestId         = tbJsonData.QuestId or -1
    self.bGlobalQuest     = tbJsonData.GlobalQuest or false
    self.szQuestParam1    = tbJsonData.QuestParam1 or ""
    self.szQuestParam2    = tbJsonData.QuestParam2 or ""
    self.szDescParam1     = tbJsonData.DescParam1 or ""
    self.szDescParam2     = tbJsonData.DescParam2 or ""

    return true
end

local function GetStringValue(szKey)
    if(szKey == nil or string.len(szKey) == 0) then
        return nil
    end
    local Value = BattleBlackboard:GetRaw(szKey)
    if(Value) then
        Value = tostring(Value)
    end
    return Value
end

function BattleReceiveQuestAction:Execute()

    BattleOperationHelper:PrintLog(self,
        "GetObjKey: "..(self.szGetObjKey or "")..
        ", QuestId: "..self.nQuestId..
        ", GlobalQuest: "..(self.bGlobalQuest and "true" or "false")..
        ", QuestParam1: "..(self.szQuestParam1 or "")..
        ", QuestParam2: "..(self.szQuestParam2 or "")..
        ", DescParam1: "..(self.szDescParam1 or "")..
        ", DescParam2: "..(self.szDescParam2 or ""))

    local szQuestParam1 = GetStringValue(self.szQuestParam1)
    local szQuestParam2 = GetStringValue(self.szQuestParam2)
    local szDescParam1 = GetStringValue(self.szDescParam1)
    local szDescParam2 = GetStringValue(self.szDescParam2)

    local tbQuestParamArr = {szQuestParam1,szQuestParam2}
    local tbDescParamArr  = {szDescParam1,szDescParam2}
    if self.bGlobalQuest then
        BattleQuestSystem:AddGlobalQuest(self.nQuestId,tbQuestParamArr,tbDescParamArr)
    else
        local tbPlayer = nil
        if string.len(self.szGetObjKey) > 0 then
            tbPlayer = BattleBlackboard:GetTable(self.szGetObjKey)
            if not tbPlayer then
                return false
            end
        end

        local tbTeamMembers = BattleTeamSystem:GetTeamMembersByPlayer(tbPlayer)
        for _, curIterPlayer in ipairs(tbTeamMembers) do
            if not curIterPlayer:IsDead() then
                BattleQuestSystem:AddPrivateQuest(curIterPlayer,self.nQuestId,tbQuestParamArr,tbDescParamArr)
            end
        end
    end

    return true
end

return BattleReceiveQuestAction

