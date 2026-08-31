local luaclass = require("luaclass")
local ProcedureBase = require("ProcedureBase")
local ProcedureTool = require("ProcedureTool")
local Procedure_SelectRole = luaclass("Procedure_SelectRole", ProcedureBase)
local Proto = require("ClientProtoNames")
local ClientEventDef = require("ClientEventDef")
local NetworkManager = dynamic_require("NetworkManager")
local UIManager = require("UIManager")
local UIUtils = require("UIUtils")
local UIDef = require("UIDef")
local SelfEventHelper = require("SelfEventHelper")

local ManagerRoot = require("ManagerRoot")
local ManagerGroupDef = require("ManagerGroupDef")
local DelayTimer = require("DelayTimer")
local ShipDataTable = require("ShipDataTable")
local HumanDataTable = require("HumanDataTable")
local GameAvatarHelper = require("GameAvatarHelper")
local UEActorHelper = require("UEActorHelper")
local MatineeSystem = dynamic_require("MatineeSystem")
local CameraWalkerHelper = require("CameraWalkerHelper")
local GenderTypeDef 	= require("GenderTypeDefine")
local CreateRoleCameraIni = require("CreateRoleCameraIni")
local SCENE_LEVEL = ''
local AvatarDataTable = require("AvatarDataTable")
local SelfAnimationHelper = require("SelfAnimationHelper")

-- local LOGIN_MATINEE_ID = 5


-- local CREATE_ROLE_LOOP_FEMALE_MATINEE_ID = 11
-- local CREATE_ROLE_LOOP_MALE_MATINEE_ID = 8


Procedure_SelectRole.EventHelper = nil

Procedure_SelectRole.pStreamingLevel = nil
Procedure_SelectRole.CameraActor = nil
Procedure_SelectRole.HumanPosActor = nil
Procedure_SelectRole.ShipPosActor = nil
Procedure_SelectRole.bSendEnterGame = false

Procedure_SelectRole.nShipID = 0
Procedure_SelectRole.pShipActor = nil
Procedure_SelectRole.pShipAvatarComponent = nil

Procedure_SelectRole.nHumanID = 0
Procedure_SelectRole.pHumanActor = nil
Procedure_SelectRole.pHumanAvatarComponent = nil

Procedure_SelectRole.ZoomInFocusPositionM = nil
Procedure_SelectRole.ZoomOutFocusPositionM = nil
Procedure_SelectRole.ZoomInFocusPositionF = nil
Procedure_SelectRole.ZoomOutFocusPositionF = nil
Procedure_SelectRole.CameraWalker = nil

local function ClearTimer(self)
	if self.ShowUITimer then
		DelayTimer:ClearTimer(self.ShowUITimer)
		self.ShowUITimer = nil
	end
end

function Procedure_SelectRole:Init()
	Procedure_SelectRole.super.Init(self)
	self.EventHelper = SelfEventHelper()
end

function Procedure_SelectRole:Uninit()
	self:UnbindHubMethod()
	if self.CameraWalker then
		self.CameraWalker:TearDown()
		self.CameraWalker = nil
	end
	Procedure_SelectRole.super.Uninit(self)
end

function Procedure_SelectRole:Begin()

	self.nShipID = 0
	self.pShipActor = nil
	self.pShipAvatarComponent = nil

	self.nHumanID = 0
	self.pHumanActor = nil
	self.pHumanAvatarComponent = nil

	UIManager:CloseWnd(UIDef.UI_LOGIN)
	Procedure_SelectRole.super.Begin(self)
	self:BindHubMethod()
	self.bSendEnterGame = false
	ManagerRoot:InitGroup(ManagerGroupDef.nLoginGroupID, true)
	self:OpenSelectRoleMap()
end

function Procedure_SelectRole:End()
	if self.pShipActor then
		UEActorHelper:DestroyActor(self.pShipActor)
		self.pShipActor = nil
		self.pShipAvatarComponent = nil
		self.nShipID = 0
	end

	if self.pHumanActor then
		UEActorHelper:DestroyActor(self.pHumanActor)
		self.pHumanActor = nil
		self.pHumanAvatarComponent = nil
		self.nHumanID = 0
	end

	if self.pStreamingLevelLoadedDelegate then
		self.EventHelper:UnregisterCppDelegate(self.pStreamingLevelLoadedDelegate)
		self.pStreamingLevelLoadedDelegate = nil
	end

	if self.CameraWalker then
		self.CameraWalker:TearDown()
		self.CameraWalker = nil
	end

	self:UnbindHubMethod()
	self:HideUI()
	ClearTimer(self)
	UIManager:PopAllState()
	ManagerRoot:UninitGroup(ManagerGroupDef.nLoginGroupID)
	Procedure_SelectRole.super.End(self)
	-- SoundManager:StopBackgroundMusic()
