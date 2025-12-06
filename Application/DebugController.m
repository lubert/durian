#import "DebugController.h"

@implementation DebugController
- (id)init
{
    if (![super initWithWindowNibName:@"Debug"])
        return nil;
    return self;
}

- (void)setInfoText:(NSString*)text
{
    [textView setString:text];
}
@end