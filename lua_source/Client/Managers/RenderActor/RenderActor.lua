-----------------------------------------------------
--File Name    : RenderActor.lua
--Author       : Zuo Kun
--Create Time  : 2017-06-18
--Description  : RenderActor
-----------------------------------------------------
local luaclass = require("luaclass")
local RenderActor = luaclass("RenderActor")
local UEActorHelper = require("UEActorHelper")
local GameAvatarHelper = require("GameAvatarHelper")
local ResourceManager = require("ResourceManager")
local LuaDelegate = require("LuaDelegate")
local DelayTimer = require("DelayTimer")
-- local RenderTargetType = require("RenderTargetType")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

local tbShipRenderComponentTags = {"Common", "Wild", "Battle"}
local pDefaultLocation = Vector {X = 10000, Y = 10000, Z = 1000}
local pDefaultRotation = Rotator {Pitch = 0, Yaw = 0, Roll = 0}
local pDefaultScale = Vector {X = 1, Y = 1, Z = 1}

local szShipAvatarComponent = "/Game/Game/Ships/Components/BP_ShipAvatarComponent.BP_ShipAvatarComponent_C"
-- local szHumanAvatarComponent = "/Game/Game/Characters/Components/BP_HumanAvatarComponent.BP_HumanAvatarComponent_C"

RenderActor.szAvatarClassPath = ""
RenderActor.pUEActor = nil
RenderActor.pAvatarComponent = nil
RenderActor.nRefCount = 1
RenderActor.SceneCaptureRecord = nil
RenderActor.Owner = nil
RenderActor.OnComplete = nil
RenderActor.ShipResHandler = nil
RenderActor.NomalResHandler = nil
RenderActor.HumanResHandler = nil
RenderActor.DelayShowHandler = nil

RenderActor.ActorType = {
	Normal = 1,
	Human = 2,
	Ship = 3,
	Npc = 4,
}

RenderActor.tbDeleteTimer = nil

function RenderActor:Clear()
	if self.tbDeleteTimer then
		DelayTimer:ClearTimer(self.tbDeleteTimer)
		self.tbDeleteTimer = nil
	end
	self.pAvatarComponent = nil
	if self.pUEActor then
		UEActorHelper:DestroyActor(self.pUEActor)
		self.pUEActor = nil
	end
end

function RenderActor:UnDestroy()
	if self.tbDeleteTimer then
		DelayTimer:ClearTimer(self.tbDeleteTimer)
		self.tbDeleteTimer = nil
	end
end

function RenderActor:Destroy()
	self.nRefCount = self.nRefCount - 1
	log("RenderActor Remove RenderActor")
	if self.nRefCount <= 0 then
		if self.ShipResHandler then
			ResourceManager:CancelLoadAsync(self.ShipResHandler)
			self.ShipResHandler = nil
		end
		if self.DelayShowHandler then
			DelayTimer.ClearTimer(self.DelayShowHandler)
			self.DelayShowHandler = nil
		end
		if self.HumanResHandler then
			ResourceManager:CancelLoadAsync(self.HumanResHandler)
			self.HumanResHandler = nil
		end
		if self.NomalResHandler then
			ResourceManager:CancelLoadAsync(self.NomalResHandler)
			self.NomalResHandler = nil
		end
		if self.pUEActor then
			-- EngineExtActorShell.SetActorSkeletalMeshLightChannel(self.pUEActor, false, false, false)
			self.tbDeleteTimer = DelayTimer:RunNextTick(function()
				log("RenderActor Start Destroy RenderActor")
				UEActorHelper:DestroyActor(self.pUEActor)
				log("RenderActor End Destroy RenderActor")
				self.tbDeleteTimer = nil
				self.Owner:RemoveActor(self)
				self.pUEActor = nil
			end )
		end
		-- self.Owner:RemoveActor(self)
		if self.OnComplete then
			-- self.OnComplete:Fire()
			self.OnComplete:UnbindAll()
			self.OnComplete = nil
		end
		self.pAvatarComponent = nil
	end
end

