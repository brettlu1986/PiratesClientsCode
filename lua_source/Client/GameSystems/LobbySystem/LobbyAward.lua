-----------------------------------------------------
--File Name    : LobbyAward.lua
--Author       : chenyixin
--Description  : 大厅获得物品展示界面
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbySubBase = require("LobbySubBase")
local LobbyAward = luaclass("LobbyShip", LobbySubBase)

local ClientEventDef = require("ClientEventDef")
local LobbySubTypeDef = require("LobbySubTypeDef")
local ItemCategoryDef = require("ItemCategoryDef")
local UIShipDataTable = require("UIShipDataTable")
local AvatarDataTable = require("AvatarDataTable")
local DisplayAwardItemIni = require("DisplayAwardItemIni")
local LobbySubLevelDataTable = require("LobbySubLevelDataTable")

local LuaDelegate = require("LuaDelegate")
local EventManager = require("EventManager")
local UEActorHelper = require("UEActorHelper")
local SelfTimerHelper = require("SelfTimerHelper")
local GameAvatarHelper = require("GameAvatarHelper")
local DisplayItemHelper = require("DisplayItemHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local LobbyHumanFashion3DOperator = require("LobbyHumanFashion3DOperator")

local ItemSystem = require("ItemSystem")
local LobbyChatSystem = require("LobbyChatSystem")

local HumanAvatarDef = require("HumanAvatarDef")
local HumanArmorDef = require("HumanArmorDef")
local HumanAvatarHelper = require("HumanAvatarHelper")
local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
local UIManager = require("UIManager")
local UILobbyCaptainHelper = require("UILobbyCaptainHelper")

LobbyAward.TimerHelper = nil

LobbyAward.tbAllTemplates = {}
LobbyAward.tbAwardDatas = {}
-- LobbyAward.tbDisplayFashionIds = nil
LobbyAward.OnWndCloseDelegate = nil
LobbyAward.AnimTimer = nil
LobbyAward.SailTimer = nil
LobbyAward.DelayTimer = nil

LobbyAward.LobbyHumanFashion3DOperator = nil
LobbyAward.pShipActor = nil
LobbyAward.pWateringEffect = nil

LobbyAward.szCurOpenWnd = nil
LobbyAward.nSourceType = nil
LobbyAward.szSourceWndName = nil

local tbCategoryToWndName = {
    [ItemCategoryDef.FASHION] = UIDef.UI_LOBBY_AWARD_DISPLAY_FASHION,
    [ItemCategoryDef.SHIP] = UIDef.UI_LOBBY_AWARD_DISPLAY_SHIP,
    [ItemCategoryDef.SHIP_SKIN] = UIDef.UI_LOBBY_AWARD_DISPLAY_SHIP,
}

local tbDisplayConfig = {
    [ItemCategoryDef.SHIP] = DisplayAwardItemIni.tbShipDisplay,
    [ItemCategoryDef.SHIP_SKIN] = DisplayAwardItemIni.tbShipDisplay,
    [ItemCategoryDef.FASHION] = DisplayAwardItemIni.tbHumanDisplay,
}

local ZERO_VECTOR = Vector()
local ZERO_ROTATOR = Rotator()
local SCALE_VECTOR = Vector({X = 1, Y = 1, Z = 1})
-- local NORMAL_SIZE_X = 1050      -- 雪虎号X轴大小，水花特效缩放值以雪虎号为基准
local FULL_SAIL_TIME = 1        -- 开始展开船帆的时间
local WATERING_EFFECT = DisplayAwardItemIni.tbShipDisplay.szWateringEffect
-- local GET_SHIP_REWARD_SHAKE = "Blueprint'/Game/Game/Camera/NewGameCamera/BP_LobbyGetShipShake.BP_LobbyGetShipShake_C'"

local function BindOnWndCloseDelegate(self, fnOnClose)
    if self.OnWndCloseDelegate then
        self.OnWndCloseDelegate:UnbindAll()
        self.OnWndCloseDelegate = nil
    end
    if not self.OnWndCloseDelegate and fnOnClose then
        self.OnWndCloseDelegate = LuaDelegate()
        self.OnWndCloseDelegate:Bind(fnOnClose)
    end
end

local function ClearAnimTimer(self)
    if self.AnimTimer then
        self.TimerHelper:ClearTimer(self.AnimTimer)
        self.AnimTimer = nil
    end
end

local function ClearSailTimer(self)
    if self.SailTimer then
        self.TimerHelper:ClearTimer(self.SailTimer)
        self.SailTimer = nil
    end
end

local function ClearDelayTimer(self)
    if self.DelayTimer then
        self.TimerHelper:ClearTimer(self.DelayTimer)
        self.DelayTimer = nil
    end
end

local function SetPlayerMyself(pPlayer)
    if not pPlayer then
        return
    end
    local tbOceanSystems = GameplayStatics.GetAllActorsOfClass(GWorld, OceanSystem)
    local pOceanSystem = tbOceanSystems[1]
    if pOceanSystem then
        pOceanSystem:SetPlayerMyself(pPlayer)
    end
end

local function UpdateShipSkin(tbResData, nShipTemplateId, tbTResData, pShipActor, szShipAvatarComponent)
    local pShipAvatarComponent = EngineExtActorShell.CreateActorComponent(pShipActor, szShipAvatarComponent:load())
    pShipAvatarComponent:Init(nil, pShipActor, 0)
    GameAvatarHelper:UpdateShipAvatar(pShipAvatarComponent, tbResData, nShipTemplateId, tbTResData)
	EngineExtActorShell.SetActorSkeletalMeshMipMap(pShipActor, true)
end

local function GetWateringEffectActor(self)
    if not isvalidhandle(self.pWateringEffect) then
        local pWateringEffect = EngineExtActorShell.SpawnActorForScript(GWorld, WATERING_EFFECT:load(), Transform(), nil)
        if pWateringEffect then
            pWateringEffect:Init()
        else
            logerror("[LobbyAward] load BP_WateringEffect failed.")
        end
        self.pWateringEffect = pWateringEffect
    end
    return self.pWateringEffect
end

local function PlayWateringPostProcessEffect(self)
    local pWateringEffect = GetWateringEffectActor(self)
    if isvalidhandle(pWateringEffect) then
        pWateringEffect:Start()
    end
    -- self:PlayCameraShake(GET_SHIP_REWARD_SHAKE)
end

local function StopWateringPostProcessEffect(self)
    local pWateringEffect = GetWateringEffectActor(self)
    if isvalidhandle(pWateringEffect) then
        pWateringEffect:End()
    end
end

local function ClearWateringEffectObj(self)
    if isvalidhandle(self.pWateringEffect) then
        StopWateringPostProcessEffect(self)
        self.pWateringEffect:SetActorTickEnabled(false)
        UEActorHelper:DestroyActor(self.pWateringEffect)
    end
end

-- 播放完出水动画后，生成船周围海面特效
local function OnShipAnimSpawned(self, pShipActor)
    ClearAnimTimer(self)
    if not isvalidhandle(pShipActor) then
        log("Ship actor is nil.")
        return
    end

    -- 根据船吃水线和浮力大小，计算特效位置和大小
    local pFloatLoc = pShipActor.Flotage.RelativeLocation
    local pSprayLoc = pShipActor.WaterLine.RelativeLocation
    -- local pBoxSize = pShipActor.Flotage:GetUnscaledBoxExtent()
    -- local nScale = pBoxSize.X / NORMAL_SIZE_X
    local nScale = 1
    pSprayLoc.X = 0
    pSprayLoc.Y = 0
    pSprayLoc.Z = pFloatLoc.Z + pSprayLoc.Z
    ExtendBlueprintFunctions.SpawnEmitterAttachedEx(DisplayAwardItemIni.tbShipDisplay.szSeaFoamRes:load(), pShipActor.RootComponent, "" , pSprayLoc, ZERO_ROTATOR, ZERO_VECTOR,
    EAttachLocation.KeepRelativeOffset, true, nScale, EPSCPoolMethod.None, false)
end

local function SpawnShipFoamEffect(self, tbShipFoamsTags, tbShipFoamsRes, pShipActor, pSubLevel)
    if not pSubLevel then
        logerror("ULLobbyDisplayAwardItem:SpawnShipFoamEffect, cannot find SubLevel")
    end

    local szWndName = UIDef.UI_LOBBY_AWARD_DISPLAY_SHIP
    local tbFoams = {}
    for i, v in ipairs(tbShipFoamsRes) do
        local szShipFoamTag = tbShipFoamsTags[i]
        if not isvalidhandle(pShipActor) then
            logerror("Ship actor is nil.")
            return
        end

        local pLocation, pRotation = self.SubLevelLoadHelper:GetLocationAndRotationByTag(self.nSubType, szWndName, szShipFoamTag)

        local pFoam = ExtendBlueprintFunctions.SpawnEmitterAtLocationEx(GWorld, v:load(), pLocation, pRotation, SCALE_VECTOR, true, 1, EPSCPoolMethod.None, false)
        table.insert(tbFoams, pFoam)
    end
    return tbFoams
end

local function LoadShipEnd(self, tbResData, nShipTemplateId, tbTResData, fnPlayAnimEnd)
    local tbShipConfig = tbDisplayConfig[ItemCategoryDef.SHIP]
    local pSubLevel = self:GetLevelStream(self.szCurOpenWnd)

    local pShipActor = self.pShipActor
    self:SetActorSkeletalMeshLightChannel(UIDef.UI_LOBBY_AWARD_DISPLAY_SHIP, pShipActor)
    SetPlayerMyself(pShipActor)

    -- 打开浮力
    if pShipActor.Flotage then
        pShipActor.Flotage.bAlwaysUpdate = true
        pShipActor.Flotage.ApplyTransform = true
    end
    
    -- 更新船时装
    UpdateShipSkin(tbResData, nShipTemplateId, tbTResData, pShipActor, tbShipConfig.szShipAvatarComponent)

    -- 播放船出水动画/特效
    local pShipAnim = tbShipConfig.szShipAnim:load()
    local nTime = pShipActor.SKM_ShipMaster:GetAnimInstance():Montage_Play(pShipAnim, 1.0, EMontagePlayReturnType.MontageLength, 0.0, false)
    ExtendBlueprintFunctions.UpdateSkeletalComponentAnim(pShipActor.SKM_ShipMaster)
    self.tbFoams = SpawnShipFoamEffect(self, tbShipConfig.tbShipFoamsTags, tbShipConfig.tbShipFoamsRes, pShipActor, pSubLevel)
    PlayWateringPostProcessEffect(self)
    ClearAnimTimer(self)
    self.AnimTimer = self.TimerHelper:NewTimerMethod(self, function()
        OnShipAnimSpawned(self, pShipActor)
        if fnPlayAnimEnd then
            fnPlayAnimEnd()
        end
    end, nTime - 3, false)
    ExtendBlueprintFunctions.UpdateSkeletalComponentAnim(pShipActor.SKM_ShipMaster)

    -- 在动画播完之前打开船帆
    ClearSailTimer(self)
    self.SailTimer = self.TimerHelper:NewTimer(function()
        ClearSailTimer(self)
        if isvalidhandle(pShipActor) then
            pShipActor:SetPosture(EShipPosture.FullSail)
        end
    end, FULL_SAIL_TIME, false)
end

local function OpenAwardWnd(self, tbTemplate, szLastWndName)
    if not tbTemplate then
        self:OnWndClose()
        return
    end
    local szWndName = tbCategoryToWndName[tbTemplate.nCategory]

    if szLastWndName then
        if szWndName ~= szLastWndName then
            self:SetShouldBeVisible(szLastWndName, false)
        end
        UIManager:CloseWnd(szLastWndName)
    end

    self.szCurOpenWnd = szWndName
    self:SetShouldBeVisible(szWndName, true)
    self:PlayBGMusic(szWndName)
    local AwardWnd = UIManager:GetWnd(szWndName)
    local tbOpenArgs =  {tbItemTemplate = tbTemplate, OwnerSub = self, nSourceType = self.nSourceType}
    if not AwardWnd then
        AwardWnd = UIManager:OpenWnd(szWndName, tbOpenArgs)
    end

    AwardWnd:UpdateUIDisplay(tbOpenArgs)
end

local function ShowDisplayAwardWnd(self, tbParam)
    self.nSourceType = tbParam and tbParam.nSourceType
    local tbItemTemplates = tbParam and tbParam.tbItemTemplates

    if not self.tbAllTemplates then
        self.tbAllTemplates = tbItemTemplates
    elseif tbItemTemplates then
        for _, v in pairs(tbItemTemplates) do
            -- if v.nCategory == ItemCategoryDef.FASHION then
            --     self.tbDisplayFashionIds = v
            -- else
                table.insert(self.tbAllTemplates, v) 
            -- end
        end
    end
    if tbParam and tbParam.fnOnDisplayWndClosed then
        BindOnWndCloseDelegate(self, tbParam.fnOnDisplayWndClosed)
    end

    local tbTemplate = self:GetNextItem()
    -- if not tbTemplate then
    --     tbTemplate = self.tbDisplayFashionIds
    --     self.tbDisplayFashionIds = nil
    -- end

    OpenAwardWnd(self, tbTemplate)
end

local function ShowCommonAwardWnd(self, tbAwardDatas)
    if not tbAwardDatas or (not tbAwardDatas[1]) or (not tbAwardDatas[1].tbAwardDatas) or #tbAwardDatas[1].tbAwardDatas <=0 then
        return
    end
    LobbyChatSystem:OnAwardNotification(tbAwardDatas)
    local szWndName = UIDef.UI_LOBBY_AWARD_ITEM
    if UIManager:IsWndOpen(szWndName) then
        EventManager:OnFireEvent(ClientEventDef.EV_UI_PUSH_AWARD, tbAwardDatas)
    else
        local tbItemDatas = tbAwardDatas[1]
        table.remove(tbAwardDatas, 1)
        local tbItemQueue = nil
        if #tbAwardDatas > 0 then
            tbItemQueue = {}
            for i, v in ipairs(tbAwardDatas) do
                table.insert(tbItemQueue, v.tbAwardDatas)
            end
        end
        UIManager:OpenWnd(UIDef.UI_LOBBY_AWARD_ITEM,{tbItemDatas = tbItemDatas.tbAwardDatas, tbItemQueue = tbItemQueue, OwnerSub = self})
    end
end

local function ShowAward(self, nSourceType, tbDisplayItemTemplates)
    if tbDisplayItemTemplates ~= nil and #tbDisplayItemTemplates > 0 then
        local tbParam = {
            tbItemTemplates = tbDisplayItemTemplates, 
            nSourceType = nSourceType,
        }
        ShowDisplayAwardWnd(self, tbParam)
    else
        ShowCommonAwardWnd(self, self.tbAwardDatas)
    end
end

local function OnPushLobbyAward(self, tbAwardDatas)
    local tbCurrentDatas = tbAwardDatas[1].tbAwardDatas
    local tbCommonItemTemplates, tbDisplayItemTemplates = DisplayItemHelper.InitItemTemplates(tbCurrentDatas)
    tbAwardDatas[1].tbAwardDatas = tbCommonItemTemplates

    if tbCommonItemTemplates and #tbCommonItemTemplates > 0 then
        if UIManager:IsWndOpen(UIDef.UI_LOBBY_AWARD_ITEM) then
            EventManager:OnFireEvent(ClientEventDef.EV_UI_PUSH_AWARD, tbAwardDatas)
        else
            table.move(tbAwardDatas, 1, #tbAwardDatas, #self.tbAwardDatas + 1, self.tbAwardDatas)
        end
    end
    table.move(tbDisplayItemTemplates, 1, #tbDisplayItemTemplates, #self.tbAllTemplates + 1, self.tbAllTemplates)
end

function LobbyAward:Init(Owner, nSubType)
    LobbyAward.super.Init(self, Owner, nSubType)
    return true
end

function LobbyAward:Activate(tbParam)
    LobbyAward.super.Activate(self, tbParam)

    UIUtils.BottomMenuUnselectAll()
    UIUtils.BottomMenuHide(true)

    if not self.TimerHelper then
        self.TimerHelper = SelfTimerHelper()
    end

    local pWateringEffect = GetWateringEffectActor(self)
    pWateringEffect:SetActorTickEnabled(true)

    self.szSourceWndName = tbParam and tbParam.szSourceWndName
    local tbAwardDatas = tbParam and tbParam.tbAwardDatas
    -- if not tbAwardDatas or #tbAwardDatas <= 0 then
    --     self.Owner:ReturnToPrevSub()
    --     return
    -- end

    local tbCurrentDatas = tbAwardDatas[1].tbAwardDatas
    local nSourceType = tbAwardDatas.nSourceType
    local tbCommonItemTemplates, tbDisplayItemTemplates = DisplayItemHelper.InitItemTemplates(tbCurrentDatas)
    if tbCommonItemTemplates and next(tbCommonItemTemplates) then
        tbAwardDatas[1].tbAwardDatas = tbCommonItemTemplates
        self.tbAwardDatas = tbAwardDatas
    end

    ShowAward(self, nSourceType, tbDisplayItemTemplates)

    self.EventHelper:RegisterEvent(ClientEventDef.EV_PUSH_LOBBY_AWARD, self, OnPushLobbyAward)
end

function LobbyAward:Deactivate()
    LobbyAward.super.Deactivate(self)
    
    if isvalidhandle(self.pShipActor) then
        UEActorHelper:DestroyActor(self.pShipActor)
        self.pShipActor = nil
    end

    ClearWateringEffectObj(self)

    -- if isvalidhandle(self.pHumanActor) then
    --     UEActorHelper:DestroyActor(self.pHumanActor)
    --     self.pShipActor = nil
    -- end

    if self.LobbyHumanFashion3DOperator then
        self.LobbyHumanFashion3DOperator:Uninit()
    end

    ClearSailTimer(self)
    ClearAnimTimer(self)
    ClearDelayTimer(self)

    self.szSourceWndName = nil
    -- self.tbAllTemplates = {}
    -- self.tbDisplayFashionIds = nil

    if self.szCurOpenWnd then
        UIManager:CloseWnd(self.szCurOpenWnd)
        self:SetShouldBeVisible(self.szCurOpenWnd, false)
        self.szCurOpenWnd = nil
    end

    if self.tbFoams then
        for _, v in pairs(self.tbFoams) do
            if isvalidhandle(v) then
                ExtendBlueprintFunctions.DestroyEmitter(v)
            end
        end
        self.tbFoams = nil
    end

    UIUtils.BottomMenuHide(false)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_PUSH_LOBBY_AWARD)
    self.tbAwardDatas = {}
end

function LobbyAward:Uninit()
    if isvalidhandle(self.pShipActor) then
        UEActorHelper:DestroyActor(self.pShipActor)
        self.pShipActor = nil
    end

    ClearWateringEffectObj(self)

    if self.LobbyHumanFashion3DOperator then
        self.LobbyHumanFashion3DOperator:Uninit()
    end

    ClearSailTimer(self)
    ClearAnimTimer(self)
    ClearDelayTimer(self)

    if self.tbFoams then
        for _, v in pairs(self.tbFoams) do
            if isvalidhandle(v) then
                ExtendBlueprintFunctions.DestroyEmitter(v)
            end
        end
        self.tbFoams = nil
    end

    self.tbAwardDatas = {}

    LobbyAward.super.Uninit(self)
end

function LobbyAward:GetNextItem()
    local tbItem = nil
    if self.tbAllTemplates and #self.tbAllTemplates > 0 then
        tbItem = table.remove(self.tbAllTemplates)
    end
    return tbItem
end

function LobbyAward:CreateShipActor(tbItemTemplate, fnPlayAnimEnd)
    if not tbItemTemplate then
        logerror("[LobbyAward] tbItemTemplate is nil")
        return
    end

    local pShipActor = self.pShipActor
    if isvalidhandle(pShipActor) then
        UEActorHelper:DestroyActor(pShipActor)
        pShipActor = nil
    end

    -- 获取船template
    local tbShipResTemplate = DisplayItemHelper.GetShipResTemplate(tbItemTemplate.nId)
    local szModelClassName = nil
    if tbShipResTemplate == nil then
        error("tbShipResTemplate is nil, nItemId is " .. tostring(tbItemTemplate.nId))
        return
    else
        szModelClassName = tbShipResTemplate.szModelClassName
    end

    -- 生成Actor
    local pModelClass = szModelClassName:load()
    pShipActor = EngineExtActorShell.SpawnActorForScript(GWorld, pModelClass, Transform(), nil)
    if not pShipActor then
        error("pShipActor is nil")
        return
    end

    -- 调整船位置
    local szWndName = UIDef.UI_LOBBY_AWARD_DISPLAY_SHIP
    local tbSubLevelTemplate = LobbySubLevelDataTable:GetTemplate(self.nSubType, szWndName)
    if not tbSubLevelTemplate then
        logerror("[LobbyShip] SettleShipTransform cannot find tbsubleveltemplate", self.nSubType, szWndName)
        return 
    end
    local pLocation, pRotation = self.SubLevelLoadHelper:GetLocationAndRotationByTag(self.nSubType, szWndName, DisplayAwardItemIni.tbShipDisplay.szActorTag)
    local UIShipTemp = UIShipDataTable:GetTemplate(tbShipResTemplate.nResId, "displayaward")
    pRotation.Yaw = pRotation.Yaw + UIShipTemp.nYaw
    local nShipScale = tbShipResTemplate.nModelScale
    pShipActor:K2_SetActorLocation(pLocation)
    pShipActor:K2_SetActorRotation(pRotation)
    pShipActor:SetActorScale3D(Vector{X = nShipScale, Y = nShipScale, Z = nShipScale})
    pShipActor:SetPosture(EShipPosture.Reef)
    pShipActor:SetActiveBlend(true)

    self.pShipActor = pShipActor

    LoadShipEnd(self, nil, -1, tbShipResTemplate, fnPlayAnimEnd)

    return pShipActor
end

function LobbyAward:CreateHumanActor(tbFashionTemplates)
    -- 根据当前玩家信息创建Actor
    local szWndName = UIDef.UI_LOBBY_AWARD_DISPLAY_FASHION
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local nAvatarId = tbPlayerSelf.LobbyPropertyComponent:GetAvatarId()
    local nHumanTemplateId = tbPlayerSelf.LobbyPropertyComponent:GetHumanTemplateId()
    local Human3DOperator = self.LobbyHumanFashion3DOperator
    if not Human3DOperator then
        Human3DOperator = LobbyHumanFashion3DOperator()
        self.LobbyHumanFashion3DOperator = Human3DOperator
        Human3DOperator:Init()
    end
    local pLocation, pRotation = self.SubLevelLoadHelper:GetLocationAndRotationByTag(self.nSubType, szWndName, tbDisplayConfig[ItemCategoryDef.FASHION].szActorTag)

    Human3DOperator:SetActorLocation(pLocation)
    Human3DOperator:SetActorRotator(pRotation)
    local tbAvatar = AvatarDataTable:GetTemplate(nHumanTemplateId)
    if tbAvatar.szShowAnimation then
        Human3DOperator:SetAnimation(tbAvatar.szShowAnimation)
    end
    local tbAppearanceId = tbPlayerSelf.AppearanceComponent:GetAppearanceIds()
    local nTemplateId = tbFashionTemplates.tbFashionIds[1]
    local szAnim = UILobbyCaptainHelper.GetHumanAnimationByFashionTemplateId(nTemplateId)
    local tbTemplate = ItemSystem:GetItemTemplate(nTemplateId)
    self.LobbyHumanFashion3DOperator:SetAnimation(szAnim)
    if  tbTemplate.nFashionType == HumanAvatarDef.FashionType.Basic then
        self.LobbyHumanFashion3DOperator:SetArmorTypeAndLevel(nil, nil)
    else
        local nAmorType = HumanAvatarHelper.FashionTypeToArmorType[tbTemplate.nFashionType]
        self.LobbyHumanFashion3DOperator:SetArmorTypeAndLevel(nAmorType, HumanArmorDef.MAX_LEVEL)
    end
    local pHumanActor = self.LobbyHumanFashion3DOperator:Display(nAvatarId, tbFashionTemplates.tbFashionIds, tbAppearanceId)
    SetPlayerMyself(pHumanActor)
    return pHumanActor
end

function LobbyAward:OnWndClose(szWndName)
    ClearAnimTimer(self)
    ClearSailTimer(self)
    ClearDelayTimer(self)

    if self.Owner:GetActiveSub().nSubType ~= self.nSubType then
        return
    end

    -- 仅绑定1个Delegate，当全部道具展示完后调
    if self.tbAllTemplates and #self.tbAllTemplates > 0 then
        local tbNextItemTemplate = self:GetNextItem()
        if tbNextItemTemplate then
            OpenAwardWnd(self, tbNextItemTemplate, szWndName)
            return
        end
    end

    if self.tbAwardDatas and #self.tbAwardDatas > 0 then
        if szWndName then
            self:SetShouldBeVisible(szWndName, false)
            UIManager:CloseWnd(szWndName)
        end
        ShowCommonAwardWnd(self, self.tbAwardDatas)
        return
    end

    if self.OnWndCloseDelegate then
        self.OnWndCloseDelegate:Fire()
        self.OnWndCloseDelegate:UnbindAll()
        self.OnWndCloseDelegate = nil
    end

    self.Owner:ReturnToPrevSub()
end

function LobbyAward:Wear(tbItemTemplate)
    local nCategory = tbItemTemplate.nCategory
    -- local bNeedReturn = self.tbDisplayFashionIds or (self.tbAllTemplates and #self.tbAllTemplates > 0)

    local tbParams = {}
    tbParams.szSourceWndName = self.szSourceWndName
    if nCategory == ItemCategoryDef.FASHION then
        tbParams = {nItemTemplateId = tbItemTemplate.tbFashionIds[1]}
        self.Owner:Activate(LobbySubTypeDef.CAPTAIN, tbParams)
    elseif nCategory == ItemCategoryDef.SHIP then
        tbParams.szKey = "Hull"
        self.Owner:Activate(LobbySubTypeDef.SHIP, tbParams)
    elseif nCategory == ItemCategoryDef.SHIP_SKIN then
        tbParams.szKey = "Handbook"
        tbParams.tbParams = {
            nShipSkinTemplateId = tbItemTemplate.nId, 
            nShipTemplateId = tbItemTemplate.nShipItemId,
        }
        self.Owner:Activate(LobbySubTypeDef.SHIP, tbParams)
    end
end

function LobbyAward:Rotate(nDeltaYaw, pActor)
    if isvalidhandle(pActor) then
        local pRotation = pActor:K2_GetActorRotation()
        local pNewRotation = Rotator {
            Yaw = pRotation.Yaw - nDeltaYaw
        }
        pActor:K2_SetActorRotation(pNewRotation)
    end
end

function LobbyAward:NeedShowDisplayWnd()
    if self.tbAllTemplates and #self.tbAllTemplates > 0 then
        return true
    end

    -- if self.tbDisplayFashionIds then
    --     return true
    -- end

    return false
end

function LobbyAward:PlayWateringPostProcessEffect()
    PlayWateringPostProcessEffect(self)
end

function LobbyAward:StopWateringPostProcessEffect()
    StopWateringPostProcessEffect(self)
end

function LobbyAward:GetWateringEffectActor()
    return GetWateringEffectActor(self)
end

return LobbyAward