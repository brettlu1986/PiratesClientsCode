#include "Engine.h"
#include "U4LuaLib.h"
#include "U4LuaStack.hpp"
#include "Shell/EngineExtActorShell.h"
#include "Shell/CommonShell.h"
#include "Shell/CommonActorShell.h"
#include "ExtendBlueprintFunctions.h"
#include "Network/RPCNetworkManager.h"
#include "Network/SocketNetworkManager.h"
#include "Network/CustomReplicationComponent.h"
#include "Network/ReplicatedProtoCallComponent.h"
#include "Engine/Classes/Kismet/KismetSystemLibrary.h"
#include "ExtendBlueprintFunctions.h"
#include "Game/Battle/PiratesGridTypeManager.h"
#include "Util/LuaTableRef.h"
#include "ShipMovementComponent.h"
#include "Battle/TemplateActorDataManager.h"
#include "Game/Battle/PiratesPlayerGrid.h"
#include "Game/PathNode/PathNodeFinder.h"
#include "Game/Battle/PiratesActorTriggerGroupManager.h"
#include "AI/AICoverPointsManager.h"
#include "Game/Battle/PiratesAreaTriggerManager.h"
#include "OceanNavGridManager.h"
#include "Network/Http/HttpHelper.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Game/Input/InputManager.h"
#include "Game/Delegates/KMDelegateManager.h"
#include "KMPlayerController.h"
#include "Game/Battle/PiratesActorWeaponInhibitManager.h"
#include "Util/LogReport.h"
#include "AI/DestructibleObject/AIDestructibleObjectManagerRoot.h"
#include "AI/Vehicle/AIVehicleManager.h"
#include "AI/Smoke/AISmokeManager.h"
#include "AI/OceanGrid/AIOceanGridManagerRoot.h"

///////////////////////////////////////////////////////////////////////////////////////////////////////
class FU4LExportedClass0_KismetSystemLibrary
{
    static bool K2_SetTimer(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Object_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        auto FunctionName_1 = TU4LStack<FString>::Get(L, 2);
        auto Time_2 = TU4LStack<float>::Get(L, 3);
        auto bLooping_3 = TU4LStack<bool>::Get(L, 4);
        auto InitialStartDelay_4 = TU4LStack<float>::Get(L, 5);
        auto InitialStartDelayVariance_5 = TU4LStack<float>::Get(L, 6);
        auto ReturnValue_6 = UKismetSystemLibrary::K2_SetTimer(Object_0, FunctionName_1, Time_2, bLooping_3, InitialStartDelay_4, InitialStartDelayVariance_5);
        U4L_STACK_PUSH_STRUCT_VALUE(L, FTimerHandle, ReturnValue_6);
        OutRetCount = 1;
        return true;
    }

    static bool K2_GetTimerRemainingTimeHandle(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        
        FTimerHandle* pHandle_1 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 2, FTimerHandle, pHandle_1);
        if(pHandle_1 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: Handle");
            return false;
        }
        auto& Handle_1 = *pHandle_1;
        
        auto ReturnValue_2 = UKismetSystemLibrary::K2_GetTimerRemainingTimeHandle(WorldContextObject_0, Handle_1);
        TU4LStack<float>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool K2_GetTimerElapsedTimeHandle(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        
        FTimerHandle* pHandle_1 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 2, FTimerHandle, pHandle_1);
        if(pHandle_1 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: Handle");
            return false;
        }
        auto& Handle_1 = *pHandle_1;
        
        auto ReturnValue_2 = UKismetSystemLibrary::K2_GetTimerElapsedTimeHandle(WorldContextObject_0, Handle_1);
        TU4LStack<float>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool K2_IsTimerPausedHandle(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        
        FTimerHandle* pHandle_1 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 2, FTimerHandle, pHandle_1);
        if(pHandle_1 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: Handle");
            return false;
        }
        auto& Handle_1 = *pHandle_1;
        
        auto ReturnValue_2 = UKismetSystemLibrary::K2_IsTimerPausedHandle(WorldContextObject_0, Handle_1);
        TU4LStack<bool>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool K2_IsTimerActiveHandle(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        
        FTimerHandle* pHandle_1 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 2, FTimerHandle, pHandle_1);
        if(pHandle_1 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: Handle");
            return false;
        }
        auto& Handle_1 = *pHandle_1;
        
        auto ReturnValue_2 = UKismetSystemLibrary::K2_IsTimerActiveHandle(WorldContextObject_0, Handle_1);
        TU4LStack<bool>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool K2_UnPauseTimerHandle(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        
        FTimerHandle* pHandle_1 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 2, FTimerHandle, pHandle_1);
        if(pHandle_1 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: Handle");
            return false;
        }
        auto& Handle_1 = *pHandle_1;
        
        UKismetSystemLibrary::K2_UnPauseTimerHandle(WorldContextObject_0, Handle_1);
        OutRetCount = 0;
        return true;
    }

    static bool K2_PauseTimerHandle(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        
        FTimerHandle* pHandle_1 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 2, FTimerHandle, pHandle_1);
        if(pHandle_1 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: Handle");
            return false;
        }
        auto& Handle_1 = *pHandle_1;
        
        UKismetSystemLibrary::K2_PauseTimerHandle(WorldContextObject_0, Handle_1);
        OutRetCount = 0;
        return true;
    }

    static bool K2_ClearTimerHandle(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        
        FTimerHandle* pHandle_1 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 2, FTimerHandle, pHandle_1);
        if(pHandle_1 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: Handle");
            return false;
        }
        auto& Handle_1 = *pHandle_1;
        
        UKismetSystemLibrary::K2_ClearTimerHandle(WorldContextObject_0, Handle_1);
        OutRetCount = 0;
        return true;
    }

public:
    FU4LExportedClass0_KismetSystemLibrary()
    {
        FName ClassName(TEXT("/Script/Engine.KismetSystemLibrary"));
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("K2_SetTimer"), &FU4LExportedClass0_KismetSystemLibrary::K2_SetTimer);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("K2_GetTimerRemainingTimeHandle"), &FU4LExportedClass0_KismetSystemLibrary::K2_GetTimerRemainingTimeHandle);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("K2_GetTimerElapsedTimeHandle"), &FU4LExportedClass0_KismetSystemLibrary::K2_GetTimerElapsedTimeHandle);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("K2_IsTimerPausedHandle"), &FU4LExportedClass0_KismetSystemLibrary::K2_IsTimerPausedHandle);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("K2_IsTimerActiveHandle"), &FU4LExportedClass0_KismetSystemLibrary::K2_IsTimerActiveHandle);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("K2_UnPauseTimerHandle"), &FU4LExportedClass0_KismetSystemLibrary::K2_UnPauseTimerHandle);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("K2_PauseTimerHandle"), &FU4LExportedClass0_KismetSystemLibrary::K2_PauseTimerHandle);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("K2_ClearTimerHandle"), &FU4LExportedClass0_KismetSystemLibrary::K2_ClearTimerHandle);
    }
};
static FU4LExportedClass0_KismetSystemLibrary GRegister_FU4LExportedClass0_KismetSystemLibrary;

///////////////////////////////////////////////////////////////////////////////////////////////////////
class FU4LExportedClass0_EngineExtActorShell
{
    static bool ResetDrawDistanceWithCharacterValue(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        UEngineExtActorShell::ResetDrawDistanceWithCharacterValue(Actor_0);
        OutRetCount = 0;
        return true;
    }

    static bool SetActorMeshTranslucency(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto pActor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        auto nTranslucencySortPriority_1 = TU4LStack<float>::Get(L, 2);
        UEngineExtActorShell::SetActorMeshTranslucency(pActor_0, nTranslucencySortPriority_1);
        OutRetCount = 0;
        return true;
    }

    static bool GetLocalHostAddress(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto ReturnValue_0 = UEngineExtActorShell::GetLocalHostAddress();
        TU4LStack<FString>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetSkeletalMeshSocketTransformRTSMesh(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Component_0 = Cast<USkinnedMeshComponent>(TU4LStack<UObject*>::Get(L, 1));
        auto InSocketName_1 = TU4LStack<FName>::Get(L, 2);
        auto ReturnValue_2 = UEngineExtActorShell::GetSkeletalMeshSocketTransformRTSMesh(Component_0, InSocketName_1);
        U4L_STACK_PUSH_STRUCT_VALUE(L, FTransform, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool SetComponentEditorOnly(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto ActorComponent_0 = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        auto bEditorOnly_1 = TU4LStack<bool>::Get(L, 2);
        UEngineExtActorShell::SetComponentEditorOnly(ActorComponent_0, bEditorOnly_1);
        OutRetCount = 0;
        return true;
    }

    static bool GetLocationZOnStaticWorld(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        
        FVector* pLocation_1 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 2, FVector, pLocation_1);
        if(pLocation_1 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: Location");
            return false;
        }
        auto& Location_1 = *pLocation_1;
        
        
        TArray<AActor*> ActorsToIgnore_2;
        auto ActorsToIgnore_2_Type = lua_type(L, 3);
        if (ActorsToIgnore_2_Type == LUA_TTABLE)
        {
            lua_len(L, 3);
            int ArrayLength = (int)luaL_checknumber(L, -1);
            lua_pop(L, 1);
        
            if (ArrayLength > 0)
            {
                ActorsToIgnore_2.Reserve(ArrayLength);
                int GetIndex = lua_gettop(L) + 1;
                for (int ArrayIndex = 0; ArrayIndex < ArrayLength; ++ArrayIndex)
                {
                    lua_rawgeti(L, 3, ArrayIndex + 1);
                    auto ActorsToIgnore_3863576946 = Cast<AActor>(TU4LStack<UObject*>::Get(L, GetIndex));
                    ActorsToIgnore_2.Emplace(ActorsToIgnore_3863576946);
                    lua_pop(L, 1);
                }
            }
        }
        else if(ActorsToIgnore_2_Type == LUA_TNIL)
        {
            // Do nothing.
        }
        else
        {
            OutError = TEXT("Input array param must be a table or nil, name: ActorsToIgnore");
            return false;
        }
        
        auto AddZ_3 = TU4LStack<float>::Get(L, 4);
        auto MinusZ_4 = TU4LStack<float>::Get(L, 5);
        auto ReturnValue_5 = UEngineExtActorShell::GetLocationZOnStaticWorld(WorldContextObject_0, Location_1, ActorsToIgnore_2, AddZ_3, MinusZ_4);
        TU4LStack<float>::Push(L, ReturnValue_5);
        OutRetCount = 1;
        return true;
    }

    static bool GetLocationZOnFloor(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        
        FVector* pLocation_1 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 2, FVector, pLocation_1);
        if(pLocation_1 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: Location");
            return false;
        }
        auto& Location_1 = *pLocation_1;
        
        
        TArray<AActor*> ActorsToIgnore_2;
        auto ActorsToIgnore_2_Type = lua_type(L, 3);
        if (ActorsToIgnore_2_Type == LUA_TTABLE)
        {
            lua_len(L, 3);
            int ArrayLength = (int)luaL_checknumber(L, -1);
            lua_pop(L, 1);
        
            if (ArrayLength > 0)
            {
                ActorsToIgnore_2.Reserve(ArrayLength);
                int GetIndex = lua_gettop(L) + 1;
                for (int ArrayIndex = 0; ArrayIndex < ArrayLength; ++ArrayIndex)
                {
                    lua_rawgeti(L, 3, ArrayIndex + 1);
                    auto ActorsToIgnore_3863576946 = Cast<AActor>(TU4LStack<UObject*>::Get(L, GetIndex));
                    ActorsToIgnore_2.Emplace(ActorsToIgnore_3863576946);
                    lua_pop(L, 1);
                }
            }
        }
        else if(ActorsToIgnore_2_Type == LUA_TNIL)
        {
            // Do nothing.
        }
        else
        {
            OutError = TEXT("Input array param must be a table or nil, name: ActorsToIgnore");
            return false;
        }
        
        auto AddZ_3 = TU4LStack<float>::Get(L, 4);
        auto MinusZ_4 = TU4LStack<float>::Get(L, 5);
        auto ReturnValue_5 = UEngineExtActorShell::GetLocationZOnFloor(WorldContextObject_0, Location_1, ActorsToIgnore_2, AddZ_3, MinusZ_4);
        TU4LStack<float>::Push(L, ReturnValue_5);
        OutRetCount = 1;
        return true;
    }

    static bool GetLocationOnFloor(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        
        FVector* pLocation_1 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 2, FVector, pLocation_1);
        if(pLocation_1 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: Location");
            return false;
        }
        auto& Location_1 = *pLocation_1;
        
        
        TArray<AActor*> ActorsToIgnore_2;
        auto ActorsToIgnore_2_Type = lua_type(L, 3);
        if (ActorsToIgnore_2_Type == LUA_TTABLE)
        {
            lua_len(L, 3);
            int ArrayLength = (int)luaL_checknumber(L, -1);
            lua_pop(L, 1);
        
            if (ArrayLength > 0)
            {
                ActorsToIgnore_2.Reserve(ArrayLength);
                int GetIndex = lua_gettop(L) + 1;
                for (int ArrayIndex = 0; ArrayIndex < ArrayLength; ++ArrayIndex)
                {
                    lua_rawgeti(L, 3, ArrayIndex + 1);
                    auto ActorsToIgnore_3863576946 = Cast<AActor>(TU4LStack<UObject*>::Get(L, GetIndex));
                    ActorsToIgnore_2.Emplace(ActorsToIgnore_3863576946);
                    lua_pop(L, 1);
                }
            }
        }
        else if(ActorsToIgnore_2_Type == LUA_TNIL)
        {
            // Do nothing.
        }
        else
        {
            OutError = TEXT("Input array param must be a table or nil, name: ActorsToIgnore");
            return false;
        }
        
        auto AddZ_3 = TU4LStack<float>::Get(L, 4);
        auto MinusZ_4 = TU4LStack<float>::Get(L, 5);
        auto ReturnValue_5 = UEngineExtActorShell::GetLocationOnFloor(WorldContextObject_0, Location_1, ActorsToIgnore_2, AddZ_3, MinusZ_4);
        U4L_STACK_PUSH_STRUCT_VALUE(L, FVector, ReturnValue_5);
        OutRetCount = 1;
        return true;
    }

