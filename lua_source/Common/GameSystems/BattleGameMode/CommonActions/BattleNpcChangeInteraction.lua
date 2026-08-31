-----------------------------------------------------
--File Name    : BattleNpcChangeInteraction.lua
--Author       : 
--Create Time  : 
--Description  : 修改npc可交互状态
-----------------------------------------------------

local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleNpcChangeInteraction = luaclass("BattleNpcChangeInteraction", BattleActionBase)

local BattleNpcHelper = require("BattleNpcHelper")
local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleNpcChangeInfoHelper = require("BattleNpcChangeInfoHelper")

BattleNpcChangeInteraction.bInteraction = nil

function BattleNpcChangeInteraction:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    self.bInteraction = tbJsonData.Interaction
    return true
end

function BattleNpcChangeInteraction:Execute()
    
    BattleOperationHelper:PrintLog(self,
        ", Tag: " ..(self.szTag and self.szTag or "nil")..
        ", TemplateId: " ..(self.nTemplateId and self.nTemplateId or "nil")..
        ", Group: " ..(self.nGroupIndex and self.nGroupIndex or "nil")..
        ", CampType: " ..(self.nCampType and self.nCampType or "nil")..
        ", Interaction: " ..(self.bInteraction and "true" or "false"))
    local isFindNpc = false
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    for nId, Object in pairs(tbObjects) do
        if( BattleNpcHelper:CheckIdentifier(self, Object))  then
            BattleNpcChangeInfoHelper:SetChangeNpcInteraction(Object, self.bInteraction)
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

return BattleNpcChangeInteraction

