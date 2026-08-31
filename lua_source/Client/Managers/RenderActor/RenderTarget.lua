-----------------------------------------------------
--File Name    : RenderTarget.lua
--Author       : Zuo Kun
--Create Time  : 2017-06-17
--Description  : RenderTarget
-----------------------------------------------------
local luaclass = require("luaclass")
local UEActorHelper = require("UEActorHelper")
local ResourceManager = require("ResourceManager")
local RenderTarget = luaclass("RenderTarget")
local LuaDelegate = require("LuaDelegate")
local DelayTimer = require("DelayTimer")

local fDefaultSize = 1024
local fDefaultOrthoWidth = 1024
local DELAY_DELETE_TIME = 60

RenderTarget.RenderTargetActor = nil
RenderTarget.nTag = 0
RenderTarget.nRefCount = 1
RenderTarget.Owner = nil
RenderTarget.pMaterial = nil
RenderTarget.pRenderTargetImgRef = nil
RenderTarget.bInvalid = false
RenderTarget.OnLoadComplete = nil
RenderTarget.nWidth = nil
RenderTarget.nHeight = nil
RenderTarget.pLoadHandler = nil

local szRenderActorClassPath = "/Game/Framework/Character/BP_RenderActor.BP_RenderActor_C"
local szDefaultRenderActorMaterial = "/Game/UI/Materials/M_RenderTarget_UI.M_RenderTarget_UI"
local pDefaultLocation = Vector {X = 10000, Y = 10000, Z = 1000}
local pDefaultRotation = Rotator {Pitch = 0, Yaw = 0, Roll = 0}
local function LoadComplete(self, szInMaterial, fInOrthoWidth, bInOrthographic)
	local _, pRenderTargetActor = UEActorHelper:CreateActor(szRenderActorClassPath, pDefaultLocation, pDefaultRotation)
	if not pRenderTargetActor then
		return nil
	end

	local szMaterial =(szInMaterial == nil) and szDefaultRenderActorMaterial or szInMaterial
	local fOrthoWidth =(fInOrthoWidth == nil) and fDefaultOrthoWidth or fInOrthoWidth
	local bOrthographic =(bInOrthographic ~= nil) and bInOrthographic or false

	pRenderTargetActor:CreateRenderActor(self.nWidth, self.nHeight, szMaterial:load(), fOrthoWidth, bOrthographic)
	if not self.pMaterial then
		self.pMaterial = pRenderTargetActor:GetRenderMaterial()
	end
	self.RenderTargetActor = pRenderTargetActor

	if self.OnLoadComplete then
		self.OnLoadComplete:Fire(self)
		self.OnLoadComplete:UnbindAll()
	end
end

function RenderTarget:Create(nTag, fInOrthoWidth, szInMaterial, bInOrthographic, fImgWidth, fImgHeight, fnOnLoadComplete)
	self.OnLoadComplete = LuaDelegate()

	self.nWidth = fDefaultSize
	self.nHeight = fDefaultSize

	if fImgWidth and fImgHeight then
		self.nWidth = fImgWidth
		self.nHeight = fImgHeight
	end

    self.nTag = nTag
	self.nRefCount = 1

	if fnOnLoadComplete then
		self.OnLoadComplete:Bind(fnOnLoadComplete)
		local fnOnLoadEnd = function(szAssetName, pObject, nHandle)
			self.pLoadHandler = nil
			LoadComplete(self, szInMaterial, fInOrthoWidth, bInOrthographic)
		end
		self.pLoadHandler = ResourceManager:LoadAsync(szRenderActorClassPath,fnOnLoadEnd)
	else
		 LoadComplete(self, szInMaterial, fInOrthoWidth, bInOrthographic)
	end
end

function RenderTarget:ReBind(nWidth, nHeight)
	local bNeedResize = false
	if nWidth and nHeight then
		if self.nWidth ~= nWidth or self.nHeight ~= nHeight then
			self.nWidth = nWidth
			self.nHeight = nHeight
			bNeedResize = true
		end
	else
		if self.nWidth ~= fDefaultSize or self.nHeight ~= fDefaultSize then
			self.nWidth = fDefaultSize
			self.nHeight = fDefaultSize
			bNeedResize = true
		end
	end
	self.RenderTargetActor:K2_SetActorLocation(pDefaultLocation)
	self.RenderTargetActor:K2_SetActorRotation(pDefaultRotation)

	self.nRefCount = 1
	if bNeedResize then
		self.RenderTargetActor:ReCreateTexture(self.nWidth, self.nHeight)
		self.pMaterial = nil
		if self.RenderTargetActor.MatInstance then
			self.pMaterial = self.RenderTargetActor.MatInstance
		end
	else
		self.RenderTargetActor:ReBindTexture()
	end
	if self.tbDeleteTimerHandler then
		DelayTimer:ClearTimer(self.tbDeleteTimerHandler)
		self.tbDeleteTimerHandler = nil
	end
