-----------------------------------------------------
--File Name    : GuideStep.lua
--Author       : Edward J
--Create Time  : 2019-05-08
--Description  : 新手指引步骤
-----------------------------------------------------
local luaclass      = require("luaclass")
local GuideModule   = luaclass("GuideModule")

local GuideGroup    = require("GuideGroup")
local GuideDebug    = require("GuideDebug")
local UIManager     = require("UIManager")
local UIDef         = require("UIDef")
local EventManager  = require("EventManager")
local ClientEventDef= require("ClientEventDef")
-----------------------------------------------------
--member veriable
GuideModule.tbModuleGroups      = nil
GuideModule.tbGroupWaitQueue    = nil
GuideModule.tbGroupFinish       = nil
GuideModule.OnEndCallBack       = nil
GuideModule.OnGroupEndCallBack  = nil
GuideModule.Owner               = nil
GuideModule.tbCurrentGroup      = nil
GuideModule.tbSharedInfo        = nil
GuideModule.nModuleId           = 0
GuideModule.bHasNextModule      = false --此module是否有下一个连续的module
GuideModule.bHasAlwaysTriggerGroup = false
GuideModule.bIsOpen             = false
-----------------------------------------------------

function GuideModule:Init(Owner, nModuleId, tbGroups)
    if not tbGroups then
        self:LogError("Init error,tbGroups==nil")
        return
    end
    self.nModuleId = nModuleId
    self.tbModuleGroups = {}
    self.tbGroupWaitQueue = {}
    self.tbGroupFinish = {}
    self.tbSharedInfo = {}
    self.bHasAlwaysTriggerGroup = false
    self:DebugLog("Init Module moduleId = " .. nModuleId)
    local tbModuleGroups =  self.tbModuleGroups
    self.Owner = Owner
    for nGroup, tbSteps in pairs(tbGroups) do
        if not Owner:CheckIsStripGroups(nModuleId, nGroup) then
            local CurrentGroup = tbModuleGroups[nGroup]
            if(CurrentGroup == nil)then
                CurrentGroup = GuideGroup()
                CurrentGroup:Init(self, nGroup, tbSteps)
                CurrentGroup:BindStartCallBack(function(GroupClass, nGroupId) self:OnGroupStart(GroupClass, nGroupId) end)
                CurrentGroup:BindEndCallBack(function(GroupClass, nGroupId, bEnableEnd) self:OnGroupEnd(GroupClass, nGroupId, bEnableEnd) end)
                tbModuleGroups[nGroup] = CurrentGroup
                self.tbGroupFinish[nGroup] = false
            end
        end
    end
end

function GuideModule:Begin()
    local tbModuleGroups = self.tbModuleGroups
    if not tbModuleGroups then
        return
    end
    for nGroup, GroupClass in pairs(tbModuleGroups) do   
        GroupClass:Begin()
    end
    self.bIsOpen = true
end

function GuideModule:End()
    self:DebugLog("End")
    local tbModuleGroups = self.tbModuleGroups
    if not tbModuleGroups then
        return
    end
    for nGroup, GroupClass in pairs(tbModuleGroups) do
        GroupClass:End()
    end
    if self.bHasNextModule then
        self:DebugLog("End nextModule = " .. tostring(self.bHasNextModule))
        local GuideWnd = UIManager:GetWnd(UIDef.UI_GUIDE)
        if GuideWnd then
            self:DebugLog("End ShowSpaceScreen")
            EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_SHOW_SPACE_SCREEN, true)
        end
    end
    self.bIsOpen = false
    self.tbSharedInfo = nil
end

function GuideModule:Uninit()
    self:DebugLog("Uninit")
    local tbModuleGroups = self.tbModuleGroups
    if not tbModuleGroups then
        return
    end
    for nGroup, GroupClass in pairs(tbModuleGroups) do
        GroupClass:Uninit()
    end
    self.tbModuleGroups         = nil
    self.tbGroupWaitQueue       = nil
    self.tbGroupFinish          = nil
    self.OnEndCallBack          = nil
    self.OnGroupEndCallBack     = nil
    self.tbCurrentGroup         = nil
    self.tbSharedInfo           = nil
    self.bHasNextModule         = false
end

function GuideModule:SetHasAlwaysTriggerGroup(bResult)
    self.bHasAlwaysTriggerGroup = bResult
end

