//
//  SUDownloadTask.m
//  SUAdvancePlayer
//
//  Created by fanghe on 17/9/15.
//  Copyright © 2017年 Sevenuncle. All rights reserved.
//

#import "SUDownloadTask.h"
#import "SURange.h"

@interface SUDownloadTask()<NSURLSessionDataDelegate>
{
    SURange *_downloadRange;
    NSUInteger _failCount;
}
@property (nonatomic, strong) NSURLSession          *session;
@property (nonatomic, strong) NSURLSessionDataTask  *dataTask;
@property (nonatomic, assign) SURangePointer        currentRange;
@property (nonatomic, assign) SURangePointer        reqRange;
@property (nonatomic, strong) NSMutableDictionary   *rangeDict;

@end

@implementation SUDownloadTask

#pragma mark - 生命周期
- (void)dealloc {
    SURangeFree(_downloadRange);
    SURangeFree(self.currentRange);
}

#pragma mark - public

- (void)startDownloadWithURL:(NSURL *)url {
    self.resourceLength = 0;
    self.requestOffset  = 0;
    self.currentOffset  = 0;
    self.resourceCachedLength = 0;
    self.rangeDict = [NSMutableDictionary dictionary];
    _failCount = 0;
    self.currentRange = malloc(sizeof(SURange));
    self.currentRange->next = NULL;
    [self recreateTempFile:self.temporyFilePath];
    [self seekToDownloadAtOffset:0 withURL:url];
}

- (void)seekToDownloadAtOffset:(unsigned long long)offset withURL:(NSURL *)url {
    
    
    NSURL *effectiveURL = [self originSchemeURL:url];
    _resourceURL = url;
    self.resourceCachedLength = 0;
    [self.dataTask cancel]; //很重要，否则数据会乱
    
    NSMutableURLRequest *request;
    request = [NSMutableURLRequest requestWithURL:effectiveURL];
    if (self.resourceLength > 0) {
        SURangePointer requestRange = malloc(sizeof(SURange));
        requestRange->location = offset;
        requestRange->length   = self.resourceLength - 1 - offset + 1;
        requestRange->next     = NULL;
        SURangePointer tmpRange = SUGetGapRanges(_downloadRange, requestRange);
        if(NULL == tmpRange) {
            free(requestRange);
            SURangeFree(tmpRange);
            [self continueDownload];
            return;
        }
        _failCount = 0;
//        if(self.reqRange != NULL) {
//            SURangeFree(self.reqRange);
//        }
//        self.reqRange = tmpRange;
        self.requestOffset  = tmpRange->location;
        self.currentOffset  = tmpRange->location;
        NSString *value = [NSString stringWithFormat:@"bytes=%lld-%lld",tmpRange->location, tmpRange->location + tmpRange->length - 1];
        [request addValue:value forHTTPHeaderField:@"Range"];
        free(requestRange);
        SURangeFree(tmpRange);
    }
    _currentRange->location = self.requestOffset;
    _currentRange->length   = 0;
    
    self.dataTask = [self.session dataTaskWithRequest:request];
    [self.dataTask resume];
}


- (NSData *)readDataInRange:(NSRange)range {
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:self.temporyFilePath];
    [fileHandle seekToFileOffset:range.location];
    return [fileHandle readDataOfLength:range.length];
}

#pragma mark - private

- (NSURL *)originSchemeURL:(NSURL *)url {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = @"http";
    return components.URL;
}

- (SURangePointer)useRange:(SURangePointer)request {
    return NULL;
}

- (void)continueDownload {
    if(0 == _failCount) {
        _failCount ++;
        [self seekToDownloadAtOffset:0 withURL:self.resourceURL];
    }else if(_failCount >= 1) {
        NSLog(@"下载完成");
        return;
    }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    completionHandler(NSURLSessionResponseAllow);
    
    //获取该资源的基本信息，资源文件长度、类型
    NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)response;
    NSDictionary *dict = [httpURLResponse allHeaderFields];
    NSString     *content = [dict valueForKey:@"Content-Range"];
    NSArray      *array   = [content componentsSeparatedByString:@"/"];
    NSString     *length  = array.lastObject;
    
    //资源长度
    if(0 == [length integerValue]) {
        self.resourceLength = response.expectedContentLength;
    }else {
        self.resourceLength = [length integerValue];
    }
    NSLog(@"返回信息>>>> content:%@ 请求:%lld 长度%lld",content, self.requestOffset, self.resourceLength);
    //资源类型
    
    //重新创建临时文件
    

}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.temporyFilePath];
    [fileHandle seekToFileOffset:self.currentOffset];
    [fileHandle writeData:data];
    self.resourceCachedLength += data.length;
    //
    _currentRange->length += data.length;
    SURange *range;
    range = malloc(sizeof(SURange));
    range->location = self.currentOffset;
    range->length   = data.length;
    range->next     = NULL;
    _downloadRange = SUInsertNodeIntoRange(_downloadRange, range);
    free(range);
    SURangePrint(_downloadRange);
    
    self.currentOffset += data.length;
    //通知数据更新
    if(self.freshDataCachedHandler) {
        self.freshDataCachedHandler();
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    NSLog(@">>>>>>>>>><<<<<<<<<<<");
//    SURangePrint(self.reqRange);
//    SURangePrint(_currentRange);
    NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)task.response;
    NSDictionary *dict = [httpURLResponse allHeaderFields];
    NSString     *content = [dict valueForKey:@"Content-Range"];
    NSString *offsetString = [NSString stringWithFormat:@"%lld", _currentOffset-1];
    NSLog(@"完成一次请求%@", content);
    NSLog(@"offset%@", offsetString);
    NSLog(@">>>>>>>>>><<<<<<<<<<<");

    if([content rangeOfString:offsetString].length>0) {
        if (self.currentOffset >= self.resourceLength) {
            [self seekToDownloadAtOffset:0 withURL:self.resourceURL];
        }else {
            [self seekToDownloadAtOffset:self.currentOffset withURL:self.resourceURL];
        }
    }
}

#pragma mark - Getter & Setter

- (NSString *)temporyFilePath {
    if(!_temporyFilePath) {
        NSString *directory = NSTemporaryDirectory();
        NSString *filePath  = [NSString stringWithFormat:@"%@%@", directory, @"resource.tmp"];
        _temporyFilePath = filePath;
    }
    return _temporyFilePath;
}

- (BOOL)recreateTempFile:(NSString *)filePath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:filePath]) {
        [fileManager removeItemAtPath:filePath error:nil];
    }
    [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    return YES;
}

- (NSURLSession *)session {
    if(!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

- (NSURLSessionDataTask *)dataTask {
    if(!_dataTask) {
        
    }
    return _dataTask;
}


@end
