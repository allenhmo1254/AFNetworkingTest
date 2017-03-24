//
//  ZJHttpRequest.m
//  AFNetworkingTest
//
//  Created by 景中杰 on 17/1/17.
//  Copyright © 2017年 景中杰. All rights reserved.
//

#import "ZJHttpRequest.h"
#import <AFNetworking.h>
#import "ZJDefaultHttpResponseHandler.h"

static uint ZJHttpRequestGlobalTimeoutInterval = 30;

@interface ZJHttpRequest (/*Private*/)

/**
 执行状态
 */
@property (assign, nonatomic) ZJHttpRequestState requestState;

-(NSError*)_parseResonseData:(id)responseData;

-(void)_executeRealRequest;
-(void)_get;
-(void)_post;
-(void)_delete;

-(void)_invokeRequestSuccessfulHandler;
-(void)_invokeRequestFailedHandler:(NSError*)error;
-(void)_invokeRequestCancelHandler;
-(void)_invokeDownloadProgressHandler:(double)progress;
-(void)_invokeUploadProgressHandler:(double)progress;
-(void)_invokeRequestFinishedHandler;

@end

@implementation ZJHttpRequest
{
    AFHTTPSessionManager *_sessionManager;
    
    __weak ZJHttpRequest *_weakSelf;
    //当前请求的task
    NSURLSessionDataTask *_currentTask;
}

+(ZJHttpRequestMethod)httpRequestMethodByString:(NSString *)method
{
    if ([method caseInsensitiveCompare:@"POST"]) {
        return ZJHttpRequestMethodPost;
    } else {
        return ZJHttpRequestMethodGet;
    }
}

+(NSString *)getErrorMessage:(NSError *)error
{
    if (!error) {
        return @"";
    }
    
    NSDictionary *dict = [error userInfo];
    NSString *message;
    NSString *returnMsg;
    
    if (dict) {
        message = [dict valueForKey:NSLocalizedDescriptionKey];
        returnMsg = [dict valueForKey:@"resultMessage"];
    }
    
    if (returnMsg && returnMsg.length > 0) {
        return returnMsg;
    }
    
    if (message) {
        message = [message stringByAppendingFormat:@"%ld",(long)error.code];
        return message;
    }
    
    return @"";
}

+(void)setGlobalTimeoutInterval:(uint)interval
{
    ZJHttpRequestGlobalTimeoutInterval = interval;
}

#pragma mark - 初始化

-(instancetype)initWithUrl:(NSString *)url
                     method:(ZJHttpRequestMethod)method
{
    return [self initWithUrl:url parameter:nil method:method];
}

-(instancetype)initWithUrl:(NSString *)url
                 parameter:(NSDictionary *)parmeter
                    method:(ZJHttpRequestMethod)method
{
    self = [super init];
    if (self) {
        self.url = url;
        self.method = method;
        self.isAppendGlobalParameter = YES;
        self.timeoutInterval = ZJHttpRequestGlobalTimeoutInterval;
        
        _parameter = [[NSMutableDictionary alloc] init];
        
        if (parmeter) {
            [_parameter addEntriesFromDictionary:parmeter];
        }
        
        _sessionManager = [AFHTTPSessionManager manager];
        _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        _weakSelf = self;
        
        _requestState = ZJHttpRequestStateInit;
        _responseAcceptType = ZJResponseAcceptTypeAutomation;
        
        self.postDataEncodingType = ZJPostDataEncodingTypeJSON;
        _responseDataType = ZJResponseDataTypeJSON;
        _responseHandler = [[ZJDefaultHttpResponseHandler alloc] init];
    }
    return self;
}

#pragma mark - 属性方法

-(void)setResponseHandler:(id<ZJHttpResponseHandler>)responseHandler
{
    //  应答处理器不能设置成空值，调用set方法将替换掉默认的 responsehandler
    if (!responseHandler) {
        return;
    }
    
    _responseHandler = responseHandler;
}

-(BOOL)isRequestSuccessful
{
    return [_responseHandler isRequestSuccessful];
}

-(NSString*)resultMessage
{
    return _responseHandler.resultMessage;
}

-(NSString*)resultCode
{
    return _responseHandler.resultCode;
}

-(id)resultData
{
    return _responseHandler.resultData;
}

#pragma mark - 公共方法

-(void)addParameter:(NSString *)value key:(NSString *)key
{
    [self.parameter setValue:value forKey:key];
}

-(void)addParameterWithDict:(NSDictionary *)value key:(NSString *)key
{
    [self.parameter setValue:value forKey:key];
}

- (void)addParameterWithArray:(NSArray *)value key:(NSString *)key
{
    [self.parameter setValue:value forKey:key];
}

