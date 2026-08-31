-----------------------------------------------------
--File Name    : UIResourceDef.lua
--Author       : Song Fuhao
--Create Time  : 2017-04-07
--Description  : UI相关资源定义
-----------------------------------------------------
local UIResourceDef = {}

local DCProto = require("DungeonCommonProtoNames")
local ControlModeDef = require("ControlModeDef")
local UIColorDef = require("UIColorDef")

local GetLinearColorFunc = KMUMGLibrary.GetLinearColor
local GetSlateColorFunc = KMUMGLibrary.GetSlateColor

------------------------------------字号-----------------------------------
UIResourceDef.FONT_SIZE =
{
    TITLE1 = 48,
    TITLE2 = 36,
    TITLE3 = 30,
    TITLE4 = 72,
    NORMAL1 = 24,
    NORMAL2 = 20,
    NORMAL3 = 18,
    NORMAL4 = 22,
}

------------------------------------颜色---------------------------------------
UIResourceDef.COLOR = UIColorDef

UIResourceDef.FONT_GRADE_COLOR =
{
    [0] = UIColorDef.WHITE["SLATE_COLOR"],
    [1] = UIColorDef.GREEN["SLATE_COLOR"],
    [2] = UIColorDef.BLUE["SLATE_COLOR"],
    [3] = UIColorDef.PURPLE["SLATE_COLOR"],
    [4] = UIColorDef.ORANGE["SLATE_COLOR"],
}

UIResourceDef.TEAM_INDEX_COLOR = {
    [1] = UIColorDef.YELLOW.LINEAR_COLOR,  --黄
    [2] = UIColorDef.ORANGE1.LINEAR_COLOR,  --橙
    [3] = UIColorDef.BLUE.LINEAR_COLOR,  --蓝
    [4] = UIColorDef.GREEN.LINEAR_COLOR,  --绿
}

UIResourceDef.TEAM_INDEX_SLATECOLOR = {
    [1] = UIColorDef.YELLOW.SLATE_COLOR,  --黄
    [2] = UIColorDef.ORANGE1.SLATE_COLOR,  --橙
    [3] = UIColorDef.BLUE.SLATE_COLOR,  --蓝
    [4] = UIColorDef.GREEN.SLATE_COLOR,  --绿
}

UIResourceDef.TEAM_INDEX_COLOR_TRANSPARENT = {
    [1] = UIColorDef.YELLOW.LINEAR_COLOR_TRANSPARENT,  --黄
    [2] = UIColorDef.ORANGE1.LINEAR_COLOR_TRANSPARENT,  --橙
    [3] = UIColorDef.BLUE.LINEAR_COLOR_TRANSPARENT,  --蓝
    [4] = UIColorDef.GREEN.LINEAR_COLOR_TRANSPARENT,  --绿
}

UIResourceDef.FFA_SAIL_CONTROL_DIRECTION_LINEAR_COLOR = {
    [1] = UIColorDef.GREEN.LINEAR_COLOR,
    [2] = UIColorDef.GREEN.LINEAR_COLOR,
    [3] = UIColorDef.WHITE.LINEAR_COLOR,
    [4] = UIColorDef.YELLOW.LINEAR_COLOR
}

UIResourceDef.NPC_HEAD_NAME_COLOR =
{
    [1] = UIColorDef.WHITE.SLATE_COLOR,        --和平
    [2] = UIColorDef.RED.SLATE_COLOR,          --主动
    [3] = UIColorDef.ORANGE1.SLATE_COLOR,      --被动
}

-------------------------------------图标----------------------------------

--[[
    战斗相关
]]
-- 技能面板相关
UIResourceDef.SKILL_AIM_NORMAL                  = "PaperSprite'/Game/UI/Textures/Skill02/Frames/Spr_Skill_03_Normal.Spr_Skill_03_Normal'"
UIResourceDef.SKILL_AIM_PRESSED                 = "PaperSprite'/Game/UI/Textures/Skill02/Frames/Spr_Skill_03_Pressed.Spr_Skill_03_Pressed'"
UIResourceDef.SKILL_AIM_CANCEL_NORMAL           = "PaperSprite'/Game/UI/Textures/Skill02/Frames/Spr_Skill_06_Normal.Spr_Skill_06_Normal'"
UIResourceDef.SKILL_AIM_CANCEL_PRESSED          = "PaperSprite'/Game/UI/Textures/Skill02/Frames/Spr_Skill_06_Pressed.Spr_Skill_06_Pressed'"
UIResourceDef.SKILL_FIRE_CANNON_NORMAL          = "PaperSprite'/Game/UI/Textures/Skill02/Frames/Spr_Skill_01_Normal.Spr_Skill_01_Normal'"
UIResourceDef.SKILL_FIRE_CANNON_PRESSED         = "PaperSprite'/Game/UI/Textures/Skill02/Frames/Spr_Skill_01_Pressed.Spr_Skill_01_Pressed'"
UIResourceDef.SKILL_FIRE_TORPEDO_NORMAL         = "PaperSprite'/Game/UI/Textures/Skill02/Frames/Spr_Skill_02_Normal.Spr_Skill_02_Normal'"
UIResourceDef.SKILL_FIRE_TORPEDO_PRESSED        = "PaperSprite'/Game/UI/Textures/Skill02/Frames/Spr_Skill_02_Pressed.Spr_Skill_02_Pressed'"
UIResourceDef.SKILL_FIRE_CHANGE_CANNON          = "PaperSprite'/Game/UI/Textures/Skill02/Frames/Spr_FireCannon.Spr_FireCannon'"
UIResourceDef.SKILL_FIRE_CHANGE_TORPEDO         = "PaperSprite'/Game/UI/Textures/Skill02/Frames/Spr_FireTorpedo.Spr_FireTorpedo'"


-- 船只头顶血条

UIResourceDef.BATTLE_COMMAND_HEAD_RES = {
    "PaperSprite'/Game/UI/Textures/UI_BattleMain02/Frames/Spr_BtnAttack02.Spr_BtnAttack02'",
    "PaperSprite'/Game/UI/Textures/UI_BattleMain02/Frames/Spr_BtnSet02.Spr_BtnSet02'",
    "PaperSprite'/Game/UI/Textures/UI_BattleMain02/Frames/Spr_BtnBack02.Spr_BtnBack02'"
}

-- 未装备配件时的图标
UIResourceDef.ACCESSORY_BG_RESOURCE = {
   "PaperSprite'/Game/UI/Textures/AccessoriesIcon/Frames/Spr_AccessoriesIcon_04.Spr_AccessoriesIcon_04'", -- 船首像
   "PaperSprite'/Game/UI/Textures/AccessoriesIcon/Frames/Spr_AccessoriesIcon_01.Spr_AccessoriesIcon_01'", -- 船锚
   "PaperSprite'/Game/UI/Textures/AccessoriesIcon/Frames/Spr_AccessoriesIcon_02.Spr_AccessoriesIcon_02'", -- 船帆
   "PaperSprite'/Game/UI/Textures/AccessoriesIcon/Frames/Spr_AccessoriesIcon_03.Spr_AccessoriesIcon_03'"  -- 船灯
}

-- 未装备消耗品时的图标
UIResourceDef.CONSUMABLE_BG_RESOURCE = {
   "PaperSprite'/Game/UI/Textures/AccessoriesIcon/Frames/Spr_AccessoriesIcon_05.Spr_AccessoriesIcon_05'", -- 旗子
   "PaperSprite'/Game/UI/Textures/AccessoriesIcon/Frames/Spr_AccessoriesIcon_06.Spr_AccessoriesIcon_06'", -- 涂装
   "PaperSprite'/Game/UI/Textures/AccessoriesIcon/Frames/Spr_AccessoriesIcon_07.Spr_AccessoriesIcon_07'"  -- 炮弹
}

-- 装配还是卸下配件或消耗品的效果图标
UIResourceDef.SELECT_ITEM_EFFECT = "PaperSprite'/Game/UI/Textures/AccessoriesIcon/Frames/Spr_Up.Spr_Up'"
UIResourceDef.RESET_ITEM_EFFECT = "PaperSprite'/Game/UI/Textures/AccessoriesIcon/Frames/Spr_Down.Spr_Down'"

-- tabbutton的图标
UIResourceDef.TAB_BUTTON_DISABLE = "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_TabBigDisable.Spr_TabBigDisable'"

-- 物品左上角角标
UIResourceDef.ITEM_NEW = "PaperSprite'/Game/UI/Textures/Common/Frames/Spr_NewShip.Spr_NewShip'"
UIResourceDef.ITEM_TIME_LIMIT = "PaperSprite'/Game/UI/Textures/Common/Frames/Spr_Time.Spr_Time'"

--[[
    船类型图标
]]
UIResourceDef.SHIP_FLAG_BORDER = {
    "PaperSprite'/Game/UI/Textures/Common/Frames/Spr_BorderBattleship.Spr_BorderBattleship'",   -- 战列舰
    "PaperSprite'/Game/UI/Textures/Common/Frames/Spr_BorderFrigate.Spr_BorderFrigate'",         -- 护卫舰
    "PaperSprite'/Game/UI/Textures/Common/Frames/Spr_BorderPirate.Spr_BorderPirate'",           -- 炮艇
}

UIResourceDef.BOSS_FLAG_GRAY = "PaperSprite'/Game/UI/Textures/Common/Frames/Spr_BossLogo.Spr_BossLogo'"
UIResourceDef.BOSS_FLAG_BORDER = "PaperSprite'/Game/UI/Textures/Common/Frames/Spr_BorderBossLogo.Spr_BorderBossLogo'"

