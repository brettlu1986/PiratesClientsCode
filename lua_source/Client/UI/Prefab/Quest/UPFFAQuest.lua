-----------------------------------------------------
--File Name    : UPFFAQuest.lua
--Author       : LiHui
--Create Time  : 
--Description  : UPFFAQuest
-----------------------------------------------------
local luaclass      = require("luaclass")
local UPFFABase     = require("UPFFABase")
local UPFFAQuest = luaclass("UPFFAQuest", UPFFABase)

local SelfVerticalListHelper = require("SelfVerticalListHelper")
local ClientEventDef = require("ClientEventDef")
local BattleQuestSystem = dynamic_require("BattleQuestSystem")

local ANIMATION_NAME = "animMissonTips"

UPFFAQuest.bVisible = false
UPFFAQuest.ListHelper = nil
UPFFAQuest.bPlayingEffect = false

local function PlayImgAnimation(self)
    if not self.bPlayingEffect then
        self.bPlayingEffect = true
        self.Owner:PlayAnimation(ANIMATION_NAME, 0, 0, EUMGSequencePlayMode.Forward, 1)
    end
end

local function StopImgAnimation(self)
    if self.bPlayingEffect then
        self.bPlayingEffect = false
        self.Owner:StopAnimation(ANIMATION_NAME)
    end
end

local function RefreshQuestData(self)
    --TODO 将来从component拿数据
    local tbQuestData = BattleQuestSystem:GetQuestData()

    local tbDoingQuest = {}
    local tbCompletedQuest = {}

    for _,v in pairs(tbQuestData) do
        if v.bCompleted then
            table.insert(tbCompletedQuest,v)
        else
            table.insert(tbDoingQuest,v)
        end
    end

    for _,v in pairs(tbCompletedQuest) do
        table.insert(tbDoingQuest,v)
    end

    self.ListHelper:SetData(tbDoingQuest)
end

function UPFFAQuest:Activate()
    self.super.Activate(self)
    StopImgAnimation(self)
    self.bVisible = true
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    RefreshQuestData(self)
end

function UPFFAQuest:Deactivate()
    self.super.Deactivate(self)
    self.bVisible = false
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    self.ListHelper:SetData(nil)
end

function UPFFAQuest:ToggleActivate()
    if self.bVisible then
        self:Deactivate()
        return
    end
    self:Activate()
end

function UPFFAQuest:OnLoad()
    self.super.OnLoad(self)

    local pWidgetRef = self.pWidgetRef

    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, pWidgetRef.KMVerticalList_0)
end

function UPFFAQuest:OnUnload()
    self.super.OnUnload(self)
    
    self.ListHelper:Uninit()
    self.ListHelper = nil
end

local function OnQuestNew(self)
    if not self.bVisible then
        PlayImgAnimation(self)
    end
end

local function OnQuestUpdate(self)
    if self.bVisible then
        RefreshQuestData(self)
    end
end

function UPFFAQuest:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_QUEST_NEW, self, OnQuestNew)
    EventHelper:RegisterEvent(ClientEventDef.EV_QUEST_UPDATE, self, OnQuestUpdate)
end

return UPFFAQuest