    static bool GetPlayerViewPoint(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto PC_0 = Cast<AController>(TU4LStack<UObject*>::Get(L, 1));
        FVector out_Location_1;
        FRotator out_Rotation_2;
        UEngineExtActorShell::GetPlayerViewPoint(PC_0, out_Location_1, out_Rotation_2);
        U4L_STACK_PUSH_STRUCT_VALUE(L, FVector, out_Location_1);
        U4L_STACK_PUSH_STRUCT_VALUE(L, FRotator, out_Rotation_2);
        OutRetCount = 2;
        return true;
    }

    static bool SetActorMaxDrawDistance(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto pActor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        auto NewCullDistance_1 = TU4LStack<float>::Get(L, 2);
        UEngineExtActorShell::SetActorMaxDrawDistance(pActor_0, NewCullDistance_1);
        OutRetCount = 0;
        return true;
    }

    static bool SetActorSkeletalMeshCastShadow(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto pActor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        auto bCastShadow_1 = TU4LStack<bool>::Get(L, 2);
        UEngineExtActorShell::SetActorSkeletalMeshCastShadow(pActor_0, bCastShadow_1);
        OutRetCount = 0;
        return true;
    }

    static bool SetActorSkeletalMeshMipMap(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto pActor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        auto bForceMipStreaming_1 = TU4LStack<bool>::Get(L, 2);
        UEngineExtActorShell::SetActorSkeletalMeshMipMap(pActor_0, bForceMipStreaming_1);
        OutRetCount = 0;
        return true;
    }

    static bool SetActorSkeletalMeshLightChannel(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto pActor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        auto Channel0_1 = TU4LStack<bool>::Get(L, 2);
        auto Channel1_2 = TU4LStack<bool>::Get(L, 3);
        auto Channel2_3 = TU4LStack<bool>::Get(L, 4);
        UEngineExtActorShell::SetActorSkeletalMeshLightChannel(pActor_0, Channel0_1, Channel1_2, Channel2_3);
        OutRetCount = 0;
        return true;
    }

