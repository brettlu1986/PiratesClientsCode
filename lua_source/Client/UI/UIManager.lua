-----------------------------------------------------
--File Name    : UIManager.lua
--Author       : Song Fuhao
--Create Time  : 2016-06-15
--Description  : 加载界面
-----------------------------------------------------

local UIManager = {}

local WndDataTable = require("WndDataTable")
local UIStateHelper = require("UIStateHelper")
local UIWndStackHelper = require("UIWndStackHelper")
local UIStateDef = require("UIStateDef")
local ResourceCacheSystem = require("ResourceCacheSystem")
local UIDef = require("UIDef")
local DelayTimer = require("DelayTimer")
local ResourceManager = require("ResourceManager")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

-- luacheck: push ignore 241
-- Holds all widget so they are not GC-ed.
local tbWndList             = {}    -- 窗口集合
local tbWidgetHolderList    = {}    -- 资源管理
-- local tbNeedBlurBGWnds      = {}
-- local tbNeedTopbarWnds      = {}
local tbRegisterAnimEndForcely = {}
local tbOpenWndList         = {}    --打开状态的窗口
local tbTryToCloseBlurWndTimer = nil
local tbTryToCloseTopWndTimer = nil
local tbSceneRenderingOffDelay = nil
-- luacheck: pop

local SWITCH_RENDERING_FUNC = LowEntryExtendedStandardLibrary.SetWorldRenderingEnabled--  KMUMGLibrary.SwitchRendering
local DELAY_SCENE_RENDERING_OFF = 1
local DELAY_SCENE_RENDERING_OFF_ASYNC = 2

-- local function TryToOpenBlurWnd(Wnd)
--     if Wnd:IsNeedBlurBG() then
--         if tbTryToCloseBlurWndTimer then
--             DelayTimer:ClearTimer(tbTryToCloseBlurWndTimer)
--             tbTryToCloseBlurWndTimer = nil
--         end
--         UIManager:OpenWnd(UIDef.UI_WINDOWS_BG)
--         tbNeedBlurBGWnds[Wnd:GetWndName()] = true
--     end
-- end

-- local function TryToCloseBlurWnd(Wnd)
--     if Wnd:IsNeedBlurBG() then
--         tbNeedBlurBGWnds[Wnd:GetWndName()] = nil
--         if tbTryToCloseBlurWndTimer == nil then
--             tbTryToCloseBlurWndTimer = DelayTimer:RunNextTick(function()
--                 tbTryToCloseBlurWndTimer = nil
--                 if next(tbNeedBlurBGWnds) == nil then
--                     UIManager:CloseWnd(UIDef.UI_WINDOWS_BG)
--                 end
--             end)
--         end
--     end
-- end

-- local function TryToOpenTopWnd(Wnd)
--     if Wnd:IsNeedTopBar() then
--         if tbTryToCloseTopWndTimer then
--             DelayTimer:ClearTimer(tbTryToCloseTopWndTimer)
--             tbTryToCloseTopWndTimer = nil
--         end
--         UIManager:OpenWnd(UIDef.UI_WINDOWS_TOP_BAR)
--         tbNeedTopbarWnds[Wnd:GetWndName()] = true
--     end
-- end

-- local function TryToCloseTopWnd(Wnd)
--     if Wnd:IsNeedTopBar() then
--         tbNeedTopbarWnds[Wnd:GetWndName()] = nil
--         if tbTryToCloseTopWndTimer == nil then
--             tbTryToCloseTopWndTimer = DelayTimer:RunNextTick(function()
--                 tbTryToCloseTopWndTimer = nil
--                 if next(tbNeedTopbarWnds) == nil then
--                     UIManager:CloseWnd(UIDef.UI_WINDOWS_TOP_BAR)
--                 end
--             end)
--         end
--     end
-- end

local function TrySceneRenderingOn()
    if tbSceneRenderingOffDelay then
        DelayTimer:ClearTimer(tbSceneRenderingOffDelay)
        tbSceneRenderingOffDelay = nil
    end
    log("[UI]TrySceneRenderingOn")
    SWITCH_RENDERING_FUNC(true)
end

local function TrySceneRenderingOff(bImmediate, nDelay)
    if bImmediate then
        log("[UI]TrySceneRenderingOff now")
        SWITCH_RENDERING_FUNC(false)
        if tbSceneRenderingOffDelay then
            DelayTimer:ClearTimer(tbSceneRenderingOffDelay)
            tbSceneRenderingOffDelay = nil
        end
    else
        if tbSceneRenderingOffDelay then
            return
        end
        tbSceneRenderingOffDelay = DelayTimer:DelayRun(function()
            log("[UI]TrySceneRenderingOff delayed")
            SWITCH_RENDERING_FUNC(false)
            tbSceneRenderingOffDelay = nil
        end, nDelay, "UIManager TrySceneRenderingOff")
    end
