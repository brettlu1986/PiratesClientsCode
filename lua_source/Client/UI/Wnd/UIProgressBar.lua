-----------------------------------------------------
--File Name    : UIProgressBar.lua
--Author       : zhiyuan
--Create Time  : 2019-07-02
--Description  : 主界面的读条ui
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIProgressBar = luaclass("UIProgressBar", WndBase)
local PlayerSelfHelper = require("GamePlayerSelfHelper")

function UIProgressBar:OnLoad()
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    self.pbProgressBar = PrefabHelper:BindPrefab(pWidgetRef.pbProgressBar)
end

function UIProgressBar:OnStartProgressBar(nProgressBarId, nProgressBarTime)
    local SelfPlayer = PlayerSelfHelper:Get()
    self.pbProgressBar:OnProgressBarChanged(SelfPlayer:GetServerInstanceId(), true, nProgressBarId, nProgressBarTime)
end

function UIProgressBar:OnBindEvent(EventHelper)
end

function UIProgressBar:OnEnter()
    local SelfPlayer = PlayerSelfHelper:Get()
    self.pbProgressBar:OnProgressBarChanged(SelfPlayer:GetServerInstanceId(), true, self.tbOpenArgs.nProgressBarId, self.tbOpenArgs.nProgressBarTime)
end

return UIProgressBar