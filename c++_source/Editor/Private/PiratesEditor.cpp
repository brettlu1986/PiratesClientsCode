#include "PiratesEditor.h"
#include "KMCustomPropertyDetails.h"
#include "Components/SceneCaptureComponent.h"
#include "ActorDetailsDelegates.h"
#include "DetailLayoutBuilder.h"
#include "LevelEditor.h"
#include "FileHelpers.h"
#include "ContentBrowserModule.h"
#include "Modules/ModuleManager.h"
#include "AssetData.h"
#include "Kismet2/KismetEditorUtilities.h"

//yangjingzhao for 4.20 interrupt with editor.h in UnrealEd
class IPiratesEditorModule;

DECLARE_LOG_CATEGORY_CLASS(EditorLog1, Log, All)

class FPiratesEditorModule : public IPiratesEditorModule
{
private:
    virtual void StartupModule();
    virtual void ShutdownModule();

    virtual void InitCustomPropertyDetails();
    virtual void UpdateCustomData();

private:
    void AddMenuExtension(FMenuBuilder& Builder);
    void OnAssetSelectionChanged(const TArray<FAssetData>& NewSelection, bool bIsPrimaryBrowser);
    void ResaveSelectedPackagesWithCompilation();
    void ResaveSelectedPackagesWithoutCompilation();
    void ResaveSelectedPackages(bool bNeedCompile);

private:
    FKMCustomPropertyDetails CustomPropertyDetailTool;
    TArray<FAssetData> SelectedAssets;
    FDelegateHandle SelectionChangedHandle;
};

void FPiratesEditorModule::StartupModule()
{
    UpdateCustomData();
    InitCustomPropertyDetails();

    TSharedPtr<FExtender> MenuExtender = MakeShareable(new FExtender());
    MenuExtender->AddMenuExtension(
        "PiratesTools",
        EExtensionHook::After,
        NULL,
        FMenuExtensionDelegate::CreateRaw(this, &FPiratesEditorModule::AddMenuExtension));

    FLevelEditorModule& LevelEditorModule = FModuleManager::LoadModuleChecked<FLevelEditorModule>("LevelEditor");
    LevelEditorModule.GetMenuExtensibilityManager()->AddExtender(MenuExtender);

    FContentBrowserModule& ContentBrowserModule = FModuleManager::LoadModuleChecked<FContentBrowserModule>(TEXT("ContentBrowser"));
    FContentBrowserModule::FOnAssetSelectionChanged& AssetSelectionChangedDelegate = ContentBrowserModule.GetOnAssetSelectionChanged();
    SelectionChangedHandle = AssetSelectionChangedDelegate.AddRaw(this, &FPiratesEditorModule::OnAssetSelectionChanged);
}

void FPiratesEditorModule::ShutdownModule()
{
    FContentBrowserModule* ContentBrowserModule = FModuleManager::GetModulePtr<FContentBrowserModule>(TEXT("ContentBrowser"));
    if (ContentBrowserModule)
    {
        FContentBrowserModule::FOnAssetSelectionChanged& AssetSelectionChangedDelegate = ContentBrowserModule->GetOnAssetSelectionChanged();
        AssetSelectionChangedDelegate.Remove(SelectionChangedHandle);
    }
}

void FPiratesEditorModule::InitCustomPropertyDetails()
{
    OnExtendActorDetails.AddLambda([&](IDetailLayoutBuilder& DetailBuilder, const FGetSelectedActors& GetSelectedActors)
    {
        const TArray< TWeakObjectPtr<AActor> >& Actors = GetSelectedActors.Execute();
        CustomPropertyDetailTool.AddCodeViewCategory(DetailBuilder, Actors);
    });
}

void FPiratesEditorModule::UpdateCustomData()
{
#if WITH_METADATA
    UClass* SCCClass = USceneCaptureComponent::StaticClass();
    FProperty* SFSProperty = SCCClass->FindPropertyByName(FName(TEXT("ShowFlagSettings")));
    UMetaData* MetaData = SCCClass->GetOutermost()->GetMetaData();
    MetaData->SetValue(SFSProperty->GetUPropertyWrapper(), TEXT("Category"), TEXT("ShowFlagSettings"));
#endif
}

void FPiratesEditorModule::AddMenuExtension(FMenuBuilder& Builder)
{
    Builder.AddMenuEntry(
        FText::FromString("ResaveSelectedPackagesWithCompilation"),
        FText::FromString("Resave selected packages with compilation."),
        FSlateIcon(FEditorStyle::GetStyleSetName(), "LevelEditor.Build"),
        FUIAction(FExecuteAction::CreateRaw(this, &FPiratesEditorModule::ResaveSelectedPackagesWithCompilation))
    );

    Builder.AddMenuEntry(
        FText::FromString("ResaveSelectedPackagesWithoutCompilation"),
        FText::FromString("Resave selected packages without compilation."),
        FSlateIcon(FEditorStyle::GetStyleSetName(), "LevelEditor.Build"),
        FUIAction(FExecuteAction::CreateRaw(this, &FPiratesEditorModule::ResaveSelectedPackagesWithoutCompilation))
    );
}

void FPiratesEditorModule::OnAssetSelectionChanged(const TArray<FAssetData>& NewSelection, bool bIsPrimaryBrowser)
{
    SelectedAssets = NewSelection;
}

void FPiratesEditorModule::ResaveSelectedPackagesWithCompilation()
{
    ResaveSelectedPackages(true);
}

void FPiratesEditorModule::ResaveSelectedPackagesWithoutCompilation()
{
    ResaveSelectedPackages(false);
}

void FPiratesEditorModule::ResaveSelectedPackages(bool bNeedCompile)
{
    int Num = SelectedAssets.Num();
    if (Num > 0)
    {
        TArray<UPackage*> PackagesToSave;
        for (int32 ii = 0; ii < Num; ii++)
        {
            FAssetData& AssetData = SelectedAssets[ii];
            UPackage* Package = AssetData.GetPackage();
            if (Package)
            {
                PackagesToSave.AddUnique(Package);
            }

            if (bNeedCompile)
            {
                auto BP = Cast<UBlueprint>(AssetData.GetAsset());
                if (BP)
                {
                    FKismetEditorUtilities::CompileBlueprint(BP);
                }
            }
        }

        if (PackagesToSave.Num() > 0)
        {
            FEditorFileUtils::PromptForCheckoutAndSave(PackagesToSave, false, false);
        }
    }
}

IMPLEMENT_GAME_MODULE(FPiratesEditorModule, Editor);