--File Name    : Matinee.lua
--Author       : Zuo Kun
--Create Time  : 2017-06-09
--Description  : Matinee
-----------------------------------------------------
local luaclass = require("luaclass")
local Matinee = require("Matinee")
local Matinee_C = luaclass("Matinee_C", Matinee)
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GenderTypeDef = require("GenderTypeDefine")
local MatineeSubTitle = require("MatineeSubTitle")
local NpcUiTable = require("NpcUiTable")
local UIManager = require("UIManager")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local HumanDataTable = require("HumanDataTable")
local MatineeBindActorData = require("MatineeBindActorData")
local UEActorHelper = require("UEActorHelper")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local MatineeEventDatatable = require("MatineeEventDatatable")
-- local SUBTITLE_BACKGROUND = '/Game/UI/Textures/Common/Frames/Spr_Common_12.Spr_Common_12'
Matinee_C.LoadSubtitleEndDelegate = nil
Matinee_C.tbBindActor = {}
Matinee_C.bHasSubtitle =  false


local MatineeEventType = {}
MatineeEventType["OpenUI"] = 0
MatineeEventType["SendEvent"] = 1

function Matinee_C:GetMatineeRes()
	local szRes = self.tbMatineeData.szMaleRes

	if self.tbMatineeData.szFemaleRes then
		local gender = GenderTypeDef.MALE
		local PlayerSelf = GamePlayerSelfHelper:Get()
		if PlayerSelf and PlayerSelf.LobbyPropertyComponent then
			gender = PlayerSelf.LobbyPropertyComponent:GetHumanGender()
		elseif GlobalVariableSystem_C:HasNewRoldAvatarId() then
			local tbHumanData = HumanDataTable:GetTemplate(GlobalVariableSystem_C:GetNewRoleAvatarId())
			gender = tbHumanData.nGender
		end
		if gender == GenderTypeDef.FEMALE then
			szRes = self.tbMatineeData.szFemaleRes
		end
	end
	return szRes
end

function Matinee_C:StopMatinee()
	Matinee_C.super.StopMatinee(self)
	local pPlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
	if not pPlayerController then
		return
	end
	local pHUD = pPlayerController:GetHUD()
	if pHUD and pHUD.TryGetSubtitleManager then
		pHUD:StopSubtitle()
	end

	for i, v in ipairs(self.tbBindActor) do
		UEActorHelper:DestroyActor(v)
	end
	self.tbBindActor = {}
end

function Matinee_C:PlayMatinee()
	Matinee_C.super.PlayMatinee(self)
	if self.tbMatineeData.szSubTitlePath then
		local pHUD = GameplayStatics.GetPlayerController(GWorld, 0):GetHUD()
		if pHUD and pHUD.TryGetSubtitleManager then
			self.bHasSubtitle = true
			pHUD:TryGetSubtitleManager()
			self.LoadSubtitleEndDelegate = self.EventHelper:RegisterCppDelegate(pHUD.SubtitleManager.OnLoadEnd, self, self.OnLoadSubtitleEnd)
			pHUD:StartPlaySubtitleforSequence(self.tbMatineeData.szSubTitlePath)
		end
	end
end

function Matinee_C:OnLoadSubtitleEnd()
	local pHUD = GameplayStatics.GetPlayerController(GWorld, 0):GetHUD()
	pHUD.SubtitleManager.OffsetPosition = Vector2D {X = 0, Y = - 70}
	pHUD.SubtitleManager.ShadowOffset = Vector2D {X = 2, Y = 2}
	MatineeSubTitle:Parse(pHUD.SubtitleManager)
	self.EventHelper:UnregisterCppDelegate(self.LoadSubtitleEndDelegate)

	-- local pHUD = GameplayStatics.GetPlayerController(GWorld, 0):GetHUD()
	self.LoadSubtitleEndDelegate = self.EventHelper:RegisterCppDelegate(pHUD.SubtitleManager.OnEventTrigger, self, self.OnEventTrigger)
end

function Matinee_C:OnLoopStart()
	Matinee_C.super.OnLoopStart(self)
	if not self.bHasSubtitle then
		return
	end

	local pPlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
	if not pPlayerController then
		return
	end
	local pHUD = pPlayerController:GetHUD()
	if pHUD and pHUD.TryGetSubtitleManager then
		pHUD:RestartSubtittle()
	end
end

