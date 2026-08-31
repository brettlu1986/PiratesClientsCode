// Fill out your copyright notice in the Description page of Project Settings.

#include "Network/PiratesReplicationGraph.h"
#include "Common.h"
#include "ReplicationGraph.h"
#include "Net/UnrealNetwork.h"
#include "Engine/LevelStreaming.h"
#include "EngineUtils.h"
#include "CoreGlobals.h"

#if WITH_GAMEPLAY_DEBUGGER
#include "GameplayDebuggerCategoryReplicator.h"
#endif

#include "GameFramework/GameModeBase.h"
#include "GameFramework/GameState.h"
#include "GameFramework/PlayerState.h"
#include "GameFramework/Pawn.h"
#include "Engine/LevelScriptActor.h"
#include "KMCharacter.h"
#include "KMPawn.h"
#include "Pawns/PiratesShipPawn.h"
#include "Pawns/PiratesHumanCharacter.h"
#include "Pawns/PiratesMountCharacter.h"
#include "PiratesPlayerController.h"
#include "Shell/CommonShell.h"
#include "Battle/PiratesGridTypeManager.h"

DEFINE_LOG_CATEGORY(LogPiratesReplicationGraph);


int32 CVar_PiratesRepGraph_DisplayClientLevelStreaming = 0;
static FAutoConsoleVariableRef CVarPiratesRepGraphDisplayClientLevelStreaming(TEXT("PiratesRepGraph.DisplayClientLevelStreaming"), CVar_PiratesRepGraph_DisplayClientLevelStreaming, TEXT(""), ECVF_Default );


static TAutoConsoleVariable<FString> CVarPiratesRepGraphConditionalBreakpointActorName(TEXT("PiratesRepGraph.ConditionalBreakpointActorName"), TEXT(""), TEXT(""), ECVF_Default);
FORCEINLINE bool PiratesRepGraphConditionalActorBreakpoint(AActor* Actor)
{
#if !(UE_BUILD_SHIPPING || UE_BUILD_TEST)
    if (CVarPiratesRepGraphConditionalBreakpointActorName.GetValueOnGameThread().Len() > 0 && GetNameSafe(Actor).Contains(CVarPiratesRepGraphConditionalBreakpointActorName.GetValueOnGameThread()))
    {
        return true;
    }
#endif
    return false;
}


UPiratesReplicationGraph::UPiratesReplicationGraph()
{
    ReplicationConnectionManagerClass = UPiratesReplicationConnectionGraph::StaticClass();

    FClassReplicationInfoPreset PawnClassRepInfo;
    PawnClassRepInfo.Class = APawn::StaticClass();
    PawnClassRepInfo.DistancePriorityScale = 1.f;
    PawnClassRepInfo.StarvationPriorityScale = 1.f;
    PawnClassRepInfo.ActorChannelFrameTimeout = 4;    
    PawnClassRepInfo.CullDistanceSquared = 15000.f * 15000.f; //keep it bigger than distance between actual pawn and inviewer
    ReplicationInfoSettings.Add(PawnClassRepInfo);
}

void InitClassReplicationInfo(FClassReplicationInfo& Info, UClass* Class, bool bSpatialize, float ServerMaxTickRate)
{
	AActor* CDO = Class->GetDefaultObject<AActor>();
	if (bSpatialize)
	{
		Info.SetCullDistanceSquared(CDO->NetCullDistanceSquared);
		UE_LOG(LogPiratesReplicationGraph, Log, TEXT("Setting cull distance for %s to %f (%f)"), *Class->GetName(), Info.GetCullDistanceSquared(), FMath::Sqrt(Info.GetCullDistanceSquared()));
	}

	Info.ReplicationPeriodFrame = FMath::Max<uint32>( (uint32)FMath::RoundToFloat(ServerMaxTickRate / CDO->NetUpdateFrequency), 1);

	UClass* NativeClass = Class;
	while(!NativeClass->IsNative() && NativeClass->GetSuperClass() && NativeClass->GetSuperClass() != AActor::StaticClass())
	{
		NativeClass = NativeClass->GetSuperClass();
	}

	UE_LOG(LogPiratesReplicationGraph, Log, TEXT("Setting replication period for %s (%s) to %d frames (%.2f)"), *Class->GetName(), *NativeClass->GetName(), Info.ReplicationPeriodFrame, CDO->NetUpdateFrequency);
}

void UPiratesReplicationGraph::ResetGameWorldState()
{
	Super::ResetGameWorldState();

    //all actor will be destroyed. just reset it.
    PendingConnectionActors.Reset();
    PendingTeamRequests.Reset();

    auto EmptyConnectionNode = [](TArray<UNetReplicationGraphConnection*>& PiratesConnections)
    {
        for (UNetReplicationGraphConnection* RepConnManager : PiratesConnections)
        {
            if (UPiratesReplicationConnectionGraph* PiratesConnManager = Cast<UPiratesReplicationConnectionGraph>(RepConnManager))
            {
                PiratesConnManager->AlwaysRelevantForConnectionNode->NotifyResetAllNetworkActors();
            }
        }
    };

    EmptyConnectionNode(PendingConnections);
    EmptyConnectionNode(Connections);

	AlwaysRelevantStreamingLevelActors.Empty();
}