end

local function CheckSceneRendering(self, bCloseWnd)
    local szTopWnd = UIWndStackHelper:GetWndStackTop()
    log("[UI]szTopWnd=", szTopWnd, bCloseWnd)
    if szTopWnd then
        local tbTopWnd = self:GetWnd(szTopWnd)
        if tbTopWnd and tbTopWnd.tbTemplate.bSceneRenderingOff then
            local nDelay = DELAY_SCENE_RENDERING_OFF
            if not tbTopWnd.pWidgetRef then
                nDelay = DELAY_SCENE_RENDERING_OFF_ASYNC
            end
            TrySceneRenderingOff(bCloseWnd, nDelay)

        else
            TrySceneRenderingOn()
        end
    else
        TrySceneRenderingOn()
    end
end

local function TryPushWnd(self, Wnd)
    if not Wnd then
        return
    end
    if Wnd.tbTemplate.bPushToStack then
        local szTopWnd = UIWndStackHelper:GetWndStackTop()
        if szTopWnd then
            local TopWnd = self:GetWnd(szTopWnd)
            if TopWnd then
                TopWnd:Pause()
            end
        end
        UIWndStackHelper:Push(Wnd.tbTemplate.szWndName)
    end
end

local function TryPopWnd(self, Wnd)
    if not Wnd then
        return
    end
    local szLastTopWnd = UIWndStackHelper:GetWndStackTop()
    UIWndStackHelper:Pop(Wnd.tbTemplate.szWndName)
    local szTopWnd = UIWndStackHelper:GetWndStackTop()
    if not szTopWnd or (szLastTopWnd == szTopWnd) then
        return
    end
    local TopWnd = self:GetWnd(szTopWnd)
    if TopWnd then
        TopWnd:Resume()
    end
end

function UIManager:Init()
    UIStateHelper:Init()
    return true
end

function UIManager:Uninit()
    UIStateHelper:Uninit()
    if tbTryToCloseBlurWndTimer then
        DelayTimer:ClearTimer(tbTryToCloseBlurWndTimer)
        tbTryToCloseBlurWndTimer = nil
    end
    if tbTryToCloseTopWndTimer then
        DelayTimer:ClearTimer(tbTryToCloseTopWndTimer)
        tbTryToCloseTopWndTimer = nil
    end
    if tbSceneRenderingOffDelay then
        DelayTimer:ClearTimer(tbSceneRenderingOffDelay)
        tbSceneRenderingOffDelay = nil
    end
    self:DestroyAllWnd()
end

-- Core Function
function UIManager:CreateWnd(szWndName, tbParams)
    local tbTemplate = WndDataTable:GetTemplate(szWndName)
    if not tbTemplate then
        logerror('[UI] CreateWnd failed, tbTemplate is nil, please check config table, szWndName =', szWndName)
        return
    end
    local szScriptName = tbTemplate.szScriptName
    local tbWndClass = require(szScriptName)
    local Wnd = tbWndClass()
    tbParams = tbParams or {}
    tbParams.UIManager = UIManager
    tbParams.tbAnimNameForcely = tbRegisterAnimEndForcely[szWndName]
    Wnd:Create(tbTemplate, tbParams)
    tbWndList[szWndName] = Wnd
    return Wnd
end


function UIManager:OpenWnd(szWndName, tbParams)
    ResourceManager:VerifyUObjectCount()
    local Wnd = self:GetWnd(szWndName)
    if Wnd then
        Wnd:CheckOpenState()
        Wnd = self:GetWnd(szWndName)
    end
    tbParams = tbParams and tbParams or {}
    if not Wnd then
        Wnd = self:CreateWnd(szWndName, tbParams)
    end
    if not Wnd:CanOpen() then
        log("[UI] Can not open wnd, szWndName =", szWndName)
        self:DestroyWnd(szWndName)
        return nil
    end
    if not self:IsWndOpen(szWndName) then
        tbOpenWndList[szWndName] = true
        --TryToOpenBlurWnd(Wnd)
        --TryToOpenTopWnd(Wnd)
        if tbParams.bVisibility then
            logwarning("[UI] UIManager:OpenWnd, Param:bVisibility is conflict!!")
        end
        tbParams.bVisibility = UIStateHelper:VerifyWndVisibility(Wnd)
        Wnd:Open(tbParams)
        if szWndName ~= UIDef.UI_GUIDE then
            TryPushWnd(self, Wnd)
        end
        CheckSceneRendering(self)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_UI_MANAGER_OPEN_UI_FINISH, szWndName)
    return Wnd
end

