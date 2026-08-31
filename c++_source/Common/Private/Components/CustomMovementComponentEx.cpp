// Fill out your copyright notice in the Description page of Project Settings.

#include "Components/CustomMovementComponentEx.h"
#include "Common.h"


void UCustomMovementComponentEx::TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction)
{
    Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

    FVector PositionDelta;
    FRotator NewRotation;
    ComputeMovement(DeltaTime, PositionDelta, NewRotation);

    MoveUpdatedComponent(PositionDelta, NewRotation, true);
    UpdateComponentVelocity();
}


void UCustomMovementComponentEx::ComputeMovement_Implementation(float DeltaTime, FVector& PositionDelta, FRotator& NewRotation)
{
    AActor* Owner = GetOwner();
    if (Owner)
    {
        PositionDelta = Velocity * DeltaTime;
        NewRotation = Owner->GetActorRotation();
    }
}

bool UCustomMovementComponentEx::AlongSurface(const FVector& Direction, float WalkableFloorAngle)
{
    if (!Direction.IsNearlyZero())
    {
        FHitResult Hit;
        SafeMoveUpdatedComponent(Direction, UpdatedComponent->GetComponentRotation(), true, Hit);
        // 如碰到物体，尝试沿其滑动
        if (Hit.IsValidBlockingHit())
        {
            float WalkableFloorZ = FMath::Cos(FMath::DegreesToRadians(WalkableFloorAngle));
            const UPrimitiveComponent* HitComponent = Hit.Component.Get();
            if (HitComponent)
            {
                const FWalkableSlopeOverride& SlopeOverride = HitComponent->GetWalkableSlopeOverride();
                WalkableFloorZ = SlopeOverride.ModifyWalkableFloorZ(WalkableFloorZ);
            }
            // 坡度太平缓
            if (Hit.Normal.Z > WalkableFloorZ)
            {
                return false;
            }

            return SlideAlongSurface(Direction, 1.f - Hit.Time, Hit.Normal, Hit) > 0.f;
        }
    }
    return false;
}