-----------------------------------------------------
--File Name    : UPDebugHumanWeaponPanel.lua
--Author       : WuJizhou
--Create Time  : 2018-12-26 11:51:30
--Description  : UPDebugHumanWeaponPanel
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")

local UPDebugHumanWeaponPanel = luaclass("UPDebugHumanWeaponPanel", PrefabBase)

local SelfVerticalListHelper = require("SelfVerticalListHelper")
local UIDef = require("UIDef")
local HumanWeaponDef = require("HumanWeaponDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemSystemClient = require("BattleItemSystemClient")
local BattleItemCategoryDef = require("BattleItemCategoryDef")

local HumanWeaponProperty = HumanWeaponDef.Property

UPDebugHumanWeaponPanel.tbWeaponPropertyItem = nil
UPDebugHumanWeaponPanel.ListHelper = nil

local tbPropertyName = {}
tbPropertyName[HumanWeaponProperty.CD] = "输入cd"
tbPropertyName[HumanWeaponProperty.OpenSightSpeed] = "开镜速度"
tbPropertyName[HumanWeaponProperty.DamagePerBullet] = "单发伤害"
tbPropertyName[HumanWeaponProperty.RateOfFire] = "射速"
-- tbPropertyName[HumanWeaponProperty.SpeedAffectDamage] = "飞行速度是否影响伤害"
tbPropertyName[HumanWeaponProperty.InitialSpeed] = "子弹初速度"
-- tbPropertyName[HumanWeaponProperty.FireType] = "开枪制式"
tbPropertyName[HumanWeaponProperty.ReloadTime] = "装填时间"
-- tbPropertyName[HumanWeaponProperty.BulletType] = "子弹类型"
tbPropertyName[HumanWeaponProperty.BulletMax] = "子弹数量"
tbPropertyName[HumanWeaponProperty.EffectiveRange] = "射程"
-- tbPropertyName[HumanWeaponProperty.RecoilUpperAngle] = "后坐力垂直角度上限"
-- tbPropertyName[HumanWeaponProperty.RecoildLowerAngle] = "后坐力垂直角度下限"
-- tbPropertyName[HumanWeaponProperty.RecoildHUpperAngle] = "后坐力水平角度上限"
-- tbPropertyName[HumanWeaponProperty.RecoilHorizontalMaxPercent] = "枪口水平随机跳动最大比例"
-- tbPropertyName[HumanWeaponProperty.RecoilHorizontalMinPercent] = "枪口水平随机跳动最小比例"
-- tbPropertyName[HumanWeaponProperty.RecoilDuration] = "后坐力持续时间"
-- tbPropertyName[HumanWeaponProperty.RecoilRecoverMaxPercent] = "后坐恢复最大百分比"
-- tbPropertyName[HumanWeaponProperty.RecoilRecoverMinPercent] = "后坐恢复最小百分比"
-- tbPropertyName[HumanWeaponProperty.RecoilMaxYaw] = "后坐造成的摄像机在Z轴上旋转角度上限"
-- tbPropertyName[HumanWeaponProperty.RecoilMinYaw] = "后坐造成的摄像机在Z轴上旋转角度下限"
tbPropertyName[HumanWeaponProperty.DispersionDeviation] = "散布标准差"
tbPropertyName[HumanWeaponProperty.DispersionRecover] = "散布的恢复时间"
tbPropertyName[HumanWeaponProperty.Dispersion] = "武器散布基础值"
tbPropertyName[HumanWeaponProperty.DispersionPublishStand] = "站姿散布惩罚"
tbPropertyName[HumanWeaponProperty.DispersionPublishSquat] = "蹲姿散布惩罚"
tbPropertyName[HumanWeaponProperty.DispersionPublishProne] = "卧姿散布惩罚"
tbPropertyName[HumanWeaponProperty.DispersionPublishWalk] = "走姿散布惩罚"
tbPropertyName[HumanWeaponProperty.DispersionPublishJump] = "跳姿散布惩罚"
tbPropertyName[HumanWeaponProperty.DispersionPublishNormalAim] = "腰射瞄准散布惩罚（非开火后恢复时间内）"
tbPropertyName[HumanWeaponProperty.DispersionPublishSightAim] = "开镜瞄准散布惩罚（非开火后恢复时间内）"
tbPropertyName[HumanWeaponProperty.DispersionPublishNormalFire] = "腰射开火散布惩罚（非开火后恢复时间内）"
tbPropertyName[HumanWeaponProperty.DispersionPublishSightFire] = "开镜开火散布惩罚（非开火后恢复时间内）"
tbPropertyName[HumanWeaponProperty.MeleeAttackSpeed] = "近战挥动速度"
-- tbPropertyName[HumanWeaponProperty.ScopeResId] = "开镜准镜资源id"
tbPropertyName[HumanWeaponProperty.OpenAimCameraRate] = "武器开镜倍率"
tbPropertyName[HumanWeaponProperty.OpenAimCameraHMoveScale] = "武器开镜划屏水平方向系数"
tbPropertyName[HumanWeaponProperty.OpenAimCameraVMoveScale] = "武器开镜划屏垂直方向系数"
tbPropertyName[HumanWeaponProperty.DeviationX] = "不开镜长轴散布系数"
tbPropertyName[HumanWeaponProperty.DeviationY] = "不开镜短轴散布系数"
tbPropertyName[HumanWeaponProperty.AimDeviationX] = "开镜长轴散布系数"
tbPropertyName[HumanWeaponProperty.AimDeviationY] = "开镜短轴散布系数"
tbPropertyName[HumanWeaponProperty.DecreaseBulletCount] = "一次性扣弹个数"
tbPropertyName[HumanWeaponProperty.MaxSpotCount] = "一次性打出子弹个数"
tbPropertyName[HumanWeaponProperty.MaxSectorAngle] = "最大散布角度"
tbPropertyName[HumanWeaponProperty.WeaponLength] = "武器长度"

UPDebugHumanWeaponPanel.tbDataList = nil

local tbErrorCode = {}
tbErrorCode.NotHuman = 1
tbErrorCode.NoWeaponComponent = 2
tbErrorCode.NoWeapon = 3
tbErrorCode.NotWeaponCategory = 4
tbErrorCode.IllegalWeaponOwner = 5

local tbErrorMsg = {}
tbErrorMsg[tbErrorCode.NotHuman]            = "当前不是人形态，无法调整武器属性"
tbErrorMsg[tbErrorCode.NoWeaponComponent]   = "当前没有HumanWeaponComponent，无法调整武器属性"
tbErrorMsg[tbErrorCode.NoWeapon]            = "当前没持有武器，无法调整武器属性"
tbErrorMsg[tbErrorCode.NotWeaponCategory]   = "当前持有的物品类型不是武器，无法调整武器属性"
tbErrorMsg[tbErrorCode.IllegalWeaponOwner]  = "当前持有的武器的所有者非法，无法调整武器属性"

local function OnCommitClicked(self)
    local tbPlayer = GamePlayerSelfHelper:Get()
    local WeaponComponent = tbPlayer.HumanWeaponComponent
    local nCurrentWeaponInstanceId = WeaponComponent:GetCurrentWeaponInstanceId()
    local tbCurrentWeapon = BattleItemSystemClient:GetItem(nCurrentWeaponInstanceId)
    local tbProperty = tbCurrentWeapon:GetBaseProperty(true)
    local szCommand = "sethumanweaponproperty"
    local bChanged = false
    for _, v in ipairs(self.tbDataList) do
        local szProperty =  v.szProperty
        if tbProperty[szProperty] ~= v.nValue then
            szCommand =  szCommand .." " .. szProperty .. " " .. v.nValue
            if not bChanged then
                bChanged = true
            end
        end
    end
    if bChanged then
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, szCommand, GameplayStatics.GetPlayerController(GWorld, 0))
    end
