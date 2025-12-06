#import <Cocoa/Cocoa.h>

/* Playlist item PasteBoard type, mainly used for reordering drag and drop operations */
extern NSString* const AUDPlaylistItemPBoardType;
/* Undocumented in Cocoa : iTunes item */
extern NSString* const iTunesPBoardType;

@class PlaylistDocument, PlaylistView;

@interface PlaylistArrayController : NSArrayController {
    PlaylistDocument* mDocument;
    IBOutlet PlaylistView* mPlaylistView;
    IBOutlet NSButton* repeatButton;
    IBOutlet NSButton* shuffleButton;
    IBOutlet NSButton* addButton;
    IBOutlet NSButton* removeButton;
}
- (void)setPlaylistDocument:(PlaylistDocument*)playlistdoc;
- (IBAction)trackSeek:(id)sender;
- (IBAction)toggleRepeat:(id)sender;
- (IBAction)toggleShuffle:(id)sender;
@end