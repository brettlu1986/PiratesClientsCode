-----------------------------------------------------
--File Name    : LobbySubLevelHelper.lua
--Author       : Ran Jie
--Create Time  : 2020-04-26
--Description  : 大厅子关卡加载帮助类
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbySubLevelHelper = luaclass("LobbySubLevelHelper")

local LobbySubLevelDataTable = require("LobbySubLevelDataTable")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local LobbyFOVLockHelper = require("LobbyFOVLockHelper")


local FUNC_LOAD_MULTI_ASSET_ASYNC_CALLBACK_FIRE = EngineExtShell.LoadMultiAssetsAsyncCallbackFire
local TEMP_LOCATION = Vector()
local TEMP_ROTATION = Rotator()
local RENDER_PARAM_TAG = "RPOW"


LobbySubLevelHelper.pDelegate = nil
LobbySubLevelHelper.nDelegateHandle = nil
LobbySubLevelHelper.bAsync = nil
LobbySubLevelHelper.tbLevelStream = nil
LobbySubLevelHelper.tbSubLevelWaitForLoad = nil
LobbySubLevelHelper.fnLoadedCallback = nil
LobbySubLevelHelper.tbLevelActor = nil
LobbySubLevelHelper.szActiveWndName = nil
LobbySubLevelHelper.nActiveCameraIndex = nil

local function UnbindLoadDelegate(self)
    if(isvalidhandle(self.pDelegate)) then
        unbindDelegate(self.pDelegate, self.nDelegateHandle)
    end
    self.pDelegate = nil
    self.nDelegateHandle = nil
end

local function GetSubLevelPaths(self, nSubType, tbTempPaths)
    local tbPaths = {}
    local tbAllTemplate = tbTempPaths
    if not tbAllTemplate then
        tbAllTemplate = LobbySubLevelDataTable:GetAllTemplateById(nSubType)
    end
    if not tbAllTemplate then
        return tbPaths
    end 
    local szResPath = nil
    local pLevelStream = nil
    local tbResPathExist = {}
    for k, v in pairs(tbAllTemplate) do
        if v.szResPath then
            szResPath = v.szResPath
        else
            szResPath = v
        end
        if not tbResPathExist[szResPath] then
            tbResPathExist[szResPath] = true
            pLevelStream = self.tbLevelStream[szResPath]
            if not pLevelStream then
                pLevelStream = ClientShell.GetClient(GWorld):GetStreamingLevel(GWorld, szResPath)
                self.tbLevelStream[szResPath] = pLevelStream
                self.tbLevelActor[pLevelStream] = {}
            end
            --logdebug("GetSubLevelPaths,szResPath=",szResPath,pLevelStream.LoadedLevel)
            if pLevelStream then
                pLevelStream:SetShouldBeVisible(false)
                if not pLevelStream.LoadedLevel then
                    --logdebug("GetSubLevelPaths",szResPath)
                    table.insert(tbPaths, szResPath)
                end
            else
                error("GetSubLevelPaths, sublevel is not found! szResPath="..tostring(szResPath))
            end
        end
        
    end
    return tbPaths
end

local function GetLevelActorByTag(self, pLevelStream, szTag)
    if not isvalidhandle(pLevelStream) then
        return
    end
    local pActor = self.tbLevelActor[pLevelStream][szTag]
    if not pActor then
        pActor = ExtendBlueprintFunctions.GetLevelActorByTag(pLevelStream, szTag)
        self.tbLevelActor[pLevelStream][szTag] = pActor
    end
    return pActor
end

local function ApplyRenderParam(self, pLevelStream, szTag)
    local pActor = GetLevelActorByTag(self, pLevelStream, szTag)
    if pActor then
        pActor:Apply()
    end
end

local function RestoreRenderParam(self, pLevelStream, szTag)
    local pActor = GetLevelActorByTag(self, pLevelStream, szTag)
    if pActor then
        pActor:Restore()
    end
end

local function SetLevelStreamShouldBeVisible(self, pLevelStream, bVisible)
    if not pLevelStream then
        return
    end
    pLevelStream:SetShouldBeVisible(bVisible)
    GameplayStatics.FlushLevelStreaming(GWorld)
    if bVisible then
        ApplyRenderParam(self, pLevelStream, RENDER_PARAM_TAG)
    else
        RestoreRenderParam(self, pLevelStream, RENDER_PARAM_TAG)
    end