function UIManager:CloseWnd(szWndName, tbParams)
    local Wnd = self:GetWnd(szWndName)
    if not Wnd then
        return nil
    end
    if self:IsWndOpen(szWndName) then
        Wnd:Close(tbParams)
        --TryToCloseBlurWnd(Wnd)
        --TryToCloseTopWnd(Wnd)
        if szWndName ~= UIDef.UI_GUIDE then
            TryPopWnd(self, Wnd)
        end
        CheckSceneRendering(self, true)
        tbOpenWndList[szWndName] = nil
    end
    EventManager:OnFireEvent(ClientEventDef.EV_UI_MANAGER_CLOSE_UI_FINISH, szWndName)
    return Wnd
end


function UIManager:ToggleWnd(szWndName, tbParams)
    local Wnd = self:GetWnd(szWndName)
    if Wnd then
        if self:IsWndOpen(szWndName) then
            self:CloseWnd(szWndName, tbParams)
        else
            self:OpenWnd(szWndName, tbParams)
        end
    else
        Wnd = self:OpenWnd(szWndName, tbParams)
    end
    return Wnd
end

function UIManager:DestroyWnd(szWndName)
    local Wnd = self:GetWnd(szWndName)
    if not Wnd then
        return
    end

    Wnd:Destroy()
    tbWndList[szWndName] = nil
    tbOpenWndList[szWndName] = nil
    CheckSceneRendering(self, true)
end

function UIManager:IsWndVisible(szWndName)
    local Wnd = self:GetWnd(szWndName)
    if not Wnd then
        return false
    end
    return Wnd:IsVisible()
end

function UIManager:IsWndOpen(szWndName)
    local bIsOpen = tbOpenWndList[szWndName] or false
    return bIsOpen
end

function UIManager:CloseAllWnd()
    for _,Wnd in pairs(tbWndList) do
        Wnd:Close()
    end
    tbOpenWndList = {}
    CheckSceneRendering(self, true)
end


function UIManager:DestroyAllWnd()
    for _,Wnd in pairs(tbWndList) do
        Wnd:Destroy()
    end
    tbWndList = {}
    tbOpenWndList = {}
    CheckSceneRendering(self, true)
end

function UIManager:GetWnd(szWndName)
    return tbWndList[szWndName]
end

--UI状态切换
function UIManager:PushState(szStateName, tbParams, bImmediateSwitch, bKeepLastStateCache)
    UIStateHelper:PushState(szStateName, tbParams, bImmediateSwitch, bKeepLastStateCache)
end

function UIManager:PopState(szStateName, bKeepStateCache)
    UIStateHelper:PopState(szStateName, bKeepStateCache)
end

function UIManager:PopAllState(bKeepStateCache)
    UIStateHelper:PopAllState(bKeepStateCache)
end

function UIManager:ResetCurrentState()
    UIStateHelper:Reset()
end

function UIManager:SnapshotUI(bSnapshot, tbSnapshotUI)
    local tbCurrentWndList = {}
    for k, v in pairs(tbOpenWndList) do
        tbCurrentWndList[k] = v
    end
    local tbRemainMap = {}
    for k, v in pairs(tbSnapshotUI) do
        tbRemainMap[v] = true
    end
    local pVisibility = bSnapshot and ESlateVisibility_Collapsed or ESlateVisibility_SelfHitTestInvisible
    for k, v in pairs(tbCurrentWndList) do
        if not tbRemainMap[k] then
            local tbWnd = self:GetWnd(k)
            if tbWnd and tbWnd.pWidgetRef then
                tbWnd.pWidgetRef:SetVisibility(pVisibility)
            end 
        end
    end
end

local function HoldUIObject(self, pUIObject)
    if pUIObject then
        local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pUIObject)
        tbWidgetHolderList[nUniqueID] = luaholder(pUIObject)
    end
end

local function UnholdUIObject(self, pUIObject)
    if pUIObject then
        local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pUIObject)
        tbWidgetHolderList[nUniqueID] = nil
    end
end

-- 创建一个UMG
-- @param   szUIPath    UI资源路径
-- @return  pWidgetRef  UMG引用
function UIManager:CreateUMG(szUIPath, pWidgetObject)
    local pRet = ResourceCacheSystem:CreateUMGObject(szUIPath)
    if(pRet) then
        return pRet
    end
    if type(szUIPath) ~= 'string' then
        logerror('[UI] Create UMG failed, type(szUIPath) ~= string.')
        return nil
    end
    local pWidgetClass = pWidgetObject
    if not pWidgetClass then
        pWidgetClass = szUIPath:load()
        if not pWidgetClass then
            logerror('[UI] Create UMG failed, load UMG class failed. UIPath :', szUIPath)
            return nil, nil
        end
        if not KismetMathLibrary.ClassIsChildOf(pWidgetClass, PiratesUserWidget) then
            logerror('[UI] UMG is not a child of PiratesUserWidget. UIPath :', szUIPath)
            return
        end
    end
    local pWidgetRef = WidgetBlueprintLibrary.Create(GWorld, pWidgetClass, nil)
    if(pWidgetRef ~= nil) then
        HoldUIObject(self, pWidgetRef)
    end
    return pWidgetRef