function GuideModule:OnGroupStart(GroupClass, nGroup)
    self:DebugLog("OnGroupStart() nGroup = " .. nGroup .. " tbGroupWaitQueue = " .. tostring(self.tbGroupWaitQueue) .. " bInqueue = " .. tostring(GroupClass.bInQueue))
    local tbGroupWaitQueue = self.tbGroupWaitQueue
    if GroupClass.bInQueue then
        if not tbGroupWaitQueue then
            return
        end
        local tbTemp = {}
        tbTemp.GroupClass = GroupClass
        tbTemp.nGroup = nGroup
        for i, tbGroupInfo in ipairs(self.tbGroupWaitQueue) do
            self:DebugLog("tbGroupWaitQueue nGroup = " .. tostring(tbGroupInfo.nGroup))
        end
        self:AddToGroupWaitQueue(tbTemp)
        if #tbGroupWaitQueue == 1 then
            self:DebugLog("StartSteps() nGroup = " .. nGroup)
            GroupClass:StartSteps() 
        end
    else
        self:DebugLog("111  nGroup = " .. nGroup)
        local bWaitQeueuInUse = false
        if tbGroupWaitQueue and #tbGroupWaitQueue > 0 then
            bWaitQeueuInUse = true
        end
        if not self.tbCurrentGroup and not bWaitQeueuInUse then
            self.tbCurrentGroup = GroupClass
            self:DebugLog("222 nGroup = " .. nGroup)
            GroupClass:StartSteps()
            self:DebugLog("Set Current Group! nGroup = " .. nGroup)
        else
            self:DebugLog("333 nGroup = " .. nGroup)
            --此处的做法是为了防止两个group都是可以被打断的group，当恰巧二者的触发条件
            --一样时，就会造成二者不断被打断的死循环，所以此处规定，只有后来者能够打断
            --前者，即如果想要打断我的group被我打断过，那么将无视这个group
            if self.tbCurrentGroup and self.tbCurrentGroup.bInterrupt then
                if GroupClass.bInterrupt then
                    if GroupClass:CheckBeInterruptByThisGroup(self.tbCurrentGroup.nGroupId) then
                        GroupClass:Restart()
                        return
                    end
                end
                self:DebugLog("444 nGroup = " .. nGroup)
                local tbTemp = self.tbCurrentGroup
                tbTemp:Interrupt()
                tbTemp:SetBeInterruptByThisGroup(GroupClass.nGroupId)
                GroupClass:StartSteps()
                self.tbCurrentGroup = GroupClass
            else
                GroupClass:Restart()
            end
        end
    end
end

local function SortFunc(a, b)
    return a.nGroup < b.nGroup
end

function GuideModule:AddToGroupWaitQueue(tbTemp)
    local tbGroupWaitQueue = self.tbGroupWaitQueue
    local bCanInsert = true
    for i,v in ipairs(tbGroupWaitQueue) do
        if v.nGroup == tbTemp.nGroup then
            bCanInsert = false
            break
        end
    end
    if bCanInsert then
        self:DebugLog("AddToGroupWaitQueue nGroup = " .. tostring(tbTemp.nGroup))
        table.insert(tbGroupWaitQueue, tbTemp)
        table.sort(tbGroupWaitQueue, SortFunc)
    end
end

function GuideModule:GetWaitGroupId(nGroup)
    for i, tbGroupInfo in ipairs(self.tbGroupWaitQueue) do
        if tbGroupInfo.nGroup == nGroup then
            self:DebugLog(":GetWaitGroupId nGroup = " .. tostring(nGroup))
            return i
        end
    end
    return nil
end

function GuideModule:CheckAllGroupFinish()
    for k,bGroupState in pairs(self.tbGroupFinish) do
        if not bGroupState then
            return false
        end
    end
    return true
end

function GuideModule:GetOpenedGroups()
    local tbOpenedGrops = {}
    for nGroupId, bGroupState in pairs(self.tbGroupFinish) do
        if not bGroupState then
            table.insert(tbOpenedGrops, nGroupId)
        end
    end
    return tbOpenedGrops
end

function GuideModule:GetGroup(nGroupId)
    local tbModuleGroups = self.tbModuleGroups
    if not tbModuleGroups then
        return nil
    end
    return tbModuleGroups[nGroupId]
end

