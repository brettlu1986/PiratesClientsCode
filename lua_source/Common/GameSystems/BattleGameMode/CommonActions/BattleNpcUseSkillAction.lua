-----------------------------------------------------
--File Name    : BattleNpcUseSkillAction.lua
--Author       : 
--Create Time  : 
--Description  : 修改npc使用技能
-----------------------------------------------------

local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleNpcUseSkillAction = luaclass("BattleNpcUseSkillAction", BattleActionBase)

local BattleNpcHelper = require("BattleNpcHelper")
local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")

BattleNpcUseSkillAction.nSkillID = nil

function BattleNpcUseSkillAction:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    self.nSkillID = tbJsonData.skillid
    self.nSkillLv = tbJsonData.skilllv
    return self.nSkillID > 0
end

function BattleNpcUseSkillAction:Execute()
    
    BattleOperationHelper:PrintLog(self,
        ", Tag: " ..(self.szTag and self.szTag or "nil")..
        ", TemplateId: " ..(self.nTemplateId and self.nTemplateId or "nil")..
        ", Group: " ..(self.nGroupIndex and self.nGroupIndex or "nil")..
        ", CampType: " ..(self.nCampType and self.nCampType or "nil")..
        ", nSkillID: " ..(self.nSkillID)..
        ", nSkillLv: " ..(self.nSkillLv and self.nSkillLv or "nil"))
    local isFindNpc = false
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    for nId, Object in pairs(tbObjects) do
        if BattleNpcHelper:CheckIdentifier(self, Object) and Object.SkillComponentServer then
            Object.SkillComponentServer:AcquireSkill(self.nSkillID, self.nSkillLv)
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

return BattleNpcUseSkillAction

