#ifndef PlaySound2_h
#define PlaySound2_h

#import <Foundation/Foundation.h>

@interface PlaySound : NSObject

- (void) playSound:(NSString *) sound withVolume: (NSInteger) volume;
- (void) stopPlayingSound;
- (void) say:(NSString *) text language: (NSString *) language;
- (Boolean) isPlayingSound;

@end

#endif /* PlaySound2_h */
