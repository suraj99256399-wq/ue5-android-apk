#include "MyGamePawn.h"
#include "Camera/CameraComponent.h"
#include "Components/SceneComponent.h"
#include "GameFramework/FloatingPawnMovement.h"

AMyGamePawn::AMyGamePawn()
{
	PrimaryActorTick.bCanEverTick = true;

	Root = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
	SetRootComponent(Root);

	Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
	Camera->SetupAttachment(Root);
	Camera->SetRelativeLocation(FVector(0.0f, 0.0f, 64.0f));
	Camera->bUsePawnControlRotation = false;

	Movement = CreateDefaultSubobject<UFloatingPawnMovement>(TEXT("Movement"));
	Movement->UpdatedComponent = Root;
	Movement->MaxSpeed = MoveSpeed;
}

void AMyGamePawn::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);

	if (!MoveInput.IsNearlyZero())
	{
		// Movement is always horizontal, so pitching the view never lifts the pawn.
		const FRotator YawOnly(0.0f, GetActorRotation().Yaw, 0.0f);
		const FVector Forward = FRotationMatrix(YawOnly).GetUnitAxis(EAxis::X);
		const FVector Right = FRotationMatrix(YawOnly).GetUnitAxis(EAxis::Y);

		AddMovementInput(Forward, MoveInput.Y);
		AddMovementInput(Right, MoveInput.X);
	}

	if (bLooking && !LookInput.IsNearlyZero())
	{
		AddActorLocalRotation(FRotator(0.0f, LookInput.X * YawSensitivity, 0.0f));

		const float NewPitch = FMath::Clamp(
			Camera->GetRelativeRotation().Pitch - LookInput.Y * PitchSensitivity, -80.0f, 80.0f);
		Camera->SetRelativeRotation(FRotator(NewPitch, 0.0f, 0.0f));

		LookInput = FVector2D::ZeroVector;
	}
}
