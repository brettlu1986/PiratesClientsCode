--File Name    : InteractionMatinee.lua
--Author       : Zuo Kun
--Create Time  : 2017-04-11
--Description  : Matinee
-----------------------------------------------------
local luaclass = require("luaclass")
local InteractionBase = require("InteractionBase")
local InteractionMatinee = luaclass("InteractionMatinee", InteractionBase)
local InteractionDef = require("InteractionDef")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local UEClientActorHelper = require("UEClientActorHelper")
local Proto = require("ClientProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local MatineeSystem = dynamic_require("MatineeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
-- local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GameWorldSystem = require("GameWorldSystem")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local GameObjectTypeDef = require("GameObjectTypeDef")
local DelayTimer = require("DelayTimer")
local UIManager = require("UIManager")
local UIStateDef = require("UIStateDef")
local UIDef = require("UIDef")
-- 例子

InteractionMatinee.nInteractionType = InteractionDef.InteractionMode.MATINEE

InteractionMatinee.isOcean = false 
InteractionMatinee.GlobalWaveAmplitude = 0
InteractionMatinee.GlobalWaveSpeed = 0
InteractionMatinee.FollowMethod = nil
InteractionMatinee.tbPlayingMatinee = nil 
InteractionMatinee.tbPlayTimer = nil 
InteractionMatinee.nVisiblityFactor = nil

function InteractionMatinee:Init(Owner)
    InteractionMatinee.super.Init(self, Owner)
    self.nVisiblityFactor = UEClientActorHelper:AllocateObjectVisiblityFactor()
end 

function InteractionMatinee:OnInteractionEnd()
    self.nVisiblityFactor = nil
    InteractionMatinee.super.OnInteractionEnd(self)
end

function InteractionMatinee:DoInteraction(tbSelectedNpc, tbParams)
	InteractionMatinee.super.DoInteraction(self, tbSelectedNpc, tbParams)
	-- UIManager:OpenWnd(UIDef.UI_INTERACTION, {tbSelectedNpc = tbSelectedNpc, tbParams = tbParams, bIsShowAvatar = false})
	if tbParams.nID == nil then
		EventManager:OnFireEvent(ClientEventDef.EV_INTERACTION_END)
		return
	end

	self:StopMove()

	-- UIManager:CloseWnd(UIDef.UI_MAIN)
	local World = GameWorldSystem:GetWorld()
	if World then 
    	self.isOcean = World:IsOcean()
	end 
	if not self.isOcean and GlobalVariableSystem:IsInDungeon() then 
		self.isOcean = true
	end 
	GlobalVariableSystem_C.bShowCharacter = false
	-- local PlayerSelf = GamePlayerSelfHelper:Get()
	-- if PlayerSelf then 
	-- 	local pUEActor = GamePlayerSelfHelper:Get():GetModelActor()
	-- 	if pUEActor then 
	-- 		if self.isOcean then 
	-- 			if pUEActor.BuoyancyForce then 
	-- 				local OceanManager = pUEActor.BuoyancyForce.OceanManager
	-- 				if OceanManager then 
	-- 					local savaInfiniteSystemComponent = OceanManager:GetComponentByClass(InfiniteComponent)
	-- 					self.GlobalWaveAmplitude = OceanManager.GlobalWaveAmplitude
	-- 					self.GlobalWaveSpeed = OceanManager.GlobalWaveSpeed
	-- 					self.FollowMethod = savaInfiniteSystemComponent.FollowMethod
	-- 				end 
	-- 			end 
	-- 		end 
	-- 	end 
	-- end 

	local function OnEnd(tbMatinee)
		self:OnMatineeEnd(tbMatinee)
	end 

	local function OnPlay(tbMatinee)
		self:CloseAllUI()
		local tbTypes = {}
		tbTypes[GameObjectTypeDef.PlayerSelf] = true
		tbTypes[GameObjectTypeDef.PlayerOther] = true
		tbTypes[GameObjectTypeDef.Trigger] = true
		tbTypes[GameObjectTypeDef.Dummy] = true
		tbTypes[GameObjectTypeDef.Npc] = true
		tbTypes[GameObjectTypeDef.AtmoSphereNpc] = true
		local BlockActos = ExtendBlueprintFunctions.GetLevelActorsByTag(GWorld, "BlockActor")	
		if BlockActos then 
			for i,v in ipairs(BlockActos) do
				v:SetActorHiddenInGame(true)
			end
		end 
	
	    UEClientActorHelper:SetAllObjectVisibilityFactor(self.nVisiblityFactor, tbTypes, false)
		-- UEClientActorHelper:SetPlayerVisible(tbTypes, false)
		-- SoundManager:PauseBackgroundMusic(true)
	
		-- self:SetAllNpcHeadInfoVisible( false)
		self.tbPlayTimer = DelayTimer:RunNextTick(function()
			self.tbPlayTimer = nil 
			
            local tbOpenArgs = {}
            tbOpenArgs.fnMethod = function() self:OnStopMatinee() end
            UIManager:OpenWnd(UIDef.UI_MATINEE_PANEL, tbOpenArgs)
		end)		
	end 
	self.tbPlayingMatinee = MatineeSystem:PlayMatinee(tbParams.nID, tbParams.bLoop, OnEnd, OnPlay)
	if not self.tbPlayingMatinee then 
		EventManager:OnFireEvent(ClientEventDef.EV_INTERACTION_END)
	end 
end

function InteractionMatinee:StopPlayMatinee()
	if self.tbPlayingMatinee then 
		self.tbPlayingMatinee:StopMatinee()
	end 
end

function InteractionMatinee:OnMatineeEnd()
	if self.tbPlayingMatinee then 
		UIManager:CloseWnd(UIDef.UI_MATINEE_PANEL)
		self.tbPlayingMatinee = nil
		EventManager:OnFireEvent(ClientEventDef.EV_INTERACTION_END)
	end 
end

function InteractionMatinee:OnInteractionEnd()
	if self.tbPlayTimer then 
		DelayTimer:ClearTimer(self.tbPlayTimer)
		self.tbPlayTimer = nil 
	end 
	GlobalVariableSystem_C.bShowCharacter = true
	-- local PlayerSelf = GamePlayerSelfHelper:Get()
	-- if PlayerSelf then 
	-- 	local pUEActor = GamePlayerSelfHelper:Get():GetModelActor()
	-- 	if pUEActor then 
	-- 		if self.isOcean then 
	-- 			if pUEActor.BuoyancyForce then 
	-- 				local OceanManager = pUEActor.BuoyancyForce.OceanManager
	-- 				if OceanManager then 
	-- 					local savaInfiniteSystemComponent = OceanManager:GetComponentByClass(InfiniteComponent)
	-- 					if savaInfiniteSystemComponent then 
	-- 						-- logdebug(" old ".. OceanManager.GlobalWaveAmplitude .. " new " .. self.GlobalWaveAmplitude)
	-- 						OceanManager.GlobalWaveAmplitude = self.GlobalWaveAmplitude 
	-- 						OceanManager.GlobalWaveSpeed = self.GlobalWaveSpeed
	-- 						savaInfiniteSystemComponent.FollowMethod = self.FollowMethod
	-- 						OceanManager:UpdateDisplay()
	-- 					end 
	-- 				end 
	-- 			end 
	-- 		end 
	-- 	end 
	-- end 

	-- UIManager:OpenWnd(UIDef.UI_MAIN)
	-- SoundManager:PauseBackgroundMusic(false)
	local tbTypes = {}
	tbTypes[GameObjectTypeDef.PlayerSelf] = true
	tbTypes[GameObjectTypeDef.PlayerOther] = true
	tbTypes[GameObjectTypeDef.Trigger] = true	
	tbTypes[GameObjectTypeDef.Dummy] = true
	tbTypes[GameObjectTypeDef.Npc] = true
	tbTypes[GameObjectTypeDef.AtmoSphereNpc] = true
    UEClientActorHelper:SetAllObjectVisibilityFactor(self.nVisiblityFactor, tbTypes, true)
	-- UEClientActorHelper:SetPlayerVisible(tbTypes, true)
	local BlockActos = ExtendBlueprintFunctions.GetLevelActorsByTag(GWorld, "BlockActor")	
	if BlockActos then 
		for i,v in ipairs(BlockActos) do
			v:SetActorHiddenInGame(false)
		end
	end 	
	if self.bNeedSendToServerOnEnd then
		NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_MatineeEnd)
	end
	
	-- self:SetAllNpcHeadInfoVisible(true)
end

function InteractionMatinee:CloseAllUI()
    -- logdebug("InteractionBase:CloseAllUI,self.bUseUIState="..tostring(self.bUseUIState))
    if self.bControlUIByState then 
        UIManager:PushState(UIStateDef.StateName.UI_MATINEE_STATE, nil)
    end
end

return InteractionMatinee 