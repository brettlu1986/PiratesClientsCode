#include "Engine.h"
#include "U4LuaLib.h"
#include "U4LuaStack.hpp"
#include "ClientShell.h"
#include "Blueprint/UserWidget.h"
#include "RenderSettingsManager.h"
#include "SensitiveWords/SensitiveWordManager.h"
#include "Delegates/ClientDelegateManager.h"
#include "ChannelSdk/ChannelSdkManager.h"
#include "GVoiceSdk/GVoiceSdkManager.h"
#include "PersistentTimer/PersistentTimer.h"
#include "Hydra.h"
#include "GameCameraShotShell.h"
#include "GameObjectShell.h"
#include "GameSoundShell.h"
#include "GameDungeonShell.h"
#include "SaveGame/SaveGameManager.h"
#include "LandNavMeshDataManager.h"
#include "GameActorShell.h"
#include "Battle/TemplateActorDataManager.h"
#include "Battle/PiratesGridTypeManager.h"
#include "Battle/PiratesPlayerGrid.h"
#include "Battle/PiratesActorWeaponInhibitManager.h"
#include "PathNode/PathNodeFinder.h"
#include "Battle/PiratesActorTriggerGroupManager.h"
#include "AI/AICoverPointsManager.h"
#include "Battle/PiratesAreaTriggerManager.h"
#include "CommonActorShell.h"
#include "Network/RPCNetworkManager.h"
#include "Network/SocketNetworkManager.h"
#include "ShipMovementComponent.h"
#include "OceanNavGridManager.h"
#include "Network/Http/HttpHelper.h"
#include "Delegates/GameDelegateManager.h"
#include "Input/InputManager.h"
#include "Util/LogReport.h"
#include "Util/LuaTableRef.h"
#include "Game/Lua/GameLuaRoot.h"
#include "AI/DestructibleObject/AIDestructibleObjectManagerRoot.h"
#include "Game/SystemInfo/SystemInfoManager.h"
#include "AI/Vehicle/AIVehicleManager.h"
#include "AI/Smoke/AISmokeManager.h"
#include "AI/OceanGrid/AIOceanGridManagerRoot.h"
#include "DataSdk/DataSdkManager.h"

