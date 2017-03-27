//
//  ZJHttpBusinessRequest.m
//  AFNetworkingTest
//
//  Created by 景中杰 on 17/3/27.
//  Copyright © 2017年 景中杰. All rights reserved.
//

#import "ZJHttpBusinessRequest.h"

static NSString     *MSMainServerAddress = @"";
static NSDictionary *ServerAddressList;
static BOOL isShowReLoginDialog = NO;

@interface ZJHttpBusinessRequest ()

/**
 *  创建包头
 */
-(void)createRequestHeader;

/**
 *  创建签名
 *
 *  param parameter 参数字典
 *  param token token号
 *  param time 时间戳
 */
-(NSString *)createSign:(NSDictionary *)parameter
                  token:(NSString *)token
                   time:(NSString *)time
                 userId:(NSString *)userId;

@end

@implementation ZJHttpBusinessRequest
{
//    MSProgressView *mProgressView;
    NSString *mTimestamp;
    //公用对话框
//    MSAlertDialog *mDialog;
}

-(instancetype)init
{
    self = [super init];
    
    if (self) {
        _isShowLoading = NO;
        _isShowErrorToast = YES;
        _isProcessCommonError = YES;
        mTimestamp = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
    }
    
    return self;
}

-(instancetype) initWithURL:(NSString*) url
                  parameter:(NSDictionary*) parameter
                     method:(ZJHttpRequestMethod) method
{
    self = [super initWithUrl:url parameter:parameter method:method];
    
    if (self) {
        
    }
    
    return self;
}

+(void)setServerAddress:(NSDictionary*)address
{
    
    MSMainServerAddress = address[@"msvr://"] == nil ? @"" : address[@"msvr://"];
    ServerAddressList   = address;
    
    if (MSMainServerAddress && MSMainServerAddress.length > 0 && [MSMainServerAddress hasSuffix:@"/"]){
        MSMainServerAddress = [MSMainServerAddress substringToIndex:MSMainServerAddress.length - 1];
    }
}

/**
 *  替换 URL 中的主机头。
 *  将 URL 中的 msvr:// 等scheme 替换成实际的主机头，如果 URL中没有上述的主机头则原样返回 URL。
 *
 *  @param url 等替换的 URL
 *
 *  @return 替换后的　URL。
 */
+ (NSString*)replaceHostByScheme:(NSString*)url
{
    if (!url) return url;
    
    if (!ServerAddressList) {
        return url;
    }
    
    NSRange range = [url rangeOfString:@"://"];
    if (range.location == NSNotFound){
        return url;
    }
    
    range.length += range.location;
    range.location = 0;
    
    NSString* scheme  = [url substringWithRange:range];
    NSString* address = ServerAddressList[scheme];
    
    if (address && address.length > 0) {
        return url;
    }
    
    if (![address hasSuffix:@"/"]){
        address = [address stringByAppendingString:@"/"];
    }
    
    url = [url stringByReplacingCharactersInRange:range withString:address];
    
    NSLog(@"url = %@",url);
    
    return url;
}

+(void)removeAllCookie
{
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies= cookieStorage.cookies;
    if (!cookies) {
        return ;
    }
    
    for (NSHTTPCookie *cookie in cookies) {
        [cookieStorage deleteCookie:cookie];
    }
}

-(NSString*)timestamp
{
    return [mTimestamp copy];
}

- (BOOL)onBeforeExecute
{
    if ([self.url rangeOfString:@"://"].location != NSNotFound) {
        // URL 是一个绝对路径
        self.url = [ZJHttpBusinessRequest replaceHostByScheme:self.url];
        
    }
    else{
        // url 是一个相对路径 添加缺省主机头
        if ([self.url hasPrefix:@"/"]) {
            self.url = [MSMainServerAddress stringByAppendingString:self.url];
        }
        else{
            self.url = [MSMainServerAddress stringByAppendingFormat:@"/%@",self.url];
        }
    }
    
    BOOL ok = [super onBeforeExecute];
    
    if (ok) {
        if (_isShowLoading) {
//            mProgressView = [[MSProgressView alloc] init];
            
            if (_loadingMessage) {
//                mProgressView.labelText = _loadingMessage;
            }
            else{
                //显示缺省 loading 文本
//                mProgressView.labelText = MSLocalizedString(@"Http_001", nil);
            }
            
//            [mProgressView show];
        }
        
        if (self.responseDataType == ZJResponseDataTypeJSON) {
            //创建包头
            [self createRequestHeader];
        }
    }
    
    return ok;
}