end

-------------------------初始化-----------------------
function LobbySubLevelHelper:Init()
    self.tbLevelStream = {}
    self.tbLevelActor = {}
end

function LobbySubLevelHelper:Uninit()
    self:CancelLoadSubLevelAsync()
    self.tbLevelStream = nil
    self.tbLevelActor = nil
    self.szActiveWndName = nil
    self.nActiveCameraIndex = nil
end

---------------------------外部接口---------------------------
function LobbySubLevelHelper:LoadSubLevelAsync(nSubType, tbPaths)
    log("LobbySubLevelHelper:LoadSubLevelAsync",nSubType)
    if not GlobalVariableSystem.bLoadAllLobbySublevel then
        nSubType = 1
    end
    self:CancelLoadSubLevelAsync()
    local tbSubLevelWaitForLoad = GetSubLevelPaths(self, nSubType, tbPaths)
    if #tbSubLevelWaitForLoad == 0 then
        return
    end
    
    self.tbSubLevelWaitForLoad = tbSubLevelWaitForLoad
    self.bAsync = true
    local fnLoadedCallback = function(tbLoadedObjects)
        for k, v in ipairs(tbSubLevelWaitForLoad) do
            self.tbLevelStream[v]:SetShouldBeLoaded(true)
        end
    end
    self.fnLoadedCallback = fnLoadedCallback
    self.pDelegate, self.nDelegateHandle = createDelegate(FUNC_LOAD_MULTI_ASSET_ASYNC_CALLBACK_FIRE, fnLoadedCallback, "load lobby sublevel")
    EngineExtShell.Get(GWorld):LoadMultiAssetsAsync(tbSubLevelWaitForLoad, self.pDelegate)
end

function LobbySubLevelHelper:LoadSubLevelSync(nSubType, tbPaths)
    log("LobbySubLevelHelper:LoadSubLevelSync",nSubType)
    if not GlobalVariableSystem.bLoadAllLobbySublevel then
        nSubType = 1
    end
    self:CancelLoadSubLevelAsync()
    local tbTempPaths = GetSubLevelPaths(self, nSubType, tbPaths)
    if #tbTempPaths == 0 then
        return
    end
    
    self.bAsync = false
    for k, v in ipairs(tbTempPaths) do
        v:load()
        self.tbLevelStream[v]:SetShouldBeLoaded(true)
    end
    GameplayStatics.FlushLevelStreaming(GWorld)
end

function LobbySubLevelHelper:CancelLoadSubLevelAsync()
    UnbindLoadDelegate(self)
    self.bAsync = nil
    self.tbSubLevelWaitForLoad = nil
end


function LobbySubLevelHelper:GetSubLevel(nSubType, szWndName)
    local tbSubLevelTemplate = LobbySubLevelDataTable:GetTemplate(nSubType, szWndName)
    if not tbSubLevelTemplate then
        logerror("LobbySubLevelHelper:GetSubLevel, tbSubLevelTemplate is not found",nSubType, szWndName, debug.traceback())
        return
    end
    local pLevelStream = self.tbLevelStream[tbSubLevelTemplate.szResPath]
    if not pLevelStream then
        logerror("LobbySubLevelHelper:GetSubLevel, pLevelStream is not found",nSubType, szWndName, debug.traceback())
        return
    end
    return pLevelStream
end

function LobbySubLevelHelper:SetCamera(nSubType, szWndName, nCameraIndex)
    self:SetCameraWithBlend(nSubType, szWndName, nCameraIndex, 0, EViewTargetBlendFunction.VTBlend_Linear, 0)
end

