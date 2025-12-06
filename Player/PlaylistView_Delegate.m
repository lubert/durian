/*
 PlaylistView_Delegate.m

 This file is part of Durian.

 Durian is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Durian is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Durian.  If not, see <http://www.gnu.org/licenses/>.

 Original code written by Damien Plisson 09/2010 */

#import "PlaylistView_Delegate.h"
#import "PlaylistDocument.h"


@implementation PlaylistView_Delegate

-(void)setDocument:(PlaylistDocument*)mydoc
{
	document = mydoc;
}

-(NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSTextFieldCell *cell = [tableColumn dataCell];
	CGFloat systemFontSize = [NSFont systemFontSize];
	BOOL isSelected = [tableView isRowSelected:row];

	if(document) {
		// Set text color based on selection state
		if (isSelected) {
			// Use system color for selected text (white on blue highlight)
			[cell setTextColor: [NSColor selectedTextColor]];
		} else if (row == [document playingTrackIndex]) {
			[cell setTextColor: [NSColor systemBlueColor]];
		} else {
			[cell setTextColor: [NSColor labelColor]];
		}

		// Set font based on playing state
		if (row == [document playingTrackIndex]) {
			[cell setFont:[NSFont boldSystemFontOfSize:systemFontSize]];
		} else {
			[cell setFont:[NSFont systemFontOfSize:systemFontSize]];
		}
	}
	else [cell setTextColor: [NSColor labelColor]];

	return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSTableView *tableView = [aNotification object];

	NSDictionary *plTrackDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithLong:[tableView selectedRow]] forKey:@"index"];
	[[NSNotificationCenter defaultCenter] postNotificationName:AUDPlaylistSelectionCursorChangedNotification
														object:self userInfo:plTrackDict];
}

@end