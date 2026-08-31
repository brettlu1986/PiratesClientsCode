local luaclass = require("luaclass")
local ControlModeBase = luaclass("ControlModeBase")

function ControlModeBase:OnActivate(tbParams)
end

function ControlModeBase:OnDeactivate()
end

function ControlModeBase:GetModeType()
    error("derived class must to implement it.")
end

return ControlModeBase