function LobbySubLevelHelper:SetCameraWithBlend(nSubType, szWndName, nCameraIndex, nBlendTime, pBlendFunction, nBlendExp)
    if not nSubType or not szWndName or not nCameraIndex then
        log("LobbySubLevelHelper:SetCameraWithBlend failed", nSubType, szWndName, nCameraIndex)
        return
    end
    local pLevelStream = self:GetSubLevel(nSubType, szWndName)
    if not pLevelStream or not pLevelStream:IsLevelVisible() then
        return
    end
    local pViewportSize = WidgetLayoutLibrary.GetViewportSize(GWorld)
    local tbCameraTag = LobbySubLevelDataTable:GetCameraTagsByAspectRatio(nSubType, szWndName, pViewportSize.X / pViewportSize.Y)
    local szCameraTag = tbCameraTag[nCameraIndex]
    if not szCameraTag or szCameraTag == "" then
        return
    end
    self.szActiveWndName = szWndName
    self.nActiveCameraIndex = nCameraIndex
    local pCameraActor = GetLevelActorByTag(self, pLevelStream, szCameraTag)
    if not pCameraActor then
        return
    end
    local tbTags = pCameraActor.Tags
    local szLockTag = LobbyFOVLockHelper.LOCK_TAG.Y
    if #tbTags > 1 then
        --第二个tag用来控制fov锁定的方向
        szLockTag = tbTags[2] 
    end
    log("LobbySubLevelHelper:SetCameraWithBlend",szCameraTag, szLockTag)
    LobbyFOVLockHelper:LockFov(pCameraActor, szLockTag)
    nBlendTime = nBlendTime and nBlendTime or 0
    pBlendFunction = pBlendFunction and pBlendFunction or EViewTargetBlendFunction.VTBlend_Linear
    nBlendExp = nBlendExp and nBlendExp or 0
    local pController = GameplayStatics.GetPlayerController(GWorld, 0)
    pController:SetViewTargetWithBlend(pCameraActor, nBlendTime, pBlendFunction, nBlendExp, false)
end

function LobbySubLevelHelper:PlayCameraShake(szShakeClassPath)
    local pShakeClass = szShakeClassPath:load()
    if pShakeClass then
        local pCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
        if pCameraManager then
            pCameraManager:PlayCameraShakeInstance(pShakeClass, 1.0, ECameraAnimPlaySpace.CameraLocal, TEMP_ROTATION)
        end
    end
end

function LobbySubLevelHelper:GetLocationAndRotationByTag(nSubType, szWndName, szTag)
    local pLevelStream = self:GetSubLevel(nSubType, szWndName)
    if not pLevelStream then
        return TEMP_LOCATION, TEMP_ROTATION
    end
    local pPosActor = GetLevelActorByTag(self, pLevelStream, szTag)
    if not pPosActor then
        logerror("LobbySubLevelHelper:GetLocationAndRotationByTag, pPosActor is not found",nSubType, szWndName, szTag)
        return TEMP_LOCATION, TEMP_ROTATION
    end
    local location = pPosActor:K2_GetActorLocation()
    local rotation = pPosActor:K2_GetActorRotation()
    return location, rotation
end

function LobbySubLevelHelper:SetShouldBeVisible(nSubType, szWndName, bVisible)
    log("LobbySubLevelHelper:SetShouldBeVisible",nSubType, szWndName, bVisible)
    if szWndName then
        local pLevelStream = self:GetSubLevel(nSubType, szWndName)
        SetLevelStreamShouldBeVisible(self, pLevelStream, bVisible)
    else
        local tbAllTemplate = LobbySubLevelDataTable:GetAllTemplateById(nSubType)
        if tbAllTemplate then
            for k, v in pairs(tbAllTemplate) do
                local szResPath = v.szResPath
                local pLevelStream = self.tbLevelStream[szResPath]
                SetLevelStreamShouldBeVisible(self, pLevelStream, bVisible)
            end
        end
    end

end

function LobbySubLevelHelper:SetActorSkeletalMeshLightChannel(nSubType, szWndName, pActor)
    local tbSubLevelTemplate = LobbySubLevelDataTable:GetTemplate(nSubType, szWndName)
    if not tbSubLevelTemplate then
        logerror("LobbySubLevelHelper:SetActorSkeletalMeshLightChannel, tbSubLevelTemplate is not found",nSubType, szWndName, debug.traceback())
        return
    end

    local nLightChannel = tbSubLevelTemplate.nLightChannel
    if not nLightChannel then
        return
    end
    local bChannel0 = nLightChannel == 0
    local bChannel1 = nLightChannel == 1
    local bChannel2 = nLightChannel == 2
    if not pActor.HumanAvatarComponent then
        EngineExtActorShell.SetActorSkeletalMeshLightChannel(pActor, bChannel0, bChannel1, bChannel2)
    end
end

function LobbySubLevelHelper:GetActiveCameraIndex()
    return self.nActiveCameraIndex
end

function LobbySubLevelHelper:OnViewPortChanged(nSubType)
    self:SetCamera(nSubType, self.szActiveWndName, self.nActiveCameraIndex)
end

return LobbySubLevelHelper