// Fill out your copyright notice in the Description page of Project Settings.

#include "Components/LocalOceanComponent.h"
#include "Common.h"
#include "KismetProceduralMeshLibrary.h"


ULocalOceanComponent::ULocalOceanComponent(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer)
{
    // Ticking enabled.
    PrimaryComponentTick.bCanEverTick = true;
    PrimaryComponentTick.bStartWithTickEnabled = true;
    PrimaryComponentTick.TickGroup = TG_PrePhysics;

    // In case of being created as a default object.
    if (this->GetOwner() == nullptr)
    {
        return;
    }
    
    // Create and attach the procedural mesh component.
    ProceduralMesh = this->CreateDefaultSubobject<UProceduralMeshComponent>(TEXT("ProceduralMesh"));
    ProceduralMesh->SetupAttachment(GetOwner()->GetRootComponent());
    ProceduralMesh->SetAbsolute(false, true, false);
}

void ULocalOceanComponent::BeginPlay()
{   
    Super::BeginPlay();

    // In case of being created as a default object.
    if (this->GetOwner() == nullptr)
    {
        SetEnabled(false);
        return;
    }

    
    SetEnabled(this->Enabled);
}

void ULocalOceanComponent::TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction)
{
    Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

    if (UKismetSystemLibrary::IsDedicatedServer(this) || !Enabled)
    {
        return;
    }    

    DeltaTime *= TimeScale;

    if (CurrentHeightField == HeightField0)
    {
        CurrentHeightField = HeightField1;
        CurrentHeightFieldV = HeightFieldV1;

        PreviousHeightField = HeightField0;
        PreviousHeightFieldV = HeightFieldV0;
    }
    else
    {
        CurrentHeightField = HeightField0;
        CurrentHeightFieldV = HeightFieldV0;

        PreviousHeightField = HeightField1;
        PreviousHeightFieldV = HeightFieldV1;
    }

    OffsetX = (this->GetOwner()->GetActorLocation().X - RecentLocationX) / CELL_SIZE;
    OffsetY = (this->GetOwner()->GetActorLocation().Y - RecentLocationY) / CELL_SIZE;

    RecentLocationX = this->GetOwner()->GetActorLocation().X;
    RecentLocationY = this->GetOwner()->GetActorLocation().Y;

    
    this->Simulate(DeltaTime);
    this->UpdateMesh(DeltaTime);

    const FVector MaskVector = FVector(1.0f, 1.0f, 0);
    ProceduralMesh->SetWorldLocation(ProceduralMesh->GetComponentLocation() * MaskVector);
}

