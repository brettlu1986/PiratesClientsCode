local ManagerGroupChangeBinder = {}

ManagerGroupChangeBinder.tbContainer = nil
ManagerGroupChangeBinder.fnInitFunc = nil
ManagerGroupChangeBinder.fnUninitFunc = nil


local GetGroup = function(self, nGroupID, bAutoCreate)
    if(self.tbContainer == nil) then
        self.tbContainer = {}
    end

    local tbTemp = self.tbContainer[nGroupID]
    if(tbTemp == nil and bAutoCreate) then
        tbTemp = {}
        self.tbContainer[nGroupID] = tbTemp
    end
    return tbTemp
end  

local GetInitFunc = function(Manager)
    if(Manager.Init) then
        return Manager.Init
    elseif(Manager.InitGroup) then
        return Manager.InitGroup
    elseif(Manager.Active) then
        return Manager.Active
    end
    return nil
end

local GetUninitFunc = function(Manager)
    if(Manager.Uninit) then
        return Manager.Uninit
    elseif(Manager.UninitGroup) then
        return Manager.UninitGroup
    elseif(Manager.Unactive) then
        return Manager.Unactive
    end
    return nil
end

local AddDataToGroup = function(self, nGroupID, TempClass,
                                TempInitFunc, TempUninitFunc,
                                TempInitParam, TempUninitParam,
                                bInsertFront)    
    -- if(TempInitFunc == nil) then
    --     error("ManagerGroupChangeBinder:AddDataToGroup InitFunc nil")
    --     return false
    -- end

    local tbGroup = GetGroup(self, nGroupID, true)
    for _, tbData in ipairs(tbGroup) do
        if(tbData.Class == TempClass
            and tbData.InitFunc == TempInitFunc) then
            logwarning("ManagerGroupChangeBinder:AddDataToGroup duplicated, Class: ", tostring(TempClass))
            return false
        end
    end

    local tbData = 
    {
        bInited = false,
        Class = TempClass,
        InitFunc = TempInitFunc,
        UninitFunc = TempUninitFunc,
        InitParam = TempInitParam,
        UninitParam = TempUninitParam
    }
    if(bInsertFront) then
        table.insert(tbGroup, 0, tbData)
    else
        table.insert(tbGroup, tbData)
    end
    return true
end

function ManagerGroupChangeBinder:BindFunc(nGroupID, TempInitFunc, TempUninitFunc,
                                     TempInitParam, TempUninitParam)
    return AddDataToGroup(self, nGroupID, nil, TempInitFunc, 
                                TempUninitFunc, TempInitParam, TempUninitParam)
end

function ManagerGroupChangeBinder:Bind(nGroupID, Class, InitParam, UninitParam)
    if(Class == nil) then
        error("ManagerGroupChangeBinder:AddManager nil")
        return false
    end

    return AddDataToGroup(self, nGroupID, Class,
                            GetInitFunc(Class),
                            GetUninitFunc(Class),
                            InitParam,
                            UninitParam)
end

function ManagerGroupChangeBinder:Unbind(nGroupID, Class)
    if(Class == nil) then
        return false
    end

    local tbGroup = GetGroup(self, nGroupID, false)
    if(tbGroup) then
        for k, tbData in pairs(tbGroup) do
            if(tbData.Class == Class) then
                table.remove(tbGroup, k)
                return true
            end
        end
    end
    return false
end

function ManagerGroupChangeBinder:RemoveAll()
    self.tbContainer = {}
end

local InitData = function(tbData)
    if(not tbData.bInited and tbData.InitFunc) then
        tbData.bInited = true
        if(tbData.Class) then
            if(tbData.InitParam ~= nil) then
                tbData.InitFunc(tbData.Class, tbData.InitParam)
            else
                tbData.InitFunc(tbData.Class)
            end
        else
            if(tbData.InitParam ~= nil) then
                tbData.InitFunc(tbData.InitParam)
            else
                tbData.InitFunc()
            end
        end  
    end
end

function ManagerGroupChangeBinder:InitGroup(nGroupID)
    log("ManagerGroupChangeBinder:InitGroup "..nGroupID)
    local tbGroup = GetGroup(self, nGroupID, false)
    if(tbGroup) then
        local nIndex = 1
        while(nIndex <= #tbGroup) do
            InitData(tbGroup[nIndex])
            nIndex = nIndex + 1
        end
    end
end

local UninitData = function(tbData)
    if(tbData.bInited and tbData.UninitFunc) then
        tbData.bInited = false

        if(tbData.Class) then
            if(tbData.UninitParam ~= nil) then
                tbData.UninitFunc(tbData.Class, tbData.UninitParam)
            else                
                tbData.UninitFunc(tbData.Class)
            end
        else
            if(tbData.UninitParam ~= nil) then
                tbData.UninitFunc(tbData.UninitParam)
            else
                tbData.UninitFunc()
            end
        end  
    end
end

function ManagerGroupChangeBinder:UninitGroup(nGroupID)
    log("ManagerGroupChangeBinder:UninitGroup "..nGroupID)
    local tbGroup = GetGroup(self, nGroupID, false)
    if(tbGroup) then
        local nIndex = #tbGroup
        while(nIndex > 0) do
            UninitData(tbGroup[nIndex])
            nIndex = nIndex - 1
        end
    end 
end

function ManagerGroupChangeBinder:Init()
end

function ManagerGroupChangeBinder:Uninit()
    self:RemoveAll()
end

return ManagerGroupChangeBinder