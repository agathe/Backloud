//
// Created by Agathe Battestini on 8/22/14.
// Copyright (c) 2014 Agathe Battestini. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "ABAudioMan.h"
#import "MeterTable.h"

@interface ABAudioMan()<AVAudioRecorderDelegate> {
    MeterTable _meterTable;
}


@property (nonatomic, strong) AVAudioRecorder * recorder;
@property (nonatomic, strong) NSTimer *levelTimer;
@property (nonatomic, assign) double lowPassResults;

//@property (nonatomic, strong) MeterTable *meterTable;

@end

@implementation ABAudioMan {

}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    NSError *setCategoryError = nil;

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&setCategoryError];
    [audioSession setActive:YES error:nil];
    if (setCategoryError)
        NSLog(@"Error setting category! %d", setCategoryError.code);

    // New recording path.
    NSString *recorderFilePath = [NSString stringWithFormat:@"%@/%@.caf",
                    [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"], @"cache"];
    NSURL *url = [NSURL fileURLWithPath:recorderFilePath];

    NSDictionary *settings =
            [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithFloat: 44100.0],                 AVSampleRateKey,
            [NSNumber numberWithInt: kAudioFormatAppleLossless], AVFormatIDKey,
            [NSNumber numberWithInt: 1],                         AVNumberOfChannelsKey,
            [NSNumber numberWithInt: AVAudioQualityMax],         AVEncoderAudioQualityKey,
                    nil];

    NSError *error;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings
                                                   error:&error];
    self.recorder.delegate = self;

    if(error){
        NSLog(@"ERROR %@", error);
    }

    return self;
}

- (void)listenToAudio {
    if(self.recorder && !self.recorder.recording){
        if([self.recorder prepareToRecord]){
            self.recorder.meteringEnabled = YES;
            BOOL result = [self.recorder record];
            NSLog(@"recording %d", result);
            self.levelTimer = [NSTimer scheduledTimerWithTimeInterval: 0.03 target: self selector: @selector
            (levelTimerCallback:) userInfo: nil repeats: YES];

            dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC);
            dispatch_after(when, dispatch_get_main_queue(), ^{
                [self removeRecordingFile];
            });
        }

    }

}

- (void)levelTimerCallback:(NSTimer *)timer {
    float scale = 0.5;
    if (self.recorder.recording){
        [self.recorder updateMeters];
        float power = [self.recorder averagePowerForChannel:0];
        float level = _meterTable.ValueAt(power);
        scale = level * 5.0f;
        NSLog(@"power %f level %f, scale %f",power, level, scale);
    }
    else {
        NSLog(@"not recording");
    }



//    // trying to detect blow
//    const double ALPHA = 0.05;
//    double peakPowerForChannel = pow(10, (0.05 * [self.recorder peakPowerForChannel:0]));
//    self.lowPassResults = ALPHA * peakPowerForChannel + (1.0 - ALPHA) * self.lowPassResults;
//
//    if (self.lowPassResults < 0.95)
//        NSLog(@"Mic blow detected");
}


- (void)removeRecordingFile
{
    // Remove the data file from the recording.
    NSString *recorderFilePath = [NSString stringWithFormat:@"%@/%@.caf",
                    [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"], @"cache"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    BOOL success = [fileManager removeItemAtPath:recorderFilePath error:&error];

    if(success) {
        NSLog(@"Deleted recording file");
    }
    else {
        NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
    }
}

#pragma mark - Delegate

-(void)audioRecorderDidFinishRecording:
        (AVAudioRecorder *)recorder
                          successfully:(BOOL)flag
{
}

-(void)audioRecorderEncodeErrorDidOccur:
        (AVAudioRecorder *)recorder
                                  error:(NSError *)error
{
    NSLog(@"Encode Error occurred");
}

@end