    static bool FindFirstLevelScriptActor(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        auto ReturnValue_1 = UEngineExtActorShell::FindFirstLevelScriptActor(WorldContextObject_0);
        TU4LStack<UObject*>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool ConvertToActorClass(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Object_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        auto ReturnValue_1 = UEngineExtActorShell::ConvertToActorClass(Object_0);
        TU4LStack<UClass*>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool CreateActorComponent(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        auto UC_1 = Cast<UClass>(TU4LStack<UObject*>::Get(L, 2));
        auto ReturnValue_2 = UEngineExtActorShell::CreateActorComponent(Actor_0, UC_1);
        TU4LStack<UObject*>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool GetStaticMeshFromMeshComponent(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Component_0 = Cast<UStaticMeshComponent>(TU4LStack<UObject*>::Get(L, 1));
        auto ReturnValue_1 = UEngineExtActorShell::GetStaticMeshFromMeshComponent(Component_0);
        TU4LStack<UObject*>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool GetWorldRotationToTargetLocation(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        
        FVector* pTargetLocation_1 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 2, FVector, pTargetLocation_1);
        if(pTargetLocation_1 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: TargetLocation");
            return false;
        }
        auto& TargetLocation_1 = *pTargetLocation_1;
        
        auto ReturnValue_2 = UEngineExtActorShell::GetWorldRotationToTargetLocation(Actor_0, TargetLocation_1);
        U4L_STACK_PUSH_STRUCT_VALUE(L, FRotator, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool DestroyActorComponent(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        auto Component_1 = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 2));
        UEngineExtActorShell::DestroyActorComponent(Actor_0, Component_1);
        OutRetCount = 0;
        return true;
    }

    static bool DestroyActor(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        auto Actor_1 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 2));
        auto bNetForce_2 = TU4LStack<bool>::Get(L, 3);
        UEngineExtActorShell::DestroyActor(WorldContextObject_0, Actor_1, bNetForce_2);
        OutRetCount = 0;
        return true;
    }

    static bool HasActorBegunPlay(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        auto ReturnValue_1 = UEngineExtActorShell::HasActorBegunPlay(Actor_0);
        TU4LStack<bool>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool IsCanSafeTeleport(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        auto Pawn_1 = Cast<APawn>(TU4LStack<UObject*>::Get(L, 2));
        auto ReturnValue_2 = UEngineExtActorShell::IsCanSafeTeleport(WorldContextObject_0, Pawn_1);
        TU4LStack<bool>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool IsPawnLocationBlocked(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        auto Pawn_1 = Cast<APawn>(TU4LStack<UObject*>::Get(L, 2));
        auto ReturnValue_2 = UEngineExtActorShell::IsPawnLocationBlocked(WorldContextObject_0, Pawn_1);
        TU4LStack<bool>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool MovePawnToSafeLocation(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        auto Pawn_1 = Cast<APawn>(TU4LStack<UObject*>::Get(L, 2));
        auto ReturnValue_2 = UEngineExtActorShell::MovePawnToSafeLocation(WorldContextObject_0, Pawn_1);
        TU4LStack<bool>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool SetSpawnLogEnabled(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto bEnabled_0 = TU4LStack<bool>::Get(L, 1);
        UEngineExtActorShell::SetSpawnLogEnabled(bEnabled_0);
        OutRetCount = 0;
        return true;
    }

    static bool SpawnActorWithoutTransform(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        auto UC_1 = Cast<UClass>(TU4LStack<UObject*>::Get(L, 2));
        auto Instigator_2 = Cast<APawn>(TU4LStack<UObject*>::Get(L, 3));
        auto ReturnValue_3 = UEngineExtActorShell::SpawnActorWithoutTransform(WorldContextObject_0, UC_1, Instigator_2);
        TU4LStack<UObject*>::Push(L, ReturnValue_3);
        OutRetCount = 1;
        return true;
    }

    static bool SpawnActorForScript_LR(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        auto UC_1 = Cast<UClass>(TU4LStack<UObject*>::Get(L, 2));
        
        FVector* pLocation_2 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 3, FVector, pLocation_2);
        if(pLocation_2 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: Location");
            return false;
        }
        auto& Location_2 = *pLocation_2;
        
        
        FRotator* pRotation_3 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 4, FRotator, pRotation_3);
        if(pRotation_3 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: Rotation");
            return false;
        }
        auto& Rotation_3 = *pRotation_3;
        
        auto Instigator_4 = Cast<APawn>(TU4LStack<UObject*>::Get(L, 5));
        auto ReturnValue_5 = UEngineExtActorShell::SpawnActorForScript_LR(WorldContextObject_0, UC_1, Location_2, Rotation_3, Instigator_4);
        TU4LStack<UObject*>::Push(L, ReturnValue_5);
        OutRetCount = 1;
        return true;
    }

    static bool SpawnActorForScript(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        auto UC_1 = Cast<UClass>(TU4LStack<UObject*>::Get(L, 2));
        
        FTransform* pSpawnTransform_2 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 3, FTransform, pSpawnTransform_2);
        if(pSpawnTransform_2 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: SpawnTransform");
            return false;
        }
        auto& SpawnTransform_2 = *pSpawnTransform_2;
        
        auto Instigator_3 = Cast<APawn>(TU4LStack<UObject*>::Get(L, 4));
        auto ReturnValue_4 = UEngineExtActorShell::SpawnActorForScript(WorldContextObject_0, UC_1, SpawnTransform_2, Instigator_3);
        TU4LStack<UObject*>::Push(L, ReturnValue_4);
        OutRetCount = 1;
        return true;
    }

    static bool GetRotatorFromVectors(lua_State* L, int& OutRetCount, FString& OutError)
    {
        
        FVector* pVector1_0 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 1, FVector, pVector1_0);
        if(pVector1_0 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: Vector1");
            return false;
        }
        auto& Vector1_0 = *pVector1_0;
        
        
        FVector* pVector2_1 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 2, FVector, pVector2_1);
        if(pVector2_1 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: Vector2");
            return false;
        }
        auto& Vector2_1 = *pVector2_1;
        
        auto ReturnValue_2 = UEngineExtActorShell::GetRotatorFromVectors(Vector1_0, Vector2_1);
        U4L_STACK_PUSH_STRUCT_VALUE(L, FRotator, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool GetActorNetGuid(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        auto ReturnValue_1 = UEngineExtActorShell::GetActorNetGuid(Actor_0);
        TU4LStack<uint32>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool GetActorUniqueId(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        auto ReturnValue_1 = UEngineExtActorShell::GetActorUniqueId(Actor_0);
        TU4LStack<uint32>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool GetActorScale3D(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        auto ReturnValue_1 = UEngineExtActorShell::GetActorScale3D(Actor_0);
        U4L_STACK_PUSH_STRUCT_VALUE(L, FVector, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool SetActorScale3D(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        
        FVector* pScale_1 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 2, FVector, pScale_1);
        if(pScale_1 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: Scale");
            return false;
        }
        auto& Scale_1 = *pScale_1;
        
        UEngineExtActorShell::SetActorScale3D(Actor_0, Scale_1);
        OutRetCount = 0;
        return true;
    }

    static bool SetActorScale(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        auto Scale_1 = TU4LStack<float>::Get(L, 2);
        UEngineExtActorShell::SetActorScale(Actor_0, Scale_1);
        OutRetCount = 0;
        return true;
    }

    static bool GetActorRotationYawPitchRoll(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        float Yaw_1;
        float Pitch_2;
        float Roll_3;
        UEngineExtActorShell::GetActorRotationYawPitchRoll(Actor_0, Yaw_1, Pitch_2, Roll_3);
        TU4LStack<float>::Push(L, Yaw_1);
        TU4LStack<float>::Push(L, Pitch_2);
        TU4LStack<float>::Push(L, Roll_3);
        OutRetCount = 3;
        return true;
    }

    static bool GetActorRotation(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        auto ReturnValue_1 = UEngineExtActorShell::GetActorRotation(Actor_0);
        U4L_STACK_PUSH_STRUCT_VALUE(L, FRotator, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool SetActorRotationYawPitchRoll(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        auto Yaw_1 = TU4LStack<float>::Get(L, 2);
        auto Pitch_2 = TU4LStack<float>::Get(L, 3);
        auto Roll_3 = TU4LStack<float>::Get(L, 4);
        UEngineExtActorShell::SetActorRotationYawPitchRoll(Actor_0, Yaw_1, Pitch_2, Roll_3);
        OutRetCount = 0;
        return true;
    }

    static bool SetActorRotation(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        
        FRotator* pRotation_1 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 2, FRotator, pRotation_1);
        if(pRotation_1 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: Rotation");
            return false;
        }
        auto& Rotation_1 = *pRotation_1;
        
        UEngineExtActorShell::SetActorRotation(Actor_0, Rotation_1);
        OutRetCount = 0;
        return true;
    }

    static bool GetActorLocationXYZ(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        float X_1;
        float Y_2;
        float Z_3;
        UEngineExtActorShell::GetActorLocationXYZ(Actor_0, X_1, Y_2, Z_3);
        TU4LStack<float>::Push(L, X_1);
        TU4LStack<float>::Push(L, Y_2);
        TU4LStack<float>::Push(L, Z_3);
        OutRetCount = 3;
        return true;
    }

    static bool GetActorLocation(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        auto ReturnValue_1 = UEngineExtActorShell::GetActorLocation(Actor_0);
        U4L_STACK_PUSH_STRUCT_VALUE(L, FVector, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool SetActorLocationXYZ(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        auto X_1 = TU4LStack<float>::Get(L, 2);
        auto Y_2 = TU4LStack<float>::Get(L, 3);
        auto Z_3 = TU4LStack<float>::Get(L, 4);
        UEngineExtActorShell::SetActorLocationXYZ(Actor_0, X_1, Y_2, Z_3);
        OutRetCount = 0;
        return true;
    }

    static bool SetActorLocation(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 1));
        
        FVector* pPosition_1 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 2, FVector, pPosition_1);
        if(pPosition_1 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: Position");
            return false;
        }
        auto& Position_1 = *pPosition_1;
        
        UEngineExtActorShell::SetActorLocation(Actor_0, Position_1);
        OutRetCount = 0;
        return true;
    }

public:
    FU4LExportedClass0_EngineExtActorShell()
    {
        FName ClassName(TEXT("/Script/EngineExt.EngineExtActorShell"));
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ResetDrawDistanceWithCharacterValue"), &FU4LExportedClass0_EngineExtActorShell::ResetDrawDistanceWithCharacterValue);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetActorMeshTranslucency"), &FU4LExportedClass0_EngineExtActorShell::SetActorMeshTranslucency);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetLocalHostAddress"), &FU4LExportedClass0_EngineExtActorShell::GetLocalHostAddress);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetSkeletalMeshSocketTransformRTSMesh"), &FU4LExportedClass0_EngineExtActorShell::GetSkeletalMeshSocketTransformRTSMesh);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetComponentEditorOnly"), &FU4LExportedClass0_EngineExtActorShell::SetComponentEditorOnly);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetLocationZOnStaticWorld"), &FU4LExportedClass0_EngineExtActorShell::GetLocationZOnStaticWorld);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetLocationZOnFloor"), &FU4LExportedClass0_EngineExtActorShell::GetLocationZOnFloor);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetLocationOnFloor"), &FU4LExportedClass0_EngineExtActorShell::GetLocationOnFloor);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetPlayerViewPoint"), &FU4LExportedClass0_EngineExtActorShell::GetPlayerViewPoint);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetActorMaxDrawDistance"), &FU4LExportedClass0_EngineExtActorShell::SetActorMaxDrawDistance);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetActorSkeletalMeshCastShadow"), &FU4LExportedClass0_EngineExtActorShell::SetActorSkeletalMeshCastShadow);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetActorSkeletalMeshMipMap"), &FU4LExportedClass0_EngineExtActorShell::SetActorSkeletalMeshMipMap);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetActorSkeletalMeshLightChannel"), &FU4LExportedClass0_EngineExtActorShell::SetActorSkeletalMeshLightChannel);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("FindFirstLevelScriptActor"), &FU4LExportedClass0_EngineExtActorShell::FindFirstLevelScriptActor);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ConvertToActorClass"), &FU4LExportedClass0_EngineExtActorShell::ConvertToActorClass);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("CreateActorComponent"), &FU4LExportedClass0_EngineExtActorShell::CreateActorComponent);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetStaticMeshFromMeshComponent"), &FU4LExportedClass0_EngineExtActorShell::GetStaticMeshFromMeshComponent);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetWorldRotationToTargetLocation"), &FU4LExportedClass0_EngineExtActorShell::GetWorldRotationToTargetLocation);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("DestroyActorComponent"), &FU4LExportedClass0_EngineExtActorShell::DestroyActorComponent);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("DestroyActor"), &FU4LExportedClass0_EngineExtActorShell::DestroyActor);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("HasActorBegunPlay"), &FU4LExportedClass0_EngineExtActorShell::HasActorBegunPlay);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("IsCanSafeTeleport"), &FU4LExportedClass0_EngineExtActorShell::IsCanSafeTeleport);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("IsPawnLocationBlocked"), &FU4LExportedClass0_EngineExtActorShell::IsPawnLocationBlocked);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("MovePawnToSafeLocation"), &FU4LExportedClass0_EngineExtActorShell::MovePawnToSafeLocation);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetSpawnLogEnabled"), &FU4LExportedClass0_EngineExtActorShell::SetSpawnLogEnabled);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SpawnActorWithoutTransform"), &FU4LExportedClass0_EngineExtActorShell::SpawnActorWithoutTransform);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SpawnActorForScript_LR"), &FU4LExportedClass0_EngineExtActorShell::SpawnActorForScript_LR);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SpawnActorForScript"), &FU4LExportedClass0_EngineExtActorShell::SpawnActorForScript);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetRotatorFromVectors"), &FU4LExportedClass0_EngineExtActorShell::GetRotatorFromVectors);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetActorNetGuid"), &FU4LExportedClass0_EngineExtActorShell::GetActorNetGuid);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetActorUniqueId"), &FU4LExportedClass0_EngineExtActorShell::GetActorUniqueId);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetActorScale3D"), &FU4LExportedClass0_EngineExtActorShell::GetActorScale3D);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetActorScale3D"), &FU4LExportedClass0_EngineExtActorShell::SetActorScale3D);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetActorScale"), &FU4LExportedClass0_EngineExtActorShell::SetActorScale);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetActorRotationYawPitchRoll"), &FU4LExportedClass0_EngineExtActorShell::GetActorRotationYawPitchRoll);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetActorRotation"), &FU4LExportedClass0_EngineExtActorShell::GetActorRotation);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetActorRotationYawPitchRoll"), &FU4LExportedClass0_EngineExtActorShell::SetActorRotationYawPitchRoll);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetActorRotation"), &FU4LExportedClass0_EngineExtActorShell::SetActorRotation);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetActorLocationXYZ"), &FU4LExportedClass0_EngineExtActorShell::GetActorLocationXYZ);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetActorLocation"), &FU4LExportedClass0_EngineExtActorShell::GetActorLocation);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetActorLocationXYZ"), &FU4LExportedClass0_EngineExtActorShell::SetActorLocationXYZ);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetActorLocation"), &FU4LExportedClass0_EngineExtActorShell::SetActorLocation);
    }
};
static FU4LExportedClass0_EngineExtActorShell GRegister_FU4LExportedClass0_EngineExtActorShell;

///////////////////////////////////////////////////////////////////////////////////////////////////////
class FU4LExportedClass0_CommonActorShell
{
    static bool FindAvatarPartData(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonActorShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto nPartId_0 = TU4LStack<int32>::Get(L, 2);
        auto nDataIndex_1 = TU4LStack<int32>::Get(L, 3);
        auto ReturnValue_2 = __OwnerObject->FindAvatarPartData(nPartId_0, nDataIndex_1);
        TU4LStack<FString>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool UndefineAllReplicatedProperties(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonActorShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 2));
        __OwnerObject->UndefineAllReplicatedProperties(Actor_0);
        OutRetCount = 0;
        return true;
    }

    static bool MarkAllActorPropertyReplicate(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonActorShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 2));
        __OwnerObject->MarkAllActorPropertyReplicate(Actor_0);
        OutRetCount = 0;
        return true;
    }

    static bool ReplicateActorPropertyNowByType(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonActorShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 2));
        auto bMulticast_1 = TU4LStack<bool>::Get(L, 3);
        __OwnerObject->ReplicateActorPropertyNowByType(Actor_0, bMulticast_1);
        OutRetCount = 0;
        return true;
    }

    static bool ReplicateActorPropertyNow(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonActorShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 2));
        __OwnerObject->ReplicateActorPropertyNow(Actor_0);
        OutRetCount = 0;
        return true;
    }

    static bool SetReplicatedPropertyValue(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonActorShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 2));
        auto ProtoName_1 = TU4LStack<FName>::Get(L, 3);
        auto TableRef_2 = Cast<ULuaTableRef>(TU4LStack<UObject*>::Get(L, 4));
        auto ReturnValue_3 = __OwnerObject->SetReplicatedPropertyValue(Actor_0, ProtoName_1, TableRef_2);
        TU4LStack<bool>::Push(L, ReturnValue_3);
        OutRetCount = 1;
        return true;
    }

    static bool UndefineReplicatedProperty(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonActorShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 2));
        auto ProtoName_1 = TU4LStack<FName>::Get(L, 3);
        auto ReturnValue_2 = __OwnerObject->UndefineReplicatedProperty(Actor_0, ProtoName_1);
        TU4LStack<bool>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool DefineReplicatedProperty(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonActorShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 2));
        auto ProtoName_1 = TU4LStack<FName>::Get(L, 3);
        auto ReturnValue_2 = __OwnerObject->DefineReplicatedProperty(Actor_0, ProtoName_1);
        TU4LStack<bool>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool SetControllerReplicatedInitData(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonActorShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Controller_0 = Cast<AKMPlayerController>(TU4LStack<UObject*>::Get(L, 2));
        auto ProtoName_1 = TU4LStack<FString>::Get(L, 3);
        auto TableRef_2 = Cast<ULuaTableRef>(TU4LStack<UObject*>::Get(L, 4));
        auto LogicInstanceId_3 = TU4LStack<int32>::Get(L, 5);
        __OwnerObject->SetControllerReplicatedInitData(Controller_0, ProtoName_1, TableRef_2, LogicInstanceId_3);
        OutRetCount = 0;
        return true;
    }

    static bool GetActorSpawnInitData(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonActorShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 2));
        auto ReturnValue_1 = __OwnerObject->GetActorSpawnInitData(Actor_0);
        TU4LStack<UObject*>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool ResetActorSpawnInitData(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonActorShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->ResetActorSpawnInitData();
        OutRetCount = 0;
        return true;
    }

    static bool SetActorSpawnInitData(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCommonActorShell>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ProtoName_0 = TU4LStack<FString>::Get(L, 2);
        auto TableRef_1 = Cast<ULuaTableRef>(TU4LStack<UObject*>::Get(L, 3));
        auto InstanceId_2 = TU4LStack<int32>::Get(L, 4);
        auto BeginPlayManually_3 = TU4LStack<bool>::Get(L, 5);
        __OwnerObject->SetActorSpawnInitData(ProtoName_0, TableRef_1, InstanceId_2, BeginPlayManually_3);
        OutRetCount = 0;
        return true;
    }