-(BOOL)execute
{
    [self setRequestState:ZJHttpRequestStateNotReady];
    
    [self _addAcceptTypeToHeader];
    
    if (![self onBeforeExecute]) {
        return NO;
    }
    
    _sessionManager.requestSerializer.timeoutInterval = self.timeoutInterval;
    
    [self setRequestState:ZJHttpRequestStateExecuting];
    
    [self _executeRealRequest];
    
    return YES;
}

-(void)cancel
{
    if (!_currentTask) {
        return;
    }
    
    [_currentTask cancel];
    _currentTask = nil;
}

-(NSDictionary *)getRequestHeaders
{
    return [_sessionManager.requestSerializer HTTPRequestHeaders];
}

-(void)addRequestHeader:(NSString *)value key:(NSString *)key
{
    [_sessionManager.requestSerializer setValue:value forHTTPHeaderField:key];
}

-(void)addRequestHeaders:(NSDictionary *)headersDictionary
{
    for (NSString *key in headersDictionary) {
        [_sessionManager.requestSerializer setValue:headersDictionary[key] forHTTPHeaderField:key];
    }
}

#pragma mark - 内部事件处理

-(void)onRequestSuccessful
{
    NSLog (@"onRequestSuccessful. URL:%@",self.url);
    
#ifndef __OPTIMIZE__
    
    if (self.resultMessage){
        NSLog (@"ReturnMessage:%@",self.resultMessage);
    }
    
    if (self.resultCode){
        NSLog (@"ReturnCode:%@",self.resultCode);
    }
    
    if (self.resultData && ![self.resultData isKindOfClass:[NSData class]]){
        NSLog (@"ReturnData:%@",[self.resultData description]);
    }
    else{
        NSLog(@"ReturnData:NSData,Length=%ld",((NSData*)self.resultData).length);
    }
#endif
    
    [self _invokeRequestSuccessfulHandler];
}

-(void)onRequestFailed:(NSError *)error
{
    NSLog (@"onRequestFailed ErrorCode:%ld URL:%@",[error code],self.url);
    
#ifndef __OPTIMIZE__
    NSDictionary *dict = [error userInfo];
    NSString *message;
    NSString *retMsg;
    NSString *retCode;
    
    if (dict){
        message =[dict valueForKey:NSLocalizedDescriptionKey];
        retMsg  =[dict valueForKey:@"resultMessage"];
        retCode =[dict valueForKey:@"resultCode"];
    }
    
    if (message){
        NSLog (@"ErrorMessage:%@",message);
    }
    
    if (retCode){
        NSLog (@"ReturnCode:%@",retCode);
    }
    
    if (retMsg){
        NSLog (@"ReturnMsg:%@",retMsg);
    }
#endif
    
    [self _invokeRequestFailedHandler:error];
}

-(void)onRequestCancel
{
    NSLog(@"onRequestCancel");
    
    [self _invokeRequestCancelHandler];
}

- (void)onDownloadProgressChanged:(double) progress
{
    NSLog (@"onDownloadProgressChanged");
    
    [self _invokeDownloadProgressHandler:progress];
}

- (void)onUploadProgressChanged:(double) progress
{
    NSLog (@"onUploadProgressChanged");
    
    [self _invokeUploadProgressHandler:progress];
}

-(BOOL)onBeforeExecute
{
    NSLog(@"onBeforeExecute");
    
    return YES;
}

-(void)onFinished
{
    NSLog (@"onFinished");
    
    [self _invokeRequestFinishedHandler];
}

#pragma mark - private

-(void)_addAcceptTypeToHeader
{
    ZJResponseAcceptType acceptType;
    if (self.responseAcceptType == ZJResponseAcceptTypeAutomation) {
        switch (self.responseDataType) {
            case ZJResponseDataTypeJSON:
                acceptType = ZJResponseAcceptTypeJSON;
                break;
            case ZJResponseDataTypeNSData:
                acceptType = ZJResponseAcceptTypeData;
                break;
            case ZJResponseDataTypeText:
            case ZJResponseDataTypeJSONBase64:
                acceptType = ZJResponseAcceptTypeText;
                break;
        }
    } else {
        acceptType = self.responseAcceptType;
    }
    
    NSString *accept = nil;
    switch (acceptType) {
        case ZJResponseAcceptTypeJSON:
            accept = @"application/json;charset=utf-8";
            break;
        case ZJResponseAcceptTypeData:
            accept = @"application/octet-stream";
            break;
        case ZJResponseAcceptTypeText:
            accept = @"text/plain;charset=utf-8";
            break;
        case ZJResponseAcceptTypeImage:
            accept = @"image/png,image/gif,image/jpeg";
            break;
        case ZJResponseAcceptTypeAny:
            accept = @"*/*";
            break;
        default:
            break;
    }
    if (accept) {
        [self addRequestHeader:accept key:@"Accept"];
    }
}

