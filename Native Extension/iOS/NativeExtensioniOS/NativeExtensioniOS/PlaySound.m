#import "PlaySound.h"
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "FPANEUtils.h"


@interface PlaySound()
@property (strong) AVAudioPlayer *audioPlayer;
@property (strong) AVSpeechSynthesizer *syn;
@end

@implementation PlaySound


- (void) playSound:(NSString *) sound withVolume: (NSInteger) volume{
    NSURL* path = [[NSBundle mainBundle] URLForResource:sound  withExtension:@""];
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:path error:nil];
    if ([[NSNumber numberWithInteger:volume] intValue] < 101) {
        //value 101 means don't change the volume
        [_audioPlayer setVolume:[[NSNumber numberWithInteger:volume] floatValue]];
    }
    [_audioPlayer play];
}

- (void) stopPlayingSound {
    if ([_audioPlayer isPlaying]) {
        [_audioPlayer stop];
    }
}

- (Boolean) isPlayingSound {
    return [_audioPlayer isPlaying];
}


- (void) say:(NSString *) text language:(NSString *) language {
    FPANE_Log(@"spiketrace ANE PlaySound.m say");
    if (![_audioPlayer isPlaying]) {
        FPANE_Log(@"spiketrace ANE PlaySound.m say, audioPlayer not playing, trying to speak text now");
        _syn = [[AVSpeechSynthesizer alloc] init];
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
        [utterance setRate:0.51f];
        [utterance setPitchMultiplier:1];
        [utterance setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:language]];
        [_syn speakUtterance:utterance];
    }
}

@end

