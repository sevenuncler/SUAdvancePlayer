//
//  SUDownloadTask.m
//  SUAdvancePlayer
//
//  Created by fanghe on 17/9/15.
//  Copyright © 2017年 Sevenuncle. All rights reserved.
//

#import "SUDownloadTask.h"

@interface SUDownloadTask()<NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession          *session;
@property (nonatomic, strong) NSURLSessionDataTask  *dataTask;

@end

@implementation SUDownloadTask

#pragma mark - public

- (void)startDownloadWithURL:(NSURL *)url {
    [self seekToDownloadAtOffset:0 withURL:url];
}

- (void)seekToDownloadAtOffset:(unsigned long long)offset withURL:(NSURL *)url {
    self.requestOffset  = offset;
    self.resourceLength = 0;
    NSURL *effectiveURL = [self originSchemeURL:url];
    
    NSMutableURLRequest *request;
    request = [NSMutableURLRequest requestWithURL:effectiveURL];
    
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
#warning 最后一个参数啥意思？
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = @"http";
    return components.URL;
}


#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
#warning 允许继续完成加载？
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
    
    //资源类型
#warning 需要的时候添加
    
    //重新创建临时文件
    [self recreateTempFile:self.temporyFilePath];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.temporyFilePath];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:data];
    self.resourceCachedLength += data.length;
    
    //通知数据更新
    if(self.freshDataCachedHandler) {
        self.freshDataCachedHandler();
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
