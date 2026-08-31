local ShipUtilityExHelper = {}

--[[
    注意：通过此Helper调用ShipUtilityEx的函数时，需要用.而不是:，类比到C++的静态函数，不需要传Self
]]

-- luacheck: push ignore 231
local SHIP_UTILITY_EX_CLASS = "Blueprint'/Game/Game/ShipEx/Misc/BP_ShipUtilityEx.BP_ShipUtilityEx_C'"
local pShipUtilityEx = nil
local pHolder = nil

setmetatable(ShipUtilityExHelper, {
    __index = function(t, key)
        if pShipUtilityEx == nil then
            pShipUtilityEx = SHIP_UTILITY_EX_CLASS:load()
            pHolder = luaholder(pShipUtilityEx)
        end
        return pShipUtilityEx[key]
    end,
    __newindex = nil
})
-- luacheck: pop

-- 数据结构参考导出文件，目录 : /GameDataGenerated/common/ship_descriptors/
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local ShipWeaponFiringType = require("ShipWeaponFiringType")

local function GetExportedShipData(szShipClassPath)
    local szShipClassName = string.match(szShipClassPath, "%.(.*_C)")
    if szShipClassName then
        local tbShipData = require(szShipClassName)
        return tbShipData.tbComponents.ShipExportDataComponent.tbConfigs
    end
    return nil
end

local function IsInList(tbList, varData)
    for i,v in ipairs(tbList) do
        if v == varData then
            return true
        end
    end
    return false
end

function ShipUtilityExHelper.GetBulletMaxLoadingCount(szShipClassPath, szControlClass, nWeaponSlot, tbValidLevels)
    local tbExportedShipData = GetExportedShipData(szShipClassPath)
    if not tbExportedShipData then
        logerror("GetBulletMaxLoadingCount failed, cannot find export data. szShipClassPath =", szShipClassPath, debug.traceback())
    end
    local szWeaponSlot = ShipWeaponSlotDef.GetBPEnumName(nWeaponSlot)
    local tbSlotListShell = tbExportedShipData.tbWeaponSlot[szWeaponSlot]
    if not tbSlotListShell then -- 有可能有些船身上没有配置Slot
        return 0
    end
    local nSlotCount = 0
    local nSlotCountWithClass = 0
    for _, tbSlotData in ipairs(tbSlotListShell.tbData) do
        if IsInList(tbValidLevels, tbSlotData.nLevelIndex + 1) then
            if tbSlotData.szControlClass then
                if szControlClass == tbSlotData.szControlClass then
                    nSlotCountWithClass = nSlotCountWithClass + 1
                end
            else
                nSlotCount = nSlotCount + 1
            end
        end
    end
    if nSlotCountWithClass > 0 then -- 如果船身上有配专属ControlClass的Slot，以专属数量为准
        nSlotCount = nSlotCountWithClass
    end
    if (nWeaponSlot == ShipWeaponSlotDef.SIDE) or (nWeaponSlot == ShipWeaponSlotDef.UNKNOWN) then -- 如果是侧舷槽位/默认武器槽位，因为左右重复配置问题，数量需要/2
        nSlotCount = math.ceil(nSlotCount / 2) -- 保证数量是整数
    end
    return nSlotCount
end

function ShipUtilityExHelper.GetBulletMaxFiringCount(szShipClassPath, szControlClass, nWeaponSlot, tbValidLevels, nFiringType)
    if nFiringType == ShipWeaponFiringType.FIRING_WITH_ONE then
        return 1
    end
    local nMaxLoadingCount = ShipUtilityExHelper.GetBulletMaxLoadingCount(szShipClassPath, szControlClass, nWeaponSlot, tbValidLevels)
    if nFiringType == ShipWeaponFiringType.FIRING_WITH_ALL then
        return nMaxLoadingCount
    end
    if nFiringType == ShipWeaponFiringType.FIRING_WITH_ROW then
        return nMaxLoadingCount / (#tbValidLevels)
    end
    logerror("GetBulletMaxFiringCount failed, firing type is not valid. nFiringType =", nFiringType, debug.traceback())
    return 0
end

return ShipUtilityExHelper
