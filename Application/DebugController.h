#import <Cocoa/Cocoa.h>

@interface DebugController : NSWindowController {
    IBOutlet NSTextView* textView;
}
- (void)setInfoText:(NSString*)text;
@end