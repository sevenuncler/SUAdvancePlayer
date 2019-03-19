//
//  SUURLAssetSourceLoader.h
//  SUAdvancePlayer
//
//  Created by fanghe on 17/9/15.
//  Copyright © 2017年 Sevenuncle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface SUURLAssetSourceLoader : NSObject<AVAssetResourceLoaderDelegate>

@property (nonatomic, assign, getter=isSeeked) BOOL seeked;

@end