void UPiratesReplicationGraph::InitGlobalActorClassSettings()
{
    UE_LOG(LogPiratesReplicationGraph, Log, TEXT("start init global actor class settings"));

	Super::InitGlobalActorClassSettings();

	// ---------------------------------------
	// Programatically build the rules.
	// ---------------------------------------
	
	auto AddInfo = [&]( UClass* Class, EClassRepNodeMapping Mapping) { ClassRepNodePolicies.Set(Class, Mapping); };

	AddInfo( ALevelScriptActor::StaticClass(),						EClassRepNodeMapping::NotRouted);
	AddInfo( APlayerState::StaticClass(),							EClassRepNodeMapping::NotRouted);   //TODO：@liujifang
	AddInfo( AReplicationGraphDebugActor::StaticClass(),			EClassRepNodeMapping::NotRouted);
	AddInfo( AInfo::StaticClass(),									EClassRepNodeMapping::RelevantAllConnections);
#if WITH_GAMEPLAY_DEBUGGER
	AddInfo( AGameplayDebuggerCategoryReplicator::StaticClass(),	EClassRepNodeMapping::NotRouted);
#endif

    for (FClassReplicationPolicyPreset PolicyBP : ReplicationPolicySettings)
    {
        if (PolicyBP.Class)
        {
            AddInfo(PolicyBP.Class, PolicyBP.Policy);
        }
    }

	TArray<UClass*> AllReplicatedClasses;
    TArray<UClass*> NonSpatializedChildClasses;

	for (TObjectIterator<UClass> It; It; ++It)
	{
		UClass* Class = *It;
		AActor* ActorCDO = Cast<AActor>(Class->GetDefaultObject());
		if (!ActorCDO || !ActorCDO->GetIsReplicated())
		{
			continue;
		}

		// Skip SKEL and REINST classes.
		if (Class->GetName().StartsWith(TEXT("SKEL_")) || Class->GetName().StartsWith(TEXT("REINST_")))
		{
			continue;
		}

		// --------------------------------------------------------------------
		// This is a replicated class. Save this off for the second pass below
		// --------------------------------------------------------------------
		
		AllReplicatedClasses.Add(Class);

		// Skip if already in the map (added explicitly)
		if (ClassRepNodePolicies.Contains(Class, false))
		{
			continue;
		}

		auto ShouldSpatialize = [](const AActor* CDO)
		{
			return CDO->GetIsReplicated() && (!(CDO->bAlwaysRelevant || CDO->bOnlyRelevantToOwner || CDO->bNetUseOwnerRelevancy));
		};

		auto GetLegacyDebugStr = [](const AActor* CDO)
		{
			return FString::Printf(TEXT("%s [%d/%d/%d]"), *CDO->GetClass()->GetName(), CDO->bAlwaysRelevant, CDO->bOnlyRelevantToOwner, CDO->bNetUseOwnerRelevancy);
		};

		// Only handle this class if it differs from its super. There is no need to put every child class explicitly in the graph class mapping
		UClass* SuperClass = Class->GetSuperClass();
		if (AActor* SuperCDO = Cast<AActor>(SuperClass->GetDefaultObject()))
		{
			if (	SuperCDO->GetIsReplicated() == ActorCDO->GetIsReplicated() 
				&&	SuperCDO->bAlwaysRelevant == ActorCDO->bAlwaysRelevant
				&&	SuperCDO->bOnlyRelevantToOwner == ActorCDO->bOnlyRelevantToOwner
				&&	SuperCDO->bNetUseOwnerRelevancy == ActorCDO->bNetUseOwnerRelevancy
				)
			{
				continue;
			}

			if (ShouldSpatialize(ActorCDO) == false && ShouldSpatialize(SuperCDO) == true)
			{
				UE_LOG(LogPiratesReplicationGraph, Log, TEXT("Adding %s to NonSpatializedChildClasses. (Parent: %s)"), *GetLegacyDebugStr(ActorCDO), *GetLegacyDebugStr(SuperCDO));
				NonSpatializedChildClasses.Add(Class);
			}
		}
			
		if (ShouldSpatialize(ActorCDO))
		{
			AddInfo(Class, EClassRepNodeMapping::Spatialize_Dynamic);
		}
		else if (ActorCDO->bAlwaysRelevant && !ActorCDO->bOnlyRelevantToOwner)
		{
			AddInfo(Class, EClassRepNodeMapping::RelevantAllConnections);
		}
        else if (ActorCDO->bOnlyRelevantToOwner)
        {
            AddInfo(Class, EClassRepNodeMapping::RelevantOwnerConnection);
        }
	}

	// ---------------------------------------------------------------------------------------------
	// Setup FClassReplicationInfo. This is essentially the per class replication settings. 
    // Some we set explicitly in ReplicationInfoSettings, the rest we are setting via looking at the legacy settings on AActor.
	// ---------------------------------------------------------------------------------------------
    TArray<FClassReplicationInfoPreset> ValidClassReplicationInfoPreset;
    //custom setting
    for (FClassReplicationInfoPreset& ReplicationInfoBP : ReplicationInfoSettings)
    {
        if (ReplicationInfoBP.Class)
        {
            GlobalActorReplicationInfoMap.SetClassInfo(ReplicationInfoBP.Class, ReplicationInfoBP.CreateClassReplicationInfo());
            ValidClassReplicationInfoPreset.Add(ReplicationInfoBP);
        }
    }

	UReplicationGraphNode_ActorListFrequencyBuckets::DefaultSettings.ListSize = 12;

	// Set FClassReplicationInfo based on legacy settings from all replicated classes
	for (UClass* ReplicatedClass : AllReplicatedClasses)
	{
		if (FClassReplicationInfoPreset* Preset = ValidClassReplicationInfoPreset.FindByPredicate([&](const FClassReplicationInfoPreset& Info) { return ReplicatedClass->IsChildOf(Info.Class.Get());  }))
		{
            //duplicated or set included child will be ignored
            if (Preset->Class.Get() == ReplicatedClass || Preset->IncludeChildClasses)
            {
                continue;
            }
		}

        if (ClassRepNodePolicies.GetChecked(ReplicatedClass) == EClassRepNodeMapping::RelevantAllConnections)
        {
            FClassReplicationInfo ClassInfo;
            ClassInfo.DistancePriorityScale = 0.f;
            GlobalActorReplicationInfoMap.SetClassInfo(ReplicatedClass, ClassInfo);
            continue;
        }

		const bool bClassIsSpatialized = IsSpatialized(ClassRepNodePolicies.GetChecked(ReplicatedClass));

		FClassReplicationInfo ClassInfo;
		InitClassReplicationInfo(ClassInfo, ReplicatedClass, bClassIsSpatialized, NetDriver->NetServerMaxTickRate);
		GlobalActorReplicationInfoMap.SetClassInfo( ReplicatedClass, ClassInfo );
	}


	// Print out what we came up with
	UE_LOG(LogPiratesReplicationGraph, Log, TEXT(""));
	UE_LOG(LogPiratesReplicationGraph, Log, TEXT("Class Routing Map: "));
	UEnum* Enum = FindObject<UEnum>(ANY_PACKAGE, TEXT("EClassRepNodeMapping"));
	for (auto ClassMapIt = ClassRepNodePolicies.CreateIterator(); ClassMapIt; ++ClassMapIt)
	{		
		UClass* Class = CastChecked<UClass>(ClassMapIt.Key().ResolveObjectPtr());
		const EClassRepNodeMapping Mapping = ClassMapIt.Value();

		// Only print if different than native class
        UClass* ParentNativeClass = GetParentNativeClass(Class);
		const EClassRepNodeMapping* ParentMapping = ClassRepNodePolicies.Get(ParentNativeClass);
		if (ParentMapping && Class != ParentNativeClass && Mapping == *ParentMapping)
		{
			continue;
		}

		UE_LOG(LogPiratesReplicationGraph, Log, TEXT("  %s (%s) -> %s"), *Class->GetName(), *GetNameSafe(ParentNativeClass), *Enum->GetNameStringByValue(static_cast<uint32>(Mapping)));
	}

	UE_LOG(LogPiratesReplicationGraph, Log, TEXT(""));
	UE_LOG(LogPiratesReplicationGraph, Log, TEXT("Class Settings Map: "));
	FClassReplicationInfo DefaultValues;
	for (auto ClassRepInfoIt = GlobalActorReplicationInfoMap.CreateClassMapIterator(); ClassRepInfoIt; ++ClassRepInfoIt)
	{
		const UClass* Class = CastChecked<UClass>(ClassRepInfoIt.Key().ResolveObjectPtr());
		const FClassReplicationInfo& ClassInfo = ClassRepInfoIt.Value();
		UE_LOG(LogPiratesReplicationGraph, Log, TEXT("  %s -> %s"), *Class->GetName(), *ClassInfo.BuildDebugStringDelta());
	}

    // Rep destruct infos
    DestructInfoMaxDistanceSquared = DestructionInfoMaxDistance * DestructionInfoMaxDistance;

#if WITH_GAMEPLAY_DEBUGGER
	AGameplayDebuggerCategoryReplicator::NotifyDebuggerOwnerChange.AddUObject(this, &UPiratesReplicationGraph::OnGameplayDebuggerOwnerChange);
#endif
}

void UPiratesReplicationGraph::CreateLandGridNode()
{
    LandGridNode = CreateNewNode<UReplicationGraphNode_GridSpatialization2D_Land>();
    LandGridNode->CellSize = LandSpacialCellSize;
    LandGridNode->SpatialBias = SpatialBias;
    if (!EnableSpatialRebuilds)
    {
        LandGridNode->AddSpatialRebuildBlacklistClass(AActor::StaticClass()); // Disable All spatial rebuilding
    }
    AddGlobalGraphNode(LandGridNode);
    UE_LOG(LogPiratesReplicationGraph, Log, TEXT("CreateLandGridNode CellSize = %f"), LandSpacialCellSize);
}

void UPiratesReplicationGraph::CreateOceanGridNode()
{
    OceanGridNode = CreateNewNode<UReplicationGraphNode_GridSpatialization2D_Ocean>();
    OceanGridNode->CellSize = OceanSpacialCellSize;
    OceanGridNode->SpatialBias = SpatialBias;
    if (!EnableSpatialRebuilds)
    {
        OceanGridNode->AddSpatialRebuildBlacklistClass(AActor::StaticClass()); // Disable All spatial rebuilding
    }
    AddGlobalGraphNode(OceanGridNode);
    UE_LOG(LogPiratesReplicationGraph, Log, TEXT("CreateOceanGridNode CellSize = %f"), OceanSpacialCellSize);
}

