-----------------------------------------------------
--File Name    : InteractionCamera.lua
--Author       : Zuo Kun
--Create Time  : 2017-03-27
--Description  : 转镜头对话
-----------------------------------------------------
local luaclass = require("luaclass")
local InteractionBase = require("InteractionBase")
local InteractionCamera = luaclass("InteractionCamera", InteractionBase)
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local UEClientActorHelper = require("UEClientActorHelper")
local ClientEventDef = require("ClientEventDef")
local InteractionDef = require("InteractionDef")
local EventManager = require("EventManager")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local GameObjectTypeDef = require("GameObjectTypeDef")
local NpcAnimStateDefine = require("NpcAnimStateDefine")

-- local CAMERA_ANIMATION_TIME = 0

InteractionCamera.nInteractionType = InteractionDef.InteractionMode.SPECIAL_CAMERA
InteractionCamera.pPlayerView = nil
InteractionCamera.tbParams = nil
InteractionCamera.tbInteractionWnd = nil 
InteractionCamera.nVisiblityFactor = nil

--InteractionCamera.bUseUIState = true 

-- local function IsInRange( Npc )
-- 	local nMaxDistance = Npc.tbNpcTemplateData.nDistance
-- 	local PlayerSelf = GamePlayerSelfHelper:Get()
-- 	if Npc.pUEActor then
-- 		local nDistance = PlayerSelf.pUEActor:GetDistanceTo(Npc.pUEActor)
-- 		return (nDistance < nMaxDistance and nDistance > 0) 
-- 	end
-- 	return false 
-- end
function InteractionCamera:Init(Owner)
    InteractionCamera.super.Init(self, Owner)
    self.nVisiblityFactor = UEClientActorHelper:AllocateObjectVisiblityFactor()
end 

function InteractionCamera:OnInteractionEnd()
    self.nVisiblityFactor = nil
    InteractionCamera.super.OnInteractionEnd(self)
end

function InteractionCamera:DoInteraction(tbSelectedNpc, tbParams)
    self:CloseAllUI()
    if not tbSelectedNpc then 
        EventManager:OnFireEvent(ClientEventDef.EV_INTERACTION_ABORT)
        return 
    end 
    -- if not IsInRange(tbSelectedNpc) then 
    --     EventManager:OnFireEvent(ClientEventDef.EV_INTERACTION_ABORT)
    --     logdebug("Error Npc So Far")
	-- 	return 
	-- end 
    InteractionCamera.super.DoInteraction(self, tbSelectedNpc, tbParams)

    self:StopMove()
    self.tbParams = tbParams

    GlobalVariableSystem_C.bShowCharacter = false
	-- local tbTypes = {}
	-- tbTypes[GameObjectTypeDef.PlayerSelf] = true
	-- tbTypes[GameObjectTypeDef.PlayerOther] = true
	-- tbTypes[GameObjectTypeDef.Npc] = true
	-- tbTypes[GameObjectTypeDef.Trigger] = true

    -- UEClientActorHelper:SetPlayerVisible(tbTypes, false)    
    -- self.tbInteractionWnd = UIManager:OpenWnd(UIDef.UI_INTERACTION, {tbSelectedNpc = tbSelectedNpc, tbParams = self.tbParams, bIsShowCenterAvater = true})
    self:CameraAnimaction(tbSelectedNpc)
    if tbSelectedNpc then 
        -- tbSelectedNpc.HeadInfoComponent:SetVisibility(false)

        local AnimInstance = tbSelectedNpc.pUEActor.Mesh:GetAnimInstance()
        if AnimInstance and AnimInstance.SetAnimState ~= nil then 
            AnimInstance:SetAnimState(NpcAnimStateDefine.STAND)
        end         
    end 
end

function InteractionCamera:RefreshInteractionData(tbParams)
    if self.tbInteractionWnd then 
        self.tbInteractionWnd:RefreshDialog(tbParams)
    end 
end 

--相机动画
function InteractionCamera:CameraAnimaction(tbCurrentNpc)
	local tbTypes = {}
	tbTypes[GameObjectTypeDef.PlayerSelf] = true
	tbTypes[GameObjectTypeDef.PlayerOther] = true
	tbTypes[GameObjectTypeDef.Trigger] = true
    tbTypes[GameObjectTypeDef.Npc] = true    
    UEClientActorHelper:SetAllObjectVisibilityFactor(self.nVisiblityFactor, tbTypes, false)
    -- UEClientActorHelper:SetPlayerVisible(tbTypes, false)
    -- self:SetAllNpcHeadInfoVisible(false)

    self.tbInteractionWnd = UIManager:OpenWnd(UIDef.UI_INTERACTION, {tbSelectedNpc = tbCurrentNpc, tbParams = self.tbParams, bIsShowCenterAvater = true})

    -- local pController = GameplayStatics.GetPlayerController(GWorld, 0)

    -- self.pPlayerView = pController:GetViewTarget()
    -- pController:SetViewTargetWithBlend(tbCurrentNpc.pUEActor, CAMERA_ANIMATION_TIME, EViewTargetBlendFunction.VTBlend_Linear, 0, false)

    UIManager:OpenWnd(UIDef.UI_BLACKSCREEN)
    self.bViewTarget = not self.bViewTarget 
end


--重置相机
function InteractionCamera:ResetCamera()
    -- local pController = GameplayStatics.GetPlayerController(GWorld, 0)
    -- if pController and self.pPlayerView then 
    --     pController:SetViewTargetWithBlend(self.pPlayerView, CAMERA_ANIMATION_TIME, EViewTargetBlendFunction.VTBlend_Linear, 0, false)    
    -- end 
end


--交互结束
function InteractionCamera:OnInteractionEnd()
    self.tbInteractionWnd = nil 
    local tbSelectedNpc = self:GetSelectNpc()
    if tbSelectedNpc then 
        if tbSelectedNpc.pUEActor then 
            local AnimInstance = tbSelectedNpc.pUEActor.Mesh:GetAnimInstance()
            if AnimInstance and AnimInstance.SetAnimState ~= nil then 
                AnimInstance:SetAnimState(NpcAnimStateDefine.IDLE)
            end  
        end 

        -- if tbSelectedNpc.HeadInfoComponent then
        --     tbSelectedNpc.HeadInfoComponent:SetVisibility(true)
        -- end
    end 
    -- UIManager:OpenWnd(UIDef.UI_BLACKSCREEN)
    -- InteractionCamera.super.OnInteractionEnd(self)
    -- UIManager:CloseWnd(UIDef.UI_INTERACTION)
	local tbTypes = {}
	tbTypes[GameObjectTypeDef.PlayerSelf] = true
	tbTypes[GameObjectTypeDef.PlayerOther] = true
	tbTypes[GameObjectTypeDef.Trigger] = true    
	tbTypes[GameObjectTypeDef.Npc] = true    
    UEClientActorHelper:SetAllObjectVisibilityFactor(self.nVisiblityFactor, tbTypes, true)
    -- UEClientActorHelper:SetPlayerVisible(tbTypes, true)
    -- self:SetAllNpcHeadInfoVisible(true)
    -- self:ResetCamera()
    GlobalVariableSystem_C.bShowCharacter = true
    -- UIManager:OpenWnd(UIDef.UI_MAIN)
end

return InteractionCamera
