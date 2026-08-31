// Fill out your copyright notice in the Description page of Project Settings.

#include "SplineCylinderBuilder.h"
#include "PiratesEditor.h"
#include "Editor/UnrealEd/Public/Editor.h"
#include "Editor/UnrealEd/Public/SnappingUtils.h"
#include "Editor/EditorStyle/Public/EditorStyleSet.h"
#include "Runtime/Slate/Public/Widgets/Notifications/SNotificationList.h"
#include "Runtime/Slate/Public/Framework/Notifications/NotificationManager.h"
#include "Engine/Polys.h"
#include "GameFramework/Volume.h"
#include "Engine/Selection.h"

#define LOCTEXT_NAMESPACE "SplineCylinderBuilder"

static void bspValidateBrush(UModel* Brush, bool ForceValidate, bool DoStatusUpdate)
{
    check(Brush != nullptr);
    Brush->Modify();
    if (ForceValidate || !Brush->Linked)
    {
        Brush->Linked = 1;
        for (int32 i = 0; i < Brush->Polys->Element.Num(); i++)
        {
            Brush->Polys->Element[i].iLink = i;
        }
        int32 n = 0;
        for (int32 i = 0; i < Brush->Polys->Element.Num(); i++)
        {
            FPoly* EdPoly = &Brush->Polys->Element[i];
            if (EdPoly->iLink == i)
            {
                for (int32 j = i + 1; j < Brush->Polys->Element.Num(); j++)
                {
                    FPoly* OtherPoly = &Brush->Polys->Element[j];
                    if
                        (OtherPoly->iLink == j
                            &&	OtherPoly->Material == EdPoly->Material
                            &&	OtherPoly->TextureU == EdPoly->TextureU
                            &&	OtherPoly->TextureV == EdPoly->TextureV
                            &&	OtherPoly->PolyFlags == EdPoly->PolyFlags
                            && (OtherPoly->Normal | EdPoly->Normal) > 0.9999)
                    {
                        float Dist = FVector::PointPlaneDist(OtherPoly->Vertices[0], EdPoly->Vertices[0], EdPoly->Normal);
                        if (Dist > -0.001 && Dist < 0.001)
                        {
                            OtherPoly->iLink = i;
                            n++;
                        }
                    }
                }
            }
        }
        // 		UE_LOG(LogBSPOps, Log,  TEXT("BspValidateBrush linked %i of %i polys"), n, Brush->Polys->Element.Num() );
    }

    // Build bounds.
    Brush->BuildBound();
}

struct FConstructorStatics
    {
        FName NAME_SplineCylinder;
        TArray<FVector> DefaultVertices;
        FConstructorStatics()
            : NAME_SplineCylinder(TEXT("Spline Cylinder"))
        {
            DefaultVertices.Add(FVector(0, -10800, 0));
            DefaultVertices.Add(FVector(-12000, 10000, 0));
            DefaultVertices.Add(FVector(12000, 10000, 0));
        }
    };
    static FConstructorStatics ConstructorStatics;

USplineCylinderBuilder::USplineCylinderBuilder(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
    // Structure to hold one-time initialization
    

    Height = 200.0f;
    GroupName = ConstructorStatics.NAME_SplineCylinder;
    BitmapFilename = TEXT("Btn_SplineCylinder");
    ToolTip = TEXT("BrushBuilderName_SplineCylinder");
}

USplineCylinderBuilder::~USplineCylinderBuilder()
{
    if (SplineSource)
    {
        SplineSource = nullptr;
    }
}

void USplineCylinderBuilder::PostEditChangeProperty(FPropertyChangedEvent & PropertyChangedEvent)
{
    if (!GIsTransacting)
    {
        // Rebuild brush on property change
        ABrush* Brush = Cast<ABrush>(GetOuter());
        if (Brush)
        {
            Brush->bInManipulation = (PropertyChangedEvent.ChangeType == EPropertyChangeType::Interactive);
            Build(Brush->GetWorld(), Brush);
        }
    }
}

