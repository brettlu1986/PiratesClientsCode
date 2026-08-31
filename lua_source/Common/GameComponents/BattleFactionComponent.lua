local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local BattleFactionComponent = luaclass("BattleFactionComponent", GameComponentBaseClass)

-- 阵营类型 CampDefine.Type
BattleFactionComponent.nFaction = nil


function BattleFactionComponent:OnCreate(Owner, tbParams)
    BattleFactionComponent.super.OnCreate(self, Owner, tbParams)
    if tbParams == nil then
        return false
    end
    self.nFaction = tbParams.nFaction
    return true
end

function BattleFactionComponent:GetFaction()
    return self.nFaction
end

return BattleFactionComponent
