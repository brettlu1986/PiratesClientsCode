-----------------------------------------------------
--File Name    : UIFFABattleDeadPlayback.lua
--Author       : ranjie
--Create Time  : 2019-09-16
--Description  : 死亡回放详情
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIFFABattleDeadPlayback = luaclass("UIFFABattleDeadPlayback", WndBase)

local ClientEventDef = require("ClientEventDef")
local BattleResultSystem = dynamic_require("BattleResultSystem")

local MAX_COUNT = 3

UIFFABattleDeadPlayback.tbDeadDetailScript = nil  --1:击倒 2：助攻 3：助攻

local function OnFFADeadPlayback(self, tbPacket)
    local tbPlaybackData = BattleResultSystem:GetFFADeadPlaybackData()
    self:SetData(tbPlaybackData)
end

local function OnClickClose(self)
    self:CloseSelf()
end

function UIFFABattleDeadPlayback:OnLoad()
    self.tbDeadDetailScript = {}
    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef
    for i = 1, MAX_COUNT do
        local pbDeadDetail = PrefabHelper:BindPrefab(pWidgetRef["pbDeadDetail_"..i])
        table.insert(self.tbDeadDetailScript, pbDeadDetail) 
    end
    self.pbDialogFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbDialogFrame)
    self.pbDialogFrame:SetDialogClosedCallback(OnClickClose, self)
end

function UIFFABattleDeadPlayback:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_DEAD_PLAYBACK, self, OnFFADeadPlayback)
end

function UIFFABattleDeadPlayback:OnEnter()
    for i = 1, MAX_COUNT do
        self.tbDeadDetailScript[i]:HideData()
    end
    local tbPlaybackData = BattleResultSystem:GetFFADeadPlaybackData()
    if tbPlaybackData then
        self:SetData(tbPlaybackData)
    else
        BattleResultSystem:RequestDeadPlayback()
    end
    -- local DeathPlaybacks = {
    --     ["nCauserType"] = 2,
    --     ["nTemplateType"]= 2,
    --     ["nTemplateId"] = 100000,
    --     ["DeathPlaybackWeapons"] = {
    --       ["nWeaponTemplateId"] =18050001,
    --       ["nDamage"] = 80,
    --       ["nAttackCount"] = 40,
    --     }
    --   }
      --self:SetData(DeathPlaybacks)
end

function UIFFABattleDeadPlayback:SetData(tbData)
    for i = 1, MAX_COUNT do
        local pbDeadDetail = self.tbDeadDetailScript[i]
        pbDeadDetail:SetData(tbData[i], i)
    end
end

return UIFFABattleDeadPlayback
