--[[
    DataTable类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    tbContainer: table
    OnEditorParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnEditorParseFinished: 参数无，本DataTable读取完毕后触发
    OnGameRequired: 参数无，游戏运行时第一次require时触发
    OnEditorDefine: 定义导出参数    自定义导出标签：
         导出单行：-- [EXPORT]
         导出多行：-- [EXPORT BEGIN] 和 -- [EXPORT END]
--]]

local HumanWeaponCameraTimeDataTable = {}


HumanWeaponCameraTimeDataTable.szFileName = "common/ffa/item/human_weapon/weapon_movement_time.tab"

-- [EXPORT BEGIN]
local HumanMovementStateType = require("HumanMovementStateType")

local StateType = HumanMovementStateType
local BASE_TIME = 0.5
local tbStateKey =
{
    [StateType.UpRight_State] = "Upright",
    [StateType.Crouch_State]  = "Crouch",
    [StateType.Crawl_State]   = "Crawl",
    [StateType.Dying_State]   = "Dying",
    [StateType.Vehicle]       = "Vehicle",
}
-- [EXPORT END]

function HumanWeaponCameraTimeDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nWeaponId")
    Parser:Define("nWeaponId"               , "weapon_id"               , -1  , Parser.TypeInt)
    Parser:Define("szName"                  , "desc"                    , ""  , Parser.TypeString)
    Parser:Define("nUprightToCrouch"        , "upright_to_crouch"       , 0.0 , Parser.TypeFloat)
    Parser:Define("nUprightToCrawl"         , "upright_to_crawl"        , 0.0 , Parser.TypeFloat)
    Parser:Define("nCrouchToUpright"        , "crouch_to_upright"       , 0.0 , Parser.TypeFloat)
    Parser:Define("nCrawlToUpright"         , "crawl_to_upright"        , 0.0 , Parser.TypeFloat)
    Parser:Define("nCrawlToCrouch"          , "crawl_to_crouch"         , 0.0 , Parser.TypeFloat)
    Parser:Define("nCrouchToCrawl"          , "crouch_to_crawl"         , 0.0 , Parser.TypeFloat)
    Parser:Define("nUprightToDying"         , "upright_to_dying"         , 0.0 , Parser.TypeFloat)
    Parser:Define("nDyingToUpright"         , "dying_to_upright"         , 0.0 , Parser.TypeFloat)
    Parser:Define("nVehicleToDying"         , "vehicle_to_dying"         , 0.0 , Parser.TypeFloat)
end

-- [EXPORT BEGIN]

function HumanWeaponCameraTimeDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end

function HumanWeaponCameraTimeDataTable:GetMovementCameraTime(nWeaponId, nLastMovementState, nCurrentMovementState)
    local tbWeaponTime = self:GetTemplate(nWeaponId)

    local szLastStateKey = tbStateKey[nLastMovementState]
    local szCurrentStateKey = tbStateKey[nCurrentMovementState]
    if tbWeaponTime then
        local bHasStateKey = szLastStateKey and szCurrentStateKey
        if bHasStateKey then
            local szKey = string.format("n%sTo%s", szLastStateKey, szCurrentStateKey)
            if tbWeaponTime[szKey] then
                return tbWeaponTime[szKey]
            end
        end
    end
    return BASE_TIME
end
-- [EXPORT END]

return HumanWeaponCameraTimeDataTable
