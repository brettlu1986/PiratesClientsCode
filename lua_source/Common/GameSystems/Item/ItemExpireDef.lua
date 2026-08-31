-----------------------------------------------------
--File Name    : ItemExpireDef.lua
--Description  : Item过期类型的定义
-----------------------------------------------------

local ItemExpireDef =
{
    NORMAL     = 0,
    STACK_TIME = 1,
}

local tbItemExpireTypeStrings = {}

tbItemExpireTypeStrings[ItemExpireDef.NORMAL] = "NORMAL"
tbItemExpireTypeStrings[ItemExpireDef.STACK_TIME] = "STACK_TIME"

function ItemExpireDef.GetExpireType(szType)
    for nType, v in pairs(tbItemExpireTypeStrings) do
        if v == szType then
            return nType
        end
    end
    error("ItemExpireDef:GetExpireType failed!"..szType)
end

return ItemExpireDef
