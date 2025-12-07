#import "PlaylistArrayController.h"
#import "PlaylistDocument.h"
#import "PlaylistItem.h"
#import "PlaylistView.h"

// Internal drag and drop type
NSString* const AUDPlaylistItemPBoardType = @"com.github.durian.playlistitemtype";
NSString* const iTunesPBoardType = @"CorePasteboardFlavorType 0x6974756E";

@interface PlaylistArrayController (Notifications)
- (void)handleUpdateRepeatStatus:(NSNotification*)notification;
- (void)handleUpdateShuffleStatus:(NSNotification*)notification;
@end

@implementation PlaylistArrayController

- (void)awakeFromNib
{
    mPlaylistView.doubleAction = @selector(trackSeek:);
    mPlaylistView.target = self;

    // Set SF Symbol images for buttons (dark mode compatible)
    if (@available(macOS 11.0, *)) {
        // Create symbol configuration for medium size
        NSImageSymbolConfiguration* config = [NSImageSymbolConfiguration configurationWithPointSize:13 weight:NSFontWeightRegular scale:NSImageSymbolScaleMedium];

        // Add button
        NSImage* plusImage = [NSImage imageWithSystemSymbolName:@"plus" accessibilityDescription:@"Add"];
        plusImage = [plusImage imageWithSymbolConfiguration:config];
        [addButton setImage:plusImage];

        // Remove button
        NSImage* minusImage = [NSImage imageWithSystemSymbolName:@"minus" accessibilityDescription:@"Remove"];
        minusImage = [minusImage imageWithSymbolConfiguration:config];
        [removeButton setImage:minusImage];

        // Shuffle button
        NSImage* shuffleImage = [NSImage imageWithSystemSymbolName:@"shuffle" accessibilityDescription:@"Shuffle"];
        shuffleImage = [shuffleImage imageWithSymbolConfiguration:config];
        [shuffleButton setImage:shuffleImage];
        [shuffleButton setAlternateImage:shuffleImage];

        // Repeat button
        NSImage* repeatImage = [NSImage imageWithSystemSymbolName:@"repeat" accessibilityDescription:@"Repeat"];
        repeatImage = [repeatImage imageWithSymbolConfiguration:config];
        [repeatButton setImage:repeatImage];
        [repeatButton setAlternateImage:repeatImage];
    }

    // Add playlist changes listeners
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(handleUpdateRepeatStatus:)
               name:AUDTogglePlaylistRepeat
             object:nil];
    [nc addObserver:self
           selector:@selector(handleUpdateShuffleStatus:)
               name:AUDTogglePlaylistShuffle
             object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)setPlaylistDocument:(PlaylistDocument*)playlistdoc
{
    mDocument = playlistdoc;
}

#pragma mark Table view data source methods for track number with status

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
    // For all columns, return nil to let bindings handle it
    return nil;
}

- (void)setSortDescriptors:(NSArray*)array
{
    // Do nothing, to prevent the user from sorting the playlist
}

#pragma mark add/remove/seek operations
- (IBAction)add:(id)sender
{
    [mDocument addPlaylistItems];
}

- (IBAction)remove:(id)sender
{
    [mDocument removePlaylistItems:[mPlaylistView selectedRowIndexes]];
}

- (IBAction)trackSeek:(id)sender
{
    [mDocument changePlayingTrack:[mPlaylistView clickedRow]];
}

- (IBAction)toggleRepeat:(id)sender
{
    [mDocument setIsRepeating:![mDocument isRepeating]];
}

- (IBAction)toggleShuffle:(id)sender
{
    [mDocument setIsShuffling:![mDocument isShuffling]];
}

- (void)handleUpdateRepeatStatus:(NSNotification*)notification
{
    [repeatButton setState:[mDocument isRepeating]];
}

- (void)handleUpdateShuffleStatus:(NSNotification*)notification
{
    [shuffleButton setState:[mDocument isShuffling]];
}

#pragma mark Drag and drop operations

