local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbyDecoration = luaclass("ULLobbyDecoration", UILogicBase)

local L10N = require("L10N")
local UIDef = require("UIDef")
local Timer = require("Timer")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")

local UISetUtils = require("UISetUtils")
local ShopSystem = require("ShopSystem")
local ItemSystem = require("ItemSystem")
local LobbySystem = require("LobbySystem")
local ItemDataTable = require("ItemDataTable")
local UIResourceDef = require("UIResourceDef")
local ShopDataTable = require("ShopDataTable")
local ClientEventDef = require("ClientEventDef")
local CurrencySystem = require("CurrencySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")
local ItemSourceDataTable = require("ItemSourceDataTable")
local LobbyCaptainMiscDef = require("LobbyCaptainMiscDef")
local PropertyComboSystem = require("PropertyComboSystem")
local BattleBuffDataTable = require("BattleBuffDataTable")
local CostCurrencyHelper = require("CostCurrencyHelper")
local UILobbyCaptainHelper = require("UILobbyCaptainHelper")
local LobbySubLevelDataTable = require("LobbySubLevelDataTable")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local LobbyDecorationResDataTable = require("LobbyDecorationResDataTable")
local BattleHumanDecorationDescParser = require("BattleHumanDecorationDescParser")

ULLobbyDecoration.nUiType = nil

--decoration show
ULLobbyDecoration.nShowDecorationId = nil

--用于decoration main
ULLobbyDecoration.pDecorationInfo = nil
ULLobbyDecoration.ListHelper = nil
ULLobbyDecoration.ListPropertiesHelper = nil
ULLobbyDecoration.tbDecorations = nil
ULLobbyDecoration.pDecorationActor = nil
ULLobbyDecoration.pCurrencyBar = nil
ULLobbyDecoration.nSelectIdx = -1
ULLobbyDecoration.bSelectReachMaxLevel = false
ULLobbyDecoration.bShowList = true
ULLobbyDecoration.nCurrentLevelUpId = -1
ULLobbyDecoration.tbDragIndex = nil
ULLobbyDecoration.tbDragLastPos = nil
ULLobbyDecoration.pbWindowFrame = nil
ULLobbyDecoration.pLevelUpEffActor = nil
ULLobbyDecoration.bSet3dRot = true
ULLobbyDecoration.bPlayUpgradeEff = true

local tbTempRotation = Rotator()
local DRAG_SPEED = 0.5
local CAMERA_INDEX_1 = 1
local CAMERA_INDEX_2 = 2
local CAMERA_BLEND_TIME = 0.5
local CAMERA_BLEND_EXPONENT = 5
local PROPERTY_MAX_COUNT = 4    -- 最大属性条数，见 property_combo_decoration.tab
local DEFAULT_SELECT = 1
local NOT_IN_BAG_ID = -1
local IMAGE_SIZE = 70
local TIME_SEC = 0.4
local HIDE_SEC = 2.6

local FeatureType = LobbyCaptainMiscDef.FeatureType
local SLATE_COLOR_WHITE = UIResourceDef.COLOR.WHITE["SLATE_COLOR"]
local SLATE_COLOR_RED = UIResourceDef.COLOR.RED["SLATE_COLOR"]
local PROP_COMBO_DESC_KEY       = "PropCombo"
local PROP_COMBO_DESC_SUB_KEY   = "Id"
local LevelUpActorTag = "UIornaments_lvup"
local SHOW_TIMER = "ShowTimer"
local HIDE_TIMER = "HIDE_TIMER"
local DELAY_BTN_LOOP = "DELAY_BTN_LOOP"

-- 通过Tag从Level中获取对应Actor的Location和Rotation
local function GetActorLocationAndRotationByTag()
    local tbSubLevelTemplate = LobbySubLevelDataTable:GetTemplate(LobbySubTypeDef.CAPTAIN, UIDef.UI_LOBBY_CAPTAIN_DECORATION)
    if not tbSubLevelTemplate then
        logerror("UILobbyCaptainDecoration: tbSubLevelTemplate is invalid.")
        return 
    end
    local szActorTag = tbSubLevelTemplate.tbActorTag[1]
    if not szActorTag then
        logerror("UILobbyCaptainDecoration: szActorTag is invalid.")
        return
    end

    local tbCurrentActiveSubSys = LobbySystem:GetActiveSub()
    local pLocation, pRotation = tbCurrentActiveSubSys:GetLocationAndRotationByTag(LobbySubTypeDef.CAPTAIN, UIDef.UI_LOBBY_CAPTAIN_DECORATION, szActorTag)

    return pLocation, pRotation
end

