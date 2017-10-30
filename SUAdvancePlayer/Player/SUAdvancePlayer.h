//
//  SUAdvancePlayer.h
//  SUAdvancePlayer
//
//  Created by fanghe on 17/9/15.
//  Copyright © 2017年 Sevenuncle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface SUAdvancePlayer : NSObject

@property (nonatomic, assign, readonly) NSUInteger      currentOffset;
@property (nonatomic, assign, readonly) NSUInteger      length;
@property (nonatomic, strong, readonly) AVPlayerLayer   *playerLayer;

- (instancetype)initPlayerWithURL:(NSURL *)url;
- (void)seekToOffset:(NSUInteger )offset;
- (void)play;
- (void)pause;
- (void)playNextWithURL:(NSURL *)URL;

@end