void ULocalOceanComponent::Simulate(float DeltaTime)
{    
    const float MAX_DELTA_TIME = 0.067f;

    // Avoid bad simulation caused by super long frames.
    DeltaTime = FMath::Min(DeltaTime, MAX_DELTA_TIME);


    // Create the height/v field of the last frame but samples are located at current positions.
    for (int y = 0; y < HEIGHT_FIELD_SIZE; y++)
    {
        for (int x = 0; x < HEIGHT_FIELD_SIZE; x++)
        {
            CurrentHeightField[y][x] = BilinearReadArray(PreviousHeightField, x + OffsetX, y + OffsetY);
            CurrentHeightFieldV[y][x] = BilinearReadArray(PreviousHeightFieldV, x + OffsetX, y + OffsetY);
        }
    }

    // Simulates velocity.
    // Use these to sacrifice some sample so we can avoid array bound check.
    int ymin = 1;
    int ymax = HEIGHT_FIELD_SIZE - 2;
    int xmin = 1;
    int xmax = HEIGHT_FIELD_SIZE - 2;
    for (int y = ymin; y <= ymax; y++)
    {
        for (int x = xmin; x <= xmax; x++)
        {
            float back = CurrentHeightField[y][x - 1];
            float front = CurrentHeightField[y][x + 1];
            float left = CurrentHeightField[y - 1][x];
            float right = CurrentHeightField[y + 1][x];

            float averageZ = (back + front + left + right) / 4.0f; // centre of neighbours

            float difference = CurrentHeightField[y][x] - averageZ;   // elastic distance to centre of neighbours
            
            float force = -FORCE_FACTOR * difference; // force as elastic force            

            // f=ma where mass = const, a=d2z/dt2=ddz, damping = 0.99f or similar close to one
            CurrentHeightFieldV[y][x] = DeltaTime * force + DAMPING * CurrentHeightFieldV[y][x];
        }
    }

    // Simulates height.
    for (int y = 0; y < HEIGHT_FIELD_SIZE; y++)
    {
        for (int x = 0; x < HEIGHT_FIELD_SIZE; x++)
        {
            // Avoid constant wakes on edges.
            CurrentHeightField[y][x] *= DAMPING;

            CurrentHeightField[y][x] += DeltaTime * CurrentHeightFieldV[y][x];            
        }
    }






/*

// Use these to sacrifice some sample so we can avoid array bound check(to use BilinearReadArrayUnsafe).
    int ymin;
    int ymax;
    int xmin;
    int xmax;

    // Simulates velocity.
    ymin = FMath::Max(0, FMath::CeilToInt(1 - OffsetY));
    ymax = FMath::Min(HEIGHT_FIELD_SIZE, FMath::FloorToInt(HEIGHT_FIELD_SIZE - 1 - OffsetY));
    xmin = FMath::Max(0, FMath::CeilToInt(1 - OffsetX));
    xmax = FMath::Min(HEIGHT_FIELD_SIZE, FMath::FloorToInt(HEIGHT_FIELD_SIZE - 1 - OffsetX));

    for (int y = ymin; y < ymax; y++)
    {
        for (int x = xmin; x < xmax; x++)
        {
            float ox = x + OffsetX;
            float oy = y + OffsetY;

            float back = BilinearReadArrayUnsafe(PreviousHeightField, ox - 1, oy);
            float front = BilinearReadArrayUnsafe(PreviousHeightField, ox + 1, oy);
            float left = BilinearReadArrayUnsafe(PreviousHeightField, ox, oy - 1);
            float right = BilinearReadArrayUnsafe(PreviousHeightField, ox, oy + 1);

            float averageZ = (back + front + left + right) / 4.0f; // centre of neighbours

            float difference = BilinearReadArrayUnsafe(PreviousHeightField, ox, oy) - averageZ;   // elastic distance to centre of neighbours

            float force = -FORCE_FACTOR * difference; // force as elastic force
            CurrentHeightFieldV[y][x] *= DAMPING; // where damping = 0.99f or similar close to one


                                                  // f=ma where mass = const, a=d2z/dt2=ddz
            CurrentHeightFieldV[y][x] = DeltaTime * force + DAMPING * BilinearReadArrayUnsafe(PreviousHeightFieldV, ox, oy);
        }
    }

    //for (int y = 0; y < HEIGHT_FIELD_SIZE; y++)
    //{
    //    for (int x = 0; x < HEIGHT_FIELD_SIZE; x++)
    //    {
    //        float ox = x + OffsetX;
    //        float oy = y + OffsetY;

    //        float back = BilinearReadArray(PreviousHeightField, ox - 1, oy);
    //        float front = BilinearReadArray(PreviousHeightField, ox + 1, oy);
    //        float left = BilinearReadArray(PreviousHeightField, ox, oy - 1);
    //        float right = BilinearReadArray(PreviousHeightField, ox, oy + 1);

    //        float averageZ = (back + front + left + right) / 4.0f; // centre of neighbours

    //        float difference = BilinearReadArray(PreviousHeightField, ox, oy) - averageZ;   // elastic distance to centre of neighbours
    //        
    //        float force = -FORCE_FACTOR * difference; // force as elastic force
    //        CurrentHeightFieldV[y][x] *= DAMPING; // where damping = 0.99f or similar close to one
    //        

    //        // f=ma where mass = const, a=d2z/dt2=ddz
    //        CurrentHeightFieldV[y][x] = DeltaTime * force + DAMPING * BilinearReadArray(PreviousHeightFieldV, ox, oy);
    //    }
    //}



    // Simulates height.
    ymin = FMath::Max(0, FMath::CeilToInt(0 - OffsetY));
    ymax = FMath::Min(HEIGHT_FIELD_SIZE, FMath::FloorToInt(HEIGHT_FIELD_SIZE - OffsetY));
    xmin = FMath::Max(0, FMath::CeilToInt(0 - OffsetX));
    xmax = FMath::Min(HEIGHT_FIELD_SIZE, FMath::FloorToInt(HEIGHT_FIELD_SIZE - OffsetX));

    for (int y = ymin; y < ymax; y++)
    {
        for (int x = xmin; x < xmax; x++)
        {
            float ox = x + OffsetX;
            float oy = y + OffsetY;

            float delta_height = DeltaTime * CurrentHeightFieldV[y][x];
            float prev_height = BilinearReadArrayUnsafe(PreviousHeightField, ox, oy);
            CurrentHeightField[y][x] = prev_height + delta_height;
        }
    }

    //for (int y = 0; y < HEIGHT_FIELD_SIZE; y++)
    //{
    //    for (int x = 0; x < HEIGHT_FIELD_SIZE; x++)
    //    {
    //        float ox = x + OffsetX;
    //        float oy = y + OffsetY;

    //        float delta_height = DeltaTime * CurrentHeightFieldV[y][x];
    //        float prev_height = BilinearReadArray(PreviousHeightField, ox, oy);
    //        CurrentHeightField[y][x] = prev_height + delta_height;
    //    }
    //}
*/



    // Simulates normals. Note: Cell size matters!
    for (int y = 1; y < HEIGHT_FIELD_SIZE - 1; y++)
    {
        for (int x = 1; x < HEIGHT_FIELD_SIZE - 1; x++)
        {
            FVector current = FVector(x * CELL_SIZE, y * CELL_SIZE, CurrentHeightField[y][x]);

            FVector back = FVector((x - 1) * CELL_SIZE, y * CELL_SIZE, CurrentHeightField[y][x - 1]);
            FVector front = FVector((x + 1) * CELL_SIZE, y * CELL_SIZE, CurrentHeightField[y][x + 1]);
            FVector left = FVector(x * CELL_SIZE, (y - 1) * CELL_SIZE, CurrentHeightField[y - 1][x]);
            FVector right = FVector(x * CELL_SIZE, (y + 1) * CELL_SIZE, CurrentHeightField[y + 1][x]);

            FVector rf = FVector::CrossProduct(front - current, right - current);
            FVector lb = FVector::CrossProduct(back - current, left - current);

            NormalField[y][x] = (rf + lb).GetSafeNormal();
        }
    }

    // The precise normal simulation. But much slower.
    //for (int y = 0; y < HEIGHT_FIELD_SIZE; y++)
    //{
    //    for (int x = 0; x < HEIGHT_FIELD_SIZE; x++)
    //    {
    //        FVector current = FVector(x * CELL_SIZE, y * CELL_SIZE, CurrentHeightField[y][x]);

    //        FVector back = y < 0 || y >= HEIGHT_FIELD_SIZE || x - 1 < 0 || x - 1 >= HEIGHT_FIELD_SIZE ?
    //            current : FVector((x - 1) * CELL_SIZE, y * CELL_SIZE, CurrentHeightField[y][x - 1]);
    //        FVector front = y < 0 || y >= HEIGHT_FIELD_SIZE || x + 1 < 0 || x + 1 >= HEIGHT_FIELD_SIZE ?
    //            current : FVector((x + 1) * CELL_SIZE, y * CELL_SIZE, CurrentHeightField[y][x + 1]);
    //        FVector left = y - 1 < 0 || y - 1 >= HEIGHT_FIELD_SIZE || x < 0 || x >= HEIGHT_FIELD_SIZE ?
    //            current : FVector(x * CELL_SIZE, (y - 1) * CELL_SIZE, CurrentHeightField[y - 1][x]);
    //        FVector right = y + 1 < 0 || y + 1 >= HEIGHT_FIELD_SIZE || x < 0 || x >= HEIGHT_FIELD_SIZE ?
    //            current : FVector(x * CELL_SIZE, (y + 1) * CELL_SIZE, CurrentHeightField[y + 1][x]);

    //        FVector rf = FVector::CrossProduct(front - current, right - current).GetSafeNormal();
    //        FVector lb = FVector::CrossProduct(back - current, left - current).GetSafeNormal();
    //        NormalField[y][x] = (rf + lb).GetSafeNormal();
    //    }
    //}

}

