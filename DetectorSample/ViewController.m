//
//  ViewController.m
//  iOSFrame
//
//  Created by luoyingxing on 2018/10/30.
//  Copyright © 2018 luoyingxing. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import "ViewController.h"
#import "VideoDecoder.h"
#import "colorconvert.h"
#import "ResponseDelegate.h"
#import "KCLH264Decoder.h"
//#import "DecodeH264StreamTest.h"
#import "OpenGLView20.h"

#define screenWidth [UIScreen mainScreen].bounds.size.width
#define screenHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController () <ResponseDelegate, NSURLSessionDataDelegate>{
    UIImageView *imageView;
    AVSampleBufferDisplayLayer *sampleBufferDisplayLayer;
    CVPixelBufferRef* previousPixelBuffer;
    OpenGLView20 *openGLView20;
    
    int regexNext[40];
    int splitNext[4];
    
    int regexLen;
    int splitLen;
    
    int lastIndex;
    
    BOOL hasAddObserver;
}

//缓存接受到的数据
@property (nonatomic, strong) NSMutableData* mutableData;
@property (nonatomic, strong) NSData* regexNSData;
@property (nonatomic, strong) NSData* splitNSData;
@property (nonatomic, strong) KCLH264Decoder *decoder;
//@property (nonatomic, strong) DecodeH264StreamTest *decodeH264Stream;

@end

@implementation ViewController

int mTrans=0x0F0F0F0F;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.decoder = [[KCLH264Decoder alloc] init];
    [self.decoder initializeDecoder];
    [self.decoder setResponseDelegate:self];
    
//    self.decodeH264Stream = [[DecodeH264StreamTest alloc] init];
//    [self.decodeH264Stream initialize];
//    [self.decodeH264Stream setResponseDelegate:self];
    
    
    // Do any additional setup after loading the view, typically from a nib.
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 100, 50)];
    label.text = @"image stream";
    [self.view addSubview:label];
    label.userInteractionEnabled=YES;
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(labelTouchUpInside:)];
    [label addGestureRecognizer:recognizer];
    
    UILabel *playLabel = [[UILabel alloc] initWithFrame:CGRectMake(150, 10, 100, 50)];
    playLabel.text = @"play h264";
    [self.view addSubview:playLabel];
    playLabel.userInteractionEnabled=YES;
    UITapGestureRecognizer *r = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(play:)];
    [playLabel addGestureRecognizer:r];
    
    UILabel *hLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, 100, 50)];
    hLabel.text = @"h264";
    [self.view addSubview:hLabel];
    hLabel.userInteractionEnabled=YES;
    UITapGestureRecognizer *r1 = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(playh264:)];
    [hLabel addGestureRecognizer:r1];
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 200, screenWidth, screenWidth * 9 / 16)];
//    UIImage *image = [[UIImage alloc] init];
//    image = [UIImage imageNamed:@"img_two.jpg"];
//    imageView.image = image;
//    imageView.contentMode =  UIViewContentModeCenter;
    [self.view addSubview:imageView];
    
    sampleBufferDisplayLayer = [[AVSampleBufferDisplayLayer alloc] init];
    sampleBufferDisplayLayer.frame = imageView.bounds;
    sampleBufferDisplayLayer.position = CGPointMake(CGRectGetMidX(imageView.bounds), CGRectGetMidY(imageView.bounds));
    sampleBufferDisplayLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    sampleBufferDisplayLayer.opaque = YES;
    [imageView.layer addSublayer:sampleBufferDisplayLayer];
    
    openGLView20 = [[OpenGLView20 alloc] initWithFrame:CGRectMake(0, 250, screenWidth, screenWidth * 9 / 16)];
    [openGLView20 setVideoSize:screenWidth height:screenWidth * 9 / 16];
    [self.view addSubview:openGLView20];
    
    self.decoder.openGLView20 = openGLView20;
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
    
    NSString *urlStr = @"http://116.204.67.11:17001/stream/read?tid=COWN-3B1-UY-4WS&chid=1"; //real COWN-CX3-7N-5E9
//    NSString *urlStr = [NSString stringWithFormat:@"http://116.204.67.11:17001/stream/read?tid=COWN-3B1-UY-4WS&chid=1&%@", body]; //back
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
    [self.decoder decodeH264Data:data];
    //0.
