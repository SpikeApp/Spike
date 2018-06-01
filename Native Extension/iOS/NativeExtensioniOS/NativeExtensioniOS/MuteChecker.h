#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#ifndef MuteChecker_h
#define MuteChecker_h

@interface MuteChecker : NSObject

// this class must use with a MuteChecker.caf (a 0.2 sec mute sound) in Bundle

@property (nonatomic,assign) SystemSoundID soundId;

-(instancetype)init;
-(void)check;

@end
#endif
