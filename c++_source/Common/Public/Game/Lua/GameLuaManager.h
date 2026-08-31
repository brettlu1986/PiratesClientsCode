#pragma once
//
//#include "lua.hpp"
//#include "GameLuaPathSearcher.h"
//#include "GameLuaManager.generated.h"
//
//class ULuaRoot;
//class FGameLuaHook;
//struct FGlobalFunction;
//class ULuaTableRef;
//
//UCLASS(config=Game)
//class COMMON_API UGameLuaManager : public UObject
//{    
//    GENERATED_UCLASS_BODY()
//
//public:
//    bool Init(const FString& ScriptRootPath, const FString& PathCacheFile=FString());
//    void Uninit();
//
//    void SetIsDedicatedServer(bool bServer);
//    inline const bool IsDedicatedServer() const { return bIsDedicatedServer; }
//    bool DoFile(const FString& ScriptName);
//    bool DoFile(const FString& ScriptName, FString& OutErrorMessage);
//    bool DoString(const FString& String, FString& OutReturnValue, FString& OutErrorMessage);
//    void CollectGarbage();
//    virtual UWorld* GetWorld() const override { return GetOuter()->GetWorld(); }
//    void AddSearchPath(const FString& Path);
//    void OnWorldChanged(UWorld* NewWorld);
//    void SetGlobalTableNewIndexEnabled(bool bEnabled);
//    void SetGlobalObjectVariable(const char* Name, UObject* Value);
//    void SetGlobalBoolVariable(const char* Name, bool Value);
//    void SetGlobalStringVariable(const char* Name, const char* Value);
//    void RegistGlobalFunction(const char* Name, lua_CFunction Function);
//	int GetMemoryUsage();
//
//private:
//    friend FGlobalFunction;
//    friend FGameLuaHook;
//    lua_State* GetLuaState();
//    void SetHookEnabled(bool bEnabled);
//    void SetHookLogEnabled(bool bEnabled);
//    void SetHandleCountToGC(int HandleCount);
//    void StartLuaCollectGarbageByStep();
//    void StopLuaCollectGarbageByStep();
//    bool Tick(float DeltaTime);
//
//private:
//    FGameLuaPathSearcher PathSearcher;
//    bool bIsDedicatedServer;
//    FGameLuaHook* LuaHook;
//    FDelegateHandle TickerHandle;
//#if STATS
//    TSharedPtr<FScopeCycleCounter> CurrentStatCounter;
//#endif
//
//    UPROPERTY()
//    ULuaRoot* LuaRoot;
//
//    UPROPERTY()
//    ULuaTableRef* TableRef;
//
//    UPROPERTY(config)
//    int HandleCountToTriggerLuaGC;
//    UPROPERTY(config)
//    int LuaGCStepSize;
//    UPROPERTY(config)
//    float LuaGCStepTime;
//    UPROPERTY(config)
//    FString LuaFileExtension;
//};