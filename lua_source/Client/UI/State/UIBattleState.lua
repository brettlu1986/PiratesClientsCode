-----------------------------------------------------
--File Name    : UIBattleState.lua
--Author       : Ran Jie
--Create Time  : 2017-03-07
--Description  : UIBattleState
-----------------------------------------------------

local luaclass = require("luaclass")
local UINormalState = require("UINormalState")
local UIBattleState = luaclass("UIBattleState",UINormalState)
local DungeonTypeDefine = require("DungeonTypeDefine")
local UIManager = require("UIManager")

-- import require
local UIDef = require("UIDef")
local DungeonDataTable = require("DungeonDataTable")
-- local HandlerManagerHelper = require("HandlerManagerHelper")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")

function UIBattleState:Init(szUIStateName)
    UIBattleState.super.Init(self, szUIStateName)
    self:AddActiveWnd(UIDef.UI_FFA_SELECT_BORNPOINT)
    self:AddActiveWnd(UIDef.UI_COUNT_DOWN2)
    self:AddActiveWnd(UIDef.UI_CROSSHAIRS_DEBUG)
end

function UIBattleState:Enter(tbParam)
    self.tbOpenWnd = {}
    local tbDungeonTemplate = DungeonDataTable:GetTemplate(tbParam.nDungeonId)
    if tbDungeonTemplate then
        if tbDungeonTemplate.nType == DungeonTypeDefine.PVP then
            table.insert(self.tbOpenWnd, UIDef.UI_FFA_MAIN)
            --table.insert(self.tbOpenWnd, UIDef.UI_WORLD_MAP)
        else
            error("UIBattleState:Enter failed, unsupported type: "..tostring(tbDungeonTemplate.nType))
            --table.insert(self.tbOpenWnd, UIDef.UI_FFA_PVP_MAIN)
        end
    else
        logerror("[UI]UIBattleState:Enter, tbDungeonTemplate is nil,dungeon id=",tbParam.nDungeonId)
    end
    UIBattleState.super.Enter(self, tbParam)
    UIManager:OpenWnd(UIDef.UI_WORLD_MAP)
    UIManager:OpenWnd(UIDef.UI_PICKUP_ITEM)
    UIManager:OpenWnd(UIDef.UI_PICKUP_BOX)
    -- 因为选点界面是一次性的，所以在这里打开一次，在跳伞流程开启后需要destroy掉
    UIManager:OpenWnd(UIDef.UI_FFA_SELECT_BORNPOINT)

    EventManager:OnFireEvent(ClientEventDef.EV_UI_BATTLE_STATE_ENTERED)
end


return UIBattleState