local function GetLevelUpActor(self)
    if self.pLevelUpEffActor == nil then 
        local tbSubLevelTemplate = LobbySubLevelDataTable:GetTemplate(LobbySubTypeDef.CAPTAIN, UIDef.UI_LOBBY_CAPTAIN_DECORATION)
        if not tbSubLevelTemplate then
            logerror("UILobbyCaptainDecoration: tbSubLevelTemplate is invalid.")
            return nil
        end
        local tbCurrentActiveSubSys = LobbySystem:GetActiveSub()
        local pSubLevel = tbCurrentActiveSubSys:GetLevelStream(UIDef.UI_LOBBY_CAPTAIN_DECORATION)
        self.pLevelUpEffActor = ExtendBlueprintFunctions.GetLevelActorByTag(pSubLevel, LevelUpActorTag)
    end
    return self.pLevelUpEffActor
end

local function PlayLevelUp3dEff(self)
    local pLevelUpActor = GetLevelUpActor(self)
    if pLevelUpActor then  
        local tbDecorationInfo = self.tbDecorations[self.nSelectIdx]
        if tbDecorationInfo.tbTemplate and tbDecorationInfo.tbTemplate.nGrade then
            pLevelUpActor:PlayLevelUpEffect(tbDecorationInfo.tbTemplate.nGrade)
        end
    end
end

local function StopLevel3dEff(self)
    local pLevelUpActor = GetLevelUpActor(self)
    if pLevelUpActor then 
        pLevelUpActor:StopLevelUpEffect()
    end
end

local function UpdateProperties(self, tbDecorationTemplate, bShowNextLevel)
    local nBuffId = tbDecorationTemplate.nBuffId
    local nLevel = tbDecorationTemplate.nLevel
    local nPropertyComboIdCurrent = BattleBuffDataTable:GetBuffParam(nBuffId, nLevel, PROP_COMBO_DESC_KEY, PROP_COMBO_DESC_SUB_KEY)

    local nUpgradeToId = tbDecorationTemplate.nNextLevelId
    local tbTemplateNextLevel = ItemSystem:GetItemTemplate(nUpgradeToId)
    local nBuffIdNextLevel = tbTemplateNextLevel and tbTemplateNextLevel.nBuffId
    local nLevelNextLevel = tbTemplateNextLevel and tbTemplateNextLevel.nLevel
    local nPropertyComboIdNext = nBuffIdNextLevel and nLevelNextLevel and BattleBuffDataTable:GetBuffParam(nBuffIdNextLevel, nLevelNextLevel, PROP_COMBO_DESC_KEY, PROP_COMBO_DESC_SUB_KEY)

    local tbDisplayInfoListCurrent = nPropertyComboIdCurrent and PropertyComboSystem:GetPropertyComboDisplayInfoList(nPropertyComboIdCurrent) or {}
    local tbDisplayInfoListNext = nPropertyComboIdNext and PropertyComboSystem:GetPropertyComboDisplayInfoList(nPropertyComboIdNext) or {}
    local tbPropertiesData = {}
    for i = 1, PROPERTY_MAX_COUNT do
        local tbDisplayInfoCurrent = tbDisplayInfoListCurrent[i]
        local tbDisplayInfoNext = tbDisplayInfoListNext[i]
        local szNewDisplayTemp = tbDisplayInfoNext and tbDisplayInfoNext.szDisplayValue
        if not bShowNextLevel then
            szNewDisplayTemp = nil
        end
        if tbDisplayInfoCurrent then
            tbPropertiesData[i] = {
                l10nDisplayName = tbDisplayInfoCurrent.l10nDisplayName,
                szOldDisplayValue = tbDisplayInfoCurrent.szDisplayValue,
                szNewDisplayValue = szNewDisplayTemp
            }
        end
    end

    -- 读取 Buff 中非 PropertyCombo 的附加描述：
    local tbAppendDisplayInfoListCurrent = BattleHumanDecorationDescParser:GetDescAppendDisplayInfoList(tbDecorationTemplate.nId)
    local tbAppendDisplayInfoListNext  = BattleHumanDecorationDescParser:GetDescAppendDisplayInfoList(nUpgradeToId)
    for i,tbOneAppendDescItemCurrent in ipairs(tbAppendDisplayInfoListCurrent) do
        local tbOneAppendDescItemNext = tbAppendDisplayInfoListNext[i]
        local szNewDisplayTemp = tbOneAppendDescItemNext and tbOneAppendDescItemNext.szDisplayValue
        if not bShowNextLevel then
            szNewDisplayTemp = nil
        end
        if tbOneAppendDescItemCurrent then
            table.insert(tbPropertiesData, {
                l10nDisplayName = tbOneAppendDescItemCurrent.l10nDisplayName,
                szOldDisplayValue = tbOneAppendDescItemCurrent.szDisplayValue,
                szNewDisplayValue = szNewDisplayTemp
            })
        end
    end

    self.ListPropertiesHelper:SetData(tbPropertiesData)
end

local function UpdateSelectDecorationProperties(self, bShowNextLevel)
    local tbDecorationInfo = self.tbDecorations[self.nSelectIdx]
    UpdateProperties(self,  tbDecorationInfo.tbTemplate, bShowNextLevel)
