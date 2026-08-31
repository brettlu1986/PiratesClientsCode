local luaclass = require("luaclass")
local HumanMovementStateCrawl = require("HumanMovementStateCrawl")
local HumanMovementStateCrawl_C = luaclass("HumanMovementStateCrawl_C", HumanMovementStateCrawl)
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
-- local BattleItemDataTable = require("BattleItemDataTable")
local GameCameraSystem = require("GameCameraSystem")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")

local function IsNewHumanAim()
    local nGroupDef = GameCameraModeGroupDef
    return  GameCameraSystem:IsCameraLogicActive(nGroupDef.HumanAiming) 
end

function HumanMovementStateCrawl_C:Active(tbParams)
    HumanMovementStateCrawl_C.super.Active(self)

    if self.bSelf then
        local GameCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0) 
        GameCameraManager:EnableCameraMoveCollisionCheck(true, true)
        if not IsNewHumanAim() then
            --不能传 true, control rotation 在趴下的时候已经重置了
            EventManager:OnFireEvent(CommonEventDef.EV_ACTIVE_CRAWL_CAMERA, self.GamePlayer, false)
            self.pOwnerActor.CharacterMovement:SetCrawlState(true)
        end
    end
    self:BlendCameraWithTime()
end

function HumanMovementStateCrawl_C:UnActive(tbParams)
    HumanMovementStateCrawl_C.super.UnActive(self)

    self.pOwnerActor.bCanFalling = true
    -- pUEActor.bIsCrouched = false
    -- pUEActor.CharacterMovement.MaxStepHeight = 45
    if self.bSelf then
        local GameCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0) 
        GameCameraManager:EnableCameraMoveCollisionCheck(false, false)
        if not IsNewHumanAim() then
            self.pOwnerActor.CharacterMovement:SetCrawlState(false)
        end
    end
   
end

return HumanMovementStateCrawl_C