function Matinee_C:OnEventTrigger(nEventID)
	log("[Matinee] OnOpenUI " .. nEventID)
	local tbTemplate = MatineeEventDatatable:GetTemplate(nEventID)
	if tbTemplate.nType == MatineeEventType.OpenUI then
		local tbUiData = NpcUiTable:GetTemplate(tbTemplate.nUIId)
		if not tbUiData then
			logerror("Error UI ID " .. nEventID)
			return
		end
		local tbParam = {}
		tbParam.nMatineeID = self.nID
		tbParam.szParam = tbUiData.szParam
		UIManager:OpenWnd(tbUiData.szWndName, tbParam)
	elseif tbTemplate.nType == MatineeEventType.SendEvent then
		EventManager:OnFireEvent(ClientEventDef[tbTemplate.szEventKey])
	else
		logerror("Matinee_C:OnEventTrigger error, event id : ", nEventID)
	end
end


function Matinee_C:OnPlayMatinee(pLevelSequenceActor)
	EventManager:OnFireEvent(ClientEventDef.EV_ON_MATINEE_PLAY, self)
	-- local PlayerSelf = GamePlayerSelfHelper:Get()
	-- if PlayerSelf and self.pMatineeLevel then
	-- 	local LevelScriptActor = self.pMatineeLevel:GetLevelScriptActor()
	-- 	if LevelScriptActor.GetBindID then
	-- 		pLevelSequenceActor:AddBinding(LevelScriptActor:GetBindID(), PlayerSelf.pUEActor, false)
	-- 	end
	-- end
	self:BindUEActor()
end

function Matinee_C:OnMatineeEnd()
	Matinee_C.super.OnMatineeEnd(self)
	for i, v in ipairs(self.tbBindActor) do
		UEActorHelper:DestroyActor(v)
	end
	self.tbBindActor = {}
end

function Matinee_C:BindUEActorFromBindID(nBindID, nRace, nGender)
	local tbBindData = MatineeBindActorData:GetTemplate(nBindID, nRace, nGender)
	if tbBindData and tbBindData.szBindTarget then
		if tbBindData.szReplaceMesh then
			-- local animationName = {}
			-- local LAnimSequence = {}
			-- table.insert(LAnimSequence, szAnim:load())
			-- ExtendBlueprintFunctions.ReplaceMatineeAnimation(self.pLevelSequencePlayer, tbBindData.szBindTarget, animationName, LAnimSequence)
			local tbBindActors = ExtendBlueprintFunctions.GetMatineeActor(self.pLevelSequencePlayer, tbBindData.szBindTarget)
			if #tbBindActors <=0 then
				log("[matinee] can't find BindTarget ".. tbBindData.szBindTarget)
			end
			for _,ReplaceActor in ipairs(tbBindActors) do
				if ReplaceActor == nil or ReplaceActor[tbBindData.szReplaceMesh] == nil then
					log("[matinee] can't find ReplaceMesh ".. tbBindData.szReplaceMesh)
					return
				end
				local SkeletalMeshComponent = ReplaceActor[tbBindData.szReplaceMesh]
				local AnimClass = SkeletalMeshComponent.AnimClass;
				local AnimModeType = SkeletalMeshComponent:GetAnimationMode();
				SkeletalMeshComponent:SetSkeletalMesh(tbBindData.szActorPath:load(), true)
				SkeletalMeshComponent:K2_SetAnimInstanceClass(AnimClass);
				SkeletalMeshComponent:SetAnimationMode(AnimModeType);
				-- local aa = SkeletalMeshComponent:GetPosition()
				-- logdebug("  aaa  " .. aa)
				-- SkeletalMeshComponent:SetPosition(0)
			end
			-- local ReplaceActor = ExtendBlueprintFunctions.GetWorldActorByName(GWorld, tbBindData.szBindTarget)

		else
			local bindActor = nil
			if tbBindData.szActorPath then
				local _nUniqueId, RetActor = UEActorHelper:CreateActor(tbBindData.szActorPath)
				bindActor = RetActor
				table.insert(self.tbBindActor, bindActor)
			else
				local PlayerSelf = GamePlayerSelfHelper:Get()
				bindActor = PlayerSelf.pUEActor
			end
			if bindActor then
				ExtendBlueprintFunctions.ReplaceMatineeActor(self.pLevelSequencePlayer, tbBindData.szBindTarget, bindActor)
				-- bindFunc(pLevelSequenceActor, bindActor, GWorld)
			end
		end
	end
end