///////////////////////////////////////////////////////////////////////////////////////////////////////
class FU4LExportedClass1_ClientShell
{
    static bool LineActorIntersection(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 2));
        
        FVector* pBoxPosOffset_1 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 3, FVector, pBoxPosOffset_1);
        if(pBoxPosOffset_1 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: BoxPosOffset");
            return false;
        }
        auto& BoxPosOffset_1 = *pBoxPosOffset_1;
        
        
        FVector* pBoxExtent_2 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 4, FVector, pBoxExtent_2);
        if(pBoxExtent_2 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: BoxExtent");
            return false;
        }
        auto& BoxExtent_2 = *pBoxExtent_2;
        
        
        FVector* pLineStart_3 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 5, FVector, pLineStart_3);
        if(pLineStart_3 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: LineStart");
            return false;
        }
        auto& LineStart_3 = *pLineStart_3;
        
        
        FVector* pLineEnd_4 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 6, FVector, pLineEnd_4);
        if(pLineEnd_4 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: LineEnd");
            return false;
        }
        auto& LineEnd_4 = *pLineEnd_4;
        
        auto ReturnValue_5 = __OwnerObject->LineActorIntersection(Actor_0, BoxPosOffset_1, BoxExtent_2, LineStart_3, LineEnd_4);
        TU4LStack<bool>::Push(L, ReturnValue_5);
        OutRetCount = 1;
        return true;
    }

    static bool GetClientConnectionTimeout(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetClientConnectionTimeout();
        TU4LStack<float>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool SetClientConnectionTimeout(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Value_0 = TU4LStack<float>::Get(L, 2);
        __OwnerObject->SetClientConnectionTimeout(Value_0);
        OutRetCount = 0;
        return true;
    }

    static bool SetUseU4LuaEnabled(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Enabled_0 = TU4LStack<bool>::Get(L, 2);
        __OwnerObject->SetUseU4LuaEnabled(Enabled_0);
        OutRetCount = 0;
        return true;
    }

    static bool DumpReferencedObject(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->DumpReferencedObject();
        OutRetCount = 0;
        return true;
    }

    static bool BindOnCollectingWCOriginDelegate(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->BindOnCollectingWCOriginDelegate();
        OutRetCount = 0;
        return true;
    }

    static bool SetPlayerPawn(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto PlayerActor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 2));
        __OwnerObject->SetPlayerPawn(PlayerActor_0);
        OutRetCount = 0;
        return true;
    }

    static bool ResetLoading(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->ResetLoading();
        OutRetCount = 0;
        return true;
    }

    static bool EndLoading(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->EndLoading();
        OutRetCount = 0;
        return true;
    }

    static bool BeginLoading(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto InUserWidget_0 = Cast<UUserWidget>(TU4LStack<UObject*>::Get(L, 2));
        auto InTargetPercent_1 = TU4LStack<float>::Get(L, 3);
        auto InMiniTime_2 = TU4LStack<float>::Get(L, 4);
        auto ReturnValue_3 = __OwnerObject->BeginLoading(InUserWidget_0, InTargetPercent_1, InMiniTime_2);
        TU4LStack<bool>::Push(L, ReturnValue_3);
        OutRetCount = 1;
        return true;
    }

    static bool GetTextWidget(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto UserWidget_0 = Cast<UUserWidget>(TU4LStack<UObject*>::Get(L, 2));
        TArray<UWidget*> OutWidgets_1;
        __OwnerObject->GetTextWidget(UserWidget_0, OutWidgets_1);
        
        lua_newtable(L);
        int ArrayLength = OutWidgets_1.Num();
        if(ArrayLength > 0)
        {
            for (int ArrayIndex = 0; ArrayIndex < ArrayLength; ++ArrayIndex)
            {
                TU4LStack<UObject*>::Push(L, OutWidgets_1[ArrayIndex]);
                lua_rawseti(L, -2, ArrayIndex + 1);
            }
        }
        
        OutRetCount = 1;
        return true;
    }

    static bool GuidToString(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        
        FGuid* pGuid_0 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 2, FGuid, pGuid_0);
        if(pGuid_0 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: Guid");
            return false;
        }
        auto& Guid_0 = *pGuid_0;
        
        auto ReturnValue_1 = __OwnerObject->GuidToString(Guid_0);
        TU4LStack<FString>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool GetMemoryLog(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetMemoryLog();
        TU4LStack<FString>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool Dump10KLogManual(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->Dump10KLogManual();
        TU4LStack<float>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool DumpMemoryLogManual(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->DumpMemoryLogManual();
        OutRetCount = 0;
        return true;
    }

    static bool CrashRenderThread(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->CrashRenderThread();
        OutRetCount = 0;
        return true;
    }

    static bool TriggerCrashMannual(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto CrashType_0 = (ECrashType)TU4LStack<UEnum*>::Get(L, 2);
        __OwnerObject->TriggerCrashMannual(CrashType_0);
        OutRetCount = 0;
        return true;
    }

    static bool ShowMessageBox(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto MessageType_0 = TU4LStack<int32>::Get(L, 1);
        auto Text_1 = TU4LStack<FString>::Get(L, 2);
        auto Caption_2 = TU4LStack<FString>::Get(L, 3);
        auto ReturnValue_3 = UClientShell::ShowMessageBox(MessageType_0, Text_1, Caption_2);
        TU4LStack<int32>::Push(L, ReturnValue_3);
        OutRetCount = 1;
        return true;
    }

    static bool GetStreamingLevel(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 2));
        auto PackageName_1 = TU4LStack<FString>::Get(L, 3);
        auto ReturnValue_2 = __OwnerObject->GetStreamingLevel(WorldContextObject_0, PackageName_1);
        TU4LStack<UObject*>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool OnLoadLevelCompleted(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->OnLoadLevelCompleted();
        OutRetCount = 0;
        return true;
    }

    static bool UnloadStreamLevel(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 2));
        auto PackageName_1 = TU4LStack<FString>::Get(L, 3);
        __OwnerObject->UnloadStreamLevel(WorldContextObject_0, PackageName_1);
        OutRetCount = 0;
        return true;
    }

    static bool LoadStreamLevel(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 2));
        auto PackageName_1 = TU4LStack<FString>::Get(L, 3);
        __OwnerObject->LoadStreamLevel(WorldContextObject_0, PackageName_1);
        OutRetCount = 0;
        return true;
    }

    static bool FlushAsyncLoading(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->FlushAsyncLoading();
        OutRetCount = 0;
        return true;
    }

    static bool SerializeMatShaderAfterUpdate(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->SerializeMatShaderAfterUpdate();
        OutRetCount = 0;
        return true;
    }

    static bool ToggleSceneRendering(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto InFlag_0 = TU4LStack<bool>::Get(L, 2);
        __OwnerObject->ToggleSceneRendering(InFlag_0);
        OutRetCount = 0;
        return true;
    }

    static bool InitiallyLoadLevelStreaming(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->InitiallyLoadLevelStreaming();
        OutRetCount = 0;
        return true;
    }

    static bool GetPlayFromHereTransform(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        FVector Location_0;
        FRotator Rotation_1;
        __OwnerObject->GetPlayFromHereTransform(Location_0, Rotation_1);
        U4L_STACK_PUSH_STRUCT_VALUE(L, FVector, Location_0);
        U4L_STACK_PUSH_STRUCT_VALUE(L, FRotator, Rotation_1);
        OutRetCount = 2;
        return true;
    }

    static bool IsPlayFromHereInEditor(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->IsPlayFromHereInEditor();
        TU4LStack<bool>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetSystemInfoManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetSystemInfoManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetRenderSettingsManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetRenderSettingsManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetSensitiveWordManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetSensitiveWordManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetClientDelegateManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetClientDelegateManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetDataSdkManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetDataSdkManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetGVoiceSdkManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetGVoiceSdkManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetChannelSdkManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetChannelSdkManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetPersistentTimer(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetPersistentTimer();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetHydraClient(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetHydraClient();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool OpenLevelAsync(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto URL_0 = TU4LStack<FString>::Get(L, 2);
        __OwnerObject->OpenLevelAsync(URL_0);
        OutRetCount = 0;
        return true;
    }

    static bool IsInSmoothTravel(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->IsInSmoothTravel();
        TU4LStack<bool>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool ClientTravel(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto URL_0 = TU4LStack<FString>::Get(L, 2);
        auto bIsSmoothTravel_1 = TU4LStack<bool>::Get(L, 3);
        __OwnerObject->ClientTravel(URL_0, bIsSmoothTravel_1);
        OutRetCount = 0;
        return true;
    }

    static bool GetCameraShotShell(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetCameraShotShell();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetObjectShell(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetObjectShell();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetSoundShell(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetSoundShell();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetDungeonShell(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetDungeonShell();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetSaveGameManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetSaveGameManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetLandNavMeshDataManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetLandNavMeshDataManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetClientNetworkManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetClientNetworkManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetActorShell(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UClientShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetActorShell();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetClient(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        auto ReturnValue_1 = UClientShell::GetClient(WorldContextObject_0);
        TU4LStack<UObject*>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool RecordSpawnActorFrameCounter(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->RecordSpawnActorFrameCounter();
        OutRetCount = 0;
        return true;
    }

    static bool SetNetLogEnabled(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Enabled_0 = TU4LStack<bool>::Get(L, 1);
        UCommonShell::SetNetLogEnabled(Enabled_0);
        OutRetCount = 0;
        return true;
    }

    static bool SetRemoteLuaRepository(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto URL_0 = TU4LStack<FString>::Get(L, 1);
        UCommonShell::SetRemoteLuaRepository(URL_0);
        OutRetCount = 0;
        return true;
    }

    static bool GetWeaponInhibitManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetWeaponInhibitManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetLogReport(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetLogReport();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetLuaLib(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetLuaLib();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool IsPreloadMap(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->IsPreloadMap();
        TU4LStack<bool>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool IsGMEnabled(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->IsGMEnabled();
        TU4LStack<bool>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool CreateNewTestObject(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto PropertyNum_0 = TU4LStack<int32>::Get(L, 1);
        auto FunctionNum_1 = TU4LStack<int32>::Get(L, 2);
        auto FunctionInputParamNum_2 = TU4LStack<int32>::Get(L, 3);
        auto FunctionOutputParamNum_3 = TU4LStack<int32>::Get(L, 4);
        auto ReturnValue_4 = UCommonShell::CreateNewTestObject(PropertyNum_0, FunctionNum_1, FunctionInputParamNum_2, FunctionOutputParamNum_3);
        TU4LStack<UObject*>::Push(L, ReturnValue_4);
        OutRetCount = 1;
        return true;
    }

    static bool SetTemplateActorDataManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Manager_0 = Cast<UTemplateActorDataManager>(TU4LStack<UObject*>::Get(L, 2));
        __OwnerObject->SetTemplateActorDataManager(Manager_0);
        OutRetCount = 0;
        return true;
    }

    static bool GetAISmokeManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetAISmokeManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetAIOceanGridManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetAIOceanGridManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetAIVehicleManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetAIVehicleManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetTemplateActorDataManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetTemplateActorDataManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetGridTypeManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetGridTypeManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool RequestExit(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Force_0 = TU4LStack<bool>::Get(L, 2);
        __OwnerObject->RequestExit(Force_0);
        OutRetCount = 0;
        return true;
    }

    static bool GetPiratesPlayerGrid(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetPiratesPlayerGrid();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetConnectionTimeout(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetConnectionTimeout();
        TU4LStack<float>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetGameStatus(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetGameStatus();
        TU4LStack<UEnum*>::Push(L, TEXT("EPiratesGameStatus"), (int)ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool SetGameStatus(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Status_0 = (EPiratesGameStatus)TU4LStack<UEnum*>::Get(L, 2);
        __OwnerObject->SetGameStatus(Status_0);
        OutRetCount = 0;
        return true;
    }

    static bool GetPathNodeFinder(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetPathNodeFinder();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetActorTriggerGroupManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetActorTriggerGroupManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetAIDestructibleObjectManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetAIDestructibleObjectManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetAICoverPointsManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetAICoverPointsManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetAreaTriggerManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetAreaTriggerManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetCommonActorShell(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetCommonActorShell();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetRPCNetworkManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetRPCNetworkManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetShipMovementComponent(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 2));
        auto ReturnValue_1 = __OwnerObject->GetShipMovementComponent(Actor_0);
        TU4LStack<UObject*>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool GetOceanNavGridManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetOceanNavGridManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetHttpHelper(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetHttpHelper();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetGameDelegateManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetGameDelegateManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetInputManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetInputManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetCommon(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        auto ReturnValue_1 = UCommonShell::GetCommon(WorldContextObject_0);
        TU4LStack<UObject*>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool GetNearestHitResult(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto DamagedChannel_0 = (ECollisionChannel)TU4LStack<UEnum*>::Get(L, 1);
        
        TArray<FHitResult> Hits_1;
        auto Hits_1_Type = lua_type(L, 2);
        if (Hits_1_Type == LUA_TTABLE)
        {
            lua_len(L, 2);
            int ArrayLength = (int)luaL_checknumber(L, -1);
            lua_pop(L, 1);
        
            if (ArrayLength > 0)
            {
                Hits_1.Reserve(ArrayLength);
                int GetIndex = lua_gettop(L) + 1;
                for (int ArrayIndex = 0; ArrayIndex < ArrayLength; ++ArrayIndex)
                {
                    lua_rawgeti(L, 2, ArrayIndex + 1);
                    
                    FHitResult* pHits_1438508129 = nullptr;
                    U4L_STACK_GET_STRUCT_VALUE(L, GetIndex, FHitResult, pHits_1438508129);
                    if(pHits_1438508129 == nullptr)
                    {
                        OutError = TEXT("Invalid input struct param, name: Hits");
                        return false;
                    }
                    auto& Hits_1438508129 = *pHits_1438508129;
                    
                    Hits_1.Emplace(Hits_1438508129);
                    lua_pop(L, 1);
                }
            }
        }
        else if(Hits_1_Type == LUA_TNIL)
        {
            // Do nothing.
        }
        else
        {
            OutError = TEXT("Input array param must be a table or nil, name: Hits");
            return false;
        }
        
        
        FVector* pLocation_2 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 3, FVector, pLocation_2);
        if(pLocation_2 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: Location");
            return false;
        }
        auto& Location_2 = *pLocation_2;
        
        FHitResult OutHit_3;
        auto ReturnValue_4 = UEngineExtShell::GetNearestHitResult(DamagedChannel_0, Hits_1, Location_2, OutHit_3);
        TU4LStack<bool>::Push(L, ReturnValue_4);
        U4L_STACK_PUSH_STRUCT_VALUE(L, FHitResult, OutHit_3);
        OutRetCount = 2;
        return true;
    }

    static bool GetScreenPercentageDefault(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto ReturnValue_0 = UEngineExtShell::GetScreenPercentageDefault();
        TU4LStack<float>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool FlushLog(lua_State* L, int& OutRetCount, FString& OutError)
    {
        UEngineExtShell::FlushLog();
        OutRetCount = 0;
        return true;
    }

    static bool SetComponentDrawDistance(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Comp_0 = Cast<UPrimitiveComponent>(TU4LStack<UObject*>::Get(L, 1));
        UEngineExtShell::SetComponentDrawDistance(Comp_0);
        OutRetCount = 0;
        return true;
    }

    static bool SetSkeletalMeshComDrawDis(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Comp_0 = Cast<USkeletalMeshComponent>(TU4LStack<UObject*>::Get(L, 1));
        UEngineExtShell::SetSkeletalMeshComDrawDis(Comp_0);
        OutRetCount = 0;
        return true;
    }

    static bool PrintErrorLog(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Log_0 = TU4LStack<FString>::Get(L, 1);
        UEngineExtShell::PrintErrorLog(Log_0);
        OutRetCount = 0;
        return true;
    }

    static bool PrintWarningLog(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Log_0 = TU4LStack<FString>::Get(L, 1);
        UEngineExtShell::PrintWarningLog(Log_0);
        OutRetCount = 0;
        return true;
    }

    static bool PrintLog(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Log_0 = TU4LStack<FString>::Get(L, 1);
        UEngineExtShell::PrintLog(Log_0);
        OutRetCount = 0;
        return true;
    }

    static bool StaticFindClass(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Path_0 = TU4LStack<FString>::Get(L, 1);
        auto ReturnValue_1 = UEngineExtShell::StaticFindClass(Path_0);
        TU4LStack<UClass*>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool StaticFindObject(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Path_0 = TU4LStack<FString>::Get(L, 1);
        auto ReturnValue_1 = UEngineExtShell::StaticFindObject(Path_0);
        TU4LStack<UObject*>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool StaticLoadObjectWithoutFlush(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Path_0 = TU4LStack<FString>::Get(L, 1);
        auto ReturnValue_1 = UEngineExtShell::StaticLoadObjectWithoutFlush(Path_0);
        TU4LStack<UObject*>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool LoadFileLines(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Path_0 = TU4LStack<FString>::Get(L, 1);
        TArray<FString> Lines_1;
        auto ReturnValue_2 = UEngineExtShell::LoadFileLines(Path_0, Lines_1);
        TU4LStack<bool>::Push(L, ReturnValue_2);
        
        lua_newtable(L);
        int ArrayLength = Lines_1.Num();
        if(ArrayLength > 0)
        {
            for (int ArrayIndex = 0; ArrayIndex < ArrayLength; ++ArrayIndex)
            {
                TU4LStack<FString>::Push(L, Lines_1[ArrayIndex]);
                lua_rawseti(L, -2, ArrayIndex + 1);
            }
        }
        
        OutRetCount = 2;
        return true;
    }

    static bool ReloadEngineConfig(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UEngineExtShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->ReloadEngineConfig();
        OutRetCount = 0;
        return true;
    }

    static bool LoadMultiAssetsAsyncCallbackFire(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UEngineExtShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        
        TArray<UObject*> LoadedObjects_0;
        auto LoadedObjects_0_Type = lua_type(L, 2);
        if (LoadedObjects_0_Type == LUA_TTABLE)
        {
            lua_len(L, 2);
            int ArrayLength = (int)luaL_checknumber(L, -1);
            lua_pop(L, 1);
        
            if (ArrayLength > 0)
            {
                LoadedObjects_0.Reserve(ArrayLength);
                int GetIndex = lua_gettop(L) + 1;
                for (int ArrayIndex = 0; ArrayIndex < ArrayLength; ++ArrayIndex)
                {
                    lua_rawgeti(L, 2, ArrayIndex + 1);
                    auto LoadedObjects_1541101772 = Cast<UObject>(TU4LStack<UObject*>::Get(L, GetIndex));
                    LoadedObjects_0.Emplace(LoadedObjects_1541101772);
                    lua_pop(L, 1);
                }
            }
        }
        else if(LoadedObjects_0_Type == LUA_TNIL)
        {
            // Do nothing.
        }
        else
        {
            OutError = TEXT("Input array param must be a table or nil, name: LoadedObjects");
            return false;
        }
        
        __OwnerObject->LoadMultiAssetsAsyncCallbackFire(LoadedObjects_0);
        OutRetCount = 0;
        return true;
    }

    static bool LoadAssetAsync(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UEngineExtShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto AssetName_0 = TU4LStack<FString>::Get(L, 2);
        auto ReturnValue_1 = __OwnerObject->LoadAssetAsync(AssetName_0);
        TU4LStack<bool>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool GetWorldRealTimeSeconds(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UEngineExtShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetWorldRealTimeSeconds();
        TU4LStack<float>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetCurrentMapName(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UEngineExtShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetCurrentMapName();
        TU4LStack<FString>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetKMDelegateManager(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UEngineExtShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetKMDelegateManager();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GenerateObjectGuidString(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto ReturnValue_0 = UEngineExtShell::GenerateObjectGuidString();
        TU4LStack<FString>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool IsEditMode(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Object_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        auto ReturnValue_1 = UEngineExtShell::IsEditMode(Object_0);
        TU4LStack<bool>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool IsEditor(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto ReturnValue_0 = UEngineExtShell::IsEditor();
        TU4LStack<bool>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool Get(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        auto ReturnValue_1 = UEngineExtShell::Get(WorldContextObject_0);
        TU4LStack<UObject*>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

public:
    FU4LExportedClass1_ClientShell()
    {
        FName ClassName(TEXT("/Script/Client.ClientShell"));
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("LineActorIntersection"), &FU4LExportedClass1_ClientShell::LineActorIntersection);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetClientConnectionTimeout"), &FU4LExportedClass1_ClientShell::GetClientConnectionTimeout);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetClientConnectionTimeout"), &FU4LExportedClass1_ClientShell::SetClientConnectionTimeout);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetUseU4LuaEnabled"), &FU4LExportedClass1_ClientShell::SetUseU4LuaEnabled);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("DumpReferencedObject"), &FU4LExportedClass1_ClientShell::DumpReferencedObject);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("BindOnCollectingWCOriginDelegate"), &FU4LExportedClass1_ClientShell::BindOnCollectingWCOriginDelegate);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetPlayerPawn"), &FU4LExportedClass1_ClientShell::SetPlayerPawn);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ResetLoading"), &FU4LExportedClass1_ClientShell::ResetLoading);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("EndLoading"), &FU4LExportedClass1_ClientShell::EndLoading);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("BeginLoading"), &FU4LExportedClass1_ClientShell::BeginLoading);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetTextWidget"), &FU4LExportedClass1_ClientShell::GetTextWidget);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GuidToString"), &FU4LExportedClass1_ClientShell::GuidToString);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetMemoryLog"), &FU4LExportedClass1_ClientShell::GetMemoryLog);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("Dump10KLogManual"), &FU4LExportedClass1_ClientShell::Dump10KLogManual);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("DumpMemoryLogManual"), &FU4LExportedClass1_ClientShell::DumpMemoryLogManual);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("CrashRenderThread"), &FU4LExportedClass1_ClientShell::CrashRenderThread);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("TriggerCrashMannual"), &FU4LExportedClass1_ClientShell::TriggerCrashMannual);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ShowMessageBox"), &FU4LExportedClass1_ClientShell::ShowMessageBox);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetStreamingLevel"), &FU4LExportedClass1_ClientShell::GetStreamingLevel);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("OnLoadLevelCompleted"), &FU4LExportedClass1_ClientShell::OnLoadLevelCompleted);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("UnloadStreamLevel"), &FU4LExportedClass1_ClientShell::UnloadStreamLevel);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("LoadStreamLevel"), &FU4LExportedClass1_ClientShell::LoadStreamLevel);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("FlushAsyncLoading"), &FU4LExportedClass1_ClientShell::FlushAsyncLoading);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SerializeMatShaderAfterUpdate"), &FU4LExportedClass1_ClientShell::SerializeMatShaderAfterUpdate);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ToggleSceneRendering"), &FU4LExportedClass1_ClientShell::ToggleSceneRendering);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("InitiallyLoadLevelStreaming"), &FU4LExportedClass1_ClientShell::InitiallyLoadLevelStreaming);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetPlayFromHereTransform"), &FU4LExportedClass1_ClientShell::GetPlayFromHereTransform);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("IsPlayFromHereInEditor"), &FU4LExportedClass1_ClientShell::IsPlayFromHereInEditor);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetSystemInfoManager"), &FU4LExportedClass1_ClientShell::GetSystemInfoManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetRenderSettingsManager"), &FU4LExportedClass1_ClientShell::GetRenderSettingsManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetSensitiveWordManager"), &FU4LExportedClass1_ClientShell::GetSensitiveWordManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetClientDelegateManager"), &FU4LExportedClass1_ClientShell::GetClientDelegateManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetDataSdkManager"), &FU4LExportedClass1_ClientShell::GetDataSdkManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetGVoiceSdkManager"), &FU4LExportedClass1_ClientShell::GetGVoiceSdkManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetChannelSdkManager"), &FU4LExportedClass1_ClientShell::GetChannelSdkManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetPersistentTimer"), &FU4LExportedClass1_ClientShell::GetPersistentTimer);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetHydraClient"), &FU4LExportedClass1_ClientShell::GetHydraClient);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("OpenLevelAsync"), &FU4LExportedClass1_ClientShell::OpenLevelAsync);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("IsInSmoothTravel"), &FU4LExportedClass1_ClientShell::IsInSmoothTravel);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ClientTravel"), &FU4LExportedClass1_ClientShell::ClientTravel);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetCameraShotShell"), &FU4LExportedClass1_ClientShell::GetCameraShotShell);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetObjectShell"), &FU4LExportedClass1_ClientShell::GetObjectShell);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetSoundShell"), &FU4LExportedClass1_ClientShell::GetSoundShell);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetDungeonShell"), &FU4LExportedClass1_ClientShell::GetDungeonShell);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetSaveGameManager"), &FU4LExportedClass1_ClientShell::GetSaveGameManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetLandNavMeshDataManager"), &FU4LExportedClass1_ClientShell::GetLandNavMeshDataManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetClientNetworkManager"), &FU4LExportedClass1_ClientShell::GetClientNetworkManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetActorShell"), &FU4LExportedClass1_ClientShell::GetActorShell);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetClient"), &FU4LExportedClass1_ClientShell::GetClient);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("RecordSpawnActorFrameCounter"), &FU4LExportedClass1_ClientShell::RecordSpawnActorFrameCounter);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetNetLogEnabled"), &FU4LExportedClass1_ClientShell::SetNetLogEnabled);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetRemoteLuaRepository"), &FU4LExportedClass1_ClientShell::SetRemoteLuaRepository);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetWeaponInhibitManager"), &FU4LExportedClass1_ClientShell::GetWeaponInhibitManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetLogReport"), &FU4LExportedClass1_ClientShell::GetLogReport);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetLuaLib"), &FU4LExportedClass1_ClientShell::GetLuaLib);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("IsPreloadMap"), &FU4LExportedClass1_ClientShell::IsPreloadMap);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("IsGMEnabled"), &FU4LExportedClass1_ClientShell::IsGMEnabled);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("CreateNewTestObject"), &FU4LExportedClass1_ClientShell::CreateNewTestObject);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetTemplateActorDataManager"), &FU4LExportedClass1_ClientShell::SetTemplateActorDataManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetAISmokeManager"), &FU4LExportedClass1_ClientShell::GetAISmokeManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetAIOceanGridManager"), &FU4LExportedClass1_ClientShell::GetAIOceanGridManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetAIVehicleManager"), &FU4LExportedClass1_ClientShell::GetAIVehicleManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetTemplateActorDataManager"), &FU4LExportedClass1_ClientShell::GetTemplateActorDataManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetGridTypeManager"), &FU4LExportedClass1_ClientShell::GetGridTypeManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("RequestExit"), &FU4LExportedClass1_ClientShell::RequestExit);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetPiratesPlayerGrid"), &FU4LExportedClass1_ClientShell::GetPiratesPlayerGrid);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetConnectionTimeout"), &FU4LExportedClass1_ClientShell::GetConnectionTimeout);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetGameStatus"), &FU4LExportedClass1_ClientShell::GetGameStatus);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetGameStatus"), &FU4LExportedClass1_ClientShell::SetGameStatus);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetPathNodeFinder"), &FU4LExportedClass1_ClientShell::GetPathNodeFinder);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetActorTriggerGroupManager"), &FU4LExportedClass1_ClientShell::GetActorTriggerGroupManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetAIDestructibleObjectManager"), &FU4LExportedClass1_ClientShell::GetAIDestructibleObjectManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetAICoverPointsManager"), &FU4LExportedClass1_ClientShell::GetAICoverPointsManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetAreaTriggerManager"), &FU4LExportedClass1_ClientShell::GetAreaTriggerManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetCommonActorShell"), &FU4LExportedClass1_ClientShell::GetCommonActorShell);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetRPCNetworkManager"), &FU4LExportedClass1_ClientShell::GetRPCNetworkManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetShipMovementComponent"), &FU4LExportedClass1_ClientShell::GetShipMovementComponent);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetOceanNavGridManager"), &FU4LExportedClass1_ClientShell::GetOceanNavGridManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetHttpHelper"), &FU4LExportedClass1_ClientShell::GetHttpHelper);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetGameDelegateManager"), &FU4LExportedClass1_ClientShell::GetGameDelegateManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetInputManager"), &FU4LExportedClass1_ClientShell::GetInputManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetCommon"), &FU4LExportedClass1_ClientShell::GetCommon);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetNearestHitResult"), &FU4LExportedClass1_ClientShell::GetNearestHitResult);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetScreenPercentageDefault"), &FU4LExportedClass1_ClientShell::GetScreenPercentageDefault);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("FlushLog"), &FU4LExportedClass1_ClientShell::FlushLog);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetComponentDrawDistance"), &FU4LExportedClass1_ClientShell::SetComponentDrawDistance);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetSkeletalMeshComDrawDis"), &FU4LExportedClass1_ClientShell::SetSkeletalMeshComDrawDis);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("PrintErrorLog"), &FU4LExportedClass1_ClientShell::PrintErrorLog);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("PrintWarningLog"), &FU4LExportedClass1_ClientShell::PrintWarningLog);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("PrintLog"), &FU4LExportedClass1_ClientShell::PrintLog);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("StaticFindClass"), &FU4LExportedClass1_ClientShell::StaticFindClass);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("StaticFindObject"), &FU4LExportedClass1_ClientShell::StaticFindObject);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("StaticLoadObjectWithoutFlush"), &FU4LExportedClass1_ClientShell::StaticLoadObjectWithoutFlush);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("LoadFileLines"), &FU4LExportedClass1_ClientShell::LoadFileLines);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ReloadEngineConfig"), &FU4LExportedClass1_ClientShell::ReloadEngineConfig);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("LoadMultiAssetsAsyncCallbackFire"), &FU4LExportedClass1_ClientShell::LoadMultiAssetsAsyncCallbackFire);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("LoadAssetAsync"), &FU4LExportedClass1_ClientShell::LoadAssetAsync);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetWorldRealTimeSeconds"), &FU4LExportedClass1_ClientShell::GetWorldRealTimeSeconds);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetCurrentMapName"), &FU4LExportedClass1_ClientShell::GetCurrentMapName);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetKMDelegateManager"), &FU4LExportedClass1_ClientShell::GetKMDelegateManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GenerateObjectGuidString"), &FU4LExportedClass1_ClientShell::GenerateObjectGuidString);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("IsEditMode"), &FU4LExportedClass1_ClientShell::IsEditMode);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("IsEditor"), &FU4LExportedClass1_ClientShell::IsEditor);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("Get"), &FU4LExportedClass1_ClientShell::Get);
    }
};
static FU4LExportedClass1_ClientShell GRegister_FU4LExportedClass1_ClientShell;