void UPiratesReplicationGraph::InitGlobalGraphNodes()
{
	// Preallocate some replication lists.
	PreAllocateRepList(3, 12);
	PreAllocateRepList(6, 12);
	PreAllocateRepList(128, 64);
	PreAllocateRepList(512, 16);
    PreAllocateRepList(4096, 16);

	// -----------------------------------------------
	//	Spatial Actors
	// -----------------------------------------------
    CreateLandGridNode();
    CreateOceanGridNode();

	// -----------------------------------------------
	//	Always Relevant (to everyone) Actors
	// -----------------------------------------------
	AlwaysRelevantNode = CreateNewNode<UReplicationGraphNode_AlwaysRelevant_WithPending>();
	AddGlobalGraphNode(AlwaysRelevantNode);

    //TODO:@liujifang
	// -----------------------------------------------
	//	Player State specialization. This will return a rolling subset of the player states to replicate
	// -----------------------------------------------
	UPiratesReplicationGraphNode_PlayerStateFrequencyLimiter* PlayerStateNode = CreateNewNode<UPiratesReplicationGraphNode_PlayerStateFrequencyLimiter>();
	AddGlobalGraphNode(PlayerStateNode);

}

void UPiratesReplicationGraph::InitConnectionGraphNodes(UNetReplicationGraphConnection* RepGraphConnection)
{
	Super::InitConnectionGraphNodes(RepGraphConnection);

    UPiratesReplicationConnectionGraph* PiratesConnManager = Cast<UPiratesReplicationConnectionGraph>(RepGraphConnection);
    if (!PiratesConnManager)
    {
        UE_LOG(LogPiratesReplicationGraph, Warning, TEXT("Unrecognized ConnectionDriver class, Expected UPiratesReplicationConnectionGraph"));
    }

    PiratesConnManager->TeamConnectionNode = CreateNewNode<UReplicationGraphNode_AlwaysRelevant_ForTeam>();
    AddConnectionGraphNode(PiratesConnManager->TeamConnectionNode, RepGraphConnection);

    PiratesConnManager->AlwaysRelevantForConnectionNode = CreateNewNode<UPiratesReplicationGraphNode_AlwaysRelevant_ForConnection>();

	// This node needs to know when client levels go in and out of visibility
	RepGraphConnection->OnClientVisibleLevelNameAdd.AddUObject(PiratesConnManager->AlwaysRelevantForConnectionNode, &UPiratesReplicationGraphNode_AlwaysRelevant_ForConnection::OnClientLevelVisibilityAdd);
	RepGraphConnection->OnClientVisibleLevelNameRemove.AddUObject(PiratesConnManager->AlwaysRelevantForConnectionNode, &UPiratesReplicationGraphNode_AlwaysRelevant_ForConnection::OnClientLevelVisibilityRemove);

	AddConnectionGraphNode(PiratesConnManager->AlwaysRelevantForConnectionNode, RepGraphConnection);
}

EClassRepNodeMapping UPiratesReplicationGraph::GetMappingPolicy(UClass* Class)
{
	EClassRepNodeMapping* PolicyPtr = ClassRepNodePolicies.Get(Class);
	EClassRepNodeMapping Policy = PolicyPtr ? *PolicyPtr : EClassRepNodeMapping::NotRouted;
	return Policy;
}

static bool IsInOcean(const FNewReplicatedActorInfo& ActorInfo)
{
    auto Actor = ActorInfo.GetActor();
    auto Location = Actor->GetActorLocation();
    auto RegionType = UCommonShell::GetCommon(GWorld)->GetGridTypeManager()->GetRegionType(Location.X, Location.Y);
    return (RegionType == EPiratesGridRegionType::Ocean || RegionType == EPiratesGridRegionType::Port);
}

void UPiratesReplicationGraph::RouteAddNetworkActorToNodes(const FNewReplicatedActorInfo& ActorInfo, FGlobalActorReplicationInfo& GlobalInfo)
{
	EClassRepNodeMapping Policy = GetMappingPolicy(ActorInfo.Class);

    if (PiratesRepGraphConditionalActorBreakpoint(ActorInfo.GetActor()))
    {
        UE_LOG(LogPiratesReplicationGraph, Display, TEXT("UPiratesReplicationGraph::RouteAddNetworkActorToNodes: %s"), *ActorInfo.Class->GetName());
    }

	switch(Policy)
	{
		case EClassRepNodeMapping::NotRouted:
		{
			break;
		}
		
		case EClassRepNodeMapping::RelevantAllConnections:
		{
			if (ActorInfo.StreamingLevelName == NAME_None)
			{
				AlwaysRelevantNode->NotifyAddNetworkActor(ActorInfo);
			}
			else
			{
				FActorRepListRefView& RepList = AlwaysRelevantStreamingLevelActors.FindOrAdd(ActorInfo.StreamingLevelName);
				RepList.PrepareForWrite();
				RepList.ConditionalAdd(ActorInfo.Actor);
			}
			break;
		}
        
        case EClassRepNodeMapping::RelevantOwnerConnection:
        case EClassRepNodeMapping::RelevantTeamConnection:
        {
            RouteAddNetworkActorToConnectionNodes(Policy, ActorInfo, GlobalInfo);
            break;
        }

		case EClassRepNodeMapping::Spatialize_Static:
		{
            if (IsInOcean(ActorInfo))
            {
                OceanGridNode->AddActor_Static(ActorInfo, GlobalInfo);
            }
            else
            {
                LandGridNode->AddActor_Static(ActorInfo, GlobalInfo);
            }
			break;
		}
		
		case EClassRepNodeMapping::Spatialize_Dynamic:
		{
            OceanGridNode->AddActor_Dynamic(ActorInfo, GlobalInfo);
            break;
		}
		
		case EClassRepNodeMapping::Spatialize_Dormancy:
		{
            OceanGridNode->AddActor_Dormancy(ActorInfo, GlobalInfo);
            break;
		}
	};
}

void UPiratesReplicationGraph::RouteRemoveNetworkActorToNodes(const FNewReplicatedActorInfo& ActorInfo)
{
    if (PiratesRepGraphConditionalActorBreakpoint(ActorInfo.GetActor()))
    {
        UE_LOG(LogPiratesReplicationGraph, Display, TEXT("UPiratesReplicationGraph::RouteAddNetworkActorToNodes: %s"), *ActorInfo.Class->GetName());
    }
	EClassRepNodeMapping Policy = GetMappingPolicy(ActorInfo.Class);
	switch(Policy)
	{
		case EClassRepNodeMapping::NotRouted:
		{
			break;
		}
		
		case EClassRepNodeMapping::RelevantAllConnections:
		{
			if (ActorInfo.StreamingLevelName == NAME_None)
			{
				AlwaysRelevantNode->NotifyRemoveNetworkActor(ActorInfo);
			}
			else
			{
				FActorRepListRefView& RepList = AlwaysRelevantStreamingLevelActors.FindChecked(ActorInfo.StreamingLevelName);
				if (RepList.Remove(ActorInfo.Actor) == false)
				{
					UE_LOG(LogPiratesReplicationGraph, Warning, TEXT("Actor %s was not found in AlwaysRelevantStreamingLevelActors list. LevelName: %s"), *GetActorRepListTypeDebugString(ActorInfo.Actor), *ActorInfo.StreamingLevelName.ToString());
				}				
			}
			break;
		}

        case EClassRepNodeMapping::RelevantOwnerConnection:
        case EClassRepNodeMapping::RelevantTeamConnection:
        {
            RouteRemoveNetworkActorToConnectionNodes(Policy, ActorInfo);
            break;
        }

		case EClassRepNodeMapping::Spatialize_Static:
		{
            if (IsInOcean(ActorInfo))
            {
                OceanGridNode->RemoveActor_Static(ActorInfo);
            }
            else
            {
                LandGridNode->RemoveActor_Static(ActorInfo);
            }
			break;
		}
		
		case EClassRepNodeMapping::Spatialize_Dynamic:
		{
            OceanGridNode->RemoveActor_Dynamic(ActorInfo);
			break;
		}
		
		case EClassRepNodeMapping::Spatialize_Dormancy:
		{
            OceanGridNode->RemoveActor_Dormancy(ActorInfo);
			break;
		}
	};
}

void UPiratesReplicationGraph::OnRemoveConnectionGraphNodes(UNetReplicationGraphConnection* RepGraphConnection)
{
    UPiratesReplicationConnectionGraph* ConnManager = Cast<UPiratesReplicationConnectionGraph>(RepGraphConnection);
    if (ConnManager)
    {
        TeamConnectionListMap.RemoveConnectionFromTeam(ConnManager->TeamId, ConnManager);
    }
}

