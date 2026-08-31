-----------------------------------------------------
--File Name    : UPProgressBar.lua
--Author       : Zuo Kun
--Create Time  : 2017-05-04
--Description  : 进度条
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPProgressBar = luaclass("UPProgressBar", PrefabBase)
local SceneDataTable = require("SceneDataTable")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local UITextDef = require("UITextDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local InteractionDef = require("InteractionDef")
local L10N = require("L10N")
-- local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

UPProgressBar.pCurrentAnim = nil
UPProgressBar.nInteractionNpcId = 0
UPProgressBar.bVisible = false
UPProgressBar.nInteractionType = 0

function UPProgressBar:OnLoad()
    self.EventHelper:RegisterCppDelegate(self.pWidgetRef.KMCircleProgressBar_0.OnAnimationFinished, self, self.OnProgressEnd)
end

function UPProgressBar:PrograssBtnVisibleChanged(bVisible,nInteractionTypeIndex, npcID)
    if self.bVisible == bVisible and nInteractionTypeIndex ~= InteractionDef.InteractionMode.CHANGE_DISPLAY then
        return
    end
    self.bVisible = bVisible
    self.nInteractionNpcId = npcID
    self.nInteractionType = nInteractionTypeIndex
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(bVisible and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed)
    pWidgetRef.txtAction:SetVisibility(bVisible and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed)
    pWidgetRef.WidgetSwitcher_43:SetActiveWidgetIndex(0)

    if nInteractionTypeIndex then
        local strIconPath = UIResourceDef.INTERACTION_BTN[nInteractionTypeIndex]
        if strIconPath then
            UISetUtils.SetImageBrushRes(self.pWidgetRef.kimg01, strIconPath:load())
        end

        local strBtnText = UITextDef.INTERATION_BUTTON_TEXT[nInteractionTypeIndex]
        if strBtnText then
            pWidgetRef.txtAction:SetText(strBtnText)
        end

    end
    pWidgetRef.KMCircleProgressBar_0:StopAnimation(false)
    pWidgetRef.KMCircleProgressBar_0:SetPercent(0)
    if bVisible then
        self:PlayAnimation("animBtnInter", 0, 1, EUMGSequencePlayMode.Forward, 1)
    end
end


function UPProgressBar:StartProgress(tbParams, npcID)
    self.EventHelper:FireEvent(CommonEventDef.EV_INTERRUPT_CONTINUOUS_RUN)
    self.bVisible = true

    self.nInteractionNpcId = npcID
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.WidgetSwitcher_43:SetActiveWidgetIndex(tbParams.nResID)
    pWidgetRef.KMCircleProgressBar_0:SetPercent(0)
    pWidgetRef.KMCircleProgressBar_0.AnimDuration = tbParams.nTime
    pWidgetRef.KMCircleProgressBar_0:SetPercent(1, true)
    pWidgetRef.parStart:Play()

    local l10nText = tbParams.l10nText
    if l10nText ~= nil then
        pWidgetRef.txtAction:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.txtAction:SetText(l10nText)
    end

    -- self.TimerHelper:ClearAllTimer()
    -- self.TimerHelper:NewTimerMethod(self, self.OnProgressEnd, tbParams.nTime, true)
    -- logdebug("tbParams.nResID" .. tbParams.nResID)
    -- if tbParams.nResID == 3 then
        -- self.pCurrentAnim = pWidgetRef.animbtn04
        -- self:PlayAnimation("animbtn04", 0, 0, EUMGSequencePlayMode.Forward, 1)
    -- elseif tbParams.nResID == 4 then
    --     self.pCurrentAnim = pWidgetRef.animbtn05
    --     self:PlayAnimation("animbtn05", 0, 0, EUMGSequencePlayMode.Forward, 1)
    -- elseif tbParams.nResID == 5 then
    if tbParams.nResID == 5 then
        self.pCurrentAnim = pWidgetRef.animbtn06
        self:PlayAnimation("animbtn06", 0, 0, EUMGSequencePlayMode.Forward, 1)
    end
end

local function OnTeleportStateChanged(self, bTeleport, nSceneID)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.parStart:Stop()

    pWidgetRef.txtAction:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.txtBlock:SetVisibility(bTeleport and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
    if bTeleport then
        local tbData = SceneDataTable:GetTemplate(nSceneID)
        if tbData then
            pWidgetRef.txtTarget:SetText(L10N:ToString(tbData.l10nName))
        end
    end
end

local function OnClickBtnAction(self)
    log("interaction progress bar", self.nInteractionType, self.nInteractionNpcId)
    local tbNpc = GameObjectSystem:FindByInstanceId(self.nInteractionNpcId)
    EventManager:OnFireEvent(ClientEventDef.EV_UI_REQUEST_INTERACTION, tbNpc)
    self.nInteractionNpcId = 0
    self.nInteractionType = 0
end

function UPProgressBar:OnProgressEnd(nNpcServerInstanceId)
    local pWidgetRef = self.pWidgetRef
    OnTeleportStateChanged(self, false)
    self.bVisible = false
    pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    if self.pCurrentAnim ~= nil then
        self:StopAnimation("animbtn06")
    end
    -- self.TimerHelper:ClearAllTimer()
end

function UPProgressBar:OnBindEvent( EventHelper )
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnAction.OnClicked, self, OnClickBtnAction)
    EventHelper:RegisterEvent(ClientEventDef.EV_REQUEST_PROGRESS, self, self.StartProgress)
    EventHelper:RegisterEvent(ClientEventDef.EV_STOP_PROGRESS, self, self.OnProgressEnd)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_COLLECTION_BREAK, self, self.OnProgressEnd)
    EventHelper:RegisterEventFunc(ClientEventDef.EV_TELEPORT_START , function(nSceneID) OnTeleportStateChanged(self, true, nSceneID) end)
    EventHelper:RegisterEventFunc(ClientEventDef.EV_TELEPORT_END , function() OnTeleportStateChanged(self, false) end)
    EventHelper:RegisterEventFunc(ClientEventDef.EV_TELEPORT_ABORTED , function() OnTeleportStateChanged(self, false) end)
end



return UPProgressBar
