// Fill out your copyright notice in the Description page of Project Settings.

#include "Shell/CommonShell.h"
#include "Common.h"
#include "Game/GameCommon.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "OceanNavGridManager.h"
#include "Shell/CommonActorShell.h"
#include "Network//RPCNetworkManager.h"
#include "Util/LuaTableRef.h"
#include "Pawns/PiratesShipPawn.h"
#include "Util/MessageLuaUtil.h"
#include "Game/Battle/PiratesAreaTriggerManager.h"
#include "Game/PathNode/PathNodeFinder.h"
#include "CoreGlobals.h"
#include "GenericPlatform/GenericPlatformMisc.h"
#include "AI/AICoverPointsManager.h"
#include "Game/Lua/GameLuaRoot.h"
#include "Game/Battle/PiratesActorWeaponInhibitManager.h"
#include "AI/Vehicle/AIVehicleManager.h"
#include "AI/OceanGrid/AIOceanGridManagerRoot.h"
#include "AI/Smoke/AISmokeManager.h"

DEFINE_LOG_CATEGORY_STATIC(UCommonShellLog, Log, All)
UCommonShell::UCommonShell(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
}

UCommonShell* UCommonShell::GetCommon(UObject* WorldContextObject)
{
    return Cast<UCommonShell>(GetShell(WorldContextObject));
}

void UCommonShell::Init()
{
    Super::Init();

    UGameCommon* GameCommon = UGameCommon::Get(this);
    CommonActorShell = NewObject<UCommonActorShell>(this);
    CommonActorShell->Init(&GameCommon->GetActorSpawnContext(),
        GameCommon->GetRPCNetworkManager()->GetCodec());
}

void UCommonShell::Shutdown()
{
    CommonActorShell->Uninit();
    Super::Shutdown();
}

UInputManager* UCommonShell::GetInputManager()
{
    return UGameCommon::Get(this)->GetInputManager();
}

UGameDelegateManager* UCommonShell::GetGameDelegateManager()
{
    return Cast<UGameDelegateManager>(GetKMDelegateManager());
}

UHttpHelper* UCommonShell::GetHttpHelper()
{
    return UGameCommon::Get(this)->GetHttpHelper();
}

UOceanNavGridManager * UCommonShell::GetOceanNavGridManager()
{
    return UGameCommon::Get(this)->GetOceanNavGridManager();
}

UShipMovementComponent* UCommonShell::GetShipMovementComponent(AActor* Actor)
{
    APiratesShipPawn* ShipPawn = Cast<APiratesShipPawn>(Actor);
    if (ShipPawn)
    {
        return ShipPawn->GetShipMovementComponent();
    }
    return nullptr;
}

URPCNetworkManager* UCommonShell::GetRPCNetworkManager()
{
    auto Ret = UGameCommon::Get(this)->GetRPCNetworkManager();
    return Ret;
}

UPiratesAreaTriggerManager* UCommonShell::GetAreaTriggerManager()
{
    return UGameCommon::Get(this)->GetAreaTriggerManager();
}

UAICoverPointsManager* UCommonShell::GetAICoverPointsManager()
{
    return UGameCommon::Get(this)->GetAICoverPointsManager();
}

UAIDestructibleObjectManagerRoot* UCommonShell::GetAIDestructibleObjectManager()
{
    return UGameCommon::Get(this)->GetAIDestructibleObjectManager();
}

UPiratesActorTriggerGroupManager* UCommonShell::GetActorTriggerGroupManager()
{
    return UGameCommon::Get(this)->GetActorTriggerGroupManager();
}

//UPiratesGridTriggerManager* UCommonShell::GetGridTriggerManager()
//{
//    return UGameCommon::Get(this)->GetGridTriggerManager();
//}

UPiratesGridTypeManager* UCommonShell::GetGridTypeManager()
{
	return UGameCommon::Get(this)->GetGridTypeManager();
}

UPiratesPlayerGrid* UCommonShell::GetPiratesPlayerGrid()
{
    return UGameCommon::Get(this)->GetPiratesPlayerGrid();
}


UPathNodeFinder* UCommonShell::GetPathNodeFinder()
{
    return UGameCommon::Get(this)->GetPathNodeFinder();
}