public:
    FU4LExportedClass0_CommonActorShell()
    {
        FName ClassName(TEXT("/Script/Common.CommonActorShell"));
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("FindAvatarPartData"), &FU4LExportedClass0_CommonActorShell::FindAvatarPartData);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("UndefineAllReplicatedProperties"), &FU4LExportedClass0_CommonActorShell::UndefineAllReplicatedProperties);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("MarkAllActorPropertyReplicate"), &FU4LExportedClass0_CommonActorShell::MarkAllActorPropertyReplicate);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ReplicateActorPropertyNowByType"), &FU4LExportedClass0_CommonActorShell::ReplicateActorPropertyNowByType);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ReplicateActorPropertyNow"), &FU4LExportedClass0_CommonActorShell::ReplicateActorPropertyNow);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetReplicatedPropertyValue"), &FU4LExportedClass0_CommonActorShell::SetReplicatedPropertyValue);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("UndefineReplicatedProperty"), &FU4LExportedClass0_CommonActorShell::UndefineReplicatedProperty);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("DefineReplicatedProperty"), &FU4LExportedClass0_CommonActorShell::DefineReplicatedProperty);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetControllerReplicatedInitData"), &FU4LExportedClass0_CommonActorShell::SetControllerReplicatedInitData);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetActorSpawnInitData"), &FU4LExportedClass0_CommonActorShell::GetActorSpawnInitData);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ResetActorSpawnInitData"), &FU4LExportedClass0_CommonActorShell::ResetActorSpawnInitData);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetActorSpawnInitData"), &FU4LExportedClass0_CommonActorShell::SetActorSpawnInitData);
    }
};
static FU4LExportedClass0_CommonActorShell GRegister_FU4LExportedClass0_CommonActorShell;

///////////////////////////////////////////////////////////////////////////////////////////////////////
class FU4LExportedClass0_CommonShell
{
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
    FU4LExportedClass0_CommonShell()
    {
        FName ClassName(TEXT("/Script/Common.CommonShell"));
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("RecordSpawnActorFrameCounter"), &FU4LExportedClass0_CommonShell::RecordSpawnActorFrameCounter);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetNetLogEnabled"), &FU4LExportedClass0_CommonShell::SetNetLogEnabled);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetRemoteLuaRepository"), &FU4LExportedClass0_CommonShell::SetRemoteLuaRepository);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetWeaponInhibitManager"), &FU4LExportedClass0_CommonShell::GetWeaponInhibitManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetLogReport"), &FU4LExportedClass0_CommonShell::GetLogReport);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetLuaLib"), &FU4LExportedClass0_CommonShell::GetLuaLib);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("IsPreloadMap"), &FU4LExportedClass0_CommonShell::IsPreloadMap);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("IsGMEnabled"), &FU4LExportedClass0_CommonShell::IsGMEnabled);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("CreateNewTestObject"), &FU4LExportedClass0_CommonShell::CreateNewTestObject);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetTemplateActorDataManager"), &FU4LExportedClass0_CommonShell::SetTemplateActorDataManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetAISmokeManager"), &FU4LExportedClass0_CommonShell::GetAISmokeManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetAIOceanGridManager"), &FU4LExportedClass0_CommonShell::GetAIOceanGridManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetAIVehicleManager"), &FU4LExportedClass0_CommonShell::GetAIVehicleManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetTemplateActorDataManager"), &FU4LExportedClass0_CommonShell::GetTemplateActorDataManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetGridTypeManager"), &FU4LExportedClass0_CommonShell::GetGridTypeManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("RequestExit"), &FU4LExportedClass0_CommonShell::RequestExit);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetPiratesPlayerGrid"), &FU4LExportedClass0_CommonShell::GetPiratesPlayerGrid);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetConnectionTimeout"), &FU4LExportedClass0_CommonShell::GetConnectionTimeout);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetGameStatus"), &FU4LExportedClass0_CommonShell::GetGameStatus);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetGameStatus"), &FU4LExportedClass0_CommonShell::SetGameStatus);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetPathNodeFinder"), &FU4LExportedClass0_CommonShell::GetPathNodeFinder);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetActorTriggerGroupManager"), &FU4LExportedClass0_CommonShell::GetActorTriggerGroupManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetAIDestructibleObjectManager"), &FU4LExportedClass0_CommonShell::GetAIDestructibleObjectManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetAICoverPointsManager"), &FU4LExportedClass0_CommonShell::GetAICoverPointsManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetAreaTriggerManager"), &FU4LExportedClass0_CommonShell::GetAreaTriggerManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetCommonActorShell"), &FU4LExportedClass0_CommonShell::GetCommonActorShell);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetRPCNetworkManager"), &FU4LExportedClass0_CommonShell::GetRPCNetworkManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetShipMovementComponent"), &FU4LExportedClass0_CommonShell::GetShipMovementComponent);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetOceanNavGridManager"), &FU4LExportedClass0_CommonShell::GetOceanNavGridManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetHttpHelper"), &FU4LExportedClass0_CommonShell::GetHttpHelper);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetGameDelegateManager"), &FU4LExportedClass0_CommonShell::GetGameDelegateManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetInputManager"), &FU4LExportedClass0_CommonShell::GetInputManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetCommon"), &FU4LExportedClass0_CommonShell::GetCommon);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetNearestHitResult"), &FU4LExportedClass0_CommonShell::GetNearestHitResult);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetScreenPercentageDefault"), &FU4LExportedClass0_CommonShell::GetScreenPercentageDefault);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("FlushLog"), &FU4LExportedClass0_CommonShell::FlushLog);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetComponentDrawDistance"), &FU4LExportedClass0_CommonShell::SetComponentDrawDistance);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetSkeletalMeshComDrawDis"), &FU4LExportedClass0_CommonShell::SetSkeletalMeshComDrawDis);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("PrintErrorLog"), &FU4LExportedClass0_CommonShell::PrintErrorLog);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("PrintWarningLog"), &FU4LExportedClass0_CommonShell::PrintWarningLog);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("PrintLog"), &FU4LExportedClass0_CommonShell::PrintLog);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("StaticFindClass"), &FU4LExportedClass0_CommonShell::StaticFindClass);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("StaticFindObject"), &FU4LExportedClass0_CommonShell::StaticFindObject);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("StaticLoadObjectWithoutFlush"), &FU4LExportedClass0_CommonShell::StaticLoadObjectWithoutFlush);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("LoadFileLines"), &FU4LExportedClass0_CommonShell::LoadFileLines);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ReloadEngineConfig"), &FU4LExportedClass0_CommonShell::ReloadEngineConfig);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("LoadMultiAssetsAsyncCallbackFire"), &FU4LExportedClass0_CommonShell::LoadMultiAssetsAsyncCallbackFire);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("LoadAssetAsync"), &FU4LExportedClass0_CommonShell::LoadAssetAsync);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetWorldRealTimeSeconds"), &FU4LExportedClass0_CommonShell::GetWorldRealTimeSeconds);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetCurrentMapName"), &FU4LExportedClass0_CommonShell::GetCurrentMapName);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetKMDelegateManager"), &FU4LExportedClass0_CommonShell::GetKMDelegateManager);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GenerateObjectGuidString"), &FU4LExportedClass0_CommonShell::GenerateObjectGuidString);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("IsEditMode"), &FU4LExportedClass0_CommonShell::IsEditMode);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("IsEditor"), &FU4LExportedClass0_CommonShell::IsEditor);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("Get"), &FU4LExportedClass0_CommonShell::Get);
    }
};
static FU4LExportedClass0_CommonShell GRegister_FU4LExportedClass0_CommonShell;

///////////////////////////////////////////////////////////////////////////////////////////////////////
class FU4LExportedClass0_CustomReplicationComponent
{
    static bool SetPropertyToBeChecked(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCustomReplicationComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto PropertyId_0 = TU4LStack<int32>::Get(L, 2);
        __OwnerObject->SetPropertyToBeChecked(PropertyId_0);
        OutRetCount = 0;
        return true;
    }

    static bool PrintAllPropertySize(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCustomReplicationComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->PrintAllPropertySize();
        OutRetCount = 0;
        return true;
    }

    static bool AddRepNotifyProperties(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCustomReplicationComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        
        TArray<int32> Properties_0;
        auto Properties_0_Type = lua_type(L, 2);
        if (Properties_0_Type == LUA_TTABLE)
        {
            lua_len(L, 2);
            int ArrayLength = (int)luaL_checknumber(L, -1);
            lua_pop(L, 1);
        
            if (ArrayLength > 0)
            {
                Properties_0.Reserve(ArrayLength);
                int GetIndex = lua_gettop(L) + 1;
                for (int ArrayIndex = 0; ArrayIndex < ArrayLength; ++ArrayIndex)
                {
                    lua_rawgeti(L, 2, ArrayIndex + 1);
                    auto Properties_2087786535 = TU4LStack<int32>::Get(L, GetIndex);
                    Properties_0.Emplace(Properties_2087786535);
                    lua_pop(L, 1);
                }
            }
        }
        else if(Properties_0_Type == LUA_TNIL)
        {
            // Do nothing.
        }
        else
        {
            OutError = TEXT("Input array param must be a table or nil, name: Properties");
            return false;
        }
        
        __OwnerObject->AddRepNotifyProperties(Properties_0);
        OutRetCount = 0;
        return true;
    }

