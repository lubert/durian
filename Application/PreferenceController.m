#include <sys/sysctl.h>
#include <sys/types.h>

#import "AudioOutput.h"
#import "PreferenceController.h"

#pragma mark User preference keys & notifications

NSString* const AUDAppearanceMode = @"AppearanceMode";
NSString* const AUDUISkinTheme = @"UISkinTheme";
NSString* const AUDUseAppleRemote = @"UseAppleRemote";
NSString* const AUDUseMediaKeys = @"UseMediaKeys";
NSString* const AUDUseMediaKeysForVolumeControl = @"UseMediaKeysForVolumeControl";
NSString* const AUDHogMode = @"HogMode";
NSString* const AUDIntegerMode = @"IntegerMode";
NSString* const AUDPreferredAudioDeviceUID = @"PreferredAudioDeviceUID";
NSString* const AUDPreferredAudioDeviceName = @"PreferredAudioDeviceName";
NSString* const AUDSampleRateSwitchingLatency = @"SampleRateSwitchingLatencyIndex";
NSString* const AUDMaxSampleRateLimit = @"MaxSampleRateLimitIndex";
NSString* const AUDMaxAudioBufferSize = @"MaxAudioBufferSize";
NSString* const AUDForceUpsamlingType = @"ForceUpsamplingType";
NSString* const AUDSampleRateConverterModel = @"SampleRateConverterModelIndex";
NSString* const AUDSampleRateConverterQuality = @"SampleRateConverterQuality";
NSString* const AUDForceMaxIOBufferSize = @"UseMaximumIOBufferSize";
NSString* const AUDUseUTF8forM3U = @"UseUTF8forM3U";
NSString* const AUDOutsideOpenedPlaylistPlaybackAutoStart = @"OutsideOpenedPlaylistPlaybackAutoStart";
NSString* const AUDAutosavePlaylist = @"AutosavePlaylist";

NSString* const AUDLoopModeActive = @"LoopModeActive";
NSString* const AUDShuffleModeActive = @"ShuffleModeActive";

NSString* const AUDPreferredDeviceChangeNotification = @"AUDPreferredDeviceChanged";
NSString* const AUDAppleRemoteUseChangeNotification = @"AUDAppleRemoteUseChangeNotification";
NSString* const AUDMediaKeysUseChangeNotification = @"AUDMediaKeysUseChangeNotification";

#pragma mark PreferenceController implementation

@implementation PreferenceController

- (id)init
{
    audioDevicesUIDs = nil;

    if (![super initWithWindowNibName:@"Preferences"])
        return nil;
    return self;
}

- (void)dealloc
{
    if (audioDevicesUIDs)
        [audioDevicesUIDs release];
    [super dealloc];
}