--任务Spr_Repair
UIResourceDef.DIALOG_OPEN_UI    = "PaperSprite'/Game/UI/Textures/UI_Interaction/Frames/Spr_Repair.Spr_Repair'"
UIResourceDef.DIALOG_CANCEL    = "PaperSprite'/Game/UI/Textures/UI_Interaction/Frames/Spr_Close.Spr_Close'"
UIResourceDef.QUEST_ACCEPT    = "PaperSprite'/Game/UI/Textures/UI_Interaction/Frames/Spr_MissionAccept.Spr_MissionAccept'"
UIResourceDef.QUEST_TEXT   = "PaperSprite'/Game/UI/Textures/UI_Interaction/Frames/Spr_MissionOmitted.Spr_MissionOmitted'"
UIResourceDef.QUEST_QUREY    = "PaperSprite'/Game/UI/Textures/UI_Interaction/Frames/Spr_MissionUnknown.Spr_MissionUnknown'"
UIResourceDef.QUEST_ACCEPT_HEAD = "PaperSprite'/Game/UI/Textures/UI_WorldMap/Frames/Spr_Questsign_npc.Spr_Questsign_npc'"
UIResourceDef.QUEST_COMPLETE_HEAD = "PaperSprite'/Game/UI/Textures/UI_WorldMap/Frames/Spr_Subquestsign_npc.Spr_Subquestsign_npc'"
UIResourceDef.QUEST_ACCEPT_MAP = "PaperSprite'/Game/UI/Textures/UI_WorldMap/Frames/Spr_Questarea_map.Spr_Questarea_map'"
UIResourceDef.QUEST_COMPLETE_MAP = "PaperSprite'/Game/UI/Textures/UI_WorldMap/Frames/Spr_Subquestarea_map.Spr_Subquestarea_map'"
UIResourceDef.QUEST_COMPLETE = "PaperSprite'/Game/UI/Textures/ArtNumber/Frames/Spr_MissonCop.Spr_MissonCop'"

--[[
    道具格子加号
]]
UIResourceDef.ITEM_ADD = "PaperSprite'/Game/UI/Textures/GameMaterial/Frames/Spr_IconAdd.Spr_IconAdd'"

--贸易
UIResourceDef.TRADE_COMPLETE = "PaperSprite'/Game/UI/Textures/ArtNumber/Frames/Spr_DealCop.Spr_DealCop'"

UIResourceDef.INTERACTION_BTN =
{

    "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_Explore_02.Spr_Explore_02'", --对话1
    "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_Capture_01.Spr_Capture_01'", --采集2
    "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_BtnFighting.Spr_BtnFighting'", --战斗3
    "PaperSprite'/Game/UI/Textures/UI_GoFishing/Frames/Spr_GoFish_02.Spr_GoFish_02'", -- 钓鱼4
    "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_BtnFighting.Spr_BtnFighting'", --战斗5
    "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_Capture_01.Spr_Capture_01'", --海上随机采集6
    "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_Capture_01.Spr_Capture_01'", --陆地采集7
    "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_Capture_01.Spr_Capture_01'", --陆地采集8
    "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_Capture_01.Spr_Capture_01'", --陆地采集9
    "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_BtnExplore.Spr_BtnExplore'", --勘测10
    "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_BtnFlare.Spr_BtnFlare'",  -- 信号弹11
    "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_BtnMagiccircle.Spr_BtnMagiccircle'",  -- 法阵12
    "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_BtnPlunder.Spr_BtnPlunder'",  -- 掠夺13
    "PaperSprite'/Game/UI/Textures/UI_GoFishing/Frames/Spr_GoFish_02.Spr_GoFish_02'", -- 人変船，船変人
}

UIResourceDef.SHIP_PART_BUFF =
{
    "PaperSprite'/Game/UI/Textures/BuffIconNew/Frames/Spr_BuffSailDamaged_01.Spr_BuffSailDamaged_01'",
    "PaperSprite'/Game/UI/Textures/BuffIconNew/Frames/Spr_BuffRudderDamaged_01.Spr_BuffRudderDamaged_01'",
    "",
    "PaperSprite'/Game/UI/Textures/BuffIconNew/Frames/Spr_BuffIgnition_01.Spr_BuffIgnition_01'",
    "PaperSprite'/Game/UI/Textures/BuffIconNew/Frames/Spr_BuffBilging_01.Spr_BuffBilging_01'"
}




UIResourceDef.SAIL_CONTROL_GEAR = {
    [4] = '/Game/UI/Textures/Common/Frames/Spr_SailUp.Spr_SailUp',
    [3] = '/Game/UI/Textures/Common/Frames/Spr_SailUp02.Spr_SailUp02',
    [2] = '/Game/UI/Textures/Common/Frames/Spr_SailDown.Spr_SailDown',
    [1] = '/Game/UI/Textures/Common/Frames/Spr_SailDown.Spr_SailDown',
}

UIResourceDef.FFA_SAIL_CONTROL_GEAR = {
    [1] = '/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Sail_06_Pressed.Spr_Sail_06_Pressed',
    [2] = '/Game/UI/FFA/Textures/UI_FFAComon/Frames/Spr_SailTurn.Spr_SailTurn',
    [3] = '/Game/UI/Textures/Common/Frames/Spr_SailDown.Spr_SailDown',
    [4] = '/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Sail_06_Pressed.Spr_Sail_06_Pressed',
    [5] = '/Game/UI/FFA/Textures/UI_FFAComon/Frames/Spr_SailTurn.Spr_SailTurn',	-- 停船时
}



UIResourceDef.PVP_BADGE_EFFECT = "ParticleSystem'/Game/Resources/Effects/UI/PS_UI_Smash_01.PS_UI_Smash_01'"
UIResourceDef.PVP_DIVISION_EFFECT = "ParticleSystem'/Game/Resources/Effects/UI/PS_UI_Flow_01.PS_UI_Flow_01'"

-- M地图
UIResourceDef.GATHER_POINT = "PaperSprite'/Game/UI/Textures/UI_WorldMap/Frames/Spr_GatherPoint_map.Spr_GatherPoint_map'"
UIResourceDef.EMERGENCY_DELIVERY = "PaperSprite'/Game/UI/Textures/UI_WorldMap/Frames/Spr_IconEmergencyDelivery.Spr_IconEmergencyDelivery'"
UIResourceDef.BIG_PORT_MAP = "PaperSprite'/Game/UI/Textures/UI_WorldMap/Frames/Spr_BigPort_map.Spr_BigPort_map'"
UIResourceDef.SMALL_PORT_MAP = "PaperSprite'/Game/UI/Textures/UI_WorldMap/Frames/Spr_SmallPort_map.Spr_SmallPort_map'"
UIResourceDef.NAVIGATION_POINT = "PaperSprite'/Game/UI/Textures/UI_WorldMap/Frames/Spr_NavigationPoint.Spr_NavigationPoint'"
UIResourceDef.COMPLETED_WORKSHOP = "PaperSprite'/Game/UI/Textures/UI_WorldMap/Frames/Spr_WorkshopCompleted.Spr_WorkshopCompleted'"
UIResourceDef.QUEST_POINT_TAG_FINISHED = "PaperSprite'/Game/UI/Textures/UI_WorldMap/Frames/Spr_QuestTagComplete.Spr_QuestTagComplete'"
UIResourceDef.QUEST_POINT_TAG_UNFINISHED = "PaperSprite'/Game/UI/Textures/UI_WorldMap/Frames/Spr_QuestTagunfinished.Spr_QuestTagunfinished'"
UIResourceDef.RADAR_MAP_OTHER_PLAYER = "PaperSprite'/Game/UI/Textures/UI_RadarMap/Frames/Spr_MiniMap_Other.Spr_MiniMap_Other'"
UIResourceDef.TRANSFER_POINT = "PaperSprite'/Game/UI/Textures/UI_WorldMap/Frames/Spr_Transfer_Map.Spr_Transfer_Map'"

--Loading图
UIResourceDef.LOADING_BG_DUNGEN = "Texture2D'/Game/UI/Textures/UI_Loading/BGTextures/T_LoadingBg_22_UI.T_LoadingBg_22_UI'"
UIResourceDef.LOADING_BG_BIG_WORLD = "Texture2D'/Game/UI/Textures/UI_Loading/BGTextures/T_LoadingBg_1_UI.T_LoadingBg_1_UI'"

UIResourceDef.PLAYER_AVATAR_MALE = "PaperSprite'/Game/UI/Textures/Common/Frames/Spr_ManHead_01.Spr_ManHead_01'"
UIResourceDef.PLAYER_AVATAR_FAMALE = "PaperSprite'/Game/UI/Textures/Common/Frames/Spr_WomanHead_01.Spr_WomanHead_01'"

UIResourceDef.PLAYER_AVATAR_MALE_02 = "PaperSprite'/Game/UI/FFA/Textures/UI_GameHall/Frames/Spr_WomanHead.Spr_WomanHead'"
UIResourceDef.PLAYER_AVATAR_FAMALE_02 = "PaperSprite'/Game/UI/FFA/Textures/UI_GameHall/Frames/Spr_ManHead.Spr_ManHead'"

UIResourceDef.PLAYER_AVATAR_MALE_UI_MAIN = "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_ManTitle.Spr_ManTitle'"
UIResourceDef.PLAYER_AVATAR_FAMALE_UI_MAIN = "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_WomenTitle.Spr_WomenTitle'"