    static bool IsValidProperty(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCustomReplicationComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto PropertyId_0 = TU4LStack<int32>::Get(L, 2);
        auto ReturnValue_1 = __OwnerObject->IsValidProperty(PropertyId_0);
        TU4LStack<bool>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool GetProto(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCustomReplicationComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto PropertyId_0 = TU4LStack<int32>::Get(L, 2);
        auto MessageName_1 = TU4LStack<FString>::Get(L, 3);
        UProtobufMessageRef* Out_2;
        auto ReturnValue_3 = __OwnerObject->GetProto(PropertyId_0, MessageName_1, Out_2);
        TU4LStack<bool>::Push(L, ReturnValue_3);
        TU4LStack<UObject*>::Push(L, Out_2);
        OutRetCount = 2;
        return true;
    }

    static bool SetProto(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCustomReplicationComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto PropertyId_0 = TU4LStack<int32>::Get(L, 2);
        auto MessageName_1 = TU4LStack<FString>::Get(L, 3);
        auto TableRef_2 = Cast<ULuaTableRef>(TU4LStack<UObject*>::Get(L, 4));
        auto ReturnValue_3 = __OwnerObject->SetProto(PropertyId_0, MessageName_1, TableRef_2);
        TU4LStack<bool>::Push(L, ReturnValue_3);
        OutRetCount = 1;
        return true;
    }

    static bool GetFloat(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCustomReplicationComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto PropertyId_0 = TU4LStack<int32>::Get(L, 2);
        float Value_1;
        auto ReturnValue_2 = __OwnerObject->GetFloat(PropertyId_0, Value_1);
        TU4LStack<bool>::Push(L, ReturnValue_2);
        TU4LStack<float>::Push(L, Value_1);
        OutRetCount = 2;
        return true;
    }

    static bool SetFloat(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCustomReplicationComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto PropertyId_0 = TU4LStack<int32>::Get(L, 2);
        auto Value_1 = TU4LStack<float>::Get(L, 3);
        auto ReturnValue_2 = __OwnerObject->SetFloat(PropertyId_0, Value_1);
        TU4LStack<bool>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool GetInt(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCustomReplicationComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto PropertyId_0 = TU4LStack<int32>::Get(L, 2);
        int32 Value_1;
        auto ReturnValue_2 = __OwnerObject->GetInt(PropertyId_0, Value_1);
        TU4LStack<bool>::Push(L, ReturnValue_2);
        TU4LStack<int32>::Push(L, Value_1);
        OutRetCount = 2;
        return true;
    }

    static bool SetInt(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCustomReplicationComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto PropertyId_0 = TU4LStack<int32>::Get(L, 2);
        auto Value_1 = TU4LStack<int32>::Get(L, 3);
        auto ReturnValue_2 = __OwnerObject->SetInt(PropertyId_0, Value_1);
        TU4LStack<bool>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool GetBool(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCustomReplicationComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto PropertyId_0 = TU4LStack<int32>::Get(L, 2);
        bool Value_1;
        auto ReturnValue_2 = __OwnerObject->GetBool(PropertyId_0, Value_1);
        TU4LStack<bool>::Push(L, ReturnValue_2);
        TU4LStack<bool>::Push(L, Value_1);
        OutRetCount = 2;
        return true;
    }

    static bool SetBool(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UCustomReplicationComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto PropertyId_0 = TU4LStack<int32>::Get(L, 2);
        auto Value_1 = TU4LStack<bool>::Get(L, 3);
        auto ReturnValue_2 = __OwnerObject->SetBool(PropertyId_0, Value_1);
        TU4LStack<bool>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool ReceiveTick(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto DeltaSeconds_0 = TU4LStack<float>::Get(L, 2);
        __OwnerObject->ReceiveTick(DeltaSeconds_0);
        OutRetCount = 0;
        return true;
    }

    static bool RemoveTickPrerequisiteComponent(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto PrerequisiteComponent_0 = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 2));
        __OwnerObject->RemoveTickPrerequisiteComponent(PrerequisiteComponent_0);
        OutRetCount = 0;
        return true;
    }

    static bool RemoveTickPrerequisiteActor(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto PrerequisiteActor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 2));
        __OwnerObject->RemoveTickPrerequisiteActor(PrerequisiteActor_0);
        OutRetCount = 0;
        return true;
    }

    static bool AddTickPrerequisiteComponent(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto PrerequisiteComponent_0 = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 2));
        __OwnerObject->AddTickPrerequisiteComponent(PrerequisiteComponent_0);
        OutRetCount = 0;
        return true;
    }

    static bool AddTickPrerequisiteActor(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto PrerequisiteActor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 2));
        __OwnerObject->AddTickPrerequisiteActor(PrerequisiteActor_0);
        OutRetCount = 0;
        return true;
    }

    static bool SetTickGroup(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto NewTickGroup_0 = (ETickingGroup)TU4LStack<UEnum*>::Get(L, 2);
        __OwnerObject->SetTickGroup(NewTickGroup_0);
        OutRetCount = 0;
        return true;
    }

    static bool K2_DestroyComponent(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Object_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 2));
        __OwnerObject->K2_DestroyComponent(Object_0);
        OutRetCount = 0;
        return true;
    }

    static bool GetComponentTickInterval(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetComponentTickInterval();
        TU4LStack<float>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool SetComponentTickInterval(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto TickInterval_0 = TU4LStack<float>::Get(L, 2);
        __OwnerObject->SetComponentTickInterval(TickInterval_0);
        OutRetCount = 0;
        return true;
    }

    static bool IsComponentTickEnabled(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->IsComponentTickEnabled();
        TU4LStack<bool>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool SetComponentTickEnabled(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto bEnabled_0 = TU4LStack<bool>::Get(L, 2);
        __OwnerObject->SetComponentTickEnabled(bEnabled_0);
        OutRetCount = 0;
        return true;
    }

    static bool ReceiveEndPlay(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto EndPlayReason_0 = (EEndPlayReason::Type)TU4LStack<UEnum*>::Get(L, 2);
        __OwnerObject->ReceiveEndPlay(EndPlayReason_0);
        OutRetCount = 0;
        return true;
    }

    static bool ReceiveBeginPlay(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->ReceiveBeginPlay();
        OutRetCount = 0;
        return true;
    }

    static bool SetIsReplicated(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ShouldReplicate_0 = TU4LStack<bool>::Get(L, 2);
        __OwnerObject->SetIsReplicated(ShouldReplicate_0);
        OutRetCount = 0;
        return true;
    }

    static bool SetTickableWhenPaused(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto bTickableWhenPaused_0 = TU4LStack<bool>::Get(L, 2);
        __OwnerObject->SetTickableWhenPaused(bTickableWhenPaused_0);
        OutRetCount = 0;
        return true;
    }

    static bool SetAutoActivate(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto bNewAutoActivate_0 = TU4LStack<bool>::Get(L, 2);
        __OwnerObject->SetAutoActivate(bNewAutoActivate_0);
        OutRetCount = 0;
        return true;
    }

    static bool IsActive(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->IsActive();
        TU4LStack<bool>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool ToggleActive(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->ToggleActive();
        OutRetCount = 0;
        return true;
    }

    static bool SetActive(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto bNewActive_0 = TU4LStack<bool>::Get(L, 2);
        auto bReset_1 = TU4LStack<bool>::Get(L, 3);
        __OwnerObject->SetActive(bNewActive_0, bReset_1);
        OutRetCount = 0;
        return true;
    }

    static bool Deactivate(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->Deactivate();
        OutRetCount = 0;
        return true;
    }

    static bool Activate(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto bReset_0 = TU4LStack<bool>::Get(L, 2);
        __OwnerObject->Activate(bReset_0);
        OutRetCount = 0;
        return true;
    }

    static bool ComponentHasTag(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Tag_0 = TU4LStack<FName>::Get(L, 2);
        auto ReturnValue_1 = __OwnerObject->ComponentHasTag(Tag_0);
        TU4LStack<bool>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool GetOwner(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetOwner();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool OnRep_IsActive(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->OnRep_IsActive();
        OutRetCount = 0;
        return true;
    }

    static bool IsBeingDestroyed(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UActorComponent>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->IsBeingDestroyed();
        TU4LStack<bool>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

public:
    FU4LExportedClass0_CustomReplicationComponent()
    {
        FName ClassName(TEXT("/Script/Common.CustomReplicationComponent"));
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetPropertyToBeChecked"), &FU4LExportedClass0_CustomReplicationComponent::SetPropertyToBeChecked);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("PrintAllPropertySize"), &FU4LExportedClass0_CustomReplicationComponent::PrintAllPropertySize);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("AddRepNotifyProperties"), &FU4LExportedClass0_CustomReplicationComponent::AddRepNotifyProperties);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("IsValidProperty"), &FU4LExportedClass0_CustomReplicationComponent::IsValidProperty);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetProto"), &FU4LExportedClass0_CustomReplicationComponent::GetProto);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetProto"), &FU4LExportedClass0_CustomReplicationComponent::SetProto);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetFloat"), &FU4LExportedClass0_CustomReplicationComponent::GetFloat);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetFloat"), &FU4LExportedClass0_CustomReplicationComponent::SetFloat);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetInt"), &FU4LExportedClass0_CustomReplicationComponent::GetInt);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetInt"), &FU4LExportedClass0_CustomReplicationComponent::SetInt);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetBool"), &FU4LExportedClass0_CustomReplicationComponent::GetBool);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetBool"), &FU4LExportedClass0_CustomReplicationComponent::SetBool);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ReceiveTick"), &FU4LExportedClass0_CustomReplicationComponent::ReceiveTick);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("RemoveTickPrerequisiteComponent"), &FU4LExportedClass0_CustomReplicationComponent::RemoveTickPrerequisiteComponent);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("RemoveTickPrerequisiteActor"), &FU4LExportedClass0_CustomReplicationComponent::RemoveTickPrerequisiteActor);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("AddTickPrerequisiteComponent"), &FU4LExportedClass0_CustomReplicationComponent::AddTickPrerequisiteComponent);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("AddTickPrerequisiteActor"), &FU4LExportedClass0_CustomReplicationComponent::AddTickPrerequisiteActor);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetTickGroup"), &FU4LExportedClass0_CustomReplicationComponent::SetTickGroup);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("K2_DestroyComponent"), &FU4LExportedClass0_CustomReplicationComponent::K2_DestroyComponent);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetComponentTickInterval"), &FU4LExportedClass0_CustomReplicationComponent::GetComponentTickInterval);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetComponentTickInterval"), &FU4LExportedClass0_CustomReplicationComponent::SetComponentTickInterval);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("IsComponentTickEnabled"), &FU4LExportedClass0_CustomReplicationComponent::IsComponentTickEnabled);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetComponentTickEnabled"), &FU4LExportedClass0_CustomReplicationComponent::SetComponentTickEnabled);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ReceiveEndPlay"), &FU4LExportedClass0_CustomReplicationComponent::ReceiveEndPlay);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ReceiveBeginPlay"), &FU4LExportedClass0_CustomReplicationComponent::ReceiveBeginPlay);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetIsReplicated"), &FU4LExportedClass0_CustomReplicationComponent::SetIsReplicated);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetTickableWhenPaused"), &FU4LExportedClass0_CustomReplicationComponent::SetTickableWhenPaused);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetAutoActivate"), &FU4LExportedClass0_CustomReplicationComponent::SetAutoActivate);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("IsActive"), &FU4LExportedClass0_CustomReplicationComponent::IsActive);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ToggleActive"), &FU4LExportedClass0_CustomReplicationComponent::ToggleActive);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetActive"), &FU4LExportedClass0_CustomReplicationComponent::SetActive);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("Deactivate"), &FU4LExportedClass0_CustomReplicationComponent::Deactivate);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("Activate"), &FU4LExportedClass0_CustomReplicationComponent::Activate);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ComponentHasTag"), &FU4LExportedClass0_CustomReplicationComponent::ComponentHasTag);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetOwner"), &FU4LExportedClass0_CustomReplicationComponent::GetOwner);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("OnRep_IsActive"), &FU4LExportedClass0_CustomReplicationComponent::OnRep_IsActive);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("IsBeingDestroyed"), &FU4LExportedClass0_CustomReplicationComponent::IsBeingDestroyed);
    }
};
static FU4LExportedClass0_CustomReplicationComponent GRegister_FU4LExportedClass0_CustomReplicationComponent;