bool USplineCylinderBuilder::Build(UWorld * InWorld, ABrush * InBrush)
{
    AVolume* Volume = Cast<AVolume>(GetOuter());
    if (SplineSource == nullptr)
    {
        TArray<AActor*> VolumeAttachedActors;
        Volume->GetAttachedActors(VolumeAttachedActors);
        for (auto& AttachedActor : VolumeAttachedActors)
        {
            if (ASplinePointSource* Source = Cast<ASplinePointSource>(AttachedActor))
            {
                SplineSource = Source;
                break;
            }
        }
        if (SplineSource == nullptr)
        {
            SplineSource = InWorld->SpawnActor<ASplinePointSource>(ASplinePointSource::StaticClass(), Volume->GetTransform());
            auto& DefaultPoints = (PolygonPoints.Num() >= 3) ? PolygonPoints : ConstructorStatics.DefaultVertices;
            SplineSource->Spline->ClearSplinePoints();
            for (auto& Point : DefaultPoints)
            {
                SplineSource->Spline->AddSplinePoint(Point, ESplineCoordinateSpace::Local);
            }
        }
    }
    if (!SplineSource->IsAttachedTo(Volume))
    {
        GEditor->ParentActors(Volume, SplineSource, NAME_None);
    }
    if (SplineSource)
    {
        TArray<AActor*> VolumeAttachedActors;
        Volume->GetAttachedActors(VolumeAttachedActors);
        for (auto& AttachedActor : VolumeAttachedActors)
        {
            if (ASplinePointSource* Source = Cast<ASplinePointSource>(AttachedActor))
            {
                if (SplineSource == Source)
                {
                    continue;
                }
                else
                {
                    SplineSource->Spline->MarkRenderStateDirty();
                    SplineSource->Spline->MarkRenderDynamicDataDirty();
                    SplineSource->Spline->MarkRenderTransformDirty();
                    Source->RemoveFromRoot();
                    Source->Destroy();
                }
            }
        }
        SplineSource->SetActorRelativeLocation(FVector::ZeroVector);
    }
    auto& InterpCurvePoints = SplineSource->Spline->SplineCurves.Position.Points;
    PolygonPoints.Empty();
    for (auto& InterpCurvePoint : InterpCurvePoints)
    {
        PolygonPoints.Add(InterpCurvePoint.OutVal);
    }
    BeginBrush(false, GroupName);
    BuildSplineCylinder(+1, PolygonPoints, Height, FName(TEXT("Body")));
    return EndBrush(InWorld, InBrush);
}

void USplineCylinderBuilder::BuildSplineCylinder(int32 Direction, const TArray<FVector>& InVertices, float InZ, FName Item)
{
    int32 n = GetVertexCount();
    int32 InSides = InVertices.Num();

    for (int32 i = 0; i < InSides; i++)
    {
        for (int32 j = -1; j < 2; j += 2) 
        {
            Vertex3f(InVertices[i].X, InVertices[i].Y, j*InZ / 2);
        }  
    }
        

    // Polys.
    for (int32 i = 0; i < InSides; i++)
    {
        Poly4i(Direction, n + i * 2, n + i * 2 + 1, n + ((i * 2 + 3) % (2 * InSides)), n + ((i * 2 + 2) % (2 * InSides)), FName(TEXT("Wall")));
    }

    for (int32 j = -1; j < 2; j += 2)
    {
        PolyBegin(j, FName(TEXT("Cap")));
        for (int32 i = 0; i < InSides; i++)
        {
            Polyi(i * 2 + (1 - j) / 2);
        }
        PolyEnd();
    }
}


void USplineCylinderBuilder::BeginBrush(bool InMergeCoplanars, FName InLayer)
{
    Layer = InLayer;
    MergeCoplanars = InMergeCoplanars;
    Vertices.Empty();
    Polys.Empty();
}

bool USplineCylinderBuilder::EndBrush(UWorld* InWorld, ABrush* InBrush)
{
    //!!validate
    check(InWorld != nullptr);
    ABrush* BuilderBrush = (InBrush != nullptr) ? InBrush : InWorld->GetDefaultBrush();

    // Ensure the builder brush is unhidden.
    BuilderBrush->SetHidden(false);
    BuilderBrush->bHiddenEdLayer = false;

    AActor* Actor = GEditor->GetSelectedActors()->GetTop<AActor>();
    FVector Location;
    if (InBrush == nullptr)
    {
        Location = Actor ? Actor->GetActorLocation() : BuilderBrush->GetActorLocation();
    }
    else
    {
        Location = InBrush->GetActorLocation();
    }

    UModel* Brush = BuilderBrush->Brush;
    if (Brush == nullptr)
    {
        return true;
    }

    Brush->Modify();
    BuilderBrush->Modify();

    FRotator Temp(0.0f, 0.0f, 0.0f);
    FSnappingUtils::SnapToBSPVertex(Location, FVector::ZeroVector, Temp);
    BuilderBrush->SetActorLocation(Location, false);
    BuilderBrush->SetPivotOffset(FVector::ZeroVector);

    // Try and maintain the materials assigned to the surfaces. 
    TArray<FPoly> CachedPolys;
    UMaterialInterface* CachedMaterial = nullptr;
    if (Brush->Polys->Element.Num() == Polys.Num())
    {
        // If the number of polygons match we assume its the same shape.
        CachedPolys.Append(Brush->Polys->Element);
    }
    else if (Brush->Polys->Element.Num() > 0)
    {
        // If the polygons have changed check if we only had one material before. 
        CachedMaterial = Brush->Polys->Element[0].Material;
        if (CachedMaterial != NULL)
        {
            for (auto Poly : Brush->Polys->Element)
            {
                if (CachedMaterial != Poly.Material)
                {
                    CachedMaterial = NULL;
                    break;
                }
            }
        }
    }

    // Clear existing polys.
    Brush->Polys->Element.Empty();

    const bool bUseCachedPolysMaterial = CachedPolys.Num() > 0;
    int32 CachedPolyIdx = 0;
    for (TArray<FBuilderPoly>::TIterator It(Polys); It; ++It)
    {
        if (It->Direction < 0)
        {
            for (int32 i = 0; i < It->VertexIndices.Num() / 2; i++)
            {
                Exchange(It->VertexIndices[i], It->VertexIndices.Last(i));
            }
        }

        FPoly Poly;
        Poly.Init();
        Poly.ItemName = It->ItemName;
        Poly.Base = Vertices[It->VertexIndices[0]];
        Poly.PolyFlags = It->PolyFlags;

        // Try and maintain the polygons material where possible
        Poly.Material = (bUseCachedPolysMaterial) ? CachedPolys[CachedPolyIdx++].Material : CachedMaterial;

        for (int32 j = 0; j < It->VertexIndices.Num(); j++)
        {
            new(Poly.Vertices) FVector(Vertices[It->VertexIndices[j]]);
        }
        if (Poly.Finalize(BuilderBrush, 1) == 0)
        {
            new(Brush->Polys->Element)FPoly(Poly);
        }
    }

    if (MergeCoplanars)
    {
        GEditor->bspMergeCoplanars(Brush, 0, 1);
        bspValidateBrush(Brush, 1, 1);
    }
    Brush->Linked = 1;
    bspValidateBrush(Brush, 0, 1);
    Brush->BuildBound();

    GEditor->RedrawLevelEditingViewports();
    GEditor->SetPivot(BuilderBrush->GetActorLocation(), false, true);

    BuilderBrush->ReregisterAllComponents();

    return true;
}