-- 好友之心宝箱
UIResourceDef.FRIEND_HEART_FIRST_REWARD_BOX = "PaperSprite'/Game/UI/Textures/UI_FriendMain/Frames/Spr_Friend_08_png.Spr_Friend_08_png'"
UIResourceDef.FRIEND_HEART_SECOND_REWARD_BOX = "PaperSprite'/Game/UI/Textures/UI_FriendMain/Frames/Spr_Friend_07.Spr_Friend_07'"

UIResourceDef.PLAYER_EXIT_CRUISE = "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_ShipFlyClose.Spr_ShipFlyClose'"
UIResourceDef.PLAYER_ENTER_CRUISE = "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_ShipFlyOpen.Spr_ShipFlyOpen'"

-- 首胜图标
UIResourceDef.SPR_FIRST_WIN = '/Game/UI/Textures/UI_Pvp/Frames/Spr_FiresWin.Spr_FiresWin'
--银币图标
UIResourceDef.SPR_SILVER = "PaperSprite'/Game/UI/Textures/Common/Frames/Spr_IconGold.Spr_IconGold'"
--金币图标
UIResourceDef.SPR_GOLD = "PaperSprite'/Game/UI/Textures/Common/Frames/Spr_IconMoney.Spr_IconMoney'"


-- 美术字 0 - 9
UIResourceDef.tbQueueStateArtNumberPathList =
{
    '/Game/UI/Textures/UI_Pvp/Frames/Spr_Number_00.Spr_Number_00',
    '/Game/UI/Textures/UI_Pvp/Frames/Spr_Number_01.Spr_Number_01',
    '/Game/UI/Textures/UI_Pvp/Frames/Spr_Number_02.Spr_Number_02',
    '/Game/UI/Textures/UI_Pvp/Frames/Spr_Number_03.Spr_Number_03',
    '/Game/UI/Textures/UI_Pvp/Frames/Spr_Number_04.Spr_Number_04',
    '/Game/UI/Textures/UI_Pvp/Frames/Spr_Number_05.Spr_Number_05',
    '/Game/UI/Textures/UI_Pvp/Frames/Spr_Number_06.Spr_Number_06',
    '/Game/UI/Textures/UI_Pvp/Frames/Spr_Number_07.Spr_Number_07',
    '/Game/UI/Textures/UI_Pvp/Frames/Spr_Number_08.Spr_Number_08',
    '/Game/UI/Textures/UI_Pvp/Frames/Spr_Number_09.Spr_Number_09'

}

-- 竞技场选项卡背景图
UIResourceDef.PVP_SELECT_CARD_BG_01 = "PaperSprite'/Game/UI/Textures/UI_Pvp/Frames/Spr_PvpBg_01.Spr_PvpBg_01'"
UIResourceDef.PVP_SELECT_CARD_BG_02 = "PaperSprite'/Game/UI/Textures/UI_Pvp/Frames/Spr_PvpBg_02.Spr_PvpBg_02'"
UIResourceDef.PVP_SELECT_CARD_BG_03 = "PaperSprite'/Game/UI/Textures/UI_Pvp/Frames/Spr_PvpBg_03.Spr_PvpBg_03'"

-- 音效ID
UIResourceDef.SC_COUNTDOWN_END      = 10003
UIResourceDef.SC_BATTLE_WIN         = 10004
UIResourceDef.SC_BATTLE_LOSE        = 10005
UIResourceDef.SC_QUEST_COMPLETE     = 10006
UIResourceDef.SC_TRADE_COMPLETE     = 10007
UIResourceDef.SC_FOUND_ENEMY        = 10008
UIResourceDef.SC_FIRE_ALL           = 10009
UIResourceDef.SC_FIRST_SAIL         = 10010
UIResourceDef.SC_SHIP_STEERING      = 10011
UIResourceDef.SC_CAUSED_SUNK        = 10012
UIResourceDef.SC_MOUNTAIN_CRASH     = 10013
UIResourceDef.SC_BE_FOUND_BY_ENEMY  = 10014
UIResourceDef.SC_CANNON_HIT_CORE    = 10015
UIResourceDef.SC_BATTLE_START       = 10016
UIResourceDef.SC_FISHING_START      = 10017
UIResourceDef.SC_FISHING_BITE       = 10018
UIResourceDef.SC_FISHING_SUCCESS    = 10019
UIResourceDef.SC_FISHING_FAIL       = 10020
UIResourceDef.SC_COMMAND_GATHER     = 10025
UIResourceDef.SC_COMMAND_ATTACK     = 10026
UIResourceDef.SC_COMMAND_SOS        = 10027
UIResourceDef.SC_TOOK_SEVERITY      = 10028
UIResourceDef.SC_OCCUPY_SUCCESS     = 10029
UIResourceDef.SC_SHIP_WEAPON_LOAD   = 600005
UIResourceDef.SC_SHIP_OCEAN_ENV     = 800001
UIResourceDef.SC_SHIP_SAILING       = 800002
UIResourceDef.SC_SHIP_RISE_SAIL     = 600014
UIResourceDef.SC_SHIP_DOWN_SAIL     = 600015

UIResourceDef.SC_EQUIP_ATTACHMENT   = 700014
UIResourceDef.SC_UNEQUIP_ATTACHMENT = 700015
UIResourceDef.SC_DISCARD_ATTACHMENT = 700016

UIResourceDef.SC_SELECTION_POINT    = 900038

-- 势力
UIResourceDef.tbFactionIcons =
{
    '/Game/UI/Textures/UI_Faction/Frames/Spr_Faction_03.Spr_Faction_03',
    '/Game/UI/Textures/UI_Faction/Frames/Spr_Faction_02.Spr_Faction_02',
    '/Game/UI/Textures/UI_Faction/Frames/Spr_Faction_01.Spr_Faction_01',
}

UIResourceDef.tbFactionUIMainIcons =
{
    '/Game/UI/Textures/UI_Faction/Frames/Spr_Faction_07.Spr_Faction_07',
    '/Game/UI/Textures/UI_Faction/Frames/Spr_Faction_06.Spr_Faction_06',
    '/Game/UI/Textures/UI_Faction/Frames/Spr_Faction_05.Spr_Faction_05',
}


UIResourceDef.tbSelectPlayerHeadIcon =
{
    '/Game/UI/Textures/UI_CreateRoles/Frames/Spr_Roles_12.Spr_Roles_12',    -- 欧洲男
    '/Game/UI/Textures/UI_CreateRoles/Frames/Spr_Roles_11.Spr_Roles_11',    -- 欧洲女
    '/Game/UI/Textures/UI_CreateRoles/Frames/Spr_Roles_14.Spr_Roles_14',    -- 亚洲男
    '/Game/UI/Textures/UI_CreateRoles/Frames/Spr_Roles_13.Spr_Roles_13',    -- 亚洲女
    '/Game/UI/Textures/UI_CreateRoles/Frames/Spr_Roles_16.Spr_Roles_16',    -- 波斯男
    '/Game/UI/Textures/UI_CreateRoles/Frames/Spr_Roles_15.Spr_Roles_15',    -- 波斯女
}

--PuzzleGame
UIResourceDef.PUZZLE_ITEM_MATERIAL = "Material'/Game/UI/Materials/M_PuzzleItem_UI.M_PuzzleItem_UI'"
UIResourceDef.PUZZLE_ITEM_MASK = {
    "Texture2D'/Game/UI/Textures/UI_Puzzle/Textures/T_UI_PuzzleMask_01_UI.T_UI_PuzzleMask_01_UI'",
    "Texture2D'/Game/UI/Textures/UI_Puzzle/Textures/T_UI_PuzzleMask_02_UI.T_UI_PuzzleMask_02_UI'",
    "Texture2D'/Game/UI/Textures/UI_Puzzle/Textures/T_UI_PuzzleMask_03_UI.T_UI_PuzzleMask_03_UI'",
    "Texture2D'/Game/UI/Textures/UI_Puzzle/Textures/T_UI_PuzzleMask_04_UI.T_UI_PuzzleMask_04_UI'",
}

-- 协会任务
UIResourceDef.tbLevelStar =
{
    "PaperSprite'/Game/UI/Textures/UI_Association_UI/Frames/Spr_Star.Spr_Star'",
    "PaperSprite'/Game/UI/Textures/UI_Association_UI/Frames/Spr_StarBg.Spr_StarBg'"
}

--零件改造
UIResourceDef.tbModPart =
{
    "PaperSprite'/Game/UI/Textures/UI_ShipEquip/Frames/Spr_ShipEquip_09.Spr_ShipEquip_09'"
}


--活跃度
UIResourceDef.tbOpenBoxImg =
{
    "PaperSprite'/Game/UI/Textures/UI_Sign/Frames/Spr_Box01_02.Spr_Box01_02'",
    "PaperSprite'/Game/UI/Textures/UI_Sign/Frames/Spr_Box02_02.Spr_Box02_02'",
    "PaperSprite'/Game/UI/Textures/UI_Sign/Frames/Spr_Box03_02.Spr_Box03_02'",
    "PaperSprite'/Game/UI/Textures/UI_Sign/Frames/Spr_Box04_02.Spr_Box04_02'",
    "PaperSprite'/Game/UI/Textures/UI_Sign/Frames/Spr_Box05_02.Spr_Box05_02'",
    "PaperSprite'/Game/UI/Textures/UI_Sign/Frames/Spr_Box06_02.Spr_Box06_02'"
}

