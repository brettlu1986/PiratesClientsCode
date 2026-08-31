local luaclass = require("luaclass")
local WatchBattleSystem = luaclass("WatchBattleSystem")
local SelfEventHelper = require("SelfEventHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local Proto = require("DungeonCommonProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local HumanWeaponMisc = require("HumanWeaponMisc")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local CommonEventDef = require("CommonEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleTeamSystem = require("BattleTeamSystem")
local HumanWeaponDef = require("HumanWeaponDef")
local PlayerStatsHelper = require("PlayerStatsHelper")
local BattleTeamCategoryDefine = require("BattleTeamCategoryDefine")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local TeamWatchServerHelper = require("TeamWatchServerHelper")
local ShipWeaponTemplateDef = require("ShipWeaponTemplateDef")
local ShipFiringOperationDef = require("ShipFiringOperationDef")
local BotAISystem  = dynamic_require("BotAISystem")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

WatchBattleSystem.EventHelper = nil
WatchBattleSystem.tbCurrentWatchMembers = nil

local HumanWeaponType = HumanWeaponMisc.Type
local ECategoryType = BattleTeamCategoryDefine.tbCategoryType

local function GatherWatchMateInfo(tbMate, bCanChange)
    local tbInfo = {
        weapon_tempId = 0,
        bullet_count = 0,
        bullet_max = 0,
        ship_weapon_slot = 0,
        kill_count = 0,
        is_ship = false, 
        is_ship_aim = false,
    }

    if bCanChange then
        tbInfo.kill_count = PlayerStatsHelper:GetKillCountByPlayerId(tbMate:GetPlayerId())

        local bInfiniteBullet = false
        --用于下发到客户端，在客户端用于判断 人船状态，防止服务器和客户端人船切换的时候，状态不一致时ui表现不对的问题
        tbInfo.is_ship = not tbMate:IsHuman()
        if tbMate:IsHuman() then
            local WeaponComponent = tbMate.HumanWeaponComponent
            local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon(true)
            tbInfo.weapon_tempId = WeaponComponent:GetCurrentWeaponTemplateId()
            if tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponType.GUN) then
                local Item = BattleItemSystemHelper:GetItem(tbCurrentWeapon.nInstanceId, false)
                bInfiniteBullet = Item:IsBulletInfinite()
                tbInfo.bullet_count = Item:GetCurrentAmmoCount(false)
                tbInfo.bullet_max = bInfiniteBullet and Item.tbProperty[HumanWeaponDef.Property.BulletMax] or Item:GetUnequipedMatchingAmmoCount(false)
            elseif tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponType.THROW) then
                tbInfo.bullet_count = BattleItemSystemHelper:GetUnequippedItemCount(tbMate:GetServerInstanceId(),
                    tbCurrentWeapon:GetTemplateId(),false)
                tbInfo.bullet_max = tbInfo.bullet_count
            end
        else
            local bIsInAim = BattleShipWeaponSystem:GetIsInAim(tbMate)
            tbInfo.is_ship_aim  = bIsInAim
            local tbCurrentWeaponItem = BattleShipWeaponSystem:GetActiveWeaponItem(tbMate)
            if tbCurrentWeaponItem then
                local nTemplateId = tbCurrentWeaponItem:GetTemplateId()
                tbInfo.ship_weapon_slot = tbCurrentWeaponItem:GetWeaponSlot()
                tbInfo.weapon_tempId = nTemplateId

                if tbCurrentWeaponItem:GetCategory() == BattleItemCategoryDef.SHIP_THROWN_ITEM then
                    tbInfo.bullet_count = BattleItemSystemHelper:GetUnequippedItemCount(tbMate:GetServerInstanceId(), nTemplateId, false)
                    tbInfo.bullet_max = tbInfo.bullet_count
                else
                    local nBulletItemTemplateId = tbCurrentWeaponItem:GetBulletItemTemplateId()
                    if nBulletItemTemplateId then
                        tbInfo.bullet_count = tbCurrentWeaponItem:GetBulletLoadedCount(false)
                        tbInfo.bullet_max = tbCurrentWeaponItem:IsInfiniteBullet() and tbCurrentWeaponItem:GetBulletMaxLoadingCount() or tbCurrentWeaponItem:GetBulletUnloadedCount(false)
                    end
                end
            end
        end
    end
    return tbInfo
end

local function GetOtherRandomInPlayer(tbPlayers, nExcludeId) 
    for _, tbGameObject in pairs(tbPlayers) do
        if tbGameObject and tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf and not tbGameObject:IsDead() and  
        nExcludeId ~= tbGameObject:GetServerInstanceId() and not BotAISystem:IsBot(tbGameObject) then
            return tbGameObject
        end
    end
    return nil
end

local function GetOtherRandomInBot(tbPlayers, nExcludeId)
    for _, tbGameObject in pairs(tbPlayers) do
        if tbGameObject and tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf and
            not tbGameObject:IsDead() and BotAISystem:IsBot(tbGameObject) then
            return tbGameObject
        end
    end
    return nil
