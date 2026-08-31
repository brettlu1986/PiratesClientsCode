local ScreenCaptureHelper = {}

local CppDelegate = require("CppDelegate")

local pTempCaptureScreenDelegate = nil
local fnCallback = nil
local tbObject = nil

local function OnScreenShotCaptureFinished(nWidth, nHeight, pShotTexture)
    pTempCaptureScreenDelegate:Unbind()
    pTempCaptureScreenDelegate = nil
    if tbObject then
        fnCallback(tbObject, nWidth, nHeight, pShotTexture)
    else
        fnCallback(nWidth, nHeight, pShotTexture)
    end
end

-- Lua里默认截图后不会保存，需要手动调用SaveScreenshot才会保存
function ScreenCaptureHelper.Capture(fnInCallback, tbInObject)
    assert(fnInCallback)
    fnCallback = fnInCallback
    tbObject = tbInObject
    pTempCaptureScreenDelegate = CppDelegate:Bind(ClientShell.GetClient(GWorld):GetCameraShotShell().ScreenShotCaptureFinishedDelegate, OnScreenShotCaptureFinished)
    ClientShell.GetClient(GWorld):GetCameraShotShell():RequestScreenshot(true, false, "", false, 1.0)
end

-- 保存上一次截图结果
function ScreenCaptureHelper.SaveScreenshot()
    ClientShell.GetClient(GWorld):GetCameraShotShell():SaveScreenshot()
end

return ScreenCaptureHelper