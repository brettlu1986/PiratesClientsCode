local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local UIManager = require("UIManager")


local UIPopupWndHelper = {}

UIPopupWndHelper.tbUIPopupCache = nil
UIPopupWndHelper.EventHelper = nil
UIPopupWndHelper.szCurrentPopupWndName = nil
UIPopupWndHelper.szShowInWndName = nil
UIPopupWndHelper.bStartPopup = nil
UIPopupWndHelper.bBindEvent = false



local function UnbindEvent(self)
    if(self.bBindEvent)then
        self.bBindEvent = false
        local EventHelper = self.EventHelper
        if(EventHelper ~= nil)then
            EventHelper:UnregisterEvent(ClientEventDef.EV_PRE_CLOSE_UI)
            EventHelper:UnregisterEvent(ClientEventDef.EV_PRE_DESTROY_UI)
        end
    end
end

local function OnPreCloseUI(self, szUIName)
    if(szUIName == self.szCurrentPopupWndName)then
        self:CheckAndPlayPopupWnd()
    end
end

local function OnPreDestroyUI(self, szWndName)
    if(self.szCurrentPopupWndName == szWndName)then
        UnbindEvent(self)
    end
end

local function BindEvent(self)
    if(not self.bBindEvent)then
        self.bBindEvent = true
        local EventHelper = self.EventHelper
        if(EventHelper == nil)then
            EventHelper = SelfEventHelper()
            self.EventHelper = EventHelper
        end
        EventHelper:RegisterEvent(ClientEventDef.EV_PRE_CLOSE_UI, self, OnPreCloseUI)
        EventHelper:RegisterEvent(ClientEventDef.EV_PRE_DESTROY_UI, self, OnPreDestroyUI)
    end
end

function UIPopupWndHelper:AddPopupWnd(szWndName, tbOpenArgs)
    if(self.tbUIPopupCache == nil)then
        self.tbUIPopupCache = {}
    end
    local tbPopupWnd = {szWndName = szWndName, tbOpenArgs = tbOpenArgs}
    table.insert(self.tbUIPopupCache, tbPopupWnd)
    self:CheckAndPlayPopupWnd()
end

function UIPopupWndHelper:CheckAndPlayPopupWnd()
    if(self.tbUIPopupCache ~= nil and #self.tbUIPopupCache > 0)then
        BindEvent(self)
        local tbPopupWnd = self.tbUIPopupCache[1]
        UIManager:OpenWnd(tbPopupWnd.szWndName, tbPopupWnd.tbOpenArgs)
        self.szCurrentPopupWndName = tbPopupWnd.szWndName
        table.remove(self.tbUIPopupCache, 1)
    end
end

-- function UIPopupWndHelper:IsStartPopup()
--     return self.bStartPopup
-- end

-- function UIPopupWndHelper:IsShowPopupWnd()
--     local bPopup = ((self.szShowInWndName == nil and szWndName == UIDef.UI_MAIN ) 
--     or self.szShowInWndName == szWndName)
--     and not self.bStartPopup
--     return bPopup
-- end



return UIPopupWndHelper
