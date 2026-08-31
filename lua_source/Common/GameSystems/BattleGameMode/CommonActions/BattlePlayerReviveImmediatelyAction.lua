local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattlePlayerReviveImmediatelyAction = luaclass("BattlePlayerReviveImmediatelyAction", BattleActionBase)

local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local D2CHelper = require("D2CHelper")
local DelayTimer = require("DelayTimer")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

function BattlePlayerReviveImmediatelyAction:Parse(tbJsonData)    
    return true
end

function BattlePlayerReviveImmediatelyAction:Execute()
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbPlayerWaitRevive = tbGameMode.Setting.tbPlayerWaitRevive
    if tbPlayerWaitRevive == nil then
        -- 原地复活 PVE,挑战副本
        -- 有复活timer则清除
        if tbGameMode.Setting.ClearRestartTimer then
            tbGameMode.Setting:ClearRestartTimer()
        end
        local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
        for Object, _ in pairs(tbObjects) do
            if Object:IsDead() then
                local pLocation = Object:GetLocation()
                local pRotation = Object:GetRotation()
                Object:Reborn(pLocation.X, pLocation.Y, pLocation.Z, pRotation.Yaw)
                D2CHelper:PlayerSetCameraYaw(Object, pRotation.Yaw)
                EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_REVIVE_SUCCE, Object)
            end
        end
    else
        -- 指定位置复活,战场
        for _, tbPlayerRevive in ipairs(tbPlayerWaitRevive) do
            if tbPlayerRevive.tbTimer ~= nil then
                DelayTimer:ClearTimer(tbPlayerRevive.tbTimer)
                tbPlayerRevive.tbTimer = nil
            end
            local tbPlayer = tbPlayerRevive.tbPlayer
            if tbPlayer and tbPlayer:IsDead() then
                if tbPlayerRevive.tbPoint then 
                    local tbTransform = tbPlayerRevive.tbPoint.Transform
                    tbPlayer:Reborn(tbTransform.X, tbTransform.Y, tbTransform.Z, tbTransform.Yaw)
                    D2CHelper:PlayerSetCameraYaw(tbPlayer, tbTransform.Yaw)
                    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_REVIVE_SUCCE, tbPlayer)
                end
            end
        end
    end
    tbPlayerWaitRevive = nil
    return true
end


return BattlePlayerReviveImmediatelyAction