///////////////////////////////////////////////////////////////////////////////////////////////////////
class FU4LExportedClass0_ExtendBlueprintFunctions
{
    static bool CheckAttackIllegal(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto WorldContextObject_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        
        FVector* pStartPos_1 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 2, FVector, pStartPos_1);
        if(pStartPos_1 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: StartPos");
            return false;
        }
        auto& StartPos_1 = *pStartPos_1;
        
        
        FVector* pCameraPos_2 = nullptr;
        U4L_STACK_GET_STRUCT_VALUE(L, 3, FVector, pCameraPos_2);
        if(pCameraPos_2 == nullptr)
        {
            OutError = TEXT("Invalid input struct param, name: CameraPos");
            return false;
        }
        auto& CameraPos_2 = *pCameraPos_2;
        
        auto ReturnValue_3 = UExtendBlueprintFunctions::CheckAttackIllegal(WorldContextObject_0, StartPos_1, CameraPos_2);
        TU4LStack<int32>::Push(L, ReturnValue_3);
        OutRetCount = 1;
        return true;
    }

    static bool GetPlatformMilliseconds(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto ReturnValue_0 = UExtendBlueprintFunctions::GetPlatformMilliseconds();
        TU4LStack<float>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetObjectUniqueID(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Object_0 = Cast<UObject>(TU4LStack<UObject*>::Get(L, 1));
        auto ReturnValue_1 = UExtendBlueprintFunctions::GetObjectUniqueID(Object_0);
        TU4LStack<int32>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool FormatTextByName(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Fmt_0 = TU4LStack<FText>::Get(L, 1);
        
        TArray<FString> Names_1;
        auto Names_1_Type = lua_type(L, 2);
        if (Names_1_Type == LUA_TTABLE)
        {
            lua_len(L, 2);
            int ArrayLength = (int)luaL_checknumber(L, -1);
            lua_pop(L, 1);
        
            if (ArrayLength > 0)
            {
                Names_1.Reserve(ArrayLength);
                int GetIndex = lua_gettop(L) + 1;
                for (int ArrayIndex = 0; ArrayIndex < ArrayLength; ++ArrayIndex)
                {
                    lua_rawgeti(L, 2, ArrayIndex + 1);
                    auto Names_3816857761 = TU4LStack<FString>::Get(L, GetIndex);
                    Names_1.Emplace(Names_3816857761);
                    lua_pop(L, 1);
                }
            }
        }
        else if(Names_1_Type == LUA_TNIL)
        {
            // Do nothing.
        }
        else
        {
            OutError = TEXT("Input array param must be a table or nil, name: Names");
            return false;
        }
        
        
        TArray<FText> Args_2;
        auto Args_2_Type = lua_type(L, 3);
        if (Args_2_Type == LUA_TTABLE)
        {
            lua_len(L, 3);
            int ArrayLength = (int)luaL_checknumber(L, -1);
            lua_pop(L, 1);
        
            if (ArrayLength > 0)
            {
                Args_2.Reserve(ArrayLength);
                int GetIndex = lua_gettop(L) + 1;
                for (int ArrayIndex = 0; ArrayIndex < ArrayLength; ++ArrayIndex)
                {
                    lua_rawgeti(L, 3, ArrayIndex + 1);
                    auto Args_125343109 = TU4LStack<FText>::Get(L, GetIndex);
                    Args_2.Emplace(Args_125343109);
                    lua_pop(L, 1);
                }
            }
        }
        else if(Args_2_Type == LUA_TNIL)
        {
            // Do nothing.
        }
        else
        {
            OutError = TEXT("Input array param must be a table or nil, name: Args");
            return false;
        }
        
        auto ReturnValue_3 = UExtendBlueprintFunctions::FormatTextByName(Fmt_0, Names_1, Args_2);
        TU4LStack<FText>::Push(L, ReturnValue_3);
        OutRetCount = 1;
        return true;
    }

    static bool FormatText(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto Fmt_0 = TU4LStack<FText>::Get(L, 1);
        
        TArray<FText> Args_1;
        auto Args_1_Type = lua_type(L, 2);
        if (Args_1_Type == LUA_TTABLE)
        {
            lua_len(L, 2);
            int ArrayLength = (int)luaL_checknumber(L, -1);
            lua_pop(L, 1);
        
            if (ArrayLength > 0)
            {
                Args_1.Reserve(ArrayLength);
                int GetIndex = lua_gettop(L) + 1;
                for (int ArrayIndex = 0; ArrayIndex < ArrayLength; ++ArrayIndex)
                {
                    lua_rawgeti(L, 2, ArrayIndex + 1);
                    auto Args_125343109 = TU4LStack<FText>::Get(L, GetIndex);
                    Args_1.Emplace(Args_125343109);
                    lua_pop(L, 1);
                }
            }
        }
        else if(Args_1_Type == LUA_TNIL)
        {
            // Do nothing.
        }
        else
        {
            OutError = TEXT("Input array param must be a table or nil, name: Args");
            return false;
        }
        
        auto ReturnValue_2 = UExtendBlueprintFunctions::FormatText(Fmt_0, Args_1);
        TU4LStack<FText>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

public:
    FU4LExportedClass0_ExtendBlueprintFunctions()
    {
        FName ClassName(TEXT("/Script/Common.ExtendBlueprintFunctions"));
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("CheckAttackIllegal"), &FU4LExportedClass0_ExtendBlueprintFunctions::CheckAttackIllegal);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetPlatformMilliseconds"), &FU4LExportedClass0_ExtendBlueprintFunctions::GetPlatformMilliseconds);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetObjectUniqueID"), &FU4LExportedClass0_ExtendBlueprintFunctions::GetObjectUniqueID);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("FormatTextByName"), &FU4LExportedClass0_ExtendBlueprintFunctions::FormatTextByName);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("FormatText"), &FU4LExportedClass0_ExtendBlueprintFunctions::FormatText);
    }
};
static FU4LExportedClass0_ExtendBlueprintFunctions GRegister_FU4LExportedClass0_ExtendBlueprintFunctions;

///////////////////////////////////////////////////////////////////////////////////////////////////////
class FU4LExportedClass0_PiratesGridTypeManager
{
    static bool SetUpdateInterval(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UPiratesGridTypeManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Interval_0 = TU4LStack<float>::Get(L, 2);
        __OwnerObject->SetUpdateInterval(Interval_0);
        OutRetCount = 0;
        return true;
    }

    static bool RemoveActor(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UPiratesGridTypeManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 2));
        __OwnerObject->RemoveActor(Actor_0);
        OutRetCount = 0;
        return true;
    }

    static bool AddActor(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UPiratesGridTypeManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Actor_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 2));
        __OwnerObject->AddActor(Actor_0);
        OutRetCount = 0;
        return true;
    }

    static bool GetMarkPositions(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UPiratesGridTypeManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto LandID_0 = TU4LStack<uint8>::Get(L, 2);
        auto RegionType_1 = (EPiratesGridRegionType)TU4LStack<UEnum*>::Get(L, 3);
        TArray<FVector2D> PosList_2;
        auto ReturnValue_3 = __OwnerObject->GetMarkPositions(LandID_0, RegionType_1, PosList_2);
        TU4LStack<bool>::Push(L, ReturnValue_3);
        
        lua_newtable(L);
        int ArrayLength = PosList_2.Num();
        if(ArrayLength > 0)
        {
            for (int ArrayIndex = 0; ArrayIndex < ArrayLength; ++ArrayIndex)
            {
                U4L_STACK_PUSH_STRUCT_VALUE(L, FVector2D, PosList_2[ArrayIndex]);
                lua_rawseti(L, -2, ArrayIndex + 1);
            }
        }
        
        OutRetCount = 2;
        return true;
    }

    static bool GetRandomPosition(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UPiratesGridTypeManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto LandProb_0 = TU4LStack<float>::Get(L, 2);
        auto LandIDEqual_1 = TU4LStack<bool>::Get(L, 3);
        auto ReturnValue_2 = __OwnerObject->GetRandomPosition(LandProb_0, LandIDEqual_1);
        U4L_STACK_PUSH_STRUCT_VALUE(L, FVector2D, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool GetClosestPositionOfRegionType(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UPiratesGridTypeManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto PosX_0 = TU4LStack<float>::Get(L, 2);
        auto PosY_1 = TU4LStack<float>::Get(L, 3);
        auto RegionType_2 = (EPiratesGridRegionType)TU4LStack<UEnum*>::Get(L, 4);
        FVector2D OutLocation_3;
        auto ReturnValue_4 = __OwnerObject->GetClosestPositionOfRegionType(PosX_0, PosY_1, RegionType_2, OutLocation_3);
        TU4LStack<bool>::Push(L, ReturnValue_4);
        U4L_STACK_PUSH_STRUCT_VALUE(L, FVector2D, OutLocation_3);
        OutRetCount = 2;
        return true;
    }

    static bool GetRegionName(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UPiratesGridTypeManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto PosX_0 = TU4LStack<float>::Get(L, 2);
        auto PosY_1 = TU4LStack<float>::Get(L, 3);
        auto ReturnValue_2 = __OwnerObject->GetRegionName(PosX_0, PosY_1);
        TU4LStack<FString>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool GetLandID(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UPiratesGridTypeManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto PosX_0 = TU4LStack<float>::Get(L, 2);
        auto PosY_1 = TU4LStack<float>::Get(L, 3);
        auto ReturnValue_2 = __OwnerObject->GetLandID(PosX_0, PosY_1);
        TU4LStack<uint8>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool GetRegionType(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UPiratesGridTypeManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto PosX_0 = TU4LStack<float>::Get(L, 2);
        auto PosY_1 = TU4LStack<float>::Get(L, 3);
        auto ReturnValue_2 = __OwnerObject->GetRegionType(PosX_0, PosY_1);
        TU4LStack<UEnum*>::Push(L, TEXT("EPiratesGridRegionType"), (int)ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

public:
    FU4LExportedClass0_PiratesGridTypeManager()
    {
        FName ClassName(TEXT("/Script/Common.PiratesGridTypeManager"));
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetUpdateInterval"), &FU4LExportedClass0_PiratesGridTypeManager::SetUpdateInterval);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("RemoveActor"), &FU4LExportedClass0_PiratesGridTypeManager::RemoveActor);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("AddActor"), &FU4LExportedClass0_PiratesGridTypeManager::AddActor);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetMarkPositions"), &FU4LExportedClass0_PiratesGridTypeManager::GetMarkPositions);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetRandomPosition"), &FU4LExportedClass0_PiratesGridTypeManager::GetRandomPosition);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetClosestPositionOfRegionType"), &FU4LExportedClass0_PiratesGridTypeManager::GetClosestPositionOfRegionType);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetRegionName"), &FU4LExportedClass0_PiratesGridTypeManager::GetRegionName);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetLandID"), &FU4LExportedClass0_PiratesGridTypeManager::GetLandID);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetRegionType"), &FU4LExportedClass0_PiratesGridTypeManager::GetRegionType);
    }
};
static FU4LExportedClass0_PiratesGridTypeManager GRegister_FU4LExportedClass0_PiratesGridTypeManager;

