local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattlePlayerAcquireSkillAction = luaclass("BattlePlayerAcquireSkillAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleBlackboard = require("BattleBlackboard")

BattlePlayerAcquireSkillAction.nSkillID = nil
BattlePlayerAcquireSkillAction.nSkillLv = nil
BattlePlayerAcquireSkillAction.szGetObjKey = nil

function BattlePlayerAcquireSkillAction:Parse(tbJsonData)
    self.nSkillID = tbJsonData.skillid
    self.nSkillLv = tbJsonData.skilllevel
    self.szGetObjKey = tbJsonData.GetObjKey
    return  self.nSkillID > 0
end

function BattlePlayerAcquireSkillAction:Execute()
    BattleOperationHelper:PrintLog(self, "nSkillID: "..self.nSkillID..
                                ",nSkillLv: "..(self.nSkillLv and self.nSkillLv or "nil"))

    if self.szGetObjKey ~= nil and string.len(self.szGetObjKey) > 0 then 
        local tbPlayer = BattleBlackboard:GetTable(self.szGetObjKey)
        if tbPlayer and tbPlayer.SkillComponentServer ~= nil then
            tbPlayer.SkillComponentServer:AcquireSkill(self.nSkillID, self.nSkillLv)
        end
    else
        local tbAll = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
        for Object, _ in pairs(tbAll) do
            if(Object.SkillComponentServer ~= nil ) then
                Object.SkillComponentServer:AcquireSkill(self.nSkillID, self.nSkillLv)
            end
        end
    end
    return true
end

return BattlePlayerAcquireSkillAction