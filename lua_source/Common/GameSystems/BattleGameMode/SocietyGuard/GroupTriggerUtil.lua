
local GroupTriggerUtil = {}

local GroupTriggerDataTable = require("GroupTriggerDataTable")
local TriggerBuffDataTable = require("TriggerBuffDataTable")

-- return tbTriggerBuffInfo
-- tbTriggerBuffInfo.nTriggerResId
-- tbTriggerBuffInfo.nBuffId
function GroupTriggerUtil:GetRandomBuffIdByGroupID(nGroupID)
    local tbGroupTriggerList = GroupTriggerDataTable:GetGroup(nGroupID)
    if tbGroupTriggerList == nil then
        logerror('GroupTriggerUtil:GetRandomBuffIdByGroupId() is nil group id : ', nGroupID)
        return nil
    end
    local nGroupCount = #tbGroupTriggerList
    local nRandomIndex = math.random(1, nGroupCount)
    local tbTriggerBuffTemplate = tbGroupTriggerList[nRandomIndex]
    local tbTriggerBuffInfo = TriggerBuffDataTable:GetTemplateId(tbTriggerBuffTemplate.nTriggerBuffId)
    if tbTriggerBuffInfo == nil then
        logerror('GroupTriggerUtil:GetRandomBuffIdByGroupId() is nil trigger buff id : ', tbTriggerBuffTemplate.nTriggerBuffId)
        return nil
    end

    return tbTriggerBuffInfo
end

return GroupTriggerUtil
