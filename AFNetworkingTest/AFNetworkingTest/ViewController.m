//
//  ViewController.m
//  AFNetworkingTest
//
//  Created by 景中杰 on 17/1/17.
//  Copyright © 2017年 景中杰. All rights reserved.
//

#import "ViewController.h"
#import "ZJHttpRequest.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    ZJHttpRequest *request = [[ZJHttpRequest alloc] initWithUrl:@"http://m2.yinjitv.com/api/system/time" method:ZJHttpRequestMethodGet];
    
    request.requestSuccessfulHandler = ^(ZJHttpRequest *request)
    {
        NSLog(@"requestSuccessfulHandler");
    };
    
    request.requestFailedHandler = ^(ZJHttpRequest *request, NSError *error)
    {
        NSLog(@"error = %@",error.description);
    };
    
    [request execute];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
