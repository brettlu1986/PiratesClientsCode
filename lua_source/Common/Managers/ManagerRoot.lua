-- 所有manager都会注册到这里，方便未来统一管理
local ManagerRoot = {}

ManagerRoot.tbGroupManagers = {}
ManagerRoot.fnInitCallback = nil
ManagerRoot.fnUninitCallback = nil

function ManagerRoot:RegisterAllManagers()
    local Register = dynamic_require("ManagerRegister")
    Register:RegisterManagers(self)
end

local GetGroup = function(self, nGroupID, bAutoCreate)
    local tbGroup = self.tbGroupManagers[nGroupID]
    if(tbGroup == nil and bAutoCreate) then
        tbGroup =
        {
            nGroupID = nGroupID,
            bInited = false,
            tbContainer = {}
        }
        self.tbGroupManagers[nGroupID] = tbGroup
    end
    return tbGroup
end

function ManagerRoot:RegisterByGroup(nGroupID, Manager)
    if not Manager.Init then
        error("Cannot find Init function in " .. tostring(Manager))
        return nil
    end
    if not Manager.Uninit then
        error("Cannot find Uninit function in " .. tostring(Manager))
        return nil
    end

    local tbGroup = GetGroup(self, nGroupID, true)
    local tbContainer = tbGroup.tbContainer
    for _, TempManager in ipairs(tbContainer) do
        if(TempManager == Manager) then
            logwarning("ManagerRoot register duplicated manager"..tostring(Manager))
            return Manager
        end
    end
    table.insert(tbContainer, Manager)
    if(Manager.OnRegister) then
        Manager:OnRegister()
    end
    return Manager
end

function ManagerRoot:UnregisterByGroup(nGroupID, Manager)
    local tbGroup = GetGroup(self, nGroupID, false)
    if(tbGroup) then
        local tbContainer = tbGroup.tbContainer
        for k, TempManager in pairs(tbContainer) do
            if(TempManager == Manager) then
                if(Manager.OnUnregister) then
                    Manager:OnUnregister()
                end
                table.remove(tbContainer, k)
                return true
            end
        end
    end
    return false
end

function ManagerRoot:InitGroup(nGroupID, bNoCheck)
    local tbGroup = GetGroup(self, nGroupID, false)
    if(tbGroup) then
        log("ManagerRoot:InitGroup", nGroupID)
        if(tbGroup.bInited) then
            if(not bNoCheck) then
                logwarning("ManagerRoot:InitGroup duplicated, GroupID: ", nGroupID)
            end
            return false
        end

        tbGroup.bInited = true
        local tbContainer = tbGroup.tbContainer
        for _, TempManager in pairs(tbContainer) do
            if(TempManager:Init() == false) then
                logerror("ManagerRoot:InitGroup failed, groupid: ", nGroupID,
                    ", manager: ", tostring(TempManager))
                return false
            end
        end
    end
    if(self.fnInitCallback) then
        self.fnInitCallback(nGroupID)
    end
    return true
end

function ManagerRoot:UninitGroup(nGroupID, bNoCheck)
    -- 根Init顺序相反
    if(self.fnUninitCallback) then
        self.fnUninitCallback(nGroupID)
    end

    local tbGroup = GetGroup(self, nGroupID, false)
    if(tbGroup) then
        if(not tbGroup.bInited) then
            if(not bNoCheck) then
                logwarning("ManagerRoot:UninitGroup failed, the group has not initialized, GroupID: ", nGroupID)
            end
            return false
        end

        local tbContainer = tbGroup.tbContainer
        local nIndex = #tbContainer
        while (nIndex > 0) do
            local TempManager = tbContainer[nIndex]
            if TempManager then
                TempManager:Uninit()
            end
            nIndex = nIndex - 1
        end
        tbGroup.bInited = false
    end
end

function ManagerRoot:UnregisterAll()
    self.tbGroupManagers = {}
end

function ManagerRoot:UninitAll()
    -- 在其他地方uninitgroup
    -- local tbAllGroups = self.tbGroupManagers
    -- for nGroupID, tbGroup in pairs(tbAllGroups) do
    --     self:UninitGroup(nGroupID, true)
    -- end
    self:UnregisterAll()
end

function ManagerRoot:SetInitGroupCallback(fnInitCallback)
    self.fnInitCallback = fnInitCallback
end

function ManagerRoot:SetUninitGroupCallback(fnUninitCallback)
    self.fnUninitCallback = fnUninitCallback
end

return ManagerRoot
