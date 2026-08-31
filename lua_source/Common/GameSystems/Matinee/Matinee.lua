--File Name    : Matinee.lua
--Author       : Zuo Kun
--Create Time  : 2017-06-09
--Description  : Matinee
-----------------------------------------------------
local SelfEventHelper = require("SelfEventHelper")
local luaclass = require("luaclass")
local MatineeDataTable = require("MatineeDataTable")
local LuaDelegate = require("LuaDelegate")
local UEActorHelper = require("UEActorHelper")
local CppDelegate = require("CppDelegate")
local Matinee = luaclass("Matinee")

local OCEAN_PATH_CLASS = '/Game/Resources/Scenes/Ocean2/Blueprint/BP_OceanSystem.BP_OceanSystem_C'
Matinee.EventHelper = nil
Matinee.szLevelName = ""
Matinee.tbMatineeData = nil

Matinee.pLevelDelegate = nil
Matinee.pLevelSequencePlayer = nil
Matinee.OnComplete = nil
Matinee.OnPlay = nil
Matinee.nID = 0
Matinee.bLoop = false 
Matinee.pOcean = nil 
Matinee.nDebugWaveHeightScale = 0 
Matinee.nDebugWaveChoppyScale = 0 
Matinee.bFlotage = false 
Matinee.bReverse = false

function Matinee:Create(nID, bLoop, fnOnComplete, fnOnPlay, bReverse)
	log("[Matinee] Play Matinee", nID)
	self.nID = nID
	self.bLoop = bLoop	
	self.EventHelper = SelfEventHelper()
	self.tbMatineeData = MatineeDataTable:GetTemplate(nID)
	self.OnComplete = LuaDelegate()
	self.OnPlay = LuaDelegate()
	self.bReverse = bReverse
	if self.tbMatineeData == nil then
		logwarning("Error Matinee ID " .. nID)
		return false
	end
	if fnOnComplete then 
		self.OnComplete:Bind(fnOnComplete)
	end 
	if fnOnPlay then 
		self.OnPlay:Bind(fnOnPlay)
	end 
	
	if self.tbMatineeData.bUseOcean then 
		local Oceans = GameplayStatics.GetAllActorsOfClass(GWorld, OCEAN_PATH_CLASS:load())
		if Oceans and #Oceans >= 1 then 
			self.pOcean = Oceans[1]
			self.nDebugWaveHeightScale = self.pOcean.DebugWaveHeightScale
			self.nDebugWaveChoppyScale = self.pOcean.DebugWaveChoppyScale
			self.bFlotage = self.pOcean.bFlotage
			self.pOcean.DebugWaveHeightScale = self.tbMatineeData.nWaveHeight
			self.pOcean.DebugWaveChoppyScale = self.tbMatineeData.nWaveChoppy
			self.pOcean.bFlotage = true
			-- self.pOcean:SetActorHiddenInGame(true)
		end 		
	end 
	self:LoadLevel()

	return true
end

function Matinee:Destroy()
	if self.EventHelper then 
		self.EventHelper:UnregisterAll()
		self.EventHelper = nil	
	end 	
	if self.OnComplete then
		-- OnComplete.Unbind(self.fnOnComplete)
		self.OnComplete:UnbindAll()
		self.OnComplete = nil 
	end	
	self:StopMatinee()
end 

function Matinee:LoadLevel()
	if(self.tbMatineeData.szLevelPath == nil or self.tbMatineeData.szLevelPath == "") then
		self:PlayMatinee()
		return
	end
	log('[Matinee] : load level,  leve path=' .. tostring(self.tbMatineeData.szLevelPath))
	-- self:PlayMatinee()
	local szReverse = string.reverse(self.tbMatineeData.szLevelPath)
	local nStart, _ = string.find(szReverse, "/", 1, true)
	self.szLevelName = string.reverse(string.sub(szReverse, 1, nStart - 1))

	-- local pDelegateLevel = EngineExtShell.Get(GWorld):GetKMDelegateManager().Level
	-- self.pLevelDelegate = self.EventHelper:RegisterCppDelegate(pDelegateLevel.OnLevelAddedToWorld, self, self.LevelBeginPlay)
	self.pMatineeLevel = ExtendBlueprintFunctions.LoadSubLevelDynamic(GWorld, self.tbMatineeData.szLevelPath, Vector(), Rotator())
	local Func = function()
		if self.pMatineeLevel then
			ExtendBlueprintFunctions.SetLevelClientOnlyVisible(self.pMatineeLevel, true)
			self:PlayMatinee()
			if self.MatineeLevelLoadedDelegate then
				self.MatineeLevelLoadedDelegate:Unbind()
				self.MatineeLevelLoadedDelegate = nil 
			end
		end
	end
	if self.MatineeLevelLoadedDelegate then 
		self.MatineeLevelLoadedDelegate:Unbind()
		self.MatineeLevelLoadedDelegate = nil 
	end 
	if self.pMatineeLevel then 
		if self.pMatineeLevel:IsLevelLoaded() then 
			Func()
		else 
			self.MatineeLevelLoadedDelegate = CppDelegate:Bind(self.pMatineeLevel.OnLevelLoaded, Func)	
		end 
	end 
end

function Matinee:UnloadLevel()
	if(self.tbMatineeData.szLevelPath == nil or self.tbMatineeData.szLevelPath == "") then
		return
	end
	log('[Matinee] : unload level, name:', self.tbMatineeData.szLevelPath)
	ExtendBlueprintFunctions.UnloadSubLevelDynamic(GWorld, self.tbMatineeData.szLevelPath)
	-- self.tbMatineeData.szLevelPath = nil
