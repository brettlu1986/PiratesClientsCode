// Copyright 1998-2018 Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "ReplicationGraph.h"
#include "PiratesReplicationGraph.generated.h"

class AKMCharacter;
class UReplicationGraphNode_GridSpatialization2D;
class AGameplayDebuggerCategoryReplicator;
class UPiratesReplicationConnectionGraph;

DECLARE_LOG_CATEGORY_EXTERN( LogPiratesReplicationGraph, Log, All );

// This is the main enum we use to route actors to the right replication node. Each class maps to one enum.
UENUM(BlueprintType)
enum class EClassRepNodeMapping : uint8
{
    // Does not route to any node. Special case when you want to control manual way.
    NotRouted,
    // Routes to an AlwaysRelevantNode
    RelevantAllConnections,
    // Routes to an AlwaysRelevantNode_ForConnection node
    RelevantOwnerConnection,
    // Routes to an AlwaysRelevantNode_ForTeam node
    RelevantTeamConnection,

    // ONLY SPATIALIZED Enums below here! See UReplicationGraphBase::IsSpatialized

    // Routes to GridNode: these actors don't move and don't need to be updated every frame.
    Spatialize_Static,
    // Routes to GridNode: these actors mode frequently and are updated once per frame.
    Spatialize_Dynamic,
    // Routes to GridNode: While dormant we treat as static. When flushed/not dormant dynamic. Note this is for things that "move while not dormant".
    Spatialize_Dormancy,
};

struct FTeamRequest
{
    int32 TeamId;
    APlayerController* Requestor;
    FTeamRequest(int32 InTeamId, APlayerController* PC) :TeamId(InTeamId), Requestor(PC) {}
};

USTRUCT(BlueprintType)
struct FClassReplicationPolicyPreset
{
    GENERATED_BODY()
public:
    // Class to set replication policy.
    UPROPERTY(EditAnywhere)
    TSubclassOf<AActor> Class;

    // Policy to set.
    UPROPERTY(EditAnywhere)
    EClassRepNodeMapping Policy;
};

USTRUCT(BlueprintType)
struct FClassReplicationInfoPreset
{
    GENERATED_BODY()
public:
    // Class of this Replication info is related
    UPROPERTY(EditAnywhere)
    TSubclassOf<AActor> Class;
    
