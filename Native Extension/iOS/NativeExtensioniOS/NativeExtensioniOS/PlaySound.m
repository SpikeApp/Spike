#import "PlaySound.h"
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "FPANEUtils.h"
#import <MediaPlayer/MPMusicPlayerController.h>

@interface PlaySound() <AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate>
@property (strong) AVAudioPlayer *audioPlayer;
@property (strong) AVSpeechSynthesizer *syn;
@property float currentSystemVolume;
@property BOOL shouldRestoreSystemVolume;
@end

@implementation PlaySound


- (void) playSound:(NSString *) sound withVolume: (NSInteger) volume{
    NSURL* path = [[NSBundle mainBundle] URLForResource:sound  withExtension:@""];
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:path error:nil];
    _audioPlayer.delegate = self;
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
    
    [self restoreSystemVolume];
}

- (Boolean) isPlayingSound {
    return [_audioPlayer isPlaying];
}

- (void) changeSystemVolume:(float) volume  {
    //We save the current system volume so we can restore it after the sound finishes playing
    _currentSystemVolume = [[AVAudioSession sharedInstance] outputVolume];
    _shouldRestoreSystemVolume = true;
    
    //We set the system volume to the user desired value before playing the sound
    [self updateSystemVolume:volume];
}

- (void) updateSystemVolume:(float) volume  {
    //Undocumented API to change device system volume
    MPMusicPlayerController *systemPlayer = [MPMusicPlayerController systemMusicPlayer];
    [systemPlayer setValue:@(volume) forKey:@"volume"];
    [systemPlayer setValue:@(volume) forKey:@"volumePrivate"];
}

- (void) restoreSystemVolume  {
    if (_shouldRestoreSystemVolume)
    {
        //Restore system volume to how it was before. Update restore flag so it doesn't try to restore on the next sound/speech if not needed.
        _shouldRestoreSystemVolume = false;
        [self updateSystemVolume:_currentSystemVolume];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self restoreSystemVolume];
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
        _syn.delegate = self;
        [_syn speakUtterance:utterance];
    }
}

-(void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    [self restoreSystemVolume];
}

@end

