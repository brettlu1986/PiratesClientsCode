-----------------------------------------------------
--File Name    : LobbyFOVLockHelper.lua
--Author       : Ran Jie
--Create Time  : 2020-04-26
--Description  : 大厅相机FOV锁定Helper
-----------------------------------------------------

local LobbyFOVLockHelper = {}


LobbyFOVLockHelper.tbCameraFOVBak = nil
LobbyFOVLockHelper.LOCK_TAG =
{
    X = "X",
    Y = "Y",
}

local function ResetCameraField(self)
    for pCamera, v in pairs(self.tbCameraFOVBak) do
        if isvalidhandle(pCamera) then
            local pCameraComponent = pCamera.CameraComponent
            pCameraComponent.FieldOfView = v.XFOVBak
        end
        v.bUpdate = false
        v.szLockTag = self.LOCK_TAG.X
    end
end

-- local function OnViewportResized(self)
--     for k, v in pairs(self.tbCameraFOVBak)do
--         v.bUpdate = true
--     end
--     if isvalidhandle(self.pCurrentCamera) then
--         local tbFovBak = self.tbCameraFOVBak[self.pCurrentCamera]
--         local szLockTag = self.LOCK_TAG.Y
--         if tbFovBak then
--             szLockTag = tbFovBak.szLockTag
--         end
--         self:LockFov(self.pCurrentCamera, szLockTag)
--     end
-- end
-------------------------初始化-----------------------
function LobbyFOVLockHelper:Init()
    self.tbCameraFOVBak = {}
    --EventManager:BindEventMethod(ClientEventDef.EV_VIEWPORT_RESIZED, self, OnViewportResized)
end

function LobbyFOVLockHelper:Uninit()
    ResetCameraField(self)
    self.tbCameraFOVBak = nil
    --EventManager:UnBindEventMethod(ClientEventDef.EV_VIEWPORT_RESIZED, self, OnViewportResized)
end

---------------------------外部接口---------------------------
function LobbyFOVLockHelper:LockFov(pCameraActor, szLockTag)
    if not isvalidhandle(pCameraActor) then
        return
    end
    local szLockTagTemp = szLockTag == nil and self.LOCK_TAG.Y or szLockTag
    local tbFovBak = self.tbCameraFOVBak[pCameraActor]
    local pCameraComponent = pCameraActor.CameraComponent
    if not tbFovBak then
        tbFovBak = {}
        tbFovBak.XFOVBak = pCameraComponent.FieldOfView
        tbFovBak.bUpdate = true
        self.tbCameraFOVBak[pCameraActor] = tbFovBak
    end
    --if tbFovBak.bUpdate then
        if szLockTagTemp == self.LOCK_TAG.X then
            log("LobbyFOVLockHelper:LockFov[X],XFOVBak=",tbFovBak.XFOVBak,pCameraActor)
            pCameraComponent.FieldOfView = tbFovBak.XFOVBak
        elseif szLockTagTemp == self.LOCK_TAG.Y then
            local yFOV = RenderExtendBlueprintFunctions.ConvertXFOVToYFOV(pCameraComponent, tbFovBak.XFOVBak, pCameraComponent.AspectRatio)
            log("LobbyFOVLockHelper:LockFov[Y],XFOVBak,yFOV=",tbFovBak.XFOVBak,yFOV,pCameraActor)
            pCameraComponent.FieldOfView = yFOV
        else
            logerror("LobbyFOVLockHelper:LockFov[unknown], no define lock tag, lock Fov Y", szLockTagTemp)
            szLockTagTemp = self.LOCK_TAG.Y
        end
        tbFovBak.szLockTag = szLockTagTemp
        tbFovBak.bUpdate = false
    --end
end


return LobbyFOVLockHelper