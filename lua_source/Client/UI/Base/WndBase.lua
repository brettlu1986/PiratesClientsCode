-----------------------------------------------------
--File Name    : WndBase.lua
--Author       : Song Fuhao
--Create Time  : 2016-06-15
--Description  : UI逻辑脚本基类
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = luaclass("WndBase")

local SelfEventHelper = require("SelfEventHelper")
local SelfPrefabHelper = require("SelfPrefabHelper")
local SelfTimerHelper = require("SelfTimerHelper")
local SelfWidgetHelper = require("SelfWidgetHelper")
local SelfUILogicHelper = require("SelfUILogicHelper")

local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local UISetUtils = require("UISetUtils")
local ResourceManager = require("ResourceManager")
local WidgetAnimationHandle = require("WidgetAnimationHandle")

-- member variable
WndBase.tbTemplate      = nil       -- 窗口相关配置数据
WndBase.tbOpenArgs      = nil       -- 窗口Open时传入的参数
WndBase.tbCloseArgs     = nil       -- 窗口Close时传入的参数
WndBase.pWidgetRef      = nil       -- UMG引用
WndBase.bEntered        = false
WndBase.bEventBinded    = false
WndBase.bShowed         = false
WndBase.tbAnimDelegate  = nil
WndBase.bClosing        = false
WndBase.nZOrder         = 0

--[[
    Helper用于对UI内部的行为进行统一管理，以防止出现未知的问题，如有特殊需求，可以直接使用原生的调用方式
    EventHelper     在此绑定的所有Event，在Exit时会自动解绑
    PrefabHelper    所有的Prefab必须通过此Helper进行Create/Bind，此Helper会自动维护UI与各Prefab的各生命周期关系
    TimerHelper     在此绑定的所有Timer，在Exit时会自动Stop，在UnloadResource时自动Clear
]]
WndBase.EventHelper     = nil
WndBase.PrefabHelper    = nil
WndBase.TimerHelper     = nil
WndBase.WidgetHelper    = nil
WndBase.UILogicHelper   = nil
WndBase.UIManager       = nil
WndBase.tbRegisterAnimEndForcely = nil
WndBase.tbAsyncHandles  = nil

local DEFAULT_SEED = 1

local function AddToViewport(self)
    log('[UI] WndBase : AddToViewport, name: ' .. self.tbTemplate.szWndName .. "ZOrder: " .. self.nZOrder)
    self.pWidgetRef:AddToViewport(self.nZOrder)
    local Visibility = self.tbOpenArgs.bVisibility and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Collapsed
    self.pWidgetRef:SetVisibility(Visibility)
    log('[UI] WndBase : AddToViewport end, name: ' .. self.tbTemplate.szWndName .. "ZOrder: " .. self.nZOrder)
end

local function AddToViewportWithZOrder(self, nZOrder)
    log('[UI] WndBase : AddToViewportWithZOrder, name: ' .. self.tbTemplate.szWndName .. " ZOrder: " .. nZOrder)
    self.pWidgetRef:AddToViewport(nZOrder)
end

local function RemoveFromViewport(self)
    log('[UI] WndBase : RemoveFromViewport, name:', self.tbTemplate.szWndName)
    self.pWidgetRef:RemoveFromViewport()
    log('[UI] WndBase : RemoveFromViewport end, name:', self.tbTemplate.szWndName)
end

local function AfterLoadResource(self)
    self:Enter()
    self:BindEvent()
    local bAddToView = self.tbOpenArgs.bAddToView
    if bAddToView == nil or bAddToView == true then
        AddToViewport(self)
    end
    self:Show()
    self.EventHelper:FireEvent(ClientEventDef.EV_OPEN_UI, self.tbTemplate.szWndName)
end

local function CancelAsyncResource(self)
    for k, v in ipairs(self.tbAsyncHandles) do
        ResourceManager:CancelLoadAsync(v)
    end
    self.tbAsyncHandles = {}
end

