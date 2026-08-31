-----------------------------------------------------
--File Name    : PropValueGMHelper.lua
--Author       : Song Fuhao
--Create Time  : 2019-05-16
--Description  : 这个文件是专门用来服务GM指令里查询服务器数值用的，不要用在非GM环境
-----------------------------------------------------
local PropValueGMHelper = {}

-- require文件直接在函数内req，此处指req此helper最小运行条件的引用
local EventManager = require("EventManager")
local DungeonCommonProtoNames = require("DungeonCommonProtoNames")
local GMSearchablePropDataTable = require("GMSearchablePropDataTable")
local NetworkManager = dynamic_require("NetworkManager")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")
local PropName = require("PropName")

local FN_PROP_VALUE_SEARCHER_MAP = nil

local function DEBUG_LOG(...)
    log(...)
end

local function GetDeviceModel()
	local szDeviceModel = RenderExtendBlueprintFunctions.GetDeviceModel()
	local StringUtil = require("StringUtil")
	if StringUtil.IsEmptyString(szDeviceModel) then
		szDeviceModel = "Unknown"
	end
    szDeviceModel = string.format("DeviceModel : \"%s\"", szDeviceModel)
    return szDeviceModel
end

local function GetShipActiveWeaponItem(tbCharacter)
    if tbCharacter:IsShip() then
        local ActiveWeaponItem = BattleShipWeaponSystem:GetActiveWeaponItem(tbCharacter)
        if ActiveWeaponItem then
            -- 获取前刷新一下ShotBaseInfo数据
            ActiveWeaponItem:UpdateShotBaseInfo()
            return ActiveWeaponItem
        else
            return nil, "需要先激活船武器"
        end
    else
        return nil, "需要先切换至船形态"
    end
end

local function GetShipWeaponLeakingProp(tbCharacter)
    local BaseUtil = require("BaseUtil")
    local ActiveWeaponItem, szFailedReason = GetShipActiveWeaponItem(tbCharacter)
    if ActiveWeaponItem then
        local tbWeaponTemplate = ActiveWeaponItem:GetTemplate()
        local nLeakingProb = tbWeaponTemplate.nLeakingProb
        nLeakingProb = nLeakingProb + (tbCharacter.ShipBattlePropertyComponent:GetProp(PropName.nLeakingProb) - 1)
        local tbLeakingProbInfo = tbCharacter.ShipBattlePropertyComponent:GetProp(PropName.tbLeakingProbInfo)
        if tbLeakingProbInfo then
            if BaseUtil:ContainsByValue(tbLeakingProbInfo.tbWeaponTypes, ActiveWeaponItem:GetTemplateType())
            or BaseUtil:ContainsByValue(tbLeakingProbInfo.tbWeaponIds, ActiveWeaponItem:GetInstanceId()) then
                nLeakingProb = nLeakingProb + tbLeakingProbInfo.nValue
            end
        end
        return nLeakingProb
    else
        return szFailedReason
    end
end

local function GetShipWeaponAttack(tbCharacter)
    local ActiveWeaponItem, szFailedReason = GetShipActiveWeaponItem(tbCharacter)
    if ActiveWeaponItem then
        local tbWeaponTemplate = ActiveWeaponItem:GetTemplate()
        local nBaseAttack = tbWeaponTemplate.nBaseDamage
        local nTemplateType = ActiveWeaponItem:GetTemplateType()
        return BattleShipWeaponSystem:GetWeaponAttack(tbCharacter, nTemplateType, nBaseAttack)
    else
        return szFailedReason
    end
end

local function GetShipWeaponTriggerRange(tbCharacter)
    local ShipUtilityExHelper = require("ShipUtilityExHelper")
    local ActiveWeaponItem, szFailedReason = GetShipActiveWeaponItem(tbCharacter)
    if ActiveWeaponItem then
        local pComponent = ActiveWeaponItem:GetBPComponent()
        return ShipUtilityExHelper.GetTriggerRangeFromShotBaseInfo(pComponent.ShotBaseInfo, GWorld)
    else
        return szFailedReason
    end
end

local function GetShipWeaponFiringInterval(tbCharacter)
    local ActiveWeaponItem, szFailedReason = GetShipActiveWeaponItem(tbCharacter)
    if ActiveWeaponItem then
        return ActiveWeaponItem:GetFiringInterval()
    else
        return szFailedReason
    end
end

local function GetShipAngularMaxSpeed(tbCharacter)
    if tbCharacter:IsShip() then
        return tbCharacter.pUEActor.ShipMovementComponent:GetCurrentMaxAngularSpeed()
    else
        return "需要先切换至船形态"
    end
end

local function GetHumanListenRange(tbCharacter)
    return tbCharacter.HumanBattlePropertyComponent.GetHumanListenRange()
end

local function GetHp(tbCharacter)
    return tbCharacter:GetCurrentPropertyComponent():GetHp()
end

local function GetDyingHpReduceSpeed(tbCharacter)
    if tbCharacter:IsDying() then
        return tbCharacter.BattleDyingComponent.nDyingHpReduceSpeed
    else
        return "需要先进入重伤模式"
    end
end

local function GetHumanSpeed(tbCharacter)
    if tbCharacter:IsHuman() then
        return tbCharacter.pUEActor.CharacterMovement.MaxWalkSpeed
    else
        return "需要先切换至人形态"
    end
end

