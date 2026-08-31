-----------------------------------------------------
--File Name    : GMQADataTable.lua
--Author       : Song Fuhao
--Create Time  : 2019-07-02
--Description  : QA用GM面板配置
-----------------------------------------------------
local GMQADataTable = {}

-- [EXPORT BEGIN]
local TYPE_LOBBY = 1
local TYPE_DUNGEON = 2
local TYPE_ALL = 3
-- [EXPORT END]

-- @Override
GMQADataTable.szFileName = "client/ui/debug/gm_qa.tab"

-- @Override
function GMQADataTable:OnEditorDefine(Parser)
    Parser:Define("szCommandDisplayName", "command_display_name", "", Parser.TypeString)
    Parser:Define("szCommand"           , "command"             , "", Parser.TypeString)
end

-- @Override
function GMQADataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nGroupId = Parser:Get("group_id", -1, Parser.TypeInt)
    local tbGroup = tbContainer[nGroupId]
    if not tbGroup then
        tbGroup = {}
        tbGroup.nGroupId    = nGroupId
        tbGroup.nGroupType  = Parser:Get("group_type"   , -1, Parser.TypeInt)
        tbGroup.szGroupName = Parser:Get("group_name"   , "", Parser.TypeString)
        tbGroup.tbCommandList = {}
        tbContainer[nGroupId] = tbGroup
    end
    table.insert(tbGroup.tbCommandList, tbNewTemplate)
    return true
end

-- @Override
function GMQADataTable:OnEditorParseFinished()
    local tbNewContainer = {
        [TYPE_LOBBY] = {},
        [TYPE_DUNGEON] = {}
    }
    for _, tbGroup in pairs(self.tbContainer) do
        if tbGroup.nGroupType == TYPE_ALL then
            table.insert(tbNewContainer[TYPE_LOBBY], tbGroup)
            table.insert(tbNewContainer[TYPE_DUNGEON], tbGroup)
        else
            table.insert(tbNewContainer[tbGroup.nGroupType], tbGroup)
        end
    end

    local function SortGourpList(tbGroupA, tbGroupB)
        return tbGroupA.nGroupId < tbGroupB.nGroupId
    end
    table.sort(tbNewContainer[TYPE_LOBBY], SortGourpList)
    table.sort(tbNewContainer[TYPE_DUNGEON], SortGourpList)

    self.tbContainer = tbNewContainer
end

-- [EXPORT BEGIN]
function GMQADataTable:GetLobbyCommandGroupList()
    return self.tbContainer[TYPE_LOBBY]
end

function GMQADataTable:GetDungeonCommandGroupList()
    return self.tbContainer[TYPE_DUNGEON]
end
-- [EXPORT END]

return GMQADataTable

--[[ tbContainer结构
[
    [
        {
            "tbCommandList": [
                {
                    "szCommandDisplayName": "007",
                    "szCommand": "startmatchmaking 100011 1 true 007"
                },
                {
                    "szCommandDisplayName": "蒙娜丽莎",
                    "szCommand": "startmatchmaking 100011 1 true mnls"
                }
            ],
            "nGroupType": 1,
            "nGroupId": 101,
            "szGroupName": "单开房间"
        }
    ],
    [
        {
            "tbCommandList": [
                {
                    "szCommandDisplayName": "跳过等待阶段到选点阶段",
                    "szCommand": "dm setboolvalue SkipFFAWaitTime true"
                },
                {
                    "szCommandDisplayName": "跳过选点阶段到跳伞阶段",
                    "szCommand": "dm setboolvalue SkipFFASelectionPoint true"
                }
            ],
            "nGroupType": 2,
            "nGroupId": 201,
            "szGroupName": "副本流程控制"
        },
        {
            "tbCommandList": [
                {
                    "szCommandDisplayName": "集合岛",
                    "szCommand": "dm teleport 947356 227599 920"
                },
                {
                    "szCommandDisplayName": "矿山遗迹",
                    "szCommand": "dm teleport -314035 -305086 4500"
                }
            ],
            "nGroupType": 2,
            "nGroupId": 202,
            "szGroupName": "人传送"
        }
    ]
]
]]