//
//  DetectorPlayer.m
//  DetectorSample
//
//  Created by conwin on 2018/12/21.
//  Copyright © 2018年 luoyingxing. All rights reserved.
//

#import "DetectorPlayer.h"

@interface DetectorPlayer ()<NSURLSessionDataDelegate>{
    //播放实时视频的请求
    NSURLSessionDataTask* realSessionDataTask;
}

@end

@implementation DetectorPlayer

//初始化播放资源
- (void)initPlayer:(NSString*) server{
    self.server = server;
    
    //初始化解码器
    self.detectorDecoder = [[DetectorDecoder alloc] init];
    [self.detectorDecoder initializeDecoder];
}

//设置播放监听回调
- (void)setDetectorPlayDelegate:(id)delegate{
    detectorPlayDelegate = delegate;
}

//请求播放实时视频
- (void)playReal:(DetectorPlayView*)view tid:(NSString*)tid channel:(NSInteger)channel{
    [self.detectorDecoder setDetectorPlayView:view];
    
    NSString *urlStr = [NSString stringWithFormat:@"%@/stream/read?tid=%@&chid=%lu", self.server, tid, channel];
    NSLog(@"Rquest URL: %@", urlStr);
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
    [session setSessionDescription:@"real"];
    
    //创建请求对象
    NSMutableURLRequest *request =[[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setTimeoutInterval:15];
    [request addValue:@"keep-Alive" forHTTPHeaderField:@"Connection"];
    [request addValue:@"close" forHTTPHeaderField:@"Connection"];
    [request addValue:@"CONWIN" forHTTPHeaderField:@"User-Agent"];
    
    //根据会话对象创建一个 Task（发送请求）
    realSessionDataTask = [session dataTaskWithRequest:request];
    //执行任务
    [realSessionDataTask resume];
}

//1.接收到服务器响应的时候调用该方法
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    //在该方法中可以得到响应头信息，即response
    NSLog(@"didReceiveResponse description:[%@]   响应头： %@", session.sessionDescription, response);
    
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
    NSLog(@"didComplete error:%@", error);
    if (detectorPlayDelegate) {
        if (error) {
            if ([detectorPlayDelegate respondsToSelector:@selector(onError:)]) {
                [detectorPlayDelegate onError:error.debugDescription];
            }
        }else {
            if ([detectorPlayDelegate respondsToSelector:@selector(onComplete)]) {
                [detectorPlayDelegate onComplete];
            }
        }
    }
}

//停止播放实时视频
- (void)stopReal{
    [realSessionDataTask cancel];
}

//释放资源
- (void)releaseMemory{
    [self.detectorDecoder destroyDecoder];
}


@end