//    Byte* regexByte = (Byte*)[self.regexNSData bytes];
//    Byte* splitByte = (Byte*)[self.splitNSData bytes];
//
//    //1. add to mutable date
//    [self.mutableData appendData:data];
//
//    //2. find regex
//    Byte *dataByte = (Byte *)[self.mutableData bytes];
//    int position = (int)[self.mutableData length] - 1;
//
////    NSLog(@"当前数据长度： %d", position);
////    NSLog(@"didReceiveData：regex:%s  regex[0]:%d", self.regexByte, self.regexByte[0]);
//
//    if (position > regexLen) {
//        int findIndex = -1;
//        int j = lastIndex;
//        int s = 0;
//        while(j < position){
//            if (s == -1 || dataByte[j] == regexByte[s]) {
//                j ++;
//                s ++;
//                if (s >= regexLen){
//                    findIndex = j - regexLen;
//                    break;
//                }
//            }else{
//                s = regexNext[s];
//            }
//        }
//
////        NSLog(@"===== find part data ===== %d", findIndex);
//
//        if (findIndex != -1) {
//            //find part data
//
//            if (findIndex >= splitLen) {
//                int jj = 0;
//                int ss = 0;
//
//                while (jj < findIndex) {
//                    if (ss == -1 || dataByte[jj] == splitByte[ss]) {
//                        jj ++;
//                        ss ++;
//
//                        if (ss >= splitLen) {
//                            int n = jj - splitLen;
//
//                            NSData *headerData =[self.mutableData subdataWithRange:NSMakeRange(0, n)];
//                            NSString *header = [[NSString alloc] initWithData:headerData encoding:NSUTF8StringEncoding];
//                            NSLog(@"header: %@", header);
//
//                            NSData *imageData =[self.mutableData subdataWithRange:NSMakeRange(n + splitLen, findIndex - n - splitLen)];
//                            NSLog(@"image length: %lu", [imageData length]);
//
//                            [self dispatch:headerData image:imageData];
//                        }
//
//                    }else{
//                        ss = splitNext[ss];
//                    }
//                }
//            }
//
//            //reset
//            lastIndex = 0;
//
//            [self.mutableData replaceBytesInRange:NSMakeRange(0, findIndex + regexLen) withBytes:NULL length:0];//删除索引0到索引50的数据
//
//        }else{
//            lastIndex = position - regexLen -1;
//        }
//    }
}

//3.当请求完成(成功|失败)的时候会调用该方法，如果请求失败，则error有值
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    NSLog(@"didCompleteWithError 请求结束: %@", error);
}

- (void) dispatch:(NSData*)header image:(NSData*)image{
    //back
//    dispatch_async(dispatch_get_main_queue(), ^{
//        UIImage *img = [UIImage imageWithData:image];
//        imageView.image = img;
//
//    });
    
    //real
    [self.decoder decodeH264Data:image];
    
//    [self.decodeH264Stream decode:image];
}

- (void) dispatchs:(uint8_t) data{
    NSMutableData *valData = [[NSMutableData alloc] init];
    
    unsigned char valChar[1];
    valChar[0] = 0xff & data;
    [valData appendBytes:valChar length:1];
    
    NSData* image = [self dataWithReverse:valData];
    
    [self performSelectorOnMainThread:@selector(displayImage:) withObject:image waitUntilDone:YES];
}

-(void) dispatch:(UIImage*) image{
    [self performSelectorOnMainThread:@selector(displayImage:) withObject:image waitUntilDone:YES];
}

-(void)displayImage:(UIImage*) image{
//    NSLog(@"%@", image);
    imageView.image = image;
    
}

- (void) dispatchBuff:(CVPixelBufferRef)buff{
    [self dispatchPixelBuffer:buff];
}

//把pixelBuffer包装成samplebuffer送给displayLayer
- (void) dispatchPixelBuffer:(CVPixelBufferRef) pixelBuffer{
    if (!pixelBuffer){
        return;
    }
    @synchronized(self) {
        if (previousPixelBuffer){
            CFRelease(previousPixelBuffer);
            previousPixelBuffer = nil;
        }
        previousPixelBuffer = CFRetain(pixelBuffer);
    }
    
    //不设置具体时间信息
    CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
    //获取视频信息
    CMVideoFormatDescriptionRef videoInfo = NULL;
    OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    NSParameterAssert(result == 0 && videoInfo != NULL);
    
    CMSampleBufferRef sampleBuffer = NULL;
    result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault,pixelBuffer, true, NULL, NULL, videoInfo, &timing, &sampleBuffer);
    NSParameterAssert(result == 0 && sampleBuffer != NULL);
    CFRelease(pixelBuffer);
    CFRelease(videoInfo);
    
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
    [self enqueueSampleBuffer:sampleBuffer toLayer:sampleBufferDisplayLayer];
    CFRelease(sampleBuffer);
}

- (void) enqueueSampleBuffer:(CMSampleBufferRef) sampleBuffer toLayer:(AVSampleBufferDisplayLayer*) layer{
    if (sampleBuffer){
        CFRetain(sampleBuffer);
        [layer enqueueSampleBuffer:sampleBuffer];
        CFRelease(sampleBuffer);
        if (layer.status == AVQueuedSampleBufferRenderingStatusFailed){
            NSLog(@"ERROR: %@", layer.error);
            if (-11847 == layer.error.code){
                [self rebuildSampleBufferDisplayLayer];
            }
        }else{
            //NSLog(@"STATUS: %i", (int)layer.status);
        }
    }else{
        NSLog(@"ignore null samplebuffer");
    }
}


