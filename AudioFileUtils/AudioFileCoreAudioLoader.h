#ifndef __AUDIOCOREAUDIOFILELOADER_H__
#define __AUDIOCOREAUDIOFILELOADER_H__

#import "AudioFileLoader.h"
#include <samplerate.h>

@interface AudioFileCoreAudioLoader : AudioFileLoader {
    AudioStreamBasicDescription mInputStreamFormat;
    ExtAudioFileRef mInputFileRef;

    // For libSampleRate
    SRC_STATE* mLibSrcState;
    Float32* mTmpSRCdata;

    AudioConverterRef mCoreAudioConverterRef; // For Integer mode format convertion
    Float32* mTmplibSampleRateOutBuf; // Used for Integer Mode with libSampleRate
}
@end

#endif