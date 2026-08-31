local ClientEventDef = require("ClientEventDef")
local SelfEventHelper = require("SelfEventHelper")
local RenderTarget = require("RenderTarget")
local RenderActor = require("RenderActor")
local CppDelegate = require("CppDelegate")
local UEMapLoader = require("UEMapLoader")

local tbRenderActorLevel = {

}

local RenderTargetManager = {}

RenderTargetManager.tbRenderTargets = {}
RenderTargetManager.tbAvatarActors = {}
RenderTargetManager.EventHelper = nil
RenderTargetManager.tbLightMaps = {}

function RenderTargetManager:Init()
	if not self.EventHelper then
		self.EventHelper = SelfEventHelper()
		self.EventHelper:RegisterEvent(ClientEventDef.EV_EXIT_LOADING, self, self.OnPostLoadMap)
		self.EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_LOADING, self, self.OnPreLoadMap)
	end
end

local function Clear(self)
	for i,v in ipairs(self.tbAvatarActors) do
		v:Clear()
	end
	for i,v in ipairs(self.tbRenderTargets) do
		v:Clear()
	end	
	self.tbAvatarActors = {}
	-- self.pRenderActorMap = nil
	self.tbLightMaps = {}
	self.tbRenderTargets = {}	
end 

function RenderTargetManager:Uninit()
	if self.EventHelper then 
		self.EventHelper:UnregisterAll()
		self.EventHelper = nil
	end 
	Clear(self)
end

function RenderTargetManager:OnPreLoadMap()
	Clear(self)	
end

function RenderTargetManager:OnPostLoadMap()
	-- self.pRenderActorMap = nil
	-- self.tbAvatarActors = {}
	-- self.tbRenderTargets = {}
	-- if not self.pRenderActorMap then
	-- self.pRenderActorMap = ExtendBlueprintFunctions.LoadSubLevelDynamic(GWorld, szRenderActorLevel, Vector(), Rotator())
	-- end
	-- self:LoadLightMap()
end

function RenderTargetManager:UnLoadLightMap(nTag)
	if EngineExtShell.IsEditor() then 
		return
	end 
	local pRenderActorMap = self.tbLightMaps[nTag]
	if not pRenderActorMap then
		return
	end 
	pRenderActorMap.nRefCount = pRenderActorMap.nRefCount - 1
	if pRenderActorMap.nRefCount > 0 then 
		return
	end 
	local szRenderActorLevel = tbRenderActorLevel[nTag]
	-- ExtendBlueprintFunctions.UnloadSubLevelDynamic(GWorld, szRenderActorLevel)
	UEMapLoader:UnLoadSubLevel(szRenderActorLevel)
	self.tbLightMaps[nTag] = nil 
end 

function RenderTargetManager:LoadLightMap(nTag, bAsync, fnLoadComplete)
	local szRenderActorLevel = tbRenderActorLevel[nTag]
	local pRenderActorMap = self.tbLightMaps[nTag]
	if not pRenderActorMap then
		local LoadMapEnd = function()
			ExtendBlueprintFunctions.SetLevelClientOnlyVisible(pRenderActorMap, true)
			local pCharacterPos = ExtendBlueprintFunctions.GetLevelActorByTag(pRenderActorMap, "CharacterPos")
			local position = nil 
			if pCharacterPos.RootComponent then 
				position = pCharacterPos.RootComponent.RelativeLocation
			else 
				position = pCharacterPos:K2_GetActorLocation()
			end 
			self.tbLightMaps[nTag] =  { pMapLevel = pRenderActorMap, nRefCount = 1, CharacterPos = position}

			if self.RenderActorMapLoadedDelegate then
				self.RenderActorMapLoadedDelegate:Unbind()
			end		
			if fnLoadComplete then 
				fnLoadComplete()
			end 				
		end 
		-- szRenderActorLevel:load()
		-- local pRenderActorMap = ExtendBlueprintFunctions.LoadSublevelSyncDynamic(GWorld, szRenderActorLevel, Vector(), Rotator())
		if not bAsync then 
			pRenderActorMap = UEMapLoader:LoadSubLevelSync(szRenderActorLevel)
			if not pRenderActorMap then 
				return
			end 
			LoadMapEnd(pRenderActorMap)
		else
			pRenderActorMap = ExtendBlueprintFunctions.LoadSubLevelDynamic(GWorld, szRenderActorLevel, Vector(), Rotator()) 
			if pRenderActorMap:IsLevelLoaded() then 
				LoadMapEnd(pRenderActorMap)
			else 
				self.RenderActorMapLoadedDelegate = CppDelegate:Bind(pRenderActorMap.OnLevelLoaded, LoadMapEnd)
			end			
		end 

	else 
		if fnLoadComplete then 
			fnLoadComplete()
		end 
		pRenderActorMap.nRefCount = pRenderActorMap.nRefCount + 1
	end	