void ULocalOceanComponent::UpdateMesh(float DeltaTime)
{
    // Vertex positions and normals.
    if (SourceMesh != nullptr)
    {
        float X, Y;
        for (int i = 0; i < InterestingVertexIndices.Num(); i++)
        {
            FVector& CurPos = Vertices[InterestingVertexIndices[i]];
            GetXYFromWorldLocation(ProceduralMesh->GetComponentTransform().TransformPosition(CurPos), X, Y);
            //CurPos.Z = BilinearReadArray(CurrentHeightField, X, Y);
            CurPos.Z = CloseReadArray(CurrentHeightField, X, Y);

            FVector& CurNormal = Normals[InterestingVertexIndices[i]];
            
            CurNormal = BilinearReadArrayVector(NormalField, X, Y);
            //CurNormal = CloseReadArrayVector(NormalField, X, Y);
        }
    }
    else
    {
        // For default mesh: mesh vertices always follow the height field.
        for (int y = 0; y < HEIGHT_FIELD_SIZE; y++)
        {
            for (int x = 0; x < HEIGHT_FIELD_SIZE; x++)
            {
                FVector pos = FVector(x * CELL_SIZE - HalfSize, y * CELL_SIZE - HalfSize, CurrentHeightField[y][x]) + GetOwner()->GetActorLocation();
                pos = ProceduralMesh->GetComponentTransform().InverseTransformPosition(pos);
                pos.Z = 0;
                Vertices[y * HEIGHT_FIELD_SIZE + x] = pos;
                Normals[y * HEIGHT_FIELD_SIZE + x] = NormalField[y][x];
            }
        }
    }

    // Colors.
    for (int i = 0; i < Colors.Num(); i++)
    {
        Colors[i] = FColor::White;
    }


    ProceduralMesh->UpdateMeshSection(0, Vertices, Normals, UVs, Colors, Tangents);
}