end

--观战其他人 帮玩家找一个
local function GetOtherValidWatchTarget(nExcludeId)
    local tbGameObjects = GameObjectSystem:GetAllGameObjects()
    local tbOtherWatchPlayer =  GetOtherRandomInPlayer(tbGameObjects, nExcludeId)
    if (tbOtherWatchPlayer == nil) then
        tbOtherWatchPlayer = GetOtherRandomInBot(tbGameObjects, nExcludeId)
    end
    return tbOtherWatchPlayer
end

function WatchBattleSystem:ChangeTeammateView(nPreMateId, nNewMateId, nSenderUniqueId, bOtherTeam)

    local tbPreMate = GameObjectSystem:FindByInstanceId(nPreMateId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    local WatchBattleComponent = nil

    log("[server watch] ChangeTeammateView ::", nPreMateId, nNewMateId, nSenderUniqueId)
    if tbPreMate then
        if tbPreMate:IsShip() then
            tbPreMate.pUEActor.ShipMovementComponent:DecreaseViewers()
        end
        WatchBattleComponent = tbPreMate.WatchBattleComponent
        if WatchBattleComponent then
            WatchBattleComponent:RemoveViewerId(tbPlayer:GetServerInstanceId())
        end
        if tbPlayer and tbPlayer.WatchBattleComponent then
            tbPlayer.WatchBattleComponent.nCurrentViewId = -1
        end
    end

    local tbMate = nil   
    --当前尝试观战其他人，-1的情况是其他人可能已经死亡，或者是在玩家非被击杀死亡，比如溺水，自杀等情况的时候
    if nNewMateId == -1 then  
        tbMate = GetOtherValidWatchTarget(nPreMateId)
    else   
        tbMate = GameObjectSystem:FindByInstanceId(nNewMateId)
        local bNpc = tbMate and tbMate:GetObjectType() == GameObjectTypeDef.Npc
        local bDead = tbMate and tbMate:IsDead()
        local bNil = tbMate == nil
        local bOtherNotValid = bNil or bDead or bNpc
        if bOtherTeam and bOtherNotValid then  
            tbMate = GetOtherValidWatchTarget(nPreMateId)
        end
    end

    local nOffsetYaw = 0
    local bCanChange = true
    if not tbMate or tbMate:IsDead() then
        bCanChange = false
    end

    local nVehicleId = -1
    local nTeamId = -1
    if bCanChange then
        --以要被观战的那个人的teamid为主
        nNewMateId = tbMate.nServerInstanceId
        nTeamId = tbMate.BattleTeamComponent.nTeamId

        --设置其他的Team 要给即将观战该队的人 Rep
        if bOtherTeam then
            WatchBattleComponent = tbPlayer.WatchBattleComponent
            local tbTeamData = BattleTeamSystem:GetDataByTeamId(nTeamId)
            WatchBattleComponent:Reset()
            log("[server watch] try to watch other team ::", nTeamId)
            WatchBattleComponent:SetWatchTeamData(tbTeamData)
            WatchBattleComponent:OnDataChanged(ECategoryType.All)
        end
        
        local pSelfController = tbPlayer.pUEActor:GetController()
        local bPlayerController = pSelfController:IsPlayerController()

        local pOtherUEActor = nil
        if tbMate:IsHuman() then
            local bInVehicle = tbMate.HumanMovementStateComponent:IsInVehicle()
            local pAttachParent = tbMate.pUEActor:GetAttachParentActor()
            if bInVehicle and pAttachParent and bPlayerController then
                nVehicleId = tbMate.HumanMovementStateComponent:GetVehicleInstanceId()
                pOtherUEActor = pAttachParent
                PiratesReplicationBPHelpers.SetActorReplicateToController(pSelfController, tbMate.pUEActor, true)
            else
                pOtherUEActor = tbMate.pUEActor
            end
        else
            pOtherUEActor = tbMate.pUEActor
        end

        if tbPreMate and tbPreMate.pUEActor and bPlayerController then
            PiratesReplicationBPHelpers.SetActorReplicateToController(pSelfController, tbPreMate.pUEActor, false)
        end

        if pSelfController and pOtherUEActor and bPlayerController then
            PiratesReplicationBPHelpers.SetActorReplicateToController(pSelfController, pOtherUEActor, true)
        end

        if tbMate and tbMate:IsShip() then
            --船在初始化的时候因为保持相机和船朝向一致，所以设置了ControlRotation和ActorRotation一直，摇臂默认Yaw是0，
            --因此在观战同步的时候 直接通过ControlRotation来设置摇臂的话会有初始化的 偏移量的偏差
            --还需要考虑 船ActorRotation 相对 ContorlRotation的转向偏差
            tbMate.pUEActor.ShipMovementComponent:IncreaseViewers()
            local ShipRotation = tbMate.pUEActor:K2_GetActorRotation()
            nOffsetYaw = -ShipRotation.Yaw
        end

        WatchBattleComponent = tbMate.WatchBattleComponent
        local nPlayerInsId = tbPlayer:GetServerInstanceId()
        if WatchBattleComponent then
            WatchBattleComponent:AddViewerId(nPlayerInsId)
        end
        self.tbCurrentWatchMembers[nPlayerInsId] = true  
        self.EventHelper:FireEvent(CommonEventDef.EV_MEMBER_ENTER_WATCH, self:GetCurrentWatchCount(), nPlayerInsId)
        
        tbPlayer.WatchBattleComponent.nCurrentViewId = nNewMateId
    end

    local tbInfo = GatherWatchMateInfo(tbMate, bCanChange)
    log("[ServerWatch] watch battle now target id is::", nNewMateId, bCanChange)
    local tbPacket = {
        watch_mate_id = nNewMateId,
        watch_vehicle_id = nVehicleId,
        offsetYaw = nOffsetYaw,
        info = tbInfo,
        watch_team_id = nTeamId,
        is_success = bCanChange,
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(nSenderUniqueId, Proto.d2c_NotifyWatchTeamMate, tbPacket)

    return bCanChange, nNewMateId
end

function WatchBattleSystem:StopTeammateView(nMateInsId, nStopType, nSenderUniqueId)
    if nMateInsId > 0 then
        --停止观战 就不发了 这块需要处理一下
        local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
        local tbWatchMate = GameObjectSystem:FindByInstanceId(nMateInsId)
        if tbWatchMate and tbPlayer then
            local WatchBattleComponent = tbWatchMate.WatchBattleComponent
            if WatchBattleComponent then
                WatchBattleComponent:RemoveViewerId(tbPlayer:GetServerInstanceId())
            end
        end
        self.tbCurrentWatchMembers[nMateInsId] = false  
        self.EventHelper:FireEvent(CommonEventDef.EV_MEMBER_LEAVE_WATCH, self:GetCurrentWatchCount(), nMateInsId)
    end
end

local function PlayerLoginOut(self, tbGamePlayer)
    local WatchBattleComponent = tbGamePlayer.WatchBattleComponent
    if WatchBattleComponent then   
        local nCurrentViewId = WatchBattleComponent.nCurrentViewId
        if nCurrentViewId > 0 then
            local tbWatchMate = GameObjectSystem:FindByInstanceId(nCurrentViewId)
            if tbWatchMate and tbWatchMate.WatchBattleComponent then
                local WatchMateBattleComponent = tbWatchMate.WatchBattleComponent
                WatchMateBattleComponent:RemoveViewerId(tbGamePlayer:GetServerInstanceId())
            end
        end
    end
end

local function OnShipWeaponFiringOperationChanged(self, tbCharacter, WeaponItem, nFiringOperation)
    if WeaponItem:GetTemplateType() ~= ShipWeaponTemplateDef.CARRONADE then
        return
    end
    TeamWatchServerHelper.NotifyViewersCarronadeCameraActiveChanged(tbCharacter, nFiringOperation == ShipFiringOperationDef.START)
end

function WatchBattleSystem:GetCurrentWatchCount()  
    local nCount = 0
    for _, v in pairs(self.tbCurrentWatchMembers) do
        if v == true then   
            nCount = nCount + 1
        end
    end
    return nCount
end

--加子弹 加投掷物
-- local function OnItemRemoved(self, nInstanceId)
-- end

-- --从背包扔掉子弹袋或者扔掉武器
-- local function OnItemAdded(self, NewItem)
-- end

local function OnPawnDead(self, tbGameObject)
    local bServer = GlobalVariableSystem:IsServerLogic()
    if tbGameObject and tbGameObject.pUEActor and bServer and tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf then
        local WatchBattleComponent = tbGameObject.WatchBattleComponent
        if WatchBattleComponent and WatchBattleComponent:HasViewers() then  
            local tbViewers = WatchBattleComponent:GetViewers()
            for _, v in pairs(tbViewers) do   
                local tbPlayer = GameObjectSystem:FindByInstanceId(v)
                local bNotBot = not BotAISystem:IsBot(tbPlayer)
                if tbPlayer and tbPlayer.pUEActor and bNotBot then
                    local pController = tbPlayer.pUEActor:GetController()
                    PiratesReplicationBPHelpers.SetActorReplicateToController(pController, tbGameObject.pUEActor, false)
                end
            end
        end
    end
end



function WatchBattleSystem:Init()
    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper
    self.tbCurrentWatchMembers = {}
    -- EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_ADD_SERVER, self, OnItemAdded)
    -- EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_REMOVE_SERVER, self, OnItemRemoved)
    -- EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, OnActorDestroy)

    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_PRE_DEAD, self, OnPawnDead)
    EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, PlayerLoginOut)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_WEAPON_FIRING_OPERATION_CHANGED_SERVER, self, OnShipWeaponFiringOperationChanged)
end

function WatchBattleSystem:Uninit()
    self.EventHelper:UnregisterAll()
    self.tbCurrentWatchMembers = nil
end

return WatchBattleSystem()