UIResourceDef.tbCloseBoxImg =
{
    "PaperSprite'/Game/UI/Textures/UI_Sign/Frames/Spr_Box01_01.Spr_Box01_01'",
    "PaperSprite'/Game/UI/Textures/UI_Sign/Frames/Spr_Box02_01.Spr_Box02_01'",
    "PaperSprite'/Game/UI/Textures/UI_Sign/Frames/Spr_Box03_01.Spr_Box03_01'",
    "PaperSprite'/Game/UI/Textures/UI_Sign/Frames/Spr_Box04_01.Spr_Box04_01'",
    "PaperSprite'/Game/UI/Textures/UI_Sign/Frames/Spr_Box05_01.Spr_Box05_01'",
    "PaperSprite'/Game/UI/Textures/UI_Sign/Frames/Spr_Box06_01.Spr_Box06_01'"
}

UIResourceDef.tbLivenessHead =
{
    "PaperSprite'/Game/UI/Textures/UI_Sign/Frames/Spr_ProgressGo_01.Spr_ProgressGo_01'",
    "PaperSprite'/Game/UI/Textures/UI_Sign/Frames/Spr_ProgressGo_02.Spr_ProgressGo_02'"
}

UIResourceDef.tbFireDamageIcon = "PaperSprite'/Game/UI/Textures/BuffIconNew/Frames/Spr_BuffIgnition_01.Spr_BuffIgnition_01'"
UIResourceDef.tbLeakDamageIcon = "PaperSprite'/Game/UI/Textures/BuffIconNew/Frames/Spr_BuffBilging_01.Spr_BuffBilging_01'"

UIResourceDef.BATTLE_MVP_ICON = {
    [0] = "PaperSprite'/Game/UI/Textures/UI_BattleMain02/Frames/Spr_Best.Spr_Best'",
    [1] = "PaperSprite'/Game/UI/Textures/UI_BattleMain02/Frames/Spr_Good.Spr_Good'",
}

UIResourceDef.SHIP_GRADE_ICON = {
    [0] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAComon/Frames/Spr_ShipLevel.Spr_ShipLevel'",
    [1] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAComon/Frames/Spr_ShipLevel_01.Spr_ShipLevel_01'",
    [2] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAComon/Frames/Spr_ShipLevel_02.Spr_ShipLevel_02'",
    [3] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAComon/Frames/Spr_ShipLevel_03.Spr_ShipLevel_03'",
}

UIResourceDef.BUILD_ITEM_GRADE_ICON = {
    [1] = "PaperSprite'/Game/UI/FFA/Textures/UI_BuildShip/Frames/Spr_BuildShip13.Spr_BuildShip13'",
    [2] = "PaperSprite'/Game/UI/FFA/Textures/UI_BuildShip/Frames/Spr_BuildShip14.Spr_BuildShip14'",
    [3] = "PaperSprite'/Game/UI/FFA/Textures/UI_BuildShip/Frames/Spr_BuildShip15.Spr_BuildShip15'",
}

UIResourceDef.SHIP_WEAPON_SLOT_ICON = {
    [1] = "PaperSprite'/Game/UI/FFA/Textures/UI_BuildShip/Frames/Spr_ShipFaceBg.Spr_ShipFaceBg'",
    [2] = "PaperSprite'/Game/UI/FFA/Textures/UI_BuildShip/Frames/Spr_ShipSideBg.Spr_ShipSideBg'",
    [3] = "PaperSprite'/Game/UI/FFA/Textures/UI_BuildShip/Frames/Spr_ShipUpBg.Spr_ShipUpBg'",
}

UIResourceDef.SHIP_PART_SLOT_ICON = {
    [1] = "PaperSprite'/Game/UI/FFA/Textures/UI_BuildShip/Frames/Spr_ShipSailBg.Spr_ShipSailBg'",
    [2] = "PaperSprite'/Game/UI/FFA/Textures/UI_BuildShip/Frames/Spr_ShiparmorBg.Spr_ShiparmorBg'",
    [3] = "PaperSprite'/Game/UI/FFA/Textures/UI_BuildShip/Frames/Spr_CaptaincabinBg.Spr_CaptaincabinBg'",
}

UIResourceDef.ITEM_COLOR_GRADE_ICON = {
    [0] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAItem/Frames/Spr_Level_01.Spr_Level_01'",
    [1] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAItem/Frames/Spr_Level_02.Spr_Level_02'",
    [2] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAItem/Frames/Spr_Level_03.Spr_Level_03'",
    [3] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAItem/Frames/Spr_Level_04.Spr_Level_04'",
    [4] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAItem/Frames/Spr_Level_05.Spr_Level_05'",
}

UIResourceDef.ITEM_COLOR_GRADE_BG = {
    [0] = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonItemBg.Spr_CommonItemBg'",
    [1] = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonItemBg02.Spr_CommonItemBg02'",
    [2] = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonItemBg03.Spr_CommonItemBg03'",
    [3] = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonItemBg04.Spr_CommonItemBg04'",
    [4] = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonItemBg05.Spr_CommonItemBg05'",
}

UIResourceDef.ITEM_COLOR_GRADE_HALFBG = {
    [0] = "PaperSprite'/Game/UI/Textures/UI_LobbyShop/Frames/Spr_LobbyShopBg01.Spr_LobbyShopBg01'",
    [1] = "PaperSprite'/Game/UI/Textures/UI_LobbyShop/Frames/Spr_LobbyShopBg02.Spr_LobbyShopBg02'",
    [2] = "PaperSprite'/Game/UI/Textures/UI_LobbyShop/Frames/Spr_LobbyShopBg03.Spr_LobbyShopBg03'",
    [3] = "PaperSprite'/Game/UI/Textures/UI_LobbyShop/Frames/Spr_LobbyShopBg04.Spr_LobbyShopBg04'",
    [4] = "PaperSprite'/Game/UI/Textures/UI_LobbyShop/Frames/Spr_LobbyShopBg05.Spr_LobbyShopBg05'",
}

UIResourceDef.ITEM_COLOR_GRADE_SMALL_HALFBG = {
    [0] = "PaperSprite'/Game/UI/Textures/LobbyShip/Frames/Spr_LobbyShipBg01.Spr_LobbyShipBg01'",
    [1] = "PaperSprite'/Game/UI/Textures/LobbyShip/Frames/Spr_LobbyShipBg02.Spr_LobbyShipBg02'",
    [2] = "PaperSprite'/Game/UI/Textures/LobbyShip/Frames/Spr_LobbyShipBg03.Spr_LobbyShipBg03'",
    [3] = "PaperSprite'/Game/UI/Textures/LobbyShip/Frames/Spr_LobbyShipBg04.Spr_LobbyShipBg04'",
    [4] = "PaperSprite'/Game/UI/Textures/LobbyShip/Frames/Spr_LobbyShipBg05.Spr_LobbyShipBg05'",
}

UIResourceDef.SAILOR_GRADE_HALFBG = {
    [0] = "PaperSprite'/Game/UI/Textures/UI_LobbySailor/Frames/Spr_LobbySailorBg01.Spr_LobbySailorBg01'",
    [1] = "PaperSprite'/Game/UI/Textures/UI_LobbySailor/Frames/Spr_LobbySailorBg02.Spr_LobbySailorBg02'",
    [2] = "PaperSprite'/Game/UI/Textures/UI_LobbySailor/Frames/Spr_LobbySailorBg03.Spr_LobbySailorBg03'",
    [3] = "PaperSprite'/Game/UI/Textures/UI_LobbySailor/Frames/Spr_LobbySailorBg04.Spr_LobbySailorBg04'",
    [4] = "PaperSprite'/Game/UI/Textures/UI_LobbySailor/Frames/Spr_LobbySailorBg05.Spr_LobbySailorBg05'",
}


UIResourceDef.SCHEDULE_ITEM_COLOR_GRADE_BG = {
    [0] = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity35.Spr_LobbyActivity35'",
    [1] = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity36.Spr_LobbyActivity36'",
    [2] = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity37.Spr_LobbyActivity37'",
    [3] = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity38.Spr_LobbyActivity38'",
    [4] = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity39.Spr_LobbyActivity39'",
}


UIResourceDef.ITEM_INFO_GRADE_BG_H = {
    [0] = "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptain_01.Spr_LobbyCaptain_01'",
    [1] = "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptain_02.Spr_LobbyCaptain_02'",
    [2] = "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptain_03.Spr_LobbyCaptain_03'",
    [3] = "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptain_04.Spr_LobbyCaptain_04'",
    [4] = "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptain_05.Spr_LobbyCaptain_05'",
}

UIResourceDef.ITEM_INFO_GRADE_BG_V = {
    [0] = "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptain_12.Spr_LobbyCaptain_12'",
    [1] = "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptain_13.Spr_LobbyCaptain_13'",
    [2] = "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptain_14.Spr_LobbyCaptain_14'",
    [3] = "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptain_15.Spr_LobbyCaptain_15'",
    [4] = "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptain_16.Spr_LobbyCaptain_16'",
}



UIResourceDef.ITEM_GRADE_ICON = {
    [1] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAComon/Frames/Spr_ItemLevel_01.Spr_ItemLevel_01'",
    [2] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAComon/Frames/Spr_ItemLevel_02.Spr_ItemLevel_02'",
    [3] ="PaperSprite'/Game/UI/FFA/Textures/UI_FFAComon/Frames/Spr_ItemLevel_03.Spr_ItemLevel_03'",
}

