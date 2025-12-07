#import "PlaylistView.h"
#import "PlaylistArrayController.h"

// Custom cell for vertical centering
@interface VerticallyCenteredTextFieldCell : NSTextFieldCell
@end

@implementation VerticallyCenteredTextFieldCell

- (NSRect)titleRectForBounds:(NSRect)theRect
{
    NSRect titleFrame = [super titleRectForBounds:theRect];
    NSSize titleSize = [[self attributedStringValue] size];
    titleFrame.origin.y = theRect.origin.y + (theRect.size.height - titleSize.height) / 2.0;
    return titleFrame;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
    NSRect titleRect = [self titleRectForBounds:cellFrame];
    [[self attributedStringValue] drawInRect:titleRect];
}

@end

@implementation PlaylistView

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self registerForDraggedTypes:[NSArray arrayWithObjects:AUDPlaylistItemPBoardType,
                                      NSFilenamesPboardType, NSPasteboardTypeURL,
                                      iTunesPBoardType, nil]];

    // Use system font size for better accessibility
    NSFont* systemFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    CGFloat fontSize = [systemFont pointSize];

    // Calculate row height based on font size with fixed padding
    CGFloat verticalPadding = 8.0; // 4 pixels top + 4 pixels bottom
    CGFloat rowHeight = fontSize + verticalPadding;
    [self setRowHeight:rowHeight];

    // Enable row size style for better vertical alignment
    [self setRowSizeStyle:NSTableViewRowSizeStyleDefault];

    // Replace all text cells with vertically centered cells
    for (NSTableColumn* column in [self tableColumns]) {
        NSCell* dataCell = [column dataCell];
        if ([dataCell isKindOfClass:[NSTextFieldCell class]]) {
            NSTextFieldCell* oldCell = (NSTextFieldCell*)dataCell;

            // Create new vertically centered cell
            VerticallyCenteredTextFieldCell* newCell = [[VerticallyCenteredTextFieldCell alloc] init];

            // Use system font size for accessibility
            [newCell setFont:systemFont];
            [newCell setAlignment:[oldCell alignment]];
            [newCell setLineBreakMode:NSLineBreakByTruncatingTail];
            [newCell setEditable:[oldCell isEditable]];
            [newCell setSelectable:[oldCell isSelectable]];
            [newCell setFormatter:[oldCell formatter]];

            [column setDataCell:newCell];
            [newCell release];
        }
    }
}

// Take over space key event to activate the menu command for play/pause
- (void)keyDown:(NSEvent*)theEvent
{
    if ([[theEvent characters] compare:@" "] == NSOrderedSame) {
        [[NSApp mainMenu] performKeyEquivalent:theEvent];
    } else if ([[theEvent charactersIgnoringModifiers] isEqualToString:@"\x7F"]) {
        // Delete or Backspace key pressed
        if ([[self dataSource] respondsToSelector:@selector(remove:)]) {
            [[self dataSource] performSelector:@selector(remove:) withObject:self];
        }
    } else
        [super keyDown:theEvent];
}

- (void)keyUp:(NSEvent*)theEvent
{
    if ([[theEvent characters] compare:@" "] == NSOrderedSame) {

    } else
        [super keyUp:theEvent];
}

// Disable the focus ring
- (NSFocusRingType)focusRingType
{
    return NSFocusRingTypeNone;
}

@end