end


function Procedure_SelectRole:HoldObject(pObject)
	if pObject then
		local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pObject)
		self.tbHolderList[nUniqueID] = luaholder(pObject)
	end
end

function Procedure_SelectRole:UnholdObject(pObject)
	if pObject then
		local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pObject)
		self.tbHolderList[nUniqueID] = nil
	end
end

function Procedure_SelectRole:LoadMontage()

	self.CameraActor = ExtendBlueprintFunctions.GetLevelActorByTag(self.pStreamingLevel, "Camera2")

	self.HumanPosActor = ExtendBlueprintFunctions.GetLevelActorByTag(self.pStreamingLevel, "Human2")
	self.ShipPosActor = ExtendBlueprintFunctions.GetLevelActorByTag(self.pStreamingLevel, "ShipActor")

	local TagsPos = {
		{ Pos = "ZoomOutFocusPositionM", Tag = "ZoomOutFocus2" },
		{ Pos = "ZoomInFocusPositionM",  Tag = "ZoomInFocus2M" },
		{ Pos = "ZoomOutFocusPositionF", Tag = "ZoomOutFocus2" },
		{ Pos = "ZoomInFocusPositionF",  Tag = "ZoomInFocus2F" },
	}
	for i,v in ipairs(TagsPos) do
		local pFocusRefActor = ExtendBlueprintFunctions.GetLevelActorByTag(self.pStreamingLevel, v.Tag)
		if pFocusRefActor then
			self[v.Pos] = pFocusRefActor:K2_GetActorLocation()
		end
	end
end

function Procedure_SelectRole:ShowUI()
	UIManager:OpenWnd(UIDef.UI_SELECT_ROLE, self.Param)
end

function Procedure_SelectRole:HideUI()
	self.pStreamingLevel = nil
	UIManager:CloseWnd(UIDef.UI_SELECT_ROLE)
end

function Procedure_SelectRole:OpenSelectRoleMap()
	if not self.pStreamingLevel then
		ClientShell.GetClient(GWorld):FlushAsyncLoading()
		SCENE_LEVEL:load()
		ClientShell.GetClient(GWorld):LoadStreamLevel(GWorld, SCENE_LEVEL)
	else
		self:PostLoadMap()
	end

end

function Procedure_SelectRole:PostLoadMap()
	if not self.pStreamingLevel then
		self.pStreamingLevel = ClientShell.GetClient(GWorld):GetStreamingLevel(GWorld, SCENE_LEVEL)
		if not self.pStreamingLevel then
			return
		end
	end
	if self.pStreamingLevelLoadedDelegate then
		self.EventHelper:UnregisterCppDelegate(self.pStreamingLevelLoadedDelegate)
		self.pStreamingLevelLoadedDelegate = nil
	end

	self:LoadMontage()

	-- local tbLoginMatinee = MatineeSystem:GetMatinee(LOGIN_MATINEE_ID)
	-- if tbLoginMatinee then
	-- 	tbLoginMatinee:StopMatinee()
	-- end

	-- tbLoginMatinee = MatineeSystem:GetMatinee(CREATE_ROLE_LOOP_FEMALE_MATINEE_ID)
	-- if tbLoginMatinee then
	-- 	tbLoginMatinee:StopMatinee()
	-- end

	-- tbLoginMatinee = MatineeSystem:GetMatinee(CREATE_ROLE_LOOP_MALE_MATINEE_ID)
	-- if tbLoginMatinee then
	-- 	tbLoginMatinee:StopMatinee()
	-- end

	MatineeSystem:Clear()
	local pController = GameplayStatics.GetPlayerController(GWorld, 0)
	pController:SetViewTargetWithBlend(self.CameraActor, 0, EViewTargetBlendFunction.VTBlend_Linear, 0, false)

	if not self.ShowUITimer then
		self.ShowUITimer = DelayTimer:DelayRun(function()
				self.ShowUITimer = nil
				self:ShowUI()
		end, 0.1)
	end
end

local function RotateCamera(self, Yaw, Pitch)
	if self.CameraWalker then
		self.CameraWalker:RotateCamera(Yaw, Pitch)
	end
end