///////////////////////////////////////////////////////////////////////////////////////////////////////
class FU4LExportedClass0_RPCNetworkManager
{
    static bool ClearPendingPackets(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<URPCNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->ClearPendingPackets();
        OutRetCount = 0;
        return true;
    }

    static bool SetActorAsyncCreatingEnabled(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<URPCNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Enabled_0 = TU4LStack<bool>::Get(L, 2);
        __OwnerObject->SetActorAsyncCreatingEnabled(Enabled_0);
        OutRetCount = 0;
        return true;
    }

    static bool SetPacketEncryptionEnabled(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<URPCNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Enabled_0 = TU4LStack<bool>::Get(L, 2);
        auto Seed_1 = TU4LStack<int32>::Get(L, 3);
        __OwnerObject->SetPacketEncryptionEnabled(Enabled_0, Seed_1);
        OutRetCount = 0;
        return true;
    }

    static bool SetLimitPacketProcessingEnabled(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<URPCNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Enable_0 = TU4LStack<bool>::Get(L, 2);
        __OwnerObject->SetLimitPacketProcessingEnabled(Enable_0);
        OutRetCount = 0;
        return true;
    }

    static bool SetQueueProcessFactor(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<URPCNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Factor_0 = TU4LStack<float>::Get(L, 2);
        __OwnerObject->SetQueueProcessFactor(Factor_0);
        OutRetCount = 0;
        return true;
    }

    static bool SetMaxTimeForPacketProcessing(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<URPCNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Time_0 = TU4LStack<float>::Get(L, 2);
        __OwnerObject->SetMaxTimeForPacketProcessing(Time_0);
        OutRetCount = 0;
        return true;
    }

    static bool GetCustomReplicationDefineInfoCRC(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<URPCNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Name_0 = TU4LStack<FName>::Get(L, 2);
        auto ReturnValue_1 = __OwnerObject->GetCustomReplicationDefineInfoCRC(Name_0);
        TU4LStack<int32>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool ClearCustomReplicationDefineInfo(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<URPCNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        __OwnerObject->ClearCustomReplicationDefineInfo();
        OutRetCount = 0;
        return true;
    }

    static bool AddCustomReplicationDefineInfo(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<URPCNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Name_0 = TU4LStack<FName>::Get(L, 2);
        
        TArray<FCustomReplicationPropertyDefine> Defines_1;
        auto Defines_1_Type = lua_type(L, 3);
        if (Defines_1_Type == LUA_TTABLE)
        {
            lua_len(L, 3);
            int ArrayLength = (int)luaL_checknumber(L, -1);
            lua_pop(L, 1);
        
            if (ArrayLength > 0)
            {
                Defines_1.Reserve(ArrayLength);
                int GetIndex = lua_gettop(L) + 1;
                for (int ArrayIndex = 0; ArrayIndex < ArrayLength; ++ArrayIndex)
                {
                    lua_rawgeti(L, 3, ArrayIndex + 1);
                    
                    FCustomReplicationPropertyDefine* pDefines_3020868416 = nullptr;
                    U4L_STACK_GET_STRUCT_VALUE(L, GetIndex, FCustomReplicationPropertyDefine, pDefines_3020868416);
                    if(pDefines_3020868416 == nullptr)
                    {
                        OutError = TEXT("Invalid input struct param, name: Defines");
                        return false;
                    }
                    auto& Defines_3020868416 = *pDefines_3020868416;
                    
                    Defines_1.Emplace(Defines_3020868416);
                    lua_pop(L, 1);
                }
            }
        }
        else if(Defines_1_Type == LUA_TNIL)
        {
            // Do nothing.
        }
        else
        {
            OutError = TEXT("Input array param must be a table or nil, name: Defines");
            return false;
        }
        
        __OwnerObject->AddCustomReplicationDefineInfo(Name_0, Defines_1);
        OutRetCount = 0;
        return true;
    }

    static bool GetRPCComponent(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<URPCNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Sender_0 = Cast<AActor>(TU4LStack<UObject*>::Get(L, 2));
        auto ReturnValue_1 = __OwnerObject->GetRPCComponent(Sender_0);
        TU4LStack<UObject*>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool GetMulticastRPCComponent(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<URPCNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetMulticastRPCComponent();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool GetServerRPCComponent(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<URPCNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto SenderUniqueId_0 = TU4LStack<uint32>::Get(L, 2);
        auto ReturnValue_1 = __OwnerObject->GetServerRPCComponent(SenderUniqueId_0);
        TU4LStack<UObject*>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool GetClientRPCComponent(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<URPCNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto ReturnValue_0 = __OwnerObject->GetClientRPCComponent();
        TU4LStack<UObject*>::Push(L, ReturnValue_0);
        OutRetCount = 1;
        return true;
    }

    static bool Multicast(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<URPCNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto MessageType_0 = TU4LStack<FString>::Get(L, 2);
        auto MessageBodyTableRef_1 = Cast<ULuaTableRef>(TU4LStack<UObject*>::Get(L, 3));
        auto bSendToServer_2 = TU4LStack<bool>::Get(L, 4);
        auto ReturnValue_3 = __OwnerObject->Multicast(MessageType_0, MessageBodyTableRef_1, bSendToServer_2);
        TU4LStack<bool>::Push(L, ReturnValue_3);
        OutRetCount = 1;
        return true;
    }

    static bool SendToClient(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<URPCNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto SenderUniqueId_0 = TU4LStack<uint32>::Get(L, 2);
        auto MessageType_1 = TU4LStack<FString>::Get(L, 3);
        auto MessageBodyTableRef_2 = Cast<ULuaTableRef>(TU4LStack<UObject*>::Get(L, 4));
        auto ReturnValue_3 = __OwnerObject->SendToClient(SenderUniqueId_0, MessageType_1, MessageBodyTableRef_2);
        TU4LStack<bool>::Push(L, ReturnValue_3);
        OutRetCount = 1;
        return true;
    }

    static bool SendToServer(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<URPCNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto MessageType_0 = TU4LStack<FString>::Get(L, 2);
        auto MessageBodyTableRef_1 = Cast<ULuaTableRef>(TU4LStack<UObject*>::Get(L, 3));
        auto ReturnValue_2 = __OwnerObject->SendToServer(MessageType_0, MessageBodyTableRef_1);
        TU4LStack<bool>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool SetProtoIds(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UNetworkManagerBase>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        
        TMap<uint16,FString> Ids_0;
        auto Ids_0_Type = lua_type(L, 2);
        if (Ids_0_Type == LUA_TTABLE)
        {
            lua_pushnil(L);
            while (lua_next(L, 2))
            {
                auto Ids_Key_3104592983 = TU4LStack<uint16>::Get(L, -2);
                auto Ids_4214549053 = TU4LStack<FString>::Get(L, -1);
                Ids_0.Emplace(Ids_Key_3104592983, Ids_4214549053);
                lua_pop(L, 1);
            }
        }
        else if (Ids_0_Type == LUA_TNIL)
        {
            // Do nothing.
        }
        else
        {
            OutError = TEXT("Input map param must be a table or nil, name: Ids");
            return false;
        }
        
        __OwnerObject->SetProtoIds(Ids_0);
        OutRetCount = 0;
        return true;
    }

    static bool SetIgnoreMessageLog(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UNetworkManagerBase>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        
        TArray<FName> Names_0;
        auto Names_0_Type = lua_type(L, 2);
        if (Names_0_Type == LUA_TTABLE)
        {
            lua_len(L, 2);
            int ArrayLength = (int)luaL_checknumber(L, -1);
            lua_pop(L, 1);
        
            if (ArrayLength > 0)
            {
                Names_0.Reserve(ArrayLength);
                int GetIndex = lua_gettop(L) + 1;
                for (int ArrayIndex = 0; ArrayIndex < ArrayLength; ++ArrayIndex)
                {
                    lua_rawgeti(L, 2, ArrayIndex + 1);
                    auto Names_3816857761 = TU4LStack<FName>::Get(L, GetIndex);
                    Names_0.Emplace(Names_3816857761);
                    lua_pop(L, 1);
                }
            }
        }
        else if(Names_0_Type == LUA_TNIL)
        {
            // Do nothing.
        }
        else
        {
            OutError = TEXT("Input array param must be a table or nil, name: Names");
            return false;
        }
        
        __OwnerObject->SetIgnoreMessageLog(Names_0);
        OutRetCount = 0;
        return true;
    }

    static bool SetEnableLog(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UNetworkManagerBase>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Enable_0 = TU4LStack<bool>::Get(L, 2);
        __OwnerObject->SetEnableLog(Enable_0);
        OutRetCount = 0;
        return true;
    }

    static bool ConvertIPToString(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UNetworkManagerBase>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto IPv4_0 = TU4LStack<uint32>::Get(L, 2);
        auto ReturnValue_1 = __OwnerObject->ConvertIPToString(IPv4_0);
        TU4LStack<FString>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool SetProtoFile(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UNetworkManagerBase>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto FileName_0 = TU4LStack<FString>::Get(L, 2);
        __OwnerObject->SetProtoFile(FileName_0);
        OutRetCount = 0;
        return true;
    }

public:
    FU4LExportedClass0_RPCNetworkManager()
    {
        FName ClassName(TEXT("/Script/Common.RPCNetworkManager"));
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ClearPendingPackets"), &FU4LExportedClass0_RPCNetworkManager::ClearPendingPackets);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetActorAsyncCreatingEnabled"), &FU4LExportedClass0_RPCNetworkManager::SetActorAsyncCreatingEnabled);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetPacketEncryptionEnabled"), &FU4LExportedClass0_RPCNetworkManager::SetPacketEncryptionEnabled);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetLimitPacketProcessingEnabled"), &FU4LExportedClass0_RPCNetworkManager::SetLimitPacketProcessingEnabled);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetQueueProcessFactor"), &FU4LExportedClass0_RPCNetworkManager::SetQueueProcessFactor);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetMaxTimeForPacketProcessing"), &FU4LExportedClass0_RPCNetworkManager::SetMaxTimeForPacketProcessing);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetCustomReplicationDefineInfoCRC"), &FU4LExportedClass0_RPCNetworkManager::GetCustomReplicationDefineInfoCRC);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ClearCustomReplicationDefineInfo"), &FU4LExportedClass0_RPCNetworkManager::ClearCustomReplicationDefineInfo);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("AddCustomReplicationDefineInfo"), &FU4LExportedClass0_RPCNetworkManager::AddCustomReplicationDefineInfo);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetRPCComponent"), &FU4LExportedClass0_RPCNetworkManager::GetRPCComponent);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetMulticastRPCComponent"), &FU4LExportedClass0_RPCNetworkManager::GetMulticastRPCComponent);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetServerRPCComponent"), &FU4LExportedClass0_RPCNetworkManager::GetServerRPCComponent);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("GetClientRPCComponent"), &FU4LExportedClass0_RPCNetworkManager::GetClientRPCComponent);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("Multicast"), &FU4LExportedClass0_RPCNetworkManager::Multicast);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SendToClient"), &FU4LExportedClass0_RPCNetworkManager::SendToClient);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SendToServer"), &FU4LExportedClass0_RPCNetworkManager::SendToServer);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetProtoIds"), &FU4LExportedClass0_RPCNetworkManager::SetProtoIds);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetIgnoreMessageLog"), &FU4LExportedClass0_RPCNetworkManager::SetIgnoreMessageLog);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetEnableLog"), &FU4LExportedClass0_RPCNetworkManager::SetEnableLog);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ConvertIPToString"), &FU4LExportedClass0_RPCNetworkManager::ConvertIPToString);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetProtoFile"), &FU4LExportedClass0_RPCNetworkManager::SetProtoFile);
    }
};
static FU4LExportedClass0_RPCNetworkManager GRegister_FU4LExportedClass0_RPCNetworkManager;

