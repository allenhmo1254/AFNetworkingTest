//
//  ZJHttpRequest.h
//  AFNetworkingTest
//
//  Created by 景中杰 on 17/1/17.
//  Copyright © 2017年 景中杰. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZJHttpResponseHandler.h"

/**
 *  服务器返回数据类型
 */
typedef NS_ENUM(NSInteger, ZJResponseDataType) {
    
    ZJResponseDataTypeJSON = 0, //JSON 类型数据
    ZJResponseDataTypeNSData,   //Data 类型数据
    ZJResponseDataTypeText,     //String类型数据
    ZJResponseDataTypeJSONBase64
};


/**
 *  定义一个接收类型的枚举
 */
typedef NS_ENUM(NSInteger, ZJResponseAcceptType) {
    
    ZJResponseAcceptTypeNone = 0,  // 不指定 Accept
    ZJResponseAcceptTypeAutomation,
    ZJResponseAcceptTypeJSON,     // application/json;charset=utf-8;
    ZJResponseAcceptTypeData,     // application/octet-stream
    ZJResponseAcceptTypeText,     // text/plain;charset=utf-8;
    ZJResponseAcceptTypeImage,    // image/png,image/gif,image/jpge
    ZJResponseAcceptTypeAny       // */*
};

/**
 *  执行状态的枚举类型
 */
typedef NS_ENUM(NSInteger, ZJHttpRequestState) {
    
    ZJHttpRequestStateInit = 0,      /*准备就绪将要执行请求*/
    ZJHttpRequestStateNotReady,      /*未就绪不能执行请求*/
    ZJHttpRequestStateExecuting,     /*正在执行 http 请求*/
    ZJHttpRequestStateFinished       /*http请求执行完成*/
    
};

/**
 *  定义Http请求的类型
 */
typedef NS_ENUM(NSInteger, ZJHttpRequestMethod){
    
    ZJHttpRequestMethodGet = 0,
    ZJHttpRequestMethodPost,
    ZJHttpRequestMethodDelete,
};

/**
 *  Post 请求格式
 */
typedef NS_ENUM(NSInteger, ZJPostDataEncodingType){
    
    ZJPostDataEncodingTypeURl = 0,
    ZJPostDataEncodingTypeJSON, //
    ZJPostDataEncodingTypeBASE64 //默认为Base加密的
};

@class ZJHttpRequest;
/** 请求回调函数 */
typedef void (^ZJHttpRequestBlock)(ZJHttpRequest *request);

/** 请求失败回调函数 */
typedef void (^ZJHttpRequestFailedBlock)    (ZJHttpRequest *request,NSError *error);

/** 带有进度条请求回调函数*/
typedef void (^ZJHttpRequestProgressBlock)  (ZJHttpRequest *request,double progress);

@interface ZJHttpRequest : NSObject

/**
 *  应答处理器，默认的处理器为 MSDefaultHttpResponseHandler，你可以重新设置一个自定义的处理器。
 *  该属性不能设为 nil。
 */
@property (strong,nonatomic) id<ZJHttpResponseHandler> responseHandler;

/** 
 设定结果数据的类型，默认值为 MSReponseDataTypeJSON 
 */
@property (assign,nonatomic) ZJResponseDataType responseDataType;

/** 
 Http 请求目的地址
 */
@property (copy, nonatomic) NSString *url;

/** 
 Http 表单数据（NSNumber、NSString）
 */
@property (strong, nonatomic, readonly) NSMutableDictionary *parameter;

/** 
 Http 请求方法类型 
 */
@property (assign, nonatomic) ZJHttpRequestMethod method;

/** 
 是否在每个请求上添加公共参数，默认是YES 
 */
@property (assign, nonatomic) BOOL isAppendGlobalParameter;

/** 
 POST 表单数据格式， 默认的是 
 */
@property (assign, nonatomic) ZJPostDataEncodingType postDataEncodingType;

/**
 *  设置 Accept 的类型，缺省为 ZJResponseAcceptTypeAutomation 将与 responseDataType 自动匹配对应，
 *  对应关系如下:
 *  ZJReponseDataTypeJSONBase64 => ZJResponseAcceptTypeText
 *  ZJReponseDataTypeJSON    => ZJResponseAcceptTypeJSON
 *  ZJResponseAcceptTypeData => ZJResponseAcceptTypeData
 *  ZJReponseDataTypeText    => ZJResponseAcceptTypeText
 */
@property (assign, nonatomic, readonly) ZJResponseAcceptType responseAcceptType;

