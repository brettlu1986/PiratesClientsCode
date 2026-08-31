local luaclass       = require("luaclass")
local WndBase        = require("WndBase")

local UILobbyCaptainVisual = luaclass("UILobbyCaptainVisual", WndBase)


local UITextDef = require("UITextDef")
local SelfTabBarHelper = require("SelfTabBarHelper")
local ClientEventDef = require("ClientEventDef")
local LobbyCaptainMiscDef = require("LobbyCaptainMiscDef")
local ItemSystem = require("ItemSystem")
local ItemCategoryDef = require("ItemCategoryDef")

local FeatureType = LobbyCaptainMiscDef.FeatureType

UILobbyCaptainVisual.nCurrentActivateTabIndex = nil
UILobbyCaptainVisual.tbTabBarHelper = nil

local LogicTypeDef = 
{
    WeaponFashion = 1,
    HumanFashion  = 2,
    PlaceHolder1  = 3,      -- 预留占位
    PlaceHolder2  = 4,      -- 预留占位
}

local tbLogicConfig = {}

local function DoRegisterSubLogic(nType, szLogicScript, l10nTabKey)
    if tbLogicConfig[nType] then
        return
    end
    local tbInfo = {}
    tbInfo.szScript = szLogicScript
    tbInfo.l10nTabKey = l10nTabKey
    tbLogicConfig[nType] = tbInfo
end

local function RegisterSubLogic()
    DoRegisterSubLogic(LogicTypeDef.WeaponFashion,  "ULLobbyCaptainWeaponFashionTabView", UITextDef.UI_STATIC_LOBBY_CAPTAIN_WEAPON_FASHION)
    DoRegisterSubLogic(LogicTypeDef.HumanFashion,  "ULLobbyCaptainHumanFashionTabView", UITextDef.UI_STATIC_LOBBY_CAPTAIN_HUMAN_FASHION)
end

local function InitSubLogic(self)
    local tbULContentLogic = self.tbULContentLogic
    if not tbULContentLogic then
        tbULContentLogic = {}
        self.tbULContentLogic = tbULContentLogic
    end
    for nType, tbInfo in pairs(tbLogicConfig) do
        local tbUL = self.UILogicHelper:CreateUILogic(tbInfo.szScript)
        tbUL:Init(self.tbOpenArgs.tbOwnerSystem)
        tbULContentLogic[nType] = tbUL
    end
end

local function UnitSubLogic(self)
    local tbULContentLogic = self.tbULContentLogic
    if tbULContentLogic then
        for nType, tbUL in pairs(tbULContentLogic) do
            tbUL:Uninit()
        end
        self.tbULContentLogic = nil
    end
end

local function DoOnTabBarSelectedChanged(self, nIndex, tbParams)
    local tbULContentLogic = self.tbULContentLogic
    if not tbULContentLogic then
        return
    end
    local nCurrentActivateTabIndex = self.nCurrentActivateTabIndex
    if nCurrentActivateTabIndex then
        local tbULCurrentContentLogic = tbULContentLogic[nCurrentActivateTabIndex]
        assert(tbULCurrentContentLogic)
        tbULCurrentContentLogic:Deactivate()
        self.nCurrentActivateTabIndex = nil
    end

    local tbULTargetContentLogic = tbULContentLogic[nIndex]
    assert(tbULTargetContentLogic)
    tbULTargetContentLogic:Activate(tbParams)
    self.nCurrentActivateTabIndex = nIndex
end

local function OnTabBarSelectedChanged(self, nIndex)
    DoOnTabBarSelectedChanged(self, nIndex, nil)
end

local function InitTabBar(self)
    self.tbTabBarHelper = SelfTabBarHelper()
    self.tbTabBarHelper:Init(self, self.pWidgetRef.vboxContainer)
    self.tbTabBarHelper.OnSelectedChangedDelegate:Bind(OnTabBarSelectedChanged, self)
    for _, nType in pairs(LogicTypeDef) do
        local tbInfo = tbLogicConfig[nType]
        if not tbInfo then
            self.tbTabBarHelper:SetVisibilityByIndex(nType, ESlateVisibility_Collapsed)
        else
            self.tbTabBarHelper:SetVisibilityByIndex(nType, ESlateVisibility_SelfHitTestInvisible)
            self.tbTabBarHelper:SetTabText(nType, tbInfo.l10nTabKey)
        end
    end
