-----------------------------------------------------
--File Name    : UILevelLoader.lua
--Author       : Ran Jie
--Create Time  : 2016-11-21
--Description  : UILevelLoader
-- load 3d level for UI
-- 1. call LoadLevel(szLevelPath, FuncAdded, Wnd)
-- 2. call SetLevelVisible( bVisible )
-----------------------------------------------------


local UILevelLoader = {}

-- import require
local LuaDelegate = require("LuaDelegate")
local CppDelegate = require("CppDelegate")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
-- member variable
UILevelLoader.szMainCamera            = 'MainCamera'
UILevelLoader.pStreamingLevel         = nil
UILevelLoader.pLastViewTarget         = nil
UILevelLoader.pLevelDelegate          = nil
UILevelLoader.szWndName               = nil
UILevelLoader.ParentWnd               = nil
UILevelLoader.bResourceLoaded         = false
UILevelLoader.szLevelName             = nil
UILevelLoader.szLevelPath             = nil
UILevelLoader.LoadFinishedDelegate    = nil
UILevelLoader.tbLoadedLevelList       = {}


-- public function
function UILevelLoader:Init()
    self.LoadFinishedDelegate = LuaDelegate()
    EventManager:BindEventMethod(ClientEventDef.EV_PRE_LOAD_MAP,self,self.UnloadLevel)
end

function UILevelLoader:UnInit()
    self.LoadFinishedDelegate = nil
    self.szLevelPath = nil
    EventManager:UnBindEventMethod(ClientEventDef.EV_PRE_LOAD_MAP, self, self.UnloadLevel)
end


function UILevelLoader:LoadLevel(szLevelPath, FuncAdded, Wnd)
    log('[UI] UILevelLoader : load level,  leve path='..tostring(szLevelPath))
    if(szLevelPath == nil or szLevelPath =="" or szLevelPath == self.szLevelPath)then
        return
    end
    self.bResourceLoaded = false
    self.szLevelPath =  szLevelPath
    local szReverse = string.reverse(szLevelPath)
    local nStart,_ = string.find(szReverse,"/",1,true)
    self.szLevelName = string.reverse(string.sub(szReverse,1,nStart-1))
    if FuncAdded then 
        local pDelegateLevel =  ClientShell.GetClient(GWorld):GetKMDelegateManager().Level
        self.pLevelDelegate = CppDelegate:BindMethod(pDelegateLevel.OnLevelAddedToWorld, self, self.LevelBeginPlay)
        self.LoadFinishedDelegate:Bind(FuncAdded,Wnd)
    end 
    self.pStreamingLevel = ExtendBlueprintFunctions.LoadSubLevelDynamic(GWorld, self.szLevelPath, Vector{X=0,Y=0,Z=-100000}, Rotator())
    
end

function UILevelLoader:UnloadLevel()
    if(self.szLevelPath == nil or self.szLevelPath == "")then
        return
    end
    log('[UI] SelfLevelHelper : unload level, name:', self.szLevelName)
    ExtendBlueprintFunctions.UnloadSubLevelDynamic(GWorld, self.szLevelPath)
    self.bResourceLoaded = false
    self.szLevelPath = nil
end

function UILevelLoader:IsLevelLoaded()
    return self.bResourceLoaded
end

function UILevelLoader:SetLevelVisible( bVisible )
    log('[UI] SelfLevelHelper : SetLevelVisible:bVisible=', tostring(bVisible))
    local PlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
    if not PlayerController then
        logerror('[UI] SelfLevelHelper : playerController is nil.')
        return
    end
    if self.bResourceLoaded then
        if bVisible then
            self.pLastViewTarget = PlayerController:GetViewTarget()
            PlayerController:SetViewTargetWithBlend(self.tbActorMap[self.szMainCamera], 0, EViewTargetBlendFunction.VTBlend_Linear, 0, false)
        else
            PlayerController:SetViewTargetWithBlend(self.pLastViewTarget, 0, EViewTargetBlendFunction.VTBlend_Linear, 0, false)
        end
    else
        logerror('[UI] SelfLevelHelper : level is not loaded, name:', self.szLevelName)
    end
end

function UILevelLoader:BindActor()
    
    local mt = {
        __index = function( tb, k)
            tb[k] = ExtendBlueprintFunctions.GetLevelActorByTag(self.pStreamingLevel, k)
            return tb[k]
        end
    }
    self.tbActorMap = {}
    setmetatable(self.tbActorMap, mt)
end

--todo 如果将来要使用UILevelLoader,这个一定要重写下，因为OnLevelAddedToWorld的接口已经改过了
function UILevelLoader:LevelBeginPlay( pLevelActor )
    assert(false)
--[[
    local szLevelName = ""
    if(pLevelActor.GetLevelName ~= nil)then
        szLevelName= pLevelActor:GetLevelName()
    end
    --logwarning("SelfLevelHelper:LevelBeginPlay,szLevelName="..tostring(szLevelName).." self.szLevelName="..tostring(self.szLevelName).." pLevelActor.GetLevelName="..tostring(pLevelActor.GetLevelName))
    if self.szLevelName ~= szLevelName then
        return
    end
    self.bResourceLoaded = true
    if self.pLevelDelegate then
        self.pLevelDelegate:Unbind()
        self.pLevelDelegate = nil
    end
    self:BindActor()
    if self.LoadFinishedDelegate then
        self.LoadFinishedDelegate:Fire()
        self.LoadFinishedDelegate:UnbindAll()
    end
]]
end
return UILevelLoader
