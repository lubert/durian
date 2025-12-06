#import "AudioFileLoader.h"

#include <samplerate.h>
#include <sndfile.h>

@interface AudioFileSndFileLoader : AudioFileLoader {
    SNDFILE* mSndFileRef;
    SF_INFO mSF_Info;

    // For libSampleRate
    SRC_STATE* mLibSrcState;
    Float32* mTmpSRCdata;
    Float32* mTmplibSampleRateOutBuf; // Used for Integer Mode with libSampleRate

    // For CoreAudio SRC
    AudioConverterRef mCoreAudioConverterRef;

    Float64* mTmpSndFileSourceData; // Used for Integer mode
}

@end