//
//  DetectorPlayer.m
//  DetectorSample
//
//  Created by conwin on 2018/12/21.
//  Copyright © 2018年 luoyingxing. All rights reserved.
//

#import "DetectorDecoder.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <libavcodec/avcodec.h>
#import <libswscale/swscale.h>
#import <libavutil/pixdesc.h>
#import <libavutil/imgutils.h>

@implementation DetectorDecoder{
     CVPixelBufferPoolRef *pixelBufferPool;
     AVCodec *codec;
     AVCodecParserContext *codecParser;
     AVCodecContext *codecContext;
     AVFrame *frame;
     AVPacket *packet;
     struct SwsContext *swsContext;
    
     uint8_t *pictureData[4];
     int pictureLineSize[4];
}

-(void) setDetectorPlayDelegate:(id)delegate{
    detectorPlayDelegate = delegate;
}

- (void) onPrepared:(NSInteger)frame{
    if ([detectorPlayDelegate respondsToSelector:@selector(onPrepared:)]) {
        [detectorPlayDelegate onPrepared:frame];
    }
}

- (void)initializeDecoder {
    avcodec_register_all();
    packet = av_packet_alloc();
    if (!packet) {
        NSLog(@"初始化解码器失败");
    }
    
    codec = avcodec_find_decoder(AV_CODEC_ID_H264);
    if (!codec) {
        NSLog(@"初始化解码器失败");
    }
    
    char *codecName = codec->name;
    NSLog(@"codecName： %s", codecName);
    
    codecParser = av_parser_init(codec->id);
    if (!codecParser) {
        NSLog(@"初始化解码器失败");
    }
    
    codecContext = avcodec_alloc_context3(codec);
    if (!codecContext) {
        NSLog(@"初始化解码器失败");
    }
    
    if (avcodec_open2(codecContext, codec, NULL) < 0) {
        NSLog(@"初始化解码器失败");
    }
    
    frame = av_frame_alloc();
    if (!frame) {
        NSLog(@"初始化解码器失败");
    }
}

- (void) destroyDecoder{
//    free(pixelBufferPool);
//    av_free(codec);
//    av_free(codecParser);
//    av_free(codecContext);
//    av_free(frame);
//    av_free(swsContext);
//
//    av_freep(codec);
//    av_freep(codecParser);
//    av_freep(codecContext);
//    av_freep(frame);
//    av_freep(swsContext);
}

- (void)decodeH264Data:(NSData *)data {
    NSMutableData *tempData = [[NSMutableData alloc] initWithData:data];
    while (tempData.length > 0) {
        int len = av_parser_parse2(codecParser, codecContext, &packet->data, &packet->size, tempData.bytes, (int)tempData.length, AV_NOPTS_VALUE, AV_NOPTS_VALUE, 0);
        if (len < 0) {
            NSLog(@"解码失败");
            return;
        }
        
        NSMutableData *subData = [[NSMutableData alloc] initWithData:[tempData subdataWithRange:NSMakeRange(len, tempData.length - len)]];
        tempData = subData;
        
        if (packet->size) {
            NSLog(@"解码:%d", packet->size);
            [self decodeCodecContext:codecContext frame:frame packet:packet];
        }
    }
}

- (void)decodeCodecContext:(AVCodecContext *)decCtx frame:(AVFrame *)fae packet:(AVPacket *)pkt {
    int ret = avcodec_send_packet(decCtx, pkt);
    if (ret < 0) {
        NSLog(@"解码失败");
        return;
    }
    while (ret >= 0) {
        ret = avcodec_receive_frame(decCtx, fae);
        if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) {
            return;
        } else if (ret < 0) {
            NSLog(@"解码失败");
            return;
        }
        
        int frameHeight = fae->height;
        int frameWidth = fae->width;
        int channels = 3;
        
        //反转图像
        //        fae->data[0] += fae->linesize[0] * (frameHeight - 1);
        //        fae->linesize[0] *= -1;
        //        fae->data[1] += fae->linesize[1] * (frameHeight / 2 - 1);
        //        fae->linesize[1] *= -1;
        //        fae->data[2] += fae->linesize[2] * (frameHeight / 2 - 1);
        //        fae->linesize[2] *= -1;
        
        //创建保存yuv数据的buffer
        unsigned char* pDecodedBuffer = (unsigned char*)malloc(frameHeight*frameWidth * sizeof(unsigned char)*channels);
        
        //从AVFrame中获取yuv420p数据，并保存到buffer
        int i, j, k;
        //拷贝y分量
        for (i = 0; i < frameHeight; i++){
            memcpy(pDecodedBuffer + frameWidth*i, fae->data[0] + fae->linesize[0] * i, frameWidth);
        }
        //拷贝u分量
        for (j = 0; j < frameHeight / 2; j++) {
            memcpy(pDecodedBuffer + frameWidth*i + frameWidth / 2 * j, fae->data[1] + fae->linesize[1] * j, frameWidth / 2);
        }
        //拷贝v分量
        for (k = 0; k < frameHeight / 2; k++){
            memcpy(pDecodedBuffer + frameWidth*i + frameWidth / 2 * j + frameWidth / 2 * k, fae->data[2] + fae->linesize[2] * k, frameWidth / 2);
        }
        
        [self.detectorPlayView displayYUV420pData:pDecodedBuffer width:frameWidth height:frameHeight];
        
        free(pDecodedBuffer);
        
        //        NSData *imageData = UIImagePNGRepresentation(image);
        // NSLog(@"imageData size:%lld", imageData.length);
        
        /////
        //        NSString *filenameString = [NSString stringWithFormat:@"image%d.jpg", decCtx->frame_number];
        //        NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        //        NSString *filePathOutput = [documentPath stringByAppendingPathComponent:filenameString];
        //
        //        BOOL succeed = [imageData writeToFile:filePathOutput atomically:YES];
        //        NSLog(@"save succeed: %d", succeed);
    }
}

@end
