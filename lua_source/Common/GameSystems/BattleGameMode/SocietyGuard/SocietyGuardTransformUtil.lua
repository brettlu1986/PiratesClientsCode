
local SocietyGuardTransfromUtil = {}

SocietyGuardTransfromUtil.tbJsonDataList = nil
SocietyGuardTransfromUtil.tbUsedList = nil
SocietyGuardTransfromUtil.tbFreeList = nil

--[[
    "Transform":
    {
        "X": -97840,
        "Y": 38720,
        "Z": 550,
        "Yaw": 0
    },
    "TransformId": 1
]]

function SocietyGuardTransfromUtil:Init()

end

function SocietyGuardTransfromUtil:Parse(tbTransformsJsonData)
    self.tbJsonDataList = tbTransformsJsonData
    self.tbFreeList = self.tbJsonDataList
    self.tbUsedList = {}
end

function SocietyGuardTransfromUtil:GetNextTransform()
    local tbFreeList = self.tbFreeList
    local tbUsedList = self.tbUsedList
    local nLastIndex = #tbFreeList
    if tbFreeList == nil or nLastIndex == 0 then
        return nil
    end

    local tbNext = tbFreeList[nLastIndex]
    table.insert(tbUsedList, tbNext)
    tbFreeList[nLastIndex] = nil
    return tbNext.Transform
end

function SocietyGuardTransfromUtil:GetNextRandomTransform()
    local tbFreeList = self.tbFreeList
    local tbUsedList = self.tbUsedList
    local nFreeCount = #tbFreeList
    
    if tbFreeList == nil or nFreeCount == 0 then
        return nil
    end

    
    local nIndex = math.random(1, nFreeCount)

    local tbNext = tbFreeList[nIndex]
    table.insert(tbUsedList, tbNext)
    table.remove(tbFreeList, nIndex)
    return tbNext.Transform
end

function SocietyGuardTransfromUtil:ModifyGroupNpcsTransform(tbNpcJsonDataList, tbTargetTransfrom, nCenterIndex)
    local tbCenterNpcJsonData = tbNpcJsonDataList[nCenterIndex]
    if tbCenterNpcJsonData == nil then
        error('SocietyGuardTransfromUtil:ModifyGroupNpcsTransform() center index not exist : ', nCenterIndex)
        return false
    end

    local tbCenterTransform = tbCenterNpcJsonData.Transform

    local nDeltaX = 0
    local nDeltaY = 0
    local nDeltaZ = 0
    local tbNpcTransform = nil
    for nIndex, tbNpcJsonData in pairs(tbNpcJsonDataList) do
        if nIndex ~= nCenterIndex then
            tbNpcTransform = tbNpcJsonData.Transform
            nDeltaX = tbCenterTransform.X - tbNpcTransform.X
            nDeltaY = tbCenterTransform.Y - tbNpcTransform.Y
            nDeltaZ = tbCenterTransform.Z - tbNpcTransform.Z
            tbNpcTransform.X = tbTargetTransfrom.X - nDeltaX
            tbNpcTransform.Y = tbTargetTransfrom.Y - nDeltaY
            tbNpcTransform.Z = tbTargetTransfrom.Z - nDeltaZ
            tbNpcTransform.Yaw = tbTargetTransfrom.Yaw
        end
    end

    tbCenterTransform.X = tbTargetTransfrom.X
    tbCenterTransform.Y = tbTargetTransfrom.Y
    tbCenterTransform.Z = tbTargetTransfrom.Z
    tbCenterTransform.Yaw = tbTargetTransfrom.Yaw
    
    return true
end

return SocietyGuardTransfromUtil