end

local function Show3dDecoration(self, nResId)
    local tbDecorationResTemplate = LobbyDecorationResDataTable:GetTemplate(nResId)
    if not self.pDecorationActor and tbDecorationResTemplate then
        self.pDecorationActor = EngineExtActorShell.SpawnActorForScript(GWorld, StaticMeshActor, Transform(), nil)
    end
    if self.pDecorationActor and self.pDecorationActor.StaticMeshComponent then
        local szModelResPath = tbDecorationResTemplate.szModelResPath
        self.pDecorationActor:SetMobility(EComponentMobility.Movable)
        self.pDecorationActor.StaticMeshComponent:SetStaticMesh(szModelResPath:load())
        self.pDecorationActor.StaticMeshComponent:SetForcedLodModel(1)
        self.pDecorationActor.StaticMeshComponent:SetLightingChannels(false, true, false)
    end
    local pLocation, pRotation = GetActorLocationAndRotationByTag()
    local nScale = 1
    if tbDecorationResTemplate and pLocation and pRotation then
        pLocation.X = pLocation.X + tbDecorationResTemplate.tbModelLocationOffset[1]
        pLocation.Y = pLocation.Y + tbDecorationResTemplate.tbModelLocationOffset[2]
        pLocation.Z = pLocation.Z + tbDecorationResTemplate.tbModelLocationOffset[3]
        pRotation.Pitch = pRotation.Pitch + tbDecorationResTemplate.tbModelRotationOffset[1]
        pRotation.Yaw = pRotation.Yaw + tbDecorationResTemplate.tbModelRotationOffset[2]
        pRotation.Roll = pRotation.Roll + tbDecorationResTemplate.tbModelRotationOffset[3]
        nScale = nScale * tbDecorationResTemplate.nModelScale
        EngineExtActorShell.SetActorLocation(self.pDecorationActor, pLocation)
        if self.bSet3dRot == true then
            EngineExtActorShell.SetActorRotation(self.pDecorationActor, pRotation)
        end
        self.bSet3dRot = true
        EngineExtActorShell.SetActorScale(self.pDecorationActor, nScale)
    end
end

local function UnlockCurrentDecoration(self)
    local tbDecorationInfo = self.tbDecorations[self.nSelectIdx]
    local tbEquipState = UILobbyCaptainHelper.tbCaptainItemState
    if tbDecorationInfo.nEquipState == tbEquipState.UNGET then
        local nSourceType = tbDecorationInfo.tbTemplate.nSourceType
        if ItemSourceDataTable:IfShowBuyButton(nSourceType) then
            local tbGoodsTemplate = ShopDataTable:GetItemGoodsTemplate(tbDecorationInfo.nTemplateId)
            ShopSystem:OnBuyButtonClick(tbGoodsTemplate)
        end
    end
end

