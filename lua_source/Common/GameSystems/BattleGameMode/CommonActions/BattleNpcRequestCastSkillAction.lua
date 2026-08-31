-----------------------------------------------------
--File Name    : BattleNpcRequestCastSkillAction.lua
--Author       : 
--Create Time  : 
--Description  : 修改npc使用技能
-----------------------------------------------------

local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleNpcRequestCastSkillAction = luaclass("BattleNpcRequestCastSkillAction", BattleActionBase)

local BattleNpcHelper = require("BattleNpcHelper")
local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")

BattleNpcRequestCastSkillAction.nSkillID = nil

function BattleNpcRequestCastSkillAction:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    self.nSkillID = tbJsonData.skillid
    return self.nSkillID > 0
end

function BattleNpcRequestCastSkillAction:Execute()
    
    BattleOperationHelper:PrintLog(self,
        ", Tag: " ..(self.szTag and self.szTag or "nil")..
        ", TemplateId: " ..(self.nTemplateId and self.nTemplateId or "nil")..
        ", Group: " ..(self.nGroupIndex and self.nGroupIndex or "nil")..
        ", CampType: " ..(self.nCampType and self.nCampType or "nil")..
        ", nSkillID: " ..self.nSkillID)
    local isFindNpc = false
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    for nId, Object in pairs(tbObjects) do
        if BattleNpcHelper:CheckIdentifier(self, Object) and Object.SkillComponentServer then
            Object.SkillComponentServer:RequestCastSkill(self.nSkillID)
            isFindNpc = true
        end
    end

    if not isFindNpc then
        BattleOperationHelper:PrintError(self, "Cannot find NPC szTag: "..(self.szTag and self.szTag or "nil")..
                                             "TemplateId: "..(self.nTemplateId and self.nTemplateId or "nil")..
                                             "Group: "..(self.nGroupIndex and self.nGroupIndex or "nil"))    
        return false
    end
 

    return true
end

return BattleNpcRequestCastSkillAction