function GuideModule:OnGroupEnd(GroupClass, nGroup, bEnableEnd)
    self:DebugLog("OnGroupEnd nGroup = " .. nGroup .. " bEnableEnd = " .. tostring(bEnableEnd))
    if GroupClass.bInQueue then
        local tbGroupWaitQueue = self.tbGroupWaitQueue
        if not tbGroupWaitQueue then
            self:DebugLog(":OnGroupEnd tbGroupWaitQueue is nil")
            return
        end
        local nIndex = self:GetWaitGroupId(nGroup)
        if nIndex then
            table.remove(tbGroupWaitQueue, nIndex)
        end
        local tbCurrentGroupInfo = tbGroupWaitQueue[1]
        if tbCurrentGroupInfo then
            if not tbCurrentGroupInfo.GroupClass.bRunning then
                tbCurrentGroupInfo.GroupClass:StartSteps()
            end
        else
            UIManager:CloseWnd(UIDef.UI_GUIDE)
        end
    else
        UIManager:CloseWnd(UIDef.UI_GUIDE)
        self.tbCurrentGroup = nil
    end
    GroupClass:End()
    if bEnableEnd or bEnableEnd == nil then
        self.tbGroupFinish[nGroup] = true
    end
    if self.OnGroupEndCallBack and (bEnableEnd or bEnableEnd == nil) then
        self.OnGroupEndCallBack(self.nModuleId, nGroup)
    end
    
    if self:CheckAllGroupFinish() then
        if self.OnEndCallBack then
            self.OnEndCallBack(self.nModuleId)
        end
        -- self:End()
    end
end

function GuideModule:ForceEndGroup(nGroupId)
    self:DebugLog("ForceEndGroup nGroupId = " .. tostring(nGroupId))
    local tbModuleGroups = self.tbModuleGroups
    if not tbModuleGroups then
        self:LogError("ForceEndGroup tbModuleGroup is nil")
        return
    end
    local GroupClass = tbModuleGroups[nGroupId]
    if not GroupClass then
        self:LogError("ForceEndGroup GroupClass is nil")
        return
    end
    GroupClass:ForceEnd()
end

function GuideModule:ForceEndCurrentStep(nGroupId)
    self:DebugLog("ForceEndCurrentStep nGroupId = " .. tostring(nGroupId))
    local tbModuleGroups = self.tbModuleGroups
    if not tbModuleGroups then
        self:LogError("ForceEndCurrentStep tbModuleGroup is nil")
        return
    end
    local GroupClass = tbModuleGroups[nGroupId]
    if not GroupClass then
        self:LogError("ForceEndCurrentStep GroupClass is nil")
        return
    end
    GroupClass.tbCurrentStep:OnActionEnd(1) --由于任意一个action end 时，都会结束当前步，所以此参数可以随意传
end

function GuideModule:ForceBeginCurrentStep(nGroupId)
    self:DebugLog("ForceBeginCurrentStep nGroupId = " .. tostring(nGroupId))
    local tbModuleGroups = self.tbModuleGroups
    if not tbModuleGroups then
        self:LogError("ForceBeginCurrentStep tbModuleGroup is nil")
        return
    end
    local GroupClass = tbModuleGroups[nGroupId]
    if not GroupClass then
        self:LogError("ForceBeginCurrentStep GroupClass is nil")
        return
    end
    GroupClass.tbCurrentStep:ForceBeginStep()
end


function GuideModule:GetRunningGroup()
    local tbModuleGroups = self.tbModuleGroups
    if not tbModuleGroups then
        return nil
    end
    for k, GroupClass in pairs(tbModuleGroups) do
        self:DebugLog("GetRunningGroup() nGroup = " .. GroupClass.nGroupId)
        if GroupClass.bRunning then
            return GroupClass
        end
    end
    return nil
end

function GuideModule:SetHasNextModule(bHasNextModule)
    self.bHasNextModule = bHasNextModule
end

function GuideModule:BindGroupEndCallBack(EndCallBack)
    self.OnGroupEndCallBack = EndCallBack
end

function GuideModule:BindEndCallBack(EndCallBack)
    self.OnEndCallBack = EndCallBack
end

function GuideModule:SetSharedInfo(szKey, value)
    local tbSharedInfo  = self.tbSharedInfo
    if not tbSharedInfo then
        self:LogError("tbSharedInfo is nil!")  
        return
    end
    tbSharedInfo[szKey] = value
end

function GuideModule:GetSharedInfo(szKey)
    local tbSharedInfo  = self.tbSharedInfo
    if not tbSharedInfo then
        self:LogError("tbSharedInfo is nil!")  
        return nil
    end
    return tbSharedInfo[szKey]
end

function GuideModule:DebugLog(szMsg)
    szMsg = "[GuideModule] " .. szMsg
    GuideDebug:DebugLog(szMsg)
end

function GuideModule:Log(szMsg)
    szMsg = "[GuideModule] " .. szMsg
    GuideDebug:Log(szMsg)
end

function GuideModule:LogError(szMsg)
    szMsg = "[GuideModule] " .. szMsg
    GuideDebug:LogError(szMsg)
end

return GuideModule
