
local luaclass = require("luaclass")
local UINormalState = require("UINormalState")
local UIWatchBattleState = luaclass("UIWatchBattleState", UINormalState)

-- import require
local UIDef = require("UIDef")

function UIWatchBattleState:Init(szUIStateName)
    UIWatchBattleState.super.Init(self, szUIStateName)
end

function UIWatchBattleState:Enter(tbParam)
    self.tbOpenWnd = {
        UIDef.UI_WATCHBATTLE,
    }
    local tbWndParams = {}
    tbWndParams[UIDef.UI_WATCHBATTLE] = tbParam
    UIWatchBattleState.super.Enter(self, tbWndParams)
end

return UIWatchBattleState
