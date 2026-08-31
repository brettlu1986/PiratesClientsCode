-----------------------------------------------------
--File Name    : GuideActionSelectResIcon.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFullUIControl      = require("GuideActionFullUIControl")
local GuideActionSelectBornPoint    = luaclass("GuideActionSelectBornPoint", GuideActionFullUIControl)

local UIManager         = require("UIManager")
local UIDef             = require("UIDef")
local ClientEventDef    = require("ClientEventDef")
local ProtoDR           = require("DungeonRepProtoNames")
local L10N              = require("L10N")
----------------------------------------------------------
local GetLocalSize      = SlateBlueprintLibrary.GetLocalSize
local LocalToAbsolute   = SlateBlueprintLibrary.LocalToAbsolute
----------------------------------------------------------

function GuideActionSelectBornPoint:Begin()
    GuideActionSelectBornPoint.super.Begin(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, self.OnFFAProcessStateChanged)
    local BornPointWnd = UIManager:GetWnd(UIDef.UI_FFA_SELECT_BORNPOINT)
    if not BornPointWnd then
        self:LogError("GuideActionSelectResIcon:Begin BornSelectWnd is nil")
        return
    end
    local tbArea = BornPointWnd:GetNoobParachutingArea()
    self:DebugLog("GuideActionSelectBornPoint OnDelayTimerFunc tbArea = " .. tostring(tbArea))
end

function GuideActionSelectBornPoint:RefreshOnGuideWnd()
    GuideActionSelectBornPoint.super.RefreshOnGuideWnd(self)
    self.EventHelper:FireEvent(ClientEventDef.EV_FFA_ENABLE_SELECTPOINT_MAP_PINCH, false)
end

function GuideActionSelectBornPoint:DoAction(tbTemplate)
    GuideActionSelectBornPoint.super.DoAction(self, tbTemplate)
    local bRotation = false
    local BornPointWnd = UIManager:GetWnd(UIDef.UI_FFA_SELECT_BORNPOINT)
    if not BornPointWnd then
        self:LogError("ShowSelectEffect BornSelectWnd is nil")
        return
    end
    local ovlMap = BornPointWnd.pWidgetRef.cvsPanel
    local pGeometry = ovlMap:GetCachedGeometry()
    local ClickSize = GetLocalSize(pGeometry)
    local ClickPos = LocalToAbsolute(pGeometry, Vector2D{X=0,Y=0})
    
    local tbArea = BornPointWnd:GetNoobParachutingArea()
    BornPointWnd:SetBorderCheckEnable(false)
    self:DebugLog("OnDelayTimerFunc tbArea = " .. tostring(tbArea))
    local tbPos = {}
    local tbSize = {}
    --local tbTest = {X = 230, Y = 230}
    local tbRotate = {}
    if tbArea then
        for k,v in pairs(tbArea) do
            table.insert(tbPos, v.BoxPos)
            table.insert(tbSize, v.BoxSize)
            self:DebugLog("OnDelayTimerFunc Pos.x = " .. tostring(v.BoxPos.X) .. " Pos.Y = " .. tostring(v.BoxPos.Y))
            --table.insert(tbSize, tbTest)
            table.insert(tbRotate, false)
        end
    else
        table.insert(tbPos, {X = 1409.032470703, Y = 880.88232421875})
        table.insert(tbSize, {X = 61.6, Y = 56.4})
        table.insert(tbPos, {X = 970.68896484375, Y = 215.70625305176})
        table.insert(tbSize, {X = 61.6, Y = 56.4})
        table.insert(tbPos, {X = 876.6533203125, Y = 911.74737548828})
        table.insert(tbSize, {X = 61.6, Y = 56.4})
    end
    self:CallSetBornSelectArea(tbPos, tbSize, ClickPos , ClickSize, L10N:ToString(tbTemplate.l10nGuideText), tbTemplate.szGuidePicPath, tbTemplate.nGuidePos, self, bRotation)
end

function GuideActionSelectBornPoint:OnFFAProcessStateChanged(nState)
    self:DebugLog("GuideActionSelectBornPoint:OnFFAProcessStateChanged nState = " .. tostring(nState))
    if nState and nState == ProtoDR.rFFAProcessState_EState.SELECTION_LOCK then
        self:EndAction()
    end
end

return GuideActionSelectBornPoint