void UPiratesReplicationGraph::RemoveClientConnection(UNetConnection* NetConnection)
{
    int32 ConnectionId = 0;
    bool bFound = false;

    // Remove the RepGraphConnection associated with this NetConnection. Also update ConnectionIds to stay compact.
    auto UpdateList = [&](TArray<UNetReplicationGraphConnection*> List)
    {
        for (int32 idx = 0; idx < Connections.Num(); ++idx)
        {
            UNetReplicationGraphConnection* ConnectionManager = Connections[idx];
            repCheck(ConnectionManager);

            if (ConnectionManager->NetConnection == NetConnection)
            {
                ensure(!bFound);
                //Nofity this to handle something - remove from team list
                OnRemoveConnectionGraphNodes(ConnectionManager);
                Connections.RemoveAtSwap(idx, 1, false);
                bFound = true;
            }
            else
            {
                ConnectionManager->ConnectionId = ConnectionId++;
            }
        }
    };

    UpdateList(Connections);
    UpdateList(PendingConnections);

    if (!bFound)
    {
        // At least one list should have found the connection
        UE_LOG(LogPiratesReplicationGraph, Warning, TEXT("UReplicationGraph::RemoveClientConnection could not find connection in Connection (%d) or PendingConnections (%d) lists"), *GetNameSafe(NetConnection), Connections.Num(), PendingConnections.Num());
    }
}

// Since we listen to global (static) events, we need to watch out for cross world broadcasts (PIE)
#if WITH_EDITOR
#define CHECK_WORLDS(X) if(X->GetWorld() != GetWorld()) return;
#else
#define CHECK_WORLDS(X)
#endif
void UPiratesReplicationGraph::AddDependentActor(AActor* Parent, AActor* Child)
{
    if (Parent && Child)
    {
        CHECK_WORLDS(Parent);

        GlobalActorReplicationInfoMap.AddDependentActor(Parent, Child);
    }
}

void UPiratesReplicationGraph::RemoveDependentActor(AActor* Parent, AActor* Child)
{
    if (Parent && Child)
    {
        CHECK_WORLDS(Parent);

        GlobalActorReplicationInfoMap.RemoveDependentActor(Parent, Child);
    }
}

void UPiratesReplicationGraph::ChangeOwnerOfAnActor(AActor* ActorToChange, AActor* NewOwner)
{
    EClassRepNodeMapping Policy = GetMappingPolicy(ActorToChange->GetClass());
    if (!ActorToChange || Policy == EClassRepNodeMapping::NotRouted || IsSpatialized(Policy))
    {
        //Policy doesn't matter for chaning owner
        return;
    }

    //remove from previous connection specific nodes.
    RouteRemoveNetworkActorToConnectionNodes(Policy, FNewReplicatedActorInfo(ActorToChange));

    //change owner safely
    ActorToChange->SetOwner(NewOwner);

    //re-route to connection specific nodes with new owner
    FGlobalActorReplicationInfo& GlobalInfo = GlobalActorReplicationInfoMap.Get(ActorToChange);
    RouteAddNetworkActorToConnectionNodes(Policy, FNewReplicatedActorInfo(ActorToChange), GlobalInfo);
}

void UPiratesReplicationGraph::SetTeamForPlayerController(APlayerController* PlayerController, int32 TeamId)
{
    if (!PlayerController)
    {
        return;
    }

    UPiratesReplicationConnectionGraph* ConnManager = FindConnectionGraph(PlayerController);
    if (!ConnManager)
    {
        PendingTeamRequests.Emplace(TeamId, PlayerController);
        return;
    }

    auto CurrentTeam = ConnManager->TeamId; 
    if (CurrentTeam == TeamId)
    {
        return;
    }

    auto SearchId = (TeamId == 0) ? CurrentTeam : TeamId;
//     if (CurrentTeam != 0)
//     {
//         TeamConnectionListMap.RemoveConnectionFromTeam(CurrentTeam, ConnManager);
//     }
    if (TeamId != 0)
    {
        TeamConnectionListMap.AddConnectionToTeam(TeamId, ConnManager);
    }
    ConnManager->TeamId = TeamId;
    ConnManager->PlayerController = PlayerController;

    if (TArray<TWeakObjectPtr<UPiratesReplicationConnectionGraph>>* TeamConnections = TeamConnectionListMap.GetConnectionArrayForTeam(SearchId))
    {
        for (auto TeamMember : *TeamConnections)
        {
            if (TeamMember.IsValid()
                && TeamMember->AlwaysRelevantForConnectionNode && ::IsValid(TeamMember->AlwaysRelevantForConnectionNode)
                && TeamMember != ConnManager)
            {
                auto Pawn = TeamMember->AlwaysRelevantForConnectionNode->LastPawn;
                if (TeamMember->PlayerController && Pawn)
                {
                    FConnectionReplicationActorInfo& ConnectionActorInfo = ConnManager->ActorInfoMap.FindOrAdd(Pawn);
                    if (TeamId != 0)
                    {
                        if (ConnectionActorInfo.Channel == nullptr)
                        {
                            ConnectionActorInfo.Channel = (UActorChannel*)ConnManager->NetConnection->CreateChannelByName(NAME_Actor, EChannelCreateFlags::OpenedLocally);
                            if (ConnectionActorInfo.Channel)
                            {
                                ConnectionActorInfo.Channel->SetChannelActor(Pawn, ESetChannelActorFlags::None);
                            }
                        }
                        ConnectionActorInfo.SetCullDistanceSquared(0.f);
                        ConnectionActorInfo.bDormantOnConnection = false;
                    }
                    else
                    {
                        FGlobalActorReplicationInfo& GlobalInfo = GlobalActorReplicationInfoMap.Get(Pawn);
                        ConnectionActorInfo.SetCullDistanceSquared(GlobalInfo.Settings.GetCullDistanceSquared());
                    }

                    for (int32 i = 0; i < Pawn->Children.Num(); ++i)
                    {
                        AKMCharacter* Character = Cast<AKMCharacter>(Pawn->Children[i]);
                        if (Character)
                        {
                            FConnectionReplicationActorInfo& DependentConnectionActorInfo = ConnManager->ActorInfoMap.FindOrAdd(Character);
                            if (TeamId != 0)
                            {
                                if (DependentConnectionActorInfo.Channel == nullptr)
                                {
                                    DependentConnectionActorInfo.Channel = (UActorChannel*)ConnManager->NetConnection->CreateChannelByName(NAME_Actor, EChannelCreateFlags::OpenedLocally);
                                    if (DependentConnectionActorInfo.Channel)
                                    {
                                        DependentConnectionActorInfo.Channel->SetChannelActor(Character, ESetChannelActorFlags::None);
                                    }
                                }
                                DependentConnectionActorInfo.SetCullDistanceSquared(0.f);
                                DependentConnectionActorInfo.bDormantOnConnection = false;
                            }
                            else
                            {
                                FGlobalActorReplicationInfo& GlobalInfo = GlobalActorReplicationInfoMap.Get(Character);
                                DependentConnectionActorInfo.SetCullDistanceSquared(GlobalInfo.Settings.GetCullDistanceSquared());
                            }
                        }
                    }
                }
            }
        }

        if (TeamConnections->Num() <= 0)
        {
            TeamConnectionListMap.Remove(CurrentTeam);
        }
    }
}

void UPiratesReplicationGraph::ClearTeamReplicateById(int32 TeamId)
{
    if (TArray<TWeakObjectPtr<UPiratesReplicationConnectionGraph>>* TeamConnections = TeamConnectionListMap.GetConnectionArrayForTeam(TeamId))
    {
        for (auto TeamMemberA : *TeamConnections)
        {
            if (TeamMemberA.IsValid())
            {
                for (auto TeamMemberB : *TeamConnections)
                {
                    if (TeamMemberB.IsValid() && TeamMemberA != TeamMemberB && ::IsValid(TeamMemberB->AlwaysRelevantForConnectionNode))
                    {
                        auto Pawn = TeamMemberB->AlwaysRelevantForConnectionNode->LastPawn;
                        if (::IsValid(Pawn))
                        {
                            FConnectionReplicationActorInfo& ConnectionActorInfo = TeamMemberA->ActorInfoMap.FindOrAdd(Pawn);
                            FGlobalActorReplicationInfo& GlobalInfo = GlobalActorReplicationInfoMap.Get(Pawn);
                            ConnectionActorInfo.SetCullDistanceSquared(GlobalInfo.Settings.GetCullDistanceSquared());
                        }
                    }
                }
            }
        }

        TeamConnectionListMap.Remove(TeamId);
    }
}

