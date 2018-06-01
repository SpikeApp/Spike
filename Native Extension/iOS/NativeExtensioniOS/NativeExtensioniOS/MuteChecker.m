#import <Foundation/Foundation.h>
#import "MuteChecker.h"
#import "FPANEUtils.h"
#import "Context.h"

void MuteCheckCompletionProc(SystemSoundID ssID, void* clientData);

@interface MuteChecker ()

@property (nonatomic, strong)NSDate *startTime;

-(void)completed;

@end

void MuteCheckCompletionProc(SystemSoundID ssID, void* clientData){
    MuteChecker *obj = (__bridge MuteChecker *)clientData;
    [obj completed];
}

@implementation MuteChecker

-(void)playMuteSound{
    FPANE_Log(@"spiketrace ANE MuteChecker.m playMuteSound ");
    self.startTime = [NSDate date];
    AudioServicesPlaySystemSound(self.soundId);
}

-(void)completed{
    NSDate *now = [NSDate date];
    NSTimeInterval t = [now timeIntervalSinceDate:self.startTime];
    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE MuteChecker.m playMuteSound completed, t =   %f", t ]);
    BOOL muted = (t > 0.7)? NO : YES;
    if (muted) {
        FREDispatchStatusEventAsync([Context getContext], (const uint8_t*) "phoneMuted", (const uint8_t*) "");
    } else {
        FREDispatchStatusEventAsync([Context getContext], (const uint8_t*) "phoneNotMuted", (const uint8_t*) "");
    }

}

-(void)check{
    if (self.startTime == nil) {
        [self playMuteSound];
    } else {
        NSDate *now = [NSDate date];
        NSTimeInterval lastCheck = [now timeIntervalSinceDate:self.startTime];
        if (lastCheck > 1) {	//prevent checking interval shorter then the sound length
            [self playMuteSound];
        }
    }
}


-(instancetype)init{
    //self = [self init];
    if (self) {
        NSURL* url = [[NSBundle mainBundle] URLForResource:@"../assets/silence-1sec" withExtension:@"aif"];
        if (AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_soundId) == kAudioServicesNoError){
            AudioServicesAddSystemSoundCompletion(self.soundId, CFRunLoopGetMain(), kCFRunLoopDefaultMode, MuteCheckCompletionProc,(__bridge void *)(self));
            UInt32 yes = 1;
            AudioServicesSetProperty(kAudioServicesPropertyIsUISound, sizeof(_soundId),&_soundId,sizeof(yes), &yes);
        } else {
            FPANE_Log(@"error setting up Sound ID");
        }
    }
    return self;
}


- (void)dealloc
{
    if (self.soundId != -1){
        AudioServicesRemoveSystemSoundCompletion(self.soundId);
        AudioServicesDisposeSystemSoundID(self.soundId);
    }
}


@end

