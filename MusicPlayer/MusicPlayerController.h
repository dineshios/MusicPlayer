#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

@class MusicPlayerController;

@protocol MusicPlayerControllerDelegate <NSObject>
@optional
- (void)musicPlayer:(MusicPlayerController *)musicPlayer trackDidChange:(MPMediaItem *)nowPlayingItem previousTrack:(MPMediaItem *)previousTrack;
- (void)musicPlayer:(MusicPlayerController *)musicPlayer endOfQueueReached:(MPMediaItem *)lastTrack;
- (void)musicPlayer:(MusicPlayerController *)musicPlayer playbackStateChanged:(MPMusicPlaybackState)playbackState previousPlaybackState:(MPMusicPlaybackState)previousPlaybackState;
- (void)musicPlayer:(MusicPlayerController *)musicPlayer volumeChanged:(float)volume;
@end


@interface MusicPlayerController : NSObject <MPMediaPlayback>

@property (strong, nonatomic, readonly) MPMediaItem *nowPlayingItem;
@property (nonatomic) MPMusicPlaybackState playbackState;
@property (nonatomic) MPMusicRepeatMode repeatMode; // note: MPMusicRepeatModeDefault is not supported
@property (nonatomic) MPMusicShuffleMode shuffleMode; // note: only MPMusicShuffleModeOff and MPMusicShuffleModeSongs are supported
@property (nonatomic) float volume; // 0.0 to 1.0
@property (nonatomic, readonly) NSUInteger indexOfNowPlayingItem; // NSNotFound if no queue
@property (nonatomic) BOOL updateNowPlayingCenter; // default YES
@property (nonatomic, readonly) NSArray *queue;
@property (nonatomic) BOOL shouldReturnToBeginningWhenSkippingToPreviousItem; // default YES

+ (MusicPlayerController *)sharedInstance;

- (void)addDelegate:(id<MusicPlayerControllerDelegate>)delegate;
- (void)removeDelegate:(id<MusicPlayerControllerDelegate>)delegate;
- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent;
- (void)setQueueWithItemCollection:(MPMediaItemCollection *)itemCollection;
- (void)setQueueWithQuery:(MPMediaQuery *)query;

- (void)skipToNextItem;
- (void)skipToBeginning;
- (void)skipToPreviousItem;

- (void)playItemAtIndex:(NSUInteger)index;
- (void)playItem:(MPMediaItem *)item;

// Check MPMediaPlayback for other playback related methods
// and properties like play, plause, currentPlaybackTime
// and more.

@end
