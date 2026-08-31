-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass      = require("luaclass")
local GuideTrigger  = luaclass("GuideTrigger")

local SelfEventHelper       = require("SelfEventHelper")
local GuideDebug            = require("GuideDebug")
local GuideTriggerDataTable = require("GuideTriggerDataTable")
-----------------------------------------------------
GuideTrigger.OnBreakFunc        = nil
GuideTrigger.OnEndFunc          = nil
GuideTrigger.bBegin             = nil
GuideTrigger.bEnded             = false
GuideTrigger.EventHelper        = nil
GuideTrigger.tbTemplate         = nil
GuideTrigger.tbGuideTemplate    = nil
GuideTrigger.nIndex             = nil
GuideTrigger.Owner              = nil
GuideTrigger.bIsTrigger         = false
GuideTrigger.priorTrigger       = nil
GuideTrigger.tbNextTrigger        = nil


-----------------------------------------------------
local function LogPreProcess(self, szMsg)
    local szTemp = "[GuideTrigger] "
    local tbTemplate = self.tbTemplate
    local tbGuideTemplate = self.tbGuideTemplate
    if tbTemplate and tbGuideTemplate then
        szTemp = szTemp .. self.tbTemplate.szTriggerType .. ":" .. szMsg .. " nGroup = " .. tbGuideTemplate.nGroup .. " nStep = " .. tbGuideTemplate.nStep .. " nIndex = " .. self.nIndex
    else
        szTemp = szTemp .. szMsg
    end
    return szTemp
end

function GuideTrigger:Init(Owner, priorTrigger, nIndex, tbTemplate, tbGuideTemplate, OnTriggerEndFunc, OnTriggerBreakFunc)
    self.Owner              = Owner
    self.priorTrigger       = priorTrigger
    self.nIndex             = nIndex
    self.tbTemplate         = tbTemplate
    self.tbGuideTemplate    = tbGuideTemplate
    self.OnEndFunc          = OnTriggerEndFunc
    self.OnBreakFunc        = OnTriggerBreakFunc
    self.bBegin             = false
    self.bEnded             = false
    self.EventHelper        = SelfEventHelper()
    local szNextTrigger = tbTemplate.szNext
    self:DebugLog("Init")
    if szNextTrigger ~= "" then
        local tbTriggerTemplate = GuideTriggerDataTable:GetTemplate(szNextTrigger)
        if tbTriggerTemplate then
            local GuideTriggerClass = require("GuideTrigger"..tbTriggerTemplate.szTriggerType)
            local NextTrigger = GuideTriggerClass()
            self:DebugLog("Init NextTrigger TriggerName = " .. "GuideTrigger"..tbTriggerTemplate.szTriggerType)
            NextTrigger:Init(Owner, self, nIndex, tbTriggerTemplate, tbGuideTemplate, OnTriggerEndFunc, OnTriggerBreakFunc)
            self.tbNextTrigger = NextTrigger
        end
    end
    return true
end

function GuideTrigger:Uninit()
    self:DebugLog("Uninit")
    self.OnEndFunc = nil
    self.OnBreakFunc = nil
    if self.tbNextTrigger then
        self.tbNextTrigger:Uninit()
        self.tbNextTrigger = nil
    end
    self.bBegin = false
	if self.bEnded then
        self:DebugLog("already done!")
        return
    end 
    self.bEnded = true

    self.EventHelper:UnregisterAll()
end

function GuideTrigger:Begin()
    self:DebugLog("Begin")
    self.bBegin = true
    self.bEnded = false
    self.bIsTrigger = false
    self.EventHelper:UnregisterAll()
    self:BindEvent(self.EventHelper)
end

function GuideTrigger:End()
    self:DebugLog("End")
    if self.bEnded then
        self:DebugLog("already done!")
        return
    end
    self.bBegin = false
    self.bEnded = true
    self.bIsTrigger = true
    if self.tbNextTrigger then
        self.tbNextTrigger:End()
    end
    self.EventHelper:UnregisterAll()
end

function GuideTrigger:Interrupt()
    self:DebugLog("Interrupt")
    self.bBegin = false
    self.bIsTrigger = false
    self.EventHelper:UnregisterAll()
    if self.tbNextTrigger then
        self.tbNextTrigger:Interrupt()
    end
end

function GuideTrigger:OnEndCallBack()
    self:DebugLog("OnEndCallBack")
    local priorTrigger = self.priorTrigger
    if priorTrigger then
        priorTrigger:OnEndCallBack()
    else
        if self.OnEndFunc then
            self.bIsTrigger = true
            self.OnEndFunc(self.nIndex)
        end
    end
end

function GuideTrigger:Trigger()
    self:DebugLog("Trigger")
    if self.tbNextTrigger then
        self.tbNextTrigger:Begin()
    else
        self:OnEndCallBack()
    end
end

function GuideTrigger:Break()
    self:DebugLog("Break")
    if self.tbTemplate.bBreakWhenDissatisfy then
        self:DebugLog("Break When Dissatisfy")
        local priorTrigger = self.priorTrigger
        if priorTrigger then
            priorTrigger:Break()
        else
            if self.OnBreakFunc then
                self.bIsTrigger = false
                self.OnBreakFunc(self.nIndex)
            end
        end
    end 
end

function GuideTrigger:SetIsTriggerState(bTriggered)
    self:DebugLog("SetIsTriggerState state = " .. tostring(bTriggered))
    self.bIsTrigger = bTriggered
end

function GuideTrigger:IsTrigger()
    self:DebugLog("IsTrigger = " .. tostring(self.bIsTrigger))
    return self.bIsTrigger
end

function GuideTrigger:IsEnded()
    self:DebugLog("IsEnded")
    return self.bEnded
end

function GuideTrigger:ForceEndCurrentGroup()
    self:DebugLog("ForceEndCurrentGroup")
    local pStep = self.Owner
    if not pStep then
        self:DebugLog("ForceEndCurrentGroup Step is nil!")
        return
    end
    local pGroup = pStep.Owner
    if not pGroup then
        self:DebugLog("ForceEndCurrentGroup Group is nil!")
        return
    end
    pGroup:ForceEnd()
end

function GuideTrigger:BindEndDelegate(Func, Obj)
    self.OnTriggerEnd:Bind(Func, Obj)
end

function GuideTrigger:BindBreakDelegate(Func, Obj)
    self.OnTriggerBreak:Bind(Func, Obj)
end

function GuideTrigger:SetSharedInfo(szKey, value)
    self:DebugLog("SetSharedInfo")
    self.Owner:SetSharedInfo(szKey, value)
end

function GuideTrigger:GetSharedInfo(szKey)
    self:DebugLog("GetSharedInfo")
    return self.Owner:GetSharedInfo(szKey)
end

function GuideTrigger:BindEvent(EventHelper)
    self:DebugLog("BindEvent")
end

function GuideTrigger:DebugLog(szMsg)
    szMsg = LogPreProcess(self, szMsg)
    GuideDebug:DebugLog(szMsg)
end

function GuideTrigger:Log(szMsg)
    szMsg = LogPreProcess(self, szMsg)
    GuideDebug:Log(szMsg)
end

function GuideTrigger:LogError(szMsg)
    szMsg = LogPreProcess(self, szMsg)
    GuideDebug:LogError(szMsg)
end

return GuideTrigger