- (void)windowDidLoad
{
    int maxAllowedAudioBufSize;
    int mib[] = { CTL_HW, HW_MEMSIZE };
    SInt64 ramSize;
    size_t propSize = sizeof(UInt64);

    sysctl(mib, 2, &ramSize, &propSize, NULL, 0);
    ramSize = (ramSize >> 20) - 1024; // Leave 1GB to OSX to run
    maxAllowedAudioBufSize = ((int)ramSize >> 10) << 10;
    if (maxAllowedAudioBufSize < 512)
        maxAllowedAudioBufSize = 512;
    // Cap at 4096 MB maximum
    if (maxAllowedAudioBufSize > 4096)
        maxAllowedAudioBufSize = 4096;

    [maxAudioBufferSizeSlider setMaxValue:maxAllowedAudioBufSize];
    [maxAudioBufferSizeSlider setNumberOfTickMarks:(maxAllowedAudioBufSize - 256) / 128 + 1];
    [maxAudioBufferSizeSlider setIntValue:(int)(2 * [[NSUserDefaults standardUserDefaults] integerForKey:AUDMaxAudioBufferSize])];
    [maxAudioBufferSizeValue setIntValue:[maxAudioBufferSizeSlider intValue]];

    [useAppleRemote setState:[[NSUserDefaults standardUserDefaults] boolForKey:AUDUseAppleRemote]];

    [preferredAudioDevice setStringValue:[[NSUserDefaults standardUserDefaults] stringForKey:AUDPreferredAudioDeviceName]];

    [hogMode setState:[[NSUserDefaults standardUserDefaults] boolForKey:AUDHogMode]];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:AUDHogMode]) {
        [integerMode setState:[[NSUserDefaults standardUserDefaults] boolForKey:AUDIntegerMode]];
        [integerMode setEnabled:YES];
    } else {
        [integerMode setState:NO];
        [integerMode setEnabled:NO];
    }

    [useKbdMediaKeys setState:[[NSUserDefaults standardUserDefaults] boolForKey:AUDUseMediaKeys]];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:AUDUseMediaKeys]) {
        [useKbdMediaKeysForVolumeControl setEnabled:YES];
        [useKbdMediaKeysForVolumeControl setState:[[NSUserDefaults standardUserDefaults] boolForKey:AUDUseMediaKeysForVolumeControl]];
    } else {
        [useKbdMediaKeysForVolumeControl setEnabled:NO];
        [useKbdMediaKeysForVolumeControl setState:NO];
    }

    NSToolbar* toolbar = [[self window] toolbar];
    NSArray* allItems = [toolbar items];
    for (NSToolbarItem* item in allItems) {
        NSImage* icon = nil;
        NSString* identifier = [item itemIdentifier];

        if ([identifier isEqualToString:@"General"]) {
            icon = [NSImage imageWithSystemSymbolName:@"gearshape" accessibilityDescription:@"General"];
        } else if ([identifier isEqualToString:@"AudioSystem"]) {
            icon = [NSImage imageWithSystemSymbolName:@"hifispeaker" accessibilityDescription:@"Audio System"];
        } else if ([identifier isEqualToString:@"AudioFilters"]) {
            icon = [NSImage imageWithSystemSymbolName:@"waveform" accessibilityDescription:@"Upsampling"];
        }

        if (icon) {
            // Configure the icon size for toolbar
            NSImageSymbolConfiguration* config = [NSImageSymbolConfiguration configurationWithPointSize:22.0 weight:NSFontWeightRegular scale:NSImageSymbolScaleMedium];
            icon = [icon imageWithSymbolConfiguration:config];
            [item setImage:icon];
        }
    }

    [toolbar setSelectedItemIdentifier:@"General"];
    [preferenceTabs selectTabViewItemAtIndex:0];
    [[self window] setTitle:@"General"];
    [[self window] setToolbarStyle:NSWindowToolbarStylePreference];

    activeDeviceMaxSplRate = 192000; // Default that should be overriden by the setActiveDeviceDesc call

    // Set sample rate indicator colors for dark mode support
    NSColor* supportedColor = [NSColor systemGreenColor];
    [splRate44_1kHz setTextColor:supportedColor];
    [splRate48kHz setTextColor:supportedColor];
    [splRate88_2kHz setTextColor:supportedColor];
    [splRate96kHz setTextColor:supportedColor];
    [splRate176_4kHz setTextColor:supportedColor];
    [splRate192kHz setTextColor:supportedColor];
    [splRateHigherThan192kHz setTextColor:supportedColor];

    // Set the tab view delegate for handling tab changes
    [preferenceTabs setDelegate:self];

    // Set initial window size for the first tab
    [self resizeWindowForTabIndex:0 animate:NO];
}

#pragma mark NSTabViewDelegate

- (void)resizeWindowForTabIndex:(NSInteger)tabIndex animate:(BOOL)animate
{
    NSWindow* window = [self window];
    NSRect windowFrame = [window frame];
    NSRect contentRect = [[window contentView] frame];

    // Calculate the window chrome height (difference between window and content height)
    CGFloat chromeHeight = NSHeight(windowFrame) - NSHeight(contentRect);

    // Determine the desired content height based on the selected tab
    CGFloat desiredContentHeight;

    switch (tabIndex) {
    case 0: // General tab
        desiredContentHeight = 330.0;
        break;
    case 1: // Audio System tab
        desiredContentHeight = 420.0;
        break;
    case 2: // Upsampling tab
        desiredContentHeight = 280.0;
        break;
    default:
        desiredContentHeight = 420.0;
        break;
    }

    // Calculate the new window height
    CGFloat newWindowHeight = desiredContentHeight + chromeHeight;

    // Calculate the new frame, maintaining the top-left corner position
    NSRect newFrame = windowFrame;
    newFrame.origin.y += NSHeight(windowFrame) - newWindowHeight;
    newFrame.size.height = newWindowHeight;

    // Resize the window
    [window setFrame:newFrame display:YES animate:animate];
}

- (void)tabView:(NSTabView*)tabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
    NSInteger tabIndex = [tabView indexOfTabViewItem:tabViewItem];
    [self resizeWindowForTabIndex:tabIndex animate:YES];
}

#pragma mark User preferences external updates

