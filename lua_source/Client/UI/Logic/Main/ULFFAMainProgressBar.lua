-----------------------------------------------------
--File Name    : ULFFAMainProgressBar.lua
--Author       : zhiyuan
--Create Time  : 2019-07-02
--Description  : 主界面的progressbar逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULFFAMainProgressBar = luaclass("ULFFAMainProgressBar", UILogicBase)

local CommonEventDef = require("CommonEventDef")
local UIDef = require("UIDef")
local UIManager = require("UIManager")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local function OnProgressBarChanged(self, nInstanceId, bStart, nProgressBarId, nProgressBarTime)
    if not bStart then  
        return 
    end
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local nSelfInstanceId = PlayerSelf:GetServerInstanceId()
    if nSelfInstanceId ~= nInstanceId then
        return 
    end    
    local szWndName = UIDef.UI_PROGRESS_BAR
    if UIManager:IsWndVisible(szWndName) then
        local tbWnd = UIManager:GetWnd(szWndName)
        tbWnd:OnStartProgressBar(nProgressBarId, nProgressBarTime)
    else
        UIManager:OpenWnd(szWndName, {nProgressBarId = nProgressBarId, nProgressBarTime = nProgressBarTime})
    end
end

function ULFFAMainProgressBar:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_PROGRESS_CHANGED, self, OnProgressBarChanged)
end

return ULFFAMainProgressBar
