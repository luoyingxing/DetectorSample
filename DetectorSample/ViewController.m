//
//  ViewController.m
//  iOSFrame
//
//  Created by 罗映星 on 2018/10/30.
//  Copyright © 2018 罗映星. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <NSURLSessionDataDelegate>

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 50, 200, 200)];
    label.text = @"post request";
    [self.view addSubview:label];
    
    label.userInteractionEnabled=YES;
    UITapGestureRecognizer *labelTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(labelTouchUpInside:)];
    [label addGestureRecognizer:labelTapGestureRecognizer];
    
}

-(void) labelTouchUpInside:(UITapGestureRecognizer *)recognizer{
    [self postClick];
}

/* POST 请求 */
-(void)postClick{
    // http://116.204.67.11:17001/stream/read
    // tid=COWN-3B1-UY-4WS&chid=1&from=2018-12-07 16:31:15&to=2018-12-07 16:31:35
    NSString* body = [@"from=2018-12-07 16:31:15&to=2018-12-07 16:31:35" stringByAddingPercentEncodingWithAllowedCharacters:[[NSCharacterSet characterSetWithCharactersInString:@"?!@#$^%*+,:;'\"`<>()[]{}/\\| "] invertedSet]];
    
    NSString *urlStr = [NSString stringWithFormat:@"http://116.204.67.11:17001/stream/read?tid=COWN-3B1-UY-4WS&chid=1&%@", body];
    NSLog(@"request url: %@", urlStr);
    //转码
    // stringByAddingPercentEscapesUsingEncoding 只对 `#%^{}[]|\"<> 加空格共14个字符编码，不包括”&?”等符号), ios9将淘汰
    // ios9 以后要换成 stringByAddingPercentEncodingWithAllowedCharacters 这个方法进行转码
    //    urlStr = [urlStr stringByAddingPercentEncodingWithAllowedCharacters:[[NSCharacterSet characterSetWithCharactersInString:@"?!@#$^&%*+,:;='\"`<>()[]{}/\\| "] invertedSet]];
    NSURL *url = [NSURL URLWithString:urlStr];
    //http://download.jingyun.cn/api/get-last-version?model=cn0903&level=alpha
    
    //创建会话对象
    //    NSURLSession *session = [NSURLSession sharedSession];
    /*
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
    request.timeoutInterval = 20;
    //    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
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
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"didReceiveData：%@", str);

    Byte *dataByte = (Byte *)[data bytes];
    
    
    
}

//3.当请求完成(成功|失败)的时候会调用该方法，如果请求失败，则error有值
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    NSLog(@"didCompleteWithError 请求失败: %@", error);
}

@end

