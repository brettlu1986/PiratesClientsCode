-- 玩家自己
local luaclass = require("luaclass")
local GamePlayerClass = dynamic_require("GamePlayer")
local GamePlayerSelf = luaclass("GamePlayerSelf", GamePlayerClass)

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local GameComponentCreateHelper = require("GameComponentCreateHelper")
local GameComponentTypeDefine = require("GameComponentTypeDefine")
local UEActorHelper = require("UEActorHelper")
local TemplateTypeDef = require("TemplateTypeDef")
local AIHelper = require("AIHelper")

GamePlayerSelf.bIsSpectator = false
GamePlayerSelf.pUEController = nil
GamePlayerSelf.nUEControllerNetGuid = nil
GamePlayerSelf.nUEControllerUniqueId = 0
GamePlayerSelf.tbControllerInitProtoData = nil

function GamePlayerSelf:BindUEController(pUEController, nUEControllerNetGuid, nUEControllerUniqueId, tbInitProtoData)
    log("GamePlayerSelf:BindUEController ", self.nPlayerId)
    self.nUEControllerNetGuid = nUEControllerNetGuid
    self.pUEController = pUEController
    self.nUEControllerUniqueId = nUEControllerUniqueId
    self.tbControllerInitProtoData = tbInitProtoData

    GameComponentCreateHelper:Create(self,
        self:ConvertToComponentParams(GameComponentTypeDefine.tbLifeCycleType.WithUEController))
end

function GamePlayerSelf:UnbindUEController()
    log("GamePlayerSelf:UnbindUEController ", self.nPlayerId)
    self.pUEController = nil
    self.nUEControllerNetGuid = nil
    self.nUEControllerUniqueId = 0
    GameComponentCreateHelper:Destroy(self,
        self:ConvertToComponentParams(GameComponentTypeDefine.tbLifeCycleType.WithUEController))
end

-- 创建
function GamePlayerSelf:OnCreate()
    GamePlayerSelf.super.OnCreate(self)
    return true
end

function GamePlayerSelf:RestoreUEActor(tbCreateData, tbCustomData)
    return GamePlayerSelf.super.RestoreUEActor(self, tbCreateData, tbCustomData)
end

function GamePlayerSelf:OnActorCreated(pUEActor)
    GamePlayerSelf.super.OnActorCreated(self, pUEActor)
    if not self:IsShip() then
        if GlobalVariableSystem:IsServerLogic() then
            if AIHelper.IsAIControlled(self) then
                self.Location = ExtendBlueprintFunctions.GetAISafePosition(GWorld, self.Location, 0, 10000, -50000)
                local pRelativeLocation = pUEActor.Mesh.RelativeLocation
                local pLocation = self.Location
                EngineExtActorShell.SetActorLocation(pUEActor, Vector{X=pLocation.X, Y=pLocation.Y, Z=pLocation.Z - pRelativeLocation.Z})
            else
                local nZ = EngineExtActorShell.GetLocationZOnFloor(GWorld, self.Location, {pUEActor}, 10000, -50000)
                self.Location.Z = nZ
                local pRelativeLocation = pUEActor.Mesh.RelativeLocation
                local pLocation = self.Location
                EngineExtActorShell.SetActorLocation(pUEActor, Vector{X=pLocation.X, Y=pLocation.Y, Z=pLocation.Z - pRelativeLocation.Z})
            end
        end
    end
end

function GamePlayerSelf:OnDestroy()
    self:UnbindUEController()
    GamePlayerSelf.super.OnDestroy(self)
end

function GamePlayerSelf:GetUEController()
    return self.pUEController
end

function GamePlayerSelf:GetUEControllerUniqueId()
    return self.nUEControllerUniqueId
end

function GamePlayerSelf:OnBeginSpectating()
    self.bIsSpectator = true
    if(GlobalVariableSystem:IsServerLogic() and self.pUEController) then
        self.pUEController:StartSpectating()
    end
    EventManager:OnFireEvent(CommonEventDef.EV_SHIP_BATTLE_ON_BEGIN_SPECTATING)
end

function GamePlayerSelf:OnEndSpectating()
    self.bIsSpectator = false
    EventManager:OnFireEvent(CommonEventDef.EV_SHIP_BATTLE_ON_END_SPECTATING)
end

function GamePlayerSelf:GetDebugInfo()
    local tbRet = GamePlayerSelf.super.GetDebugInfo(self)
    tbRet.nUEControllerUniqueId = self.nUEControllerUniqueId
    return tbRet
end

-- tbLoc.nX, tbLoc.nY, tbLoc,nZ - reborn location
-- tbLoc, nYaw both optional
function GamePlayerSelf:Reborn(nX, nY, nZ, nYaw)
    local bWithLocation = false
    if nX ~= nil and nY ~= nil and nZ ~= nil then
        bWithLocation = true
    end
    local pActor = self.pUEActor
    if(pActor) then
        log("BattleGameModeBase:PlayerReborn", self.nPlayerId)
        if bWithLocation then
            nYaw = nYaw or 0
            UEActorHelper:TeleportShip(self.pUEActor, Vector{X = nX, Y = nY, Z = nZ}, nYaw, true)
        end
        -- self.ShipLifecycleComponent:Reborn()
        if(self.pUEController and self.bIsSpectator) then
            self.pUEController:Possess(pActor)
        end
    end
end

function GamePlayerSelf:GetActorClassByTemplateId(nTemplateId)
    if self.nTemplateType == TemplateTypeDef.SHIP then
        -- 船时装逻辑
        local tbResTemplate = self.BattleShipSkinComponent:GetShipResTemplate(nTemplateId)
        if tbResTemplate then
            return tbResTemplate.szPawnClassName
        end
    end
    return GamePlayerSelf.super.GetActorClassByTemplateId(self, nTemplateId)
end

return GamePlayerSelf
