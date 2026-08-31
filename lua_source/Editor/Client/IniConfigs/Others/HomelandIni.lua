--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local HomelandIni = {}
HomelandIni.szFileName = "common/homeland/homeland.ini"

function HomelandIni:OnParse(Parser)
    local tbScene = {}
    tbScene.nDefaultSceneId   = Parser:Get("scene", "default_scene_id" , -1, Parser.TypeNumber)
    tbScene.nTriggerExtension = Parser:Get("scene", "trigger_extension",  1, Parser.TypeNumber)
    self.tbScene = tbScene

    local tbTreasure = {}
    tbTreasure.nCurrencyTemplateId = Parser:Get("treasure", "currency_template_id",   -1             , Parser.TypeNumber)
    tbTreasure.szLobbyActorTag     = Parser:Get("treasure", "lobby_actor_tag"     ,   "LobbyTreasure", Parser.TypeString)
    self.tbTreasure = tbTreasure

    local tbMatinee = {}
    tbMatinee.szShipActorName           = Parser:Get("matinee", "ship_actor_name"          ,   "", Parser.TypeString)
    tbMatinee.szShipActorMeshName       = Parser:Get("matinee", "ship_actor_mesh_name"     ,   "", Parser.TypeString)
    tbMatinee.nEnterHomelandMatinee     = Parser:Get("matinee", "enter_homeland_matinee"   ,   -1, Parser.TypeNumber)
    tbMatinee.nLeaveHomelandMatinee     = Parser:Get("matinee", "leave_homeland_matinee"   ,   -1, Parser.TypeNumber)
    tbMatinee.nTransportTreasureMatinee = Parser:Get("matinee", "transport_treasure_matinee",  -1, Parser.TypeNumber)
    self.tbMatinee = tbMatinee

    local tbEffect = {}
    tbEffect.szBuildingUpgradingRes       = Parser:Get("effect", "building_upgrading_res"       ,   "", Parser.TypeString)
    tbEffect.szBuildingUpgradeCompleteRes = Parser:Get("effect", "building_upgrade_complete_res",   "", Parser.TypeString)
    tbEffect.szBuildingPlacedRes          = Parser:Get("effect", "building_placed_res"          ,   "", Parser.TypeString)
    tbEffect.szBuildingRemovedRes         = Parser:Get("effect", "building_removed_res"         ,   "", Parser.TypeString)
    tbEffect.szBlockBoughtRes             = Parser:Get("effect", "block_bought_res"             ,   "", Parser.TypeString)
    self.tbEffect = tbEffect

    local tbPlayer = {}
    tbPlayer.szPlayerAttachmentClass     = Parser:Get("player", "player_attachment_class"     ,   "", Parser.TypeString)
    tbPlayer.szChangeToBuildModeMotage   = Parser:Get("player", "change_to_build_mode_motage" ,   "", Parser.TypeString)
    tbPlayer.szChangeToNormalModeMotage  = Parser:Get("player", "change_to_normal_mode_motage",   "", Parser.TypeString)
    self.tbPlayer = tbPlayer
end

return HomelandIni