///////////////////////////////////////////////////////////////////////////////////////////////////////
class FU4LExportedClass0_SocketNetworkManager
{
    static bool SetIdleTime(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<USocketNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto InWaitIdleTime_0 = TU4LStack<float>::Get(L, 2);
        auto InReadIdleTime_1 = TU4LStack<float>::Get(L, 3);
        __OwnerObject->SetIdleTime(InWaitIdleTime_0, InReadIdleTime_1);
        OutRetCount = 0;
        return true;
    }

    static bool Base64StringToMessage(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<USocketNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto MessageType_0 = TU4LStack<FString>::Get(L, 2);
        auto Content_1 = TU4LStack<FString>::Get(L, 3);
        UProtobufMessageRef* OutMessageRef_2;
        auto ReturnValue_3 = __OwnerObject->Base64StringToMessage(MessageType_0, Content_1, OutMessageRef_2);
        TU4LStack<bool>::Push(L, ReturnValue_3);
        TU4LStack<UObject*>::Push(L, OutMessageRef_2);
        OutRetCount = 2;
        return true;
    }

    static bool MessageToBase64String(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<USocketNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto MessageType_0 = TU4LStack<FString>::Get(L, 2);
        auto TableRef_1 = Cast<ULuaTableRef>(TU4LStack<UObject*>::Get(L, 3));
        auto ReturnValue_2 = __OwnerObject->MessageToBase64String(MessageType_0, TableRef_1);
        TU4LStack<FString>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool SetIgnoreSpecificError(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<USocketNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Ignore_0 = TU4LStack<bool>::Get(L, 2);
        __OwnerObject->SetIgnoreSpecificError(Ignore_0);
        OutRetCount = 0;
        return true;
    }

    static bool SetPending(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<USocketNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto bPending_0 = TU4LStack<bool>::Get(L, 2);
        __OwnerObject->SetPending(bPending_0);
        OutRetCount = 0;
        return true;
    }

    static bool SendPacketByTable(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<USocketNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto InSocketID_0 = TU4LStack<int32>::Get(L, 2);
        auto MessageType_1 = TU4LStack<FString>::Get(L, 3);
        auto TableRef_2 = Cast<ULuaTableRef>(TU4LStack<UObject*>::Get(L, 4));
        auto ReturnValue_3 = __OwnerObject->SendPacketByTable(InSocketID_0, MessageType_1, TableRef_2);
        TU4LStack<bool>::Push(L, ReturnValue_3);
        OutRetCount = 1;
        return true;
    }

    static bool IsConnected(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<USocketNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto InSocketID_0 = TU4LStack<int32>::Get(L, 2);
        auto ReturnValue_1 = __OwnerObject->IsConnected(InSocketID_0);
        TU4LStack<bool>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool Disconnect(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<USocketNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto InSocketID_0 = TU4LStack<int32>::Get(L, 2);
        __OwnerObject->Disconnect(InSocketID_0);
        OutRetCount = 0;
        return true;
    }

    static bool ConnectIPWithOpenSSL(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<USocketNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto InSocketID_0 = TU4LStack<int32>::Get(L, 2);
        auto Endpoint_1 = TU4LStack<FString>::Get(L, 3);
        auto DomainName_2 = TU4LStack<FString>::Get(L, 4);
        auto ReturnValue_3 = __OwnerObject->ConnectIPWithOpenSSL(InSocketID_0, Endpoint_1, DomainName_2);
        TU4LStack<bool>::Push(L, ReturnValue_3);
        OutRetCount = 1;
        return true;
    }

    static bool ConnectWithDomainName(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<USocketNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto InSocketID_0 = TU4LStack<int32>::Get(L, 2);
        auto DomainName_1 = TU4LStack<FString>::Get(L, 3);
        auto Port_2 = TU4LStack<uint32>::Get(L, 4);
        auto UseOpenSSL_3 = TU4LStack<bool>::Get(L, 5);
        auto ReturnValue_4 = __OwnerObject->ConnectWithDomainName(InSocketID_0, DomainName_1, Port_2, UseOpenSSL_3);
        TU4LStack<bool>::Push(L, ReturnValue_4);
        OutRetCount = 1;
        return true;
    }

    static bool Connect(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<USocketNetworkManager>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto InSocketID_0 = TU4LStack<int32>::Get(L, 2);
        auto Endpoint_1 = TU4LStack<FString>::Get(L, 3);
        auto ReturnValue_2 = __OwnerObject->Connect(InSocketID_0, Endpoint_1);
        TU4LStack<bool>::Push(L, ReturnValue_2);
        OutRetCount = 1;
        return true;
    }

    static bool SetProtoIds(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UNetworkManagerBase>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        
        TMap<uint16,FString> Ids_0;
        auto Ids_0_Type = lua_type(L, 2);
        if (Ids_0_Type == LUA_TTABLE)
        {
            lua_pushnil(L);
            while (lua_next(L, 2))
            {
                auto Ids_Key_3104592983 = TU4LStack<uint16>::Get(L, -2);
                auto Ids_4214549053 = TU4LStack<FString>::Get(L, -1);
                Ids_0.Emplace(Ids_Key_3104592983, Ids_4214549053);
                lua_pop(L, 1);
            }
        }
        else if (Ids_0_Type == LUA_TNIL)
        {
            // Do nothing.
        }
        else
        {
            OutError = TEXT("Input map param must be a table or nil, name: Ids");
            return false;
        }
        
        __OwnerObject->SetProtoIds(Ids_0);
        OutRetCount = 0;
        return true;
    }

    static bool SetIgnoreMessageLog(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UNetworkManagerBase>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        
        TArray<FName> Names_0;
        auto Names_0_Type = lua_type(L, 2);
        if (Names_0_Type == LUA_TTABLE)
        {
            lua_len(L, 2);
            int ArrayLength = (int)luaL_checknumber(L, -1);
            lua_pop(L, 1);
        
            if (ArrayLength > 0)
            {
                Names_0.Reserve(ArrayLength);
                int GetIndex = lua_gettop(L) + 1;
                for (int ArrayIndex = 0; ArrayIndex < ArrayLength; ++ArrayIndex)
                {
                    lua_rawgeti(L, 2, ArrayIndex + 1);
                    auto Names_3816857761 = TU4LStack<FName>::Get(L, GetIndex);
                    Names_0.Emplace(Names_3816857761);
                    lua_pop(L, 1);
                }
            }
        }
        else if(Names_0_Type == LUA_TNIL)
        {
            // Do nothing.
        }
        else
        {
            OutError = TEXT("Input array param must be a table or nil, name: Names");
            return false;
        }
        
        __OwnerObject->SetIgnoreMessageLog(Names_0);
        OutRetCount = 0;
        return true;
    }

    static bool SetEnableLog(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UNetworkManagerBase>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto Enable_0 = TU4LStack<bool>::Get(L, 2);
        __OwnerObject->SetEnableLog(Enable_0);
        OutRetCount = 0;
        return true;
    }

    static bool ConvertIPToString(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UNetworkManagerBase>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto IPv4_0 = TU4LStack<uint32>::Get(L, 2);
        auto ReturnValue_1 = __OwnerObject->ConvertIPToString(IPv4_0);
        TU4LStack<FString>::Push(L, ReturnValue_1);
        OutRetCount = 1;
        return true;
    }

    static bool SetProtoFile(lua_State* L, int& OutRetCount, FString& OutError)
    {
        auto __OwnerObject = Cast<UNetworkManagerBase>(TU4LStack<UObject*>::Get(L, 1));
        if(!__OwnerObject) { OutError = TEXT("Call function failed, invalid object"); return false; }
        auto FileName_0 = TU4LStack<FString>::Get(L, 2);
        __OwnerObject->SetProtoFile(FileName_0);
        OutRetCount = 0;
        return true;
    }

public:
    FU4LExportedClass0_SocketNetworkManager()
    {
        FName ClassName(TEXT("/Script/Common.SocketNetworkManager"));
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetIdleTime"), &FU4LExportedClass0_SocketNetworkManager::SetIdleTime);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("Base64StringToMessage"), &FU4LExportedClass0_SocketNetworkManager::Base64StringToMessage);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("MessageToBase64String"), &FU4LExportedClass0_SocketNetworkManager::MessageToBase64String);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetIgnoreSpecificError"), &FU4LExportedClass0_SocketNetworkManager::SetIgnoreSpecificError);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetPending"), &FU4LExportedClass0_SocketNetworkManager::SetPending);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SendPacketByTable"), &FU4LExportedClass0_SocketNetworkManager::SendPacketByTable);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("IsConnected"), &FU4LExportedClass0_SocketNetworkManager::IsConnected);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("Disconnect"), &FU4LExportedClass0_SocketNetworkManager::Disconnect);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ConnectIPWithOpenSSL"), &FU4LExportedClass0_SocketNetworkManager::ConnectIPWithOpenSSL);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ConnectWithDomainName"), &FU4LExportedClass0_SocketNetworkManager::ConnectWithDomainName);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("Connect"), &FU4LExportedClass0_SocketNetworkManager::Connect);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetProtoIds"), &FU4LExportedClass0_SocketNetworkManager::SetProtoIds);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetIgnoreMessageLog"), &FU4LExportedClass0_SocketNetworkManager::SetIgnoreMessageLog);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetEnableLog"), &FU4LExportedClass0_SocketNetworkManager::SetEnableLog);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("ConvertIPToString"), &FU4LExportedClass0_SocketNetworkManager::ConvertIPToString);
        UU4LuaLib::RegisterNativeUEFunction(ClassName, TEXT("SetProtoFile"), &FU4LExportedClass0_SocketNetworkManager::SetProtoFile);
    }
};
static FU4LExportedClass0_SocketNetworkManager GRegister_FU4LExportedClass0_SocketNetworkManager;
