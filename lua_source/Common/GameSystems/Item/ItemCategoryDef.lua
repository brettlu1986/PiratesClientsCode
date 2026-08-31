-----------------------------------------------------
--File Name    : ItemCategoryDef.lua
--Author       : zhiyuan
--Create Time  : 2019-02-27
--Description  : 大厅道具大类型的枚举定义
-----------------------------------------------------
local ItemCategoryDef =
{
    DIRECTLY_USABLE         = 10,        -- 直接可使用的道具
    FASHION                 = 11,        -- 人的时装
    DECORATION              = 12,        -- 人的饰品
    GIFT_BOX                = 13,        -- 宝箱
    CURRENCY                = 14,        -- 货币
    SAILOR                  = 15,        -- 水手
    PARTNER                 = 16,        -- 伙伴
    SHIP                    = 17,        -- 舰船
    SHIP_WEAPON             = 18,        -- 舰船武器
    SHIP_PART               = 19,        -- 舰船零件
    SHIP_SKIN               = 20,        -- 舰船皮肤
    UNLOCK_ITEM             = 21,        -- 体验卡
    DECORATIVE_BUILDING     = 22,        -- 家园装饰物
    DATA_ITEM               = 23,        -- 客户端只是在奖励获得时需要这个类型
    HUMAN_WEAPON_FASHION    = 24,        -- 人武器时装
    SUIT                    = 25,        -- 人套装
}

local tbItemCategoryDatas = {}

local function RegisterItemCategoryData(bCanUseInBackpack)
    local tbRegisterCategoryData = {
        bCanUseInBackpack = bCanUseInBackpack
    }
    return tbRegisterCategoryData
end

tbItemCategoryDatas[ItemCategoryDef.DIRECTLY_USABLE]              = RegisterItemCategoryData(true)
tbItemCategoryDatas[ItemCategoryDef.FASHION]                      = RegisterItemCategoryData(false)
tbItemCategoryDatas[ItemCategoryDef.DECORATION]                   = RegisterItemCategoryData(false)
tbItemCategoryDatas[ItemCategoryDef.GIFT_BOX]                     = RegisterItemCategoryData(true)
tbItemCategoryDatas[ItemCategoryDef.CURRENCY]                     = RegisterItemCategoryData(false)
tbItemCategoryDatas[ItemCategoryDef.SAILOR]                       = RegisterItemCategoryData(true)
tbItemCategoryDatas[ItemCategoryDef.PARTNER]                      = RegisterItemCategoryData(false)
tbItemCategoryDatas[ItemCategoryDef.SHIP]                         = RegisterItemCategoryData(false)
tbItemCategoryDatas[ItemCategoryDef.SHIP_WEAPON]                  = RegisterItemCategoryData(false)
tbItemCategoryDatas[ItemCategoryDef.SHIP_PART]                    = RegisterItemCategoryData(false)
tbItemCategoryDatas[ItemCategoryDef.SHIP_SKIN]                    = RegisterItemCategoryData(false)
tbItemCategoryDatas[ItemCategoryDef.UNLOCK_ITEM]                  = RegisterItemCategoryData(true)
tbItemCategoryDatas[ItemCategoryDef.DECORATIVE_BUILDING]          = RegisterItemCategoryData(false)
tbItemCategoryDatas[ItemCategoryDef.DATA_ITEM]                    = RegisterItemCategoryData(false)

function ItemCategoryDef:CanUseInBackpack(nItemCategory)
    return tbItemCategoryDatas[nItemCategory].bCanUseInBackpack
end

return ItemCategoryDef