void ULocalOceanComponent::SetHeightFieldAtRelativeXY(float Height, float X, float Y)
{
    if (!Enabled)
    {
        return;
    }

    FVector Location = this->GetOwner()->GetActorTransform().TransformPosition(FVector(X, Y, 0));

    //SetHeightFieldPushPoint(FVector(Location.X, Location.Y, Height));
    SetHeightFieldHollowPoint(FVector(Location.X, Location.Y, Height));
}

void ULocalOceanComponent::SetHeightFieldPushPoint(FVector WorldLocation)
{
    if (!Enabled)
    {
        return;
    }

    FVector Offset = WorldLocation - this->GetOwner()->GetActorLocation();

    float x = (Offset.X + HalfSize) / CELL_SIZE;
    float y = (Offset.Y + HalfSize) / CELL_SIZE;

    // We have to set up both current and previous height field since we cannot be sure if self or wake generators
    // tick first.
    float height = WorldLocation.Z * FMath::Square(FMath::Clamp<float>(Speed / MaxSpeed, 0, 1));
    int ix, iy;


    if (x >= 0 && x <= HEIGHT_FIELD_SIZE - 1 && y >= 0 && y <= HEIGHT_FIELD_SIZE - 1)
    {
        // Left bottom
        iy = FMath::FloorToInt(y);
        ix = FMath::FloorToInt(x);
        //CurrentHeightField[iy][ix] = FMath::Lerp(CurrentHeightField[iy][ix], height, FMath::Abs(y - iy + x - ix) / 1.0f);
        CurrentHeightField[iy][ix] = height;

        // Left top
        iy = FMath::FloorToInt(y);
        ix = FMath::CeilToInt(x);
        CurrentHeightField[iy][ix] = height;

        // Right top
        iy = FMath::CeilToInt(y);
        ix = FMath::CeilToInt(x);
        CurrentHeightField[iy][ix] = height;

        // Right bottom
        iy = FMath::CeilToInt(y);
        ix = FMath::FloorToInt(x);
        CurrentHeightField[iy][ix] = height;
    }



    x += OffsetX;
    y += OffsetY;

    if (x >= 0 && x <= HEIGHT_FIELD_SIZE - 1 && y >= 0 && y <= HEIGHT_FIELD_SIZE - 1)
    {
        // Left bottom
        iy = FMath::FloorToInt(y);
        ix = FMath::FloorToInt(x);
        PreviousHeightField[iy][ix] = height;

        // Left top
        iy = FMath::FloorToInt(y);
        ix = FMath::CeilToInt(x);
        PreviousHeightField[iy][ix] = height;

        // Right top
        iy = FMath::CeilToInt(y);
        ix = FMath::CeilToInt(x);
        PreviousHeightField[iy][ix] = height;

        // Right bottom
        iy = FMath::CeilToInt(y);
        ix = FMath::FloorToInt(x);
        PreviousHeightField[iy][ix] = height;
    }


/*
    float R = CELL_SIZE * (HEIGHT_FIELD_SIZE - 1) / 2.0f;
    int x = (Offset.X + R) / CELL_SIZE;
    int y = (Offset.Y + R) / CELL_SIZE;

    if (x >= 0 && x < HEIGHT_FIELD_SIZE && y >= 0 && y < HEIGHT_FIELD_SIZE)
    {
        PreviousHeightField[y][x] = WorldLocation.Z * FMath::Clamp<float>(Speed / MaxSpeed, 0, 1);
        CurrentHeightField[y][x] = WorldLocation.Z * FMath::Clamp<float>(Speed / MaxSpeed, 0, 1);
    }
*/

}

