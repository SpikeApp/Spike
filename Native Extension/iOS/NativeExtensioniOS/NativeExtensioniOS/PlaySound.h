#ifndef PlaySound2_h
#define PlaySound2_h

#import <Foundation/Foundation.h>
#import <MediaPlayer/MPMusicPlayerController.h>

@interface PlaySound : NSObject

- (void) playSound:(NSString *) sound withVolume: (NSInteger) volume;
- (void) stopPlayingSound;
- (void) say:(NSString *) text language: (NSString *) language;
- (void) changeSystemVolume:(float) volume;
- (Boolean) isPlayingSound;

@end

#endif /* PlaySound2_h */
