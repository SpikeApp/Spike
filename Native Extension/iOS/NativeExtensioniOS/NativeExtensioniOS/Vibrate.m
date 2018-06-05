#import <Foundation/Foundation.h>
#import "FPANEUtils.h"
#import "Vibrate.h"
#import <AudioToolbox/AudioToolbox.h>


@interface Vibrate()
@end

@implementation Vibrate

+(void)vibrate{
    FPANE_Log(@"spiketrace ANE Vibrate.m vibrate ");
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

@end