UIResourceDef.HUMAN_WEAPON_GRADE_ICON = {
    [1] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAComon/Frames/Spr_CommonLV01.Spr_CommonLV01'",
    [2] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAComon/Frames/Spr_CommonLV02.Spr_CommonLV02'",
    [3] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAComon/Frames/Spr_CommonLV03.Spr_CommonLV03'",
}

--排名1 2 3的图标
UIResourceDef.tbPvpRankIcon = {
    '/Game/UI/Textures/UI_Pvp/Frames/Spr_PvpRanking_01.Spr_PvpRanking_01',
    '/Game/UI/Textures/UI_Pvp/Frames/Spr_PvpRanking_02.Spr_PvpRanking_02',
    '/Game/UI/Textures/UI_Pvp/Frames/Spr_PvpRanking_03.Spr_PvpRanking_03'
}


UIResourceDef.FFA_TRANSPORT_PLANE_ICON = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_MapShip.Spr_MapShip'"

UIResourceDef.FFA_CLOSE = "PaperSprite'/Game/UI/Textures/Common/Frames/Spr_CommonClose.Spr_CommonClose'"
UIResourceDef.FFA_PICK_UP_BOX = "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_Explore_01.Spr_Explore_01'"
UIResourceDef.FFA_PICK_UP_ITEM = "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_Capture_01.Spr_Capture_01'"
UIResourceDef.FFA_PICK_UP_NORMAL = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAComon/Frames/Spr_CommonBg06.Spr_CommonBg06'"
UIResourceDef.FFA_PICK_UP_AUTO = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAComon/Frames/Spr_CommonBg07.Spr_CommonBg07'"

UIResourceDef.FFA_BATTLE_TOAST_ID_KILL = "PaperSprite'/Game/UI/FFA/Textures/UI_KillIcon/Frames/Spr_Kill_01.Spr_Kill_01'"
UIResourceDef.FFA_BATTLE_TOAST_ID_SERIOUS = "PaperSprite'/Game/UI/FFA/Textures/UI_KillIcon/Frames/Spr_SeriousInjury_01.Spr_SeriousInjury_01'"

UIResourceDef.FFA_VIRTUALSTICK_HUMAN_ICON = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAComon/Frames/Spr_PeopleControlMan_UI.Spr_PeopleControlMan_UI'"
UIResourceDef.FFA_VIRTUALSTICK_SHIP_ICON = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAComon/Frames/Spr_PeopleControlShip_UI.Spr_PeopleControlShip_UI'"
UIResourceDef.FFA_VIRTUALSTICK_HUMAN_RUN = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill08_Disabled.Spr_Skill08_Disabled'"
UIResourceDef.FFA_VIRTUALSTICK_SHIP_RUN = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill05_Disabled.Spr_Skill05_Disabled'"
UIResourceDef.FFA_VIRTUALSTICK_HUMAN_CHECK = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill08_Disabled.Spr_Skill08_Disabled'"
UIResourceDef.FFA_VIRTUALSTICK_HUMAN_UNCHECK = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill08_Normal.Spr_Skill08_Normal'"
UIResourceDef.FFA_VIRTUALSTICK_SHIP_CHECK = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill05_Disabled.Spr_Skill05_Disabled'"
UIResourceDef.FFA_VIRTUALSTICK_SHIP_UNCHECK = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill05_Pressed.Spr_Skill05_Pressed'"


UIResourceDef.FFA_SOUND_SHIP_FIRE = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_MiniMap_04.Spr_MiniMap_04'"
UIResourceDef.FFA_SOUND_SHIP_BE_SHOOTED = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_MiniMap_05.Spr_MiniMap_05'"
UIResourceDef.FFA_SOUND_SHIP_HIT_MOUNTAIN = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_MiniMap_03.Spr_MiniMap_03'"
UIResourceDef.FFA_SOUND_HUMAN_FIRE = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_MiniMap_08.Spr_MiniMap_08'"
UIResourceDef.FFA_SOUND_HUMAN_FIRE_WITH_MUFFLER = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_MiniMap_02.Spr_MiniMap_02'"
UIResourceDef.FFA_SOUND_CARRIER_NOISE = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_MiniMap_07.Spr_MiniMap_07'"
UIResourceDef.FFA_SOUND_FOOT_STEP = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_MiniMap_06.Spr_MiniMap_06'"

UIResourceDef.FFA_CHANGE_TO_SHIP_NORMAL = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill01_Normal.Spr_Skill01_Normal'"
UIResourceDef.FFA_CHANGE_TO_SHIP_PRESS = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill01_Normal.Spr_Skill01_Normal'"
UIResourceDef.FFA_CHANGE_TO_SHIP_DISABLED = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill01_Disabled.Spr_Skill01_Disabled'"
UIResourceDef.FFA_CHANGE_TO_HUMAN_NORMAL = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill13_Normal.Spr_Skill13_Normal'"
UIResourceDef.FFA_CHANGE_TO_HUMAN_PRESS = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill13_Normal.Spr_Skill13_Normal'"
UIResourceDef.FFA_CHANGE_TO_HUMAN_DISABLED = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill13_Disabled.Spr_Skill13_Disabled'"

UIResourceDef.FFA_HUMAN_WEAPON_FIRE_TYPE_SINGLE = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_OneFire.Spr_OneFire'"
UIResourceDef.FFA_HUMAN_WEAPON_FIRE_TYPE_TRIPLE = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_TwoFire.Spr_TwoFire'"
UIResourceDef.FFA_HUMAN_WEAPON_FIRE_TYPE_AUTO = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_TwoFire.Spr_TwoFire'"


UIResourceDef.FFA_FONT_RES_PINGFANG = "Font'/Game/UI/Fonts/Font_PingFang.Font_PingFang'"
UIResourceDef.FFA_POISON_CIRCLE_TIMER = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_MainIcon09.Spr_MainIcon09'"
UIResourceDef.FFA_REPARE_TIMER = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_MainIcon19.Spr_MainIcon19'"

--攻击图标
UIResourceDef.FFA_HUMAN_WEAPON_ATTACK_IMAGE_MELEE = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_SkillFire05_Normal.Spr_SkillFire05_Normal'"
UIResourceDef.FFA_HUMAN_WEAPON_ATTACK_IMAGE_MELEE_PRESSED = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_SkillFire05_Pressed.Spr_SkillFire05_Pressed'"
UIResourceDef.FFA_HUMAN_WEAPON_ATTACK_IMAGE_GUN = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_SkillFire02_Normal.Spr_SkillFire02_Normal'"
UIResourceDef.FFA_HUMAN_WEAPON_ATTACK_IMAGE_GUN_PRESSED = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_SkillFire02_Pressed.Spr_SkillFire02_Pressed'"
UIResourceDef.FFA_HUMAN_WEAPON_ATTACK_IMAGE_THROWN_ITEM = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_SkillFire04_Normal.Spr_SkillFire04_Normal'"
UIResourceDef.FFA_HUMAN_WEAPON_ATTACK_IMAGE_THROWN_ITEM_PRESSED = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_SkillFire04_Pressed.Spr_SkillFire04_Pressed'"
UIResourceDef.FFA_HUMAN_WEAPON_ATTACK_IMAGE_EMPTY_HAND = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_SkillFire03_Normal.Spr_SkillFire03_Normal'"
UIResourceDef.FFA_HUMAN_WEAPON_ATTACK_IMAGE_EMPTY_HAND_PRESSED = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_SkillFire03_Pressed.Spr_SkillFire03_Pressed'"


UIResourceDef.FFA_HUMAN_FREE_VIEW_PRESSED = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_SkillView_Pressed.Spr_SkillView_Pressed'"
UIResourceDef.FFA_HUMAN_FREE_VIEW_NORMAL  = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_SkillView_Normal.Spr_SkillView_Normal'"

UIResourceDef.FFA_COMMON_PACK_ICONS = {
    [ControlModeDef.HUMAN] = {
        szNormal    = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill07_Normal.Spr_Skill07_Normal'",
        szPressed   = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill07_Pressed.Spr_Skill07_Pressed'",
        szDisabled  = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill07_Disabled.Spr_Skill07_Disabled'"
    },
    [ControlModeDef.SHIP] = {
        szNormal    = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill06_Normal.Spr_Skill06_Normal'",
        szPressed   = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill06_Pressed.Spr_Skill06_Pressed'",
        szDisabled  = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill06_Disabled.Spr_Skill06_Disabled'"
    },
}

UIResourceDef.FFA_HUMAN_PACK_ICON = {
    [1] = {
        szNormal    = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill20_Normal.Spr_Skill20_Normal'",
        szPressed   = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill20_Pressed.Spr_Skill20_Pressed'",
        szDisabled  = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill20_Normal.Spr_Skill20_Normal'"
    },
    [2] = {
        szNormal    = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill22_Normal.Spr_Skill22_Normal'",
        szPressed   = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill22_Pressed.Spr_Skill22_Pressed'",
        szDisabled  = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill22_Normal.Spr_Skill22_Normal'"
    },
    [3] = {
        szNormal    = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill21_Normal.Spr_Skill21_Normal'",
        szPressed   = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill21_Pressed.Spr_Skill21_Pressed'",
        szDisabled  = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill21_Normal.Spr_Skill21_Normal'"
    },
}

