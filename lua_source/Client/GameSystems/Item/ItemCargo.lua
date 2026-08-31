-----------------------------------------------------
--File Name    : ItemCargo.lua
--Description  : 货物
-----------------------------------------------------

local luaclass = require("luaclass")
local ItemClass = require("ItemOld")
local ItemCargo = luaclass("ItemCargo", ItemClass)

ItemCargo.tbProperties = nil                    -- 已设置的属性，第一个是价格

function ItemCargo:SetProperties(tbProperties)
    self.tbProperties = tbProperties
end

function ItemCargo:GetPrice()
    if not self.tbProperties then
        return 0
    end
    return self.tbProperties[1]
end

return ItemCargo
