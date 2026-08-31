local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattlePlayerUseSkillAction = luaclass("BattlePlayerUseSkillAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")

BattlePlayerUseSkillAction.nSkillID = nil
BattlePlayerUseSkillAction.nSkillLv = nil

function BattlePlayerUseSkillAction:Parse(tbJsonData)
    self.nSkillID = tbJsonData.skillid
    self.nSkillLv = tbJsonData.SkillLv
    return  self.nSkillID > 0
end

function BattlePlayerUseSkillAction:Execute()
    BattleOperationHelper:PrintLog(self, "nSkillID: "..self.nSkillID..
                                    ",nSkillLv: "..(self.nSkillLv and self.nSkillLv or "nil"))

    local tbAll = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbAll) do
        if(Object.SkillComponentServer ~= nil ) then
            Object.SkillComponentServer:AcquireSkill(self.nSkillID, self.nSkillLv)
            --Object.SkillComponentServer:RequestCastSkill(self.nSkillID)
        end
    end

    return true
end

return BattlePlayerUseSkillAction