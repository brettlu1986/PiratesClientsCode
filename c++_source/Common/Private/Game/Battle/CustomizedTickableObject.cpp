// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Battle/CustomizedTickableObject.h"
#include "Common.h"



void UCustomizedTickableObject::Tick(float DeltaSeconds)
{
    if (CustomizedTickInterval <= 0)
    {   
        OnTick(DeltaSeconds);

        ReceiveTick(DeltaSeconds);
    }
    else
    {
        LastTickDeltaSeconds += DeltaSeconds;
        if (LastTickDeltaSeconds >= CustomizedTickInterval)
        {
            OnTick(LastTickDeltaSeconds);
         
            ReceiveTick(LastTickDeltaSeconds);

            LastTickDeltaSeconds = 0;
        }
    }

}

void UCustomizedTickableObject::OnTick(float DeltaSeconds)
{

}

TStatId UCustomizedTickableObject::GetStatId() const
{
    return TStatId();
}

bool UCustomizedTickableObject::IsTickable() const
{
    return TickEnabled;
}