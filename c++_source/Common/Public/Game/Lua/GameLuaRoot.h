#pragma once

#include "U4LuaRoot.h"
#include "GameLuaRoot.generated.h"

UCLASS(BlueprintType)
class COMMON_API UGameLuaRoot : public UU4LuaRoot
{
    friend struct FGameLuaGlobalFunction;
    GENERATED_UCLASS_BODY()    

public:    
    virtual bool Init() override;
    virtual void Uninit() override;
    void OnCurrentWorldChanged(UWorld* CurrentWorld);
    
    void SetIsDedicatedServer(bool bServer);
    FORCEINLINE const bool IsDedicatedServer() const { return bIsDedicatedServer; }
    int GetMemoryUsage(bool IncludeLuaState=true);
    void CollectGarbage();

    // 这里图省事直接卡死获取文件列表
    void SetHttpRemoteRepository(const FString& URL);

private:
    bool bIsDedicatedServer;

#if STATS
    TSharedPtr<FScopeCycleCounter> CurrentStatCounter;
#endif

    UPROPERTY()
    class ULuaTableRef* TableRef;
};