void UPiratesReplicationGraph::SetActorReplicateToController(APlayerController* PlayerController, AActor* Actor, bool bReplicate)
{
    if (!PlayerController || !Actor)
    {
        return;
    }

    UPiratesReplicationConnectionGraph* ConnManager = FindConnectionGraph(PlayerController);
    if (ConnManager && ::IsValid(Actor))
    {
        if (bReplicate)
        {
            FConnectionReplicationActorInfo& ConnectionActorInfo = ConnManager->ActorInfoMap.FindOrAdd(Actor);
            if (ConnectionActorInfo.Channel == nullptr)
            {
                ConnectionActorInfo.Channel = (UActorChannel*)ConnManager->NetConnection->CreateChannelByName(NAME_Actor, EChannelCreateFlags::OpenedLocally);
                if (ConnectionActorInfo.Channel)
                {
                    ConnectionActorInfo.Channel->SetChannelActor(Actor, ESetChannelActorFlags::None);
                }
            }
            ConnectionActorInfo.SetCullDistanceSquared(0.f);
            ConnectionActorInfo.bDormantOnConnection = false;

            FGlobalActorReplicationInfo& GlobalInfo = GlobalActorReplicationInfoMap.Get(Actor);
            GlobalInfo.Settings.DistancePriorityScale = 0.f;

            ConnManager->AlwaysRelevantForConnectionNode->AlwaysRelevantPawnsForConnection.Add(Actor);
        }
        else
        {
            ConnManager->AlwaysRelevantForConnectionNode->AlwaysRelevantPawnsForConnection.Remove(Actor);
        }
    }        
}

void UPiratesReplicationGraph::SetActorDormantForConnection(AActor* DormantActor, AActor* OtherActor, uint8 bDormant)
{
    if (!DormantActor || !OtherActor)
    {
        return;
    }

    UPiratesReplicationConnectionGraph* ConnManager = FindConnectionGraph(OtherActor);
    if (ConnManager)
    {
        FConnectionReplicationActorInfo& ConnectionActorInfo = ConnManager->ActorInfoMap.FindOrAdd(DormantActor);
        ConnectionActorInfo.bDormantOnConnection = bDormant;       
    }
}

void UPiratesReplicationGraph::ChangeActorCullDistanceSquared(AActor* Actor, float CullDistance)
{
    if (Actor)
    {
        FGlobalActorReplicationInfo& GlobalInfo = GlobalActorReplicationInfoMap.Get(Actor);
        float OldDistance = GlobalInfo.Settings.GetCullDistanceSquared();
        GlobalInfo.Settings.SetCullDistanceSquared(CullDistance);

        if (IsInOcean(FNewReplicatedActorInfo(Actor)))
        {
            OceanGridNode->NotifyActorCullDistChange(Actor, GlobalInfo, OldDistance);
        }
        else
        {
            LandGridNode->NotifyActorCullDistChange(Actor, GlobalInfo, OldDistance);
        }
    }
}

float UPiratesReplicationGraph::GetActorCullDistanceSquared(AActor* Actor)
{
    if (Actor)
    {
        FGlobalActorReplicationInfo& GlobalInfo = GlobalActorReplicationInfoMap.Get(Actor);
        return GlobalInfo.Settings.GetCullDistanceSquared();
    }

    return 0.f;
}

void UPiratesReplicationGraph::RouteAddNetworkActorToConnectionNodes(EClassRepNodeMapping Policy, const FNewReplicatedActorInfo& ActorInfo, FGlobalActorReplicationInfo& GlobalInfo)
{
    if (PiratesRepGraphConditionalActorBreakpoint(ActorInfo.GetActor()))
    {
        UE_LOG(LogPiratesReplicationGraph, Display, TEXT("UPiratesReplicationGraph::RouteAddNetworkActorToConnectionNodes: %s"), *ActorInfo.Class->GetName());
    }

    if (UPiratesReplicationConnectionGraph* ConnManager = FindConnectionGraph(ActorInfo.GetActor()))
    {
        switch (Policy)
        {
            case EClassRepNodeMapping::RelevantOwnerConnection:
            {
                ConnManager->AlwaysRelevantForConnectionNode->NotifyAddNetworkActor(ActorInfo);
                break;
            }
            case EClassRepNodeMapping::RelevantTeamConnection:
            {
                ConnManager->TeamConnectionNode->NotifyAddNetworkActor(ActorInfo);
                break;
            }
        };  
    }
    else if (ActorInfo.Actor->GetNetOwner())
    {
        //this actor is not yet ready. add to pending array to handle pending route
        PendingConnectionActors.Add(ActorInfo.GetActor());
    }
}

void UPiratesReplicationGraph::RouteRemoveNetworkActorToConnectionNodes(EClassRepNodeMapping Policy, const FNewReplicatedActorInfo& ActorInfo)
{
    if (UPiratesReplicationConnectionGraph* ConnManager = FindConnectionGraph(ActorInfo.GetActor()))
    {
        switch (Policy)
        {
            case EClassRepNodeMapping::RelevantOwnerConnection:
            {
                ConnManager->AlwaysRelevantForConnectionNode->NotifyRemoveNetworkActor(ActorInfo);
                break;
            }
            case EClassRepNodeMapping::RelevantTeamConnection:
            {
                ConnManager->TeamConnectionNode->NotifyRemoveNetworkActor(ActorInfo);
                break;
            }
        };
    }
    else if (ActorInfo.Actor->GetNetOwner())
    {
        //this actor is not yet ready. but doesn't matter the pending array contains the actor or not
        PendingConnectionActors.Remove(ActorInfo.GetActor());
    }
}

void UPiratesReplicationGraph::HandlePendingActorsAndTeamRequests()
{
    if (PendingTeamRequests.Num() > 0)
    {
        TArray<FTeamRequest> TempRequests = MoveTemp(PendingTeamRequests);

        for (FTeamRequest& Request : TempRequests)
        {
            if (Request.Requestor && ::IsValid(Request.Requestor))
            {
                //if failed, it will automatically re-added to pending list
                SetTeamForPlayerController(Request.Requestor, Request.TeamId);
            }
        }
    }

    if (PendingConnectionActors.Num() > 0)
    {
        TArray<AActor*> TempActors = MoveTemp(PendingConnectionActors);

        for (AActor* Actor : TempActors)
        {
            if (Actor && ::IsValid(Actor))
            {
                if (UNetConnection* Connection = Actor->GetNetConnection())
                {
                    //if failed, it will automatically re-added to pending list
                    EClassRepNodeMapping Policy = GetMappingPolicy(Actor->GetClass());
                    FGlobalActorReplicationInfo& GlobalInfo = GlobalActorReplicationInfoMap.Get(Actor);
                    RouteAddNetworkActorToConnectionNodes(Policy, FNewReplicatedActorInfo(Actor), GlobalInfo);
                }
            }
        }
    }
}

UPiratesReplicationConnectionGraph* UPiratesReplicationGraph::FindConnectionGraph(const AActor* Actor)
{
    if (Actor)
    {
        if (UNetConnection* NetConnection = Actor->GetNetConnection())
        {
            if (UPiratesReplicationConnectionGraph* ConnManager = Cast<UPiratesReplicationConnectionGraph>(FindOrAddConnectionManager(NetConnection)))
            {
                return ConnManager;
            }
        }
    }
    return nullptr;
}

