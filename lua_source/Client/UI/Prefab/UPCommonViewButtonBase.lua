-----------------------------------------------------
--File Name    : UPCommonViewButtonBase.lua
--Author       : Edward J
--Create Time  : 2018-03-13
--Description  : UICommonButtonList
-----------------------------------------------------
local luaclass               = require("luaclass")
local PrefabBase             = require("PrefabBase")
local UPCommonViewButtonBase = luaclass("UPCommonViewButtonBase", PrefabBase)
-----------------------------------------------------
UPCommonViewButtonBase.tbBtnsArg = nil
-----------------------------------------------------

function UPCommonViewButtonBase:OnSetData(tbBtnsArg)
    self.tbBtnsArg = tbBtnsArg
end

function UPCommonViewButtonBase:OnHide()
    self.tbBtnsArg = nil
end
return UPCommonViewButtonBase