void UCommonShell::SetGameStatus(EPiratesGameStatus Status)
{
    UGameCommon::Get(this)->SetGameStatus(Status);
}

const EPiratesGameStatus UCommonShell::GetGameStatus() const
{
    return UGameCommon::Get(this)->GetGameStatus();
}

float UCommonShell::GetConnectionTimeout()
{
    return UGameCommon::Get(this)->GetConnectionTimeout();
}


void UCommonShell::RequestExit(bool Force)
{
    GLog->Flush();
    FGenericPlatformMisc::RequestExit(Force);
}

UTemplateActorDataManager* UCommonShell::GetTemplateActorDataManager()
{
    return UGameCommon::Get(this)->GetTemplateActorDataManager();
}

UAIVehicleManager* UCommonShell::GetAIVehicleManager()
{
    return UGameCommon::Get(this)->GetAIVehicleManager();
}

UAIOceanGridManagerRoot* UCommonShell::GetAIOceanGridManager()
{
    return UGameCommon::Get(this)->GetAIOceanGridManager();
}

UAISmokeManager* UCommonShell::GetAISmokeManager()
{
    return UGameCommon::Get(this)->GetAISmokeManager();
}

void UCommonShell::SetTemplateActorDataManager(UTemplateActorDataManager* Manager)
{
    return UGameCommon::Get(this)->SetTemplateActorDataManager(Manager);
}

static void TestFunction(UObject* Context, FFrame& Stack, RESULT_DECL)
{

}

UObject* UCommonShell::CreateNewTestObject(int PropertyNum, int FunctionNum, int FunctionInputParamNum, int FunctionOutputParamNum)
{
    auto Outer = GetTransientPackage();
    auto ParentClass = UObject::StaticClass();
    UBlueprintGeneratedClass* Class = nullptr;

    static int ClassIndex = 0;
    static const TCHAR* TEST_CLASS_NAME_PREFIX = TEXT("TestClass");

    FString ClassName = FString::Printf(TEXT("%s_%d"), TEST_CLASS_NAME_PREFIX, ++ClassIndex);
    Class = NewObject<UBlueprintGeneratedClass>(Outer, *ClassName, RF_Public);
    Class->ClassFlags |= (ParentClass->ClassFlags & (CLASS_Inherit | CLASS_ScriptInherit | CLASS_CompiledFromBlueprint));
    Class->ClassConstructor = ParentClass->ClassConstructor;
    Class->ClassGeneratedBy = nullptr;
    Class->ClassAddReferencedObjects = ParentClass->ClassAddReferencedObjects;
    Class->PropertyLink = ParentClass->PropertyLink;
    Class->ClassWithin = ParentClass->ClassWithin;
    Class->ClassConfigName = ParentClass->ClassConfigName;
    Class->SetSuperStruct(ParentClass);
    Class->ClassCastFlags |= ParentClass->ClassCastFlags;

    const EObjectFlags ObjectFlags = RF_Public;
    for (int ii=0; ii<PropertyNum; ii++)
    {
        FString PropertyName = FString::Printf(TEXT("Property_%d"), ii);
        auto Property = new FIntProperty(Class, *PropertyName, ObjectFlags);
        Property->SetPropertyFlags(CPF_HasGetValueTypeHash);
        Property->SetPropertyFlags(CPF_Net | CPF_Transient | CPF_Edit);
        Property->SetFlags(RF_LoadCompleted);
        Class->AddCppProperty(Property);
    }

    for (int ii=0; ii<FunctionNum; ii++)
    {
        FString FunctionName = FString::Printf(TEXT("Function_%d"), ii);
        UFunction* NewFunction = NewObject<UFunction>(Class, *FunctionName, RF_Public);
        NewFunction->FunctionFlags |= (FUNC_Public | FUNC_Native);
        NewFunction->Next = Class->Children;
        Class->Children = NewFunction;

        for (int jj = 0; jj < FunctionInputParamNum; jj++)
        {
            FString PropertyName = FString::Printf(TEXT("Input_%d"), jj);
            auto Property = new FIntProperty(NewFunction, *PropertyName, ObjectFlags);
            Property->SetPropertyFlags(CPF_HasGetValueTypeHash);
            Property->SetPropertyFlags(CPF_Net | CPF_Transient | CPF_Edit | CPF_ConstParm | CPF_Parm);
            Property->SetFlags(RF_LoadCompleted);
            Property->Next = NewFunction->ChildProperties;
            NewFunction->ChildProperties = Property;
        }

        for (int jj = 0; jj < FunctionOutputParamNum; jj++)
        {
            FString PropertyName = FString::Printf(TEXT("Out_%d"), jj);
            auto Property = new FIntProperty(NewFunction, *PropertyName, ObjectFlags);
            Property->SetPropertyFlags(CPF_HasGetValueTypeHash);
            Property->SetPropertyFlags(CPF_Net | CPF_Transient | CPF_Edit | CPF_OutParm | CPF_Parm);
            Property->SetFlags(RF_LoadCompleted);
            Property->Next = NewFunction->ChildProperties;
            NewFunction->ChildProperties = Property;
        }

        Class->AddNativeFunction(*FunctionName, &TestFunction);
        Class->AddFunctionToFunctionMap(NewFunction, *FunctionName);
        NewFunction->Bind();
        NewFunction->StaticLink(true);
    }

    Class->Bind();
    Class->StaticLink(true);
    Class->GetDefaultObject();
    Class->UpdateCustomPropertyListForPostConstruction();

    FString ObjectName = FString::Printf(TEXT("TestObject_%d"), ClassIndex-1);
    return NewObject<UObject>(Outer, Class, *ObjectName);
}