--------------------------------------------------------------
-- 将查询结果发送到客户端
local function SendToClient(tbSearcher, tbCharacter, szKey, szData)
    local d2c_SearchPropDataForGM = {
        character_instance_id = tbCharacter:GetServerInstanceId(),
        key = szKey,
        data = szData,
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbSearcher:GetUEControllerUniqueId(), DungeonCommonProtoNames.d2c_SearchPropDataForGM, d2c_SearchPropDataForGM)
end

-- 查询接口的内部实现
local function SearchInternal(szKey, tbCharacter, tbSearcher, bServerEnv)
    local fnPropDataSearcher = FN_PROP_VALUE_SEARCHER_MAP[string.lower(szKey)]
    local varData = fnPropDataSearcher and fnPropDataSearcher(tbCharacter)
    local szData = tostring(varData)

    DEBUG_LOG("SearchInternal", bServerEnv, szKey, szData, fnPropDataSearcher)

    if bServerEnv then
        SendToClient(tbSearcher, tbCharacter, szKey, szData)
    else
        PropValueGMHelper.HandleSearchResult(szKey, szData)
    end
end

-- 前往查询服务器数据
local function SearchServerData(tbCharacter, szKey)
    local c2d_SearchPropDataForGM = {
        character_instance_id = tbCharacter:GetServerInstanceId(),
        key = szKey
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(DungeonCommonProtoNames.c2d_SearchPropDataForGM, c2d_SearchPropDataForGM)
end

-- 处理查询结果
-- @szKey       查询的Key
-- @szData      查询的结果
function PropValueGMHelper.HandleSearchResult(szKey, szData)
    log("[SearchPropForGM]", szKey, szData)
    if GlobalVariableSystem:IsClient() then
        local ClientEventDef = require("ClientEventDef")
        EventManager:OnFireEvent(ClientEventDef.EV_SEND_PROP_DATA_FOR_GM, szKey, szData)
    end
end

-- 数值查询接口
-- @szKey       数值Key，GMSearchablePropDataTable中配置
-- @tbCharacter 查询哪个角色身上的数据
-- @tbSearcher  搜索者，查询的结果最后发给谁（只有服务器生效）
function PropValueGMHelper.Search(szKey, tbCharacter, tbSearcher)
    DEBUG_LOG("PropValueGMHelper.Search 1", szKey)
    if not tbCharacter then
        if GlobalVariableSystem:IsClient() then
            DEBUG_LOG("PropValueGMHelper.Search 2")
            -- 未传Character时，客户端默认查自己
            local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
            tbCharacter = GamePlayerSelfHelper:Get()
        else
            return
        end
    end

    DEBUG_LOG("PropValueGMHelper.Search 3")
    local tbTemplate = GMSearchablePropDataTable:GetTemplate(szKey)
    if not tbTemplate then
        return
    end

    if GlobalVariableSystem:IsServerLogic() then
        DEBUG_LOG("PropValueGMHelper.Search 4")
        if tbSearcher then
            -- 当前为服务器环境时，如果没有Searcher时，不进行查询，因为数据没有人接收
            SearchInternal(szKey, tbCharacter, tbSearcher, true)
        end
    else
        DEBUG_LOG("PropValueGMHelper.Search 5", tbTemplate.bDataFromServer)
        if tbTemplate.bDungeonProp and (not GlobalVariableSystem:IsInDungeon()) then
            PropValueGMHelper.HandleSearchResult(szKey, "进入副本才能查询此数值")
            return
        end
        if tbTemplate.bDataFromServer then
            DEBUG_LOG("PropValueGMHelper.Search 6")
            -- 如果当前是客户端环境，但是数据配置为服务器查询，则c2d前往服务器查询数据
            SearchServerData(tbCharacter, szKey)
        else
            DEBUG_LOG("PropValueGMHelper.Search 7")
            -- 如果当前是客户端环境，数据为客户端查询，直接查询
            SearchInternal(szKey, tbCharacter, tbSearcher, false)
        end
    end
end
--------------------------------------------------------------

-- 直接这样静态的初始化，不写Init了，因为希望这个文件随调随用，作为一个Helper，而不是一个System
FN_PROP_VALUE_SEARCHER_MAP = {
    ["device_model"]                = GetDeviceModel,                   -- 当前船武器漏水率
    ["ship_weapon_leaking_prop"]    = GetShipWeaponLeakingProp,         -- 当前船武器漏水率
    ["ship_weapon_attack"]          = GetShipWeaponAttack,              -- 当前船武器攻击
    ["ship_weapon_trigger_range"]   = GetShipWeaponTriggerRange,        -- 船武器炮弹的碰撞半径
    ["ship_weapon_firing_interval"] = GetShipWeaponFiringInterval,      -- 武器的攻击间隔
    ["ship_angular_max_speed"]      = GetShipAngularMaxSpeed,           -- 舰船转向速度
    ["human_listen_range"]          = GetHumanListenRange,              -- 人听觉范围
    ["hp_client"]                   = GetHp,                            -- 当前形态客户端血量
    ["hp_server"]                   = GetHp,                            -- 当前形态服务器血量
    ["dying_hp_reduce_speed"]       = GetDyingHpReduceSpeed,            -- 当前形态服务器重伤掉血速度
    ["human_speed"]                 = GetHumanSpeed,                    -- 当前形态服务器重伤掉血速度
}

return PropValueGMHelper