#if WITH_GAMEPLAY_DEBUGGER
void UPiratesReplicationGraph::OnGameplayDebuggerOwnerChange(AGameplayDebuggerCategoryReplicator* Debugger, APlayerController* OldOwner)
{
	auto GetAlwaysRelevantForConnectionNode = [&](APlayerController* Controller) -> UPiratesReplicationGraphNode_AlwaysRelevant_ForConnection*
	{
		if (OldOwner)
		{
			if (UNetConnection* NetConnection = OldOwner->GetNetConnection())
			{
				if (UNetReplicationGraphConnection* GraphConnection = FindOrAddConnectionManager(NetConnection))
				{
					for (UReplicationGraphNode* ConnectionNode : GraphConnection->GetConnectionGraphNodes())
					{
						if (UPiratesReplicationGraphNode_AlwaysRelevant_ForConnection* AlwaysRelevantConnectionNode = Cast<UPiratesReplicationGraphNode_AlwaysRelevant_ForConnection>(ConnectionNode))
						{
							return AlwaysRelevantConnectionNode;
						}
					}

				}
			}
		}

		return nullptr;
	};

	if (UPiratesReplicationGraphNode_AlwaysRelevant_ForConnection* AlwaysRelevantConnectionNode = GetAlwaysRelevantForConnectionNode(OldOwner))
	{
		AlwaysRelevantConnectionNode->GameplayDebugger = nullptr;
	}

	if (UPiratesReplicationGraphNode_AlwaysRelevant_ForConnection* AlwaysRelevantConnectionNode = GetAlwaysRelevantForConnectionNode(Debugger->GetReplicationOwner()))
	{
		AlwaysRelevantConnectionNode->GameplayDebugger = Debugger;
	}
}
#endif

// ------------------------------------------------------------------------------

void UPiratesReplicationGraphNode_AlwaysRelevant_ForConnection::ResetGameWorldState()
{
	AlwaysRelevantStreamingLevelsNeedingReplication.Empty();
    AlwaysRelevantPawnsForConnection.Reset();
}

void UPiratesReplicationGraphNode_AlwaysRelevant_ForConnection::GatherActorListsForConnection(const FConnectionGatherActorListParameters& Params)
{
	QUICK_SCOPE_CYCLE_COUNTER( UPiratesReplicationGraphNode_AlwaysRelevant_ForConnection_GatherActorListsForConnection );

	UPiratesReplicationGraph* PiratesGraph = CastChecked<UPiratesReplicationGraph>(GetOuter());

	ReplicationActorList.Reset();

    for (const FNetViewer& CurView : Params.Viewers)
    {
        if (CurView.Connection == nullptr)
        {
            continue;
        }

        ReplicationActorList.ConditionalAdd(CurView.InViewer);
        ReplicationActorList.ConditionalAdd(CurView.ViewTarget);

        if (APiratesPlayerController* PC = Cast<APiratesPlayerController>(CurView.InViewer))
        {
            // 50% throttling of PlayerStates.
            const bool bReplicatePS = (Params.ConnectionManager.ConnectionId % 2) == (Params.ReplicationFrameNum % 2);
            if (bReplicatePS)
            {
                // Always return the player state to the owning player. Simulated proxy player states are handled by UPiratesReplicationGraphNode_PlayerStateFrequencyLimiter
                if (APlayerState* PS = PC->PlayerState)
                {
                    if (!bInitializedPlayerState)
                    {
                        bInitializedPlayerState = true;
                        FConnectionReplicationActorInfo& ConnectionActorInfo = Params.ConnectionManager.ActorInfoMap.FindOrAdd(PS);
                        ConnectionActorInfo.ReplicationPeriodFrame = 1;
                    }

                    ReplicationActorList.ConditionalAdd(PS);
                }
            }

            if (AKMCharacter* Pawn = Cast<AKMCharacter>(PC->GetPawn()))
            {
                if (Pawn != LastPawn)
                {
                    UE_LOG(LogPiratesReplicationGraph, Verbose, TEXT("Setting connection pawn cull distance to 0. %s"), *Pawn->GetName());
                    LastPawn = Pawn;
                    FConnectionReplicationActorInfo& ConnectionActorInfo = Params.ConnectionManager.ActorInfoMap.FindOrAdd(Pawn);
                    ConnectionActorInfo.SetCullDistanceSquared(0.f);
                }

                if (Pawn != CurView.ViewTarget)
                {
                    ReplicationActorList.ConditionalAdd(Pawn);
                }
            }
            else if (APiratesShipPawn* ShipPawn = Cast<APiratesShipPawn>(PC->GetPawn()))
            {
                if (ShipPawn != LastPawn)
                {
                    UE_LOG(LogPiratesReplicationGraph, Verbose, TEXT("Setting connection pawn cull distance to 0. %s"), *ShipPawn->GetName());
                    LastPawn = ShipPawn;
                    FConnectionReplicationActorInfo& ConnectionActorInfo = Params.ConnectionManager.ActorInfoMap.FindOrAdd(ShipPawn);
                    ConnectionActorInfo.SetCullDistanceSquared(0.f);
                }

                if (ShipPawn != CurView.ViewTarget)
                {
                    ReplicationActorList.ConditionalAdd(ShipPawn);
                }
            }

            if (CurView.ViewTarget != LastPawn)
            {
                if (AKMCharacter* ViewTargetPawn = Cast<AKMCharacter>(CurView.ViewTarget))
                {
                    UE_LOG(LogPiratesReplicationGraph, Verbose, TEXT("Setting connection view target pawn cull distance to 0. %s"), *ViewTargetPawn->GetName());
                    LastPawn = ViewTargetPawn;
                    FConnectionReplicationActorInfo& ConnectionActorInfo = Params.ConnectionManager.ActorInfoMap.FindOrAdd(ViewTargetPawn);
                    ConnectionActorInfo.SetCullDistanceSquared(0.f);
                }
                else if (APiratesShipPawn* ViewTargetShipPawn = Cast<APiratesShipPawn>(CurView.ViewTarget))
                {
                    UE_LOG(LogPiratesReplicationGraph, Verbose, TEXT("Setting connection view target pawn cull distance to 0. %s"), *ViewTargetShipPawn->GetName());
                    LastPawn = ViewTargetShipPawn;
                    FConnectionReplicationActorInfo& ConnectionActorInfo = Params.ConnectionManager.ActorInfoMap.FindOrAdd(ViewTargetShipPawn);
                    ConnectionActorInfo.SetCullDistanceSquared(0.f);
                }
            }
        }
    }

	Params.OutGatheredReplicationLists.AddReplicationActorList(ReplicationActorList);

    for (auto AlwaysRelevantPawnForConnection : AlwaysRelevantPawnsForConnection)
    {
        if (AlwaysRelevantPawnForConnection && AlwaysRelevantPawnForConnection->GetClass() && ::IsValid(AlwaysRelevantPawnForConnection) && !AlwaysRelevantPawnForConnection->IsPendingKill())
        {
            if (AKMCharacter* Pawn = Cast<AKMCharacter>(AlwaysRelevantPawnForConnection))
            {   
                FConnectionReplicationActorInfo& ConnectionActorInfo = Params.ConnectionManager.ActorInfoMap.FindOrAdd(AlwaysRelevantPawnForConnection);
                ConnectionActorInfo.SetCullDistanceSquared(0.f);
                ReplicationActorList.ConditionalAdd(Pawn);
            }
            else if (APiratesShipPawn* ShipPawn = Cast<APiratesShipPawn>(AlwaysRelevantPawnForConnection))
            {
                FConnectionReplicationActorInfo& ConnectionActorInfo = Params.ConnectionManager.ActorInfoMap.FindOrAdd(AlwaysRelevantPawnForConnection);
                ConnectionActorInfo.SetCullDistanceSquared(0.f);
                ReplicationActorList.ConditionalAdd(ShipPawn);
            }
        }
        else
        {
            AlwaysRelevantPawnsForConnection.Remove(AlwaysRelevantPawnForConnection);
            break;
        }
    }

    // Always relevant streaming level actors.
	FPerConnectionActorInfoMap& ConnectionActorInfoMap = Params.ConnectionManager.ActorInfoMap;

	TMap<FName, FActorRepListRefView>& AlwaysRelevantStreamingLevelActors = PiratesGraph->AlwaysRelevantStreamingLevelActors;

	for (int32 Idx=AlwaysRelevantStreamingLevelsNeedingReplication.Num()-1; Idx >= 0; --Idx)
	{
		const FName& StreamingLevel = AlwaysRelevantStreamingLevelsNeedingReplication[Idx];

		FActorRepListRefView* Ptr = AlwaysRelevantStreamingLevelActors.Find(StreamingLevel);
		if (Ptr == nullptr)
		{
			// No always relevant lists for that level
			UE_CLOG(CVar_PiratesRepGraph_DisplayClientLevelStreaming > 0, LogPiratesReplicationGraph, Display, TEXT("CLIENTSTREAMING Removing %s from AlwaysRelevantStreamingLevelActors because FActorRepListRefView is null. %s "), *StreamingLevel.ToString(),  *Params.ConnectionManager.GetName());
			AlwaysRelevantStreamingLevelsNeedingReplication.RemoveAtSwap(Idx, 1, false);
			continue;
		}

		FActorRepListRefView& RepList = *Ptr;

		if (RepList.Num() > 0)
		{
			bool bAllDormant = true;
			for (FActorRepListType Actor : RepList)
			{
				FConnectionReplicationActorInfo& ConnectionActorInfo = ConnectionActorInfoMap.FindOrAdd(Actor);
				if (ConnectionActorInfo.bDormantOnConnection == false)
				{
					bAllDormant = false;
					break;
				}
			}

			if (bAllDormant)
			{
				UE_CLOG(CVar_PiratesRepGraph_DisplayClientLevelStreaming > 0, LogPiratesReplicationGraph, Display, TEXT("CLIENTSTREAMING All AlwaysRelevant Actors Dormant on StreamingLevel %s for %s. Removing list."), *StreamingLevel.ToString(), *Params.ConnectionManager.GetName());
				AlwaysRelevantStreamingLevelsNeedingReplication.RemoveAtSwap(Idx, 1, false);
			}
			else
			{
				UE_CLOG(CVar_PiratesRepGraph_DisplayClientLevelStreaming > 0, LogPiratesReplicationGraph, Display, TEXT("CLIENTSTREAMING Adding always Actors on StreamingLevel %s for %s because it has at least one non dormant actor"), *StreamingLevel.ToString(), *Params.ConnectionManager.GetName());
				Params.OutGatheredReplicationLists.AddReplicationActorList(RepList);
			}
		}
		else
		{
			UE_LOG(LogPiratesReplicationGraph, Warning, TEXT("UPiratesReplicationGraphNode_AlwaysRelevant_ForConnection::GatherActorListsForConnection - empty RepList %s"), *Params.ConnectionManager.GetName());
		}

	}

#if WITH_GAMEPLAY_DEBUGGER
	if (GameplayDebugger)
	{
		ReplicationActorList.ConditionalAdd(GameplayDebugger);
	}
#endif
}

