// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Avatar/GameAvatarComponentBase.h"
#include "Common.h"
#include "Game/Avatar/GameAvatarPartProcessNodeBase.h"
#include "TabFile/GameAvatarPartTabFile.h"
#include "TabFile/GameAvatarPartTypeTabFile.h"
#include "Shell/EngineExtShell.h"
#include "Game/Delegates/KMDelegateManager.h"
//#include "GameAvatarPartStaticMeshNode.h"
//#include "GameAvatarPartSkeletonMeshNode.h"
//#include "KMShipMeshMerge.h"

DEFINE_LOG_CATEGORY_STATIC(LogGameAvatarComponentBase, Log, All);

//////////////////////////////////////////////////////////////////////////

UAvatarAssetLoader::UAvatarAssetLoader(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer),
    GameAvatarComponentBase(nullptr),
    bInited(false)
{

}

void UAvatarAssetLoader::BeginDestroy()
{
//    UE_LOG(LogGameAvatarComponentBase, Log, TEXT("UAvatarAssetLoader[%p],BeginDestroy"), this);
    Uninit();
    Super::BeginDestroy();
}

bool UAvatarAssetLoader::Init(UGameAvatarComponentBase* ComponentBase)
{
    bInited = true;
    GameAvatarComponentBase = ComponentBase;
//    UE_LOG(LogGameAvatarComponentBase, Log, TEXT("UAvatarAssetLoader[%p],Init"), this);
    return true;
}


void UAvatarAssetLoader::Uninit()
{
    Clear();
}

bool UAvatarAssetLoader::LoadAssetsAsync(const TArray<FString>& Assets)
{
    double T1 = FPlatformTime::Seconds();
    if (!bInited)
    {
        return false;
    }
    TArray<FName> LoadingAssetNames;
    AsyncLoadHandlers.GetKeys(LoadingAssetNames);
    TArray<FName> PendingLoadAssetNames;
    // start new assets
    for (const auto& AssetName : Assets)
    {
        FName TempName(*AssetName);
        PendingLoadAssetNames.Emplace(TempName);
        UObject* Object = StaticFindObject(UObject::StaticClass(), nullptr, *AssetName);
        if (!Object)
        {
            TSharedPtr<FStreamableHandle>* Ret = AsyncLoadHandlers.Find(TempName);
            if (!Ret)
            {
                UE_LOG(LogGameAvatarComponentBase, Log, TEXT("UAvatarAssetLoader[%p],start load asset: %s"),this, *AssetName);
                TSharedPtr<FStreamableHandle> ptrHandle = AssetLoader.RequestAsyncLoad(FStringAssetReference(AssetName),
                    FStreamableDelegate::CreateUObject(this, &UAvatarAssetLoader::OnAssetLoadFinished), AsyncLoadPriority);
                if (ptrHandle.IsValid())
                {
                    AsyncLoadHandlers.Add(TempName, ptrHandle);
                }
            }
        }
    }
    // stop old unnessary asset
    for (const auto& AssetName : LoadingAssetNames)
    {
        if (PendingLoadAssetNames.Find(AssetName) < 0)
        {
            TSharedPtr<FStreamableHandle>* Ret = AsyncLoadHandlers.Find(AssetName);
            if (Ret && (*Ret).IsValid())
            {
                (*Ret)->CancelHandle();
                UE_LOG(LogGameAvatarComponentBase, Log, TEXT("UAvatarAssetLoader[%p],stop load asset: %s"), this, *AssetName.ToString());
            }
            AsyncLoadHandlers.Remove(AssetName);
        }
    }
    double T2 = FPlatformTime::Seconds();
    // if there is no more loading asset, trigger callback
    if (AsyncLoadHandlers.Num() <= 0 && GameAvatarComponentBase)
    {
        GameAvatarComponentBase->OnAsyncAssetsLoaded();
    }
    double T3 = FPlatformTime::Seconds();
    UE_LOG(LogGameAvatarComponentBase, Log, TEXT("UAvatarAssetLoader LoadAssetsAsync, part1 cost : %.5f, part2 cost : %.5f"), T2-T1, T3-T2);
    return true;
}



void UAvatarAssetLoader::Clear()
{
//    UE_LOG(LogGameAvatarComponentBase, Log, TEXT("UAvatarAssetLoader[%p],clear"), this);
    for (auto Iterator = AsyncLoadHandlers.CreateIterator(); Iterator; ++Iterator)
    {
        auto& ptrHandle = Iterator.Value();
        check(ptrHandle.IsValid());
        UE_LOG(LogGameAvatarComponentBase, Log, TEXT("UAvatarAssetLoader[%p],stop load asset: %s"), this, *Iterator.Key().ToString());
        ptrHandle->CancelHandle();
    }
    AsyncLoadHandlers.Empty();
    GameAvatarComponentBase = nullptr;
    bInited = false;
}