/** 
 服务器返回码， 正常返回时返回码为 "000000" 
 */
@property (copy, nonatomic) NSString *resultCode;

/** 
 服务器返回的消息 是服务器结果数据中 message 字段的内容 
 */
@property (copy, nonatomic, readonly) NSString *resultMessage;

/**
 *  结果数据
 *  如果 responseType = MSReponseDataTypeNSData 则 resultData 返回　一个 NSData 对象。
 *  如果 responseType = MSReponseDataTypeText 则  resultData 返回　一个 NSString 对象。
 *  如果 responseType = MSReponseDataTypeJSON  resultData 返回一个 MSJSONArray 或 MSJSONArray，
 *  它是服务器结果数据中 data 字段的内容。
 */
@property (strong, nonatomic, readonly) id resultData;

/** 
 执行状态 
 */
@property (assign, nonatomic, readonly) ZJHttpRequestState requestState;

/** 
 当前请求是否被取消 
 */
@property (assign, nonatomic) BOOL isCancelled;

/**
 *  Http 请求成功处理器，如果 isFromCache = true 表示本次返回的是缓存的数据。
 *  处理器中需要检测 requestState 值，如果不等于MSHttpRequestStateFinished，
 *  则表示请求仍在进行，该事件可能还会在次发送。
 *  结果数据保存在 resultData 属性中。
 */
@property (copy, nonatomic) ZJHttpRequestBlock requestSuccessfulHandler;

/**
 *  Http 请求失败处理器
 */
@property (copy, nonatomic) ZJHttpRequestFailedBlock requestFailedHandler;

/**
 *  Http 请求取消处理器
 */
@property (copy, nonatomic) ZJHttpRequestBlock requestCancelHandler;

/**
 *  下载数据进度处理器，进度范围 [0，1]。如果是从缓存中返回的数据，这个处理器将不会调用。
 */
@property (copy, nonatomic) ZJHttpRequestProgressBlock downloadProgressHandler;


/**
 *  上载数据进度处理器，进度范围 [0，1]
 */
@property (copy, nonatomic) ZJHttpRequestProgressBlock uploadProgressHandler;

/**
 *  请求执行完成处理器，该处理器是处理器序列中的最后一个，无论请求成功、失败、被取消，
 *  该处理器都将被执行。
 */
@property (copy, nonatomic) ZJHttpRequestBlock requestFinishedHandler;

/**
 *  设置请求超时时间，单位秒。
 */
@property (assign, nonatomic) int timeoutInterval;

/**
 *  自定义标签，用于标识当前请求。缺省值为 nil;
 */
@property (copy, nonatomic) NSString* tag;

/**
 *  是否移除值为 Empty 的参数，默认值为 YES。
 */
@property (assign, nonatomic) BOOL isRemoveEmptyParameter;

/**
 *  初始化方法
 *
 *  @param url      Http 请求地址
 *  @param parmeter Http 请求参数 NSString、NSData 数据字典，如果添加了 NSData,
 *                    则http请求的方法会强制为 multipart/form-data。
 *  @param method   请求方法
 *
 *  @return   返回 MSHttpRequest 对象
 */
- (instancetype)initWithUrl:(NSString *)url parameter:(NSDictionary *)parmeter method:(ZJHttpRequestMethod)method;
/**
 *  初始化方法
 *
 *  @param url    Http 请求地址
 *  @param method 请求方法
 *
 *  @return 返回一个 MSHttpRequest 对象
 */
- (instancetype)initWithUrl:(NSString *)url method:(ZJHttpRequestMethod)method;

/**
 *  添加表单数据
 *
 *  @param value 数据
 *  @param key   数据对应的键值
 */
- (void)addParameter:(NSString *)value key:(NSString *)key;
/**
 *  添加表单数据
 *
 *  @param value 数据
 *  @param key   数据的键值
 */
- (void)addParameterWithDict:(NSDictionary *)value key:(NSString *)key;
/**
 *  添加表单数据
 *
 *  @param value 数据
 *  @param key   数据的键值
 */
- (void)addParameterWithArray:(NSArray *)value key:(NSString *)key;
/**
 *  添加一个文件，如果调用了此方法，则http请求方法会强制为 mulipart/frome-data
 *
 *  @param filePath 添加文件的路径
 *  @param key      文件的键值
 */
- (void)addFile:(NSString *)filePath forKey:(NSString *)key;
/**
 *   添加一个数据流用于上传，如果调用了此方法，则http请求方法会强制为 mulipart/frome-data
 *
 *  @param data 数据流
 *  @param key  数据流键值
 */
