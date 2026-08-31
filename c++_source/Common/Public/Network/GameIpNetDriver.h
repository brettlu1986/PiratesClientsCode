#pragma once
#include "IpNetDriver.h"
#include "GameIpNetDriver.generated.h"

UCLASS(transient, config = Engine)
class COMMON_API UGameIpNetDriver : public UIpNetDriver
{
    GENERATED_UCLASS_BODY()

    virtual void PostInitProperties() override;
    virtual void PostReloadConfig(FProperty* PropertyToLoad) override;
    virtual void ProcessRemoteFunction(class AActor* Actor, class UFunction* Function, void* Parameters, struct FOutParmRec* OutParms, struct FFrame* Stack, class UObject* SubObject = NULL) override;

    virtual void TickDispatch(float DeltaTime) override;
    virtual bool ShouldQueueBunchesForActorGUID(FNetworkGUID InGUID) const override;

public:
    void ProcessReconnectInfos();
    bool RecreateUDPSocketInClient();
    void AddCustomStatelessHandlers() override;

    FORCEINLINE void AddActorGUIDForQueueBunches(const FNetworkGUID& GUID) { ActorGUIDForQueueBunches.Emplace(GUID); }
    FORCEINLINE void RemoveActorGUIDForQueueBunches(const FNetworkGUID& GUID) { ActorGUIDForQueueBunches.Remove(GUID); }
    FORCEINLINE const bool IsActorAsyncCreatingEnabled() const { return EnableActorAsyncCreating; }
    void SetActorAsyncCreatingEnabled(bool Enabled);
    FORCEINLINE const float GetActorAsyncCreatingRemainTime() const { return ActorAsyncCreatingRemainTime; }
    FORCEINLINE void ConsumeActorAsyncCreatingTime(float ElapseTime) { ActorAsyncCreatingRemainTime -= ElapseTime; }

private:
    void ReplaceActorChannel();
    void AddReconnectComponentHandler();
    FORCEINLINE void ResetActorAsyncCreatingRemainTime() { ActorAsyncCreatingRemainTime = ActorAsyncCreatingTimeLimit; }

private:
    virtual bool InitBase(bool bInitAsClient, FNetworkNotify* InNotify, const FURL& URL, bool bReuseAddressAndPort, FString& Error) override;
    virtual void PostTickFlush() override;
    virtual void Shutdown() override;
    void OnDisconnect(UWorld* InWorld, UNetDriver* NetDriver);

public:
    TWeakPtr<class ReconnectHandlerComponent> ReconnectComponent;

private:
    TSet<FNetworkGUID> ActorGUIDForQueueBunches;
    bool EnableActorAsyncCreating;
    FDelegateHandle OnDisconnectHandle;
    bool NeedCallDisconnectDelegate;

    UPROPERTY(config)
    float ActorAsyncCreatingTimeLimit;

    float ActorAsyncCreatingRemainTime;
};
