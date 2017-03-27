//
//  ZJHttpBusinessRequest.h
//  AFNetworkingTest
//
//  Created by 景中杰 on 17/3/27.
//  Copyright © 2017年 景中杰. All rights reserved.
//

#import "ZJHttpRequest.h"

@interface ZJHttpBusinessRequest : ZJHttpRequest
/**是否显示错误提示，缺省显示*/
@property (nonatomic,assign) BOOL isShowErrorToast;
/**是否显示 Loading，缺省不显示 */
@property (nonatomic,assign) BOOL isShowLoading;
/**是否处理通用错误（例如：当登录无效时会显示一个对话框提示用户重新登录），默认 YES */
@property (nonatomic,assign) BOOL isProcessCommonError;
/**Loading 中的消息文本，缺省为 nil，显示缺省文本 */
@property (nonatomic,copy) NSString *loadingMessage;
/**当前请求的时间戳，这个时间戳时创建 MSBusinessRequest 实例时生成的。*/
@property (nonatomic,copy,readonly) NSString *timestamp;

/**
 * 设置服务地址
 * @param address config 文件中的 ServerAddress 节点对象
 */
+(void)setServerAddress:(NSDictionary*)address;

/**
 *  替换 URL 中的主机头。
 *  将 URL 中的 msvr:// 等替换成实际的主机头，如果 URL中没有上述的主机头则原样返回 URL。
 *
 *  @param url 等替换的 URL
 *
 *  @return 替换后的　URL。
 */
+ (NSString*)replaceHostByScheme:(NSString*)url;

/**
 *  清除本地端所有 Cookie 信息
 */
+ (void)removeAllCookie;

@end
