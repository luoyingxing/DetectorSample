//
//  DetectorPlayViewController.m
//  DetectorSample
//
//  Created by conwin on 2018/12/21.
//  Copyright © 2018年 luoyingxing. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "DetectorPlayViewController.h"
#import "DetectorPlayView.h"
#import "DetectorDecoder.h"
#import "DetectorPlayDelegate.h"

#define screenWidth [UIScreen mainScreen].bounds.size.width
#define screenHeight [UIScreen mainScreen].bounds.size.height

@interface DetectorPlayViewController ()<DetectorPlayDelegate, NSURLSessionDataDelegate>{
    DetectorPlayView *detectorPlayView;
}

@property (nonatomic, strong) DetectorDecoder *detectorDecoder;

@end

@implementation DetectorPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initBaseBar];
    [self initPlayView];
}

- (void) initBaseBar{
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.navigationController.navigationBar.barStyle = UIStatusBarStyleLightContent;
    [self setNeedsStatusBarAppearanceUpdate];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor orangeColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18],
                                                                      NSForegroundColorAttributeName:[UIColor whiteColor]}];
    self.title = @"视频探测器";
    UIButton* backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 80, 44)];
    backButton.titleLabel.font = [UIFont systemFontOfSize:16.0f];
    backButton.adjustsImageWhenHighlighted = NO;
    [backButton setImage:[UIImage imageNamed:@"ic_bar_back.png"] forState:UIControlStateNormal];
    [backButton setTitle:@"返回" forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    backButton.contentHorizontalAlignment =UIControlContentHorizontalAlignmentLeft;
    backButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
}

- (void) initPlayView{
    self.detectorDecoder = [[DetectorDecoder alloc] init];
    [self.detectorDecoder initializeDecoder];
    [self.detectorDecoder setDetectorPlayDelegate:self];
    
    detectorPlayView = [[DetectorPlayView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenWidth * 9 / 16)];
    [detectorPlayView setVideoSize:screenWidth height:screenWidth * 9 / 16];
    [self.view addSubview:detectorPlayView];
    self.detectorDecoder.detectorPlayView = detectorPlayView;
}

- (void) back:(id)sender{
    [self dismissViewControllerAnimated:TRUE completion:^{
        NSLog(@"go back");
    }];
}

- (void) viewDidAppear:(BOOL)animated{
    [self requestPlayReal];
}

-(void)requestPlayReal{
    NSString *urlStr = @"http://116.204.67.11:17001/stream/read?tid=COWN-3B1-UY-4WS&chid=1"; //real COWN-CX3-7N-5E9
    NSURL *url = [NSURL URLWithString:urlStr];
    
    /*
     创建会话对象
     NSURLSession *session = [NSURLSession sharedSession];
     第一个参数：会话对象的配置信息defaultSessionConfiguration 表示默认配置
     第二个参数：谁成为代理，此处为控制器本身即self
     第三个参数：队列，该队列决定代理方法在哪个线程中调用，可以传主队列|非主队列
     [NSOperationQueue mainQueue]   主队列：   代理方法在主线程中调用
     [[NSOperationQueue alloc]init] 非主队列： 代理方法在子线程中调用
     */
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    
    //创建请求对象
    NSMutableURLRequest *request =[[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setTimeoutInterval:20];
    [request addValue:@"keep-Alive" forHTTPHeaderField:@"Connection"];
    [request addValue:@"close" forHTTPHeaderField:@"Connection"];
    [request addValue:@"CONWIN" forHTTPHeaderField:@"User-Agent"];
    
    //根据会话对象创建一个 Task（发送请求）
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
    [dataTask resume]; //执行任务
}

//1.接收到服务器响应的时候调用该方法
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    //在该方法中可以得到响应头信息，即response
    NSLog(@"didReceiveResponse 响应头： %@", response);
    
    //注意：需要使用completionHandler回调告诉系统应该如何处理服务器返回的数据
    //默认是取消的
    /*
     NSURLSessionResponseCancel = 0,        默认的处理方式，取消
     NSURLSessionResponseAllow = 1,         接收服务器返回的数据
     NSURLSessionResponseBecomeDownload = 2,变成一个下载请求
     NSURLSessionResponseBecomeStream        变成一个流
     */
    completionHandler(NSURLSessionResponseAllow);
}

//2.接收到服务器返回数据的时候会调用该方法，如果数据较大那么该方法可能会调用多次
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    [self.detectorDecoder decodeH264Data:data];
}

//3.当请求完成(成功|失败)的时候会调用该方法，如果请求失败，则error有值
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    NSLog(@"didCompleteWithError 请求结束: %@", error);
}

# pragma DetectorPlayDelegate
- (void) onPrepared:(NSInteger)frame{
    
}


@end
