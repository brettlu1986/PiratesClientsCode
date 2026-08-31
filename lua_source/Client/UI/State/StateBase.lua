-----------------------------------------------------
--File Name    : StateBase.lua
--Author       : Ran Jie
--Create Time  : 2017-03-07
--Description  : UI状态基类
-----------------------------------------------------

local luaclass = require("luaclass")
local StateBase = luaclass("StateBase")

-- import require
local UIManager = require("UIManager")
local UIStateDef = require("UIStateDef")


-- member variable
StateBase.tbOpenWnd = nil                       --进state时，打开的UI
StateBase.tbPermanentWnd = nil                  --出state时，不会被关闭的UI
StateBase.tbActiveWnd = nil                      --重置state时，不会被关闭的UI
StateBase.bDestroyOnExit = true

StateBase.szName = nil
StateBase.nStateType = UIStateDef.StateType.NORMAL

local function GetCurrentWndList()
    --logwarning("[UI]call back="..debug.traceback())
    local tbWndList = {}
    local tbOriginalWndList = UIManager:GetWndList()
    for k, v in pairs(tbOriginalWndList)do
        tbWndList[k] = v
    end
    return tbWndList
end

local function CanReset(self, szWndName)
    local bReset = not self.tbActiveWnd[szWndName] and not self.tbPermanentWnd[szWndName]
    if bReset then
        for k, v in pairs(self.tbOpenWnd) do
            if v == szWndName then
                bReset = false
                break
            end
        end
    end
    return bReset
end

function StateBase:Init(szUIStateName)
    log("[UI]StateBase:Init,szUIStateName="..tostring(szUIStateName))
    self.szName = szUIStateName
    self.tbPermanentWnd = {}
    self.tbActiveWnd = {}
    self.tbOpenWnd = {}
end

function StateBase:Enter(tbParam)
    log("[UI]StateBase:Enter,szUIStateName="..tostring(self.szName))
    UIManager:ClearStack()
    local tbStateParam = tbParam == nil and {} or tbParam
    --打开UI
    local nCount = #self.tbOpenWnd
    for i = 1, nCount do
        local szWndName = self.tbOpenWnd[i]
        UIManager:OpenWnd(szWndName, tbStateParam[szWndName])
    end
end

function StateBase:Exit(bKeepCache)
    log("[UI]StateBase:Exit,szUIStateName="..tostring(self.szName),bKeepCache)
    self:ClearWnd(bKeepCache)
end

function StateBase:Pause()
end

function StateBase:Resume()
end

function StateBase:ClearWnd(bKeepCache)
    local tbWndList = GetCurrentWndList()
    for k, v in pairs(tbWndList) do
        --logdebug("[UI]k="..tostring(k).." permanent="..tostring(self.tbPermanentWnd[k]))
        if(not self.tbPermanentWnd[k])then
            UIManager:CloseWnd( k )
            if self.bDestroyOnExit and (not bKeepCache or not v.tbTemplate.bCache)then
                UIManager:DestroyWnd( k )
            end
        end
    end
    local bFlag = false
    tbWndList = GetCurrentWndList()
    for k, v in pairs(tbWndList) do
        if not self.tbPermanentWnd[k] and (not bKeepCache or not v.tbTemplate.bCache)then
            bFlag = true
            break
        end
    end
    if bFlag then
        self:ClearWnd(bKeepCache)
    end
end

function StateBase:VerifyWndVisibility(Wnd)
    return true
end

function StateBase:Reset()
    local tbWndList = GetCurrentWndList()
    for k, Wnd in pairs(tbWndList) do
        if CanReset(self, k) then
            UIManager:CloseWnd(k)
        end
    end
end

function StateBase:AddActiveWnd(szWndName)
    self.tbActiveWnd[szWndName] = true
end

function StateBase:AddPermanentWnd(szWndName)
    self.tbPermanentWnd[szWndName] = true
end

return StateBase
