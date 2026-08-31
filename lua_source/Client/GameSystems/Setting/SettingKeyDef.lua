local SettingKeyDef = {}

SettingKeyDef.RemoveKeyStart = 1
SettingKeyDef.RemoveKeyEnd = 9999

SettingKeyDef.LocalKeyStart = 10000
SettingKeyDef.LocalKeyEnd   = 10500

-- 服务器存储数据 1-9999
SettingKeyDef.RemoteKeys = {
    ALLOW_WATCH_SEASON_STATS  = 100,    --允许别人查看个人战绩
    ALLOW_WATCH_HISTORY_STATS = 101,    --允许别人查看历史战绩

    ALLOW_WATCH_OTHER_RELATION = 102,
    ALOOW_WATCH_TEAM_RELATION  = 103,

    --布局1
    --通用布局  1200 - 1299
    --人布局    1300 - 1399
    --船布局    1400 - 1499
    --坐骑布局  1500 - 1599

    --布局2
    --通用布局  2200 - 2299
    --人布局    2300 - 2399
    --船布局    2400 - 2499
    --坐骑布局  2500 - 2599

    --布局风格
    LAYOUT_HUMAN_STYLE = 1000,
    LAYOUT_SHIP_STYLE = 1001,
    LAYOUT_VEHICLE_STYLE = 1002,

    --操作方式
    CONTROL_MODE_VEHICLE = 2000,
    CONTROL_MODE_SHIP = 2001,
}

-- 本地保存数据 从10000开始
SettingKeyDef.LocalKeys = {
    -- 左手开火建
    FIRE_BY_LEFT_HAND = 10000,
    --人物状态陀螺仪
    HUMAN_GYRO = 10001,
    --舰船状态陀螺仪
    SHIP_GYRO = 10002,
    --吸附开关
    AIM_ASSIST = 10003,
    --智能药品推荐
    MEDICINE_RECOMMEND = 10004,
    -- 出航登录辅助
    CHANGE_DISPLAY = 10005,
    -- 载具自动跟随
    AUTO_ROT = 10006,
    -- 默认状态船帆透明度
    NORMAL_SAIL_OPACITY = 10007,
    -- 默认状态船帆透明度
    FIRING_SAIL_OPACITY = 10008,
    -- 自动开门
    AUTO_OPEN_DOOR = 10009,

    -- 画面品质
    FRAME_QUALITY = 10050,
    -- 帧数设置
    FPS_QUALITY = 10051,
    -- 画面风格
    FRAME_STYLE = 10052,
    -- 亮度
    FRAME_BRIGHTNESS = 10053,
    -- 自适应
    AUTO_ADAPTIVE = 10054,
    -- 异形屏边距
    CUTOUT_SPACER_WIDTH = 10055,

    -- 主音量
    ALL_SOUND = 10070,
    -- 界面音效
    UI_SOUND = 10071,
    -- 音效
    SFX_SOUND = 10072,
    -- 背景音乐
    MUSIC = 10073,
    -- 麦克风
    MIC = 10074,
    -- 喇叭
    HORN = 10075,

    ALL_SOUND_ACTIVATE = 10076,
    UI_SOUND_ACTIVATE = 10077,
    SFX_SOUND_ACTIVATE = 10078,
    MUSIC_SOUND_ACTIVATE = 10079,
    MIC_VOLUME = 10080,
    HORN_VOLUME = 10081,

    -- 快捷聊天
    QUICK_CHAT_1 = 10100,
    QUICK_CHAT_2 = 10101,
    QUICK_CHAT_3 = 10102,
    QUICK_CHAT_4 = 10103,
    QUICK_CHAT_5 = 10104,
    QUICK_CHAT_6 = 10105,
    QUICK_CHAT_7 = 10106,
    QUICK_CHAT_8 = 10107,
    QUICK_CHAT_9 = 10108,
    QUICK_CHAT_10 = 10109,

    -- 拾取
    PICK_UP_AUTO  = 10200,
    PICK_UP_AUTO_CHANGE_SAIL  = 10201,
    PICK_UP_LIST_AUTO = 10021,
    PICK_UP_START = 10202,
    PICK_UP_END = 10299,

    -- 镜头
    -- 全局灵敏度
    CAMERA_GLOBAL_SENSITIVITY = 10300,
    -- 跳伞状态
    CAMERA_PARACHUTING_SENSITIVITY = 10301,
    -- 人物状态不开镜
    CAMERA_HUMAN_CLOSE_SENSITIVITY = 10302,
    -- 人物状态开镜
    CAMERA_HUMAN_OPEN_SENSITIVITY = 10303,
    -- 舰船状态不开镜
    CAMERA_SHIP_CLOSE_SENSITIVITY = 10304,
    -- 舰船状态开镜（2倍）
    CAMERA_SHIP_OPEN2_SENSITIVITY = 10305,
    -- 舰船状态开镜（4倍）
    CAMERA_SHIP_OPEN4_SENSITIVITY = 10306,
    -- 舰船状态开镜（8倍）
    CAMERA_SHIP_OPEN8_SENSITIVITY = 10307,

    --陀螺仪 
    GYRO_PARACHUTING_SENSITIVITY = 10320,
    -- 人物状态不开镜
    GYRO_HUMAN_CLOSE_SENSITIVITY = 10321,
    -- 人物状态开镜
    GYRO_HUMAN_OPEN_SENSITIVITY = 10322,
    -- 舰船状态不开镜
    GYRO_SHIP_CLOSE_SENSITIVITY = 10323,
    -- 舰船状态开镜（2倍）
    GYRO_SHIP_OPEN2_SENSITIVITY = 10324,
    -- 舰船状态开镜（4倍）
    GYRO_SHIP_OPEN4_SENSITIVITY = 10325,
    -- 舰船状态开镜（8倍）
    GYRO_SHIP_OPEN8_SENSITIVITY = 10326,
}

SettingKeyDef.tbLocal  = nil
SettingKeyDef.tbRemote = nil

function SettingKeyDef.Init()
    SettingKeyDef.tbRemote = {}
    for k, v in pairs(SettingKeyDef.RemoteKeys) do
        SettingKeyDef.tbRemote[v] = k
    end

    SettingKeyDef.tbLocal  = {}
    for k, v in pairs(SettingKeyDef.LocalKeys) do
        SettingKeyDef.tbLocal[v] = k
    end
end

SettingKeyDef.Init()

return SettingKeyDef