end


--[[function Matinee:LevelBeginPlay(pLevelActor)
	local szLevelName = ""
	if(pLevelActor.GetLevelName ~= nil) then
		szLevelName = pLevelActor:GetLevelName()
	end
	--logwarning("SelfLevelHelper:LevelBeginPlay,szLevelName="..tostring(szLevelName).." self.szLevelName="..tostring(self.szLevelName).." pLevelActor.GetLevelName="..tostring(pLevelActor.GetLevelName))
	if self.szLevelName ~= szLevelName then
		logdebug(szLevelName)
		return
	end
	
	if self.pLevelDelegate then
		self.pLevelDelegate:Unbind()
		self.pLevelDelegate = nil
	end
	
	self:PlayMatinee()
end]]

function Matinee:GetMatineeRes()
	return self.tbMatineeData.szMaleRes
end 

function Matinee:PlayMatinee()
	local szRes = self:GetMatineeRes()
	log("[matinee] Matinee OnPlay id ", self.nID, szRes)

	local pSetting = MovieSceneSequencePlaybackSettings()
	self.pLevelSequencePlayer = LevelSequencePlayer.CreateLevelSequencePlayer(GWorld, szRes:load(), pSetting)
	if not self.pLevelSequencePlayer then 
		logwarning("[matinee] Matinee not create levelsequencePlayer")
		return 
	end 
	local pActor = ExtendBlueprintFunctions.GetSequenceActorFromPlayer(self.pLevelSequencePlayer)
	if pActor then 
		pActor:SetTickableWhenPaused(true)
	end 

	self.EventHelper:RegisterCppDelegate(self.pLevelSequencePlayer.OnFinished, self, self.OnMatineeEnd)
	self.EventHelper:RegisterCppDelegate(self.pLevelSequencePlayer.OnStop, self, self.OnMatineeEnd)
	self.EventHelper:RegisterCppDelegate(self.pLevelSequencePlayer.OnLoopStart, self, self.OnLoopStart)
	-- self.EventHelper:RegisterCppDelegate(self.pLevelSequencePlayer.OnStop, self, self.OnMatineeStop)
	if self.tbMatineeData.nCinematicMode > 0 then
		local pPlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
		if pPlayerController then
			pPlayerController:SetCinematicMode(true, false, false, false, false)
		end
	end
	if self.bLoop then 
		self.pLevelSequencePlayer:PlayLooping(-1)
	elseif self.bReverse then
		self.pLevelSequencePlayer.TimeCursorPosition = self.pLevelSequencePlayer:GetLength()
		self.pLevelSequencePlayer:PlayReverse()
	else 
		self.pLevelSequencePlayer:Play()
	end 
	self:OnPlayMatinee(self.pLevelSequenceActor)
	if self.OnPlay then
		self.OnPlay:Fire(self)
		self.OnPlay:UnbindAll()
		self.OnPlay = nil 
	end	
end

function Matinee:OnPlayMatinee(pLevelSequenceActor)
end 

local function Clear(self)
	if self.pOcean then 
		-- self.pOcean:SetActorHiddenInGame(false)
		self.pOcean.DebugWaveHeightScale = self.nDebugWaveHeightScale
		self.pOcean.DebugWaveChoppyScale = self.nDebugWaveChoppyScale		
		self.pOcean.bFlotage = self.bFlotage
		self.pOcean = nil 
	end 		
	if self.MatineeLevelLoadedDelegate then 
		self.MatineeLevelLoadedDelegate:Unbind()
		self.MatineeLevelLoadedDelegate = nil 
	end 
	if self.EventHelper then 
		self.EventHelper:UnregisterAll()
		self.EventHelper = nil	
	end 	
	local pActor = ExtendBlueprintFunctions.GetSequenceActorFromPlayer(self.pLevelSequencePlayer)
	UEActorHelper:DestroyActor(pActor)
	self.pLevelSequencePlayer = nil
	if self.tbMatineeData.nCinematicMode > 0 then
		local pPlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
		if pPlayerController then
			pPlayerController:SetCinematicMode(false, false, false, false, false)
		end
	end
		
	self:UnloadLevel()

	if self.OnComplete then
		self.OnComplete:Fire(self)
		-- OnComplete.Unbind(self.fnOnComplete)
		self.OnComplete:UnbindAll()
		self.OnComplete = nil 
	end
end 


function Matinee:StopMatinee()
	log("[matinee] Stop Matinee", self.nID)
	if self.pOcean then 
		self.pOcean.DebugWaveHeightScale = self.nDebugWaveHeightScale
		self.pOcean.DebugWaveChoppyScale = self.nDebugWaveChoppyScale	
		self.pOcean.bFlotage = self.bFlotage		
		-- self.pOcean:SetActorHiddenInGame(false)
		self.pOcean = nil 
	end 	
	if not self.pLevelSequencePlayer then 
		return 
	end
	if not isvalidhandle(self.pLevelSequencePlayer) then 
		error("[Matinee] Valid SequencePlayer")
		return 
	end 	
	self.pLevelSequencePlayer:Stop()
	self:OnMatineeEnd()
end

function Matinee:OnMatineeStop()
	log("[matinee] OnMatineeStop ", self.nID)
	self:OnMatineeEnd()
end 

function Matinee:Pause()
	if self.pLevelSequencePlayer ~= nil then
		self.pLevelSequencePlayer:Pause()
	end
end

function Matinee:OnMatineeEnd()
	Clear(self)
end

function Matinee:OnLoopStart()
end 


function Matinee:ReplaceMatineeActor(szSrcActorName, szTargetActorClassName)

end 

return Matinee

