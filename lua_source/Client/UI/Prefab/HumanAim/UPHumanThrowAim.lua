-----------------------------------------------------
--Author       : Ran Jie
--Description  : UPHumanThrowAim
-----------------------------------------------------

local luaclass = require ("luaclass")
local UPHumanAimBase = require("UPHumanAimBase")
local UPHumanThrowAim = luaclass("UPHumanThrowAim", UPHumanAimBase)




function UPHumanThrowAim:Init(tbItem)
    UPHumanThrowAim.super.Init(self, tbItem)
end




return UPHumanThrowAim
