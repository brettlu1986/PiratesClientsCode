local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local BattleCampComponent = luaclass("BattleCampComponent", GameComponentBaseClass)

local CampDef = require("CampDefine")
local ProtoDC = require("DungeonCommonProtoNames")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local NetworkManager = dynamic_require("NetworkManager")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local SessionSystem = require("SessionSystem")

-- 阵营类型 CampDefine.Type
BattleCampComponent.CampType = CampDef.Type.CAMP_NONE

local function RefreshBPCampType(self)
    local pUEActor = self.Owner.pUEActor
    if pUEActor and pUEActor.ShipStatusComponent then
        pUEActor.ShipStatusComponent:SetCampType(self.CampType)
    end
end

function BattleCampComponent:SetCampType(NewCampType)
    if(NewCampType == nil or self.CampType == NewCampType) then
        return
    end

    self.CampType = NewCampType
    RefreshBPCampType(self)
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_CAMP_TYPE_CHANGED, self.Owner, NewCampType)

    if GlobalVariableSystem:IsServerLogic() then
        NetworkManager:GetRPCNetworkProxy():Multicast(ProtoDC.d2c_CampTypeChanged, {instance_id = self.Owner:GetServerInstanceId(), camp_type = NewCampType})
    end
end

-- GameComponentDataParser:ParseNpcGameModeData
-- tbData["BattleCampComponent"] = { Camp = tbJsonData.CampType }
function BattleCampComponent:OnCreate(Owner, tbParams)
    BattleCampComponent.super.OnCreate(self, Owner, tbParams)
    if tbParams == nil then
        return false
    end
    self.CampType = tbParams.CampType
    return true
end

function BattleCampComponent:GetCampType()
    return self.CampType
end

local function GetSessionData(self)
    local Session
    local SessoinType = SessionSystem.Type
    Session = SessionSystem:GetAlivedSession(SessoinType.ChangeToShip) or
        SessionSystem:GetAlivedSession(SessoinType.ChangeToHuman)
    return Session and Session:GetData() or nil
end

function BattleCampComponent:OnActorCreated(pUEActor)
    BattleCampComponent.super.OnActorCreated(self, pUEActor)

    local tbSessionData = GetSessionData(self)
    if(tbSessionData and tbSessionData.nCampType ~= nil) then
        self:SetCampType(tbSessionData.nCampType)
    else
        RefreshBPCampType(self)
    end
end

function BattleCampComponent:OnActorDestroyed(pUEActor)
    local tbSessionData = GetSessionData(self)
    if(tbSessionData) then
        tbSessionData.nCampType = self.CampType
    end

    BattleCampComponent.super.OnActorDestroyed(self, pUEActor)
end


return BattleCampComponent