function RenderActor:Create(Owner, nActorType, szAvatarClassPath, szRecordName, pInLocation, pInRotation, pInScale, bAsync)
    self.Owner = Owner
    self.szAvatarClassPath = szAvatarClassPath
	local pLocation =(pInLocation == nil) and Vector() or pInLocation
	local pRotation =(pInRotation == nil) and pDefaultRotation or pInRotation
	local pScale =(pInScale == nil) and pDefaultScale or pInScale
	-- szRecordName = (szRecordName == nil) and pDefaultRecordName or szRecordName

	if nActorType == self.ActorType.Normal then
        self:LoadNomalActor(szAvatarClassPath, szRecordName, pLocation, pRotation, pScale, bAsync)
	elseif nActorType == self.ActorType.Human then
        self:CreateHumanActor(szAvatarClassPath, szRecordName, pLocation, pRotation, pScale, bAsync)
	elseif nActorType == self.ActorType.Ship then
        self:CreateShipActor(szAvatarClassPath, szRecordName, pLocation, pRotation, pScale)
	end
end

function RenderActor:LoadNomalActor(szAvatarClassPath, szRecordName, pInLocation, pInRotation, pInScale, bAsync)
	if bAsync then
		local function fnLoadNomalEnd(szAssetName, pObject, nHandler)
			if not pObject then
				logerror("Error Avatar Path " .. szAvatarClassPath)
				return
			end
			self:LoadNomalEnd(pObject, szRecordName, pInLocation, pInRotation, pInScale)
		end

		self.NomalResHandler = ResourceManager:LoadAsync(szAvatarClassPath, fnLoadNomalEnd)
	else
		self:LoadNomalEnd(szAvatarClassPath:load(),szRecordName,pInLocation,pInRotation,pInScale)
	end
end

function RenderActor:LoadNomalEnd(pObject, szRecordName, pInLocation, pInRotation, pInScale)
	if self.NomalResHandler then
		self.NomalResHandler = nil
	end
	-- pDefaultLocation = self.Owner.tbLightMaps[RenderTargetType.Normal].CharacterPos
	self:CreateNormalActor(pObject, szRecordName, pInLocation, pInRotation, pInScale)
end

function RenderActor:CreateNormalActor(pObject, szRecordName, pInLocation, pInRotation, pInScale)
	local pLocation, pRotation
	if pInLocation then
		pLocation = pInLocation
	else
		pLocation = pDefaultLocation
	end

	if pInRotation then
		pRotation = pInRotation
	else
		pRotation = pDefaultRotation
	end
	local pTransform = KismetMathLibrary.MakeTransform(pLocation, pRotation, pDefaultScale)
	-- local pLocation = KismetMathLibrary.TransformLocation(pTransform, pInLocation)
	-- pTransform = KismetMathLibrary.MakeTransform(pLocation, pInRotation, pInScale)

	local RetActor = UEActorHelper:CreateActorByClass(pObject, pTransform)
	RetActor:K2_SetActorTransform(pTransform)

	-- EngineExtActorShell.SetActorSkeletalMeshLightChannel(RetActor, false, true, false)
	EngineExtActorShell.SetActorSkeletalMeshMipMap(RetActor, true)
	-- EngineExtActorShell.SetActorSkeletalMeshCastShadow(RetActor, false)

	self.pUEActor = RetActor
	self.nRefCount = 1

	if szRecordName then
		if RetActor.CaptureTransform then
			self.SceneCaptureRecord = {}
			local RelativeTransform = RetActor.CaptureTransform
			local Location, Rotation, Scale = KismetMathLibrary.BreakTransform(RelativeTransform)
			local WorldLocation = KismetMathLibrary.TransformLocation(pTransform, Location)
			pTransform = KismetMathLibrary.MakeTransform(WorldLocation, Rotation, Scale)
			self.SceneCaptureRecord.pTransform = pTransform
			self.SceneCaptureRecord.OrthoWidth = RetActor.CaptureOrthoWidth
			self.SceneCaptureRecord:SetCaptureFov(RetActor.CaptureFovAngle)
			self.SceneCaptureRecord.ProjectionType = RetActor.CaptureProjectionType
		else
			local pCaptureRecord = RetActor[szRecordName]
			if pCaptureRecord then
				self.SceneCaptureRecord = {}
				local WorldLocation = KismetMathLibrary.TransformLocation(pTransform, pCaptureRecord.RelativeLocation)
				pTransform = KismetMathLibrary.MakeTransform(WorldLocation, pCaptureRecord.RelativeRotation, pDefaultScale)
				self.SceneCaptureRecord.pTransform = pTransform
				self.SceneCaptureRecord.OrthoWidth = pCaptureRecord.OrthoWidth
				self.SceneCaptureRecord:SetCaptureFov(pCaptureRecord.FOVAngle)
				self.SceneCaptureRecord.ProjectionType = pCaptureRecord.ProjectionType
			end
		end
    end
end