local function OnListSelectedChanged(self, nIndex)
    local tbDecorationInfo = self.tbDecorations[nIndex]
    self.nSelectIdx = nIndex
    self.pDecorationInfo:SetData(tbDecorationInfo)
    local nMaxLevel = UILobbyCaptainHelper.GetMaxUpGradeLevel()
    self.bSelectReachMaxLevel = tbDecorationInfo.tbTemplate.nLevel >= nMaxLevel

    -- self.pWidgetRef.txtIntro:SetText(ItemSystem:GetItemIntro(tbDecorationInfo.nTemplateId))
    self.pWidgetRef.txtBgInfo:SetText(tbDecorationInfo.tbTemplate.l10nBgIntro)
    local bShowNextLevel = not self.bShowList
    UpdateProperties(self, tbDecorationInfo.tbTemplate, bShowNextLevel)

    local nBuffId = 0
    local pImgBuff = self.pWidgetRef.imgBuff
    if tbDecorationInfo then
        nBuffId = tbDecorationInfo.tbTemplate.nBuffId
    end
    if nBuffId > 0 then
        pImgBuff:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        local tbRes = BattleBuffDataTable:GetResTemplate(nBuffId)
        local szRes = tbRes.szIconRes
        UISetUtils.SetImageBrushRes(pImgBuff, szRes:load())
    else
        pImgBuff:SetVisibility(ESlateVisibility.Collapsed)
    end

    local tbEquipState = UILobbyCaptainHelper.tbCaptainItemState
    local pWidgetRef = self.pWidgetRef

    if self.bShowList then
        pWidgetRef.btnEquip:SetVisibility(tbDecorationInfo.nEquipState == tbEquipState.GET and
            ESlateVisibility.Visible or ESlateVisibility.Collapsed)
        pWidgetRef.btnUnEquip:SetVisibility(tbDecorationInfo.nEquipState == tbEquipState.EQUIP and
            ESlateVisibility.Visible or ESlateVisibility.Collapsed)
        if tbDecorationInfo.nEquipState == tbEquipState.UNGET then
            local nSourceType = tbDecorationInfo.tbTemplate.nSourceType
            local bShowBuyBtn = ItemSourceDataTable:IfShowBuyButton(nSourceType)
            pWidgetRef.btnBuy:SetVisibility(bShowBuyBtn and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
            pWidgetRef.bdrUnlock:SetVisibility(bShowBuyBtn and ESlateVisibility.Collapsed or ESlateVisibility.SelfHitTestInvisible)
            if not bShowBuyBtn then 
                pWidgetRef.kmtxtUnlockDesc:SetText(ItemSourceDataTable:GetSourceDesc(nSourceType))
            end
        else 
            pWidgetRef.btnBuy:SetVisibility( ESlateVisibility.Collapsed)
            pWidgetRef.bdrUnlock:SetVisibility( ESlateVisibility.Collapsed)
        end
    else
        pWidgetRef.btnEquip:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.btnUnEquip:SetVisibility(ESlateVisibility.Collapsed)
    end

    if tbDecorationInfo.nEquipState == tbEquipState.UNGET then
        pWidgetRef.btnListSeeR:SetVisibility( ESlateVisibility.Collapsed)
        pWidgetRef.UpgradeBox:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.UpgradeFx:SetVisibility(ESlateVisibility.Collapsed)
    else
        pWidgetRef.btnListSeeR:SetVisibility( self.bShowList and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
        local bCollapse = self.bShowList or self.bSelectReachMaxLevel or self.bPlayUpgradeEff
        pWidgetRef.UpgradeBox:SetVisibility( bCollapse and ESlateVisibility.Collapsed or ESlateVisibility.Visible)
        pWidgetRef.UpgradeFx:SetVisibility( bCollapse and ESlateVisibility.Collapsed or ESlateVisibility.SelfHitTestInvisible)
    end

    pWidgetRef.vbLevelUp:SetVisibility((not self.bSelectReachMaxLevel) and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
    pWidgetRef.txtMaxLv:SetVisibility(self.bSelectReachMaxLevel and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed)
    local pIcon = CurrencySystem:GetCurrencySmallIcon(tbDecorationInfo.tbTemplate.nConsumeId)
    if pIcon then
        UISetUtils.SetImageBrushRes(pWidgetRef.ImgMoney, pIcon:load(), false, true, IMAGE_SIZE, IMAGE_SIZE)
    end

    local nCurrencyCount = CurrencySystem:GetCurrencyCount(tbDecorationInfo.tbTemplate.nConsumeId)
    local bEnough = nCurrencyCount >= tbDecorationInfo.tbTemplate.nConsumeCount
    pWidgetRef.txtCount:SetText(tbDecorationInfo.tbTemplate.nConsumeCount)
    pWidgetRef.txtCount:SetColorAndOpacity(bEnough and SLATE_COLOR_WHITE or SLATE_COLOR_RED)

    local nResId = tbDecorationInfo.tbTemplate.nResId
    Show3dDecoration(self, nResId)
    
end

local function CheckAndUpdateSelectDecoration(self, nInstanceId, bPutOn)
    for _, v in ipairs(self.tbDecorations) do
        if nInstanceId == v.nInstanceId then
            v.nEquipState = bPutOn and UILobbyCaptainHelper.tbCaptainItemState.EQUIP
                or UILobbyCaptainHelper.tbCaptainItemState.GET
            break
        end
    end
    self.bSet3dRot = false
    self.ListHelper:SetSelectedIndex(self.nSelectIdx)
    self.ListHelper:RequestListRefresh()
end

local function OnDecorationPutOn(self, nInstanceId)
    CheckAndUpdateSelectDecoration(self, nInstanceId, true)
end

local function OnDecorationTakeOff(self, nInstanceId)
    CheckAndUpdateSelectDecoration(self, nInstanceId, false)
end

local function EquipDecoration(self)
    local tbDecorationInfo = self.tbDecorations[self.nSelectIdx]
    if tbDecorationInfo then
        ItemSystem:RequestEquipDecorationItem(tbDecorationInfo.nInstanceId)
    end
end

local function UnEquipDecoration(self)
    ItemSystem:RequestUnequipDecorationItem()
end

local function ShowNotEnoughToast(nCurrencyId)
    UIUtils.ShowToast(L10N:Format(UISetUtils.GetL10NTextByKey("DECORATION_CURRENCY_NOT_ENOUGH"), CurrencySystem:GetCurrencyName(nCurrencyId)))
end

local function ShowUpgradeWidgets(self, bShow)
    self.pWidgetRef.UpgradeBox:SetVisibility(bShow and ESlateVisibility.Visible or ESlateVisibility.Collapsed )
    
    local bShowEff = not self.bSelectReachMaxLevel and bShow
    self.pWidgetRef.UpgradeFx:SetVisibility(bShowEff and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed)
end

local function UpgradeCurrentDecoration(self)
    local tbDecorationInfo = self.tbDecorations[self.nSelectIdx]
    if tbDecorationInfo == nil then return end
    if self.bSelectReachMaxLevel then
        UIUtils.ShowToast(UITextDef.UPGRADE_MAX_LEVEL)
        return
    end
    local nCurrencyCount = CurrencySystem:GetCurrencyCount(tbDecorationInfo.tbTemplate.nConsumeId)
    local bEnough = nCurrencyCount >= tbDecorationInfo.tbTemplate.nConsumeCount
    if bEnough then
        self.nCurrentLevelUpId = tbDecorationInfo.tbTemplate.nNextLevelId
        ItemSystem:RequestUpgradeCurrentDecoration(tbDecorationInfo.nInstanceId)
        UIUtils.ShowWaitingPacket()
        self.bPlayUpgradeEff = true
        ShowUpgradeWidgets(self, false)
    else
        ShowNotEnoughToast(tbDecorationInfo.tbTemplate.nConsumeId)
    end
end

local function OnUpgradeFinish(self)
    UIUtils.HideWaitingPacket()
end

local function TryDisableUpgradeBtnAndAnim(self)
    if self.bSelectReachMaxLevel then
        self.pWidgetRef.UpgradeBox:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.UpgradeFx:SetVisibility(ESlateVisibility.Collapsed)
        self.Owner:StopAnimation("anim_LevelUpLoop")
    end
end

local function OnAddItem(self, Item)
    local nItemTemplateId = Item:GetTemplateId()
    if self.nCurrentLevelUpId == nItemTemplateId then
        local tbDecorationInfo = self.tbDecorations[self.nSelectIdx]
        tbDecorationInfo.nTemplateId = nItemTemplateId
        tbDecorationInfo.tbTemplate = Item:GetTemplate()
        tbDecorationInfo.tbResTemplate = ItemDataTable:GetResTemplate(nItemTemplateId)
        tbDecorationInfo.nInstanceId = Item:GetInstanceId()
        self.bSet3dRot = false
        self.ListHelper:SetSelectedIndex(self.nSelectIdx)
        self.ListHelper:RequestListRefresh()
        PlayLevelUp3dEff(self)
        ShowUpgradeWidgets(self, false)
        self.bPlayUpgradeEff = true
        Timer.StartOwnerTimer(self, HIDE_TIMER, function()
            if not self.bShowList then
                ShowUpgradeWidgets(self, true)
            end
            self.bPlayUpgradeEff = false
        end, HIDE_SEC, false)
        TryDisableUpgradeBtnAndAnim(self)
    end
end

local function UpdateButtons(self, bShowListBtn, bShowLevelUpBtn)
    -- self.pWidgetRef.btnListSeeL:SetVisibility(bShowListBtn and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
    if self.pWidgetRef == nil then return end

    local tbDecorationInfo = self.tbDecorations[self.nSelectIdx]
    local bReachMaxLevel = self.bSelectReachMaxLevel
    local tbEquipState = UILobbyCaptainHelper.tbCaptainItemState

    local pWidgetRef = self.pWidgetRef
    if tbDecorationInfo.nEquipState == tbEquipState.UNGET then
        pWidgetRef.btnListSeeR:SetVisibility( ESlateVisibility.Collapsed)
        pWidgetRef.UpgradeBox:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.UpgradeFx:SetVisibility(ESlateVisibility.Collapsed)
    else
        pWidgetRef.btnListSeeR:SetVisibility(bShowLevelUpBtn and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
        Timer.StartOwnerTimer(self, DELAY_BTN_LOOP, function()
            if self.pWidgetRef then
                pWidgetRef.UpgradeFx:SetVisibility((bShowLevelUpBtn or bReachMaxLevel) and ESlateVisibility.Collapsed or ESlateVisibility.SelfHitTestInvisible)
            end
        end, 0.6)
        pWidgetRef.UpgradeBox:SetVisibility((bShowLevelUpBtn or bReachMaxLevel) and ESlateVisibility.Collapsed or ESlateVisibility.Visible)
        
    end

    if self.bShowList then
        pWidgetRef.btnEquip:SetVisibility(tbDecorationInfo.nEquipState == tbEquipState.GET and
            ESlateVisibility.Visible or ESlateVisibility.Collapsed)
        pWidgetRef.btnUnEquip:SetVisibility(tbDecorationInfo.nEquipState == tbEquipState.EQUIP and
            ESlateVisibility.Visible or ESlateVisibility.Collapsed)
        pWidgetRef.txtBgInfo:SetVisibility(ESlateVisibility.Visible)
    else
        pWidgetRef.btnEquip:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.btnUnEquip:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtBgInfo:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function ShowListView(self, bFirstShowList)
    self.bShowList = true
    -- 显示列表界面时需要先播完动画，再设置按钮显示与否的状态，否则 UpgradeBox 收起的动画就看不到了，而 装备 按钮也会过早显示出来：
   
    if bFirstShowList then  
        self.Owner:PlayAnimation("anim_LobbyCaptainDecorationIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
        Timer.StartOwnerTimer(self, SHOW_TIMER, function()
            UpdateButtons(self, false, true)
        end, TIME_SEC, false)
    else   
        self.Owner:PlayAnimation("anim_LobbyCaptainDecorationLevelUpIn", 0, 1, EUMGSequencePlayMode.Reverse, 1)
        Timer.StartOwnerTimer(self, SHOW_TIMER, function()
            UpdateButtons(self, false, true)
            self.Owner:StopAnimation("anim_LevelUpLoop")
        end, TIME_SEC, false)
    end
    UpdateSelectDecorationProperties(self, false)

    local tbCurrentActiveSubSys = LobbySystem:GetActiveSub()
    tbCurrentActiveSubSys:SetCameraWithBlend(UIDef.UI_LOBBY_CAPTAIN_DECORATION, CAMERA_INDEX_2, CAMERA_BLEND_TIME, EViewTargetBlendFunction.VTBlend_EaseOut, CAMERA_BLEND_EXPONENT)
end

local function ShowUpgradeView(self)
    --lz
    if self.bSelectReachMaxLevel then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("DECORATION_REACH_MAX_LEVEL"))
        return
    end

    self.bShowList = false
    -- 显示升级界面时需要先设置按钮显示与否的状态，再播动画，否则 UpgradeBox 展开动画就看不到了：
    UpdateButtons(self, true, false)
    UpdateSelectDecorationProperties(self, true)
    self.Owner:PlayAnimation("anim_LobbyCaptainDecorationLevelUpIn", 0, 1, EUMGSequencePlayMode.Forward, 1, 
    function() 
        self.Owner:PlayAnimation("anim_LevelUpLoop", 0, 0, EUMGSequencePlayMode.Forward, 1)
    end)
    

    local tbCurrentActiveSubSys = LobbySystem:GetActiveSub()
    tbCurrentActiveSubSys:SetCameraWithBlend(UIDef.UI_LOBBY_CAPTAIN_DECORATION, CAMERA_INDEX_1, CAMERA_BLEND_TIME, EViewTargetBlendFunction.VTBlend_EaseOut, CAMERA_BLEND_EXPONENT)
end

local function OnGoShoppingSuccess(self, nGoodsId)
    local tbDecorationInfo = self.tbDecorations[self.nSelectIdx]

    local tbGoodsTemplate = ShopDataTable:GetItemGoodsTemplate(tbDecorationInfo.nTemplateId)
    if tbGoodsTemplate == nil then
        return
    end
    local nUnlockDecorationId = tbDecorationInfo.nTemplateId
    if nGoodsId == tbGoodsTemplate.nId then
        self.tbDecorations = UILobbyCaptainHelper.GetAllDecorations()
        self.ListHelper:SetData(self.tbDecorations)
        self.ListHelper:ScrollToTop(false)
        for k, v in ipairs(self.tbDecorations) do
            if v.nTemplateId == nUnlockDecorationId then
                self.ListHelper:SetSelectedIndex(k)
                break
            end
        end
    end
end

local function OnBackClicked(self)
    --lz
    Timer.StopOwnerTimer(self, HIDE_TIMER)
    StopLevel3dEff(self)
    if self.bShowList then  
        self.Owner:StopAnimation("anim_LevelUpLoop")
        self.pbWindowFrame:SetBackIsCloseSelf(true)
        self.EventHelper:FireEvent(ClientEventDef.EV_LOBBY_CAPTAIN_CALL_TO_DEACIVATE_FEATURE, FeatureType.Decoration)
    else  
        ShowListView(self)
        self.pbWindowFrame:SetBackIsCloseSelf(false)
    end
end

local function RotateDecorationActor(self, nYawDelta)
    local pDecorationActor = self.pDecorationActor
    if pDecorationActor then
        local tbRotation = pDecorationActor:K2_GetActorRotation()
        tbTempRotation.Pitch = tbRotation.Pitch
        tbTempRotation.Roll = tbRotation.Roll
        tbTempRotation.Yaw = tbRotation.Yaw + nYawDelta
        pDecorationActor:K2_SetActorRotation(tbTempRotation)
    end
end

local function OnMouseButtonDown(self, pGeometry, pMouseEvent)
    local nTouchIndex = KismetInputLibrary.PointerEvent_GetPointerIndex(pMouseEvent)
    self.tbDragIndex[nTouchIndex] = true
    self.tbDragLastPos[nTouchIndex] = KismetInputLibrary.PointerEvent_GetScreenSpacePosition(pMouseEvent)
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseButtonMove(self, pGeometry, pMouseEvent)
    local nTouchIndex = KismetInputLibrary.PointerEvent_GetPointerIndex(pMouseEvent)
    if not self.tbDragIndex[nTouchIndex] or not self.tbDragLastPos[nTouchIndex] then
        return WidgetBlueprintLibrary.Handled()
    end

    local tbCurPos = KismetInputLibrary.PointerEvent_GetScreenSpacePosition(pMouseEvent)
    local nMoveDeltaX = tbCurPos.X - self.tbDragLastPos[nTouchIndex].X

    RotateDecorationActor(self, -nMoveDeltaX * DRAG_SPEED)

    self.tbDragLastPos[nTouchIndex] = tbCurPos
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseButtonUp(self, pGeometry, pMouseEvent)
    local nTouchIndex = KismetInputLibrary.PointerEvent_GetPointerIndex(pMouseEvent)
    self.tbDragIndex[nTouchIndex] = false
    self.tbDragLastPos[nTouchIndex] = nil
    return WidgetBlueprintLibrary.Handled()
end

local function OnActiveDecorationMain(self)
    self.tbDragIndex = {}
    self.tbDragLastPos = {}

    self.pbWindowFrame = self.Owner.pbWindowFrame
    self.pbWindowFrame:SetBackDelegate(OnBackClicked, self)

    self.pDecorationInfo = self.Owner.pDecorationInfo
    local pWidgetRef = self.pWidgetRef
    self.ListPropertiesHelper = SelfVerticalListHelper()
    self.ListPropertiesHelper:Init(self, pWidgetRef.listProperties)

    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, pWidgetRef.pItemList, {}, UIDef.UP_DECORATION_LIST_ITEM)

    self.tbDecorations = UILobbyCaptainHelper.GetAllDecorations()
    self.ListHelper:SetData(self.tbDecorations)
    self.ListHelper.OnSelectedChangedDelegate:Bind(OnListSelectedChanged, self)
    self.ListHelper:SetSelectedIndex(DEFAULT_SELECT)
    ShowListView(self, true)
end

local function OnShopNotEnoughCurrency(self, tbShoppingGoods)
    if not tbShoppingGoods.currency_auto_exchange then
        CostCurrencyHelper:FirstCostFailed()
    else
        CostCurrencyHelper:SecondCostFailed()
    end
end

local function OnDeactiveDecorationMain(self)
    StopLevel3dEff(self)
    self.ListHelper:Uninit()
    self.ListHelper = nil
    self.ListPropertiesHelper:Uninit()
    self.ListPropertiesHelper = nil
    self.pLevelUpEffActor = nil
    Timer.StopOwnerAllTimer(self, true)
    local pDecorationActor = self.pDecorationActor
    self.pDecorationActor = nil
    if(isvalidhandle(pDecorationActor)) then
        EngineExtActorShell.DestroyActor(GWorld, pDecorationActor, false)
    end
    if self.EventHelper then 
        self.EventHelper:UnregisterAll()
    end
end

local function RegisterDecorationMainEvent(self)
    local EventHelper = self.EventHelper
    local pWidgetRef = self.pWidgetRef
    -- EventHelper:RegisterCppDelegate(pWidgetRef.btnBack.OnClicked, self, OnBackClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnEquip.OnClicked, self, EquipDecoration)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnUnEquip.OnClicked, self, UnEquipDecoration)
    -- EventHelper:RegisterCppDelegate(pWidgetRef.btnListSeeL.OnClicked, self, ShowListView)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnListSeeR.OnClicked, self, ShowUpgradeView)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnUpgrade.OnClicked, self, UpgradeCurrentDecoration)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBuy.OnClicked, self, UnlockCurrentDecoration)

    EventHelper:RegisterEvent(ClientEventDef.EV_GO_SHOPPING_SUCCESS, self, OnGoShoppingSuccess)
    EventHelper:RegisterEvent(ClientEventDef.EV_EQUIP_LOBBY_DECORATION, self, OnDecorationPutOn)
    EventHelper:RegisterEvent(ClientEventDef.EV_UNEQUIP_LOBBY_DECORATION, self, OnDecorationTakeOff)
    EventHelper:RegisterEvent(ClientEventDef.EV_ADD_LOBBY_ITEM, self, OnAddItem)
    EventHelper:RegisterEvent(ClientEventDef.EV_UPGRADE_DECORATION_FINISH, self, OnUpgradeFinish)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHOP_NOT_ENOUGH_CURRENCY, self, OnShopNotEnoughCurrency)
    

    local pBorderWidget = pWidgetRef.bdrModelRotateListener
    EventHelper:RegisterCppDelegateFunc(pBorderWidget.OnMouseButtonDownEvent, function(pGeometry, pMouseEvent) return OnMouseButtonDown(self, pGeometry, pMouseEvent) end)
    EventHelper:RegisterCppDelegateFunc(pBorderWidget.OnMouseMoveEvent, function(pGeometry, pMouseEvent) return OnMouseButtonMove(self, pGeometry, pMouseEvent) end)
    EventHelper:RegisterCppDelegateFunc(pBorderWidget.OnMouseButtonUpEvent, function(pGeometry, pMouseEvent) return OnMouseButtonUp(self, pGeometry, pMouseEvent) end)
    
