-----------------------------------------------------
--File Name    : HumanWeaponAttachmentDataTableHelper.lua
--Author       : WuJizhou
--Create Time  : 8/29/2018, 12:05:53 PM
--Description  : HumanWeaponAttachmentDataTableHelper
-----------------------------------------------------
local HumanWeaponAttachmentDataTableHelper = {}

-- local HumanWeaponDataTableHelperBase = require("HumanWeaponDataTableHelperBase")
-- local HumanWeaponRecoilDataTable = require("HumanWeaponRecoilDataTable")
-- local PROPERTY_CONFIG_COUNT = 4

-- local function ParseWeaponPropertyConfig(Parser, NewTemplate)
--     local tbProperty = NewTemplate.tbProperty
--     if tbProperty == nil then
--         tbProperty = {}
--         NewTemplate.tbProperty = tbProperty
--     end

--     for idx = 1, PROPERTY_CONFIG_COUNT do
--         local szProperty = Parser:Get("property_"..idx, "", Parser.TypeString)
--         local nAddValue = Parser:Get("add_value_"..idx, 0.0, Parser.TypeFloat)
--         local nMultiplyValue = Parser:Get("multiply_value_"..idx, 1.0, Parser.TypeFloat)
--         local nReplaceValue = Parser:Get("replace_value_"..idx, nil, Parser.TypeFloat)  --logic needed, then set default value to nil
--         if szProperty ~= "" then
--             local szPropertyField = HumanWeaponDataTableHelperBase.GetPropertyField(szProperty)
--             if not szPropertyField then
--                 szPropertyField = HumanWeaponRecoilDataTable:GetPropertyField(szProperty)
--             end
--             if szPropertyField ~= nil then
--                 NewTemplate.tbProperty[szPropertyField] = {nAddValue, nMultiplyValue, nReplaceValue}
--             else
--                 error(szProperty .. " is illegal!")
--             end
--         end
--     end
-- end

function HumanWeaponAttachmentDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nCapacity               = Parser:Get("capacity"                     , -1    , Parser.TypeInt)
    NewTemplate.nAttachmentCategory     = Parser:Get("attachment_category"          , 1     , Parser.TypeInt)
    NewTemplate.nAvatarId               = Parser:Get("avatar_id"                    , -1    , Parser.TypeInt)
    NewTemplate.tbBuffIds               = Parser:Get("buff_ids"                     , -1    , Parser.TypeArrayInt)
    -- ParseWeaponPropertyConfig(Parser, NewTemplate)
end

return HumanWeaponAttachmentDataTableHelper