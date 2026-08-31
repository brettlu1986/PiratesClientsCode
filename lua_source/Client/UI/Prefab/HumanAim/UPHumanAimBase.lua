-----------------------------------------------------
--Author       : Ran Jie
--Description  : UPHumanAimBase
-----------------------------------------------------

local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPHumanAimBase = luaclass("UPHumanAimBase", PrefabBase)



UPHumanAimBase.tbNotAimInitSize = nil
UPHumanAimBase.tbAimInitSize = nil
UPHumanAimBase.tbItem = nil


--member function
function UPHumanAimBase:OnLoad()
    local pSize = self.pWidgetRef.ovlNotAim.Slot:GetSize()
    self.tbNotAimInitSize = {X = pSize.X, Y = pSize.Y}
    pSize =  self.pWidgetRef.ovlAim.Slot:GetSize()
    self.tbAimInitSize = {X = pSize.X, Y = pSize.Y}
end

function UPHumanAimBase:Init(tbItem)
    self.tbItem = tbItem
end


return UPHumanAimBase
