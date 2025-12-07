#import "CustomSliderCell.h"

@implementation CustomSliderCell

- (void)dealloc
{
    if (mBackgroundImage) {
        [mBackgroundImage release];
        mBackgroundImage = nil;
    }
    if (mKnobImage) {
        [mKnobImage release];
        mKnobImage = nil;
    }
    [super dealloc];
}

- (void)setBackgroundImage:(NSImage*)backgroundImage
{
    [backgroundImage retain];
    if (mBackgroundImage)
        [mBackgroundImage release];
    mBackgroundImage = backgroundImage;
}

- (void)setKnobImage:(NSImage*)knobImage
{
    [knobImage retain];
    if (mKnobImage)
        [mKnobImage release];
    mKnobImage = knobImage;
}

- (void)drawKnob:(NSRect)knobRect
{
    if (mKnobImage) {
        if ([self isVertical])
            [mKnobImage drawInRect:NSMakeRect(knobRect.origin.x + (knobRect.size.width - [mKnobImage size].width) / 2, knobRect.origin.y, [mKnobImage size].width, [mKnobImage size].height)
                          fromRect:NSZeroRect
                         operation:NSCompositingOperationSourceOver
                          fraction:1.0f
                    respectFlipped:YES
                             hints:nil];
        else
            [mKnobImage drawInRect:NSMakeRect(knobRect.origin.x + (knobRect.size.width - [mKnobImage size].width) / 2,
                                       knobRect.origin.y + (knobRect.size.height - [mKnobImage size].height) / 2,
                                       [mKnobImage size].width, [mKnobImage size].height)
                          fromRect:NSZeroRect
                         operation:NSCompositingOperationSourceOver
                          fraction:1.0f
                    respectFlipped:YES
                             hints:nil];
    } else {
        [super drawKnob:knobRect];
    }
}

- (void)drawBarInside:(NSRect)aRect flipped:(BOOL)flipped
{
    if (mBackgroundImage) {
        if ([self isVertical])
            [mBackgroundImage drawAtPoint:NSMakePoint(aRect.origin.x + aRect.size.width / 2 - [mBackgroundImage size].width / 2, aRect.origin.y + 1)
                                 fromRect:NSZeroRect
                                operation:NSCompositingOperationSourceOver
                                 fraction:1.0f];
        else
            [mBackgroundImage drawAtPoint:NSMakePoint(aRect.origin.x + aRect.size.width / 2 - [mBackgroundImage size].width / 2,
                                              aRect.origin.y + (flipped ? 1 : -1) * (aRect.size.height / 2 - [mBackgroundImage size].height / 2))
                                 fromRect:NSZeroRect
                                operation:NSCompositingOperationSourceOver
                                 fraction:1.0f];

    } else {
        [super drawBarInside:aRect flipped:flipped];
    }
}

- (BOOL)_usesCustomTrackImage
{
    return YES;
}

@end
