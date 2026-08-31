-----------------------------------------------------
--File Name    : CameraShotSystem.lua
--Author       : Zhang Yuzhen
--Create Time  : 2017-09-14
--Description  : 拍照活动
-----------------------------------------------------

local SceneDataTable = require("SceneDataTable")
local GameWorldSystem = require("GameWorldSystem")
local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local CommonEventDef = require("CommonEventDef")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")


local CameraShotSystem = {}
CameraShotSystem.bActiveShotTarget = false
CameraShotSystem.bInValidArea = false
CameraShotSystem.tbJsonTableFileList = {}

CameraShotSystem.tbShotTarget = {}
CameraShotSystem.nAreaID = nil
CameraShotSystem.tbAreaInfo = nil


local function GetCameraShotJson(self, nSceneId)
	local tbJsonTableFile = self.tbJsonTableFileList[nSceneId]
	if not tbJsonTableFile then
		-- logdebug("GetCameraShotJson()  nSceneId:" .. nSceneId)
		local tbDescriptor = SceneDataTable:GetDescriptor(nSceneId)
		if tbDescriptor == nil then
			logerror("descriptor is nil, scene id :", nSceneId)
			return nil
		end
		local tbCameraShotTriggers = tbDescriptor.tbCameraShotTriggers

		if tbCameraShotTriggers ~= nil then 
			tbJsonTableFile = {}
			tbJsonTableFile.tbContainer ={}
			tbJsonTableFile.tbContainer.CameraShotTriggers = tbCameraShotTriggers
			self.tbJsonTableFileList[nSceneId] = tbJsonTableFile
		else
			logerror("GetCameraShotJson() failed, invalid scene res" .. nSceneId)
		end
	end

	return tbJsonTableFile
end

local function ActiveShotScene(self)
	if self.tbAreaInfo then
		return
	end

	local Triggers, nNewAreaID
	local pTriggerManager = CommonShell.GetCommon(GWorld):GetAreaTriggerManager()
	local nCurrentSceneId = GameWorldSystem:GetWorld().nSceneId
	for _, v in ipairs(self.tbShotTarget) do
		if v[1] == nCurrentSceneId then
			local tbJsonTableFile = GetCameraShotJson(self, nCurrentSceneId)
			if tbJsonTableFile then
				Triggers = tbJsonTableFile.tbContainer.CameraShotTriggers
				for _, v1 in pairs(Triggers) do
					if v1.TargetId == v[2] then
						for _, v2 in pairs(v1.Triggers) do
							nNewAreaID = pTriggerManager:Create2DArea(v2.X, v2.Y, v2.Radius)
							if not self.tbAreaInfo then
								self.tbAreaInfo = {}
							end
							self.tbAreaInfo[nNewAreaID] = v1
						end
					end
				end

				local PlayerSelf = GamePlayerSelfHelper:Get()
				pTriggerManager:AddActor(PlayerSelf.pUEActor)
			end
			break
		end
	end
end

local function InactiveShotScene(self)
	if self.tbAreaInfo then
		local pTriggerManager = CommonShell.GetCommon(GWorld):GetAreaTriggerManager()
		for k, _ in pairs(self.tbAreaInfo) do 
			pTriggerManager:Destroy2DArea(k)
		end
		self.tbAreaInfo = nil
		self.nAreaID = nil
		self.bActiveShotTarget = false
		self.bInValidArea = false
	end
end

local function OnShotSuccess(self)
	if self.bInValidArea and self.bActiveShotTarget then
		local tbTrigger = self.tbAreaInfo[self.nAreaID]
		local Socket = NetworkManager:GetHubServerProxy()
		local c2s_CameraShot = {
			scene_id = tbTrigger.SceneId,
			target_id = tbTrigger.TargetId,
		}
		if not Socket:SendPacket(Proto.c2s_CameraShot, c2s_CameraShot) then
			logwarning("Send c2s_CameraShot failed")
		end

		self.bInValidArea = false
		self.nAreaID = nil
	end
end

local function OnCheckEnterShotMode(self, tbData)
	if tbData and tbData.nTag == 7 and self.bInValidArea then
        EventManager:OnFireEvent(ClientEventDef.EV_SHOT_ENTER_CAMERA_MODE)
    end
end

local function OnEnterScene(self)
	ActiveShotScene(self)
end

local function OnLeaveScene(self)
	InactiveShotScene(self)
end

function CameraShotSystem:ReceiveActiveCameraShot(tbPacket)
	local nSceneId = tbPacket.scene_id
	local nTargetId = tbPacket.target_id

	local bExit = false
	for _, v in ipairs(self.tbShotTarget) do
		if v[1] == nSceneId and v[2] == nTargetId then
			bExit = true
			break
		end
	end
	
	if not bExit then
		table.insert(self.tbShotTarget, {nSceneId, nTargetId})
	end

	ActiveShotScene(self)
