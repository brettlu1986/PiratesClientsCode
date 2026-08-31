local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleInteractionHeadDialogAction = luaclass("BattleInteractionHeadDialogAction", BattleActionBase)

local BattleInteractionHelper = require("BattleInteractionHelper")
local BattleOperationHelper = require("BattleOperationHelper")
local BattleNpcHelper = require("BattleNpcHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")

BattleInteractionHeadDialogAction.nDialogId = nil

function BattleInteractionHeadDialogAction:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    self.nDialogId = tbJsonData.DialogId
    return self.nDialogId > 0
end

function BattleInteractionHeadDialogAction:Execute()
    BattleOperationHelper:PrintLog(self, 
        "DialogId: "..self.nDialogId..
        ", Tag: " ..(self.szTag and self.szTag or "nil")..
        ",TemplateId: " ..(self.nTemplateId and self.nTemplateId or "nil")..
        ",Group: " ..(self.nGroupIndex and self.nGroupIndex or "nil")..
        ",CampType: " ..(self.nCampType and self.nCampType or "nil"))
   
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    for nId, Object in pairs(tbObjects) do
        if( BattleNpcHelper:CheckIdentifier(self, Object))  then
            BattleInteractionHelper:ShowHeadDialog(Object, self.nDialogId)
            self.IsShowHeadDialog = true
        end
    end
    if not self.IsShowHeadDialog then
        BattleOperationHelper:PrintError(self, "Cannot find NPC szTag: "..(self.szTag and self.szTag or "nil")..
                                        "TemplateId: "..(self.nTemplateId and self.nTemplateId or "nil")..
                                        "Group: "..(self.nGroupIndex and self.nGroupIndex or "nil"))    
    end

    -- TODO...
    return true
end

return BattleInteractionHeadDialogAction