end

function UIManager:DestroyUMG(pWidgetRef)
    if(pWidgetRef == nil) then
        logerror("UIManager:DestroyUMG failed, invalid pWidgetRef: ", debug.traceback())
        return
    end

    if(ResourceCacheSystem:DestroyUMGObject(pWidgetRef)) then
        return
    end
    UnholdUIObject(self, pWidgetRef)
end

-- 创建一个Widget
-- @param   pClass  Widget的Class，直接写名字即可，如Image、Border
-- @return  pWidget  Widget引用
function UIManager:CreateWidget(pClass, bHoldUI)
    local pWidget = ExtendBlueprintFunctions.CreateObject(pClass, GameplayStatics.GetGameInstance(GWorld))
    if not pWidget then
        logerror('[UI] Create Widget failed, LuaCallStack:', debug.traceback())
    end
    if(bHoldUI == nil or bHoldUI == true) then
        HoldUIObject(self, pWidget)
    end
    return pWidget
end

function UIManager:DestroyWidget(pWidget)
    if(pWidget == nil) then
        logerror("UIManager:DestroyWidget failed, invalid pWidget: ", debug.traceback())
        return
    end
    UnholdUIObject(self, pWidget)
end

function UIManager:GetInCinematicMode()
    local ActiveState = UIStateHelper:GetActiveState()
    if(ActiveState ~= nil)then
        log("[UI]GetInCinematicMode="..tostring(ActiveState.nStateType))
        return ActiveState.nStateType == UIStateDef.StateType.CINEMATIC
    end
    return false
end

function UIManager:GetActiveState()
    return UIStateHelper:GetActiveState()
end

--UI堆栈管理
function UIManager:ClearStack()
    UIWndStackHelper:Clear()
end

function UIManager:IsStackTopUI(szWndName)
    return UIWndStackHelper:IsStackTopUI(szWndName)
end

local function IsTop(self, szWndName, tbWndStack, nIndex)
    if not tbWndStack then
        return false
    end
    if nIndex <= 0 then
        return false
    end
    local szTopWnd = tbWndStack[nIndex]
    log("topwnd="..tostring(szTopWnd) .. " targetWnd = " .. szWndName .. " nWndCount = " .. tostring(nIndex))
    local nMaxZorder = 0
    for i, szName in pairs(tbWndStack) do
        local Wnd = self:GetWnd(szName)
        if Wnd then
            local nZOrder = Wnd.tbTemplate.nZOrder
            nMaxZorder = nZOrder > nMaxZorder and nZOrder or nMaxZorder
        end
    end
    if szTopWnd ~= nil and szTopWnd == szWndName then
        local TopWnd = self:GetWnd(szWndName)
        if TopWnd then
            local nZOrder = TopWnd.tbTemplate.nZOrder
            return nZOrder >= nMaxZorder 
        else
            return false
        end
    else
        local bVisible = self:IsWndVisible(szTopWnd)
        log("bVisible = " .. tostring(bVisible))
        if not bVisible then
            nIndex = nIndex - 1
            log("Recursion nIndex = " .. tostring(nIndex))
            return IsTop(self, szWndName, tbWndStack, nIndex)
        end
        return false
    end
end

function UIManager:IsShowTopUI(szWndName)
    local tbWndStack = UIWndStackHelper:GetWndStack()
    local nWndCount = #tbWndStack
    local bResult = IsTop(self, szWndName, tbWndStack, nWndCount)
    log("IsShowTopUI" .. tostring(bResult))
    return bResult
end

function UIManager:GetWndStackTop()
    return UIWndStackHelper:GetWndStackTop()
end

function UIManager:GetWndStack()
    return UIWndStackHelper:GetWndStack()
end

function UIManager:GetWndList()
    return tbWndList
end

function UIManager:SetRegisterAnimEndForcely(tbUIAnimName)
    tbRegisterAnimEndForcely = tbUIAnimName
end

function UIManager:SetRegisterAnimEndForcelyWithWndName(szWndName, szAnimName)
    local tbAnims = tbRegisterAnimEndForcely[szWndName]
    if not tbAnims then
        tbRegisterAnimEndForcely[szWndName] = {}
        tbAnims = tbRegisterAnimEndForcely[szWndName]
    end
    table.insert(tbAnims, szAnimName)
end

function UIManager:GetOpenWndList()
    return tbOpenWndList
end

return UIManager
