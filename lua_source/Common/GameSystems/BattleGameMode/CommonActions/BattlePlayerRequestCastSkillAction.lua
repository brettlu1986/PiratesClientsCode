local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattlePlayerRequestCastSkillAction = luaclass("BattlePlayerRequestCastSkillAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleBlackboard = require("BattleBlackboard")

BattlePlayerRequestCastSkillAction.nSkillID = nil
BattlePlayerRequestCastSkillAction.szGetObjKey = nil


function BattlePlayerRequestCastSkillAction:Parse(tbJsonData)
    self.nSkillID = tbJsonData.skillid
    self.szGetObjKey = tbJsonData.GetObjKey
    return  self.nSkillID > 0
end

function BattlePlayerRequestCastSkillAction:Execute()
    BattleOperationHelper:PrintLog(self, "nSkillID: "..self.nSkillID)

    if self.szGetObjKey ~= nil and string.len(self.szGetObjKey) > 0 then 
        local tbPlayer = BattleBlackboard:GetTable(self.szGetObjKey)
        if tbPlayer and tbPlayer.SkillComponentServer ~= nil then
            tbPlayer.SkillComponentServer:RequestCastSkill(self.nSkillID)
        end
    else
        local tbAll = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
        for Object, _ in pairs(tbAll) do
            if(Object.SkillComponentServer ~= nil ) then
                Object.SkillComponentServer:RequestCastSkill(self.nSkillID)
            end
        end
    end
    return true
end

return BattlePlayerRequestCastSkillAction