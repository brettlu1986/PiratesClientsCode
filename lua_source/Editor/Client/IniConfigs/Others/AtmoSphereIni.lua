--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
--]]

local AtmoSphereIni = {}
AtmoSphereIni.szFileName = "client/atmosphere/new/atmosphere.ini"

function AtmoSphereIni:OnParse(Parser)
    self.nGridCount          = Parser:Get("Create", "grid_count"            , -1, Parser.TypeNumber)

    self.nGridSizeLand          = Parser:Get("Create", "grid_size_land"            , -1, Parser.TypeNumber)
    self.nGridSizeOcean          = Parser:Get("Create", "grid_size_ocean"            , -1, Parser.TypeNumber)

    self.nHumanMinCreateDistance          = Parser:Get("Create", "human_min_distance"            , -1, Parser.TypeNumber)
    self.nHumanMinCreateDistance = self.nHumanMinCreateDistance
    self.nHumanMaxCreateDistance          = Parser:Get("Create", "human_max_distance"        , -1, Parser.TypeNumber)
    self.nHumanMaxCreateDistance = self.nHumanMaxCreateDistance

    self.nShipMinCreateDistance          = Parser:Get("Create", "ship_min_distance"            , -1, Parser.TypeNumber)
    self.nShipMinCreateDistance = self.nShipMinCreateDistance 
    self.nShipMaxCreateDistance          = Parser:Get("Create", "ship_max_distance"        , -1, Parser.TypeNumber)
    self.nShipMaxCreateDistance = self.nShipMaxCreateDistance 
    
    self.nMaxNpcCount          = Parser:Get("Create", "max_npc_count"        , -1, Parser.TypeNumber)
    self.nNpcCreateDelayTime          = Parser:Get("Create", "npc_create_delay_time"        , -1, Parser.TypeNumber)
    self.nSpecialNpcCreateDelayTime          = Parser:Get("Create", "special_npc_create_delay_time"        , -1, Parser.TypeNumber)
    
    self.nShipSpeedZoom          = Parser:Get("Create", "ship_speed_zoom"        , -1, Parser.TypeNumber)

    self.nToSpotProbability          = Parser:Get("AI", "to_spot_probability"        , -1, Parser.TypeNumber)
    self.nToPlayerProbability          = Parser:Get("AI", "to_player_probability"        , -1, Parser.TypeNumber)
    self.nToNpcProbability          = Parser:Get("AI", "to_npc_probability"        , -1, Parser.TypeNumber)
    self.nToSelfProbability          = Parser:Get("AI", "to_self_probability"        , -1, Parser.TypeNumber)

    self.nHumanTickIntervalDistance          = Parser:Get("AI", "human_tick_interval_distance"        , -1, Parser.TypeNumber)
    self.nHumanTickIntervalDistance = self.nHumanTickIntervalDistance * self.nHumanTickIntervalDistance

    self.nTurnToPlayDistance          = Parser:Get("AI", "human_turn_to_player_distance"        , -1, Parser.TypeNumber)
    self.nTurnToPlayDistance = self.nTurnToPlayDistance * self.nTurnToPlayDistance
    self.nHumanDisplayDistance          = Parser:Get("AI", "human_display_distance"        , -1, Parser.TypeNumber)
    self.nHumanDisplayDistance = self.nHumanDisplayDistance * self.nHumanDisplayDistance

    self.nShipDisplayDistance          = Parser:Get("AI", "ship_display_distance"        , -1, Parser.TypeNumber)
    self.nShipDisplayDistance = self.nShipDisplayDistance * self.nShipDisplayDistance


    self.nShipTickIntervalDistance          = Parser:Get("AI", "ship_tick_interval_distance"        , -1, Parser.TypeNumber)
    self.nShipTickIntervalDistance = self.nShipTickIntervalDistance * self.nShipTickIntervalDistance

    
    self.nInteractionMinDistance          = Parser:Get("AI", "interaction_min_distance"        , -1, Parser.TypeNumber)
    self.nInteractionMinDistance = self.nInteractionMinDistance * self.nInteractionMinDistance

    self.nInteractionShipMinDistance          = Parser:Get("AI", "interaction_ship_min_distance"        , -1, Parser.TypeNumber)
    self.nInteractionShipMinDistance = self.nInteractionShipMinDistance * self.nInteractionShipMinDistance

    self.nSpotCdTime          = Parser:Get("AI", "spot_cd_time"        , -1, Parser.TypeNumber)
    self.nFollowPlayerCdTime          = Parser:Get("AI", "follow_to_player_cd"        , -1, Parser.TypeNumber)
    self.nInteractionToNpcCdTime          = Parser:Get("AI", "interaction_to_npc_cd"        , -1, Parser.TypeNumber)
    self.nArtSelfCdTime          = Parser:Get("AI", "art_self_cd_time"        , -1, Parser.TypeNumber)
    self.nCommonCdTime          = Parser:Get("AI", "common_cd_tiem"        , -1, Parser.TypeNumber)

end

return AtmoSphereIni