    // How much will distance affect to priority
    UPROPERTY(EditAnywhere, meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
    float DistancePriorityScale = 1.f;
    
    // How much will stavation affect to priority
    UPROPERTY(EditAnywhere, meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
    float StarvationPriorityScale = 1.f;
    
    // Cull distance that overrides NetCullDistance (Warning : IsNetRelevantFor will not be called in this system)
    UPROPERTY(EditAnywhere, meta = (ClampMin = "0.0", UIMin = "0.0"))
    float CullDistanceSquared = 0.f;

    //Server frame count per actual replication
    UPROPERTY(EditAnywhere, meta = (ClampMin = "0.0", UIMin = "0.0"))
    uint8 ReplicationPeriodFrame = 1;

    // How long will this actor channel stay alive even after it's being out of relevancy
    UPROPERTY(EditAnywhere, meta = (ClampMin = "0.0", UIMin = "0.0"))
    uint8 ActorChannelFrameTimeout = 4;

    // Whether this setting overrides all child classes or not
    UPROPERTY(EditAnywhere)
    bool IncludeChildClasses = true;

    FClassReplicationInfo CreateClassReplicationInfo()
    {
        FClassReplicationInfo Info;
        Info.DistancePriorityScale = DistancePriorityScale;
        Info.StarvationPriorityScale = StarvationPriorityScale;
        Info.SetCullDistanceSquared(CullDistanceSquared);
        Info.ReplicationPeriodFrame = ReplicationPeriodFrame;
        Info.ActorChannelFrameTimeout = ActorChannelFrameTimeout;
        return Info;
    }
};

struct FTeamConnectionListMap : public TMap<int32, TArray<TWeakObjectPtr<UPiratesReplicationConnectionGraph>>>
{
public:
    //Get array of connection managers for gathering actor list
    TArray<TWeakObjectPtr<UPiratesReplicationConnectionGraph>>* GetConnectionArrayForTeam(int32 TeamId);

    //Add Connection to team, if there's no array, add one.
    void AddConnectionToTeam(int32 TeamId, TWeakObjectPtr<UPiratesReplicationConnectionGraph> ConnManager);

    //Remove Connection from team, if there's no member of the team after removal, remove array from the map
    void RemoveConnectionFromTeam(int32 TeamId, TWeakObjectPtr<UPiratesReplicationConnectionGraph> ConnManager);
};


UCLASS()
class UPiratesReplicationGraphNode_AlwaysRelevant_ForConnection : public UReplicationGraphNode
{
    GENERATED_BODY()

public:

    virtual void NotifyAddNetworkActor(const FNewReplicatedActorInfo& Actor) override { }
    virtual bool NotifyRemoveNetworkActor(const FNewReplicatedActorInfo& ActorInfo, bool bWarnIfNotFound = true) override { return false; }
    virtual void NotifyResetAllNetworkActors() override { }

    virtual void GatherActorListsForConnection(const FConnectionGatherActorListParameters& Params) override;

    virtual void LogNode(FReplicationGraphDebugInfo& DebugInfo, const FString& NodeName) const override;

    void OnClientLevelVisibilityAdd(FName LevelName, UWorld* StreamingWorld);
    void OnClientLevelVisibilityRemove(FName LevelName);

    void ResetGameWorldState();

#if WITH_GAMEPLAY_DEBUGGER
    AGameplayDebuggerCategoryReplicator* GameplayDebugger = nullptr;
#endif

public:
    UPROPERTY()
    AActor* LastPawn = nullptr;

    TArray<AActor*> AlwaysRelevantPawnsForConnection;

private:

    TArray<FName, TInlineAllocator<64> > AlwaysRelevantStreamingLevelsNeedingReplication;

    FActorRepListRefView ReplicationActorList;

    bool bInitializedPlayerState = false;       

};

/** This is a specialized node for handling PlayerState replication in a frequency limited fashion. It tracks all player states but only returns a subset of them to the replication driver each frame. */
UCLASS()
class UPiratesReplicationGraphNode_PlayerStateFrequencyLimiter : public UReplicationGraphNode
{
    GENERATED_BODY()

        UPiratesReplicationGraphNode_PlayerStateFrequencyLimiter();

    virtual void NotifyAddNetworkActor(const FNewReplicatedActorInfo& Actor) override { }
    virtual bool NotifyRemoveNetworkActor(const FNewReplicatedActorInfo& ActorInfo, bool bWarnIfNotFound = true) override { return false; }

    virtual void GatherActorListsForConnection(const FConnectionGatherActorListParameters& Params) override;

    virtual void PrepareForReplication() override;

    virtual void LogNode(FReplicationGraphDebugInfo& DebugInfo, const FString& NodeName) const override;

    /** How many actors we want to return to the replication driver per frame. Will not suppress ForceNetUpdate. */
    int32 TargetActorsPerFrame = 2;

private:

    TArray<FActorRepListRefView> ReplicationActorLists;
    FActorRepListRefView ForceNetUpdateReplicationActorList;
};

UCLASS()
class UReplicationGraphNode_AlwaysRelevant_ForTeam : public UReplicationGraphNode_ActorList
{
    GENERATED_BODY()

public:
    //Gather up other team member's list 
    virtual void GatherActorListsForConnection(const FConnectionGatherActorListParameters& Params) override;

    //Function that calls parent ActorList's GatherActorList...
    virtual void GatherActorListsForConnectionDefault(const FConnectionGatherActorListParameters& Params);

private:

    FActorRepListRefView ReplicationActorList;
};

UCLASS()
class UPiratesReplicationConnectionGraph : public UNetReplicationGraphConnection
{
    GENERATED_BODY()

public:
    UPROPERTY()
    UPiratesReplicationGraphNode_AlwaysRelevant_ForConnection* AlwaysRelevantForConnectionNode; 

    UPROPERTY()
    class UReplicationGraphNode_AlwaysRelevant_ForTeam* TeamConnectionNode;

    int32 TeamId = 0;

    APlayerController* PlayerController;

    TArray<AActor*> DormantReplicationPlayers;
    
    TArray<AActor*> ReplicationPlayers;
    
};

UCLASS()
class UReplicationGraphNode_AlwaysRelevant_WithPending : public UReplicationGraphNode_ActorList
{
    GENERATED_BODY()

public:
    UReplicationGraphNode_AlwaysRelevant_WithPending();
    virtual void PrepareForReplication() override;
};

UCLASS()
class UReplicationGraphNode_GridSpatialization2D_Ocean : public UReplicationGraphNode_GridSpatialization2D
{
    GENERATED_BODY()

public:
    virtual void GatherActorListsForConnection(const FConnectionGatherActorListParameters& Params) override;

};

UCLASS()
class UReplicationGraphNode_GridSpatialization2D_Land : public UReplicationGraphNode_GridSpatialization2D
{
    GENERATED_BODY()

public:
    virtual void GatherActorListsForConnection(const FConnectionGatherActorListParameters& Params) override;

};


/**
 *
 */
UCLASS(Blueprintable)
class UPiratesReplicationGraph :public UReplicationGraph
{
	GENERATED_BODY()

public:
    // How far destruction infos will be sent. When server destroyed an actor that is NetLoadOnClient tick is on
    UPROPERTY(EditDefaultsOnly, meta = (ClampMin = "1000.0", ClampMax = "100000.0", UIMin = "1000.0", UIMax = "100000.0"))
    float DestructionInfoMaxDistance = 30000.f;

    // Cell size of spatial gird.
    UPROPERTY(EditDefaultsOnly, meta = (ClampMin = "1000.0", ClampMax = "2000000.0", UIMin = "1000.0", UIMax = "2000000.0"))
    float LandSpacialCellSize = 50000.f;

    UPROPERTY(EditDefaultsOnly, meta = (ClampMin = "1000.0", ClampMax = "2000000.0", UIMin = "1000.0", UIMax = "2000000.0"))
    float OceanSpacialCellSize = 100000.f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, meta = (DefaultValue = "true"))
    bool bLimitPlayerNum = true;

    UPROPERTY(EditDefaultsOnly, meta = (ClampMin = "0", ClampMax = "1000", UIMin = "0", UIMax = "1000"))
    int32 ReplicatePlayerMaxNum = 50;

    // Spatial grid out of bound bias. Better not change this.
    UPROPERTY(EditDefaultsOnly)
    FVector2D SpatialBias = FVector2D(-WORLD_MAX, -WORLD_MAX);

    // Should spatial grid rebuilt upon detecting an actor that is out of bias?
    UPROPERTY(EditDefaultsOnly)
    bool EnableSpatialRebuilds = false;

    UPROPERTY(EditDefaultsOnly)
    TArray<FClassReplicationPolicyPreset> ReplicationPolicySettings;

    UPROPERTY(EditDefaultsOnly)
    TArray<FClassReplicationInfoPreset> ReplicationInfoSettings;

public:

	UPiratesReplicationGraph();

	virtual void InitGlobalActorClassSettings() override;
	virtual void InitGlobalGraphNodes() override;
	virtual void InitConnectionGraphNodes(UNetReplicationGraphConnection* RepGraphConnection) override;
	virtual void RouteAddNetworkActorToNodes(const FNewReplicatedActorInfo& ActorInfo, FGlobalActorReplicationInfo& GlobalInfo) override;
	virtual void RouteRemoveNetworkActorToNodes(const FNewReplicatedActorInfo& ActorInfo) override;
    virtual void OnRemoveConnectionGraphNodes(UNetReplicationGraphConnection* RepGraphConnection);
    virtual void RemoveClientConnection(UNetConnection* NetConnection) override;

    virtual void ResetGameWorldState() override;
	
	UPROPERTY()
    UReplicationGraphNode_GridSpatialization2D_Land* LandGridNode;

    UPROPERTY()
    UReplicationGraphNode_GridSpatialization2D_Ocean* OceanGridNode;

    UPROPERTY()
    UReplicationGraphNode_AlwaysRelevant_WithPending* AlwaysRelevantNode;

	TMap<FName, FActorRepListRefView> AlwaysRelevantStreamingLevelActors;

    //Add Child Actor to Parent's Dep List, Child will relevant according to Replicator's relevancy
    void AddDependentActor(AActor* Parent, AActor* Child);
    void RemoveDependentActor(AActor* Parent, AActor* Child);

    //Change Owner of an actor that is relevant to connection specific
    void ChangeOwnerOfAnActor(AActor* ActorToChange, AActor* NewOwner);

    //SetTeam via TeamId
    void SetTeamForPlayerController(APlayerController* PlayerController, int32 TeamId);

    void ClearTeamReplicateById(int32 TeamId);

    //Change Actor CullDistance
    void ChangeActorCullDistanceSquared(AActor* Actor, float CullDistance);

    float GetActorCullDistanceSquared(AActor* Actor);

    void SetActorReplicateToController(APlayerController* OwnerController, AActor* Actor, bool bReplicate);

    void SetActorDormantForConnection(AActor* DormantActor, AActor* OtherActor, uint8 bDormant);

    //to handle actors that has no connection at addnofity execution
    void RouteAddNetworkActorToConnectionNodes(EClassRepNodeMapping Policy, const FNewReplicatedActorInfo& ActorInfo, FGlobalActorReplicationInfo& GlobalInfo);
    void RouteRemoveNetworkActorToConnectionNodes(EClassRepNodeMapping Policy, const FNewReplicatedActorInfo& ActorInfo);

    //handle pending team requests and notifies
    void HandlePendingActorsAndTeamRequests();

    UPiratesReplicationConnectionGraph* FindConnectionGraph(const AActor* Actor);

#if WITH_GAMEPLAY_DEBUGGER
	void OnGameplayDebuggerOwnerChange(AGameplayDebuggerCategoryReplicator* Debugger, APlayerController* OldOwner);
#endif

	void PrintRepNodePolicies();

private:

	EClassRepNodeMapping GetMappingPolicy(UClass* Class);

	bool IsSpatialized(EClassRepNodeMapping Mapping) const { return Mapping >= EClassRepNodeMapping::Spatialize_Static; }

    void CreateLandGridNode();
    void CreateOceanGridNode();

	TClassMap<EClassRepNodeMapping> ClassRepNodePolicies;

    friend UReplicationGraphNode_AlwaysRelevant_ForTeam;
    FTeamConnectionListMap TeamConnectionListMap;

    TArray<AActor*> PendingConnectionActors;
    TArray<FTeamRequest> PendingTeamRequests;
};