- (BOOL)tableView:(NSTableView*)tv writeRowsWithIndexes:(NSIndexSet*)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    // Copy the row numbers to the pasteboard.
    NSError* error = nil;
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes requiringSecureCoding:YES error:&error];
    if (data == nil) {
        NSLog(@"Failed to archive row indexes: %@", error);
        return NO;
    }
    [pboard declareTypes:[NSArray arrayWithObject:AUDPlaylistItemPBoardType] owner:self];
    [pboard setData:data forType:AUDPlaylistItemPBoardType];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
    if ([info draggingSource] == tv)
        return NSDragOperationMove; // Internal drag is a move operation
    else
        return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView*)aTableView acceptDrop:(id<NSDraggingInfo>)info
              row:(NSInteger)row
    dropOperation:(NSTableViewDropOperation)operation
{
    BOOL success = NO;
    NSPasteboard* pboard = [info draggingPasteboard];

    if ([info draggingSource] == aTableView) {
        // Internal drag: Move the specified row to its new location...
        NSData* rowData = [pboard dataForType:AUDPlaylistItemPBoardType];

        NSError* error = nil;
        NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSIndexSet class] fromData:rowData error:&error];
        if (rowIndexes == nil) {
            NSLog(@"Failed to unarchive row indexes: %@", error);
            return NO;
        }

        [mDocument movePlaylistItems:rowIndexes toRow:row];
        success = YES;
    } else {
        // External drop
        NSArray* droppedTypes = [pboard types];

        if ([droppedTypes containsObject:iTunesPBoardType]) {
            NSDictionary* iTunesDroppedData = [[info draggingPasteboard] propertyListForType:iTunesPBoardType];
            NSDictionary* iTunesTracks = [iTunesDroppedData objectForKey:@"Tracks"];
            NSDictionary* playlistDropped = [[iTunesDroppedData objectForKey:@"Playlists"] objectAtIndex:0];
            NSArray* tracksIndexes = [playlistDropped objectForKey:@"Playlist Items"];
            NSURL* trackFileUrl;
            NSMutableArray* droppedURLs = [[[NSMutableArray alloc] initWithCapacity:[tracksIndexes count]] autorelease];

            for (NSDictionary* iTunesTrackNumber in tracksIndexes) {
                NSNumber* trackNum = [iTunesTrackNumber objectForKey:@"Track ID"];
                NSDictionary* track = [iTunesTracks objectForKey:[trackNum stringValue]];
                trackFileUrl = [NSURL URLWithString:[track objectForKey:@"Location"]];
                if ([trackFileUrl isFileURL])
                    [droppedURLs addObject:trackFileUrl];
            }
            if ([droppedURLs count] > 0) {
                [mDocument insertPlaylistItems:droppedURLs atRow:row sortToplist:NO];
                success = YES;
            }
        } else if ([droppedTypes containsObject:NSPasteboardTypeFileURL]) {
            NSMutableArray* droppedURLs = [[[NSMutableArray alloc] init] autorelease];

            // Read file URLs from each pasteboard item
            NSArray* pasteboardItems = [pboard pasteboardItems];
            for (NSPasteboardItem* item in pasteboardItems) {
                NSString* urlString = [item stringForType:NSPasteboardTypeFileURL];
                if (urlString) {
                    NSURL* url = [NSURL URLWithString:urlString];
                    if (url && [url isFileURL]) {
                        [droppedURLs addObject:url];
                    }
                }
            }

            if ([droppedURLs count] > 0) {
                [mDocument insertPlaylistItems:droppedURLs atRow:row sortToplist:YES];
                success = YES;
            }
        } else if ([droppedTypes containsObject:NSPasteboardTypeURL]) {
            NSURL* droppedURL = [NSURL URLFromPasteboard:pboard];
            if ([droppedURL isFileURL]) {
                [mDocument insertPlaylistItems:[NSArray arrayWithObject:droppedURL] atRow:row sortToplist:YES];
                success = YES;
            }
        }
    }
    return success;
}

@end