local function ZoomCamera(self)
	if self.CameraWalker then
		local ZoomState = self.CameraWalker.ZoomStateDef
		local CurrentZoomState = self.CameraWalker:GetCurrentZoomState()
		if CurrentZoomState == ZoomState.Out then
			self.CameraWalker:ZoomCamera(ZoomState.In)
		else
			self.CameraWalker:ZoomCamera(ZoomState.Out)
		end
	end
end

function Procedure_SelectRole:BindHubMethod()
	self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_ENTER_GAME, self, self.OnEnterGame)
	self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_DELETE_ROLE, self, self.OnDeleteRole)
	self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_SELETE_ROLE, self, self.OnSelectRole)
	self.EventHelper:RegisterEvent(ClientEventDef.EV_ON_ENTER_GAME_ERROR, self, self.OnEnterGameError)
	self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_SELECT_ROLE_BACK, self, self.OnReturnBack)
	self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_ROTATER_AVATAR_SELECT_ROLE, self, RotateCamera)
	self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_ZOOM_AVATAR_SELECT_ROLE, self, ZoomCamera)
	self.pStreamingLevelLoadedDelegate = self.EventHelper:RegisterCppDelegate(ClientShell.GetClient(GWorld).OnSubLevelLoadEnd,self, self.PostLoadMap)
end

function Procedure_SelectRole:OnEnterGame(nID)
	-- if self.bSendEnterGame then
	-- 	return
	-- end
	if not self.Param or #self.Param < nID then
		return
	end
	local tbSelectRole = self.Param[nID]
	self.bSendEnterGame = true
	local Socket = NetworkManager:GetHubServerProxy()
	local c2s_EnterGame =
	{
		player_id = tbSelectRole.id,
	}
	if(not Socket:SendPacket(Proto.c2s_EnterGame, c2s_EnterGame)) then
		UIUtils.ShowToastWithKey("SEND_LOGIN_PACKET_FAILED")
		logwarning("Send login packet failed.")
	end
end

function Procedure_SelectRole:OnEnterGameError()
	self.bSendEnterGame = false
end

-- todo
function Procedure_SelectRole:OnDeleteRole(nAvatarId)
	-- local Socket = NetworkManager:GetHubServerProxy()
	-- local c2s_CreateAvatar =
	-- {
	-- 	name = szAvatarName,
	-- 	avatar_id = nAvatarId,
	-- 	skip_tutorial = bDisableGuide
	-- }
	-- if(not Socket:SendPacket(Proto.c2s_CreateAvatar, c2s_CreateAvatar)) then
	-- 	UIUtils.ShowToast("Send login packet failed.")
	-- 	logwarning("Send login packet failed.")
	-- end
end

function Procedure_SelectRole:OnSelectRole(nID)
	if not self.Param or #self.Param < nID then
		local tbParam = self.Param
		if not tbParam then
			tbParam = {}
		end
		tbParam.bFromSelecteRole = true
		ProcedureTool:EnterCreateRole(tbParam)
		return
	end
	local tbSelectRole = self.Param[nID]
	self:ShipShow(tbSelectRole.preview.ship)
	self:HumanShow(tbSelectRole.preview.human)
end

function Procedure_SelectRole:ShipShow(tbShipPreviewData)
	if self.pShipActor then
		if self.nShipID ~= tbShipPreviewData.ship_id then
			UEActorHelper:DestroyActor(self.pShipActor)
			self.pShipActor = nil
			self.pShipAvatarComponent = nil
		else
			GameAvatarHelper:UpdateShipAvatar(self.pShipAvatarComponent, tbShipPreviewData.res, tbShipPreviewData.ship_id)
			return
		end
    end
    -- self.nShipTemplateId = nShipTemplateId
	local tbShipTemplate = ShipDataTable:GetTemplate(tbShipPreviewData.ship_id)
	self.nShipID = tbShipPreviewData.ship_id
	if not tbShipTemplate then
		return
	end
	local szPawnClassName = tbShipTemplate.tbResData.szPawnClassName


    local location = self.ShipPosActor:K2_GetActorLocation()
    local rotation = self.ShipPosActor:K2_GetActorRotation()
	local _, pShip = UEActorHelper:CreateActor(szPawnClassName,location,rotation,Vector{X=1,Y=1,Z=1})

	-- pShip:K2_SetActorTransform(pTransform)
	self.pShipActor = pShip
	if not pShip or not pShip.ShipModel then
		return
	end
	if pShip.Flotage then
		pShip.Flotage.bAlwaysUpdate = true
		pShip.Flotage.ApplyTransform = true
	end
	pShip.ShipModel.ChildActor:SetExhibition(true)
	self.pShipAvatarComponent =  pShip.ShipAvatarComponent

	local szUiAnimation = tbShipTemplate.tbResData.szUiAnimation
	if szUiAnimation ~= nil then
	    pShip.ShipModel.ChildActor.SKM_ShipMaster:PlayAnimation(szUiAnimation:load(), true)
	end
	-- local ShipMovementConfig = ShipMovementConfig()
	-- ClientShell.GetClient(GWorld):GetActorShell()():InitShipMovement(pShip, false, ShipMovementConfig)
	-- ShipInit(tbShipPreviewData.ship_id, pShip)
	GameAvatarHelper:UpdateShipAvatar(self.pShipAvatarComponent, tbShipPreviewData.res, tbShipPreviewData.ship_id)