end

local function OnShowBackClicked(self)
    --LobbySystem:Deactivate(LobbySubTypeDef.SHOW)
    LobbySystem:ReturnToPrevSub()
end

local function OnActiveDecorationShow(self, tbInfo)
    self.tbDragIndex = {}
    self.tbDragLastPos = {}
    self.ListPropertiesHelper = SelfVerticalListHelper()
    self.ListPropertiesHelper:Init(self, self.pWidgetRef.listProperties)

    self.pDecorationInfo = self.Owner.pDecorationInfo
    self.pDecorationInfo.bShowOnly = true
    self.nShowDecorationId = tbInfo.nTemplateId

    self.pbWindowFrame = self.Owner.pbWindowFrame
    self.pbWindowFrame:SetBackDelegate(OnShowBackClicked, self)
    
    --construct fake decoration
    local tbItemTemplate = ItemDataTable:GetTemplate(tbInfo.nTemplateId)
    local tbItemInBag = ItemSystem:GetItemsByTemplateId(tbInfo.nTemplateId)
    local tbFakeDecorationInfo = {
        nTemplateId = tbInfo.nTemplateId, tbTemplate = tbItemTemplate,
        tbResTemplate = ItemDataTable:GetResTemplate(tbInfo.nTemplateId), 
        nEquipState = #tbItemInBag ~= 0 and UILobbyCaptainHelper.tbCaptainItemState.GET or UILobbyCaptainHelper.tbCaptainItemState.UNGET,
        nInstanceId = NOT_IN_BAG_ID
    }
    self.pDecorationInfo:SetData(tbFakeDecorationInfo)

    --update buff
    local nBuffId = 0
    local pImgBuff = self.pWidgetRef.imgBuff
    if tbFakeDecorationInfo then
        nBuffId = tbFakeDecorationInfo.tbTemplate.nBuffId
    end
    if nBuffId > 0 then
        pImgBuff:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        local tbRes = BattleBuffDataTable:GetResTemplate(nBuffId)
        local szRes = tbRes.szIconRes
        UISetUtils.SetImageBrushRes(pImgBuff, szRes:load())
    else
        pImgBuff:SetVisibility(ESlateVisibility.Collapsed)
    end
    --update property
    UpdateProperties(self, tbFakeDecorationInfo.tbTemplate, false)
    --update bg info
    self.pWidgetRef.txtBgInfo:SetText(tbFakeDecorationInfo.tbTemplate.l10nBgIntro)
    --show 3d actor
    local nResId = tbFakeDecorationInfo.tbTemplate.nResId
    Show3dDecoration(self, nResId)