local function LoadAsyncFinished(self, szTempAssetName, pObject, nHandle)
    log('[UI] WndBase : LoadAsyncFinished:', self.tbTemplate.szWndName, szTempAssetName, nHandle)
    self:OnLoadAsyncFinished(szTempAssetName, pObject, nHandle)
    if self.tbAsyncHandles[self.tbTemplate.szUIPath] == nHandle then
        log('[UI] WndBase : LoadAsyncFinished wnd, name:', self.tbTemplate.szWndName)
        self.pWidgetRef = self.UIManager:CreateUMG(self.tbTemplate.szUIPath, pObject)
        self.pWidgetRef.bTopWindow = true
        self:LoadText()
        self:OnLoad()
        self.UILogicHelper:OnLoad()
        AfterLoadResource(self)
    end
    ResourceManager:CancelLoadAsync(nHandle)
    self.tbAsyncHandles[szTempAssetName] = nil
end

local function AsyncLoadResource(self)
    if self.pWidgetRef then
        AfterLoadResource(self)
        return
    end
    log('[UI] WndBase : AsyncLoadResource wnd, name:', self.tbTemplate.szWndName)
    local tbResources = {}
    if self.StaticCollectResources then
        self.StaticCollectResources(tbResources)
    end
    table.insert(tbResources, self.tbTemplate.szUIPath)
    for k, szRourcePath in ipairs(tbResources) do
        if not self.tbAsyncHandles[szRourcePath] then
            local nHandle = ResourceManager:LoadAsync(szRourcePath,
                function(szTempAssetName, pObject, nInHandle)
                    LoadAsyncFinished(self, szTempAssetName, pObject, nInHandle)
                end, false)
            if nHandle < 0 then
                error("[UI] WndBase : AsyncLoadResource invalid handle, wnd, name:", self.tbTemplate.szWndName)
            else
                self.tbAsyncHandles[szRourcePath] = nHandle
            end
        end
    end
end

local function LoadResource(self)
    if self.pWidgetRef then
        return
    end
    log('[UI] WndBase : Load wnd, name:', self.tbTemplate.szWndName)
    self.pWidgetRef = self.UIManager:CreateUMG(self.tbTemplate.szUIPath)
    self.pWidgetRef.bTopWindow = true
    self:LoadText()
    self:OnLoad()
    self.UILogicHelper:OnLoad()
end

local function UnloadResource(self)
    if not self.pWidgetRef then
        return
    end
    log('[UI] WndBase : Unload wnd, name:', self.tbTemplate.szWndName)
    self:OnUnload()
    self.UILogicHelper:OnUnload()
    self.PrefabHelper:UnbindAllPrefab()
    self.WidgetHelper:DestroyAllWidget()
    self.UIManager:DestroyUMG(self.pWidgetRef)
    self.pWidgetRef = nil
end



--[[
    public interface
]]

function WndBase:Create(tbTemplate, tbParams)
    log('[UI] WndBase : create wnd, name:', tbTemplate.szWndName)
    self.tbTemplate = tbTemplate
    self.nZOrder = tbTemplate.nZOrder
    self.tbOpenArgs = tbParams and tbParams or {}
    self.UIManager = tbParams.UIManager
    self.tbRegisterAnimEndForcely = tbParams.tbAnimNameForcely
    self.EventHelper = SelfEventHelper()
    self.PrefabHelper = SelfPrefabHelper()
    self.TimerHelper = SelfTimerHelper()
    self.WidgetHelper = SelfWidgetHelper()
    self.UILogicHelper = SelfUILogicHelper()

    self.PrefabHelper:SetOwner(self)
    self.PrefabHelper:SetWndCreator(self.UIManager)
    self.UILogicHelper:SetOwner(self)

    self.tbAnimDelegate = {}
    self.tbAsyncHandles = {}

    self:OnCreate()
end