void ULocalOceanComponent::SetHeightFieldHollowPoint(FVector WorldLocation)
{
    if (!Enabled)
    {
        return;
    }

    FVector Offset = WorldLocation - this->GetOwner()->GetActorLocation();

    float x = (Offset.X + HalfSize) / CELL_SIZE;
    float y = (Offset.Y + HalfSize) / CELL_SIZE;

    // We have to set up both current and previous height field since we cannot be sure if self or wake generators
    // tick first.
    float height = WorldLocation.Z * FMath::Square(FMath::Clamp<float>(Speed / MaxSpeed, 0, 1));
    int ix, iy;


    // Center
    iy = y + 0.5f;
    ix = x + 0.5f;
    if (ix >= 0 && ix < HEIGHT_FIELD_SIZE && iy >= 0 && iy < HEIGHT_FIELD_SIZE)
    {
        CurrentHeightField[iy][ix] = height;
    }

    // Left
    if (ix >= 0 && ix < HEIGHT_FIELD_SIZE && iy - 1 >= 0 && iy - 1 < HEIGHT_FIELD_SIZE)
    {
        CurrentHeightField[iy - 1][ix] = -height;
    }

    // Right
    if (ix >= 0 && ix < HEIGHT_FIELD_SIZE && iy + 1 >= 0 && iy + 1 < HEIGHT_FIELD_SIZE)
    {
        CurrentHeightField[iy + 1][ix] = -height;
    }

    // Front
    if (ix + 1 >= 0 && ix + 1 < HEIGHT_FIELD_SIZE && iy >= 0 && iy < HEIGHT_FIELD_SIZE)
    {
        CurrentHeightField[iy][ix + 1] = -height;
    }

    // back
    if (ix - 1 >= 0 && ix - 1 < HEIGHT_FIELD_SIZE && iy >= 0 && iy < HEIGHT_FIELD_SIZE)
    {
        CurrentHeightField[iy][ix - 1] = -height;
    }


    x += OffsetX;
    y += OffsetY;

    // Center
    iy = y + 0.5f;
    ix = x + 0.5f;
    if (ix >= 0 && ix < HEIGHT_FIELD_SIZE && iy >= 0 && iy < HEIGHT_FIELD_SIZE)
    {
        PreviousHeightField[iy][ix] = height;
    }

    // Left
    if (ix >= 0 && ix < HEIGHT_FIELD_SIZE && iy - 1 >= 0 && iy - 1 < HEIGHT_FIELD_SIZE)
    {
        PreviousHeightField[iy - 1][ix] = -height;
    }

    // Right
    if (ix >= 0 && ix < HEIGHT_FIELD_SIZE && iy + 1 >= 0 && iy + 1 < HEIGHT_FIELD_SIZE)
    {
        PreviousHeightField[iy + 1][ix] = -height;
    }

    // Front
    if (ix + 1 >= 0 && ix + 1 < HEIGHT_FIELD_SIZE && iy >= 0 && iy < HEIGHT_FIELD_SIZE)
    {
        PreviousHeightField[iy][ix + 1] = -height;
    }

    // back
    if (ix - 1 >= 0 && ix - 1 < HEIGHT_FIELD_SIZE && iy >= 0 && iy < HEIGHT_FIELD_SIZE)
    {
        PreviousHeightField[iy][ix - 1] = -height;
    }

}