void UPiratesReplicationGraphNode_AlwaysRelevant_ForConnection::OnClientLevelVisibilityAdd(FName LevelName, UWorld* StreamingWorld)
{
	UE_CLOG(CVar_PiratesRepGraph_DisplayClientLevelStreaming > 0, LogPiratesReplicationGraph, Display, TEXT("CLIENTSTREAMING ::OnClientLevelVisibilityAdd - %s"), *LevelName.ToString());
	AlwaysRelevantStreamingLevelsNeedingReplication.Add(LevelName);
}

void UPiratesReplicationGraphNode_AlwaysRelevant_ForConnection::OnClientLevelVisibilityRemove(FName LevelName)
{
	UE_CLOG(CVar_PiratesRepGraph_DisplayClientLevelStreaming > 0, LogPiratesReplicationGraph, Display, TEXT("CLIENTSTREAMING ::OnClientLevelVisibilityRemove - %s"), *LevelName.ToString());
	AlwaysRelevantStreamingLevelsNeedingReplication.Remove(LevelName);
}

void UPiratesReplicationGraphNode_AlwaysRelevant_ForConnection::LogNode(FReplicationGraphDebugInfo& DebugInfo, const FString& NodeName) const
{
	DebugInfo.Log(NodeName);
	DebugInfo.PushIndent();
	LogActorRepList(DebugInfo, NodeName, ReplicationActorList);

	for (const FName& LevelName : AlwaysRelevantStreamingLevelsNeedingReplication)
	{
		UPiratesReplicationGraph* PiratesGraph = CastChecked<UPiratesReplicationGraph>(GetOuter());
		if (FActorRepListRefView* RepList = PiratesGraph->AlwaysRelevantStreamingLevelActors.Find(LevelName))
		{
			LogActorRepList(DebugInfo, FString::Printf(TEXT("AlwaysRelevant StreamingLevel List: %s"), *LevelName.ToString()), *RepList);
		}
	}

	DebugInfo.PopIndent();
}

// ------------------------------------------------------------------------------

UPiratesReplicationGraphNode_PlayerStateFrequencyLimiter::UPiratesReplicationGraphNode_PlayerStateFrequencyLimiter()
{
	bRequiresPrepareForReplicationCall = true;
}

void UPiratesReplicationGraphNode_PlayerStateFrequencyLimiter::PrepareForReplication()
{
	QUICK_SCOPE_CYCLE_COUNTER( UPiratesReplicationGraphNode_PlayerStateFrequencyLimiter_GlobalPrepareForReplication );

	ReplicationActorLists.Reset();
	ForceNetUpdateReplicationActorList.Reset();

	ReplicationActorLists.AddDefaulted();
	FActorRepListRefView* CurrentList = &ReplicationActorLists[0];
	CurrentList->PrepareForWrite();

	// We rebuild our lists of player states each frame. This is not as efficient as it could be but its the simplest way
	// to handle players disconnecting and keeping the lists compact. If the lists were persistent we would need to defrag them as players left.

	for (TActorIterator<APlayerState> It(GetWorld()); It; ++It)
	{
		APlayerState* PS = *It;
		if (IsActorValidForReplicationGather(PS) == false)
		{
			continue;
		}

		if (CurrentList->Num() >= TargetActorsPerFrame)
		{
			ReplicationActorLists.AddDefaulted();
			CurrentList = &ReplicationActorLists.Last(); 
			CurrentList->PrepareForWrite();
		}
		
		CurrentList->Add(PS);
	}	
}

void UPiratesReplicationGraphNode_PlayerStateFrequencyLimiter::GatherActorListsForConnection(const FConnectionGatherActorListParameters& Params)
{
	const int32 ListIdx = Params.ReplicationFrameNum % ReplicationActorLists.Num();
	Params.OutGatheredReplicationLists.AddReplicationActorList(ReplicationActorLists[ListIdx]);

	if (ForceNetUpdateReplicationActorList.Num() > 0)
	{
		Params.OutGatheredReplicationLists.AddReplicationActorList(ForceNetUpdateReplicationActorList);
	}	
}

void UPiratesReplicationGraphNode_PlayerStateFrequencyLimiter::LogNode(FReplicationGraphDebugInfo& DebugInfo, const FString& NodeName) const
{
	DebugInfo.Log(NodeName);
	DebugInfo.PushIndent();	

	int32 i=0;
	for (const FActorRepListRefView& List : ReplicationActorLists)
	{
		LogActorRepList(DebugInfo, FString::Printf(TEXT("Bucket[%d]"), i++), List);
	}

	DebugInfo.PopIndent();
}

// ------------------------------------------------------------------------------
void UReplicationGraphNode_AlwaysRelevant_ForTeam::GatherActorListsForConnection(const FConnectionGatherActorListParameters& Params)
{
    UPiratesReplicationConnectionGraph* PiratesConnManager = Cast<UPiratesReplicationConnectionGraph>(&Params.ConnectionManager);
    if (PiratesConnManager && PiratesConnManager->TeamId != 0)
    {
        UPiratesReplicationGraph* ReplicationGraph = Cast<UPiratesReplicationGraph>(GetOuter());
        if (TArray<TWeakObjectPtr<UPiratesReplicationConnectionGraph>>* TeamConnections = ReplicationGraph->TeamConnectionListMap.GetConnectionArrayForTeam(PiratesConnManager->TeamId))
        {
            ReplicationActorList.Reset();
            for (auto TeamMember : *TeamConnections)
            {
                if (TeamMember.IsValid()
                    && TeamMember->AlwaysRelevantForConnectionNode && !TeamMember->AlwaysRelevantForConnectionNode->IsPendingKill() && ::IsValid(TeamMember->AlwaysRelevantForConnectionNode))
                {
                    auto Pawn = TeamMember->AlwaysRelevantForConnectionNode->LastPawn;
                    if (Pawn && !Pawn->IsPendingKill())
                    {
                        FConnectionReplicationActorInfo& ConnectionActorInfo = Params.ConnectionManager.ActorInfoMap.FindOrAdd(Pawn);
                        ConnectionActorInfo.SetCullDistanceSquared(0.f);
                        ReplicationActorList.ConditionalAdd(Pawn);                        

                        Params.OutGatheredReplicationLists.AddReplicationActorList(ReplicationActorList);
                    }
                }                
                else
                {
                    //UE_LOG(LogPiratesReplicationGraph, Log, TEXT("GatherActorListsForConnection Remove %d"), PiratesConnManager->TeamId);
                    ReplicationGraph->TeamConnectionListMap.RemoveConnectionFromTeam(PiratesConnManager->TeamId, TeamMember);
                    break;
                }
            }
        }
    }
    else
    {
        Super::GatherActorListsForConnection(Params);
    }
}