function WndBase:Destroy()
    log('[UI] WndBase : destroy wnd, name:', self.tbTemplate.szWndName)
    self.EventHelper:FireEvent(ClientEventDef.EV_PRE_DESTROY_UI, self.tbTemplate.szWndName)
    if self.bEntered then
      self:Exit()
    end
    UnloadResource(self)
    self.UILogicHelper:DestroyAllUILogic()
    self:OnDestroy()
    self.EventHelper:FireEvent(ClientEventDef.EV_DESTROY_UI, self.tbTemplate.szWndName)

    self.EventHelper = nil
    self.PrefabHelper = nil
    self.TimerHelper = nil
    self.WidgetHelper = nil
    self.UILogicHelper = nil
end

function WndBase:CheckOpenState()
    if self.bClosing then
        self:HideFinished()
    end
end

function WndBase:Open(tbParams)
    log('[UI] WndBase : Open wnd, name:', self.tbTemplate.szWndName)
    self.EventHelper:FireEvent(ClientEventDef.EV_PRE_OPEN_UI, self.tbTemplate.szWndName)
    self.tbOpenArgs = tbParams and tbParams or {}
    if self.tbOpenArgs.bAsync or self.tbTemplate.bAsync then
        AsyncLoadResource(self)
    else
        LoadResource(self)
        AfterLoadResource(self)
    end
end

function WndBase:Close(tbParams)
    log('[UI] WndBase : Close wnd, name:', self.tbTemplate.szWndName)
    if (self.tbOpenArgs.bAsync or self.tbTemplate.bAsync) and not self.bEntered then
        CancelAsyncResource(self)
        return
    end
    self.tbCloseArgs = tbParams and tbParams or {}

    self.EventHelper:FireEvent(ClientEventDef.EV_PRE_CLOSE_UI, self.tbTemplate.szWndName)
    if self:Hide() ~= false then
        self:HideFinished()
    end
end

function WndBase:CloseSelf()
    self.UIManager:CloseWnd(self.tbTemplate.szWndName)
end

function WndBase:HideFinished()
    if self.tbTemplate.bCache then
        self:Exit()
    else
        self.UIManager:DestroyWnd(self.tbTemplate.szWndName)
    end
end

function WndBase:SetVisible(bVisible)
    local pVisibility = bVisible and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed
    self.pWidgetRef:SetVisibility(pVisibility)
end

function WndBase:IsVisible()
    if self.pWidgetRef then
        local bVisible = self.pWidgetRef:IsVisible()
        if self.pWidgetRef.bTakeWidgetCache then
            bVisible = bVisible and self.bShowed
        end
        return bVisible
    end
    return false
end

function WndBase:SetZOrder(nZOrder)
    RemoveFromViewport(self)
    AddToViewportWithZOrder(self, nZOrder)
end

function WndBase:AddToViewportWithZOrder(nZOrder)
    AddToViewportWithZOrder(self, nZOrder)
end

function WndBase:RemoveFromViewport()
    RemoveFromViewport(self)
end

-- Basic Function
function WndBase:Enter()
    self:OnEnter()
    self.UILogicHelper:OnEnter()
    self.PrefabHelper:Enter()
    self.bEntered = true
end

function WndBase:Show()
    self:OnShow()
    self.UILogicHelper:OnShow()
    self.PrefabHelper:Show()
    self.bShowed = true
end

function WndBase:Hide()
    self.bClosing = true
    self.bShowed = false
    local bDelayFinish = self:OnHide()
    self.UILogicHelper:OnHide()
    self.PrefabHelper:Hide()
    return bDelayFinish
end

function WndBase:Exit()
    log('[UI] WndBase : Exit wnd, name:', self.tbTemplate.szWndName)
    self.bEntered = false
    local bAddToView = self.tbOpenArgs.bAddToView
    if bAddToView == nil or bAddToView == true then
        RemoveFromViewport(self)
    end
    CancelAsyncResource(self)
    self:UnbindEvent()
    self.TimerHelper:ClearAllTimer()
    self:OnExit()
    self.UILogicHelper:OnExit()
    self.PrefabHelper:Exit()
    self.EventHelper:FireEvent(ClientEventDef.EV_POST_EXIT_UI, self.tbTemplate.szWndName)
    self.bClosing = false
    self.tbOpenArgs.bVisibility = nil
