local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local UIManager = require("UIManager")


local UIWndQueueHelper = {}

local tbWndQueue = nil
local szCurrentWndName = nil
local EventHelper = SelfEventHelper()



local function UnbindEvent()
    EventHelper:UnregisterAll()
end

local function GetWndIndex(szWndName)
    if #tbWndQueue == 0 then
        return
    end
    for k, v in ipairs(tbWndQueue)do
        if v.szWndName == szWndName then
            return k
        end
    end
end

local function RemoveWnd(szWndName)
    local nRemoveIndex = GetWndIndex(szWndName)
    if nRemoveIndex then
        table.remove(tbWndQueue, nRemoveIndex)
        if szWndName == szCurrentWndName then
            szCurrentWndName = nil
        end
    end
    log("RemoveWnd,nRemoveIndex=",nRemoveIndex,#tbWndQueue)
    if #tbWndQueue == 0 then
        UnbindEvent()
    end
end

local function CheckAndPopupWnd()
    if(#tbWndQueue > 0)then
        local tbPopupWnd = tbWndQueue[1]
        UIManager:OpenWnd(tbPopupWnd.szWndName, tbPopupWnd.tbOpenArgs)
        szCurrentWndName = tbPopupWnd.szWndName
        log("CheckAndPopupWnd,szCurrentWndName=",szCurrentWndName)
    end
end

local function OnPreCloseUI(szWndName)
    RemoveWnd(szWndName)
    if(szCurrentWndName == nil)then
        CheckAndPopupWnd()
    end
end

local function BindEvent()
    EventHelper:RegisterEventFunc(ClientEventDef.EV_PRE_CLOSE_UI, OnPreCloseUI)
end

function UIWndQueueHelper.AddWnd(szWndName, tbOpenArgs)
    if(tbWndQueue == nil)then
        tbWndQueue = {}
    end
    if #tbWndQueue == 0 then
        BindEvent()
    end

    if not GetWndIndex(szWndName) then
        log("UIWndQueueHelper.AddWnd")
        local tbPopupWnd = {szWndName = szWndName, tbOpenArgs = tbOpenArgs}
        table.insert(tbWndQueue, tbPopupWnd)
    end
    if szCurrentWndName == nil then
        CheckAndPopupWnd()
    end
end

return UIWndQueueHelper