end

local function CheckOnShow(self)
    local tbPlayer = GamePlayerSelfHelper:Get()
    if (not tbPlayer) or (not tbPlayer:IsHuman()) then
        return false, tbErrorCode.NotHuman
    end
    local WeaponComponent = tbPlayer.HumanWeaponComponent
    if not WeaponComponent then
        return false, tbErrorCode.NoWeaponComponent
    end
    local nCurrentWeaponInstanceId = WeaponComponent:GetCurrentWeaponInstanceId()
    local tbCurrentWeapon = BattleItemSystemClient:GetItem(nCurrentWeaponInstanceId)
    if not tbCurrentWeapon then
        return false, tbErrorCode.NoWeapon
    end
    local nCategory = tbCurrentWeapon:GetCategory()
    if nCategory ~= BattleItemCategoryDef.HUMAN_WEAPON then
        return false, tbErrorCode.NotWeaponCategory
    end
    local nOwnerCharacterId = tbCurrentWeapon:GetOwnerCharacterInstanceId()
    local nPlayerId = tbPlayer:GetServerInstanceId()
    if nOwnerCharacterId ~= nPlayerId then
        return false, tbErrorCode.IllegalWeaponOwner
    end
    return true
end

-- local function CheckOnCommit()

-- end


function UPDebugHumanWeaponPanel:OnCreate()
    self.ListHelper = SelfVerticalListHelper()
end

function UPDebugHumanWeaponPanel:OnLoad()
    local pWidgetRef = self.pWidgetRef

    self.ListHelper:Init(self, pWidgetRef.vList, {}, UIDef.UP_DEBUG_HUMAN_WEAPON_LIST_ITEM)
end

function UPDebugHumanWeaponPanel:OnUnload()
    self.ListHelper:Uninit()
end


function UPDebugHumanWeaponPanel:OnShow()
    local pWidgetRef = self.pWidgetRef
    local bCheckResult, nErrorCode = CheckOnShow(self)
    if not bCheckResult then
        local szErrorMsg = tbErrorMsg[nErrorCode]
        pWidgetRef.txtErrorMsg:SetText(szErrorMsg)
        pWidgetRef.txtErrorMsg:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.vList:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.btnCommit:SetVisibility(ESlateVisibility.Collapsed)
        return
    end
    pWidgetRef.txtErrorMsg:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.vList:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.btnCommit:SetVisibility(ESlateVisibility.Visible)
    self.tbDataList = {}
    local tbPlayer = GamePlayerSelfHelper:Get()
    local WeaponComponent = tbPlayer.HumanWeaponComponent
    local nCurrentWeaponInstanceId = WeaponComponent:GetCurrentWeaponInstanceId()
    local tbCurrentWeapon = BattleItemSystemClient:GetItem(nCurrentWeaponInstanceId)
    local tbProperty = tbCurrentWeapon:GetBaseProperty(true)
    for k, v in pairs(tbPropertyName) do
        local tbData = {}
        tbData.szProperty = k
        tbData.szName = v
        local tempValue = tbProperty[k]
        if type(tempValue) == "boolean" then
            tbData.nValue = tempValue and 1 or 0
        else
            tbData.nValue = tempValue
        end
        table.insert( self.tbDataList, tbData )
    end
    table.sort( self.tbDataList, function (a, b) return a.szProperty < b.szProperty end)
    self.ListHelper:SetData(self.tbDataList)
end

function UPDebugHumanWeaponPanel:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnCommit.OnClicked, self, OnCommitClicked)
end


return UPDebugHumanWeaponPanel