end

local function RegisterDecorationShowEvent(self)
    local EventHelper = self.EventHelper
    local pWidgetRef = self.pWidgetRef
    local pBorderWidget = pWidgetRef.bdrModelRotateListener
    EventHelper:RegisterCppDelegateFunc(pBorderWidget.OnMouseButtonDownEvent, function(pGeometry, pMouseEvent) return OnMouseButtonDown(self, pGeometry, pMouseEvent) end)
    EventHelper:RegisterCppDelegateFunc(pBorderWidget.OnMouseMoveEvent, function(pGeometry, pMouseEvent) return OnMouseButtonMove(self, pGeometry, pMouseEvent) end)
    EventHelper:RegisterCppDelegateFunc(pBorderWidget.OnMouseButtonUpEvent, function(pGeometry, pMouseEvent) return OnMouseButtonUp(self, pGeometry, pMouseEvent) end)
end

local function OnDeactiveDecorationShow(self)
    self.ListPropertiesHelper:Uninit()
    self.ListPropertiesHelper = nil
    local pDecorationActor = self.pDecorationActor
    Timer.StopOwnerAllTimer(self, true)
    self.pDecorationActor = nil
    if(isvalidhandle(pDecorationActor)) then
        EngineExtActorShell.DestroyActor(GWorld, pDecorationActor, false)
    end
end

function ULLobbyDecoration:Activate(nUiType, ...)
    self.nUiType = nUiType
    if self.nUiType == UILobbyCaptainHelper.DecorationUIType.MAIN then  
        OnActiveDecorationMain(self)
        RegisterDecorationMainEvent(self)
    elseif self.nUiType == UILobbyCaptainHelper.DecorationUIType.SHOW then  
        OnActiveDecorationShow(self, ...)
        RegisterDecorationShowEvent(self)
    end
end

function ULLobbyDecoration:Deactivate()
    if self.nUiType == UILobbyCaptainHelper.DecorationUIType.MAIN then
        OnDeactiveDecorationMain(self)
    elseif self.nUiType == UILobbyCaptainHelper.DecorationUIType.SHOW then
        OnDeactiveDecorationShow(self)
    end
end

function ULLobbyDecoration:OnCreate()
end

function ULLobbyDecoration:OnLoad()
end

function ULLobbyDecoration:OnUnload()
    
end

return ULLobbyDecoration