function Matinee_C:BindUEActorFromSkeletalMesh(szBindTarget, szReplaceMesh, pSkeletalMesh)
	local tbBindActors = ExtendBlueprintFunctions.GetMatineeActor(self.pLevelSequencePlayer, szBindTarget)
	if #tbBindActors <=0 then
		log("[matinee] can't find BindTarget ".. szBindTarget)
	end
	for _,ReplaceActor in ipairs(tbBindActors) do
		if ReplaceActor == nil or ReplaceActor[szReplaceMesh] == nil then
			log("[matinee] can't find ReplaceMesh ".. szReplaceMesh)
			return
		end
		local SkeletalMeshComponent = ReplaceActor[szReplaceMesh]
		local AnimClass = SkeletalMeshComponent.AnimClass;
		local AnimModeType = SkeletalMeshComponent:GetAnimationMode();
		SkeletalMeshComponent:SetSkeletalMesh(pSkeletalMesh, true)
		SkeletalMeshComponent:K2_SetAnimInstanceClass(AnimClass);
		SkeletalMeshComponent:SetAnimationMode(AnimModeType);
		-- local aa = SkeletalMeshComponent:GetPosition()
		-- logdebug("  aaa  " .. aa)
		-- SkeletalMeshComponent:SetPosition(0)
	end
end

function Matinee_C:BindUEActor()
	local pLevelSequenceActor = ExtendBlueprintFunctions.GetSequenceActorFromPlayer(self.pLevelSequencePlayer)
	if not pLevelSequenceActor then
		return
	end
	local PlayerSelf = GamePlayerSelfHelper:Get()
	if self.tbMatineeData.tbBindHuman then
		local tbHumanData = nil
		if PlayerSelf and  PlayerSelf.LobbyPropertyComponent then
			tbHumanData = HumanDataTable:GetTemplate(PlayerSelf.LobbyPropertyComponent.nHumanTemplateId)
		elseif GlobalVariableSystem_C:HasNewRoldAvatarId() then
			tbHumanData = HumanDataTable:GetTemplate(GlobalVariableSystem_C:GetNewRoleAvatarId())
		end
		-- for k,v in pairs(self.tbMatineeData.tbBindHuman) do
		for i, v in ipairs(self.tbMatineeData.tbBindHuman) do
			if tbHumanData then
				-- tbBindData = MatineeBindActorData:GetTemplate(v, tbHumanData.nRace, tbHumanData.nGender)
				self:BindUEActorFromBindID(v, tbHumanData.nRace, tbHumanData.nGender)
			else
				-- tbBindData = MatineeBindActorData:GetTemplate(v)
				self:BindUEActorFromBindID(v)
			end
		end
	end
	if self.tbMatineeData.tbBindShip then
		for i, v in ipairs(self.tbMatineeData.tbBindShip) do
			self:BindUEActorFromBindID(v)
		end
	end
end

function Matinee_C:ReplaceMatineeActor(szSrcActorName, szTargetActorClassName)
	local _, RetActor = UEActorHelper:CreateActor(szTargetActorClassName)
	if RetActor then
		table.insert(self.tbBindActor, RetActor)
		ExtendBlueprintFunctions.ReplaceMatineeActor(self.pLevelSequencePlayer, szSrcActorName, RetActor)
	end
end

function Matinee_C:ReplaceShipSkeletalByTag(szTagName, szSkeletalName, szShipClassName)
	local ReplaceActor = ExtendBlueprintFunctions.GetWorldActorByName(GWorld, szTagName)
	if ReplaceActor == nil then
		logerror("Replace actor failed！ReplaceActor == nil", szTagName, szSkeletalName, szShipClassName)
		return
	end
	if ReplaceActor[szSkeletalName] == nil then
		logerror("Replace actor failed！ReplaceActor[szSkeletalName] == nil ", szTagName, szSkeletalName, szShipClassName)
		return
	end
	local _, pShip = UEActorHelper:CreateActor(szShipClassName)

    local pTransform = KismetMathLibrary.MakeTransform(Vector{X=0, Y=0, Z=0}, Rotator{Roll=0,Pitch=0,Yaw=0}, Vector{X=0, Y=0, Z=0})
	local pShipMaster = EngineExtActorShell.SpawnActorForScript(GWorld, pShip.ShipModel.ChildActorClass, pTransform, nil)
	local SkeletalMeshComponent = ReplaceActor[szSkeletalName]
	SkeletalMeshComponent:SetSkeletalMesh(pShipMaster.SKM_ShipMaster.SkeletalMesh, true)
	SkeletalMeshComponent:K2_SetRelativeLocation(pShip.ShipModel.RelativeLocation)
	if ReplaceActor.ShipModel then
		ReplaceActor.ShipModel.ChildActorClass = pShip.ShipModel.ChildActorClass
	end
	ReplaceActor.Flotage.LocationZ =  pShip.Flotage.LocationZ

	UEActorHelper:DestroyActor(pShip)
	UEActorHelper:DestroyActor(pShipMaster)
end

return Matinee_C