function RenderActor:CreateHumanActor(szAvatarClassPath, szRecordName, pInLocation, pInRotation, pInScale, bAsync)
	if bAsync then
		local function fnLoadHumanEnd(szAssetName, pObject, nHandler)
			if not pObject then
				logerror("Error Avatar Path " .. szAvatarClassPath)
				return
			end
			self:LoadHumanEnd(pObject, szRecordName, pInLocation, pInRotation, pInScale)
		end

		self.HumanResHandler = ResourceManager:LoadAsync(szAvatarClassPath, fnLoadHumanEnd)
	else
		self:LoadHumanEnd(szAvatarClassPath:load(),szRecordName,pInLocation,pInRotation,pInScale)
	end

end

function RenderActor:LoadHumanEnd(pObject, szRecordName, pInLocation, pInRotation, pInScale)
	if self.HumanResHandler then
		self.HumanResHandler = nil
	end
	-- if not self.Owner.tbLightMaps[RenderTargetType.Human] then
	-- 	return
	-- end
	-- pDefaultLocation = self.Owner.tbLightMaps[RenderTargetType.Human].CharacterPos
	self:CreateNormalActor(pObject, szRecordName, pInLocation, pInRotation, pInScale)
	if not self.pUEActor then
		-- logdebug("Error Avatar Path " .. szAvatarClassPath)
		return
	end

	-- local pHumanAvatarComponent = EngineExtActorShell.CreateActorComponent(self.pUEActor, szHumanAvatarComponent:load())
	-- pHumanAvatarComponent:Init(self.pUEActor.Mesh)
	self.pAvatarComponent = self.pUEActor.HumanAvatarComponent
	self.pUEActor:SetActorHiddenInGame(true)
	self.DelayShowHandler = DelayTimer:RunNextTick(function()
		self.DelayShowHandler = nil
		if self.pUEActor then
			self.pUEActor:SetActorHiddenInGame(false)
		end
	end)
	EngineExtActorShell.SetActorSkeletalMeshMipMap(self.pUEActor, true)
	-- EngineExtActorShell.SetActorSkeletalMeshLightChannel(self.pUEActor, false, true, false)
	-- EngineExtActorShell.SetActorSkeletalMeshCastShadow(self.pUEActor, false)
	if self.OnComplete then
		self.OnComplete:Fire()
		self.OnComplete:UnbindAll()
	end
end

function RenderActor:CreateShipActor(szAvatarClassPath, szRecordName, pInLocation, pInRotation, pInScale)
	-- local nUniqueId, pShip = UEActorHelper:CreateActor(szAvatarClassPath)
	local function fnLoadShipEnd(szAssetName, pObject, nHandler)
		if not pObject then
			logerror("Error Avatar Path " .. szAvatarClassPath)
			return
		end
		self:LoadShipEnd(szAvatarClassPath, pObject, szRecordName, pInLocation, pInRotation, pInScale)
	end

	self.ShipResHandler = ResourceManager:LoadAsync(szAvatarClassPath, fnLoadShipEnd)
end

