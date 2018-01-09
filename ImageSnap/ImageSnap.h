//
//  ImageSnap.h
//  ImageSnap
//
//  Created by Robert Harder on 9/10/09.
//  Updated by Sam Green for Mavericks (OSX 10.9) on 11/22/13
//  Updated by Vitalii Parovishnyk for Yosemite (OSX 10.10) on 14/01/15
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

@interface ImageSnap : NSObject

/**
 * Returns all attached AVCaptureDevice objects that have video.
 * This includes video-only devices (AVMediaTypeVideo) and
 * audio/video devices (AVMediaTypeMuxed).
 *
 * @return autoreleased array of video devices
 */
+ (NSArray <AVCaptureDevice *> * _Nonnull)videoDevices;

/**
 * Returns the default AVCaptureDevice object for video
 * or nil if none is found.
 */
+ (AVCaptureDevice * _Nonnull)defaultVideoDevice;

/**
 * Returns the AVCaptureDevice with the given name
 * or nil if the device cannot be found.
 */
+ (AVCaptureDevice * _Nonnull)deviceNamed:(NSString * _Nonnull)name;

/**
 * Primary one-stop-shopping message for capturing an image.
 * Activates the video source, saves a frame, stops the source,
 * and saves the file.
 */
+ (BOOL)saveSnapshotFrom:(AVCaptureDevice * _Nonnull)device
                  toFile:(NSString * _Nonnull)path;

+ (BOOL)saveSnapshotFrom:(AVCaptureDevice * _Nonnull)device
                  toFile:(NSString * _Nonnull)path
              withWarmup:(NSNumber * _Nullable)warmup;

+ (BOOL)saveSnapshotFrom:(AVCaptureDevice * _Nonnull)device
                  toFile:(NSString * _Nonnull)path
              withWarmup:(NSNumber * _Nullable)warmup
           withTimelapse:(NSNumber * _Nullable)timelapse;

/**
 * Returns current snapshot or nil if there is a problem
 * or session is not started.
 */
@property (nonatomic, readonly, copy, nonnull) NSImage *snapshot;

@end