void UReplicationGraphNode_AlwaysRelevant_ForTeam::GatherActorListsForConnectionDefault(const FConnectionGatherActorListParameters& Params)
{
    Super::GatherActorListsForConnection(Params);
}

//----------------------------------------
UReplicationGraphNode_AlwaysRelevant_WithPending::UReplicationGraphNode_AlwaysRelevant_WithPending()
{
    bRequiresPrepareForReplicationCall = true;
}

void UReplicationGraphNode_AlwaysRelevant_WithPending::PrepareForReplication()
{
    UPiratesReplicationGraph* ReplicationGraph = Cast<UPiratesReplicationGraph>(GetOuter());
    ReplicationGraph->HandlePendingActorsAndTeamRequests();
}

static bool IsHuman(const AActor* ViewTarget)
{
    if (auto PC = Cast<APiratesPlayerController>(ViewTarget))
    {
        return (Cast<AKMCharacter>(PC->GetPawn()) != nullptr);
    }
    return false;
}

void UReplicationGraphNode_GridSpatialization2D_Ocean::GatherActorListsForConnection(const FConnectionGatherActorListParameters& Params)
{
    // 海洋格子 人船都遍历
    Super::GatherActorListsForConnection(Params);

    UPiratesReplicationGraph* ReplicationGraph = Cast<UPiratesReplicationGraph>(GetOuter());
    if (!ReplicationGraph)
    {
        return;
    }
    
    UPiratesReplicationConnectionGraph* PiratesConnManager = Cast<UPiratesReplicationConnectionGraph>(&Params.ConnectionManager);
    if (!PiratesConnManager)
    {
        return;
    }

    if (!ReplicationGraph->bLimitPlayerNum && PiratesConnManager->DormantReplicationPlayers.Num() > 0)
    {
        for (AActor* Actor : PiratesConnManager->DormantReplicationPlayers)
        {
            if (Actor)
            {
                FConnectionReplicationActorInfo* ConnectionData = Params.ConnectionManager.ActorInfoMap.Find(Actor);
                if (ConnectionData)
                {
                    ConnectionData->bDormantOnConnection = false;
                }
            }
        }
        PiratesConnManager->DormantReplicationPlayers.Empty();
        PiratesConnManager->ReplicationPlayers.Empty();
    }
    
    if (ReplicationGraph->bLimitPlayerNum)
    {
        auto FrameNum = ReplicationGraph->GetReplicationGraphFrame();
        for (FActorRepListRawView& List : Params.OutGatheredReplicationLists.GetLists(EActorRepListTypeFlags::Default))
        {
            for (AActor* Actor : List)
            {
                if (!Actor || PiratesConnManager->DormantReplicationPlayers.Contains(Actor) || PiratesConnManager->ReplicationPlayers.Contains(Actor))
                {
                    continue;
                }
                
                APiratesHumanCharacter* Pawn = Cast<APiratesHumanCharacter>(Actor);
                if (Pawn && Pawn->GetController())
                {
                    FConnectionReplicationActorInfo* ConnectionData = Params.ConnectionManager.ActorInfoMap.Find(Actor);
                    if (ConnectionData && ConnectionData->GetCullDistanceSquared() > 0.f)
                    {
                        if (PiratesConnManager->ReplicationPlayers.Num() >= ReplicationGraph->ReplicatePlayerMaxNum)
                        {
                            ConnectionData->bDormantOnConnection = true;
                            PiratesConnManager->DormantReplicationPlayers.Add(Actor);
                        }
                        else
                        {                            
                            PiratesConnManager->ReplicationPlayers.Add(Actor);
                        }
                    }
                }
            }
        }
    }
}

void UReplicationGraphNode_GridSpatialization2D_Land::GatherActorListsForConnection(const FConnectionGatherActorListParameters& Params)
{
    for (const FNetViewer& CurView : Params.Viewers)
    {
        // 陆地格子 人遍历
        if (IsHuman(CurView.ViewTarget))
        {
            Super::GatherActorListsForConnection(Params);
        }
    }    
}

TArray<TWeakObjectPtr<UPiratesReplicationConnectionGraph>>* FTeamConnectionListMap::GetConnectionArrayForTeam(int32 TeamId)
{
    return Find(TeamId);
}

void FTeamConnectionListMap::AddConnectionToTeam(int32 TeamId, TWeakObjectPtr<UPiratesReplicationConnectionGraph> ConnManager)
{
    TArray<TWeakObjectPtr<UPiratesReplicationConnectionGraph>>& TeamList = FindOrAdd(TeamId);
    TeamList.Add(ConnManager);
}

void FTeamConnectionListMap::RemoveConnectionFromTeam(int32 TeamId, TWeakObjectPtr<UPiratesReplicationConnectionGraph> ConnManager)
{
    if (TArray<TWeakObjectPtr<UPiratesReplicationConnectionGraph>>* TeamList = Find(TeamId))
    {
        TeamList->RemoveSwap(ConnManager);
        //remove team if there's no one left
        if (TeamList->Num() == 0)
        {
            Remove(TeamId);
        }
    }
}

// console commands copied from shooter repgraph
// ------------------------------------------------------------------------------
void UPiratesReplicationGraph::PrintRepNodePolicies()
{
    UEnum* Enum = FindObject<UEnum>(ANY_PACKAGE, TEXT("EClassRepNodeMapping"));
    if (!Enum)
    {
        return;
    }

    GLog->Logf(TEXT("===================================="));
    GLog->Logf(TEXT("Pirates Replication Routing Policies"));
    GLog->Logf(TEXT("===================================="));

    for (auto It = ClassRepNodePolicies.CreateIterator(); It; ++It)
    {
        FObjectKey ObjKey = It.Key();

        EClassRepNodeMapping Mapping = It.Value();

        GLog->Logf(TEXT("%-40s --> %s"), *GetNameSafe(ObjKey.ResolveObjectPtr()), *Enum->GetNameStringByValue(static_cast<uint32>(Mapping)));
    }
}

FAutoConsoleCommandWithWorldAndArgs PiratesPrintRepNodePoliciesCmd(TEXT("PiratesRepGraph.PrintRouting"), TEXT("Prints how actor classes are routed to RepGraph nodes"),
    FConsoleCommandWithWorldAndArgsDelegate::CreateLambda([](const TArray<FString>& Args, UWorld* World)
{
    for (TObjectIterator<UPiratesReplicationGraph> It; It; ++It)
    {
        It->PrintRepNodePolicies();
    }
})
);

FAutoConsoleCommandWithWorldAndArgs ChangeFrequencyBucketsCmd(TEXT("PiratesRepGraph.FrequencyBuckets"), TEXT("Resets frequency bucket count."), FConsoleCommandWithWorldAndArgsDelegate::CreateLambda([](const TArray< FString >& Args, UWorld* World)
{
    int32 Buckets = 1;
    if (Args.Num() > 0)
    {
        LexTryParseString<int32>(Buckets, *Args[0]);
    }

    UE_LOG(LogPiratesReplicationGraph, Display, TEXT("Setting Frequency Buckets to %d"), Buckets);
    for (TObjectIterator<UReplicationGraphNode_ActorListFrequencyBuckets> It; It; ++It)
    {
        UReplicationGraphNode_ActorListFrequencyBuckets* Node = *It;
        Node->SetNonStreamingCollectionSize(Buckets);
    }
}));