end

function Procedure_SelectRole:HumanShow(tbHumanPreviewData)
	if self.pHumanActor then
		if self.nHumanID ~= tbHumanPreviewData.avatar_id then
        	UEActorHelper:DestroyActor(self.pHumanActor)
        	self.pHumanActor = nil
			self.pHumanAvatarComponent = nil
		else
			GameAvatarHelper:UpdateHumanAvatar(self.pHumanAvatarComponent, tbHumanPreviewData.res, tbHumanPreviewData.avatar_id, true)
			return
		end
	end

	local tbHumanData = HumanDataTable:GetResData(tbHumanPreviewData.avatar_id)
	self.nHumanID = tbHumanPreviewData.avatar_id
	if not tbHumanData then
		return
	end
	local szPawnClassName = tbHumanData.szPawnClassName

    local location = self.HumanPosActor:K2_GetActorLocation()
    local rotation = self.HumanPosActor:K2_GetActorRotation()
	local _, pHuman = UEActorHelper:CreateActor(szPawnClassName,location,rotation,Vector{X=1,Y=1,Z=1})

	self.pHumanActor = pHuman
	self.pHumanAvatarComponent = pHuman.HumanAvatarComponent
	if pHuman.HumanAvatarComponent then
		pHuman.HumanAvatarComponent:SetMergeSkeletalMesh(false)
	end
	GameAvatarHelper:UpdateHumanAvatar(self.pHumanAvatarComponent, tbHumanPreviewData.res, tbHumanPreviewData.avatar_id, true)
	GameAvatarHelper:UpdataHumanAvatarState(tbHumanPreviewData.res, pHuman)

	local tbAvatar = AvatarDataTable:GetTemplate(tbHumanPreviewData.avatar_id)
	if tbAvatar.szShowAnimation then
		SelfAnimationHelper:PlayActorAnimation(pHuman,tbHumanPreviewData.avatar_id,tbAvatar.szShowAnimation)
	end

	local nGender = HumanDataTable:GetTemplate(tbHumanPreviewData.avatar_id).nGender
	if not self.CameraWalker then
		self.CameraWalker = CameraWalkerHelper()
		local InitialFocusPostion = nil
		if nGender == GenderTypeDef.MALE then
			InitialFocusPostion = self.ZoomOutFocusPositionM
		else
			InitialFocusPostion = self.ZoomOutFocusPositionF
		end
		local DirectionLight = ExtendBlueprintFunctions.GetWorldActorByName(GWorld, "Light")
		self.CameraWalker:SetCamera(self.CameraActor, DirectionLight, CreateRoleCameraIni.tbSelectRole, InitialFocusPostion)
		if nGender == GenderTypeDef.MALE then
			self.CameraWalker:SetZoomFocusPosition(self.ZoomInFocusPositionM, self.ZoomOutFocusPositionM)
		else
			self.CameraWalker:SetZoomFocusPosition(self.ZoomInFocusPositionF, self.ZoomOutFocusPositionF)
		end
	else
		if nGender == GenderTypeDef.MALE then
			self.CameraWalker:SetZoomFocusPosition(self.ZoomInFocusPositionM, self.ZoomOutFocusPositionM)
		else
			self.CameraWalker:SetZoomFocusPosition(self.ZoomInFocusPositionF, self.ZoomOutFocusPositionF)
		end
		self.CameraWalker:RestoreCamera()
	end
end


function Procedure_SelectRole:UnbindHubMethod()
	self.EventHelper:UnregisterAll()
end

function Procedure_SelectRole:OnReturnBack()
	local HubServerProxy = NetworkManager:GetHubServerProxy()
	HubServerProxy:Disconnect()
end

return Procedure_SelectRole
