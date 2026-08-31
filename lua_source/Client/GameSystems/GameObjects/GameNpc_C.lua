-- NPC角色
local luaclass = require("luaclass")
local GameNpcClass = require("GameNpc")
local GameNpc_C = luaclass("GameNpc_C", GameNpcClass)
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local GameWorldSystem = require("GameWorldSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local EffectResDataTable = require("EffectResDataTable")
local L10N = require("L10N")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
-- local SelfAnimationHelper = require("SelfAnimationHelper")
local InteractionCheckBase = require("InteractionCheckBase")
local GameObjectTypeDef = require("GameObjectTypeDef")

-- local GameObjectTypeDef = require("GameObjectTypeDef")
local NPC_SELECTED_RES = "/Game/Resources/Effects/Common/PS_NPC_Select_01.PS_NPC_Select_01"
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
GameNpc_C.pSelectedEffectComponent = nil
GameNpc_C.nDefaultYaw = 0 --初始朝向
GameNpc_C.nAreanId = -1
GameNpc_C.pNpcEffect = nil
GameNpc_C.nVfxID = 0
GameNpc_C.bResetLocation = true

local Scale1 = Vector{X = 1, Y = 1, Z = 1}
local GameObjectSystem = nil

function GameNpc_C:OnPostCreate()
	GameNpc_C.super.OnPostCreate(self)
	self:SetCheckInteractionClass(InteractionCheckBase)
	self:CreateInteractionTrigger()
end

function GameNpc_C:ParseCreateData(tbCreateData)
	local bRet = GameNpc_C.super.ParseCreateData(self, tbCreateData)
	if not bRet then
		return bRet
	end

    if tbCreateData.szNameArg and string.len(tbCreateData.szNameArg) > 0 then
        self.szName = L10N:Format(self.tbNpcTemplateData.szName,tbCreateData.szNameArg)
    end
	self.nVfxID = tbCreateData.nVfxID
	return true
end

function GameNpc_C:OnActorCreated(pUEActor)
    if not GlobalVariableSystem_C.bShowCharacter then
        pUEActor:SetActorHiddenInGame(true)
        if self.HeadInfoComponent then
            self.HeadInfoComponent:SetVisibility(false)
        end
	end
	if not GlobalVariableSystem:IsInDungeon() and self.bResetLocation then
		local World = GameWorldSystem:GetWorld()
		if World and not  World:IsOcean() and not self:IsShip() then
			self:GetLocationOnFloor()
			local pRelativeLocation = pUEActor.Mesh.RelativeLocation
			-- local pLocation = UEActorHelper:GetActorLocation(pUEActor)
			local pLocation = self.Location
			EngineExtActorShell.SetActorLocation(pUEActor, Vector{X=pLocation.X, Y=pLocation.Y, Z=pLocation.Z - pRelativeLocation.Z})
		end

		if self:IsShip() and self.ObjectType == GameObjectTypeDef.Npc then
			if pUEActor.Flotage then
				pUEActor.Flotage.ApplyTransform = true
				-- pUEActor.Flotage.bAlwaysUpdate = true
			end
		end
	end

	self.nDefaultYaw = pUEActor:K2_GetActorRotation().Yaw
	self:SyncNpcRes(self.nVfxID)
	GameNpc_C.super.OnActorCreated(self, pUEActor)
	-- self:CreateInteractionTrigger()
	if self:IsHuman() then 
		pUEActor.Mesh:SetVisibility(true)
	end
end

function GameNpc_C:UnbindUEActor()
	if self.pUEActor  and  self.pSelectedEffectComponent then
		EngineExtActorShell.DestroyActorComponent(self.pUEActor, self.pSelectedEffectComponent)
		self.pSelectedEffectComponent = nil
	end
	GameNpc_C.super.UnbindUEActor(self)
	self:DestroyInteractionTrigger()
end

function GameNpc_C:SetSelected(bSelected)
	-- if self.HeadInfoComponent then
	--     self.HeadInfoComponent:SetSelected(bSelected)
	-- end
	if bSelected then
		local nInteractionType = self.tbNpcTemplateData.nInteractionType
		--可交互 但不显示选中
		if nInteractionType == 5 or nInteractionType == 4 then
			return
		end
		if not self.pSelectedEffectComponent and self.pUEActor then
			local pScale = nil
			local World = GameWorldSystem:GetWorld()

			if World:IsOcean()  or  GlobalVariableSystem:IsInDungeon() then
				pScale = Vector {X = 50, Y = 1, Z = 1}
			else
				pScale = Vector {X = 1, Y = 1, Z = 1}
			end
			local position = nil
			if self.pUEActor.Mesh then
				position = self.pUEActor.Mesh:K2_GetComponentLocation()
			elseif self.pUEActor.ShipModel then
				position = self.pUEActor.ShipModel:K2_GetComponentLocation()
			end
			self.pSelectedEffectComponent = ExtendBlueprintFunctions.SpawnEmitterAttachedEx(NPC_SELECTED_RES:load(), self.pUEActor.RootComponent, "", position, Rotator(), Scale1,
			EAttachLocation.KeepWorldPosition, false, 1, EPSCPoolMethod.None, false)
			if self.pSelectedEffectComponent then
				self.pSelectedEffectComponent:SetRelativeScale3D(pScale)
			end
		end
	elseif self.pUEActor and self.pSelectedEffectComponent then
		EngineExtActorShell.DestroyActorComponent(self.pUEActor, self.pSelectedEffectComponent)
		self.pSelectedEffectComponent = nil
	end
end


function GameNpc_C:FaceToPlayer()
	if self.pUEActor then
		local pPlayer = GamePlayerSelfHelper:Get().pUEActor
		self.pTargetRotation = KismetMathLibrary.FindLookAtRotation(self.pUEActor:K2_GetActorLocation(), pPlayer:K2_GetActorLocation())

		self.pUEActor:RotatorTo(self.pTargetRotation.Yaw, 15)
	end
end

function GameNpc_C:ResetDefaultRotator()
	if self.pUEActor then
		self.pUEActor:RotatorTo(self.nDefaultYaw, 15)
	end
end

function GameNpc_C:CreateInteractionTrigger()
	if not self:CheckCanInteraction() then
		return
	end

	local AreaTriggerManager = ClientShell.GetClient(GWorld):GetAreaTriggerManager()
	local position = self.pUEActor and self.pUEActor:K2_GetActorLocation() or self:GetLocation()
	self.nAreanId = AreaTriggerManager:Create2DArea(position.X, position.Y, self.tbNpcTemplateData.nDistance)
end

function GameNpc_C:DestroyInteractionTrigger()
	if self.nAreanId ~= -1 then
			EventManager:OnFireEvent(CommonEventDef.EV_GAME_AREA_LEAVE, self, self.nAreanId)
        local AreaTriggerManager = ClientShell.GetClient(GWorld):GetAreaTriggerManager()
        AreaTriggerManager:Destroy2DArea(self.nAreanId)
        self.nAreanId = -1
    end
	self.bEnableInteraction = false
end

function GameNpc_C:GetLocationOnFloor()
	if GameObjectSystem == nil then
		GameObjectSystem = require("GameObjectSystem_C")
	end
	local tbIngoreActor = {}
	local tbObjects = GameObjectSystem:GetAllGameObjects()
	for _, v in pairs(tbObjects) do
		if v.pUEActor ~= nil then
			table.insert(tbIngoreActor, v.pUEActor)
		end
	end
	local nZ = EngineExtActorShell.GetLocationZOnFloor(GWorld, self.Location, tbIngoreActor, 1000, -5000)
	self.Location.Z = nZ
end

function GameNpc_C:SyncNpcRes(nVfxID)
	if self.pNpcEffect  then
		EngineExtActorShell.DestroyActorComponent(self.pUEActor, self.pNpcEffect)
		self.pNpcEffect = nil
	end

	if nVfxID > 0 then
		local tbEffect = EffectResDataTable:GetTemplate(nVfxID)
		if tbEffect then
			local attachComnponent = self.pUEActor[tbEffect.szSocket]
			if attachComnponent then
				self.pNpcEffect = ExtendBlueprintFunctions.SpawnEmitterAttachedEx(tbEffect.szEffectClass:load(),
					self.pUEActor.RootComponent, "" , attachComnponent:K2_GetComponentLocation(), Rotator(), Scale1,
					EAttachLocation.KeepWorldPosition, false, 1, EPSCPoolMethod.None, false)
			else
				self.pNpcEffect = ExtendBlueprintFunctions.SpawnEmitterAttachedEx(tbEffect.szEffectClass:load(),
					self.pUEActor.RootComponent, "" , self.pUEActor:K2_GetActorLocation(), Rotator(), Scale1,
					EAttachLocation.KeepWorldPosition, false, 1, EPSCPoolMethod.None, false)
			end
		end
	end
end

function GameNpc_C:PlayAnimation(szAnimKey)
	logerror("[GameAtmoSphereShipNpc_C:PlayAnimation]该函数已由[SelfAnimationHelper:PlayNPCAnimation]替换", debug.traceback( ))
	return false
end

function GameNpc_C:SetHumanMovementComponent(bEnable)
	if not GlobalVariableSystem:IsInDungeon() and self.pUEActor.CharacterMovement and not self:IsShip() then
		self.pUEActor.CharacterMovement:SetComponentTickEnabled(bEnable)
	end
end

function GameNpc_C:OnDelayDestroy()
	self.pUEActor:SetActorHiddenInGame(true)
	if self.NpcQuestComponent then
		self.NpcQuestComponent:UpdateHeadInfo()
	end
	if self.HeadInfoComponent then
		self.HeadInfoComponent:SetVisibility(false)
	end
	if self.pNpcEffect  then
		EngineExtActorShell.DestroyActorComponent(self.pUEActor, self.pNpcEffect)
		self.pNpcEffect = nil
	end

	if self.HeadInfoComponent then
		self.HeadInfoComponent:SetVisibility(false)
	end

	self:DestroyInteractionTrigger()
end


function GameNpc_C:OnRestoreObject(tbParam)
	if self.NpcQuestComponent then
		self.NpcQuestComponent:UpdateHeadInfo()
	end
	if self.HeadInfoComponent then
		self.HeadInfoComponent:SetVisibility(true)
	end
	self:SyncNpcRes(self.nVfxID)
	self.pUEActor:SetActorHiddenInGame(false)
	if self.HeadInfoComponent then
		self.HeadInfoComponent:SetVisibility(true)
	end
	if self.tbNpcTemplateData and self.tbNpcTemplateData.nInteractionType ~= 0  then
        self.bEnableInteraction = true
    end
	self:CreateInteractionTrigger()
end


return GameNpc_C
