#include "MyGamePlayerController.h"
#include "MyGamePawn.h"
#include "Components/InputComponent.h"

AMyGamePlayerController::AMyGamePlayerController()
{
	bShowMouseCursor = false;
	DefaultMouseCursor = EMouseCursor::Default;
}

void AMyGamePlayerController::SetupInputComponent()
{
	Super::SetupInputComponent();

	// Touch events reach us through the legacy input component bindings, so a
	// phone-only build needs no Enhanced Input mapping assets.
	InputComponent->BindTouch(IE_Pressed, this, &AMyGamePlayerController::OnTouchPressed);
	InputComponent->BindTouch(IE_Repeat, this, &AMyGamePlayerController::OnTouchMoved);
	InputComponent->BindTouch(IE_Released, this, &AMyGamePlayerController::OnTouchReleased);
}

AMyGamePawn* AMyGamePlayerController::GetMyPawn() const
{
	return Cast<AMyGamePawn>(GetPawn());
}

void AMyGamePlayerController::OnTouchPressed(ETouchIndex::Type FingerIndex, FVector Location)
{
	int32 ViewportX = 0;
	int32 ViewportY = 0;
	GetViewportSize(ViewportX, ViewportY);

	const FVector2D Screen(Location.X, Location.Y);

	if (Screen.X < ViewportX * 0.5f)
	{
		if (MoveFingerIndex == INDEX_NONE)
		{
			MoveFingerIndex = static_cast<int32>(FingerIndex);
			JoystickCentre = Screen;
			JoystickKnob = Screen;
		}
	}
	else if (LookFingerIndex == INDEX_NONE)
	{
		LookFingerIndex = static_cast<int32>(FingerIndex);
		LastLookLocation = Screen;
		if (AMyGamePawn* MyPawn = GetMyPawn())
		{
			MyPawn->SetLooking(true);
		}
	}
}

void AMyGamePlayerController::OnTouchMoved(ETouchIndex::Type FingerIndex, FVector Location)
{
	const FVector2D Screen(Location.X, Location.Y);

	if (static_cast<int32>(FingerIndex) == MoveFingerIndex)
	{
		FVector2D Delta = Screen - JoystickCentre;
		const float Length = Delta.Size();
		if (Length > JoystickRadius)
		{
			Delta *= JoystickRadius / Length;
		}
		JoystickKnob = JoystickCentre + Delta;

		if (AMyGamePawn* MyPawn = GetMyPawn())
		{
			// Screen Y grows downward; world forward should grow upward.
			MyPawn->SetMoveInput(FVector2D(Delta.X / JoystickRadius, -Delta.Y / JoystickRadius));
		}
	}
	else if (static_cast<int32>(FingerIndex) == LookFingerIndex)
	{
		const FVector2D Delta = Screen - LastLookLocation;
		LastLookLocation = Screen;
		if (AMyGamePawn* MyPawn = GetMyPawn())
		{
			MyPawn->AddLookInput(Delta);
		}
	}
}

void AMyGamePlayerController::OnTouchReleased(ETouchIndex::Type FingerIndex, FVector Location)
{
	if (static_cast<int32>(FingerIndex) == MoveFingerIndex)
	{
		MoveFingerIndex = INDEX_NONE;
		if (AMyGamePawn* MyPawn = GetMyPawn())
		{
			MyPawn->SetMoveInput(FVector2D::ZeroVector);
		}
	}
	else if (static_cast<int32>(FingerIndex) == LookFingerIndex)
	{
		LookFingerIndex = INDEX_NONE;
		if (AMyGamePawn* MyPawn = GetMyPawn())
		{
			MyPawn->SetLooking(false);
		}
	}
}
