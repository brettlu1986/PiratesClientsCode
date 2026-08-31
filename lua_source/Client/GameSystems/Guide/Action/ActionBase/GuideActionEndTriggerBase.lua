-----------------------------------------------------
--File Name    : GuideActionEndGroupTrigger.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionEndTriggerBase     = luaclass("GuideActionEndTriggerBase")

local GuideDebug            = require("GuideDebug")
local SelfEventHelper       = require("SelfEventHelper")
local SelfTimerHelper       = require("SelfTimerHelper")
local UIManager             = require("UIManager")
-----------------------------------------------------

--member veriable

GuideActionEndTriggerBase.Owner             = nil
GuideActionEndTriggerBase.szEndTriggerName  = nil
GuideActionEndTriggerBase.tbTemplate        = nil
GuideActionEndTriggerBase.nGroup            = 0
GuideActionEndTriggerBase.nStep             = 0
GuideActionEndTriggerBase.TriggeredCallBack = nil
GuideActionEndTriggerBase.tbParam           = nil
GuideActionEndTriggerBase.TimerHelper       = nil 
-----------------------------------------------------

local function LogPreProcess(self, szMsg)
    local szTemp = "[GuideActionEndTrigger] " .. szMsg
    if self.szEndTriggerName then
        szTemp = "[GuideActionEndTrigger] " .. self.szEndTriggerName .. ":" .. szMsg .. " ngroup = ".. self.nGroup .. " nstep = " .. self.nStep
    end
    return szTemp
end

function GuideActionEndTriggerBase:Init(Owner, szEndTriggerName, tbTemplate, nGroup, nStep, OnTriggeredCallBack)
    self.Owner              = Owner
    self.szEndTriggerName   = szEndTriggerName
    self.tbTemplate         = tbTemplate
    self.nGroup             = nGroup
    self.nStep              = nStep
    self.TriggeredCallBack  = OnTriggeredCallBack
    self.EventHelper        = SelfEventHelper()
    self.TimerHelper        = SelfTimerHelper()
    self:DebugLog("Init")
    return true
end

function GuideActionEndTriggerBase:Uninit()
    self:DebugLog("Uninit")
    self.szEndTriggerName       = nil
    self.nGroup                 = 0
    self.nStep                  = 0
    self.EventHelper:UnregisterAll()
    self.TimerHelper:ClearAllTimer()
end

function GuideActionEndTriggerBase:Begin(tbParam)
    self:DebugLog("Begin")
    self.EventHelper:UnregisterAll()
    self.TimerHelper:ClearAllTimer()
    self.tbParam = tbParam
    self:BindEvent(tbParam)
end

function GuideActionEndTriggerBase:End()
    assert(self.Owner, "self Owner is nil!")
    self:DebugLog("End")
    self.EventHelper:UnregisterAll()
    self.TimerHelper:ClearAllTimer()
    
end

function GuideActionEndTriggerBase:Triggered()
    assert(self.TriggeredCallBack, "TriggeredCallBack is nil!")
    self:DebugLog("Triggered")
    self.TriggeredCallBack(self.Owner)
    self.OnTriggeredCallBack = nil
end

function GuideActionEndTriggerBase:Interrupt()
    self:DebugLog("Interrupt")
    self.EventHelper:UnregisterAll()
    self.TimerHelper:ClearAllTimer()
end

function GuideActionEndTriggerBase:BindEvent(tbParam)
    self:DebugLog("BindEvent")
end

function GuideActionEndTriggerBase:GetParentUserWidget()
    self:DebugLog("GetParentUserWidget")
    local tbTemplate = self.tbTemplate
    local Wnd = UIManager:GetWnd(tbTemplate.szUIName)
    if(Wnd == nil or not UIManager:IsWndOpen(tbTemplate.szUIName))then
        self:LogError("GetPrefab,wnd nil,uiname="..tostring(tbTemplate.szUIName))
        return
    end
    local pWidgetRef = Wnd.pWidgetRef
    for k, v in ipairs(tbTemplate.tbPrefabName)do
        pWidgetRef = pWidgetRef[v]
        if not pWidgetRef then
            self:LogError("GetPrefab,can't find prefab,name=", v)
            return
        end
    end
    return pWidgetRef
end

function GuideActionEndTriggerBase:GetSelectWidgets()
    self:DebugLog("GetSelectWidgets tbWidgetName" .. tostring(self.tbTemplate.tbWidgetName[1]))
    local tbSelectWidgets = {}
    local tbTemplate = self.tbTemplate
    local pWidgetRef = self:GetParentUserWidget()
    self:DebugLog("GetSelectWidgets pWidgetRef = " .. tostring(pWidgetRef))
    if not pWidgetRef then
        return tbSelectWidgets
    end
    for k, v in ipairs(tbTemplate.tbWidgetName)do
        self:DebugLog("GetSelectWidgets tbWidgetName = " .. v)
        local pSelectWidget = pWidgetRef[v]
        if pSelectWidget then
            table.insert(tbSelectWidgets, pSelectWidget)
        else
            self:LogError("GetSelectWidgets,can't find widgeht,name=", v)
        end
    end
    return tbSelectWidgets
end

function GuideActionEndTriggerBase:GetSelectPrefab()
    self:DebugLog("GetSelectPrefab tbWidgetName" .. tostring(self.tbTemplate.tbWidgetName[1]))
    local tbSelectWidgets = {}
    local pWidgetRef = self:GetParentUserWidget()
    self:DebugLog("GetSelectWidgets pWidgetRef = " .. tostring(pWidgetRef))
    if not pWidgetRef then
        return tbSelectWidgets
    end
    table.insert(tbSelectWidgets, pWidgetRef)
    return tbSelectWidgets
end

function GuideActionEndTriggerBase:DebugLog(szMsg)
    szMsg = LogPreProcess(self, szMsg)
    GuideDebug:DebugLog(szMsg)
end

function GuideActionEndTriggerBase:Log(szMsg)
    szMsg = LogPreProcess(self, szMsg)
    GuideDebug:Log(szMsg)
end

function GuideActionEndTriggerBase:LogError(szMsg)
    szMsg = LogPreProcess(self, szMsg)
    GuideDebug:LogError(szMsg)
end

return GuideActionEndTriggerBase
