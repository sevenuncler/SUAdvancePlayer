//
//  SUURLAssetSourceLoader.m
//  SUAdvancePlayer
//
//  Created by fanghe on 17/9/15.
//  Copyright © 2017年 Sevenuncle. All rights reserved.
//

#import "SUURLAssetSourceLoader.h"
#import "SUDownloadTask.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "SURange.h"

@interface SUURLAssetSourceLoader()

@property (nonatomic, strong) NSMutableArray    *pendingRequests;
@property (nonatomic, strong) SUDownloadTask    *downloadTask;


@end

@implementation SUURLAssetSourceLoader

- (instancetype)init {
    if(self = [super init]) {
        self.seeked = NO;
    }
    return self;
}

#pragma mark - 内部处理函数

- (void)addLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    [self.pendingRequests addObject:loadingRequest];
    [self doDownloadSource:loadingRequest];
}

- (void)doDownloadSource:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSURL *URL = loadingRequest.request.URL;
    NSUInteger requestOffset = loadingRequest.dataRequest.requestedOffset;
    __weak typeof(self) weakSelf = self;
    [self dealWithLoadingRequests];
    if(!self.downloadTask) {
        self.downloadTask = [SUDownloadTask new];
        self.downloadTask.freshDataCachedHandler = ^() {
            [weakSelf dealWithLoadingRequests];
        };
        [self.downloadTask startDownloadWithURL:URL];
    }else if(requestOffset>0 && self.isSeeked){
        NSLog(@"%12lld-%12lld-%12ld >>>>> Seeked <<<<<", loadingRequest.dataRequest.currentOffset, loadingRequest.dataRequest.requestedOffset, loadingRequest.dataRequest.requestedLength);
        NSMutableArray *finishArray = [NSMutableArray array];
        [self.pendingRequests enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(idx == weakSelf.pendingRequests.count - 1) {
                return;
            }
            AVAssetResourceLoadingRequest *loadingRequest = (AVAssetResourceLoadingRequest *)obj;
            [loadingRequest finishLoading];
            [finishArray addObject:loadingRequest];
        }];
        [self.pendingRequests removeObjectsInArray:finishArray];
        [self.downloadTask seekToDownloadAtOffset:requestOffset withURL:URL];
        self.seeked = NO;
    }
}

- (void)dealWithLoadingRequests {
    NSMutableArray *requestsCompleted = [NSMutableArray array];  //请求完成的数组
    //每次下载一块数据都是一次请求，把这些请求放到数组，遍历数组
    for (AVAssetResourceLoadingRequest *loadingRequest in self.pendingRequests)
    {
        [self fillInContentInformation:loadingRequest.contentInformationRequest]; //对每次请求加上长度，文件类型等信息
        
        BOOL didRespondCompletely = [self fillResponseDataForLoadingRequest:loadingRequest]; //判断此次请求的数据是否处理完全
        
        if (didRespondCompletely) {
            
            [requestsCompleted addObject:loadingRequest];  //如果完整，把此次请求放进 请求完成的数组
            [loadingRequest finishLoading];
            
        }
    }
    
    [self.pendingRequests removeObjectsInArray:requestsCompleted];   //在所有请求的数组中移除已经完成的
}

- (void)fillInContentInformation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest
{
    NSString *mimeType = @"video/mp4";
    CFStringRef stringRef = (__bridge CFStringRef)(mimeType);
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, stringRef, NULL);
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = CFBridgingRelease(contentType);
    contentInformationRequest.contentLength = self.downloadTask.resourceLength;
    CFRelease(stringRef);
//    CFRelease(contentType);
}

- (BOOL)fillResponseDataForLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    AVAssetResourceLoadingDataRequest *dataRequest = loadingRequest.dataRequest;
    
    long long startOffset = dataRequest.requestedOffset;
    
    if (dataRequest.currentOffset != 0) {
        startOffset = dataRequest.currentOffset;
    }
    
    if ((self.downloadTask.requestOffset + self.downloadTask.resourceLength) < startOffset)
    {
        //NSLog(@"NO DATA FOR REQUEST");
        return NO;
    }
    
    if (startOffset < self.downloadTask.requestOffset) {
        return NO;
    }
    SURangePointer requestRange = malloc(sizeof(SURange));
    requestRange->location = startOffset;
    requestRange->length   = dataRequest.requestedLength;
    requestRange->next     = NULL;
//    SUMakeRange(startOffset, dataRequest.requestedLength);
    SURangePointer dataRange = SUGetXRanges(self.downloadTask.downloadRange, requestRange);
    if(NULL == dataRange) {
        SURangeFree(dataRange);
        SURangeFree(requestRange);
        return NO;
    }
    
    // This is the total data we have from startOffset to whatever has been downloaded so far
//    NSUInteger unreadBytes = self.downloadTask.resourceCachedLength - ((NSInteger)startOffset - self.downloadTask.requestOffset);
    
    // Respond with whatever is available if we can't satisfy the request fully yet
//    NSUInteger numberOfBytesToRespondWith = MIN((NSUInteger)dataRequest.requestedLength, unreadBytes);
    
//    NSData *data = [self.downloadTask readDataInRange:NSMakeRange((NSUInteger)startOffset - self.downloadTask.requestOffset, (NSUInteger)numberOfBytesToRespondWith)];
    NSData *data = [self.downloadTask readDataInRange:NSMakeRange(dataRange->location, dataRange->length)];
    [dataRequest respondWithData:data];
    
    
    
    long long endOffset = startOffset + dataRequest.requestedLength;
    BOOL didRespondFully = (dataRange->location + dataRange->length) >= endOffset;
    if(didRespondFully) {
        NSLog(@"%12lld-%12lld-%12ld >>>>> 完成1", startOffset, dataRequest.requestedOffset, dataRequest.requestedLength);
        NSLog(@"%12lld-%12lld-%12ld >>>>> 完成2", dataRequest.currentOffset, dataRequest.requestedOffset, dataRequest.requestedLength);
    }
    SURangeFree(dataRange);
    SURangeFree(requestRange);

    return didRespondFully;
}



#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    [self addLoadingRequest:loadingRequest];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    
}

#pragma mark - Getter & Setter

- (NSMutableArray *)pendingRequests {
    if(!_pendingRequests) {
        _pendingRequests = [[NSMutableArray alloc] init];
    }
    return _pendingRequests;
}

@end
