//
//  SUAdvancePlayer.m
//  SUAdvancePlayer
//
//  Created by fanghe on 17/9/15.
//  Copyright © 2017年 Sevenuncle. All rights reserved.
//

#import "SUAdvancePlayer.h"
#import "SUURLAssetSourceLoader.h"

@interface SUAdvancePlayer()
{
    AVPlayerLayer *_playerLayer;
}
@property (nonatomic, strong) AVPlayer      *player;
@property (nonatomic, strong) AVPlayerItem  *playerItem;
@property (nonatomic, strong) AVURLAsset    *urlAsset;
@property (nonatomic, strong) NSURL         *url;
@property (nonatomic, strong) SUURLAssetSourceLoader    *sourceLoader;

@end

@implementation SUAdvancePlayer

#pragma mark - Public

- (instancetype)initPlayerWithURL:(NSURL *)url {
    if(self = [super init]) {
        self.url = [url copy];
    }
    return self;
}

- (void)seekToOffset:(NSUInteger )offset {
    [self.player pause];
    [self.player seekToTime:CMTimeMake(offset, 1) completionHandler:^(BOOL finished) {
        [self.player play];
    }];
    self.sourceLoader.seeked = YES;
}

- (void)play {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self.player play];
}

- (void)pause {
    [self.player pause];
}

- (void)playNextWithURL:(NSURL *)URL {
    AVPlayerItem *newItem = [AVPlayerItem playerItemWithURL:URL];
    [self.player replaceCurrentItemWithPlayerItem:newItem];
}

#pragma mark - Private

- (NSURL *)customSchemeURL:(NSURL *)url {
    NSURLComponents * components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = @"streaming";
    return [components URL];
}

#pragma mark - Getter & Setter

- (AVPlayer *)player {
    if(!_player) {
        _player = [AVPlayer playerWithPlayerItem:self.playerItem];
    }
    return _player;
}

- (AVPlayerItem *)playerItem {
    if(!_playerItem) {
        _playerItem = [AVPlayerItem playerItemWithAsset:self.urlAsset];
    }
    return _playerItem;
}

- (AVURLAsset *)urlAsset {
    if(!_urlAsset) {
        _urlAsset = [AVURLAsset assetWithURL:[self customSchemeURL:self.url]];
        [_urlAsset.resourceLoader setDelegate:self.sourceLoader queue:dispatch_get_main_queue()]; //需要放在主线程，否则多线程操作会导致线程安全问题
    }
    return _urlAsset;
}
- (AVPlayerLayer *)playerLayer {
    if(!_playerLayer) {
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    }
    return _playerLayer;
}

- (SUURLAssetSourceLoader *)sourceLoader {
    if(!_sourceLoader) {
        _sourceLoader = [SUURLAssetSourceLoader new];
    }
    return _sourceLoader;
}



@end
