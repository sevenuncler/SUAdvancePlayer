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
}
@property (nonatomic, strong) NSURLSession          *session;
@property (nonatomic, strong) NSURLSessionDataTask  *dataTask;
@property (nonatomic, assign) SURange               currentRange;
@property (nonatomic, strong) NSMutableDictionary   *rangeDict;

@end

@implementation SUDownloadTask

#pragma mark - public

- (void)startDownloadWithURL:(NSURL *)url {
    self.resourceLength = 0;
    self.requestOffset  = 0;
    self.resourceCachedLength = 0;
    self.rangeDict = [NSMutableDictionary dictionary];
    [self seekToDownloadAtOffset:0 withURL:url];
}

- (void)seekToDownloadAtOffset:(unsigned long long)offset withURL:(NSURL *)url {
    
    self.requestOffset  = offset;
    NSURL *effectiveURL = [self originSchemeURL:url];
    self.resourceCachedLength = 0;
    [self.dataTask cancel]; //很重要，否则数据会乱
    
    NSMutableURLRequest *request;
    request = [NSMutableURLRequest requestWithURL:effectiveURL];
    if (self.resourceLength > 0) {
        [request addValue:[NSString stringWithFormat:@"bytes=%ld-%ld",(unsigned long)offset, (unsigned long)self.resourceLength - 1] forHTTPHeaderField:@"Range"];
    }
    _currentRange.location = self.requestOffset;
    _currentRange.length   = 0;
    
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


#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
#warning 允许继续完成加载?
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
    [self recreateTempFile:self.temporyFilePath];

}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.temporyFilePath];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:data];
    self.resourceCachedLength += data.length;
    
    //
    _currentRange.length += data.length;
    SURange *range;
    range = malloc(sizeof(SURange));
    range->location = _currentRange.location;
    range->length   = _currentRange.length;
    range->next     = NULL;
    _downloadRange = SUInsertNodeIntoRange(_downloadRange, range);
    free(range);
    
    SURangePrint(_downloadRange);
    //通知数据更新
    if(self.freshDataCachedHandler) {
        self.freshDataCachedHandler();
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    NSLog(@">>> <<< %@", task.response);
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
