local SettingKeyDef = require("SettingKeyDef")

local SettingValueDef = {}

local LocalKeys = SettingKeyDef.LocalKeys

SettingValueDef.DefaultValues = {
    [LocalKeys.HUMAN_GYRO] = 0,
    [LocalKeys.SHIP_GYRO] = 0,
    [LocalKeys.AIM_ASSIST] = 0,
    [LocalKeys.MEDICINE_RECOMMEND] = 1,
    [LocalKeys.CHANGE_DISPLAY] = 1,
    [LocalKeys.AUTO_ROT] = 1,
    [LocalKeys.AUTO_OPEN_DOOR] = 1,
    
    [LocalKeys.FRAME_QUALITY] = -1,
    [LocalKeys.FPS_QUALITY] = -1,
    [LocalKeys.FRAME_STYLE] = -1,
    [LocalKeys.FRAME_BRIGHTNESS] = -1,
    [LocalKeys.AUTO_ADAPTIVE] = -1,

    [LocalKeys.ALL_SOUND] = 100,
    [LocalKeys.UI_SOUND] = 100,
    [LocalKeys.SFX_SOUND] = 100,
    [LocalKeys.MUSIC] = 100,
    [LocalKeys.MIC] = 100,
    [LocalKeys.HORN] = 100,    
    [LocalKeys.ALL_SOUND_ACTIVATE] = 1,
    [LocalKeys.UI_SOUND_ACTIVATE] = 1,
    [LocalKeys.SFX_SOUND_ACTIVATE] = 1,
    [LocalKeys.MUSIC_SOUND_ACTIVATE] = 1,
    [LocalKeys.MIC_VOLUME] = 1,
    [LocalKeys.HORN_VOLUME] = 1,    

    [LocalKeys.FIRE_BY_LEFT_HAND] = 2,
    
    [LocalKeys.QUICK_CHAT_1] = -1,
    [LocalKeys.QUICK_CHAT_2] = -1,
    [LocalKeys.QUICK_CHAT_3] = -1,
    [LocalKeys.QUICK_CHAT_4] = -1,
    [LocalKeys.QUICK_CHAT_5] = -1,
    [LocalKeys.QUICK_CHAT_6] = -1,
    [LocalKeys.QUICK_CHAT_7] = -1,
    [LocalKeys.QUICK_CHAT_8] = -1,
    [LocalKeys.QUICK_CHAT_9] = -1,
    [LocalKeys.QUICK_CHAT_10] = -1,

    [LocalKeys.PICK_UP_AUTO] = 1,
    [LocalKeys.PICK_UP_AUTO_CHANGE_SAIL] = 1,
    [LocalKeys.PICK_UP_LIST_AUTO] = 1,

    [LocalKeys.CAMERA_GLOBAL_SENSITIVITY] = 2 
}

return SettingValueDef