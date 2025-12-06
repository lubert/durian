#import "AudioFileLoader.h"
#include <FLAC/stream_decoder.h>
#include <samplerate.h>

@interface AudioFileFLACLoader : AudioFileLoader {
    FLAC__StreamDecoder* mFLACStreamDecoder;

    int mFLACchannels;
    int mFLACmaxBlockSize;

    // Private data used by the FLAC decoding callback
    UInt64 mFLACreadFrames;
    UInt64 mFLACtmpInt32bufUnreadFrames;
    UInt64 mFLACbufferSizeInBytes;
    UInt32 mFLACLoadedSeconds;
    Float32* mFLACbufferData;
    Float32* tmpSRCbuf;
    Float32* tmplibSampleRateOutBuf; // Used for Integer Mode with libSampleRate
    SInt32* tmpInt32buf; // Used for Integer mode with no SRC
    SRC_STATE* mlibSrcState;
    AudioConverterRef mCoreAudioConverterRef;
}
@property (readonly, getter=FLACmaxBlockSize) int mFLACmaxBlockSize;
@end