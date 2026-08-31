-----------------------------------------------------
--File Name    : ShipDropInfoComponent.lua
--Author       : Song Fuhao
--Create Time  : 2017-03-02
--Description  : 角色冒血数字等UI掉落信息管理
-----------------------------------------------------

local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local ShipDropInfoComponent = luaclass("ShipDropInfoComponent", GameComponentBase)

local SelfEventHelperClass = require("SelfEventHelper")
local SelfTimerHelperClass = require("SelfTimerHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ClientEventDef = require("ClientEventDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local DamageLevelTypeDef = require("DamageLevelTypeDef")
local MathUtil = require("MathUtil")
local DungeonIni = require("DungeonIni")
local EventManager = require("EventManager")

local function ConvertDamageToLevelType(self, nDamage)
    nDamage = KismetMathLibrary.Round(nDamage)
    local tbOwner = self:GetOwner()
    if tbOwner and nDamage >= 0 then
        local BattleShipPropertyComponent = tbOwner.BattleShipPropertyComponent
        if BattleShipPropertyComponent then
            local nMaxHp = BattleShipPropertyComponent:GetMaxHP()
            if nMaxHp > 0 then
                local nDamageHpPercent = math.floor(nDamage * 100 / nMaxHp)
                nDamageHpPercent = MathUtil.Clamp(nDamageHpPercent, 0, 100)
                local DamageToLevelType = DungeonIni.tbUIConfig.tbDamageToLevelType
                for i,v in ipairs(DamageToLevelType) do
                    if nDamageHpPercent <= v then
                        return i
                    end
                end
            end
           
        end
    end
    return DamageLevelTypeDef.DLT_Slight
end

local DropChannelType = {
    DCT_Damage  = 1,
    DCT_Cure    = 2,
    DCT_Fire    = 3,
    DCT_Leak    = 4,
}

ShipDropInfoComponent.EventHelper = nil
ShipDropInfoComponent.TimerHelper = nil
ShipDropInfoComponent.tShowInvalidAttackbDelayTimer = nil
ShipDropInfoComponent.tbDropChannels = { }

local function GetChannelValue( self, nChannelType )
    local tbChannel = self.tbDropChannels[nChannelType]
    if tbChannel then
        return tbChannel.nValue
    end
    return 0
end

local function ChannelEevntEnd( self, nChannelType)
    local tbChannel = self.tbDropChannels[nChannelType]
    local nValue = tbChannel.nValue
    local tbExtParams = tbChannel.tbExtParams
    local tbWnd = UIManager:GetWnd(UIDef.UI_BATTLE_MAIN)
    if tbWnd and tbWnd.tbBattleDropInfo then
        if nChannelType == DropChannelType.DCT_Damage then
            tbWnd.tbBattleDropInfo:ShowDamageDrop(self.Owner, nValue, tbExtParams)
        elseif nChannelType == DropChannelType.DCT_Cure then
            tbWnd.tbBattleDropInfo:ShowCureDrop(self.Owner, nValue)
        elseif nChannelType == DropChannelType.DCT_Fire then
            tbWnd.tbBattleDropInfo:ShowFireDrop(self.Owner, nValue, tbExtParams)
        elseif nChannelType == DropChannelType.DCT_Leak then
            tbWnd.tbBattleDropInfo:ShowLeakDrop(self.Owner, nValue, tbExtParams)
        end
    end
end 
local function AddChannelEvent( self, nChannelType, nVaule, tbExtParams)
    if nVaule <= 0 then
        return
    end
    local tbChannel = self.tbDropChannels[nChannelType]
    if not tbChannel and nChannelType > 0 then
        tbChannel = { }
        self.tbDropChannels[nChannelType] = tbChannel
        tbChannel.nValue = 0
    end
    tbChannel.nValue = tbChannel.nValue + KismetMathLibrary.Round(nVaule)
    tbChannel.tbExtParams = tbExtParams
    if not tbChannel.tShowDelayTimer then
        local function OnChannelDelayEnd(_) 
            ChannelEevntEnd(self, nChannelType)
            local tbEndChannel = self.tbDropChannels[nChannelType]
            tbEndChannel.tShowDelayTimer = nil
            tbEndChannel.nValue = 0
            tbEndChannel.tbExtParams = { }
        end
        tbChannel.tShowDelayTimer = self.TimerHelper:NewTimerMethod(self, OnChannelDelayEnd, DungeonIni.tbUIConfig.nDropInfoDelay)
    end
end


local function OnShowInvalidAttackDelayEnd( self )
    local tbWnd = UIManager:GetWnd(UIDef.UI_BATTLE_MAIN)
    if tbWnd and tbWnd.tbBattleDropInfo then
        tbWnd.tbBattleDropInfo:ShowInvalidAttack(self.Owner)
    end
    self.tShowInvalidAttackbDelayTimer = nil
end

local function ShowDamage( self, nDamage, bCauser, nDamageType, pTakerShip )
    if nDamage <= 0 then
        return
    end
    local nChannelType = -1
    if nDamageType == Enum_DamageType.Fire then
        nChannelType = DropChannelType.DCT_Fire
    elseif nDamageType == Enum_DamageType.Leak then
        nChannelType = DropChannelType.DCT_Leak
    else
        nChannelType = DropChannelType.DCT_Damage
    end
    if nChannelType > 0 then
        local tbDamageStyleParams = { }
        local nPreValue = GetChannelValue(self, nChannelType)
        tbDamageStyleParams.nDamageLevelType = ConvertDamageToLevelType(self, nPreValue + nDamage)
        tbDamageStyleParams.bDamageCauser = bCauser
        tbDamageStyleParams.nDamageType = nDamageType
        tbDamageStyleParams.pTakerShip = pTakerShip
        if bCauser then
            EventManager:OnFireEvent(ClientEventDef.PLAYER_CUASED_DAMAGE_WITH_LEVEL, tbDamageStyleParams.nDamageLevelType, nDamage)
        end
        AddChannelEvent(self, nChannelType, nDamage, tbDamageStyleParams)
    end
end

local function ShowCure( self, nCure )
    AddChannelEvent(self, DropChannelType.DCT_Cure, nCure)
end

local function ShowBroken( self, nDamageType )
    local tbWnd = UIManager:GetWnd(UIDef.UI_BATTLE_MAIN)
    if tbWnd and tbWnd.tbBattleDropInfo then
        tbWnd.tbBattleDropInfo:ShowBrokenDrop(self.Owner, nDamageType)
    end
end

local function ShowInvalidAttack( self )
    if not self.tShowInvalidAttackbDelayTimer then
        self.tShowInvalidAttackbDelayTimer = self.TimerHelper:NewTimerMethod(self, OnShowInvalidAttackDelayEnd, DungeonIni.tbUIConfig.nDropInfoDelay)
    end
end

local function OnCausedInvalidAttack( self, pTakerShip )
    if EngineExtActorShell.GetActorUniqueId(pTakerShip) == self.Owner.nUniqueId then
        ShowInvalidAttack(self)
    end
end

local function OnCausedDamage( self, pTakerShip, nDamage, nDamageType )
    if EngineExtActorShell.GetActorUniqueId(pTakerShip) == self.Owner.nUniqueId then
        ShowDamage(self, nDamage, true, nDamageType, pTakerShip)
    end
end

local function OnCausedBroken( self, pTakerShip, nDamageType )
    if EngineExtActorShell.GetActorUniqueId(pTakerShip) == self.Owner.nUniqueId then
        ShowBroken(self, nDamageType)
    end
end

local function OnTookInvalidAttack( self, pCauserShip )
    ShowInvalidAttack(self)
end

local function OnTookDamage( self, pCauserShip, nDamage, nDamageType )
    ShowDamage(self, nDamage, false, nDamageType, self.Owner.pUEActor)
end

local function OnTookCure( self, pCauserShip, nCure )
    ShowCure(self, nCure)
end

local function OnTookBroken( self, pCauserShip, nDamageType )
    ShowBroken(self, nDamageType)
end

function ShipDropInfoComponent:OnActorCreated(pUEActor)
    ShipDropInfoComponent.super.OnActorCreated(self, pUEActor)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    
    self.EventHelper = SelfEventHelperClass()
    self.TimerHelper = SelfTimerHelperClass()

    if self.Owner == PlayerSelf then
        self.EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_SELF_TOOK_INVALID_ATTACK, self, OnTookInvalidAttack)
        self.EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_SELF_TOOK_DAMAGE, self, OnTookDamage)
        self.EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_SELF_TOOK_BROKEN, self, OnTookBroken)
        self.EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_SELF_TOOK_CURE, self, OnTookCure)
    else
        self.EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_SELF_CAUSED_INVALID_ATTACK, self, OnCausedInvalidAttack)
        self.EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_SELF_CAUSED_DAMAGE, self, OnCausedDamage)
        self.EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_SELF_CAUSED_BROKEN, self, OnCausedBroken)
    end
end

function ShipDropInfoComponent:OnActorDestroyed(pUEActor)
    if self.EventHelper then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end
    if self.TimerHelper then
        self.TimerHelper:ClearAllTimer()
        self.TimerHelper = nil
    end
    ShipDropInfoComponent.super.OnActorDestroyed(self, pUEActor)
end

return ShipDropInfoComponent
