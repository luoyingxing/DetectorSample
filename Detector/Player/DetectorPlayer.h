//
//  DetectorPlayer.h
//  DetectorSample
//
//  Created by conwin on 2018/12/21.
//  Copyright © 2018年 luoyingxing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DetectorPlayView.h"
#import "DetectorPlayDelegate.h"
#import "DetectorDecoder.h"

@interface DetectorPlayer : NSObject{
    //播放监听回调
    id<DetectorPlayDelegate> detectorPlayDelegate;
}

//存储服务器地址(http://ip:port)
@property (nonatomic, strong) NSString *server;

//播放实时视频的窗口view
@property (nonatomic, strong) DetectorPlayView *realDetectorPlayView;

//解码器
@property (nonatomic, strong) DetectorDecoder *detectorDecoder;

//设置播放监听回调
- (void)setDetectorPlayDelegate:(id)delegate;

//初始化播放资源
- (void)initPlayer:(NSString*) server;

//请求播放实时视频
- (void)playReal:(DetectorPlayView*)view tid:(NSString*)tid channel:(NSInteger)channel;

//停止播放实时视频
- (void)stopReal;

//释放资源
- (void)releaseMemory;

@end