end

function CameraShotSystem:ReceiveInActiveCameraShot(tbPacket)
	local nSceneId = tbPacket.scene_id
	local nTargetId = tbPacket.target_id

	local bExit = false
	for k, v in ipairs(self.tbShotTarget) do
		if v[1] == nSceneId and v[2] == nTargetId then
			bExit = true
			table.remove(self.tbShotTarget, k)
			break
		end
	end
	if bExit == false then
		logwarning("ReceiveInActiveCameraShot assert failed, data is not exist.")
	end
	InactiveShotScene(self)
end

function CameraShotSystem:ReceiveCameraShotResponce(tbPacket)
	local nCode = tbPacket.return_code
	if nCode == Proto.ReturnCode.OK then
		UIUtils.ShowToast(UITextDef.CAMERA_SHOT_SUCCESS)
	else
		error("CameraShotSystem:ReceiveCameraShotResponce() failed")
	end
end

function CameraShotSystem:Init()
	local EventHelper = SelfEventHelper()
	self.EventHelper = EventHelper
	EventHelper:RegisterEventFunc(ClientEventDef.EV_PLAYERSELF_READY, function() OnEnterScene(self) end)
	EventHelper:RegisterEventFunc(ClientEventDef.EV_LEAVE_PROCEDURE_WILD, function() OnLeaveScene(self) end)
	EventHelper:RegisterEventFunc(ClientEventDef.EV_SHOT_CAMERA_SHOT_SUCCESS, function() OnShotSuccess(self) end)
	EventHelper:RegisterEventFunc(ClientEventDef.EV_ON_UP_MAIN_QUEST_ITEM_CLICK, function(tbData) OnCheckEnterShotMode(self, tbData) end)

	EventHelper:RegisterEvent(CommonEventDef.EV_GAME_AREA_ENTER, self, self.OnActorEnterArea)
	EventHelper:RegisterEvent(CommonEventDef.EV_GAME_AREA_LEAVE, self, self.OnActorLeaveArea)
end

function CameraShotSystem:Uninit()
	if self.EventHelper then 
		self.EventHelper:UnregisterAll()
		self.EventHelper = nil
	end 
end

function CameraShotSystem:OnActorEnterArea(tbGameObject, nAreaID)
	-- logdebug("CameraShotSystem:OnActorEnterArea() nAreaID:" .. nAreaID)
	local PlayerSelf = GamePlayerSelfHelper:Get()
	if PlayerSelf then
		if self.tbAreaInfo and self.tbAreaInfo[nAreaID] and tbGameObject == PlayerSelf then
			self.bInValidArea = true
			self.nAreaID = nAreaID
			EventManager:OnFireEvent(ClientEventDef.EV_SHOT_ENTER_CAMERA_MODE)
		end
	end
end 
 
function CameraShotSystem:OnActorLeaveArea(tbGameObject, nAreaID)
	-- logdebug("CameraShotSystem:OnActorLeaveArea() nAreaID:" .. nAreaID)
	local PlayerSelf = GamePlayerSelfHelper:Get()
	if PlayerSelf then
		if self.tbAreaInfo and self.tbAreaInfo[nAreaID] and tbGameObject == PlayerSelf then
			self.bInValidArea = false
			self.nAreaID = nil
			EventManager:OnFireEvent(ClientEventDef.EV_SHOT_AUTO_LEAVE_CAMERA_MODE)
		end
	end
end 

function CameraShotSystem:IsInValidArea()
	return self.bInValidArea
end

function CameraShotSystem:SetActiveShotTarget(bActive)
	self.bActiveShotTarget = bActive
end

function CameraShotSystem:GetShotAimPos()
	return self.tbAreaInfo[self.nAreaID].TargetPos
end

function CameraShotSystem:GetTargetName(nSceneId, nTargetId)
	local tbJsonTableFile = GetCameraShotJson(self, nSceneId)
	if tbJsonTableFile then
		local Triggers = tbJsonTableFile.tbContainer.CameraShotTriggers
		for _, v in pairs(Triggers) do
			if v.TargetId == nTargetId then
				return v.TargetName
			end
		end
	end

	return nil
end

function CameraShotSystem:GetCurrentTargetName()
	local nAreaID = self.nAreaID
	local tbAreaInfo = self.tbAreaInfo
	if tbAreaInfo and nAreaID and tbAreaInfo[nAreaID] then
		local tbTrigger = tbAreaInfo[nAreaID]
		return self:GetTargetName(tbTrigger.SceneId, tbTrigger.TargetId)
	end
	return nil
end


return CameraShotSystem 