void UAvatarAssetLoader::OnVerifyAllAssetLoaded()
{
    if (!bInited)
    {
        return;
    }
    if (AsyncLoadHandlers.Num() > 0)
    {
        for (auto Iterator = AsyncLoadHandlers.CreateIterator(); Iterator; ++Iterator)
        {
            auto& ptrHandle = Iterator.Value();
            if (ptrHandle->HasLoadCompleted())
            {
                UE_LOG(LogGameAvatarComponentBase, Log, TEXT("UAvatarAssetLoader[%p],end load asset: %s"),this, *Iterator.Key().ToString());
                Iterator.RemoveCurrent();

            }
        }
        if (AsyncLoadHandlers.Num() <= 0 && GameAvatarComponentBase)
        {
            UE_LOG(LogGameAvatarComponentBase, Log, TEXT("UAvatarAssetLoader[%p],OnVerifyAllAssetLoaded"), this);
            GameAvatarComponentBase->OnAsyncAssetsLoaded();
        }
    }
}

void UAvatarAssetLoader::OnAssetLoadFinished()
{
    OnVerifyAllAssetLoaded();
}


//////////////////////////////////////////////////////////////////////////////////////////////////////


UGameAvatarComponentBase::UGameAvatarComponentBase(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , OwnerActorOfNode(nullptr)
    , AvatarAssetLoader(nullptr)
    , RootNode(nullptr)

{

}

UGameAvatarPartProcessNodeBase* UGameAvatarComponentBase::AddNode(
    UGameAvatarPartProcessNodeBase* Parent,
    const FName& PartName,
    const FName& DataKeyName,
    TSubclassOf<UGameAvatarPartProcessNodeBase> UC,
    bool PassDirtyToParent,
    bool PassDirtyToChildren,
    bool NeedSaveToTabFile)
{
    check(Parent);
    AActor* Owner = OwnerActorOfNode ? OwnerActorOfNode : GetOwner();
    UGameAvatarPartProcessNodeBase* NewNode = NewObject<UGameAvatarPartProcessNodeBase>(this, UC);
    NewNode->Init(Owner, DataKeyName, Parent, PassDirtyToParent, PassDirtyToChildren, NeedSaveToTabFile);

    if (PartName.IsValid() && DataKeyName.IsValid())
    {
        TPartNodeArray& NodeArray = NodeOfPartMap.FindOrAdd(PartName);
        NodeArray.AddUnique(NewNode);
    }

    return NewNode;
}

UGameAvatarPartProcessNodeBase* UGameAvatarComponentBase::AddRootNode()
{
    check(!RootNode);
    RootNode = NewObject<UGameAvatarPartProcessNodeBase>(GetOwner());
    return RootNode;
}

bool UGameAvatarComponentBase::AddPartByName(const FName& PartName, int PartID, bool bCommit, int nPriority, bool bMerged)
{
    if (!PartName.IsValid())
    {
        FMsg::Logf(__FILE__, __LINE__, TEXT("GameAvatar"), ELogVerbosity::Error,
            TEXT("AddPart failed, part name is invalid"));
        return false;
    }
    RemovePartByName(PartName, bCommit);

    if (PartID < 0)
    {
        return true;
    }

    auto Part = FGameAvatarPartTabFile::GetSingleton().Find(PartID);
    if (!Part)
    {
        FMsg::Logf(__FILE__, __LINE__, TEXT("GameAvatar"), ELogVerbosity::Error,
            TEXT("AddPart[%s] failed, can not find partid: %d"), *PartName.ToString(), PartID);
        return false;
    }

    TPartNodeArray* NodeArray = NodeOfPartMap.Find(PartName);
    if (!NodeArray)
    {
        FMsg::Logf(__FILE__, __LINE__, TEXT("GameAvatar"), ELogVerbosity::Error,
            TEXT("AddPart[%s] failed, can not find process node: %d"), *PartName.ToString(), PartID);
        return false;
    }

    // 因为这里两个数组都没几个元素，这里直接遍历了
    bool bRet = false;
    auto& DataArray = Part->Data;
    int iNodeCount = NodeArray->Num();
    int iDataCount = DataArray.Num();
    for (int ii=0; ii<iNodeCount; ii++)
    {
        bRet = false;
        auto Node = (*NodeArray)[ii];
        const FName& KeyName = Node->GetDataKeyName();
        for (int jj=0; jj<iDataCount; jj++)
        {
            if (DataArray[jj].Key == KeyName)
            {
                if (!Node->ApplyRawData(DataArray[jj].Value))
                {
                    FMsg::Logf(__FILE__, __LINE__, TEXT("GameAvatar"), ELogVerbosity::Error,
                        TEXT("AddPart[%s] failed, node[%s] process failed: %d"), *PartName.ToString(),
                        *KeyName.ToString(), PartID);
                    return false;
                }
				Node->SetPartID(PartID);
                Node->SetPartPriority(nPriority);
                Node->SetPartMergeFlag(bMerged);
                bRet = true;
                break;
            }
        }
    }

    ActivedParts.Add(PartName, Part);
    if (bCommit)
    {
        Commit();
    }
    return true;
}

bool UGameAvatarComponentBase::AddPartByType(int PartType, int PartID, bool bCommit)
{
    auto Data = FGameAvatarPartTypeTabFile::GetSingleton().Find(PartType);
    if (!Data)
    {
        FMsg::Logf(__FILE__, __LINE__, TEXT("GameAvatar"), ELogVerbosity::Warning,
            TEXT("AddPartByType failed, cannot find part type."));
        return false;
    }
    return AddPartByName(Data->PartName, PartID, bCommit);
}

bool UGameAvatarComponentBase::AddPartByID(int PartID, bool bCommit)
{
    auto Data = FGameAvatarPartTypeTabFile::GetSingleton().GetDataByPartID(PartID);
    if (!Data)
    {
        FMsg::Logf(__FILE__, __LINE__, TEXT("GameAvatar"), ELogVerbosity::Warning,
            TEXT("AddPartByID failed, cannot find part id."));
        return false;
    }
    return AddPartByName(Data->PartName, PartID, bCommit);
}

bool UGameAvatarComponentBase::RemovePartByName(const FName& PartName, bool bCommit)
{
    if (!PartName.IsValid())
    {
        FMsg::Logf(__FILE__, __LINE__, TEXT("GameAvatar"), ELogVerbosity::Error,
            TEXT("RemovePart failed, part name is invalid"));
        return false;
    }

    auto Part = ActivedParts.Find(PartName);
    if (!Part)
    {
        return false;
    }

    TPartNodeArray* NodeArray = NodeOfPartMap.Find(PartName);
    if (!NodeArray)
    {
        FMsg::Logf(__FILE__, __LINE__, TEXT("GameAvatar"), ELogVerbosity::Error,
            TEXT("RemovePart[%s] failed, cannot find nodes"), *PartName.ToString());
        return false;
    }

    // 因为这里两个数组都没几个元素，这里直接遍历了
    bool bRet = false;
    FString NullValue;
    auto& DataArray = (*Part)->Data;
    int iNodeCount = NodeArray->Num();
    int iDataCount = DataArray.Num();
    for (int ii = 0; ii < iNodeCount; ii++)
    {
        bRet = false;
        auto Node = (*NodeArray)[ii];
        if (!Node->ApplyRawData(NullValue))
        {
            Node->SetPartID(-1);
            const FName& KeyName = Node->GetDataKeyName();
            FMsg::Logf(__FILE__, __LINE__, TEXT("GameAvatar"), ELogVerbosity::Error,
                TEXT("RemovePart[%s] failed, node[%s] process failed"), *PartName.ToString(), *KeyName.ToString());
            return false;
        }
        Node->SetPartID(-1);
    }

    ActivedParts.Remove(PartName);
    if (bCommit)
    {
        Commit();
    }
    return false;
}

bool UGameAvatarComponentBase::RemovePartByType(int PartType, bool bCommit)
{
    auto Data = FGameAvatarPartTypeTabFile::GetSingleton().Find(PartType);
    if (!Data)
    {
        FMsg::Logf(__FILE__, __LINE__, TEXT("GameAvatar"), ELogVerbosity::Warning,
            TEXT("RemovePartByType failed, cannot find part type."));
        return false;
    }
    return RemovePartByName(Data->PartName, bCommit);
}

bool UGameAvatarComponentBase::RemovePartByID(int PartID, bool bCommit)
{
    auto Data = FGameAvatarPartTypeTabFile::GetSingleton().GetDataByPartID(PartID);
    if (!Data)
    {
        FMsg::Logf(__FILE__, __LINE__, TEXT("GameAvatar"), ELogVerbosity::Warning,
            TEXT("RemovePartByID failed, cannot find part id."));
        return false;
    }
    return RemovePartByName(Data->PartName, bCommit);
}

void UGameAvatarComponentBase::Refresh_Implementation()
{
    if (RootNode)
    {
        RootNode->Refresh(true, true, true);
    }
}
//
//void GetMesh(UGameAvatarPartProcessNodeBase* RootNode, TArray<USkeletalMesh*> &OutSkeletalMeshs, TArray<UStaticMesh*> &OutStaticMeshs, TArray<AActor*> &OutActors)
//{
//    TArray<UGameAvatarPartProcessNodeBase*> Childrens;
//    RootNode->GetChildren(Childrens, false);
//    for (int i = 0; i < Childrens.Num(); i++)
//    {
//        UGameAvatarPartProcessNodeBase* Child = Childrens[i];
//        GetMesh(Child, OutSkeletalMeshs, OutStaticMeshs, OutActors);
//        if (Child->IsA(UGameAvatarPartStaticMeshNode::StaticClass()))
//        {
//            UGameAvatarPartStaticMeshNode* StaticNode = Cast<UGameAvatarPartStaticMeshNode>(Child);
//            UStaticMesh* Mesh = StaticNode->GetStaticMesh();
//            if(Mesh)
//                OutStaticMeshs.Add(Mesh);
//        }
//        else if (Child->IsA(UGameAvatarPartSkeletonMeshNode::StaticClass()))
//        {
//            UGameAvatarPartSkeletonMeshNode* StaticNode = Cast<UGameAvatarPartSkeletonMeshNode>(Child);
//            USkeletalMesh* Mesh = StaticNode->GetSkeletalMesh();
//            if(Mesh)
//            OutSkeletalMeshs.Add(Mesh);
//        }
//        AActor* actor = Child->GetChildActor();
//        if (actor)
//            OutActors.Add(actor);
//    }
//}

void UGameAvatarComponentBase::Commit_Implementation()
{
    double T1 = FPlatformTime::Seconds();
    if (RootNode)
    {
        RootNode->Refresh(true, true, false);
    }
    double T2 = FPlatformTime::Seconds();

    if (OnCommitFinishDelegate.IsBound())
    {
        OnCommitFinishDelegate.Broadcast();
    }
    double T3 = FPlatformTime::Seconds();
    UE_LOG(LogGameAvatarComponentBase, Log, TEXT("UAvatarAssetLoader Commit, Refresh cost : %.2f ms, delegate cost : %.2f ms"), (T2 - T1) * 1000.f, (T3 - T2) * 1000.f);
 //   TArray<UStaticMesh*> OutStaticMeshs;
 //   TArray<USkeletalMesh*> OutSkeletalMeshs;
 //   TArray<AActor*> OutActors;
 //   GetMesh(RootNode, OutSkeletalMeshs, OutStaticMeshs, OutActors);

	//TArray<FSkeletalMergeParameter> SkeleParas;
	////search for skeletalmesh
	//TArray<UActorComponent*> ShipModelComs;

	//TArray<FTransform> InPutTrans;

	//if (OwnerActorOfNode)
	//{
	//	ShipModelComs = OwnerActorOfNode->K2_GetComponentsByClass(USkeletalMeshComponent::StaticClass());
	//	for (int32 KIndex = 0; KIndex < ShipModelComs.Num(); ++KIndex)
	//	{
	//		FSkeletalMergeParameter KPara;
	//		KPara.Skeletal = Cast<USkeletalMeshComponent>(ShipModelComs[KIndex])->SkeletalMesh;
	//		Cast<USkeletalMeshComponent>(ShipModelComs[KIndex])->SetVisibility(false);

	//		SkeleParas.Add(KPara);
	//	}

	//	UFunction* Test = OwnerActorOfNode->FindFunction(FName(TEXT("GetAnchorTransforms")));

	//	OwnerActorOfNode->ProcessEvent(Test, &InPutTrans);

	//}

	//TArray<FStaticMergeParameter> StaticParas;
	//int32 TransformIndex = 0;
	//for (int32 AIndex = 0; AIndex < OutActors.Num(); ++AIndex)
	//{
	//	TArray<UActorComponent*> Children;
	//	OutActors[AIndex]->GetComponents(Children);

	//	FString AnchorName = FString(TEXT("BP_Anchor"));

	//	if (!OutActors[AIndex]->GetName().Contains(AnchorName))
	//	{
	//		continue;
	//	}

	//	for (int32 CIndex = 0; CIndex < Children.Num(); ++CIndex)
	//	{
	//		if (Children[CIndex]->IsA(UStaticMeshComponent::StaticClass()))
	//		{
	//			if (InPutTrans.Num() > TransformIndex)
	//			{
	//				FStaticMergeParameter StaticPara;
	//				StaticPara.Static = Cast<UStaticMeshComponent>(Children[CIndex])->GetStaticMesh();
	//				Cast<UStaticMeshComponent>(Children[CIndex])->SetVisibility(false);

	//				StaticPara.Offset = InPutTrans[TransformIndex];
	//				TransformIndex++;

	//				StaticPara.BoneName = FName(TEXT("Point_Ship001"));
	//				StaticParas.Add(StaticPara);
	//			}
	//		}
	//	}
	//}

	//if (SkeleParas.Num() > 0 && StaticParas.Num() > 0)
	//{
	//	USkeletalMesh* ReturnSkeletal = FKMShipMeshMerge::GetSMMerge()->KMMergeStaticWithSkeleton(SkeleParas, StaticParas);

	//	USkeletalMeshComponent* SkeletalCom = NewObject<USkeletalMeshComponent>(OwnerActorOfNode, USkeletalMeshComponent::StaticClass());
	//	SkeletalCom->SetSkeletalMesh(ReturnSkeletal);
	//	SkeletalCom->RegisterComponentWithWorld(OwnerActorOfNode->GetWorld());
	//	OwnerActorOfNode->AddOwnedComponent(SkeletalCom);

	//	SkeletalCom->AttachToComponent(OwnerActorOfNode->GetRootComponent(), FAttachmentTransformRules::KeepRelativeTransform);
	//}

}

void UGameAvatarComponentBase::CommitAsync()
{
    if (RootNode && AvatarAssetLoader)
    {
        CollectResource();
        AvatarAssetLoader->LoadAssetsAsync(PendingLoadResources);
    }
}


UGameAvatarPartProcessNodeBase* UGameAvatarComponentBase::ApplyNodeRawData(const FName& PartName, const FName& DataKeyName, const FString& RawData)
{
    auto NodeArray = NodeOfPartMap.Find(PartName);
    if (!NodeArray)
    {
        return nullptr;
    }

    UGameAvatarPartProcessNodeBase* Ret = nullptr;
    int iCount = NodeArray->Num();
    for (int ii=0; ii<iCount; ii++)
    {
        if ((*NodeArray)[ii]->GetDataKeyName() == DataKeyName)
        {
            Ret = (*NodeArray)[ii];
			//Ret->SetPartID(-1);
            if (!Ret->ApplyRawData(RawData))
            {
				Ret->SetPartID(-1);
                return nullptr;
            }
        }
    }
    return Ret;
}

void UGameAvatarComponentBase::ForceLoadPartsMips()
{
    for (auto& PairArr : NodeOfPartMap)
    {
        for (auto& Node : PairArr.Value)
        {
            if (Node!=nullptr)
            {
                Node->SetForceStreaming();
            }
        }
    }
}

void UGameAvatarComponentBase::BeginPlay()
{
    Super::BeginPlay();
    AvatarAssetLoader = NewObject<UAvatarAssetLoader>();
    AvatarAssetLoader->Init(this);
}

void UGameAvatarComponentBase::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    Uninit();
    Super::EndPlay(EndPlayReason);
}

void UGameAvatarComponentBase::Uninit()
{
    if (AvatarAssetLoader)
    {
        AvatarAssetLoader->Uninit();
    }
    for (auto Iter = NodeOfPartMap.CreateConstIterator(); Iter; ++Iter)
    {
        auto& DataArray = Iter->Value;
        for (int ii = 0; ii < DataArray.Num(); ii++)
        {
            DataArray[ii]->Uninit();
        }
    }
}

void UGameAvatarComponentBase::CollectResource()
{
    if (RootNode)
    {
        TArray<UGameAvatarPartProcessNodeBase*> Childrens;
        RootNode->GetChildren(Childrens, true);
        PendingLoadResources.Empty();
        TPendingLoadResourceArray TempArray;
        for (const auto& Children : Childrens)
        {
            TempArray.Empty();
            Children->CollectResources(TempArray);
            PendingLoadResources.Append(TempArray);
        }
    }
}

void UGameAvatarComponentBase::OnAsyncAssetsLoaded()
{
    Commit();
}