int32 USplineCylinderBuilder::GetVertexCount() const
{
    return Vertices.Num();
}

FVector USplineCylinderBuilder::GetVertex(int32 i) const
{
    return Vertices.IsValidIndex(i) ? Vertices[i] : FVector::ZeroVector;
}

int32 USplineCylinderBuilder::GetPolyCount() const
{
    return Polys.Num();
}

bool USplineCylinderBuilder::BadParameters(const FText& Msg)
{
    if (NotifyBadParams)
    {
        FFormatNamedArguments Arguments;
        Arguments.Add(TEXT("Msg"), Msg);
        FNotificationInfo Info(FText::Format(LOCTEXT("BadParameters", "Bad parameters in brush builder\n{Msg}"), Arguments));
        Info.bFireAndForget = true;
        Info.ExpireDuration = Msg.IsEmpty() ? 4.0f : 6.0f;
        Info.bUseLargeFont = Msg.IsEmpty();
        Info.Image = FEditorStyle::GetBrush(TEXT("MessageLog.Error"));
        FSlateNotificationManager::Get().AddNotification(Info);
    }
    return 0;
}

int32 USplineCylinderBuilder::Vertexv(FVector V)
{
    int32 Result = Vertices.Num();
    new(Vertices)FVector(V);

    return Result;
}

int32 USplineCylinderBuilder::Vertex3f(float X, float Y, float Z)
{
    int32 Result = Vertices.Num();
    new(Vertices)FVector(X, Y, Z);
    return Result;
}

void USplineCylinderBuilder::Poly3i(int32 Direction, int32 i, int32 j, int32 k, FName ItemName, bool bIsTwoSidedNonSolid)
{
    new(Polys)FBuilderPoly;
    Polys.Last().Direction = Direction;
    Polys.Last().ItemName = ItemName;
    new(Polys.Last().VertexIndices)int32(i);
    new(Polys.Last().VertexIndices)int32(j);
    new(Polys.Last().VertexIndices)int32(k);
    Polys.Last().PolyFlags = PF_DefaultFlags | (bIsTwoSidedNonSolid ? (PF_TwoSided | PF_NotSolid) : 0);
}

void USplineCylinderBuilder::Poly4i(int32 Direction, int32 i, int32 j, int32 k, int32 l, FName ItemName, bool bIsTwoSidedNonSolid)
{
    new(Polys)FBuilderPoly;
    Polys.Last().Direction = Direction;
    Polys.Last().ItemName = ItemName;
    new(Polys.Last().VertexIndices)int32(i);
    new(Polys.Last().VertexIndices)int32(j);
    new(Polys.Last().VertexIndices)int32(k);
    new(Polys.Last().VertexIndices)int32(l);
    Polys.Last().PolyFlags = PF_DefaultFlags | (bIsTwoSidedNonSolid ? (PF_TwoSided | PF_NotSolid) : 0);
}

void USplineCylinderBuilder::PolyBegin(int32 Direction, FName ItemName)
{
    new(Polys)FBuilderPoly;
    Polys.Last().ItemName = ItemName;
    Polys.Last().Direction = Direction;
    Polys.Last().PolyFlags = PF_DefaultFlags;
}

void USplineCylinderBuilder::Polyi(int32 i)
{
    new(Polys.Last().VertexIndices)int32(i);
}


void USplineCylinderBuilder::PolyEnd()
{

}

#undef LOCTEXT_NAMESPACE