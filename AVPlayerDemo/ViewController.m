//
//  ViewController.m
//  AVPlayerDemo
//
//  Created by Daniel on 16/6/22.
//  Copyright © 2016年 Daniel. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *pauseBtn;
@property (weak, nonatomic) IBOutlet UIButton *replayBtn;
@property (weak, nonatomic) IBOutlet UIProgressView *playProgress;
@property (weak, nonatomic) IBOutlet UIProgressView *cacheProgress;



@property (nonatomic, strong)AVPlayer *player;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _playProgress.progress = 0.f;
    _cacheProgress.progress = 0.f;
}

- (AVPlayer *)player {
    
    if (!_player) {
        AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:@"http://101.200.81.192:84/Public/upfile/2016-06-22/Courage.mp3"]];
        _player = [[AVPlayer alloc] initWithPlayerItem:item];
        
        [_player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [_player.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        
        // 播放进度条
        __weak typeof(self) blockSelf = self;
        [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            
            CMTime duration = blockSelf.player.currentItem.duration;
            CGFloat totalDuration = CMTimeGetSeconds(duration);
            
            CMTime currentTime = blockSelf.player.currentTime;
            CGFloat currentTimeInterval = CMTimeGetSeconds(currentTime);
            
            blockSelf.playProgress.progress = currentTimeInterval/totalDuration;
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playDidEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    return _player;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)play:(id)sender {
    [self.player play];
}

// 重放/下一首/上一首,
// 如果'item'如果和'currentItem'一样, 重发
// 如果'item'如果和'currentItem'不一样, 切换歌曲
- (IBAction)replay:(id)sender {
    
    _playProgress.progress = 0.f;
    _cacheProgress.progress = 0.f;
    
    [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:@"http://101.200.81.192:84/Public/upfile/2016-06-22/Courage.mp3"]];
    
    [item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [self.player replaceCurrentItemWithPlayerItem:item];
    
    [self.player play];
}

- (IBAction)stop:(id)sender {
    [self.player pause];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"status"]) {
        // 将要播放
        if ([self.player.currentItem status] == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay");
        }
        // 播放失败
        else if ([self.player.currentItem status] == AVPlayerStatusFailed) {
            NSLog(@"AVPlayerStatusFailed");
        }
    }
    
    // 缓存进度
    else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval timeInterval = [self availableDuration];
        
        CMTime duration = self.player.currentItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        
        // 缓存进度
        _cacheProgress.progress = timeInterval/totalDuration;
    }
}

- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
    
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    
    // 计算缓冲总进度
    NSTimeInterval result = startSeconds + durationSeconds;
    return result;
}

- (NSString *)converTime:(CGFloat)second {
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (second/3600 >= 1) {
        formatter.dateFormat = @"HH:mm:ss";
    } else {
        formatter.dateFormat = @"mm:ss";
    }
    
    NSString *showtimeNew = [formatter stringFromDate:d];
    return showtimeNew;
}

- (void)dealloc {
    [self.player removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (void)playDidEnd {
    NSLog(@"播放完毕");
}

@end