function RenderActor:LoadShipEnd(szAvatarClassPath, pObject, szRecordName, pInLocation, pInRotation, pInScale)
	if self.ShipResHandler then
		self.ShipResHandler = nil
		-- ResourceManager:CancelLoadAsync(self.ShipResHandler)
	end
	-- pDefaultLocation = self.Owner.tbLightMaps[RenderTargetType.Ship].CharacterPos
	local pTransform = KismetMathLibrary.MakeTransform(pDefaultLocation, pDefaultRotation, pDefaultScale)
    local pLocation = KismetMathLibrary.TransformLocation(pTransform, pInLocation)

	local pGameInstance = GameplayStatics.GetGameInstance(GWorld)
	local pGlobalSettings = pGameInstance.GlobalSettings

	-- 开启此开关、避免创建BP_Ship时卸载Component
    if pGlobalSettings then
        pGlobalSettings.UIShipRenderMode = true
    end
	local pShip = UEActorHelper:CreateActorByClass(pObject, pTransform, tbShipRenderComponentTags)
	-- 恢复开关状态
    if pGlobalSettings then
        pGlobalSettings.UIShipRenderMode = false
	end

	local RetActor = EngineExtActorShell.SpawnActorForScript(GWorld, pShip.ShipModel.ChildActorClass, pTransform, nil)
	if not RetActor then
		logerror("error ChildActorClass ship path " .. szAvatarClassPath)
		return
	end
	pTransform = KismetMathLibrary.MakeTransform(pLocation, pInRotation, pInScale)
	-- pShip:K2_SetActorTransform(pTransform)
	RetActor:K2_SetActorTransform(pTransform)

	if szRecordName and pShip.CaptureTransform then
		self.SceneCaptureRecord = {}
		local RelativeTransform = pShip.CaptureTransform
		local Location, Rotation, Scale = KismetMathLibrary.BreakTransform(RelativeTransform)
		local WorldLocation = KismetMathLibrary.TransformLocation(pTransform, Location)
		pTransform = KismetMathLibrary.MakeTransform(WorldLocation, Rotation, Scale)
		self.SceneCaptureRecord.pTransform = pTransform
		self.SceneCaptureRecord.OrthoWidth = pShip.CaptureOrthoWidth
		self.SceneCaptureRecord:SetCaptureFov(pShip.CaptureFovAngle)
		self.SceneCaptureRecord.ProjectionType = pShip.CaptureProjectionType
        -- local pCaptureRecord = pShip[szRecordName]
        -- if pCaptureRecord then
        --     -- pShip:K2_SetActorTransform(pTransform)
        --     self.SceneCaptureRecord = {}
		-- 	local WorldLocation = KismetMathLibrary.TransformLocation(pTransform, pCaptureRecord.RelativeLocation)
		-- 	pTransform = KismetMathLibrary.MakeTransform(WorldLocation, pCaptureRecord.RelativeRotation, pDefaultScale)
        --     self.SceneCaptureRecord.pTransform = pTransform
        --     self.SceneCaptureRecord.OrthoWidth = pCaptureRecord.OrthoWidth
        --     self.SceneCaptureRecord.FOVAngle = pCaptureRecord.FOVAngle
        --     self.SceneCaptureRecord.ProjectionType = pCaptureRecord.ProjectionType
        -- end
	end

	EventManager:OnFireEvent(ClientEventDef.EV_CREATE_UI_BP_SHIP, pShip, RetActor)

	-- local ShipModel = pShip.ShipModel.RelativeLocation
	UEActorHelper:DestroyActor(pShip)

	-- pTransform = KismetMathLibrary.MakeTransform(pLocation, pInRotation, pInScale)
	-- RetActor:K2_SetActorTransform(pTransform)

	-- EngineExtActorShell.SetActorSkeletalMeshLightChannel(RetActor, false, false, true)
	EngineExtActorShell.SetActorSkeletalMeshMipMap(RetActor, true)
	-- EngineExtActorShell.SetActorSkeletalMeshCastShadow(RetActor, false)

	RetActor:SetExhibition(true)
	self.pUEActor = RetActor
	self.nRefCount = 1

	local pShipAvatarComponent = EngineExtActorShell.CreateActorComponent(RetActor, szShipAvatarComponent:load())
	-- TODO:Category临时填0，等左琨改
	pShipAvatarComponent:Init(nil, RetActor, 0)
	self.pAvatarComponent = pShipAvatarComponent
	if self.OnComplete then
		self.OnComplete:Fire()
		self.OnComplete:UnbindAll()
	end
end



function RenderActor:UpdateHumanAvatar(tbResData, nHumanTemplateId)
	if not self.pAvatarComponent then
		return
	end

	GameAvatarHelper.UpdateHumanAvatar(self.pAvatarComponent, tbResData)
	EngineExtActorShell.SetActorSkeletalMeshMipMap(self.pUEActor, true)
	self.pAvatarComponent:ForceLoadPartsMips()

	-- EngineExtActorShell.SetActorSkeletalMeshCastShadow(self.pUEActor, false)
end

function RenderActor:UpdateShipAvatar(tbResData, nShipTemplateId, tbTResData)
	if not self.pAvatarComponent then
		return
	end
	GameAvatarHelper:UpdateShipAvatar(self.pAvatarComponent, tbResData, nShipTemplateId, tbTResData)
	EngineExtActorShell.SetActorSkeletalMeshMipMap(self.pUEActor, true)
	-- EngineExtActorShell.SetActorSkeletalMeshLightChannel(self.pUEActor, false, false, true)
	-- EngineExtActorShell.SetActorSkeletalMeshCastShadow(self.pUEActor, false)
end

function RenderActor:LoadCompleteDelegate(fnOnComplete, Owner)
	if not self.OnComplete then
		self.OnComplete = LuaDelegate()
	end
	if fnOnComplete then
		self.OnComplete:Bind(fnOnComplete, Owner)
	end
end

return RenderActor
