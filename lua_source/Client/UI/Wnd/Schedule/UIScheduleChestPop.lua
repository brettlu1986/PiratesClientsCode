local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIScheduleChestPop = luaclass("UIScheduleChestPop", WndBase)
local ScheduleSystem = require("ScheduleSystem")
local ScheduleTypeDef = require("ScheduleTypeDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local ScheduleTable = require("ScheduleTable")
local DelayTimer = require("DelayTimer")

UIScheduleChestPop.tbInstance = nil
UIScheduleChestPop.tbDelayTimer = nil

local function Refresh(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtTime:SetText(self.tbInstance:GetTimeStr())
end

local function OnClickClose(self)
    self:CloseSelf()
end

local function OnClickGo(self)
    local ScheduleTemp = ScheduleTable:GetTemplateByType(ScheduleTypeDef.CHEST)
    UIManager:OpenWnd(UIDef.UI_SCHEDULE, {nId = ScheduleTemp.nId, szFrom = UIDef.UI_SCHEDULE_CHEST_POP})
    -- self:CloseSelf()
end

local function DestroyTimer(self)
    if self.tbDelayTimer ~= nil then  
        DelayTimer:ClearTimer(self.tbDelayTimer)
        self.tbDelayTimer = nil 
    end 
end

function UIScheduleChestPop:OnLoad()
    -- local PrefabHelper = self.PrefabHelper
    -- local pWidgetRef = self.pWidgetRef
end

function UIScheduleChestPop:OnUnload()
end

function UIScheduleChestPop:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    
    EventHelper:RegisterCppDelegate(pWidgetRef.btnClose.OnClicked, self, OnClickClose)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnGo.OnClicked, self, OnClickGo)
end

function UIScheduleChestPop:OnCreate()
    self.tbInstance = ScheduleSystem:GetInstance(ScheduleTypeDef.CHEST)
end

function UIScheduleChestPop:OnDestroy()
    DestroyTimer(self)
    self.tbInstance = nil
end

function UIScheduleChestPop:OnShow()
    if self.tbInstance == nil then
        self.tbDelayTimer = DelayTimer:DelayRun(function() 
            DestroyTimer(self)
            self:CloseSelf()
        end, 0.5)
    else
        Refresh(self)
    end
    local fnOnComplete = function()
        self:PlayAnimation("animGlow", 0, 0, EUMGSequencePlayMode.Forward)
    end
    self:PlayAnimation("animBat", 0, 1, EUMGSequencePlayMode.Forward, 1, fnOnComplete)
end

return UIScheduleChestPop
