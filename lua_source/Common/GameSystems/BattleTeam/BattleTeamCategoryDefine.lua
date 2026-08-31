local BattleTeamCategoryDefine = {}

BattleTeamCategoryDefine.tbCategoryType            = {}
BattleTeamCategoryDefine.tbCategoryType.BaseInfo   = 1
BattleTeamCategoryDefine.tbCategoryType.HealthInfo = 1<<1
BattleTeamCategoryDefine.tbCategoryType.StateInfo  = 1<<2
BattleTeamCategoryDefine.tbCategoryType.PosInfo    = 1<<3
BattleTeamCategoryDefine.tbCategoryType.SignInfo   = 1<<4
BattleTeamCategoryDefine.tbCategoryType.IDInfo     = 1<<5

BattleTeamCategoryDefine.tbCategoryType.All        = BattleTeamCategoryDefine.tbCategoryType.BaseInfo   |
                                                     BattleTeamCategoryDefine.tbCategoryType.HealthInfo |
                                                     BattleTeamCategoryDefine.tbCategoryType.StateInfo  |
                                                     BattleTeamCategoryDefine.tbCategoryType.PosInfo    |
                                                     BattleTeamCategoryDefine.tbCategoryType.SignInfo   |
                                                     BattleTeamCategoryDefine.tbCategoryType.IDInfo


return BattleTeamCategoryDefine
