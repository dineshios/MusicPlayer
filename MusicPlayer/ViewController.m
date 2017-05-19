
#import "ViewController.h"
#import "MusicPlayerController.h"
#import "NSString+TimeToString.h"

@interface ViewController () <MusicPlayerControllerDelegate, MPMediaPickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *songLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet UILabel *trackCurrentPlaybackTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *trackLengthLabel;
@property (weak, nonatomic) IBOutlet UIView *chooseView;
@property (weak, nonatomic) IBOutlet UIButton *repeatButton;
@property (weak, nonatomic) IBOutlet UIButton *shuffleButton;
@property (strong, nonatomic) NSTimer *timer;
@property BOOL panningProgress;
@property BOOL panninolume;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view bringSubviewToFront:self.chooseView];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timedJob) userInfo:nil repeats:YES];
    [self.timer fire];
}

- (void)viewWillAppear:(BOOL)animated {
    // NOTE: add and remove the MusicPlayerController delegate in
    // the viewWillAppear / viewDidDisappear methods, not in the
    // viewDidLoad / viewDidUnload methods - it will result in dangling
    // objects in memory.
    [super viewWillAppear:animated];
    [[MusicPlayerController sharedInstance] addDelegate:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[MusicPlayerController sharedInstance] removeDelegate:self];
    [super viewDidDisappear:animated];
}

- (void)timedJob {
    if (!self.panningProgress) {
        self.progressSlider.value = [MusicPlayerController sharedInstance].currentPlaybackTime;
        self.trackCurrentPlaybackTimeLabel.text = [NSString stringFromTime:[MusicPlayerController sharedInstance].currentPlaybackTime];
    }
}

#pragma mark - Catch remote control events, forward to the music player

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.shuffleButton.selected = ([MusicPlayerController sharedInstance].shuffleMode != MPMusicShuffleModeOff);
    [self setCorrectRepeatButtomImage];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    [super viewWillDisappear:animated];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    [[MusicPlayerController sharedInstance] remoteControlReceivedWithEvent:receivedEvent];
}

#pragma mark - IBActions

- (IBAction)playButtonPressed {
    if ([MusicPlayerController sharedInstance].playbackState == MPMusicPlaybackStatePlaying) {
        [[MusicPlayerController sharedInstance] pause];
    } else {
        [[MusicPlayerController sharedInstance] play];
    }
}

- (IBAction)prevButtonPressed {
    [[MusicPlayerController sharedInstance] skipToPreviousItem];
}

- (IBAction)nextButtonPressed {
    [[MusicPlayerController sharedInstance] skipToNextItem];
}

- (IBAction)chooseButtonPressed {
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    picker.delegate = self;
    picker.allowsPickingMultipleItems = YES;
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)playEverythingButtonPressed {
    MPMediaQuery *query = [MPMediaQuery songsQuery];
    [[MusicPlayerController sharedInstance] setQueueWithQuery:query];
    [[MusicPlayerController sharedInstance] play];
}

- (IBAction)volumeChanged:(UISlider *)sender {
    self.panninolume = YES;
    [MusicPlayerController sharedInstance].volume = sender.value;
}

- (IBAction)volumeEnd {
    self.panninolume = NO;
}

- (IBAction)progressChanged:(UISlider *)sender {
    // While dragging the progress slider around, we change the time label,
    // but we're not actually changing the playback time yet.
    self.panningProgress = YES;
    self.trackCurrentPlaybackTimeLabel.text = [NSString stringFromTime:sender.value];
}

- (IBAction)progressEnd {
    // Only when dragging is done, we change the playback time.
    [MusicPlayerController sharedInstance].currentPlaybackTime = self.progressSlider.value;
    self.panningProgress = NO;
}

//- (IBAction)shuffleButtonPressed {
//    self.shuffleButton.selected = !self.shuffleButton.selected;
//
//    if (self.shuffleButton.selected) {
//        [MusicPlayerController sharedInstance].shuffleMode = MPMusicShuffleModeSongs;
//    } else {
//        [MusicPlayerController sharedInstance].shuffleMode = MPMusicShuffleModeOff;
//    }
//}

- (IBAction)repeatButtonPressed {
    switch ([MusicPlayerController sharedInstance].repeatMode) {
        case MPMusicRepeatModeAll:
            // From all to one
            [MusicPlayerController sharedInstance].repeatMode = MPMusicRepeatModeOne;
            break;

        case MPMusicRepeatModeOne:
            // From one to none
            [MusicPlayerController sharedInstance].repeatMode = MPMusicRepeatModeNone;
            break;

        case MPMusicRepeatModeNone:
            // From none to all
            [MusicPlayerController sharedInstance].repeatMode = MPMusicRepeatModeAll;
            break;

        default:
            [MusicPlayerController sharedInstance].repeatMode = MPMusicRepeatModeAll;
            break;
    }

    [self setCorrectRepeatButtomImage];
}

- (void)setCorrectRepeatButtomImage {
    NSString *imageName;

    switch ([MusicPlayerController sharedInstance].repeatMode) {
        case MPMusicRepeatModeAll:
            imageName = @"Track_Repeat_On";
            break;

        case MPMusicRepeatModeOne:
            imageName = @"Track_Repeat_On_Track";
            break;

        case MPMusicRepeatModeNone:
            imageName = @"Track_Repeat_Off";
            break;

        default:
            imageName = @"Track_Repeat_Off";
            break;
    }

    [self.repeatButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

#pragma mark - MusicPlayerControllerDelegate

- (void)musicPlayer:(MusicPlayerController *)musicPlayer playbackStateChanged:(MPMusicPlaybackState)playbackState previousPlaybackState:(MPMusicPlaybackState)previousPlaybackState {
    self.playPauseButton.selected = (playbackState == MPMusicPlaybackStatePlaying);
}

- (void)musicPlayer:(MusicPlayerController *)musicPlayer trackDidChange:(MPMediaItem *)nowPlayingItem previousTrack:(MPMediaItem *)previousTrack {
    if (!nowPlayingItem) {
        self.chooseView.hidden = NO;
        return;
    }

    self.chooseView.hidden = YES;

    // Time labels
    NSTimeInterval trackLength = [[nowPlayingItem valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
    self.trackLengthLabel.text = [NSString stringFromTime:trackLength];
    self.progressSlider.value = 0;
    self.progressSlider.maximumValue = trackLength;

    // Labels
    self.songLabel.text = [nowPlayingItem valueForProperty:MPMediaItemPropertyTitle];
    self.artistLabel.text = [nowPlayingItem valueForProperty:MPMediaItemPropertyArtist];

    // Artwork
    MPMediaItemArtwork *artwork = [nowPlayingItem valueForProperty:MPMediaItemPropertyArtwork];
    if (artwork != nil) {
        self.imageView.image = [artwork imageWithSize:self.imageView.frame.size];
    }

    NSLog(@"Proof that this code is being called, even in the background!");
}

- (void)musicPlayer:(MusicPlayerController *)musicPlayer endOfQueueReached:(MPMediaItem *)lastTrack {
    NSLog(@"End of queue, but last track was %@", [lastTrack valueForProperty:MPMediaItemPropertyTitle]);
}

- (void)musicPlayer:(MusicPlayerController *)musicPlayer volumeChanged:(float)volume {
    if (!self.panninolume) {
        self.volumeSlider.value = volume;
    }
}

#pragma mark - MPMediaPickerControllerDelegate

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    [[MusicPlayerController sharedInstance] setQueueWithItemCollection:mediaItemCollection];
    [[MusicPlayerController sharedInstance] play];
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
}

@end