- (void)setAvailableDevicesList:(NSArray*)devicesList
{
    AudioDeviceDescription* audioDevDesc;
    NSString* preferredDevUID = [[NSUserDefaults standardUserDefaults] stringForKey:AUDPreferredAudioDeviceUID];

    [audioCardsList removeAllItems];

    if (audioDevicesUIDs)
        [audioDevicesUIDs release];
    audioDevicesUIDs = [[NSMutableArray alloc] initWithCapacity:[devicesList count]];

    NSEnumerator* enumerator = [devicesList objectEnumerator];

    // Directly populate the undelying menu to bypass the duplicate removal feature
    NSMenu* popupMenu = [audioCardsList menu];

    while ((audioDevDesc = [enumerator nextObject]) != nil) {
        [popupMenu addItemWithTitle:audioDevDesc.name action:nil keyEquivalent:@""];
        [audioDevicesUIDs addObject:audioDevDesc.UID];
        if ([audioDevDesc.UID compare:preferredDevUID] == NSOrderedSame)
            [preferredAudioDevice setStringValue:audioDevDesc.name];
    }
}

- (void)setActiveDeviceDesc:(AudioDeviceDescription*)audioDevDesc
{
    NSColor* supportedColor = [NSColor systemGreenColor];
    NSColor* unsupportedColor = [NSColor secondaryLabelColor];
    [splRate44_1kHz setTextColor:([audioDevDesc isSampleRateHandled:44100.0 withLimit:NO] ? supportedColor : unsupportedColor)];
    [splRate48kHz setTextColor:([audioDevDesc isSampleRateHandled:48000.0 withLimit:NO] ? supportedColor : unsupportedColor)];
    [splRate88_2kHz setTextColor:([audioDevDesc isSampleRateHandled:88200.0 withLimit:NO] ? supportedColor : unsupportedColor)];
    [splRate96kHz setTextColor:([audioDevDesc isSampleRateHandled:96000.0 withLimit:NO] ? supportedColor : unsupportedColor)];
    [splRate176_4kHz setTextColor:([audioDevDesc isSampleRateHandled:176400.0 withLimit:NO] ? supportedColor : unsupportedColor)];
    [splRate192kHz setTextColor:([audioDevDesc isSampleRateHandled:192000.0 withLimit:NO] ? supportedColor : unsupportedColor)];

    [activeAudioDevice setStringValue:audioDevDesc.name];

    activeDeviceMaxSplRate = (NSUInteger)[audioDevDesc maxSampleRate];

    if (activeDeviceMaxSplRate > 192000) {
        [splRateHigherThan192kHz setTextColor:supportedColor];
        if ((activeDeviceMaxSplRate % 1000) != 0)
            [splRateHigherThan192kHz setStringValue:[NSString stringWithFormat:@"%.0f", (float)activeDeviceMaxSplRate / 1000]];
        else
            [splRateHigherThan192kHz setStringValue:[NSString stringWithFormat:@"%.1f", (float)activeDeviceMaxSplRate / 1000]];
        [splRateHigherThan192kHz setHidden:NO];
    } else
        [splRateHigherThan192kHz setHidden:YES];

    UInt64 maxSeconds = (UInt64)[maxAudioBufferSizeSlider intValue] * 1024 * 1024 / 2 / (44100 * 8);
    int minutes = (int)(maxSeconds / 60);
    [maxTrackLengthAt44_1 setStringValue:[NSString stringWithFormat:@"%d min at 44.1kHz", minutes]];
    if (activeDeviceMaxSplRate > 0.0) {
        maxSeconds = (UInt64)[maxAudioBufferSizeSlider intValue] * 1024 * 1024 / 2 / (activeDeviceMaxSplRate * 8);
        minutes = (int)(maxSeconds / 60);
        if ((activeDeviceMaxSplRate % 1000) != 0)
            [maxTrackLengthAt192 setStringValue:[NSString stringWithFormat:@"%d min at %.1fkHz", minutes, (float)activeDeviceMaxSplRate / 1000]];
        else
            [maxTrackLengthAt192 setStringValue:[NSString stringWithFormat:@"%d min at %.0fkHz", minutes, (float)activeDeviceMaxSplRate / 1000]];
    }
}

#pragma mark Tabs selection

- (IBAction)selectGeneralTab:(id)sender
{
    [preferenceTabs selectTabViewItemAtIndex:0];
    [[self window] setTitle:@"General"];
}

- (IBAction)selectAudioDeviceTab:(id)sender
{
    [preferenceTabs selectTabViewItemAtIndex:1];
    [[self window] setTitle:@"Audio System"];
}

- (IBAction)selectAudioFiltersTab:(id)sender
{
    [preferenceTabs selectTabViewItemAtIndex:2];
    [[self window] setTitle:@"Upsampling"];
}

#pragma mark Preferred device change