-(void)createRequestHeader
{
    NSString *token = @"";
    NSString *userId = nil;
    if (token && token.length > 0) {
//        token = [MSCryptoUtil encryptToken:token key:mTimestamp];
        [self addRequestHeader:token key:@"_token"];
//        userId = [NSString stringWithFormat:@"%lld",[MSSession getSession].user.userID];
        [self addRequestHeader:userId key:@"_userId"];
    }
    
    [self addRequestHeader:@"circle" key:@"_appName"];
//    [self addRequestHeader:[MSApplicationConfig getChannelID] key:@"_channel"];
//    [self addRequestHeader:[NSString stringWithFormat:@"%d",[MSSession getSession].user.channelID] key:@"_user_channel"];
//    [self addRequestHeader:[MSDeviceInfo UDID] key:@"_deviceId"];
//    [self addRequestHeader:[MSDeviceInfo getDeviceType] key:@"_deviceType"];
//    [self addRequestHeader:[NSString stringWithFormat:@"IOS-%@",[UIDevice currentDevice].systemVersion] key:@"_osv"];
//    NSString *version = [NSString stringWithFormat:@"%d",[MSApplicationConfig getCurrentVersion]];
//    [self addRequestHeader:version key:@"_appv"];
    
    
    [self addRequestHeader:mTimestamp key:@"_time"];
    
    NSString *_sign = [self createSign:self.parameter token:token time:mTimestamp userId:userId];
    [self addRequestHeader:_sign key:@"_sign"];
    
}

-(NSString *)createSign:(NSDictionary *)parameter token:(NSString *)token time:(NSString *)time userId:(NSString *)userId
{
    NSString *_sign = @"";
    if (parameter.count > 0) {
        NSError *error;
        //因为字典对象在克隆（迭代）时会自动排序，这样导致克隆后的字典与原字典内的字段序顺不同，所以导致签名失败
        //这里将字典重新克隆一份为的是让字典重新排序，这样就与实际发出去的请求顺序是一致的。
        NSData  *data  = [NSJSONSerialization dataWithJSONObject: [parameter copy]
                                                         options: 0
                                                           error: &error];
        if (!error){
            _sign = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    
    
    
    if (token && token.length > 0) {
        if (![_sign isEqualToString:@""]) {
            _sign = [_sign stringByAppendingString:@"&"];
        }
        _sign = [_sign stringByAppendingFormat:@"_token=%@", token];
        
        if (![_sign isEqualToString:@""]) {
            _sign = [_sign stringByAppendingString:@"&"];
        }
        _sign = [_sign stringByAppendingFormat:@"_time=%@", time];
        
        if (![_sign isEqualToString:@""]) {
            _sign = [_sign stringByAppendingString:@"&"];
        }
        _sign = [_sign stringByAppendingFormat:@"_userId=%@", userId];
    } else {
        if (![_sign isEqualToString:@""]) {
            _sign = [_sign stringByAppendingString:@"&"];
        }
        _sign = [_sign stringByAppendingFormat:@"_time=%@", time];
    }
    
    return _sign;
//    return [MSCryptoUtil getMSMD5:_sign];
}

-(void)onRequestFailed:(NSError *)error
{
    if (_isProcessCommonError){//处理通用错误
        if ([@"10" isEqualToString:self.resultCode]){
//            [[NSNotificationCenter defaultCenter] postNotificationName:[MSNoticeDefine reLoginNotice] object:nil];
//            if ([[MSSession getSession] isLogin] && ![MSSession getSession].user.isRegistered) {
//                [[MSLoginManager shareInstance] logout:NO];
//            } else {
//                [self showReLoginDialog];
//            }
            [super onRequestFailed:error];
            return;
        }
    }
    
    if (_isShowErrorToast) {//显示错误提示框
        if (self.resultMessage && self.resultMessage.length > 0) {
//            [[MSApplicationHandler shareInstance].window makeToast:self.resultMessage
//                                                          duration:1.5
//                                                          position:nil];
        } else {
//            if (![MSNetworkStatusObserver isNetworkEnable]) {
//                [[MSApplicationHandler shareInstance].window makeToast:MSLocalizedString(@"Http_005", nil)
//                                                              duration:1.5
//                                                              position:nil];
//            } else {
//                if (error.code == NSURLErrorTimedOut) {
//                    [[MSApplicationHandler shareInstance].window makeToast:error.userInfo[NSLocalizedFailureReasonErrorKey]
//                                                                  duration:1.5
//                                                                  position:nil];
//                }
//            }
        }
    }
    
    [super onRequestFailed:error];
}

-(void)onFinished
{
//    if (mProgressView) {
//        [mProgressView close];
//    }
    
    [super onFinished];
}

@end