UIResourceDef.BORN_POINT = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Main_Gauge_Point.Spr_Main_Gauge_Point'"
UIResourceDef.NEW_TRANSPORTER_LINE = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAComon/Frames/Spr_MapPoint02.Spr_MapPoint02'"
UIResourceDef.NEW_TRANSPORTER_TARGET = "PaperSprite'/Game/UI/FFA/Textures/UI_MapIcon/Frames/Spr_MapIcon_07.Spr_MapIcon_07'"
UIResourceDef.CORE_AREA_POINT = "PaperSprite'/Game/UI/FFA/Textures/UI_MapIcon/Frames/Spr_MapIcon_05.Spr_MapIcon_05'"



UIResourceDef.GENDER_MALE = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_MainIcon07.Spr_MainIcon07'"
UIResourceDef.GENDER_FEMALE = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_MainIcon08.Spr_MainIcon08'"

UIResourceDef.TEAM_MEMBER_STATE_ICON = {
    [DCProto.TeamInfo_EState.NONE] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_MiniMap.Spr_MiniMap'",   --正常
    [DCProto.TeamInfo_EState.OFFLINE] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Main_OffLine.Spr_Main_OffLine'",  --掉线
    [DCProto.TeamInfo_EState.DYING] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Main_Help.Spr_Main_Help'",  --重伤
    [DCProto.TeamInfo_EState.DEAD] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Main_Die.Spr_Main_Die'",  --死亡
    [DCProto.TeamInfo_EState.DRIVING] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Main_House.Spr_Main_House'",  --载具
    [DCProto.TeamInfo_EState.PARACHUTING] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Main_Unbaler.Spr_Main_Unbaler'",  --跳伞
    [DCProto.TeamInfo_EState.ADDITIONALSUCCESS] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_MiniMap.Spr_MiniMap'",   --额外胜利
    [DCProto.TeamInfo_EState.INPLANE] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Main_Drive.Spr_Main_Drive'", --航行
}

UIResourceDef.MAP_SELF_ICON = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_MapArrow02.Spr_MapArrow02'"

UIResourceDef.UI_MAP_OBJ_AIR_DROP_ICON = "PaperSprite'/Game/UI/FFA/Textures/UI_BuildShip/Frames/Spr_BuildShip04.Spr_BuildShip04'"
UIResourceDef.UI_MAP_OBJ_DIAMOND_ICON = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAItem/Frames/Spr_RoughGem_01.Spr_RoughGem_01'"

UIResourceDef.LOBBY_PLAYER_TEAM_APPLY = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Team_01.Spr_Team_01'"
UIResourceDef.LOBBY_PLAYER_TEAM_INVITE = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Team_04.Spr_Team_04'"

UIResourceDef.SAILOR_GRADE_ICONS = {
    "PaperSprite'/Game/UI/FFA/Textures/UI_SailorIcon/Frames/Spr_Number01.Spr_Number01'",
    "PaperSprite'/Game/UI/FFA/Textures/UI_SailorIcon/Frames/Spr_Number02.Spr_Number02'",
    "PaperSprite'/Game/UI/FFA/Textures/UI_SailorIcon/Frames/Spr_Number03.Spr_Number03'",
    "PaperSprite'/Game/UI/FFA/Textures/UI_SailorIcon/Frames/Spr_Number04.Spr_Number04'",
    "PaperSprite'/Game/UI/FFA/Textures/UI_SailorIcon/Frames/Spr_Number05.Spr_Number05'"
}
UIResourceDef.SAILOR_FRAGMENT_SUMMON_ICON = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAItem/Frames/Spr_Crystal_01.Spr_Crystal_01'"


UIResourceDef.MAIL_READ_ICON       = "PaperSprite'/Game/UI/FFA/Textures/UI_LobbyEmail/Frames/Spr_LobbyEmail02.Spr_LobbyEmail02'"
UIResourceDef.MAIL_UNREAD_ICON     = "PaperSprite'/Game/UI/FFA/Textures/UI_LobbyEmail/Frames/Spr_LobbyEmail01.Spr_LobbyEmail01'"
UIResourceDef.MAIL_COIN_ICON       = "PaperSprite'/Game/UI/FFA/Textures/UI_LobbyEmail/Frames/Spr_LobbyEmail03.Spr_LobbyEmail03'"
UIResourceDef.MAIL_ATTACHMENT_ICON = "PaperSprite'/Game/UI/FFA/Textures/UI_LobbyEmail/Frames/Spr_LobbyEmail04.Spr_LobbyEmail04'"

UIResourceDef.SEASON_PASS_ACITVE_IMAGE = "PaperSprite'/Game/UI/FFA/Textures/UI_Interface/Frames/Spr_SeasonIcon_02.Spr_SeasonIcon_02'"
UIResourceDef.SEASON_PASS_UNACITVE_IMAGE = "PaperSprite'/Game/UI/FFA/Textures/UI_Interface/Frames/Spr_SeasonIcon_01.Spr_SeasonIcon_01'"

UIResourceDef.CHAT_EXPRESSION_TEMPLATE = "PaperSprite'/Game/UI/FFA/Textures/UI_Expression/Frames/Spr_Face_%02d.Spr_Face_%02d'"

UIResourceDef.FFA_CORE_AREA = "PaperSprite'/Game/UI/FFA/Textures/UI_MapIcon/Frames/Spr_MapIcon_06.Spr_MapIcon_06'"

UIResourceDef.ANNOUNCEMENT_LABEL = "PaperSprite'/Game/UI/FFA/Textures/UI_SevenDay/Frames/Spr_Announcement.Spr_Announcement'"

UIResourceDef.RANK_SUB_IMAGES1 = {
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_Gold_01.Spr_Gold_01'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_Gold_02.Spr_Gold_02'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_Gold_03.Spr_Gold_03'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_Gold_04.Spr_Gold_04'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_Gold_05.Spr_Gold_05'",
}
UIResourceDef.RANK_SUB_IMAGES2 = {
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_Silver_01.Spr_Silver_01'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_Silver_02.Spr_Silver_02'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_Silver_03.Spr_Silver_03'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_Silver_04.Spr_Silver_04'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_Silver_05.Spr_Silver_05'",
}

UIResourceDef.RANK_IMAGES = {
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_BadgeSeasonSH_01.Spr_BadgeSeasonSH_01'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_BadgeSeasonSH_02.Spr_BadgeSeasonSH_02'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_BadgeSeasonSH_03.Spr_BadgeSeasonSH_03'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_BadgeSeasonSH_04.Spr_BadgeSeasonSH_04'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_BadgeSeasonSH_05.Spr_BadgeSeasonSH_05'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_BadgeSeasonSH_06.Spr_BadgeSeasonSH_06'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_BadgeSeasonSH_07.Spr_BadgeSeasonSH_07'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_BadgeSeasonSH_08.Spr_BadgeSeasonSH_08'",
}
UIResourceDef.RANK_BG_IMAGES = {
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_BadgeSeasonBG_01.Spr_BadgeSeasonBG_01'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_BadgeSeasonBG_02.Spr_BadgeSeasonBG_02'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_BadgeSeasonBG_03.Spr_BadgeSeasonBG_03'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_BadgeSeasonBG_04.Spr_BadgeSeasonBG_04'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_BadgeSeasonBG_05.Spr_BadgeSeasonBG_05'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_BadgeSeasonBG_06.Spr_BadgeSeasonBG_06'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_BadgeSeasonBG_07.Spr_BadgeSeasonBG_07'",
    "PaperSprite'/Game/UI/Textures/UI_LobbySeasonRank/Frames/Spr_BadgeSeasonBG_08.Spr_BadgeSeasonBG_08'",
}
UIResourceDef.RANK_ICONS = {
    "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_BadgeSeasonSm_01.Spr_BadgeSeasonSm_01'",
    "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_BadgeSeasonSm_02.Spr_BadgeSeasonSm_02'",
    "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_BadgeSeasonSm_03.Spr_BadgeSeasonSm_03'",
    "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_BadgeSeasonSm_04.Spr_BadgeSeasonSm_04'",
    "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_BadgeSeasonSm_05.Spr_BadgeSeasonSm_05'",
    "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_BadgeSeasonSm_06.Spr_BadgeSeasonSm_06'",
    "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_BadgeSeasonSm_07.Spr_BadgeSeasonSm_07'",
    "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_BadgeSeasonSm_08.Spr_BadgeSeasonSm_08'",
}
UIResourceDef.RANK_SUB_ICON1 = {
    "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_BageSeasonGoldSx_01.Spr_BageSeasonGoldSx_01'",
    "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_BageSeasonGoldSx_02.Spr_BageSeasonGoldSx_02'",
    "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_BageSeasonGoldSx_03.Spr_BageSeasonGoldSx_03'",
    "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_BageSeasonGoldSx_04.Spr_BageSeasonGoldSx_04'",
    "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_BageSeasonGoldSx_05.Spr_BageSeasonGoldSx_05'",
}
UIResourceDef.RANK_SUB_ICON2 = {
    "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_BageSeasonSivleSx_01.Spr_BageSeasonSivleSx_01'",
    "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_BageSeasonSivleSx_02.Spr_BageSeasonSivleSx_02'",
    "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_BageSeasonSivleSx_03.Spr_BageSeasonSivleSx_03'",
    "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_BageSeasonSivleSx_04.Spr_BageSeasonSivleSx_04'",
    "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_BageSeasonSivleSx_05.Spr_BageSeasonSivleSx_05'",
}

