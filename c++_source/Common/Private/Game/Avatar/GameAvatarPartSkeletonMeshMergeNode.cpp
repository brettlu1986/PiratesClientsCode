// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Avatar/GameAvatarPartSkeletonMeshMergeNode.h"
#include "Common.h"
#include "Game/Avatar/GameAvatarPartSkeletonMeshNode.h"
#include "Shell/CommonShell.h"
#include "Game/Merge/KMCharacterMeshMerge.h"
#include "Shell/EngineExtShell.h"
#include "SkeletalMeshMerge.h"
#include "KMCharacter.h"

#define USE_MERGE_SKELETON_MESH

TArray<FString> HairURODistanceFactorThresholds;

DEFINE_LOG_CATEGORY_STATIC(UGameAvatarPartSkeletonMeshMergeNodeLog, Log, All);

int32 CVarMergeCharacterVal = 0;
FAutoConsoleVariableRef CVarMergeSkeletalMesh(
    TEXT("pir.MergeCharacter"),
	CVarMergeCharacterVal,
    TEXT("[Pir] Pirates’ way to merge. 0 : Not Merge; 1 : Merge")
);

int32 CVarDefaultEngineMergeChar = 0;
FAutoConsoleVariableRef CVarDefaultMergeSkeletalMesh(
	TEXT("pir.DefaultMergeChar"),
	CVarDefaultEngineMergeChar,
	TEXT("[Pir] Pirates’ use default way to merge. 0 : Not Merge; 1 : Merge")
);

