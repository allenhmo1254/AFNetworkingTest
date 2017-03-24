//
//  ZJDefaultHttpResponseHandler.m
//  AFNetworkingTest
//
//  Created by 景中杰 on 17/1/17.
//  Copyright © 2017年 景中杰. All rights reserved.
//

#import "ZJDefaultHttpResponseHandler.h"
#import "ZJHttpRequest.h"

@implementation ZJDefaultHttpResponseHandler
{
    ZJResponseDataType _responseDataType;
}

@synthesize resultCode = _resultCode;
@synthesize resultData = _resultData;
@synthesize resultMessage = _resultMessage;

-(NSError *)onParseResonseData:(ZJHttpRequest *)request response:(id)data
{
    _responseDataType = request.responseDataType;
    
    switch (_responseDataType) {
        case ZJResponseDataTypeNSData:
        {
            _resultCode = data;
        }
            break;
        case ZJResponseDataTypeText:
        {
            _resultData = data;
        }
            break;
        case ZJResponseDataTypeJSON:
        case ZJResponseDataTypeJSONBase64:
        {
            if (data == nil || ![data isKindOfClass:[NSMutableDictionary class]]) {
                
            }
            
            NSDictionary *dict = (NSDictionary *)data;
            [self parseJsonData:_responseDataType data:dict];
            
            if (!_resultCode) {
                
            }
            
            if (![self isRequestSuccessful]) {
                
            }
        }
            break;
        default:
            break;
    }
    return nil;
}

- (BOOL)isRequestSuccessful
{
    switch (_responseDataType) {
        case ZJResponseDataTypeJSON:
            return [self.resultCode isEqualToString:@"0"];
        case ZJResponseDataTypeJSONBase64:
            return [self.resultCode isEqualToString:@"1"];
        default:
            return self.resultData != nil;
    }
    
    return YES;
}

-(void)parseJsonData:(ZJResponseDataType)type data:(NSDictionary *)dict
{
    if (type == ZJResponseDataTypeJSON) {
        _resultCode = [dict valueForKey:@"code"];
        _resultMessage = [dict valueForKey:@"msg"];
        
        _resultData = [dict valueForKey:@"data"];
        
    } else {
        _resultCode     = [dict valueForKey:@"Result"];
        _resultMessage  = [dict valueForKey:@"Descrip"];
        _resultData     = dict;
    }
}

@end