bool UCommonShell::IsGMEnabled()
{
    return UGameCommon::Get(this)->IsGMEnabled();
}

bool UCommonShell::IsPreloadMap() const
{
    return UGameCommon::Get(this)->IsPreloadMap();
}

UU4LuaLib* UCommonShell::GetLuaLib()
{
    return UGameCommon::Get(this)->GetLuaRoot()->GetLib();
}

ULogReport* UCommonShell::GetLogReport()
{
    return UGameCommon::Get(this)->GetLogReport();
}

UPiratesActorWeaponInhibitManager* UCommonShell::GetWeaponInhibitManager()
{
    return UGameCommon::Get(this)->GetActorWeaponInhibitManager();
}

void UCommonShell::SetRemoteLuaRepository(const FString& URL)
{
    UGameCommon::SetRemoteLuaRepository(URL);
}

void UCommonShell::SetNetLogEnabled(bool Enabled)
{
    static ELogVerbosity::Type LogNetTrafficVerbosity = LogNetTraffic.GetVerbosity();
    static ELogVerbosity::Type LogRepTrafficVerbosity = LogRepTraffic.GetVerbosity();
    static ELogVerbosity::Type LogNetVerbosity = LogNet.GetVerbosity();
    static ELogVerbosity::Type LogRepVerbosity = LogRep.GetVerbosity();
    //static ELogVerbosity::Type LogPlayerControllerVerbosity = LogPlayerController.GetVerbosity();
    static ELogVerbosity::Type LogNetDormancyVerbosity = LogNetDormancy.GetVerbosity();

    if (Enabled)
    {
        LogNetTraffic.SetVerbosity(ELogVerbosity::VeryVerbose);
        LogRepTraffic.SetVerbosity(ELogVerbosity::VeryVerbose);
        LogNet.SetVerbosity(ELogVerbosity::Verbose);
        LogRep.SetVerbosity(ELogVerbosity::VeryVerbose);
        //LogPlayerController.SetVerbosity(ELogVerbosity::VeryVerbose);
        LogNetDormancy.SetVerbosity(ELogVerbosity::VeryVerbose);
    }
    else
    {
        LogNetTraffic.SetVerbosity(LogNetTrafficVerbosity);
        LogRepTraffic.SetVerbosity(LogRepTrafficVerbosity);
        LogNet.SetVerbosity(LogNetVerbosity);
        LogRep.SetVerbosity(LogRepVerbosity);
        //LogPlayerController.SetVerbosity(LogPlayerControllerVerbosity);
        LogNetDormancy.SetVerbosity(LogNetDormancyVerbosity);
    }
}

void UCommonShell::RecordSpawnActorFrameCounter()
{
    UGameCommon* GameCommon = UGameCommon::Get(this);
    GameCommon->RecordSpawnActorFrameCounter();
}