end

function WndBase:Pause()
    if not self.pWidgetRef then
        return
    end
    self:OnPause()
    self.UILogicHelper:OnPause()
    self.PrefabHelper:Pause()
end

function WndBase:Resume()
    if not self.pWidgetRef then
        return
    end
    self:OnResume()
    self.UILogicHelper:OnResume()
    self.PrefabHelper:Resume()
end

function WndBase:LoadText()
    local tbText = ClientShell.GetClient(GWorld):GetTextWidget(self.pWidgetRef)
    for _, v in ipairs(tbText) do
        UISetUtils.UpdateByTextSelfKey(v)
    end
end

function WndBase:BindEvent()
    self:OnBindEvent(self.EventHelper)
    self.UILogicHelper:BindEvent()
    self.PrefabHelper:BindEvent()
    self.bEventBinded = true
end

function WndBase:UnbindEvent()
    self.bEventBinded = false
    self:OnUnbindEvent(self.EventHelper)
    self.EventHelper:UnregisterAll()
    self.UILogicHelper:UnbindEvent()
    self.PrefabHelper:UnbindEvent()
    self.TimerHelper:ClearAllTimer()
end

function WndBase:PlayAnimation(szAnimName, StartTime, LoopNum, PlayMode, Speed, funcEnd, szInfo)
    self:PlayAnimationWithUserWidget(self.pWidgetRef, szAnimName, StartTime, LoopNum, PlayMode, Speed, funcEnd, szInfo)
end

function WndBase:PlayAnimationWithUserWidget(pWidgetRef, szAnimName, StartTime, LoopNum, PlayMode, Speed, funcEnd, szInfo)
    log("[UI]WndBase:PlayAnimation,szAnimName, UI =", szAnimName, self.tbTemplate.szWndName)
    --logdebug("[UI]call back="..debug.traceback())
    local pAnimRef = pWidgetRef[szAnimName]
    if not pAnimRef then
        logerror("[UI]PlayAnimation failed, pAnimRef is nil. UI name, szAnimName=", self.tbTemplate.szWndName, szAnimName)
        return
    end
    if Speed == nil then
        Speed = DEFAULT_SEED
    end
    pWidgetRef:PlayAnimation(pAnimRef, StartTime, LoopNum, PlayMode, Speed)
    if LoopNum == 0 or not (funcEnd or self:NeedRegisterAnimEndForcely(szAnimName)) then
        return
    end
    if(GEnableNewLua) then
        szInfo = szInfo or getdebuginfo_l()
    end
    self:RegisterAnimation(szAnimName, pWidgetRef, pAnimRef, funcEnd, szInfo)
end

function WndBase:StopAnimation(szAnimName)
    self:StopAnimationWithUserWidget(self.pWidgetRef, szAnimName)
end

function WndBase:StopAnimationWithUserWidget(pWidgetRef, szAnimName)
    local pAnimRef = pWidgetRef[szAnimName]
    if not pAnimRef then
        logerror("[UI]StopAnimation failed, pAnimRef is nil. UI name, szAnimName=", self.tbTemplate.szWndName, szAnimName)
        return
    end
    if pWidgetRef:IsAnimationPlaying(pAnimRef) then
        pWidgetRef:StopAnimation(pAnimRef)
        self:NotifyAnimationEnd(szAnimName, pAnimRef)
    end
end

function WndBase:IsAnimationPlaying(szAnimName)
    local pWidgetRef = self.pWidgetRef
    local pAnimRef = pWidgetRef[szAnimName]
    if not pAnimRef then
        logerror("[UI]IsAnimationPlaying failed, pAnimRef is nil. UI name, szAnimName=", self.tbTemplate.szWndName, szAnimName)
        return false
    end
    local bIsPlaying = pWidgetRef:IsAnimationPlaying(pAnimRef)
    return bIsPlaying
end

