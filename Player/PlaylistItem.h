#import <Cocoa/Cocoa.h>

@interface PlaylistItem : NSObject {
    NSURL* fileURL;
    NSString* title;
    NSString* artist;
    NSString* composer;
    NSString* album;
    UInt64 trackNumber;
    SInt64 lengthFrames;
    float durationInSeconds;
}
@property (readwrite, copy) NSURL* fileURL;
@property (readwrite, copy) NSString* title;
@property (readwrite, copy) NSString* artist;
@property (readwrite, copy) NSString* composer;
@property (readwrite, copy) NSString* album;
@property (readwrite) SInt64 lengthFrames;
@property (readwrite) UInt64 trackNumber;
@property (readwrite) float durationInSeconds;
@end