//
//  ZJHttpResponseHandler.h
//  AFNetworkingTest
//
//  Created by 景中杰 on 17/1/17.
//  Copyright © 2017年 景中杰. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ZJHttpRequest;

@protocol ZJHttpResponseHandler <NSObject>

/**
 *  服务器结果码，解析成功后应该设置此属性
 */
@property (copy, nonatomic, readonly) NSString *resultCode;

/**
 *  服务器返回的消息，是服务器结果数据中  message  字段解析成功后应该设置此属性。
 */
@property (copy, nonatomic, readonly) NSString *resultMessage;

/**
 *  结果数据，onParseResonseData 事件处器成功解析出返回数据后要设置此属性。
 *  如果 responseType = MSReponseDataTypeNSData 则 resultData 返回　一个 NSData 对象。
 *  如果 responseType = MSReponseDataTypeText 则  resultData 返回　一个 NSString 对象。
 *  如果 responseType = MSReponseDataTypeJSON  resultData 返回一个 MSJSONArray 或 MSJSONArray，
 *  它是服务器结果数据中 data 字段的内容。
 */
@property (strong, nonatomic, readonly) id resultData;

/**
 *  解析  response  数据
 *
 *  @param request 当前的请求对象。
 *  @param data    应答数据，该数据是经过转型后的数据，数据类型根据 MSReponseDataType 类型转换的
 *
 *  @return 如果数据解析成功则返回  nil  ,  否则返回错误队象。
 */
-(NSError *)onParseResonseData:(ZJHttpRequest *)request response:(id)data;

/**
 *  判断服务器返回状态是否成功，这个状态不是 Http 200， 而是业务上的成功。
 *
 *  @return 正常返回 true, 否则返回 false.
 */
- (BOOL)isRequestSuccessful;

@end
