#import <Cocoa/Cocoa.h>

@interface CustomSliderCell : NSSliderCell {
    NSImage* mBackgroundImage;
    NSImage* mKnobImage;
}

- (void)setBackgroundImage:(NSImage*)backgroundImage;
- (void)setKnobImage:(NSImage*)knobImage;

@end