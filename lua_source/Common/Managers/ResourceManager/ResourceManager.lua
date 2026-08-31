local ResourceManager = {}

local CppDelegate = require("CppDelegate")

local nMaxHandle = 1
local MAX_UOBJECT_COUNT_RATIO = 0.7

ResourceManager.nMaxUObjectCount = 0
ResourceManager.tbHolders = nil
ResourceManager.nGCStepSize = 1024  -- KBytes
ResourceManager.tbLoadRequests = nil
ResourceManager.DelegateBinder = nil

local function GenerateNewHandle()
    local nRet = nMaxHandle
    nMaxHandle = nMaxHandle + 1
    return nRet
end

local function OnAsynLoaded(self, szAssetName, pObject)
    local tbRequests = self.tbLoadRequests[szAssetName]
    if(tbRequests) then
        self.tbLoadRequests[szAssetName] = nil
        for nHandle, fnCallback in pairs(tbRequests) do
            fnCallback(szAssetName, pObject, nHandle)
        end
    end
end

function ResourceManager:Init()
    self.tbResources = {}
    self.tbLoadRequests = {}
    self.tbHolders = {}
    self.tbHolderCounts = {}

    local DelegateMgr = EngineExtShell.Get(GWorld):GetKMDelegateManager()
    self.DelegateBinder = CppDelegate:BindMethod(DelegateMgr.OnLoadAssetAsync, self, OnAsynLoaded)

    self.nMaxUObjectCount = ExtendBlueprintFunctions.GetMaxUObjectCount() * MAX_UOBJECT_COUNT_RATIO
    return true
end

function ResourceManager:Uninit()
    if(self.DelegateBinder) then
        self.DelegateBinder:Unbind()
        self.DelegateBinder = nil
    end

    self.tbHolders = nil
    self.tbHolderCounts = nil
    self.tbLoadRequests = nil
end

function ResourceManager:Hold(pObject)
    if(pObject == nil) then
        return
    end

    if(GEnableNewLua) then
        local Finded = self.tbHolders[pObject]
        if(Finded) then
            local tbHolderCounts = self.tbHolderCounts
            local nCount = tbHolderCounts[pObject]
            tbHolderCounts[pObject] = nCount + 1
        else
            self.tbHolderCounts[pObject] = 1
            self.tbHolders[pObject] = luaholder(pObject)
        end
    else
        self.tbHolders[ExtendBlueprintFunctions.GetObjectUniqueID(pObject)] = pObject
    end
end

function ResourceManager:Unhold(pObject)
    if(pObject == nil) then
        return
    end

    if(GEnableNewLua) then
        local tbHolderCounts = self.tbHolderCounts
        local nCount = tbHolderCounts[pObject]
        if(nCount == nil) then
            return
        end
        nCount = nCount - 1
        if(nCount <= 0) then
            tbHolderCounts[pObject] = nil
            self.tbHolders[pObject] = nil
        else
            tbHolderCounts[pObject] = nCount
        end
    else
        self.tbHolders[ExtendBlueprintFunctions.GetObjectUniqueID(pObject)] = nil
    end
end

function ResourceManager:LoadSync(szResource, bHold)
    local pObject = szResource:load()
    if bHold then
        self:Hold(pObject)
    end
    return pObject
end

function ResourceManager:LoadAsync(szAssetName, fnCallback, bHold)
    local tbRequests = self.tbLoadRequests[szAssetName]
    if(tbRequests == nil) then
        tbRequests = {}
        self.tbLoadRequests[szAssetName] = tbRequests
    end
    local nHandle = GenerateNewHandle()
    local fnFunc = function(szTempAssetName, pObject)
        if(bHold) then
            self:Hold(pObject)
        end
        if(fnCallback) then
            fnCallback(szTempAssetName, pObject, nHandle)
        end
    end

    tbRequests[nHandle] = fnFunc
    if(EngineExtShell.Get(GWorld):LoadAssetAsync(szAssetName)) then
        return nHandle
    end
    tbRequests[nHandle] = nil
    return -1
end

-- 因为引擎不能Cancel某一个请求，所以这里只是把callback摘掉
function ResourceManager:CancelLoadAsync(nHandle)
    local tbAllRequests = self.tbLoadRequests
    for _szResource, tbRequests in pairs(tbAllRequests) do
        tbRequests[nHandle] = nil
    end
end

function ResourceManager:GC()
    log("Request lua gc")
    luagc()
end

function ResourceManager:GetUsedMemorySize()
    return collectgarbage("count") * 1024
end

function ResourceManager:VerifyUObjectCount()
    local nUObjetCount = ExtendBlueprintFunctions.GetUObjectCount()
    log("VerifyUObjectCount", self.nMaxUObjectCount, nUObjetCount)
    if nUObjetCount > self.nMaxUObjectCount then
        log("UObject count is more than max count. exec gc. Current count :", nUObjetCount, "Max count :", self.nMaxUObjectCount)
        self:GC()
        KismetSystemLibrary.CollectGarbage()
        nUObjetCount = ExtendBlueprintFunctions.GetUObjectCount()
        log("GC end. Current count :", nUObjetCount)
    end
end

return ResourceManager