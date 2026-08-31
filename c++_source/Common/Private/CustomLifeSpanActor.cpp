// Fill out your copyright notice in the Description page of Project Settings.

#include "CustomLifeSpanActor.h"
#include "Common.h"

void ACustomLifeSpanActor::LifeSpanExpired()
{
	ReceiveLifeSpanExpired();
}