end

local function UninitTabBar(self)
    if self.tbTabBarHelper then
        self.tbTabBarHelper:Uninit()
        self.tbTabBarHelper = nil
    end
end

local function OnBack(self)
    self.EventHelper:FireEvent(ClientEventDef.EV_LOBBY_CAPTAIN_CALL_TO_DEACIVATE_FEATURE, FeatureType.Visual)
end

local function InitUIFrame(self)
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetBackDelegate(OnBack, self)
end


-- LifeCycle
-- 作用：纯逻辑的初始化，逻辑绑定
-- 时期：Wnd进行初始化被调用
-- function UILobbyCaptainVisual:OnCreate()
-- end

-- 作用：对资源进行绑定
-- 时期：Wnd进行初始化或PersistentLevel加载时会被调用
function UILobbyCaptainVisual:OnLoad()
    InitUIFrame(self)
    InitSubLogic(self)
    InitTabBar(self)
    self.UILogicHelper:CreateUILogic("ULLobbyCaptainVisualRedDot")
end

-- 作用：主UI显示前的逻辑处理
-- 时期：Show()方法调用后，主UI显示前
-- function UILobbyCaptainVisual:OnEnter()
-- end

-- 作用：主UI显示后的逻辑处理，如播放进入动画，网络数据请求等
-- 时期：OnEnter()执行完毕，主UI显示后
function UILobbyCaptainVisual:OnShow()
    self:PlayAnimation("anim_LobbyCaptainIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
    local tbParams = self.tbOpenArgs
    local nItemTemplateId = tbParams.nItemTemplateId
    local nIndex 
    if nItemTemplateId then
        local tbItemTemplate = ItemSystem:GetItemTemplate(nItemTemplateId)
        if tbItemTemplate.nCategory == ItemCategoryDef.SUIT or tbItemTemplate.nCategory == ItemCategoryDef.FASHION then
            nIndex = LogicTypeDef.HumanFashion
        else
            nIndex = LogicTypeDef.WeaponFashion
        end
        self.tbTabBarHelper:SelectByIndex(nIndex, false)
        DoOnTabBarSelectedChanged(self, nIndex, tbParams)
    else
        nIndex = LogicTypeDef.WeaponFashion
        self.tbTabBarHelper:SelectByIndex(nIndex, true)
    end
end

-- 作用：主UI隐藏前的逻辑处理，如播放退出动画等
-- 时期：Hide()方法调用后，主UI隐藏前
-- function UILobbyCaptainVisual:OnHide()
-- end

-- 作用：主UI隐藏后的逻辑处理
-- 时期：Hide()执行完毕，主UI隐藏后
-- function UILobbyCaptainVisual:OnExit()
-- end

-- 作用：逻辑解绑等
-- 时期：Wnd被手动销毁时调用
-- function UILobbyCaptainVisual:OnDestroy()
-- end

-- 作用：对资源进行解绑
-- 时期：手动销毁Wnd，或者PersistentLevel卸载时会被调用
function UILobbyCaptainVisual:OnUnload()
    UninitTabBar(self)
    UnitSubLogic(self)
end

-- 作用：对事件进行绑定
-- 时期：Enter方法调用后
-- function UILobbyCaptainVisual:OnBindEvent(EventHelper)
-- end

-- 作用：对事件进行解绑
-- 时期：Exit方法调用后
-- function UILobbyCaptainVisual:OnUnbindEvent(EventHelper)
-- end

-- 作用：获取uilevel中的一些actor
-- 时期：uilevel加载完成后调用
-- function UILobbyCaptainVisual:OnLoadLevelFinished()
-- end

-- 作用：异步加载资源的回调
-- 时期：第一次load资源时
-- function UILobbyCaptainVisual:OnLoadAsyncFinished(szTempAssetName, pObject, nHandle)
-- end
RegisterSubLogic()

return UILobbyCaptainVisual