- (void)rebuildSampleBufferDisplayLayer{
    @synchronized(self) {
        [self teardownSampleBufferDisplayLayer];
        [self setupSampleBufferDisplayLayer];
    }
}

- (void)teardownSampleBufferDisplayLayer
{
    if (sampleBufferDisplayLayer){
        [sampleBufferDisplayLayer stopRequestingMediaData];
        [sampleBufferDisplayLayer removeFromSuperlayer];
        sampleBufferDisplayLayer = nil;
    }
}

- (void)setupSampleBufferDisplayLayer{
    if (!sampleBufferDisplayLayer){
        sampleBufferDisplayLayer = [[AVSampleBufferDisplayLayer alloc] init];
        sampleBufferDisplayLayer.frame = self.view.bounds;
        sampleBufferDisplayLayer.position = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
        sampleBufferDisplayLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        sampleBufferDisplayLayer.opaque = YES;
        [self.view.layer addSublayer:sampleBufferDisplayLayer];
    }else{
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        sampleBufferDisplayLayer.frame = self.view.bounds;
        sampleBufferDisplayLayer.position = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
        [CATransaction commit];
    }
    [self addObserver];
}


- (void)addObserver{
    if (!hasAddObserver){
        NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver: self selector:@selector(didResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        [notificationCenter addObserver: self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        hasAddObserver = YES;
    }
}

- (NSData *)dataWithReverse:(NSData *)srcData{
    NSUInteger byteCount = srcData.length;
    NSMutableData *dstData = [[NSMutableData alloc] initWithData:srcData];
    NSUInteger halfLength = byteCount / 2;
    for (NSUInteger i=0; i<halfLength; i++) {
        NSRange begin = NSMakeRange(i, 1);
        NSRange end = NSMakeRange(byteCount - i - 1, 1);
        NSData *beginData = [srcData subdataWithRange:begin];
        NSData *endData = [srcData subdataWithRange:end];
        [dstData replaceBytesInRange:begin withBytes:endData.bytes];
        [dstData replaceBytesInRange:end withBytes:beginData.bytes];
    }
    
    return dstData;
}

-(void) play:(UITapGestureRecognizer *)recognizer{
    [NSThread detachNewThreadSelector:@selector(startdecode) toTarget:self withObject:nil];
}

- (void) startdecode{
    NSLog(@"start");

    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSLog(bundlePath);
    NSString *FilePath = [bundlePath stringByAppendingPathComponent: @"320x240.264"];
    NSLog(FilePath);
    FILE *_imgFileHandle =NULL;
    
    _imgFileHandle =fopen([FilePath UTF8String],"rb");
    
    if (_imgFileHandle != NULL)
    {
        NSLog(@"File Exist");
        X264_H handle = VideoDecoder_Init();
        int iTemp=0;
        int nalLen;
        int bytesRead = 0;
        int NalBufUsed=0;
        int SockBufUsed=0;
        
        bool bFirst=true;
        bool bFindPPS=true;
        
        char  SockBuf[2048];
        char  NalBuf[40980]; // 40k
        char  buffOut[115200];
        char  rgbBuffer[230400];
        int outSize, nWidth, nHeight;
        outSize = 115200;
        memset(SockBuf,0,2048);
        memset(buffOut,0,115200);
        InitConvtTbl();
        do {
            bytesRead = fread(SockBuf, 1, 2048, _imgFileHandle);
            NSLog(@"bytesRead  = %d", bytesRead);
            if (bytesRead<=0) {
                break;
            }
            SockBufUsed = 0;
            while (bytesRead - SockBufUsed > 0) {
                nalLen = MergeBuffer(NalBuf, NalBufUsed, SockBuf, SockBufUsed, bytesRead-SockBufUsed);
                NalBufUsed += nalLen;
                SockBufUsed += nalLen;
                
                while(mTrans == 1)
                {
                    mTrans = 0xFFFFFFFF;
                    
                    if(bFirst==true) // the first start flag
                    {
                        bFirst = false;
                    }
                    else  // a complete NAL data, include 0x00000001 trail.
                    {
                        if(bFindPPS==true) // true
                        {
                            if( (NalBuf[4]&0x1F) == 7 )
                            {
                                bFindPPS = false;
                            }
                            else
                            {
                                NalBuf[0]=0;
                                NalBuf[1]=0;
                                NalBuf[2]=0;
                                NalBuf[3]=1;
                                
                                NalBufUsed=4;
                                
                                break;
                            }
                        }
                        
                        //    decode nal
                        iTemp = VideoDecoder_Decode(handle, NalBuf, NalBufUsed, buffOut,  outSize, &nWidth, &nHeight);
                        if(iTemp == 0)
                        {
                            i420_to_rgb24(buffOut, rgbBuffer, nWidth, nHeight);
                            flip(rgbBuffer, nWidth, nHeight);
                            [self decodeAndShow:rgbBuffer length:nWidth*nHeight*3 nWidth:nWidth nHeight:nHeight];
                            //nFrameCount++;
                        }
                        else
                        {
                            //Log.e("DecoderNal", "DecoderNal iTemp <= 0");
                        }
                        
                        //if(iTemp>0)
                        //postInvalidate();  //使用postInvalidate可以直接在线程中更新界面    // postInvalidate();
                    }
                    
                    NalBuf[0]=0;
                    NalBuf[1]=0;
                    NalBuf[2]=0;
                    NalBuf[3]=1;
                    
                    NalBufUsed=4;
                }
            }
            
            //int nRet = VideoDecoder_Decode(handle, buff, nReadBytes, buffOut,  outSize, &nWidth, &nHeight);
            NSLog(@"nDecodeRet = %d  nWidth = %d  nHeight = %d", iTemp, nWidth, nHeight);
        } while (bytesRead>0);
        
        fclose(_imgFileHandle);
        
    }
}

int MergeBuffer(char* NalBuf, int NalBufUsed, char* SockBuf, int SockBufUsed, int SockRemain){//把读取的数剧分割成NAL块
    int  i=0;
    char Temp;
    
    for(i=0; i<SockRemain; i++)
    {
        Temp  =SockBuf[i+SockBufUsed];
        NalBuf[i+NalBufUsed]=Temp;
        
        mTrans <<= 8;
        mTrans  |= Temp;
        
        if(mTrans == 1) // 找到一个开始字
        {
            i++;
            break;
        }
    }
    
    return i;
}

-(void)decodeAndShow : (char*) pFrameRGB length:(int)len nWidth:(int)nWidth nHeight:(int)nHeight
{
    
    
    //NSLog(@"decode ret = %d readLen = %d\n", ret, nFrameLen);
    if(len > 0)
    {
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
        CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pFrameRGB, nWidth*nHeight*3,kCFAllocatorNull);
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        CGImageRef cgImage = CGImageCreate(nWidth,
                                           nHeight,
                                           8,
                                           24,
                                           nWidth*3,
                                           colorSpace,
                                           bitmapInfo,
                                           provider,
                                           NULL,
                                           YES,
                                           kCGRenderingIntentDefault);
        CGColorSpaceRelease(colorSpace);
        //UIImage *image = [UIImage imageWithCGImage:cgImage];
        UIImage* image = [[UIImage alloc]initWithCGImage:cgImage];   //crespo modify 20111020
        CGImageRelease(cgImage);
        CGDataProviderRelease(provider);
        CFRelease(data);
        [self performSelectorOnMainThread:@selector(updateView:) withObject:image waitUntilDone:YES];
        //[image release];
    }
    
    return;
}

-(void)updateView:(UIImage*)newImage{
    NSLog(@"显示新画面");
    imageView.image = newImage;
}

void flip(char *pRGBBuffer, int nWidth, int nHeight){
    char temp[nWidth*3];
    for (int i = 0; i<nHeight/2; i++) {
        memcpy(temp, pRGBBuffer + i*nWidth*3, nWidth*3);
        memcpy(pRGBBuffer + i*nWidth*3, pRGBBuffer + (nHeight - i - 1)*nWidth*3, nWidth*3);
        memcpy(pRGBBuffer + (nHeight - i - 1)*nWidth*3, temp, nWidth*3);
    }
    /*
     for (int i = 0; i<nHeight/2; i++) {
     memcpy(temp, pRGBBuffer + i*nWidth + nWidth*nHeight, nWidth);
     memcpy(pRGBBuffer + i*nWidth + nWidth*nHeight, pRGBBuffer + (nHeight - i - 1)*nWidth + nWidth*nHeight, nWidth);
     memcpy(pRGBBuffer + (nHeight - i - 1)*nWidth + nWidth*nHeight, temp, nWidth);
     }
     for (int i = 0; i<nHeight/2; i++) {
     memcpy(temp, pRGBBuffer + i*nWidth + nWidth*nHeight*2, nWidth);
     memcpy(pRGBBuffer + i*nWidth + nWidth*nHeight*2, pRGBBuffer + (nHeight - i - 1)*nWidth + nWidth*nHeight*2, nWidth);
     memcpy(pRGBBuffer + (nHeight - i - 1)*nWidth + nWidth*nHeight*2, temp, nWidth);
     }
     */
    
}

-(void) playh264:(UITapGestureRecognizer *)recognizer{
    NSLog(@"playh264");
    
}

@end

