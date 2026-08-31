// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "Builders/EditorBrushBuilder.h"
#include "SplinePointSource.h"
#include "SplineCylinderBuilder.generated.h"

UCLASS(MinimalAPI, autoexpandcategories = BrushSettings, EditInlineNew, meta = (DisplayName = "SplineCylinder"))
class USplineCylinderBuilder : public UBrushBuilder
{
public:
    GENERATED_BODY()

public:
    USplineCylinderBuilder(const FObjectInitializer& ObjectInitializer);
    ~USplineCylinderBuilder();

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = BrushSettings, meta = (MakeEditWidget = true))
    TArray<FVector> PolygonPoints;
    
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = BrushSettings)
    ASplinePointSource* SplineSource;

    /** Distance from base to tip of cone */
    UPROPERTY(EditAnywhere, Category = BrushSettings, meta = (ClampMin = "0.000001"))
    float Height;

    UPROPERTY()
    FName GroupName;

    //~ Begin UObject Interface
    virtual void PostEditChangeProperty(struct FPropertyChangedEvent& PropertyChangedEvent) override;
    //~ End UObject Interface

    /** UBrushBuilder interface */
    virtual void BeginBrush(bool InMergeCoplanars, FName InLayer) override;
    virtual bool EndBrush(UWorld* InWorld, ABrush* InBrush) override;
    virtual int32 GetVertexCount() const override;
    virtual FVector GetVertex(int32 i) const override;
    virtual int32 GetPolyCount() const override;
    virtual bool BadParameters(const FText& msg) override;
    virtual int32 Vertexv(FVector v) override;
    virtual int32 Vertex3f(float X, float Y, float Z) override;
    virtual void Poly3i(int32 Direction, int32 i, int32 j, int32 k, FName ItemName = NAME_None, bool bIsTwoSidedNonSolid = false) override;
    virtual void Poly4i(int32 Direction, int32 i, int32 j, int32 k, int32 l, FName ItemName = NAME_None, bool bIsTwoSidedNonSolid = false) override;
    virtual void PolyBegin(int32 Direction, FName ItemName = NAME_None) override;
    virtual void Polyi(int32 i) override;
    virtual void PolyEnd() override;
    virtual bool Build(UWorld* InWorld, ABrush* InBrush = NULL) override;
    //~ End UBrushBuilder Interface

    // @todo document
    virtual void BuildSplineCylinder(int32 Direction, const TArray<FVector>& InVertices, float InZ, FName Item);
};
