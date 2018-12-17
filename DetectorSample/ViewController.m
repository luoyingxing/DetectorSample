//
//  ViewController.m
//  iOSFrame
//
//  Created by luoyingxing on 2018/10/30.
//  Copyright © 2018 luoyingxing. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <NSURLSessionDataDelegate>{
    int regexNext[40];
    int splitNext[4];
    
    int regexLen;
    int splitLen;
    
    int lastIndex;
}

//缓存接受到的数据
@property (nonatomic, strong) NSMutableData* mutableData;
@property (nonatomic, strong) NSData* regexNSData;
@property (nonatomic, strong) NSData* splitNSData;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 50, 200, 200)];
    label.text = @"post request";
    [self.view addSubview:label];
    label.userInteractionEnabled=YES;
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(labelTouchUpInside:)];
    [label addGestureRecognizer:recognizer];
}

- (void) viewWillAppear:(BOOL)animated{
    // save data
    self.mutableData = [[NSMutableData alloc] init];
    lastIndex = 0;
    
    // boundary regex
    NSString* regex = @"------WebKitFormBoundaryIZDrYHwuf2VJdpHw";
    self.regexNSData = [regex dataUsingEncoding: NSUTF8StringEncoding];
    regexLen = (int) [self.regexNSData length];
    Byte* regexByte = (Byte*)[self.regexNSData bytes];
    //transform KMP next
    regexNext[0] = -1;
    int k = -1;
    int j = 0;
    while (j < regexLen - 1) {
        if (k == -1 || regexByte[j] == regexByte[k]) {
            j++;
            k++;
            regexNext[j] = k;
        }else{
            k = regexNext[k];
        }
    }
    
    // split regex
    NSString* split = @"\r\n\r\n";
    self.splitNSData = [split dataUsingEncoding: NSUTF8StringEncoding];
    splitLen = (int) [self.splitNSData length];
    Byte* splitByte = (Byte*)[self.splitNSData bytes];
    //transform KMP next
    splitNext[0] = -1;
    int k1 = -1;
    int j1 = 0;
    while (j1 < splitLen - 1) {
        if (k1 == -1 || splitByte[j1] == splitByte[k1]) {
            j1++;
            k1++;
            splitNext[j1] = k1;
        }else{
            k1 = splitNext[k1];
        }
    }
    
//    NSLog(@"viewDidLoad：regex:%s  regex[0]:%d", regexByte, regexByte[0]);
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
//    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"didReceiveData：%@", str);

//    Byte *dataByte = (Byte *)[data bytes];
//    NSLog(@"didReceiveData：%hhu", dataByte[0]);
    
//    NSData* nsData = [[NSData alloc] initWithBytes:dataByte length:data.length];
    
    //0.
    Byte* regexByte = (Byte*)[self.regexNSData bytes];
    Byte* splitByte = (Byte*)[self.splitNSData bytes];
    
    //1. add to mutable date
    [self.mutableData appendData:data];
    
    //2. find regex
    Byte *dataByte = (Byte *)[self.mutableData bytes];
    int position = (int)[self.mutableData length] - 1;
    
//    NSLog(@"当前数据长度： %d", position);
//    NSLog(@"didReceiveData：regex:%s  regex[0]:%d", self.regexByte, self.regexByte[0]);
    
    if (position > regexLen) {
        int findIndex = -1;
        int j = lastIndex;
        int s = 0;
        while(j < position){
            if (s == -1 || dataByte[j] == regexByte[s]) {
                j ++;
                s ++;
                if (s >= regexLen){
                    findIndex = j - regexLen;
                    break;
                }
            }else{
                s = regexNext[s];
            }
        }
        
//        NSLog(@"===== find part data ===== %d", findIndex);
        
        if (findIndex != -1) {
            //find part data

            if (findIndex >= splitLen) {
                int jj = 0;
                int ss = 0;
                
                while (jj < findIndex) {
                    if (ss == -1 || dataByte[jj] == splitByte[ss]) {
                        jj ++;
                        ss ++;
                        
                        if (ss >= splitLen) {
                            int n = jj - splitLen;
                            
                            NSData *headerData =[self.mutableData subdataWithRange:NSMakeRange(0, n)];
                            NSString *header = [[NSString alloc] initWithData:headerData encoding:NSUTF8StringEncoding];
                            NSLog(@"header: %@", header);
                            
                            NSData *imageData =[self.mutableData subdataWithRange:NSMakeRange(n + splitLen, findIndex - n - splitLen)];
                            NSLog(@"image length: %lu", [imageData length]);
                            
                        }
                        
                    }else{
                        ss = splitNext[ss];
                    }
                }
            }
            
            //reset
            lastIndex = 0;
            
            [self.mutableData replaceBytesInRange:NSMakeRange(0, findIndex + regexLen) withBytes:NULL length:0];//删除索引0到索引50的数据
            
        }else{
            lastIndex = position - regexLen -1;
        }
    }

}

//3.当请求完成(成功|失败)的时候会调用该方法，如果请求失败，则error有值
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    NSLog(@"didCompleteWithError 请求结束: %@", error);
}

@end