-(void)_executeRealRequest
{
    switch (self.method) {
        case ZJHttpRequestMethodGet:
        {
            [self _get];
        }
            break;
        case ZJHttpRequestMethodPost:
        {
            [self _post];
        }
            break;
        case ZJHttpRequestMethodDelete:
        {
            [self _delete];
        }
            break;
        default:
            break;
    }
}

-(void)_get
{
    _currentTask = [_sessionManager GET:self.url parameters:self.parameter progress:^(NSProgress * _Nonnull downloadProgress) {
        [_weakSelf _downloadProgressHandle:0];
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [_weakSelf _requestSuccessHandle:responseObject];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [_weakSelf _requestFailHandle:error];
    }];
}

-(void)_post
{
    _currentTask = [_sessionManager POST:self.url parameters:self.parameter progress:^(NSProgress * _Nonnull uploadProgress) {
        [_weakSelf _uploadProgressHandle:0];
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [_weakSelf _requestSuccessHandle:responseObject];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [_weakSelf _requestFailHandle:error];
    }];
}

-(void)_delete
{
    _currentTask = [_sessionManager DELETE:self.url parameters:self.parameter success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [_weakSelf _requestSuccessHandle:responseObject];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [_weakSelf _requestFailHandle:error];
    }];
}

-(NSError *)_parseResonseData:(id)responseData
{
    NSError *error = nil;
    
    error = [_responseHandler onParseResonseData:self response:responseData];
    
    //解析数据成功，返回 nil;
    return error;
}

-(id)_formatJsonString:(NSString *)string
{
    NSError *error;
    id json;
    
    if (!string || string.length <= 0) {
        json = [NSJSONSerialization JSONObjectWithData:[@"{}" dataUsingEncoding:NSUTF8StringEncoding]
                                               options:NSJSONReadingMutableContainers
                                                 error:&error];
    } else {
        json = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding]
                                               options:NSJSONReadingMutableContainers
                                                 error:&error];
    }
    return json;
}

-(void)_requestSuccessHandle:(id)responseObject
{
    NSError *error;
    
    switch (self.responseDataType) {
        case ZJResponseDataTypeNSData:
        {
            NSData *data = [[NSData alloc] initWithData:responseObject];
            error = [self _parseResonseData:data];
        }
            break;
        case ZJResponseDataTypeText:
        {
            NSString *string = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            error = [self _parseResonseData:string];
        }
            break;
        case ZJResponseDataTypeJSONBase64:
        {
            id json;
            NSData *decode = [[NSData alloc] initWithBase64EncodedData:responseObject options:0];
            if (decode) {
                NSString *data = [[NSString alloc] initWithData:decode encoding:NSUTF8StringEncoding];
                json = [self _formatJsonString:data];
            }
            error = [self _parseResonseData:json];
        }
            break;
        case ZJResponseDataTypeJSON:
        {
            id json = [self _formatJsonString:responseObject];
            error = [self _parseResonseData:json];
        }
            break;
        default:
            break;
    }
    
    [self setRequestState:ZJHttpRequestStateFinished];
    
    if (error) {
        [self onRequestFailed:error];
    } else {
        [self onRequestSuccessful];
    }
    
    [self onFinished];
}

-(void)_requestFailHandle:(NSError *)error
{
    [self setRequestState:ZJHttpRequestStateFinished];
    [self onRequestFailed:error];
    [self onFinished];
}

-(void)_downloadProgressHandle:(double)progress
{
    [self onDownloadProgressChanged:progress];
}

-(void)_uploadProgressHandle:(double)progress
{
    [self onUploadProgressChanged:progress];
}

#pragma mark - block

-(void)_invokeRequestSuccessfulHandler
{
    if (self.requestSuccessfulHandler) {
        self.requestSuccessfulHandler(self);
    }
}

-(void)_invokeRequestFailedHandler:(NSError*)error
{
    if (self.requestFailedHandler) {
        self.requestFailedHandler(self, error);
    }
}

-(void)_invokeRequestCancelHandler
{
    if (self.requestCancelHandler) {
        self.requestCancelHandler(self);
    }
}

-(void)_invokeDownloadProgressHandler:(double)progress
{
    if (self.downloadProgressHandler) {
        self.downloadProgressHandler(self, progress);
    }
}

-(void)_invokeUploadProgressHandler:(double)progress
{
    if (self.uploadProgressHandler) {
        self.uploadProgressHandler(self, progress);
    }
}

-(void)_invokeRequestFinishedHandler
{
    if (self.requestFinishedHandler) {
        self.requestFinishedHandler(self);
    }
}

@end
