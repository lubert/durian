#import "PlaylistView_Delegate.h"
#import "PlaylistDocument.h"

@implementation PlaylistView_Delegate

- (void)setDocument:(PlaylistDocument*)mydoc
{
    document = mydoc;
}

- (NSCell*)tableView:(NSTableView*)tableView dataCellForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
    NSTextFieldCell* cell = [tableColumn dataCell];
    CGFloat systemFontSize = [NSFont systemFontSize];
    BOOL isSelected = [tableView isRowSelected:row];

    if (document) {
        // Set text color based on selection state
        if (isSelected) {
            // Use system color for selected text (white on blue highlight)
            [cell setTextColor:[NSColor selectedTextColor]];
        } else if (row == [document playingTrackIndex]) {
            [cell setTextColor:[NSColor systemBlueColor]];
        } else {
            [cell setTextColor:[NSColor labelColor]];
        }

        // Set font based on playing state
        if (row == [document playingTrackIndex]) {
            [cell setFont:[NSFont boldSystemFontOfSize:systemFontSize]];
        } else {
            [cell setFont:[NSFont systemFontOfSize:systemFontSize]];
        }
    } else
        [cell setTextColor:[NSColor labelColor]];

    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification*)aNotification
{
    NSTableView* tableView = [aNotification object];

    NSDictionary* plTrackDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithLong:[tableView selectedRow]] forKey:@"index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:AUDPlaylistSelectionCursorChangedNotification
                                                        object:self
                                                      userInfo:plTrackDict];
}

@end