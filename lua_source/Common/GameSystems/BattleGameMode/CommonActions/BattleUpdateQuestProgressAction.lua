-----------------------------------------------------
--File Name    : BattleUpdateQuestProgressAction.lua
--Author       : LiHui
--Create Time  : 
--Description  : 更新任务进度信息
-----------------------------------------------------

local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleUpdateQuestProgressAction = luaclass("BattleUpdateQuestProgressAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")
local BattleQuestSystem = dynamic_require("BattleQuestSystem")
local BattleTeamSystem = require("BattleTeamSystem")

BattleUpdateQuestProgressAction.szGetObjKey      = nil
BattleUpdateQuestProgressAction.nQuestId         = 0
BattleUpdateQuestProgressAction.bAffectTeam      = nil
BattleUpdateQuestProgressAction.bComplete        = nil
BattleUpdateQuestProgressAction.szDescParam1     = nil
BattleUpdateQuestProgressAction.szDescParam2     = nil


function BattleUpdateQuestProgressAction:Parse(tbJsonData)
    self.szGetObjKey      = tbJsonData.GetObjKey or ""
    self.nQuestId         = tbJsonData.QuestId or -1
    self.bAffectTeam      = tbJsonData.AffectTeam or false
    self.bComplete        = tbJsonData.Complete or false
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

function BattleUpdateQuestProgressAction:Execute()

    BattleOperationHelper:PrintLog(self,
        "GetObjKey: "..(self.szGetObjKey or "")..
        ", QuestId: "..self.nQuestId..
        ", AffectTeam: "..(self.bAffectTeam and "true" or "false")..
        ", Complete: "..(self.bComplete and "true" or "false")..
        ", DescParam1: "..(self.szDescParam1 or "")..
        ", DescParam2: "..(self.szDescParam2 or ""))

    --local szText1 = L10N:Format(QuestDataTable.GetTextById(self.nQuestId),self.szQuestParam1,self.szQuestParam2)
    --local szText2 = L10N:Format(QuestDataTable.GetProgressDescById(self.nQuestId),self.szDescParam1,self.szDescParam2)
    
    local szDescParam1 = GetStringValue(self.szDescParam1)
    local szDescParam2 = GetStringValue(self.szDescParam2)

    local tbDescParamArr  = {szDescParam1,szDescParam2}

    local tbPlayer = nil
    if string.len(self.szGetObjKey) > 0 then
        tbPlayer = BattleBlackboard:GetTable(self.szGetObjKey)
        if not tbPlayer then
            return false
        end
    else
        return false
    end

    if self.bAffectTeam then
        local tbTeamMembers = BattleTeamSystem:GetTeamMembersByPlayer(tbPlayer)
        for _, curIterPlayer in ipairs(tbTeamMembers) do
            if not curIterPlayer:IsDead() then
                BattleQuestSystem:UpdateQuestProgress(curIterPlayer,self.nQuestId,self.bComplete,tbDescParamArr)
            end
        end
    else
        BattleQuestSystem:UpdateQuestProgress(tbPlayer,self.nQuestId,self.bComplete,tbDescParamArr)        
    end

    return true
end

return BattleUpdateQuestProgressAction

