local luaclass = require("luaclass")
local SyncDataBase = require("SyncDataBase")
local SyncDataCamera = luaclass("SyncDataCamera", SyncDataBase)

SyncDataCamera.tbCamera = nil


function SyncDataCamera:OnSync(tbPack)
    local pAIController = self.pAIController
    local tbCameraPositionX, tbCameraPositionY, tbCameraPositionZ = pAIController:GetCameraPositionXYZ()
    local tbCameraInfo = self.tbCamera
    tbCameraInfo.position = tbCameraInfo.position or {}
    tbCameraInfo.position.x = tbCameraPositionX
    tbCameraInfo.position.y = tbCameraPositionY
    tbCameraInfo.position.z = tbCameraPositionZ

    tbCameraInfo.rotation = tbCameraInfo.rotation or {}
    tbCameraInfo.rotation.x = pAIController.Pitch
    tbCameraInfo.rotation.y = pAIController.Yaw
    tbCameraInfo.rotation.z = 0
    tbPack.camera = self.tbCamera
end


function SyncDataCamera:OnStart()
    self.tbCamera = {}
end


function SyncDataCamera:OnStop()

end

return SyncDataCamera