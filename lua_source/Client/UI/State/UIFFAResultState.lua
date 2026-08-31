-----------------------------------------------------
--File Name    : UIFFAResultState.lua
--Author       : Ran Jie
--Create Time  : 2018-09-28
--Description  : UIFFAResultState
-----------------------------------------------------

local luaclass = require("luaclass")
local UINormalState = require("UINormalState")
local UIFFAResultState = luaclass("UIFFAResultState", UINormalState)

-- import require
local UIDef = require("UIDef")


function UIFFAResultState:Init(szUIStateName)
    UIFFAResultState.super.Init(self, szUIStateName)
end

function UIFFAResultState:Enter(tbParam)
    self.tbOpenWnd = {
        UIDef.UI_FFA_BATTLE_RESULT,
    }
    local tbWndParams = {}
    tbWndParams[UIDef.UI_FFA_BATTLE_RESULT] = tbParam
    UIFFAResultState.super.Enter(self, tbWndParams)
end

return UIFFAResultState
