
local luaclass = require("luaclass")
local BaseCameraSystem = require("BaseCameraSystem")
local GameCameraSystem = luaclass("GameCameraSystem", BaseCameraSystem)

local GameCameraModeGroupRegister = require("GameCameraModeGroupRegister")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local tbGroupDef = GameCameraModeGroupDef

function GameCameraSystem:OnCreateLogics()
    GameCameraSystem.super.OnCreateLogics(self)
    local InnerHelper = self.InnerHelper
    local LogicDef = tbGroupDef.LogicDef
    InnerHelper:CreateCameraLogic(LogicDef.CL_GAME_PLAYER)
    InnerHelper:CreateCameraLogic(LogicDef.CL_CARRONADE)
    InnerHelper:CreateCameraLogic(LogicDef.CL_AIMING)
    InnerHelper:CreateCameraLogic(LogicDef.CL_MOVEMENT)
    InnerHelper:CreateCameraLogic(LogicDef.CL_WATCHBATTLE)
end

function GameCameraSystem:Init()
    GameCameraSystem.super.Init(self)
    GameCameraModeGroupRegister:RegisterGameCameraModeGroup(self)
    return true
end

function GameCameraSystem:Uninit()
    GameCameraSystem.super.Uninit(self)
end

return GameCameraSystem()
