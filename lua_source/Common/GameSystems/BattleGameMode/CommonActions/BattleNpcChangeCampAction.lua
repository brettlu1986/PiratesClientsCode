-----------------------------------------------------
--File Name    : BattleNpcChangeCampAction.lua
--Author       : 
--Create Time  : 
--Description  : 修改npc阵营
-----------------------------------------------------

local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleNpcChangeCampAction = luaclass("BattleNpcChangeCampAction", BattleActionBase)

local BattleNpcHelper = require("BattleNpcHelper")
local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")

BattleNpcChangeCampAction.nNewCampType = nil

function BattleNpcChangeCampAction:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    self.nNewCampType = tbJsonData.NewCampType
    return self.nNewCampType >= 0
end

function BattleNpcChangeCampAction:Execute()
    BattleOperationHelper:PrintLog(self,
        ", Tag: " ..(self.szTag and self.szTag or "nil")..
        ", TemplateId: " ..(self.nTemplateId and self.nTemplateId or "nil")..
        ", Group: " ..(self.nGroupIndex and self.nGroupIndex or "nil")..
        ", CampType: " ..(self.nCampType and self.nCampType or "nil")..
        ", NewCampType: " ..(self.nNewCampType and self.nNewCampType or "nil"))
    
    local isFindNpc = false
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    for nId, Object in pairs(tbObjects) do
        if( BattleNpcHelper:CheckIdentifier(self, Object))  then
           Object.BattleCampComponent:SetCampType(self.nNewCampType)
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

return BattleNpcChangeCampAction

