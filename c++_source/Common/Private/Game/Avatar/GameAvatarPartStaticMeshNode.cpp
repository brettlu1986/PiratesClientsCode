// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Avatar/GameAvatarPartStaticMeshNode.h"
#include "Common.h"
#include "TabFile/Base/TabFileDataParamSerializer.h"
#include "Shell/EngineExtShell.h"

UGameAvatarPartStaticMeshNode::UGameAvatarPartStaticMeshNode(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , StaticMeshComponent(nullptr)
    , AutoCreateStaticMeshComponent(true)
    , TransformComponent(nullptr)
{
}

bool UGameAvatarPartStaticMeshNode::SetRawData_Implementation(const FString& In)
{  
    Reset();
    bool bRet = true;
    int iParseIndex = 0;
    const int TempLen = 2048;
    TCHAR Temp[TempLen] = {};
    int iInStringLen = In.Len();
    check(iInStringLen < TempLen);
    FCString::Strcpy(Temp, *In);
    Temp[iInStringLen] = LITERAL(TCHAR, ';');   // 防止最后没分号
    Temp[iInStringLen+1] = LITERAL(TCHAR, '\0');
    int iSize = iInStringLen + 2;
    for (int iStart = 0, iEnd=0; bRet && iEnd<iSize; iEnd++)
    {
        if (Temp[iEnd] == LITERAL(TCHAR, ';'))
        {
            Temp[iEnd] = LITERAL(TCHAR, '\0');
            if (iStart == iEnd || Temp[iStart] == Temp[iEnd])
            {
                continue;
            }

            switch (iParseIndex)
            {
            case 0:
                MeshPath = &Temp[iStart];
                break;
            case 1:
                bRet &= FTabFileDataParamHelper::Read(Location, &Temp[iStart]);
                break;
            case 2:
                bRet &= FTabFileDataParamHelper::Read(Rotation, &Temp[iStart]);
                break;
            case 3:
                bRet &= FTabFileDataParamHelper::Read(Scale, &Temp[iStart]);
                break;
            default:
                break;
            }
            ++iParseIndex;
            iStart = iEnd + 1;
        }
    }
    return bRet;
}

bool UGameAvatarPartStaticMeshNode::GetRawData_Implementation(FString& Out)
{
    FString TempLocation, TempRotation, TempScale;
    bool bRet = true;
    bRet &= FTabFileDataParamHelper::Write(Location, TempLocation);
    bRet &= FTabFileDataParamHelper::Write(Rotation, TempRotation);
    bRet &= FTabFileDataParamHelper::Write(Scale, TempScale);
    Out = FString::Printf(TEXT("%s;%s;%s;%s;"), *MeshPath, *TempLocation, *TempRotation, *TempScale);
    return bRet;
}

UStaticMeshComponent* UGameAvatarPartStaticMeshNode::CreateStaticMeshComponent()
{
    StaticMeshComponent = NewObject<UStaticMeshComponent>(Actor, UStaticMeshComponent::StaticClass());
    StaticMeshComponent->RegisterComponentWithWorld(Actor->GetWorld());
    Actor->AddOwnedComponent(StaticMeshComponent);
    return StaticMeshComponent;
}

void UGameAvatarPartStaticMeshNode::RefreshSelf_Implementation()
{
    if (!StaticMeshComponent && AutoCreateStaticMeshComponent)
    {
        CreateStaticMeshComponent();
    }
    if (StaticMeshComponent)
    {
        if (MeshPath.Len() > 0)
        {
            //FStringAssetReference AssetRef(MeshPath);
            //UObject* Object = AssetRef.TryLoad();
            UObject* Object = UEngineExtShell::StaticLoadObjectWithoutFlush(MeshPath);
            if (Object == nullptr)
            {
                FMsg::Logf(__FILE__, __LINE__, TEXT("GameAvatar"), ELogVerbosity::Error,
                    TEXT("UGameAvatarPartStaticMeshNode load failed: %s"), *MeshPath);
                return;
            }
            auto NewMesh = Cast<UStaticMesh>(Object);
            check(NewMesh);
            StaticMeshComponent->SetStaticMesh(NewMesh);
            if (TransformComponent)
            {
                FAttachmentTransformRules Rule(EAttachmentRule::KeepRelative, false);
                StaticMeshComponent->AttachToComponent(TransformComponent, Rule, SlotName.IsValid() ? SlotName:NAME_None);
            }
            StaticMeshComponent->SetRelativeLocationAndRotation(Location, Rotation);
            StaticMeshComponent->SetRelativeScale3D(Scale);
        }
        else
        {
            StaticMeshComponent->SetStaticMesh(nullptr);
        }
    }
}

void UGameAvatarPartStaticMeshNode::SetTransformComponent(USceneComponent* Component)
{
    TransformComponent = Component;
}

void UGameAvatarPartStaticMeshNode::Reset()
{
    MeshPath.Empty();
    Location = FVector::ZeroVector;
    Rotation = FRotator::ZeroRotator;
    Scale.X = 1.0f;
    Scale.Y = 1.0f;
    Scale.Z = 1.0f;
}

FVector UGameAvatarPartStaticMeshNode::GetWorldLocation() const
{
    FVector Ret = Location;
    if (TransformComponent)
    {
        Ret = TransformComponent->GetComponentToWorld().TransformPosition(Ret);
    }
    return Ret;
}

FRotator UGameAvatarPartStaticMeshNode::GetWorldRotation() const
{
    FRotator Ret = Rotation;
    if (TransformComponent)
    {
        Ret += TransformComponent->GetComponentRotation();
    }
    return Ret;
}

FVector UGameAvatarPartStaticMeshNode::GetWorldScale() const
{
    FVector Ret = Scale;
    if (TransformComponent)
    {
        Ret *= TransformComponent->GetComponentScale();
    }
    return Ret;
}

void UGameAvatarPartStaticMeshNode::GetAsset_Implementation(UGameAvatarPartProcessNodeBase* From)
{
    if (StaticMeshComponent && StaticMeshComponent->GetStaticMesh())
    {
        //StaticMeshComponent->SetVisibility(false);
        From->AddStaticMesh(StaticMeshComponent->GetStaticMesh(), SlotName, FTransform(Rotation, Location, Scale), StaticMeshComponent);
    }
    else if (MeshPath.Len() > 0)
    {
        //FStringAssetReference AssetRef(MeshPath);
        //UObject* Object = AssetRef.TryLoad();
        UObject* Object = UEngineExtShell::StaticLoadObjectWithoutFlush(MeshPath);
        if (Object == nullptr)
        {
            FMsg::Logf(__FILE__, __LINE__, TEXT("GameAvatar"), ELogVerbosity::Error,
                TEXT("UGameAvatarPartStaticMeshNode load failed: %s"), *MeshPath);
            return;
        }
        auto NewMesh = Cast<UStaticMesh>(Object);
        check(NewMesh);
        From->AddStaticMesh(NewMesh, SlotName, FTransform(Rotation, Location, Scale), nullptr);
    }
}

void UGameAvatarPartStaticMeshNode::CollectResources_Implementation(TArray<FString>& OutResources)
{
    if (!MeshPath.IsEmpty())
    {
        OutResources.Emplace(MeshPath);
    }
}