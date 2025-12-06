#import <Cocoa/Cocoa.h>

@class PlaylistDocument;

@interface PlaylistView_Delegate : NSObject <NSTableViewDelegate> {
    PlaylistDocument* document;
}
- (void)setDocument:(PlaylistDocument*)mydoc;
@end