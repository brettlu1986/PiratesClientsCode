-----------------------------------------------------
--File Name    : InteractionBase.lua
--Author       : Zuo Kun
--Create Time  : 2017-03-27
--Description  : 交互实现基类
-----------------------------------------------------
local luaclass = require("luaclass")
local InteractionBase = luaclass("InteractionBase")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local UIManager = require("UIManager")
local LuaDelegate = require("LuaDelegate")
local GameObjectSystem = require("GameObjectSystem_C")
local GameObjectTypeDef = require("GameObjectTypeDef")
local UIStateDef = require("UIStateDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

InteractionBase.nInteractionType = 0
InteractionBase.bNeedSendToServerOnEnd = false
InteractionBase.szCurrentUIState = nil
InteractionBase.Owner = nil
InteractionBase.bControlUIByState = true
InteractionBase.OnComplete = nil 
InteractionBase.bUseUIState = false
InteractionBase.bStopMove = false 
InteractionBase.nSelectNpcID = 0

function InteractionBase:Init(Owner)
    self.Owner = Owner
    self.bStopMove = false 
    if not self.OnComplete then 
	    self.OnComplete = LuaDelegate()
    end 
end 

function InteractionBase:GetSelectNpc()
    return GameObjectSystem:FindByInstanceId(self.nSelectNpcID)
end 

function InteractionBase:DoInteraction(tbSelecedNpc, tbParams)
    if tbSelecedNpc then 
        self.nSelectNpcID = tbSelecedNpc.nServerInstanceId
    end 
    self.bNeedSendToServerOnEnd = tbParams.bNeedSendToServerOnEnd
    if tbParams.bControlUIByState ~= nil then 
        self.bControlUIByState = tbParams.bControlUIByState
    end 

end

function InteractionBase:RefreshInteractionData(tbParams)
end

function InteractionBase:InteractionAbort()
    if self.bStopMove then 
        local PlayerSelf = GamePlayerSelfHelper:Get()
        if PlayerSelf then 
            if PlayerSelf.pUEActor and PlayerSelf.pUEActor.PlayerInputComponent then
                PlayerSelf.pUEActor.PlayerInputComponent:SetMoveEnabled(true)  
            end

            -- local pUEActor = PlayerSelf:GetModelActor()
            -- if pUEActor then 
            --     local CameraControlManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
            --     CameraControlManager.CurrentActiveModeComponent:LockCamera(false)
            -- end 
        end 
        self.bStopMove = false 
    end 

    if self.OnComplete then 
        self.OnComplete:UnbindAll()
    end 

    self:OnInteractionEnd()
    -- if self.bUseUIState then
    --     if GlobalVariableSystem:IsInDungeon() then 
    --         UIManager:PushState("UIBattleState", nil )
    --     else 
    --         UIManager:PushState("UITownState", nil )
    --     end 
    -- else
    --     UIManager:CloseWnd(UIDef.UI_INTERACTION)
    --     --UIManager:CloseWnd(UIDef.UI_GUIDE)
    --     --UIManager:SetCinematicMode(false)
    --     UIManager:PopState()
    -- end
    if self.bControlUIByState then
        UIManager:PopState()
    end
    self.bNeedSendToServerOnEnd = false 
    self.bControlUIByState = true
end 
function InteractionBase:InteractionEnd()
    if self.bStopMove then 
        local PlayerSelf = GamePlayerSelfHelper:Get()
        if PlayerSelf then 
        if PlayerSelf.pUEActor and PlayerSelf.pUEActor.PlayerInputComponent then 
            PlayerSelf.pUEActor.PlayerInputComponent:SetMoveEnabled(true)  
        end

        -- local pUEActor = PlayerSelf:GetModelActor()
        -- if pUEActor then 
        --     local CameraControlManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
        --     CameraControlManager.CurrentActiveModeComponent:LockCamera(false)
        -- end  
        end        
        self.bStopMove = false 
    end 

    if self.OnComplete then 
	    self.OnComplete:Fire(self)
        self.OnComplete:UnbindAll()
    end 

    self:OnInteractionEnd()
    -- if self.bUseUIState then
    --     if GlobalVariableSystem:IsInDungeon() then 
    --         UIManager:PushState("UIBattleState", nil )
    --     else 
    --         UIManager:PushState("UITownState", nil )
    --     end 
    -- else
    --     UIManager:CloseWnd(UIDef.UI_INTERACTION)
    --     --UIManager:CloseWnd(UIDef.UI_GUIDE)
    --     --UIManager:SetCinematicMode(false)
    --     UIManager:PopState()
    -- end
    if self.bControlUIByState then
        UIManager:PopState()
    end
    self.bNeedSendToServerOnEnd = false 
    self.bControlUIByState = true
end

function InteractionBase:OnInteractionEnd()

end

function InteractionBase:CanStop()
    return false
end 

function InteractionBase:StopMove()
    self.bStopMove = true
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf then 
        if PlayerSelf.pUEActor and PlayerSelf.pUEActor.PlayerInputComponent then 
            PlayerSelf.pUEActor.PlayerInputComponent:SetMoveEnabled(false)  
        end
        if PlayerSelf:IsShip() and not GlobalVariableSystem:IsInDungeon() then 
            NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_ShipStopImmediately)
        end 

		-- local pUEActor =PlayerSelf:GetModelActor()
		-- if pUEActor then 
		-- 	local CameraControlManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
        --     CameraControlManager.CurrentActiveModeComponent:LockCamera(true)
        -- end 
    end 
    -- local pUEActor = GamePlayerSelfHelper:Get().pUEActor 
    -- if pUEActor.ShipMovementComponent then 
    --     pUEActor.ShipMovementComponent:Brake()
    -- end 
end 

function InteractionBase:CloseAllUI()
    -- logdebug("InteractionBase:CloseAllUI,self.bUseUIState="..tostring(self.bUseUIState))
    if self.bControlUIByState then 
        UIManager:PushState(UIStateDef.StateName.UI_INTERACTION_STATE, nil)
    end
end 

function InteractionBase:SetAllNpcHeadInfoVisible(bVisible)
    local tbGameObjs = GameObjectSystem:GetAllGameObjects()
    for i,v in pairs(tbGameObjs) do
        if v.pUEActor then 
            if  v.ObjectType == GameObjectTypeDef.Npc then 
                if v.HeadInfoComponent then 
                    v.HeadInfoComponent:SetVisibility(bVisible)
                end 
            end 
        end 
    end
end 
--只允许一个存在
function InteractionBase:IsSingleInstance()
    return true
end

function InteractionBase:IsEnableInteraction(tbSelectedNpc, tbParams)
    return true
end 


return InteractionBase