end

function RenderTarget:Clear()
	if self.tbDeleteTimerHandler then
		DelayTimer:ClearTimer(self.tbDeleteTimerHandler)
		self.tbDeleteTimerHandler = nil
	end
	if self.OnLoadComplete then
		self.OnLoadComplete:UnbindAll()
	end
	if self.pLoadHandler then
		ResourceManager:CancelLoadAsync(self.pLoadHandler)
	end
	if self.RenderTargetActor and isvalidhandle(self.RenderTargetActor) then
		UEActorHelper:DestroyActor(self.RenderTargetActor)
		self.RenderTargetActor = nil
	end
end

function RenderTarget:Destroy()
	self.nRefCount = 0
	if self.OnLoadComplete then
		self.OnLoadComplete:UnbindAll()
	end

	if self.pRenderTargetImgRef then
		self.pRenderTargetImgRef:SetBrushFromMaterial(nil)
		self.pRenderTargetImgRef = nil
	end

	if self.pLoadHandler then
		ResourceManager:CancelLoadAsync(self.pLoadHandler)
		self.pLoadHandler = nil
		if self.Owner then
			self.Owner:RemoveRenderTarget(self)
		end
		return
	end
	if self.RenderTargetActor then
		self.RenderTargetActor:ClearRenderTarget()
		if self.tbDeleteTimerHandler then
			DelayTimer:ClearTimer(self.tbDeleteTimerHandler)
			self.tbDeleteTimerHandler = nil
		end
		self.tbDeleteTimerHandler = DelayTimer:DelayRun(function()
			self.tbDeleteTimerHandler = nil
			log("RenderTarget Start Destroy RenderTarget")
			UEActorHelper:DestroyActor(self.RenderTargetActor)
			log("RenderTarget End Destroy RenderTarget")

			self.RenderTargetActor = nil
			if self.Owner then
				self.Owner:RemoveRenderTarget(self)
			end
		end, DELAY_DELETE_TIME)
	end
end

function RenderTarget:RefeshShowActor(pUEActor)
	if pUEActor then
		self.RenderTargetActor:SetShowActor( pUEActor)
	end
end

function RenderTarget:BindShowActor(pRenderTargetImgRef, tbRenderActor)
	if not tbRenderActor or not tbRenderActor.pUEActor then
		return
	end
	if not self.pMaterial then
		self.pMaterial = self.RenderTargetActor:GetRenderMaterial()
	end
	if self.pRenderTargetImgRef then
		self.pRenderTargetImgRef:SetBrushFromMaterial(nil)
		self.pRenderTargetImgRef = nil
	end
	self.pRenderTargetImgRef = pRenderTargetImgRef
	pRenderTargetImgRef:SetBrushFromMaterial(self.pMaterial)
	self:RefeshShowActor(tbRenderActor.pUEActor)
	self:ChangeRenderTargetByRecord(tbRenderActor.SceneCaptureRecord)
end

function RenderTarget:ChangeRenderTarget(inOrthoWidth, inFov, eOrthographic)
	local isOrthographic = true
	if eOrthographic ~= ECameraProjectionMode.Orthographic then
		isOrthographic = false
	end
	self.RenderTargetActor:ChangeRenderActor(inOrthoWidth, inFov, isOrthographic)
end

function RenderTarget:ChangeRenderTargetByRecord(pCaptureRecord)
    if not pCaptureRecord then
        return
	end
	self.RenderTargetActor:K2_SetActorTransform(pCaptureRecord.pTransform)
	self:ChangeRenderTarget(pCaptureRecord.OrthoWidth, pCaptureRecord.FOVAngle, pCaptureRecord.ProjectionType)
end

function RenderTarget:GetTransform()
    if not self.RenderTargetActor then
        return
    end

	return self.RenderTargetActor:GetTransform()
end

return RenderTarget