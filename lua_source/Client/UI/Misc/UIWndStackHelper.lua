-----------------------------------------------------
--File Name    : UIWndStackHelper.lua
--Author       : Ran Jie
--Create Time  : 2017-08-22
--Description  : UI窗口堆栈管理
-----------------------------------------------------

local UIWndStackHelper = {}

local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")


UIWndStackHelper.tbWndStack = {}    



function UIWndStackHelper:Push(szWndName)
    
    local nWndCount = #self.tbWndStack
    if(nWndCount > 0)then
        -- log("[UIWndStack]StackBack:wndname="..self.tbWndStack[nWndCount])
        EventManager:OnFireEvent(ClientEventDef.EV_UI_STACK_BACK, self.tbWndStack[nWndCount])
    end
    table.insert(self.tbWndStack, szWndName)
    EventManager:OnFireEvent(ClientEventDef.EV_UI_STACK_TOP, szWndName)
    -- log("[UIWndStack]Push:Wnd.tbTemplate.szWndName="..szWndName.." nWndCount="..#self.tbWndStack)
end

function UIWndStackHelper:Pop(szWndName)
    local tbWndStack = self.tbWndStack
    local nWndCount = #tbWndStack
    -- log("[UIWndStack]Pop:wnd= "..szWndName)
    if(nWndCount > 0)then
        local TopWnd = tbWndStack[nWndCount]
        if(szWndName == TopWnd)then
            -- log("[UIWndStack]1111------Pop:szWndName="..szWndName.." nWndCount="..nWndCount)
            table.remove(tbWndStack)
            nWndCount = #tbWndStack
            -- log("[UIWndStack]222-----Pop:nWndCount="..nWndCount)
            if(nWndCount > 0)then
                EventManager:OnFireEvent(ClientEventDef.EV_UI_STACK_TOP, tbWndStack[nWndCount])
            end
        else
            local nIndex = 1
            while nIndex <= nWndCount do
                local nRemoveIndex = nWndCount + 1
                for i = nIndex, nWndCount do
                    if(tbWndStack[i] == szWndName)then
                        table.remove(tbWndStack, i)
                        nWndCount = #tbWndStack
                        nRemoveIndex = i
                        break
                    end
                end
                nIndex = nRemoveIndex
            end 
            if(#tbWndStack > 0)then
                EventManager:OnFireEvent(ClientEventDef.EV_UI_STACK_TOP, tbWndStack[nWndCount])
            end
        end
        return tbWndStack[nWndCount]
    end
end

function UIWndStackHelper:Clear()
    self.tbWndStack = {}
end

function UIWndStackHelper:IsStackTopUI(szWndName)
    local nWndCount = #self.tbWndStack
    local TopWnd = self.tbWndStack[nWndCount]
    --logdebug("topwnd="..tostring(TopWnd).." nWndCount="..tostring(nWndCount))
    if(TopWnd ~= nil and TopWnd == szWndName)then
        return true
    end
    return false
end

function UIWndStackHelper:GetWndStack()
    return self.tbWndStack
end

function UIWndStackHelper:GetWndStackTop()
    local nWndCount = #self.tbWndStack
    if nWndCount > 0 then
        return self.tbWndStack[nWndCount]
    end
end

return UIWndStackHelper