UIResourceDef.SETTING_LAYOUT_ICON =
{
    [1] = "PaperSprite'/Game/UI/FFA/Textures/UI_GameSet/Frames/Spr_GameSet_24.Spr_GameSet_24'",
    [2] = "PaperSprite'/Game/UI/FFA/Textures/UI_GameSet/Frames/Spr_GameSet_23.Spr_GameSet_23'",
    [3] = "PaperSprite'/Game/UI/FFA/Textures/UI_GameSet/Frames/Spr_GameSet_25.Spr_GameSet_25'",
}

UIResourceDef.DEAD_CAUSER_TYPE_ICON =
{
    [-1] = "PaperSprite'/Game/UI/FFA/Textures/UI_KillIcon/Frames/Spr_dropped_01.Spr_dropped_01'",           --跌落
    [-2] = "PaperSprite'/Game/UI/FFA/Textures/UI_KillIcon/Frames/Spr_Drowning_01.Spr_Drowning_01'",         --溺水
    [-3] = "PaperSprite'/Game/UI/FFA/Textures/UI_GameSet/Frames/Spr_GameSet_25.Spr_GameSet_25'",            --重伤自然衰减
    [-4] = "PaperSprite'/Game/UI/FFA/Textures/UI_KillIcon/Frames/Spr_TheKuroshio_01.Spr_TheKuroshio_01'",   --毒圈
}

UIResourceDef.LAST_USED_VEHICLE = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_RadenHouse.Spr_RadenHouse'"

UIResourceDef.DUNGEON_VOICE_SPEAKER_ICON =
{
    "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Talk02.Spr_Talk02'",
    "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Talk02.Spr_Talk02'",
    "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Talk01.Spr_Talk01'",
}

UIResourceDef.DUNGEON_VOICE_MIC_ICON =
{
    "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Talk15.Spr_Talk15'",
    "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Talk03.Spr_Talk03'",
    "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Talk04.Spr_Talk04'",
    "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Talk14.Spr_Talk14'",
    "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Talk05.Spr_Talk05'",
}

UIResourceDef.LOBBY_VOICE_SPEAKER_ICON =
{
    "PaperSprite'/Game/UI/Textures/LobbyMain/Frames/SprLobbyChat07.SprLobbyChat07'",
    "PaperSprite'/Game/UI/Textures/LobbyMain/Frames/SprLobbyChat07.SprLobbyChat07'",
    "PaperSprite'/Game/UI/Textures/LobbyMain/Frames/SprLobbyChat08.SprLobbyChat08'",
}

UIResourceDef.LOBBY_VOICE_MIC_ICON =
{
    "PaperSprite'/Game/UI/Textures/LobbyMain/Frames/SprLobbyChat05.SprLobbyChat05'",
    "PaperSprite'/Game/UI/Textures/LobbyMain/Frames/SprLobbyChat05.SprLobbyChat05'",
    "PaperSprite'/Game/UI/Textures/LobbyMain/Frames/SprLobbyChat06.SprLobbyChat06'",
    "PaperSprite'/Game/UI/Textures/LobbyMain/Frames/SprLobbyChat09.SprLobbyChat09'",
    "PaperSprite'/Game/UI/Textures/LobbyMain/Frames/SprLobbyChat09.SprLobbyChat09'",
}

UIResourceDef.VOICE_PANEL_CLOSE = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Talk17.Spr_Talk17'"

UIResourceDef.VOICE_MEMBER_SPEAKER_STATE_OPEN = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Talk12.Spr_Talk12'"
UIResourceDef.VOICE_MEMBER_SPEAKER_STATE_CLOSE = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Talk13.Spr_Talk13'"

UIResourceDef.LOBBY_DOT_HIGHLIGHT = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonTips001_Pressed.Spr_CommonTips001_Pressed'"
UIResourceDef.LOBBY_DOT_NORMAL = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonTips001_Normal.Spr_CommonTips001_Normal'"
UIResourceDef.LOBBY_AUTO_MATCHMAKING = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonChk001_Pressed.Spr_CommonChk001_Pressed'"
UIResourceDef.LOBBY_NOT_AUTO_MATCHMAKING = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonChk001_Normal.Spr_CommonChk001_Normal'"

UIResourceDef.LOBBY_COMMON = {
    ["ADD"] = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonAdd.Spr_CommonAdd'",
    ["LOCK"] = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonLock.Spr_CommonLock'",
    ["LOCK02"] = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonLock02.Spr_CommonLock02'",
    ["TIPS_TITLE"] = {
        [1] = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonTipsTitle.Spr_CommonTipsTitle'",
        [2] = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonTipsTitle02.Spr_CommonTipsTitle02'",
        [3] = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonTipsTitle03.Spr_CommonTipsTitle03'",
    },
    ["TIPS"] = {
        ["Pressed"] = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonTips001_Pressed.Spr_CommonTips001_Pressed'",
        ["Normal"] = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonTips001_Normal.Spr_CommonTips001_Normal'"
    }
}

UIResourceDef.LOBBY_SHIP_FOUR_DIMENSIONAL_GRAPH = "MaterialInstanceConstant'/Game/UI/Materials/Effects/Materials/MI_UI_Four_Dimensional_Graph_01.MI_UI_Four_Dimensional_Graph_01'"
UIResourceDef.LOBBY_SHIP_GRADE_BACKGROUND = {
    [-1] = "PaperSprite'/Game/UI/Textures/LobbyShip/Frames/Spr_LobbyShipBg00.Spr_LobbyShipBg00'",
    [0] = "PaperSprite'/Game/UI/Textures/LobbyShip/Frames/Spr_LobbyShipBg01.Spr_LobbyShipBg01'",
    [1] = "PaperSprite'/Game/UI/Textures/LobbyShip/Frames/Spr_LobbyShipBg02.Spr_LobbyShipBg02'",
    [2] = "PaperSprite'/Game/UI/Textures/LobbyShip/Frames/Spr_LobbyShipBg03.Spr_LobbyShipBg03'",
    [3] = "PaperSprite'/Game/UI/Textures/LobbyShip/Frames/Spr_LobbyShipBg04.Spr_LobbyShipBg04'",
    [4] = "PaperSprite'/Game/UI/Textures/LobbyShip/Frames/Spr_LobbyShipBg05.Spr_LobbyShipBg05'",
}

UIResourceDef.COMMON_MENU_SUMMARY = "PaperSprite'/Game/UI/Textures/LobbyMain/Frames/Spr_LobbyTeam08.Spr_LobbyTeam08'"
UIResourceDef.LOBBY_SAILOR_LOCK_COIN = "PaperSprite'/Game/UI/Textures/UI_LobbySailor/Frames/Spr_LobbySailorLock02.Spr_LobbySailorLock02'"

UIResourceDef.LOBBY_SAILOR_BG_STONE =
{
    [1] = {
        [0] = "PaperSprite'/Game/UI/Textures/UI_SailorRock/Frames/Spr_SailorAttack_01.Spr_SailorAttack_01'",
        [1] = "PaperSprite'/Game/UI/Textures/UI_SailorRock/Frames/Spr_SailorAttack_02.Spr_SailorAttack_02'",
        [2] = "PaperSprite'/Game/UI/Textures/UI_SailorRock/Frames/Spr_SailorAttack_03.Spr_SailorAttack_03'",
        [3] = "PaperSprite'/Game/UI/Textures/UI_SailorRock/Frames/Spr_SailorAttack_04.Spr_SailorAttack_04'",
        [4] = "PaperSprite'/Game/UI/Textures/UI_SailorRock/Frames/Spr_SailorAttack_05.Spr_SailorAttack_05'",
    },
    [2] = {
        [0] = "PaperSprite'/Game/UI/Textures/UI_SailorRock/Frames/Spr_SailorDefense_01.Spr_SailorDefense_01'",
        [1] = "PaperSprite'/Game/UI/Textures/UI_SailorRock/Frames/Spr_SailorDefense_02.Spr_SailorDefense_02'",
        [2] = "PaperSprite'/Game/UI/Textures/UI_SailorRock/Frames/Spr_SailorDefense_03.Spr_SailorDefense_03'",
        [3] = "PaperSprite'/Game/UI/Textures/UI_SailorRock/Frames/Spr_SailorDefense_04.Spr_SailorDefense_04'",
        [4] = "PaperSprite'/Game/UI/Textures/UI_SailorRock/Frames/Spr_SailorDefense_05.Spr_SailorDefense_05'",
    },
    [3] = {
        [0] = "PaperSprite'/Game/UI/Textures/UI_SailorRock/Frames/Spr_SailorSupply_01.Spr_SailorSupply_01'",
        [1] = "PaperSprite'/Game/UI/Textures/UI_SailorRock/Frames/Spr_SailorSupply_02.Spr_SailorSupply_02'",
        [2] = "PaperSprite'/Game/UI/Textures/UI_SailorRock/Frames/Spr_SailorSupply_03.Spr_SailorSupply_03'",
        [3] = "PaperSprite'/Game/UI/Textures/UI_SailorRock/Frames/Spr_SailorSupply_04.Spr_SailorSupply_04'",
        [4] = "PaperSprite'/Game/UI/Textures/UI_SailorRock/Frames/Spr_SailorSupply_05.Spr_SailorSupply_05'",
    },
}