- (void)addData:(NSData *)data forKey:(NSString *)key;

/**
 *   添加一个数据流用于上传，如果调用了此方法，则http请求方法会强制为 mulipart/frome-data
 *
 *  @param data 数据，不能为 nil
 *  @param key  数据字段的名，不能为 nil 或 空串
 *  @param fileName 数据的文件名
 *  @param mimeType 数据的 MimeType
 */
- (void)addData:(NSData*)data forKey:(NSString*) key fileName:(NSString*)fileName mimeType:(NSString*)mimeType;

/**
 *  执行网络请求
 *
 *  @return 返回一个BOOL类型的值
 */
- (BOOL)execute;

/**
 *  取消正在执行的操作
 */
- (void)cancel;

/**
 *  判断服务器返回的结果是否正常，只有在响应码为 200， 并且resultCode 为"TS0000"时才返回  true
 *
 *  @return 正常返回 true, 否则返回  false.
 */
- (BOOL)isRequestSuccessful;

/**
 *  添加请求头
 *
 *  @param value  值
 *  @param key   对应的键值
 */
- (void)addRequestHeader:(NSString *)value key:(NSString *)key;

/**
 *  添加请求头
 *
 *  @param headersDictionary 请求头字典
 */
- (void)addRequestHeaders:(NSDictionary *)headersDictionary;

/**
 *  获取Http  应答头
 *
 *  @return  返回Http应答头
 */
- (NSDictionary *)getRequestHeaders;

/**
 *  获取请求头中的某一个值
 *
 *  @param headers HTTP 请求头
 *  @param name    头名字
 *  @param key     对应值的键
 */
- (NSString *)getValueFromHeaders:(NSDictionary *)headers headerName:(NSString *)name key:(NSString *)key;

/**
 *  以 MSJSONObject/MSJSONArrar 类型返回原始 response 数据
 */
- (id)responseJSON;
/**
 *  以 NSdata 类型返回原始数据
 *
 *  @return NSData 类型的数据
 */
- (NSData *)responseData;
/**
 *  以 字符串类型返回原始数据
 *
 *  @return NSString类型的数据
 */
- (NSString *)responseText;

/**
 *  根据字符串返回http请求方法
 *
 *  @param method 方法字符串
 *
 *  @return HTTP  请求方法
 */
+ (ZJHttpRequestMethod) httpRequestMethodByString:(NSString *)method;

/**
 *  获取请求失败后的错误信息，如果不能从错误中读到信息则返回nil
 *
 *  @param error 错误对象
 *  @return message 字符串
 */
+ (NSString *)getErrorMessage:(NSError *)error;
/**
 *  添加HTTP请求全局参数，使用此方法添加的参数添加到每一个HTTP请求中 (isAppendGlobalParameters = YES 时)
 *
 *  @param value 参数值
 *  @param key   参数的键值
 */
+ (void)setGlobalParameter:(id)value forKey:(NSString *)key;
/**
 *  获取 HTTP 请求全局参数字典
 *
 *  @return 全局参数字典
 */
+ (NSMutableDictionary *)globalParameters;
/**
 *  设置全局网络超时时间，用该方法改变超时时间，只影响 MSHttpRequest 新实例， 已经创建的不影响。
 *
 *  @param interval 超时时间， 单位：秒， 默认 30秒
 */
+ (void)setGlobalTimeoutInterval:(uint)interval;

#pragma mark - 供子类重写的方法

/**
 *  请求服务器成功时调用此事件
 */
- (void)onRequestSuccessful;

/**
 *  当HTTP请求发生错误时或服务器返回一个错误消息时调用此事件。
 *
 *  @param error 错误信息对象
 */
- (void)onRequestFailed:(NSError *)error;

/**
 *   当一个正在执行的请求被取消时， 调用此事件
 */
- (void)onRequestCancel;

/**
 *  下载进度改变时调用此事件
 *
 *  @param progress 进度
 */
- (void)onDownloadProgressChanged:(double)progress;

/**
 *  上载进度改变时调用
 *
 *  @param progress 进度
 */
- (void)onUploadProgressChanged:(double)progress;

/**
 *  在 execute 方法执行时会立即触发此事件，可yi做一些预处理，如果该方法返回 false 则 execute 会立即停止执行
 *
 *  @return 返回 布尔值
 */
- (BOOL)onBeforeExecute;

/**
 *    http 请求结束后会立即调用此事件，此事件执行完成后 http 内部资源将被毁。
 *    如果子类重写此方法，必须调用[super onFinished]
 */
- (void)onFinished;

@end