- (IBAction)raisePreferredDeviceChangeSheet:(id)sender
{
    [[self window] beginSheet:preferenceChangeSheet completionHandler:nil];
}

- (IBAction)cancelPreferredDeviceChange:(id)sender
{
    [NSApp endSheet:preferenceChangeSheet];
    [preferenceChangeSheet orderOut:nil];
}

- (IBAction)changePreferredDevice:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[audioCardsList titleOfSelectedItem] forKey:AUDPreferredAudioDeviceName];
    [[NSUserDefaults standardUserDefaults] setObject:[audioDevicesUIDs objectAtIndex:[audioCardsList indexOfSelectedItem]] forKey:AUDPreferredAudioDeviceUID];
    [[NSNotificationCenter defaultCenter] postNotificationName:AUDPreferredDeviceChangeNotification object:self];
    [preferredAudioDevice setStringValue:[audioCardsList titleOfSelectedItem]];
    [NSApp endSheet:preferenceChangeSheet];
    [preferenceChangeSheet orderOut:nil];
}

- (IBAction)changeMaxAudioBufferSize:(id)sender
{
    UInt64 maxSeconds = (UInt64)[maxAudioBufferSizeSlider intValue] * 1024 * 1024 / 2 / (44100 * 8);
    int minutes = (int)(maxSeconds / 60);
    [maxTrackLengthAt44_1 setStringValue:[NSString stringWithFormat:@"%d min at 44.1kHz", minutes]];
    maxSeconds = (UInt64)[maxAudioBufferSizeSlider intValue] * 1024 * 1024 / 2 / (activeDeviceMaxSplRate * 8);
    minutes = (int)(maxSeconds / 60);
    if ((activeDeviceMaxSplRate % 1000) != 0)
        [maxTrackLengthAt192 setStringValue:[NSString stringWithFormat:@"%d min at %.1fkHz", minutes, (float)activeDeviceMaxSplRate / 1000]];
    else
        [maxTrackLengthAt192 setStringValue:[NSString stringWithFormat:@"%d min at %.0fkHz", minutes, (float)activeDeviceMaxSplRate / 1000]];

    [maxAudioBufferSizeValue setIntValue:[maxAudioBufferSizeSlider intValue]];

    [[NSUserDefaults standardUserDefaults] setInteger:[maxAudioBufferSizeSlider intValue] / 2 forKey:AUDMaxAudioBufferSize];
}

- (IBAction)changeHogMode:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:[hogMode state] forKey:AUDHogMode];

    // Disable and show as unselected the Integer Mode as it can happen only in hog mode
    if ([hogMode state]) {
        [integerMode setState:[[NSUserDefaults standardUserDefaults] boolForKey:AUDIntegerMode]];
        [integerMode setEnabled:YES];
    } else {
        [integerMode setState:NO];
        [integerMode setEnabled:NO];
    }
}

- (IBAction)changeIntegerMode:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:[integerMode state] forKey:AUDIntegerMode];
}

#pragma mark General tab settings

- (IBAction)changeAppearanceMode:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setInteger:[appearanceMode indexOfSelectedItem] forKey:AUDAppearanceMode];
    [[NSNotificationCenter defaultCenter] postNotificationName:AUDAppearanceMode object:self];
}

- (IBAction)changeUISkinTheme:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setInteger:[uiSkinTheme indexOfSelectedItem] forKey:AUDUISkinTheme];
    [[NSNotificationCenter defaultCenter] postNotificationName:AUDUISkinTheme object:self];
}

- (IBAction)changeUseAppleRemote:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:[useAppleRemote state] forKey:AUDUseAppleRemote];
    [[NSNotificationCenter defaultCenter] postNotificationName:AUDAppleRemoteUseChangeNotification object:self];
}

- (IBAction)changeUseKbdMediaKeys:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:[useKbdMediaKeys state] forKey:AUDUseMediaKeys];

    if ([useKbdMediaKeys state]) {
        [useKbdMediaKeysForVolumeControl setEnabled:YES];
        [useKbdMediaKeysForVolumeControl setState:[[NSUserDefaults standardUserDefaults] boolForKey:AUDUseMediaKeysForVolumeControl]];
    } else {
        [useKbdMediaKeysForVolumeControl setEnabled:NO];
        [useKbdMediaKeysForVolumeControl setState:NO];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:AUDMediaKeysUseChangeNotification object:self];
}

- (IBAction)changeUseKbdMediaKeysForVolumeControl:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:[useKbdMediaKeysForVolumeControl state] forKey:AUDUseMediaKeysForVolumeControl];
    [[NSNotificationCenter defaultCenter] postNotificationName:AUDMediaKeysUseChangeNotification object:self];
}

@end