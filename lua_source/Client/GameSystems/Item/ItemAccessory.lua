-----------------------------------------------------
--File Name    : ItemAccessory.lua
--Description  : 配件
-----------------------------------------------------

local luaclass = require("luaclass")
local ItemClass = require("ItemOld")
local ItemAccessory = luaclass("ItemAccessory", ItemClass)
local Env = require("Env")

ItemAccessory.nDurability  = Env.NUMBER_INVALID     -- 耐久   
ItemAccessory.tbProperties = nil                    -- 已选择的属性

function ItemAccessory:SetDurablity(nDurability)
    self.nDurability = nDurability
end

function ItemAccessory:GetDurability()
    return self.nDurability
end

function ItemAccessory:SetProperties(tbProperties)
    self.tbProperties = tbProperties
end

function ItemAccessory:GetEffectId()
    if not self.tbProperties then
        return 0
    end
    return self.tbProperties[1]
end

return ItemAccessory