end 

function RenderTargetManager:TryGetRenderTarget(nTag, fImgWidth, fImgHeight, szInMaterial, bInOrthographic, fInOrthoWidth, bAsync, fnLoadComplete)
	local tbRenderTarget = self:GetRenderTarget(fImgWidth, fImgHeight)
	if tbRenderTarget then 
		-- self:LoadLightMap(nTag)
		if fnLoadComplete then 
			fnLoadComplete(tbRenderTarget)
		end 
		return tbRenderTarget
	end 
	tbRenderTarget = RenderTarget()
	if bAsync then 
		-- local fnLoadLightMapEnd = function()
			KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "r.Mobile.UseCachedCSM 0", nil)	
			-- local tbRenderTarget = RenderTarget()
			-- tbRenderTarget.Owner = self
			-- tbRenderTarget:Create(nTag, fInOrthoWidth, szInMaterial, bInOrthographic, fImgWidth, fImgHeight)
			-- fnLoadComplete(tbRenderTarget)
			-- tbRenderTarget = RenderTarget()
			if tbRenderTarget.nRefCount > 0 then 
				tbRenderTarget.Owner = self
				tbRenderTarget:Create(nTag, fInOrthoWidth, szInMaterial, bInOrthographic, fImgWidth, fImgHeight, fnLoadComplete)		
				table.insert( self.tbRenderTargets, tbRenderTarget)	
			end
		-- end 
		-- self:LoadLightMap(nTag, bAsync,fnLoadLightMapEnd)
	else 
		-- self:LoadLightMap(nTag)
		KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "r.Mobile.UseCachedCSM 0", nil)	
		-- local tbRenderTarget = RenderTarget()
		tbRenderTarget.Owner = self
		tbRenderTarget:Create(nTag, fInOrthoWidth, szInMaterial, bInOrthographic, fImgWidth, fImgHeight)
		table.insert( self.tbRenderTargets, tbRenderTarget)	
		if fnLoadComplete then 
			fnLoadComplete(tbRenderTarget)
		end 
	end 
	return tbRenderTarget
end


function RenderTargetManager:TryGetActor(tbRenderTarget, nActorType, pRenderTargetImgRef, szAvatarClassPath, szRecordName, pInLocation, pInRotation, pInScale, bAsync)
	if not pRenderTargetImgRef or not tbRenderTarget then
		return nil
	end
	-- local tbAvatarActor = self.tbAvatarActors[szAvatarClassPath]

	-- if not tbAvatarActor then 
		local tbAvatarActor = RenderActor()
		tbAvatarActor:Create(self, nActorType, szAvatarClassPath, szRecordName, pInLocation, pInRotation, pInScale, bAsync)
		table.insert(self.tbAvatarActors, tbAvatarActor)
		-- self.tbAvatarActors[szAvatarClassPath] = tbAvatarActor	
	-- else 
	-- 	tbAvatarActor:UnDestroy()
	-- 	tbAvatarActor.nRefCount = tbAvatarActor.nRefCount + 1
	-- end 


	tbRenderTarget:BindShowActor(pRenderTargetImgRef, tbAvatarActor)
	-- if not szRecordName then 
	-- 	local pLightMap = self.tbLightMaps[tbRenderTarget.nTag]
	-- 	tbRenderTarget.RenderTargetActor:K2_SetActorLocation(pLightMap.CharacterPos)
	-- end 
	return tbAvatarActor
end 


function RenderTargetManager:RemoveActor(tbRenderActor)
	if not tbRenderActor then 	
		return 
	end 
	for i,v in pairs(self.tbAvatarActors) do 
		if v == tbRenderActor then 
			table.remove(self.tbAvatarActors, i)
			return
		end 
	end 
	-- self.tbAvatarActors[tbRenderActor.szAvatarClassPath] = nil 
end


function RenderTargetManager:GetRenderTarget(nWidth, nHeight)
	for i,v in ipairs(self.tbRenderTargets) do
		if v.nRefCount == 0 then 
			v:ReBind(nWidth, nHeight) 
			return v
		end 
	end
	return nil
end


function RenderTargetManager:RemoveRenderTarget(tbRenderTarget)
	if not tbRenderTarget then 
		return 
	end 
	for i,v in ipairs(self.tbRenderTargets) do
		if v == tbRenderTarget then 
			table.remove( self.tbRenderTargets, i)
			break
		end 
	end
	-- self.tbRenderTargets[tbRenderTarget.nTag] = nil 
	-- self:UnLoadLightMap(tbRenderTarget.nTag)
end 


return RenderTargetManager 