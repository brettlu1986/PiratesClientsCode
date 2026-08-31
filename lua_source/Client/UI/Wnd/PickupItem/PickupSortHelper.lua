-----------------------------------------------------
--File Name    : PickupSortHelper.lua
--Author       : zhiyuan
--Create Time  : 2018-11-07
--Description  : 拾取列表排序的helper
-----------------------------------------------------
local PickupSortHelper = {}

function PickupSortHelper.Sort(tbItemProtoData1, tbItemProtoData2)
    if tbItemProtoData1.bIsAutoPickUp then
        if tbItemProtoData2.bIsAutoPickUp then
            return tbItemProtoData1.instance_id < tbItemProtoData2.instance_id
        else
            return true
        end
    else
        if tbItemProtoData2.bIsAutoPickUp then
            return false
        else
            if tbItemProtoData1.bIsBetter then
                if tbItemProtoData2.bIsBetter then
                    return tbItemProtoData1.instance_id < tbItemProtoData2.instance_id
                else
                    return true
                end
            else
                if tbItemProtoData2.bIsBetter then
                    return false
                else
                    return tbItemProtoData1.instance_id < tbItemProtoData2.instance_id
                end
            end
        end
    end
end

return PickupSortHelper