UGameAvatarPartSkeletonMeshMergeNode::UGameAvatarPartSkeletonMeshMergeNode(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , RootSkeleton(nullptr)
    , bMergeSkeletalMesh(true)
	, bClearRootComponentMesh(false)
{
	HairCopyPoseAB = FString(TEXT("/Game/Game/CharacterEx/AnimBlueprint/AB_HairCopyPose.AB_HairCopyPose_C"));
	bMergedFirstTime = true;
    bForceStreaming = false;
}

void UGameAvatarPartSkeletonMeshMergeNode::RefreshSelf_Implementation()
{
	if (!RootComponent) return;
    RootComponent->bForceMipStreaming = bForceStreaming;
    for (auto& SkeletalMeshComponent : SkeletalMeshComponents)
    {
        if (SkeletalMeshComponent)
        {
            SkeletalMeshComponent->bForceMipStreaming = bForceStreaming;
        }
    }
	bool bUseParentBound = true;

	// get the dicision by project configuration; bMergeSkeletalmesh only used in ffa(not self, others);
	//out of ffa, (or self in ffa game) should not use meshmerging
	bool bMerging = bMergeSkeletalMesh;

	// do not merge if it is the player
	APlayerController* Conroller = GetWorld()->GetFirstPlayerController();
	if (Conroller && (Actor == Conroller->GetPawnOrSpectator() || Actor->GetAttachParentActor() == Conroller->GetPawnOrSpectator()))
	{
		bMerging = false;
		bUseParentBound = false;
	}

	// debug
	//bMerging = true;
	// ~

	// for the main character, dont use parent bound
	RootComponent->bUseAttachParentBound = bUseParentBound;

	if (bMerging && CVarDefaultEngineMergeChar <= 0)
	{
		bMerging = false;
	}

	if (RootComponent->SkeletalMesh && !RootSkeleton)
	{
		RootSkeleton = RootComponent->SkeletalMesh->Skeleton;
	}
	//root component tag
	if (!RootComponent->ComponentTags.Contains(FName(TEXT("SkeletalRoot"))))
	{
		RootComponent->ComponentTags.Add(FName(TEXT("SkeletalRoot")));
	}

	Meshes.Empty();
	UnMergesMeshes.Empty();

	//gather meshes which need merge; we use NeedMergeMeshNum to save nums of mesh shouled be merged
	//but we actually won't merge when character is refreshed in game. with this, we avoid to loading meshes not actually merged.
	int32 NeedMergeMeshNum = 0;

	ParaPairs.Empty();

	TArray<int32> PartIDs;
	int iCount = Children.Num();
	for (int ii = 0; ii < iCount; ii++)
	{
		UGameAvatarPartSkeletonMeshNode* MeshNode = Cast<UGameAvatarPartSkeletonMeshNode>(Children[ii]);
		if (MeshNode && MeshNode->GetMeshPath().Len() > 0)
		{
            if (bMerging && MeshNode->GetPartMergeFlag())
            {
				NeedMergeMeshNum++;
                //FStringAssetReference AssetRef(MeshNode->GetMeshPath());
                //UObject* Object = AssetRef.TryLoad();

				//if haved merged once; we just deal with unmerged meshes; merged bodies won't change in ffa. only equipment changed.
				//so we can avoid this loading mesh. 'cause bodies won't be merged in ffa game, they won't change
				if (bMergedFirstTime)
				{
					USkeletalMesh* LoadedMergeMesh = RefreshLoadMesh(MeshNode);
                    auto Param = MeshNode->GetMaterialParam();
                    if (!Param.SlotName.IsEmpty() && !Param.ValueStr.IsEmpty())
                    { 
						for (FSkeletalMaterial Mat : LoadedMergeMesh->Materials)
						{
							FString SlotNameStr = Mat.MaterialSlotName.ToString();
							if (SlotNameStr.Contains(Param.SlotName))
							{
								ParaPairs.Add(FCustomizeParameterPair(SlotNameStr, Param.ParameterName, Param.ParaType, Param.ValueStr));
							}
						}
                        //ParaPairs.Add(Param);
                    }
					Meshes.Add(LoadedMergeMesh);
					PartIDs.Add(MeshNode->GetPartID());
				}
            }
            else
            {
				if (MeshNode->GetSlotName().ToString() != FString(TEXT("")))
				{
					USkeletalMesh* LoadedUnMergeMesh = RefreshLoadMesh(MeshNode);

					FUnMergedSkeletalMeshPart UnmergePart;
					UnmergePart.Priority = MeshNode->GetPartPriority();
					UnmergePart.SkeletalMesh = LoadedUnMergeMesh;
					UnmergePart.Socketname = MeshNode->GetSlotName();
					UnMergesMeshes.Add(UnmergePart);
                    auto Param = MeshNode->GetMaterialParam();
                    if (!Param.SlotName.IsEmpty() && !Param.ValueStr.IsEmpty())
                    {
						for (FSkeletalMaterial Mat : LoadedUnMergeMesh->Materials)
						{
							FString SlotNameStr = Mat.MaterialSlotName.ToString();
							if (SlotNameStr.Contains(Param.SlotName))
							{
								ParaPairs.Add(FCustomizeParameterPair(SlotNameStr, Param.ParameterName, Param.ParaType, Param.ValueStr));
							}
						}
                        //ParaPairs.Add(Param);
                    }
				}
				else
				{
					UE_LOG(UGameAvatarPartSkeletonMeshMergeNodeLog, Error, TEXT("Don't have socket name for unmerged part %s."), *MeshNode->GetMeshPath());
				}
				
            }
			//used for merge skeletal mesh section
		}
	}

	// if there are meshes to be merged(only in game . ffa need use this)
	if (NeedMergeMeshNum > 0)
	{
		//if haved merged once; we just deal with unmerged meshes; merged bodies won't change in ffa. only equipment changed.
		if (!bMergedFirstTime)
		{
			if (UnMergesMeshes.Num())
			{
				UseUnMergedMesh(UnMergesMeshes);
			}
		}
		else
		{
			// if meshes are ready to be merged
			// pirates' way to merge
			if (CVarMergeCharacterVal)
			{
				double StartTime = FPlatformTime::Seconds();

				// create textures for merging and collect source textures
				MergedTextures.Empty();
				SourceTextures.Empty();

				FKMCharacterMeshMerge::Get().PrepareTextures(MergedTextures, SourceTextures, Meshes, 0);

				// asynchronously merge source textures to merged textures
				TFunction<FMergingResult()> MergingTextures = [&]()
				{
					return FKMCharacterMeshMerge::Get().KMMergeSkeletal(MergedTextures, SourceTextures, Meshes, PartIDs);
				};
				ResultFuture = Async(EAsyncExecution::ThreadPool, MoveTemp(MergingTextures));

				// set timer to wait for the merging result
				FTimerDelegate FinalizeMergeDelegate = FTimerDelegate::CreateUObject(this, &UGameAvatarPartSkeletonMeshMergeNode::FinalizeMerge);
				GetWorld()->GetTimerManager().SetTimer(TimerHandle, FinalizeMergeDelegate, 0.2f, true, 0.1f);

				UE_LOG(UGameAvatarPartSkeletonMeshMergeNodeLog, Log, TEXT("[XSJ] Merge skeleton meshes : %f ms."),
					(FPlatformTime::Seconds() - StartTime)*1000.0f);

			}
			else // default engine merge
			{
				EngineDefaultMerge(Meshes);
			}

			//set bMergedFirstTime tobe  false; when merge mesh first time
			bMergedFirstTime = false;
		}
	}
	//always use master pose when out of game
	else if (UnMergesMeshes.Num())
	{
		UseMasterPose(UnMergesMeshes);
	}
}

static void FinishMerge(USkeletalMeshComponent* InRootComponent, TArray<USkeletalMeshComponent*>& SkeletalMeshComponents, USkeletalMesh* MergedMesh)
{	
	auto AnimIns = InRootComponent->GetAnimInstance();
	auto Montage = AnimIns->GetCurrentActiveMontage();

	if (InRootComponent->VisibilityBasedAnimTickOption != EVisibilityBasedAnimTickOption::OnlyTickMontagesWhenNotRendered)
	{
		if (InRootComponent->VisibilityBasedAnimTickOption == EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones)
		{
			UE_LOG(UGameAvatarPartSkeletonMeshMergeNodeLog, Log, TEXT("[XSJ] Switch from AlwaysTickPoseAndRefreshBones to OnlyTickPoseWhenRendered"));
		}
		InRootComponent->VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickMontagesWhenNotRendered;
	}

	// set skeletal mesh
	if (InRootComponent->SkeletalMesh)
	{
		MergedMesh->Skeleton = InRootComponent->SkeletalMesh->Skeleton;
	}

	if (!InRootComponent->ComponentTags.Contains(FName(TEXT("MergedMainBody"))))
	{
		InRootComponent->ComponentTags.Add(FName(TEXT("MergedMainBody")));
	}

	InRootComponent->SetSkeletalMesh(MergedMesh);

	int CharacterDrawDis = AKMCharacter::GetCharacterDrawDis();
	InRootComponent->LDMaxDrawDistance = CharacterDrawDis;
	InRootComponent->CachedMaxDrawDistance = CharacterDrawDis;
	InRootComponent->SetVisibility(true);

	InRootComponent->MarkRenderStateDirty();

	//reset montage to play
	AnimIns = InRootComponent->GetAnimInstance();
	AnimIns->Montage_Play(Montage);
}

void UGameAvatarPartSkeletonMeshMergeNode::FinalizeMerge()
{
	if (ResultFuture.IsReady())
	{
		// cancel the timer
		GetWorld()->GetTimerManager().ClearTimer(TimerHandle);

		
		FMergingResult MergingResult = ResultFuture.Get(); 

		//auto& Meshes = MergingResult.SrcMeshes;

		if (FKMCharacterMeshMerge::Get().FinalizeMerge(MergingResult))
		{
			FinishMerge(RootComponent, SkeletalMeshComponents, MergingResult.SKMesh);
			
			RootComponent->OverrideMaterials.Empty();
			ComponentCustomize(RootComponent);

			if (UnMergesMeshes.Num())
			{
				UseUnMergedMesh(UnMergesMeshes);
			}

			//clean saved data
			MergedTextures.Empty();
			SourceTextures.Empty();
			Meshes.Empty();
		}
		else
		{
			UE_LOG(UGameAvatarPartSkeletonMeshMergeNodeLog, Error, TEXT("[XSJ] Pirates' Character Merging Failed."));
			EngineDefaultMerge(MergingResult.SrcMeshes);
		}

	}
}

void UGameAvatarPartSkeletonMeshMergeNode::EngineDefaultMerge(TArray<USkeletalMesh*>& InSrcMeshes)
{
	UE_LOG(UGameAvatarPartSkeletonMeshMergeNodeLog, Log, TEXT("[XSJ] Fallback to engine default skeletal mesh merging."));

	//auto& Meshes = InSrcMeshes;
	
	// get a new mesh
	USkeletalMesh* NewMesh = NewObject<USkeletalMesh>(Actor, USkeletalMesh::StaticClass());
	check(NewMesh);
	NewMesh->Skeleton = RootSkeleton;

	// do engine default merge
	TArray<FSkelMeshMergeSectionMapping> SkeletonSections;
	FSkeletalMeshMerge MeshMerger(NewMesh, InSrcMeshes, SkeletonSections, 0);
	if (MeshMerger.DoMerge())
	{
		// the materials of source meshes are likely different from each other,
		// so we need to reassign the material list.
		TArray<FSkeletalMaterial> NewMaterials;
		for (int32 i = 0; i < Meshes.Num(); i++)
		{
			for (int32 j = 0; j < Meshes[i]->Materials.Num(); j++)
			{
				NewMaterials.AddUnique(Meshes[i]->Materials[j]);
			}
		}
		NewMesh->Materials = NewMaterials;

		FinishMerge(RootComponent, SkeletalMeshComponents, NewMesh);

		//set override material for customize
		RootComponent->OverrideMaterials.Empty();
		ComponentCustomize(RootComponent);
		
	}

	if (UnMergesMeshes.Num())
	{
		UseUnMergedMesh(UnMergesMeshes);
	}

	//clean saved data
	MergedTextures.Empty();
	SourceTextures.Empty();
	Meshes.Empty();

}

void UGameAvatarPartSkeletonMeshMergeNode::UseMasterPose(TArray<FUnMergedSkeletalMeshPart>& InSrcMeshes)
{
	if (RootComponent->ComponentTags.Contains(FName(TEXT("MergedMainBody"))))
	{
		RootComponent->ComponentTags.Remove(FName(TEXT("MergedMainBody")));
	}

	// just for fail-safe, this should not be intended
	//auto& Meshes = InSrcMeshes;
	for (int ii = 0; ii < SkeletalMeshComponents.Num(); ii++)
	{
		SkeletalMeshComponents[ii]->DestroyComponent(true);
	}
	SkeletalMeshComponents.Empty();

	// master pose needs this because root is invisible
	RootComponent->VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;


	int DistanceVar = AKMCharacter::GetCharacterDrawDis();
	// hide root 
	RootComponent->SetVisibility(false);

	FBoxSphereBounds Bounds;
	for (auto It = InSrcMeshes.CreateIterator(); It; ++It)
	{
		USkeletalMesh* Mesh = It->SkeletalMesh;



		USkeletalMeshComponent* NewComponent = NewObject<USkeletalMeshComponent>(Actor, USkeletalMeshComponent::StaticClass());
		NewComponent->LDMaxDrawDistance = DistanceVar;
		NewComponent->CachedMaxDrawDistance = DistanceVar;
		NewComponent->RegisterComponentWithWorld(Actor->GetWorld());
		Actor->AddOwnedComponent(NewComponent);
		NewComponent->AttachToComponent(RootComponent, FAttachmentTransformRules::KeepRelativeTransform);
		NewComponent->SetSkeletalMesh(Mesh, false);
		NewComponent->SetCollisionEnabled(ECollisionEnabled::NoCollision);
		if (CheckIsHairMesh(Mesh))
		{
			TSubclassOf<UAnimInstance> AnimClass = LoadClass<UAnimInstance>(nullptr, *HairCopyPoseAB, nullptr, LOAD_None, nullptr);
			NewComponent->SetAnimationMode(EAnimationMode::AnimationBlueprint);
			NewComponent->SetAnimInstanceClass(AnimClass);

			UROForHair(NewComponent);
		}
		else
		{
			NewComponent->SetMasterPoseComponent(RootComponent);
		}

		NewComponent->bUseAttachParentBound = true;
		NewComponent->SetSingleSampleShadowFromStationaryLights(true);
		Bounds = Bounds + NewComponent->CalcBounds(FTransform());

		ComponentCustomize(NewComponent);

		SkeletalMeshComponents.Add(NewComponent);
	}
	
	UnMergesMeshes.Empty();
}

void UGameAvatarPartSkeletonMeshMergeNode::UseUnMergedMesh(TArray<FUnMergedSkeletalMeshPart>& InSrcMeshes)
{
	//unregister all unmerged mesh
	for (int32 SIndex = 0; SIndex < SkeletalMeshComponents.Num(); ++SIndex)
	{
		if (!SkeletalMeshComponents[SIndex]->ComponentTags.Contains(FName(TEXT("MergedMainBody"))))
		{
			SkeletalMeshComponents[SIndex]->DestroyComponent(true);
			SkeletalMeshComponents.RemoveAt(SIndex);
			SIndex--;
		}
	}

	int DistanceVar = AKMCharacter::GetCharacterDrawDis();

	for (int32 PIndex = 0; PIndex < InSrcMeshes.Num(); ++PIndex)
	{
		FName SocketName = InSrcMeshes[PIndex].Socketname;
		USkeletalMesh* Mesh = InSrcMeshes[PIndex].SkeletalMesh;
		USkeletalMeshComponent* NewComponent = nullptr;
		if (SocketName == FName(TEXT("Bip001-Head")))
		{
			
			int32 PartPriority = (int32)InSrcMeshes[PIndex].Priority;

			NewComponent = NewObject<USkeletalMeshComponent>(Actor, USkeletalMeshComponent::StaticClass());
			NewComponent->LDMaxDrawDistance = DistanceVar;
			NewComponent->CachedMaxDrawDistance = DistanceVar;
			NewComponent->RegisterComponentWithWorld(Actor->GetWorld());
			Actor->AddOwnedComponent(NewComponent);
			NewComponent->SetSkeletalMesh(Mesh, false);
			FTransform SocketTrans = NewComponent->GetSocketTransform(SocketName, ERelativeTransformSpace::RTS_Component);

			if (CheckIsHairMesh(Mesh))
			{
				TSubclassOf<UAnimInstance> AnimClass = LoadClass<UAnimInstance>(nullptr, *HairCopyPoseAB, nullptr, LOAD_None, nullptr);
				NewComponent->SetAnimationMode(EAnimationMode::AnimationBlueprint);
				NewComponent->SetAnimInstanceClass(AnimClass);

				NewComponent->AttachToComponent(RootComponent, FAttachmentTransformRules::KeepRelativeTransform);

				UROForHair(NewComponent);
			}
			else
			{
				NewComponent->SetRelativeTransform(SocketTrans.Inverse());
				NewComponent->AttachToComponent(RootComponent, FAttachmentTransformRules::KeepRelativeTransform, SocketName);
			}

			Mesh->Skeleton = RootComponent->SkeletalMesh->Skeleton;

			NewComponent->SetCollisionEnabled(ECollisionEnabled::NoCollision);
			NewComponent->SetSingleSampleShadowFromStationaryLights(true);
			NewComponent->bUseAttachParentBound = true;

			//set priority
			FString PriorityStr = FString(TEXT("Priority=")) + FString::FromInt((int32)PartPriority);
			NewComponent->ComponentTags.Add(FName(*PriorityStr));

			SkeletalMeshComponents.Add(NewComponent);
		}
		else {
			NewComponent = UseUnmergeMasterPose(&InSrcMeshes[PIndex]);
		}

		ComponentCustomize(NewComponent);

		if (NewComponent)
		{
			SkeletalMeshComponents.Add(NewComponent);
		}

	}

	UnMergesMeshes.Empty();
}

USkeletalMeshComponent* UGameAvatarPartSkeletonMeshMergeNode::UseUnmergeMasterPose(FUnMergedSkeletalMeshPart* Part)
{
	int DistanceVar = AKMCharacter::GetCharacterDrawDis();

	USkeletalMesh* Mesh = Part->SkeletalMesh;
	int32 PartPriority = (int32)Part->Priority;

	USkeletalMeshComponent* NewComponent = NewObject<USkeletalMeshComponent>(Actor, USkeletalMeshComponent::StaticClass());
	NewComponent->LDMaxDrawDistance = DistanceVar;
	NewComponent->RegisterComponentWithWorld(Actor->GetWorld());
	Actor->AddOwnedComponent(NewComponent);
	NewComponent->SetSkeletalMesh(Mesh, false);
	NewComponent->AttachToComponent(RootComponent, FAttachmentTransformRules::KeepRelativeTransform);

	Mesh->Skeleton = RootComponent->SkeletalMesh->Skeleton;

	NewComponent->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	NewComponent->SetMasterPoseComponent(RootComponent);
	NewComponent->SetSingleSampleShadowFromStationaryLights(true);
	NewComponent->bUseAttachParentBound = true;

	//set priority
	FString PriorityStr = FString(TEXT("Priority=")) + FString::FromInt((int32)PartPriority);
	NewComponent->ComponentTags.Add(FName(*PriorityStr));

	return NewComponent;
}

bool UGameAvatarPartSkeletonMeshMergeNode::CheckIsHairMesh(USkeletalMesh* InMesh)
{
	if (!InMesh)
	{
		return false;
	}

	for (int32 mIndex = 0; mIndex < InMesh->Materials.Num(); ++mIndex)
	{
		FString MatSlotName = InMesh->Materials[mIndex].MaterialSlotName.ToString();
		if (MatSlotName.ToLower().Equals(FString(TEXT("hair"))))
		{
			return true;
		}
	}

	return false;
}

bool UGameAvatarPartSkeletonMeshMergeNode::CheckIsHeadMesh(USkeletalMesh* InMesh)
{
	if (!InMesh)
	{
		return false;
	}

	for (int32 mIndex = 0; mIndex < InMesh->Materials.Num(); ++mIndex)
	{
		FString MatSlotName = InMesh->Materials[mIndex].MaterialSlotName.ToString();
		if (MatSlotName.ToLower().Equals(FString(TEXT("face"))))
		{
			return true;
		}
	}

	return false;
}

void UGameAvatarPartSkeletonMeshMergeNode::UROForHair(USkeletalMeshComponent* InCom)
{
#if 1
	if (HairURODistanceFactorThresholds.Num() == 0)
	{
		IConsoleVariable* CVarURODistance = IConsoleManager::Get().FindConsoleVariable(TEXT("pir.URODistanceFactorThresholds"));

		FString CVarValue = CVarURODistance->GetString();
		CVarValue.ParseIntoArray(HairURODistanceFactorThresholds, TEXT(","));
	}
	if (1)
	{
		check(HairURODistanceFactorThresholds.Num());

		InCom->bEnableUpdateRateOptimizations = true;
		InCom->OnAnimUpdateRateParamsCreated.BindLambda([](FAnimUpdateRateParameters* URParam) {
			URParam->BaseVisibleDistanceFactorThesholds.Empty();
			for (auto& Val : HairURODistanceFactorThresholds)
			{
				URParam->BaseVisibleDistanceFactorThesholds.Add(FMath::Square(FCString::Atof(*Val) / 2));
			}
		});
		/* 改用其他方式
		if (InCom->IsRegistered())
		{
			InCom->RefreshUpdateRateParams();
		}*/
	}
#endif
}

void UGameAvatarPartSkeletonMeshMergeNode::ComponentCustomize(USkeletalMeshComponent* InCom)
{
	uint8 MatIndex = 0;
	for (FSkeletalMaterial Mat : InCom->SkeletalMesh->Materials)
	{
		UMaterialInstanceDynamic* MatInstDy = InCom->CreateDynamicMaterialInstance(MatIndex, Mat.MaterialInterface);
		FString MatSlotName = Mat.MaterialSlotName.ToString();
		for (FCustomizeParameterPair Pair : ParaPairs)
		{
			if (MatSlotName.Equals(Pair.SlotName))
			{
				switch (Pair.ParaType)
				{
					case ECustomizeParaType::Para_Color:
					{
						//parse vector from str;
						FString ValueStr = Pair.ValueStr;
						FLinearColor ColorVec = FLinearColor::Black;
						ColorVec.InitFromString(Pair.ValueStr);
						MatInstDy->SetVectorParameterValue(FName(*Pair.ParameterName), ColorVec);
					
					}
					break;

					default:
						break;
				}

				break;
			}
		}

		MatIndex++;
	}
}

USkeletalMesh* UGameAvatarPartSkeletonMeshMergeNode::RefreshLoadMesh(UGameAvatarPartSkeletonMeshNode* MeshNode)
{
	UObject* Object = UEngineExtShell::StaticLoadObjectWithoutFlush(MeshNode->GetMeshPath());

	if (Object == nullptr)
	{
		FMsg::Logf(__FILE__, __LINE__, TEXT("GameAvatar"), ELogVerbosity::Error,
			TEXT("UGameAvatarPartSkeletonMeshMergeNode load mesh failed: %s"), *MeshNode->GetMeshPath());
		return nullptr;
	}
	UE_LOG(UGameAvatarPartSkeletonMeshMergeNodeLog, Log, TEXT("Merge skeleton load %s finished."), *MeshNode->GetMeshPath());

	auto SkeletonVisualAsset = Cast<USkeletalMesh>(Object);
	check(SkeletonVisualAsset);
	SetMeshMaterial(SkeletonVisualAsset, MeshNode->GetMaterialPath());

    if (bForceStreaming)
    {
        for (auto& Material : SkeletonVisualAsset->Materials)
        {
            if (Material.MaterialInterface)
            {
                TArray<UTexture*> UsedTextures;
                Material.MaterialInterface->GetUsedTextures(UsedTextures, EMaterialQualityLevel::Num, true, ERHIFeatureLevel::Num, true);
                for (auto UsedTexture : UsedTextures)
                {
                    auto Texture2D = Cast<UTexture2D>(UsedTexture);
                    if (Texture2D)
                    {
                        Texture2D->bForceMiplevelsToBeResident = true;
                        Texture2D->WaitForStreaming();
                    }
                }
            }
        }
    }

	return SkeletonVisualAsset;
}

void UGameAvatarPartSkeletonMeshMergeNode::SetMeshMaterial_Implementation(USkeletalMesh* SkeletalMesh, const FString& InMaterialPath)
{

}

bool UGameAvatarPartSkeletonMeshMergeNode::CheckSrcMeshValidity(const TArray<USkeletalMesh*>& InMeshes)
{
	bool bOk = true;
	for (auto& Mesh : InMeshes)
	{
		if (!Mesh->NeedCPUData(1))
		{
			bOk = false;
			UE_LOG(UGameAvatarPartSkeletonMeshMergeNodeLog, Error, TEXT("[XSJ] %s needs CPUAccess."), *Mesh->GetName());
		}
	}
	return bOk;
}

void UGameAvatarPartSkeletonMeshMergeNode::SetForceStreaming()
{
    bForceStreaming = true;
}
