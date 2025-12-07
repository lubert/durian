#import "AudioOutput.h"
#import <Cocoa/Cocoa.h>
#import <HIDRemote.h>
#import <MediaPlayer/MediaPlayer.h>
#import <SPMediaKeyTap.h>

@class PlaylistDocument;
@class PreferenceController;
@class DebugController;

typedef struct {
    UInt64 firstLoadedFrame;
    UInt64 lastLoadedFrame;
    UInt64 lastFrameToLoad;
    UInt64 trackTotalLengthinFrames;
    bool loadCompleted;
} AUDBufferLoadStatus;

@interface AppController : NSObject <HIDRemoteDelegate> {
    AudioOutput* audioOut;
    PreferenceController* preferenceController;
    DebugController* debugController;
    SPMediaKeyTap* mKeyTap;

    AUDBufferLoadStatus mAudioBuffersLoadStatus[2];

    BOOL mNowPlayingEnabled;
    BOOL mNowPlayingIntegrationSetUp;
    id mPlayCommandTarget;
    id mPauseCommandTarget;
    id mNextTrackCommandTarget;
    id mPreviousTrackCommandTarget;
    id mChangePlaybackPositionCommandTarget;

    IBOutlet NSWindow* parentWindow;
    IBOutlet NSTextField* currentDACSampleRate;
    IBOutlet NSImageView* integerModeStatus;

    IBOutlet NSView* songTextView;
    IBOutlet NSTextField* songTitle;
    IBOutlet NSTextField* songAlbum;
    IBOutlet NSTextField* songComposer;
    IBOutlet NSTextField* songArtist;
    IBOutlet NSTextField* songDuration;
    IBOutlet NSImageView* songCoverImage;
    IBOutlet NSTextField* songSampleRate;
    IBOutlet NSTextField* songBitDepth;

    IBOutlet NSButton* powerButton;
    IBOutlet NSButton* displayOffButton;
    IBOutlet NSButton* togglePlaylistButton;
    IBOutlet NSTextField* powerText;
    IBOutlet NSTextField* displayOffText;
    IBOutlet NSTextField* playlistText;

    IBOutlet NSTextField* songCurrentPlayingTime;
    IBOutlet NSSlider* songCurrentPlayingPosition;
    IBOutlet NSImageView* songLoadStatus;

    IBOutlet NSSlider* masterDeviceVolume;
    IBOutlet NSTextField* masterDeviceVolumeText;
    IBOutlet NSTextField* masterDeviceVolumeValue;
    IBOutlet NSTextField* masterDeviceVolumePlus;
    IBOutlet NSTextField* masterDeviceVolumeMinus;

    IBOutlet NSButton* playPauseButton;
    IBOutlet NSButton* stopButton;
    IBOutlet NSButton* prevButton;
    IBOutlet NSButton* nextButton;
    IBOutlet NSTextField* playText;
    IBOutlet NSTextField* stopText;
    IBOutlet NSTextField* prevText;
    IBOutlet NSTextField* nextText;

    IBOutlet NSButton* playRepeatButton;
    IBOutlet NSButton* playShuffleButton;

    IBOutlet NSTextField* displayOverload;

    PlaylistDocument* mPlaylistDoc;

    NSURL* mFirstFileToPlay; // Used during playback start process

    bool mSongSliderPositionGrabbed; // Used by the slider control
    bool mPlaybackStarting;
    bool mPlaybackInitiating;
    bool mIsAudioMute;

    // String attributes, defined at object level, and not local for performance optimization
    // (limit malloc/free) operations
    NSDictionary* mSRCStringAttributes;
    NSDictionary* mLCDSelectedStringAttributes;
    NSDictionary* mLCDStringAttributes;
    NSDictionary* mDockStringAttributes;
}

- (IBAction)togglePlaylistDrawer:(id)sender;
- (IBAction)showPreferencePanel:(id)sender;
- (IBAction)showDebugPanel:(id)sender;
- (IBAction)openDonationPage:(id)sender;

- (IBAction)performLoadPlaylist:(id)sender;
- (IBAction)performSavePlaylist:(id)sender;
- (IBAction)performSavePlaylistAs:(id)sender;
- (IBAction)deletePlaylistItem:(id)sender;
- (IBAction)prunePlaylist:(id)sender;

- (IBAction)playPause:(id)sender;
- (void)startPlaying;
- (void)startPlayingPhase2;
- (void)startPlayingPhase3;
- (void)abortPlayingStart:(NSError*)error;
- (IBAction)stop:(id)sender;

- (IBAction)seekPrevious:(id)sender;
- (IBAction)seekNext:(id)sender;

- (IBAction)positionSliderMoved:(id)sender;
- (void)seekPosition:(id)sender;

- (IBAction)toggleRepeat:(id)sender;
- (IBAction)toggleShuffle:(id)sender;

- (IBAction)setMasterVolume:(id)sender;
- (void)setVolumeControl:(UInt32)availVolumeControls;

- (void)updateMetadataDisplay:(NSString*)title
                        album:(NSString*)album_name
                       artist:(NSString*)artist_name
                     composer:(NSString*)composer_name
                   coverImage:(NSImage*)cover_image
                     duration:(Float64)duration_seconds
                  integerMode:(BOOL)isIntegerModeOn
                     bitDepth:(UInt32)bitsPerFrame
               fileSampleRate:(Float64)fileSampleRateInHz
            playingSampleRate:(Float64)playingSampleRateInHz;

- (void)updateCurrentTrackTotalLength:(UInt64)totalFrames
                             duration:(Float64)duration_seconds
                            forBuffer:(int)bufferIdx; // Used when initial duration is only approximate, and definitive comes at end of file read
- (void)updateCurrentPlayingTime;
- (void)updateLoadStatus:(UInt64)firstLoadedFrame
                      to:(UInt64)lastLoadedFrame
                    upTo:(UInt64)lastFrameToLoad
               forBuffer:(int)bufferLoading
               completed:(BOOL)isComplete
                   reset:(BOOL)isReset;
- (void)resetLoadStatus:(BOOL)onlyForNonPlaying;

// Audio HAL notifications
- (void)notifyProcessorOverload;
- (void)clearProcessorOverload;
- (void)notifyDeviceRemoved;
- (void)notifyDevicesListUpdated;
- (void)notifyDeviceVolumeChanged;
- (void)notifyDeviceDataSourceChanged;

- (void)notifyBufferPlayed:(UInt32)bufferDirty;

- (bool)fillBufferWithNext:(int)bufferToFill;

// Now Playing integration
- (void)setupNowPlayingIntegration;
- (void)tearDownNowPlayingIntegration;
- (void)updateNowPlayingInfo;
- (void)clearNowPlayingInfo;
- (void)getCurrentPlaybackPosition:(Float64*)outPosition duration:(Float64*)outDuration;
@end

#define NSLocalizedStringWithDefault(key, default) \
    [[NSBundle mainBundle] localizedStringForKey:(key) value:(default)table:nil]