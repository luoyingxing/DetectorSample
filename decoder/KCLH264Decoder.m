
//
//  KCLH264Decoder.m
//  FFmpegH264Decoder
//
//  Created by Chentao on 2017/11/27.
//  Copyright © 2017年 Chentao. All rights reserved.
//

#import "KCLH264Decoder.h"
#import <libavcodec/avcodec.h>
#import <libswscale/swscale.h>
#import <libavutil/pixdesc.h>
#import <libavutil/imgutils.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>

static AVCodec *codec;
static AVCodecParserContext *codecParser;
static AVCodecContext *codecContext;
static AVFrame *frame;
static AVPacket *packet;
//static int ret;

struct SwsContext *swsContext;

static uint8_t *pictureData[4];
static int pictureLineSize[4];

@implementation KCLH264Decoder {
    CVPixelBufferPoolRef *pixelBufferPool;
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
    NSLog(@"%s",codecName);
    
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
        
        //        UIImage *image = [self convertFrameToImage:fae];
        //         NSLog(@"size:%@", NSStringFromCGSize(image.size));
        
        //        [self dispatch:image];
        
        // ----------
        //        [self dispatchAVFrame:fae];
        
        
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
        
        [_openGLView20 displayYUV420pData:pDecodedBuffer width:frameWidth height:frameHeight];
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

void YUV420PtoNV12(unsigned char *Src, unsigned char* Dst,int Width,int Height){
    unsigned char* SrcU = Src + Width * Height;
    unsigned char* SrcV = SrcU + Width * Height / 4 ;
    unsigned char* DstU = Dst + Width * Height;
    int i = 0;
    for( i = 0 ; i < Width * Height / 4 ; i++ ){
        *(DstU++) = *(SrcU++);
        *(DstU++) = *(SrcV++);
    }
}


- (void)dispatchAVFrame:(AVFrame*) frame{
    if(!frame || !frame->data[0]){
        return;
    }
    
    NSLog(@"frame->format: %d", frame->format);
    
    CVReturn theError;
    if (!pixelBufferPool){
        NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
        [attributes setObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
        [attributes setObject:[NSNumber numberWithInt:frame->width] forKey: (NSString*)kCVPixelBufferWidthKey];
        [attributes setObject:[NSNumber numberWithInt:frame->height] forKey: (NSString*)kCVPixelBufferHeightKey];
        [attributes setObject:@(frame->linesize[0]) forKey:(NSString*)kCVPixelBufferBytesPerRowAlignmentKey];
        [attributes setObject:[NSDictionary dictionary] forKey:(NSString*)kCVPixelBufferIOSurfacePropertiesKey];
        theError = CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (__bridge CFDictionaryRef) attributes, &pixelBufferPool);
        if (theError != kCVReturnSuccess){
            NSLog(@"CVPixelBufferPoolCreate Failed");
        }
    }
    
    CVPixelBufferRef pixelBuffer = nil;
    theError = CVPixelBufferPoolCreatePixelBuffer(NULL, pixelBufferPool, &pixelBuffer);
    if(theError != kCVReturnSuccess){
        NSLog(@"CVPixelBufferPoolCreatePixelBuffer Failed");
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    size_t bytePerRowY = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    size_t bytesPerRowUV = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    void* base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    memcpy(base, frame->data[0], bytePerRowY * frame->height);
    base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    memcpy(base, frame->data[1], bytesPerRowUV * frame->height/2);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    //    [self dispatchPixelBuffer:pixelBuffer];
    
    
    if ([responseDelegate respondsToSelector:@selector(dispatchBuff:)]) {
        [responseDelegate dispatchBuff:pixelBuffer];
    }
}

-(void) setResponseDelegate:(id)inDelegate{
    responseDelegate = inDelegate;
}

- (void) dispatch:(UIImage*)image{
    if ([responseDelegate respondsToSelector:@selector(dispatch:)]) {
        [responseDelegate dispatch:image];
    }
}

- (UIImage *)convertFrameToImage:(AVFrame *)pFrame {
    
    if (pFrame->data[0]) {
        
        int width = pFrame->width;
        int height = pFrame->height;
        
        struct SwsContext *scxt = sws_getContext(width, height, pFrame->format, width, height, AV_PIX_FMT_RGBA, SWS_POINT, NULL, NULL, NULL);
        if (scxt == NULL) {
            return nil;
        }
        int det_bpp = av_get_bits_per_pixel(av_pix_fmt_desc_get(AV_PIX_FMT_RGBA));
        
        //        uint8_t *videoDstData[4];
        //        int videoLineSize[4];
        
        if (pFrame->key_frame) {
            av_image_alloc(pictureData, pictureLineSize, width, height, AV_PIX_FMT_RGBA, 1);
        }
        
        sws_scale(scxt, (const uint8_t **)pFrame->data, pFrame->linesize, 0, height, pictureData, pictureLineSize);
        
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
        CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pictureData[0], pictureLineSize[0] * height, kCFAllocatorNull);
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGImageRef cgImage = CGImageCreate(width, height, 8, det_bpp, pictureLineSize[0], colorSpace, bitmapInfo, provider, NULL, NO, kCGRenderingIntentDefault);
        CGColorSpaceRelease(colorSpace);
        UIImage *image = [UIImage imageWithCGImage:cgImage];
        
        CGImageRelease(cgImage);
        CGDataProviderRelease(provider);
        CFRelease(data);
        
        return image;
    }
    
    return nil;
}


@end

