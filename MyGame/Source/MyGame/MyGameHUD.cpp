#include "MyGameHUD.h"
#include "MyGamePlayerController.h"
#include "Engine/Canvas.h"

void AMyGameHUD::DrawHUD()
{
	Super::DrawHUD();

	const AMyGamePlayerController* PC = Cast<AMyGamePlayerController>(PlayerOwner);
	if (!PC || !Canvas)
	{
		return;
	}

	const FVector2D Centre = PC->GetJoystickCentre();
	const FVector2D Knob = PC->GetJoystickKnob();
	const float Radius = PC->GetJoystickRadius();

	const FColor RingColor(255, 255, 255, 64);
	const FColor KnobColor(255, 255, 255, 160);

	// A small ring plus a dot reads clearly as a joystick on a phone screen.
	Draw2DLine(Centre.X - Radius, Centre.Y, Centre.X + Radius, Centre.Y, RingColor);
	Draw2DLine(Centre.X, Centre.Y - Radius, Centre.X, Centre.Y + Radius, RingColor);

	const float KnobRadius = Radius * 0.3f;
	Draw2DLine(Knob.X - KnobRadius, Knob.Y, Knob.X + KnobRadius, Knob.Y, KnobColor);
	Draw2DLine(Knob.X, Knob.Y - KnobRadius, Knob.X, Knob.Y + KnobRadius, KnobColor);
}