function WndBase:RegisterAnimation(szAnimName, pWidgetRef, pAnimRef, funcEnd, szInfo)
    local nUniqueId = ExtendBlueprintFunctions.GetObjectUniqueID(pAnimRef)
    --logdebug("WndBase:RegisterAnimation,nUniqueId="..tostring(nUniqueId).." self.tbTemplate.szWndName="..tostring(self.tbTemplate.szWndName))
    if(self.tbAnimDelegate[nUniqueId] == nil) then
        self.tbAnimDelegate[nUniqueId] = self.EventHelper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(pWidgetRef, pAnimRef, function()
            if funcEnd then
                funcEnd()
            end
            self:NotifyAnimationEnd(szAnimName, pAnimRef)
        end))
    end
end

function WndBase:NotifyAnimationEnd(szAnimName, pAnimRef)
    local nUniqueId = ExtendBlueprintFunctions.GetObjectUniqueID(pAnimRef)
    if(self.EventHelper ~= nil)then
        self.EventHelper:UnRegisterHandle(self.tbAnimDelegate[nUniqueId])
    end
    self.tbAnimDelegate[nUniqueId] = nil
    log("[UI]WndBase:NotifyAnimationEnd, szuiname="..tostring(self.tbTemplate.szWndName).." szAnimName="..tostring(szAnimName))
    EventManager:OnFireEvent(ClientEventDef.EV_UI_ANIMATION_END, self.tbTemplate.szWndName, szAnimName)
end

function WndBase:NeedRegisterAnimEndForcely(szAnimName)
    if not self.tbRegisterAnimEndForcely then
        return false
    end
    return true
end

function WndBase:CanOpen()
    return true
end

function WndBase:IsNeedBlurBG()
    return self.tbTemplate.bNeedBlurBG
end

function WndBase:IsNeedTopBar()
    return self.tbTemplate.bNeedTopBar
end

function WndBase:GetWndName()
    return self.tbTemplate.szWndName
end

-- LifeCycle
-- 作用：纯逻辑的初始化，逻辑绑定
-- 时期：Wnd进行初始化被调用
function WndBase:OnCreate()
end

-- 作用：对资源进行绑定
-- 时期：Wnd进行初始化或PersistentLevel加载时会被调用
function WndBase:OnLoad()
end

-- 作用：主UI显示前的逻辑处理
-- 时期：Show()方法调用后，主UI显示前
function WndBase:OnEnter()
end

-- 作用：主UI显示后的逻辑处理，如播放进入动画，网络数据请求等
-- 时期：OnEnter()执行完毕，主UI显示后
function WndBase:OnShow()
end

-- 作用：主UI隐藏前的逻辑处理，如播放退出动画等
-- 时期：Hide()方法调用后，主UI隐藏前
function WndBase:OnHide()
end

-- 作用：主UI隐藏后的逻辑处理
-- 时期：Hide()执行完毕，主UI隐藏后
function WndBase:OnExit()
end

-- 作用：逻辑解绑等
-- 时期：Wnd被手动销毁时调用
function WndBase:OnDestroy()
end

-- 作用：对资源进行解绑
-- 时期：手动销毁Wnd，或者PersistentLevel卸载时会被调用
function WndBase:OnUnload()
end

-- 作用：对事件进行绑定
-- 时期：Enter方法调用后
function WndBase:OnBindEvent(EventHelper)
end

-- 作用：对事件进行解绑
-- 时期：Exit方法调用后
function WndBase:OnUnbindEvent(EventHelper)
end

-- 作用：获取uilevel中的一些actor
-- 时期：uilevel加载完成后调用
function WndBase:OnLoadLevelFinished()
end

-- 作用：异步加载资源的回调
-- 时期：第一次load资源时
function WndBase:OnLoadAsyncFinished(szTempAssetName, pObject, nHandle)
end

-- 作用：新窗口压栈时，当前栈顶窗口暂停的回调
-- 时期：第一次load资源时
function WndBase:OnPause()
end

-- 作用：栈顶窗口出栈时,下一个窗口恢复的回调
-- 时期：第一次load资源时
function WndBase:OnResume()
end

return WndBase
