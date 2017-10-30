//
//  SUDownloadTask.h
//  SUAdvancePlayer
//
//  Created by fanghe on 17/9/15.
//  Copyright © 2017年 Sevenuncle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SURange.h"
NS_ASSUME_NONNULL_BEGIN

typedef void (^FreshDataCachedHandler)();

@interface SUDownloadTask : NSObject

@property (nonatomic, null_resettable) NSString     *temporyFilePath;
@property (nonatomic, readonly)        NSURL        *resourceURL;
@property (nonatomic, assign)   unsigned long long  requestOffset;
@property (nonatomic, assign)   unsigned long long  currentOffset;
@property (nonatomic, assign)   unsigned long long  resourceLength;
@property (nonatomic, assign)   unsigned long long  resourceCachedLength;
@property (nonatomic, assign)   SURangePointer      downloadRange;
@property (nonatomic, copy)            FreshDataCachedHandler freshDataCachedHandler;

- (void)startDownloadWithURL:(NSURL *)url;
- (void)seekToDownloadAtOffset:(unsigned long long)offset withURL:(NSURL *)url;
- (NSData *)readDataInRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