UIResourceDef.LOBBY_SAILOR_HIGH_LEVEL_EFF = 
{
    [1] =
    {
        [3] = "MaterialInstanceConstant'/Game/UI/Materials/Effects/Materials/SailorSign/MI_UI__SailorAttack_04.MI_UI__SailorAttack_04'",
        [4] = "MaterialInstanceConstant'/Game/UI/Materials/Effects/Materials/SailorSign/MI_UI__SailorAttack_05.MI_UI__SailorAttack_05'",
    },
    [2] =
    {
        [3] = "MaterialInstanceConstant'/Game/UI/Materials/Effects/Materials/SailorSign/MI_UI__SailorDefense_04.MI_UI__SailorDefense_04'",
        [4] = "MaterialInstanceConstant'/Game/UI/Materials/Effects/Materials/SailorSign/MI_UI__SailorDefense_05.MI_UI__SailorDefense_05'",
    },
    [3] = 
    {
        [3] = "MaterialInstanceConstant'/Game/UI/Materials/Effects/Materials/SailorSign/MI_UI__SailorSupply_04.MI_UI__SailorSupply_04'",
        [4] = "MaterialInstanceConstant'/Game/UI/Materials/Effects/Materials/SailorSign/MI_UI__SailorSupply_05.MI_UI__SailorSupply_05'",
    }
}


UIResourceDef.LOBBY_SAILOR_PATTERN_COLOR = 
{
    [0] = GetSlateColorFunc(1.0, 1.0, 1.0, 1.0),
    [1] = GetSlateColorFunc(0.698039, 0.937255, 0.435294, 1.0),
    [2] = GetSlateColorFunc(0.482353, 0.690196, 0.941177, 1.0),
    [3] = GetSlateColorFunc(0.741176, 0.584314, 0.819608, 1.0),
    [4] = GetSlateColorFunc(1.0, 0.784314, 0.443137, 1.0),
}

UIResourceDef.LOBBY_SAILOR_PATTERN_DISABLE_COLOR = 
{
    [0] = KMUMGLibrary.GetSlateColorFromHex("7F7F7FFF"),
    [1] = KMUMGLibrary.GetSlateColorFromHex("66893FFF"),
    [2] = KMUMGLibrary.GetSlateColorFromHex("405B7DFF"),
    [3] = KMUMGLibrary.GetSlateColorFromHex("7E6376FF"),
    [4] = KMUMGLibrary.GetSlateColorFromHex("8E6F3FFF"),
}

UIResourceDef.LOBBY_SAILOR_STONE_DISABLE_COLOR = KMUMGLibrary.GetSlateColor(0.2, 0.2, 0.2, 1.0)

UIResourceDef.LOBBY_SAILOR_STONE_FX_GRADE_COLOR = 
{
    [0] = {
        BaseColor = GetLinearColorFunc(0.37,0.41,0.53,1),
        EdgeColor = GetLinearColorFunc(0.32,0.31,0.3,1),
    },
    [1] = {
        BaseColor = GetLinearColorFunc(0.14,0.8,0.15,1),
        EdgeColor = GetLinearColorFunc(0.48,0.43,0.36,1),
    },
    [2] = {
        BaseColor = GetLinearColorFunc(0.058,0.71,1,1),
        EdgeColor = GetLinearColorFunc(0.27,0.64,0.8,1),
    },
    [3] = {
        BaseColor = GetLinearColorFunc(0.35,0.35,1,1),
        EdgeColor = GetLinearColorFunc(0.3,0.2,0.38,1),
    },
    [4] = {
        BaseColor = GetLinearColorFunc(0.61,0.26,0.004,1),
        EdgeColor = GetLinearColorFunc(0.56,0.36,0.15,1),
    }
}

UIResourceDef.FRIEND_RELATION_IMG = 
{
    [1] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAFriend/Frames/Spr_DearFriend04.Spr_DearFriend04'",
    [2] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAFriend/Frames/Spr_DearFriend02.Spr_DearFriend02'",
    [3] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAFriend/Frames/Spr_DearFriend03.Spr_DearFriend03'",
    [4] = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAFriend/Frames/Spr_DearFriend01.Spr_DearFriend01'",
}

UIResourceDef.FRIEND_RELATION_TXT_COLOR =         
{
    [1] = KMUMGLibrary.GetSlateColorFromHex("7ECEF4FF"),
    [2] = KMUMGLibrary.GetSlateColorFromHex("F78686FF"),
    [3] = KMUMGLibrary.GetSlateColorFromHex("EFB654FF"),
    [4] = KMUMGLibrary.GetSlateColorFromHex("ED9DC0FF"),
}

-- UIResourceDef.NEW_SEASON_PASS_IMAGE = "PaperSprite'/Game/UI/Textures/UI_LobbySeason/Frames/Spr_LobbySeason07.Spr_LobbySeason07'"

UIResourceDef.NEW_SHOP_FREE_BTN_IMAGE = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_ButtonM_Pressed.Spr_ButtonM_Pressed'"
UIResourceDef.NEW_SHOP_BTN_IMAGE = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_ButtonM_Normal.Spr_ButtonM_Normal'"
UIResourceDef.LOBBY_MATCHMAKING_NOT_OPEN_IMG = "Texture2D'/Game/UI/Textures/LobbyMain/Textures/T_LobbyMain436x288_03_UI.T_LobbyMain436x288_03_UI'"

UIResourceDef.NUM_IMAGE = {
    [0] = "PaperSprite'/Game/UI/Textures/UI_LobbySeason/Frames/Spr_SeasonNumber_0.Spr_SeasonNumber_0'",
    [1] = "PaperSprite'/Game/UI/Textures/UI_LobbySeason/Frames/Spr_SeasonNumber_1.Spr_SeasonNumber_1'",
    [2] = "PaperSprite'/Game/UI/Textures/UI_LobbySeason/Frames/Spr_SeasonNumber_2.Spr_SeasonNumber_2'",
    [3] = "PaperSprite'/Game/UI/Textures/UI_LobbySeason/Frames/Spr_SeasonNumber_3.Spr_SeasonNumber_3'",
    [4] = "PaperSprite'/Game/UI/Textures/UI_LobbySeason/Frames/Spr_SeasonNumber_4.Spr_SeasonNumber_4'",
    [5] = "PaperSprite'/Game/UI/Textures/UI_LobbySeason/Frames/Spr_SeasonNumber_5.Spr_SeasonNumber_5'",
    [6] = "PaperSprite'/Game/UI/Textures/UI_LobbySeason/Frames/Spr_SeasonNumber_6.Spr_SeasonNumber_6'",
    [7] = "PaperSprite'/Game/UI/Textures/UI_LobbySeason/Frames/Spr_SeasonNumber_7.Spr_SeasonNumber_7'",
    [8] = "PaperSprite'/Game/UI/Textures/UI_LobbySeason/Frames/Spr_SeasonNumber_8.Spr_SeasonNumber_8'",
    [9] = "PaperSprite'/Game/UI/Textures/UI_LobbySeason/Frames/Spr_SeasonNumber_9.Spr_SeasonNumber_9'",
}

--Lobby Voice
UIResourceDef.LOBBY_VOICE_BTN_HIGHLIGHT = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonBg001_Pressed.Spr_CommonBg001_Pressed'"
UIResourceDef.LOBBY_VOICE_BTN_NORMAL = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_ButtonS_Normal.Spr_ButtonS_Normal'"

UIResourceDef.LOBBY_AUTO_MATCHMAKING_CHECKED = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonChk001_Pressed.Spr_CommonChk001_Pressed'"
UIResourceDef.LOBBY_AUTO_MATCHMAKING_UNCHECKED = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonChk001_Normal.Spr_CommonChk001_Normal'"

local HumanAvatarDef = require("HumanAvatarDef")
local FashionSlotCategoryExtend = HumanAvatarDef.FashionSlotCategoryExtend

UIResourceDef.LOBBY_HUMAN_SLOT_ICON =
{
    [FashionSlotCategoryExtend.Hat] = 
    {
        "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptaiBtn04_Pressed.Spr_LobbyCaptaiBtn04_Pressed'", 
        "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptaiBtn04_Normal.Spr_LobbyCaptaiBtn04_Normal'"
    },
    [FashionSlotCategoryExtend.Upper] =     
    {
        "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptaiBtn02_Pressed.Spr_LobbyCaptaiBtn02_Pressed'", 
        "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptaiBtn02_Normal.Spr_LobbyCaptaiBtn02_Normal'"
    },
    [FashionSlotCategoryExtend.Lower] = 
    {
        "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptaiBtn01_Pressed.Spr_LobbyCaptaiBtn01_Pressed'",
        "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptaiBtn01_Normal.Spr_LobbyCaptaiBtn01_Normal'"
    },
    [FashionSlotCategoryExtend.Shoe] = 
    {
        "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptaiBtn05_Pressed.Spr_LobbyCaptaiBtn05_Pressed'",
        "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptaiBtn05_Normal.Spr_LobbyCaptaiBtn05_Normal'"
    },
    [FashionSlotCategoryExtend.Suit] =     
    {
        "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptaiBtn03_Pressed.Spr_LobbyCaptaiBtn03_Pressed'",
        "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptaiBtn03_Normal.Spr_LobbyCaptaiBtn03_Normal'"
    },
}

UIResourceDef.CAPTAIN_ITEM_INFO_DISABLE_BG = "PaperSprite'/Game/UI/Textures/LobbyCaptain/Frames/Spr_LobbyCaptain_00.Spr_LobbyCaptain_00'"

return UIResourceDef
