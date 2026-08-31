-----------------------------------------------------
--File Name    : GuideTriggerCloseUI.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerCloseUI = luaclass("GuideTriggerCloseUI",GuideTrigger)

local ClientEventDef = require("ClientEventDef")
local UIManager = require("UIManager")


--override
function GuideTriggerCloseUI:BindEvent(EventHelper)
    local Wnd = UIManager:GetWnd(self.tbTemplate.szOpenUIName)
    EventHelper:RegisterEvent(ClientEventDef.EV_PRE_CLOSE_UI, self, self.OnCloseUI)
    if(Wnd == nil or not UIManager:IsWndOpen(self.tbTemplate.szOpenUIName))then
        self:Trigger()
        return
    end
    
end

function GuideTriggerCloseUI:OnCloseUI(szWndName)
    self:DebugLog("OnOpenUI,szWndName="..tostring(szWndName).." self.tbTemplate.szOpenUIName="..tostring(self.tbTemplate.szOpenUIName))
    if(szWndName ~= nil and szWndName == self.tbTemplate.szOpenUIName)then
        self:Trigger()
    end
end

function GuideTriggerCloseUI:IsTrigger()
    local Wnd = UIManager:GetWnd(self.tbTemplate.szOpenUIName)
    if(Wnd == nil or not UIManager:IsWndOpen(self.tbTemplate.szOpenUIName))then
        self.bIsTrigger = true
    else 
        self.bIsTrigger = false
    end
    return self.bIsTrigger
end

return GuideTriggerCloseUI
