//
//  SUURLAssetSourceLoader.m
//  SUAdvancePlayer
//
//  Created by fanghe on 17/9/15.
//  Copyright © 2017年 Sevenuncle. All rights reserved.
//

#import "SUURLAssetSourceLoader.h"

@interface SUURLAssetSourceLoader()

@property (nonatomic, strong) NSMutableArray    *pendingRequests;

@end

@implementation SUURLAssetSourceLoader



#pragma mark - 内部处理函数

- (void)addLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    [self.pendingRequests addObject:loadingRequest];
}

- (void)doDownloadSource {
    
}

- (void)dealWithLoadingRequests {
    
}

- (void)fillResponseDataForLoadingRequest {
    
}


#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    [self addLoadingRequest:loadingRequest];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    
}

@end