void ULocalOceanComponent::SetEnabled(bool bEnabled)
{
    this->Enabled = bEnabled;
    this->ProceduralMesh->SetVisibility(this->Enabled);


    if (!this->Enabled)
    {
        return;
    }


    HalfSize = (HEIGHT_FIELD_SIZE - 1) * CELL_SIZE / 2.0f;

    Activate();

    CurrentHeightField = HeightField0;
    CurrentHeightFieldV = HeightFieldV0;

    PreviousHeightField = HeightField1;
    PreviousHeightFieldV = HeightFieldV1;

    RecentLocationX = this->GetOwner()->GetActorLocation().X;
    RecentLocationY = this->GetOwner()->GetActorLocation().Y;


    if (SourceMesh != nullptr)
    {
        UKismetProceduralMeshLibrary::GetSectionFromStaticMesh(SourceMesh, 0, SourceMeshSectionIndex, Vertices, Triangles, Normals, UVs, Tangents);
        Colors.SetNum(Vertices.Num());
        UVs.Empty();
        Tangents.Empty();

        InterestingVertexIndices.Empty();
        for (int i = 0; i < Vertices.Num(); i++)
        {
            if (FMath::Abs(Vertices[i].X) <= HalfSize && FMath::Abs(Vertices[i].Y) <= HalfSize)
            {
                InterestingVertexIndices.Add(i);
            }
        }
    }
    else
    {
        Vertices.SetNum(HEIGHT_FIELD_SIZE * HEIGHT_FIELD_SIZE);
        Normals.SetNum(HEIGHT_FIELD_SIZE * HEIGHT_FIELD_SIZE);

        for (int y = 0; y < HEIGHT_FIELD_SIZE - 1; y++)
        {
            for (int x = 0; x < HEIGHT_FIELD_SIZE - 1; x++)
            {
                // Triangle indices: from left bottom, clockwise;
                int p0 = y * HEIGHT_FIELD_SIZE + x;
                int p1 = y * HEIGHT_FIELD_SIZE + x + 1;
                int p2 = (y + 1) * HEIGHT_FIELD_SIZE + x + 1;
                int p3 = (y + 1) * HEIGHT_FIELD_SIZE + x;

                // Right hand triangles face up(+Z)...
                Triangles.Add(p2);
                Triangles.Add(p1);
                Triangles.Add(p0);

                Triangles.Add(p0);
                Triangles.Add(p3);
                Triangles.Add(p2);
            }
        }
    }

    ProceduralMesh->CreateMeshSection(0, Vertices, Triangles, Normals, UVs, Colors, Tangents, false);

    if (Debugging)
    {
        ProceduralMesh->SetMaterial(0, DebuggingMaterials[DebuggingMaterialIndex]);
        DebuggingMaterialIndex = (DebuggingMaterialIndex + 1) % DebuggingMaterials.Num();
    }
    else
    {
        ProceduralMesh->SetMaterial(0, Material);
    }
}


