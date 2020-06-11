#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "Flauto.h"
#import "FlutterFFmpegPlugin.h"
#import "FlutterSoundPlayer.h"
#import "FlutterSoundRecorder.h"
#import "Track.h"
#import "TrackPlayer.h"

FOUNDATION_EXPORT double flutter_soundVersionNumber;
FOUNDATION_EXPORT const unsigned char flutter_soundVersionString[];

