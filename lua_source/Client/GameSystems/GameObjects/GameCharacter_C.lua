-- 角色类
-- 换装相关的建议放到component里

local luaclass = require("luaclass")
local GameCharacterClass = require("GameCharacter")
local GameCharacter_C = luaclass("GameCharacter_C", GameCharacterClass)
local GameWorldSystem = require("GameWorldSystem")
local PlayerCullDistanceIni = require("PlayerCullDistanceIni")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")


-- 该对象在雷达上的显示Icon, 由逻辑动态控制; nil：使用对象默认Icon
GameCharacter_C.nDynamicFlagId = nil
GameCharacter_C.bVisible = true

function GameCharacter_C:OnActorCreated(pUEActor)
    GameCharacter_C.super.OnActorCreated(self, pUEActor)
    self.bVisible = true
	local World = GameWorldSystem:GetWorld()
	local isOcean = false
    if World and World.IsOcean then
        isOcean = World:IsOcean()
    end
    if not GlobalVariableSystem.bIsInDungeon then
        if(isOcean) then
            if pUEActor.ShipModel and pUEActor.ShipModel.ChildActor then
                EngineExtActorShell.SetActorMaxDrawDistance(pUEActor.ShipModel.ChildActor, PlayerCullDistanceIni.nDistanceShip)
            else
                EngineExtActorShell.SetActorMaxDrawDistance(pUEActor, PlayerCullDistanceIni.nDistanceShip)
            end
        else
            EngineExtActorShell.SetActorMaxDrawDistance(pUEActor, PlayerCullDistanceIni.nDistanceHuman)
        end
    end
end

function GameCharacter_C:PlayAnimation(szAnimKey)
	logerror("[PlayAnimation]该函数已移到[SelfAnimationHelper]", debug.traceback( ))
    return false
end

function GameCharacter_C:SetDynamicFlagId(nId)
    if self.nDynamicFlagId ~= nId then
        self.nDynamicFlagId = nId
        EventManager:OnFireEvent(ClientEventDef.EV_MAP_REFRESH_DYNAMIC_FLAG, self)
    end
end

function GameCharacter_C:GetDynamicFlagId()
    return self.nDynamicFlagId
end

--todo 调查下性能问题，将来记得注释掉
function GameCharacter_C:BeforeCallFunctionInComponent(szFunc, tbComponent)
    if tbComponent.szClassName == "HumanAvatarComponentNew" then
        log("BeforeCallFunction: ", tbComponent.szClassName, szFunc)
    end
end

function GameCharacter_C:AfterCallFunctionInComponent(szFunc, tbComponent)
    if tbComponent.szClassName == "HumanAvatarComponentNew" then
        log("AfterCallFunction: ", tbComponent.szClassName, szFunc)
    end
end

return GameCharacter_C
