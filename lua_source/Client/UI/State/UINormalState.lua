-----------------------------------------------------
--File Name    : UINormalState.lua
--Author       : Ran Jie
--Create Time  : 2017-03-07
--Description  : UI通用状态, 普通ui逻辑状态从UINormalState继承
-----------------------------------------------------

local luaclass = require("luaclass")
local StateBase = require("StateBase")
local UINormalState = luaclass("UINormalState", StateBase)

-- import require
local UIDef = require("UIDef")
local UIStateDef = require("UIStateDef")

function UINormalState:Init(szUIStateName)
    UINormalState.super.Init(self, szUIStateName) 
    self.nStateType = UIStateDef.StateType.NORMAL
    --
    self:AddPermanentWnd(UIDef.UI_LOADING)
    self:AddPermanentWnd(UIDef.UI_ERROR_DIALOG)
    self:AddPermanentWnd(UIDef.UI_RETRY_CONNECT_DIALOG)
    self:AddPermanentWnd(UIDef.UI_WAIT_CONNECT_DIALOG)
    --
    self:AddActiveWnd(UIDef.UI_TOAST_BOARD)
    self:AddActiveWnd(UIDef.UI_SPECIAL_TOAST_BOARD)
    self:AddActiveWnd(UIDef.UI_GUIDE)
    self:AddActiveWnd(UIDef.UI_BLACKSCREEN)
end

return UINormalState
