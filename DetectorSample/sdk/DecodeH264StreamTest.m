//
//  DecodeH264Stream.m
//  DetectorSample
//
//  Created by conwin on 2018/12/19.
//  Copyright © 2018年 luoyingxing. All rights reserved.
//

//
// DetSDKJni
//
// Created by luoyingxing on 2018/10/08.
//

#import "DecodeH264StreamTest.h"

#define INBUF_SIZE 80 * 1024


typedef struct _VoutInfo {
    /**
     WINDOW_FORMAT_RGBA_8888          = 1,
     WINDOW_FORMAT_RGBX_8888          = 2,
     WINDOW_FORMAT_RGB_565            = 4,*/
    uint32_t pix_format;
    
    uint32_t buffer_width;
    uint32_t buffer_height;
    uint8_t *buffer;
} VoutInfo;

typedef struct _NalInfo {
    uint8_t forbidden_zero_bit;
    uint8_t nal_ref_idc;
    uint8_t nal_unit_type;
} NalInfo;

typedef struct _RenderParam {
    struct SwsContext *swsContext;
    AVCodecContext *avCodecContext;
} RenderParam;

enum {
    PIXEL_FORMAT_RGBA_8888 = 1,
    PIXEL_FORMAT_RGBX_8888 = 2,
    PIXEL_FORMAT_RGB_565 = 3
};

typedef struct _VoutRender {
    uint32_t pix_format;
    uint32_t window_format;
} VoutRender;

uint8_t inbuf[INBUF_SIZE + FF_INPUT_BUFFER_PADDING_SIZE];
AVPacket avpkt;
RenderParam *renderParam;
AVCodec *codec;
AVCodecContext *codecContext;
AVFrame *frame;
AVCodecParserContext *parser;
int frame_count;
struct SwsContext *img_convert_ctx;
AVFrame *pFrameRGB;
enum AVPixelFormat pixelFormat;
int native_pix_format = PIXEL_FORMAT_RGB_565;

static DecodeH264StreamTest *selfClass =nil;

@implementation DecodeH264StreamTest

- (void)initialize{
    selfClass = self;
    
    /* register all the codecs */
    avcodec_register_all();
    av_init_packet(&avpkt);
    
    renderParam = NULL;
    
    /* set end of buffer to 0 (this ensures that no overreading happens for damaged mpeg streams) */
    memset(inbuf, 0, INBUF_SIZE);
    
    memset(inbuf + INBUF_SIZE, 0, FF_INPUT_BUFFER_PADDING_SIZE);
    
    /* find the x264 video decoder */
    codec = avcodec_find_decoder(AV_CODEC_ID_H264);
    if (!codec) {
        return;
    }
    
    codecContext = avcodec_alloc_context3(codec);
    if (!codecContext) {
        return;
    }
    
    if (codec->capabilities & CODEC_CAP_TRUNCATED) {
        codecContext->flags |= CODEC_FLAG_TRUNCATED;
    }
    
    /* open it */
    if (avcodec_open2(codecContext, codec, NULL) < 0) {
        return;
    }
    
    frame = av_frame_alloc();
    if (!frame) {
        return;
    }
    
    parser = av_parser_init(AV_CODEC_ID_H264);
    if (!parser) {
        return;
    }

    frame_count = 0;
    img_convert_ctx = NULL;
    pFrameRGB = NULL;
    
    pixelFormat = AV_PIX_FMT_RGB565LE;
}

- (void)decode:(NSData *)data{
    decodeFrame(data.bytes, (int)data.length);
}

- (void)destroy{
    
}

-(void) setResponseDelegate:(id)inDelegate{
    responseDelegate = inDelegate;
}

- (void) dispatch:(uint8_t)data{
    if ([responseDelegate respondsToSelector:@selector(dispatchs:)]) {
        [responseDelegate dispatchs:data];
    }
}

void dispatch(AVFrame *rgbFrame){
    [selfClass dispatch:*rgbFrame->data[0]];
}

AVFrame* yuv420p_2_argb(AVFrame *frame, struct SwsContext *swsContext, AVCodecContext *avCodecContext,
                        enum AVPixelFormat format) {
    AVFrame *pFrameRGB = NULL;
    uint8_t *out_bufferRGB = NULL;
    pFrameRGB = av_frame_alloc();
    
    pFrameRGB->width = frame->width;
    pFrameRGB->height = frame->height;
    
    //给pFrameRGB帧加上分配的内存;  //AV_PIX_FMT_ARGB
    int size = avpicture_get_size(format, avCodecContext->width, avCodecContext->height);
    //out_bufferRGB = new uint8_t[size];
    out_bufferRGB = av_malloc(size * sizeof(uint8_t));
    avpicture_fill((AVPicture *) pFrameRGB, out_bufferRGB, format, avCodecContext->width,
                   avCodecContext->height);
    //YUV to RGB
    sws_scale(swsContext, frame->data, frame->linesize, 0, avCodecContext->height, pFrameRGB->data,
              pFrameRGB->linesize);
    
    return pFrameRGB;
}

void handle_data(AVFrame *pFrame, void *param) {
    RenderParam *renderParam = (RenderParam *) param;
    
    AVFrame *rgbFrame = yuv420p_2_argb(pFrame, renderParam->swsContext, renderParam->avCodecContext, pixelFormat);//AV_PIX_FMT_RGB565LE
    
    dispatch(rgbFrame);
    
    //        if (request_capture == 1) {
    //            request_capture = 0;
    //            onCapture(rgbFrame);
    //        }
    
    //        EnvPackage *envPackage = (EnvPackage *) ctx;
    //        ANativeWindow *aNativeWindow = ANativeWindow_fromSurface(envPackage->env,
    //                                                                 *(envPackage->surface));
    //
    //        VoutInfo voutInfo;
    //        voutInfo.buffer = rgbFrame->data[0];
    //        voutInfo.buffer_width = rgbFrame->width;
    //        voutInfo.buffer_height = rgbFrame->height;
    //        voutInfo.pix_format = native_pix_format;
    //
    //        android_native_window_display(aNativeWindow, &voutInfo);
    //
    //        ANativeWindow_release(aNativeWindow);
    
    av_free(rgbFrame->data[0]);
    av_free(rgbFrame);
}

int handleH264Header(uint8_t *ptr, NalInfo *nalInfo) {
    int startIndex = 0;
    uint32_t *checkPtr = (uint32_t *) ptr;
    if (*checkPtr == 0x01000000) {  // 00 00 00 01
        startIndex = 4;
    } else if (*(checkPtr) == 0 && *(checkPtr + 1) & 0x01000000) {  // 00 00 00 00 01
        startIndex = 5;
    }
    
    if (!startIndex) {
        return -1;
    } else {
        ptr = ptr + startIndex;
        nalInfo->nal_unit_type = 0x1f & *ptr;
        if (nalInfo->nal_unit_type == 5 || nalInfo->nal_unit_type == 7 ||
            nalInfo->nal_unit_type == 8 || nalInfo->nal_unit_type == 2) {  //I frame
            //            LOGD("I frame");
        } else if (nalInfo->nal_unit_type == 1) {
            //            LOGD("P frame");
        }
    }
    return 0;
}

int decodeFrame(const char *data, int length) {
    int cur_size = length;
    int ret = 0;
    
    NSLog(@"======== %d / %d", length, sizeof(inbuf) );
    memcpy(inbuf, data, length);
    const uint8_t *cur_ptr = inbuf;
    
    while (cur_size > 0) {
        int parsedLength = av_parser_parse2(parser, codecContext, &avpkt.data,&avpkt.size, (const uint8_t *) cur_ptr, cur_size,
                                            AV_NOPTS_VALUE, AV_NOPTS_VALUE, AV_NOPTS_VALUE);
        cur_ptr += parsedLength;
        cur_size -= parsedLength;
        
        NalInfo nalInfo;
        ret = handleH264Header(cur_ptr - parsedLength, &nalInfo);
        if (ret == 0) {}
        
        if (!avpkt.size) {
            continue;
        } else {
            
            int len, got_frame;
            len = avcodec_decode_video2(codecContext, frame, &got_frame, &avpkt);
            
            if (len < 0) {
                continue;
            }
            
            if (got_frame) {
                frame_count++;
                
                
                if (img_convert_ctx == NULL) {
                    img_convert_ctx = sws_getContext(codecContext->width, codecContext->height,
                                                     codecContext->pix_fmt, codecContext->width,
                                                     codecContext->height,
                                                     pixelFormat, SWS_BICUBIC, NULL, NULL, NULL);
                    
                    renderParam = (RenderParam *) malloc(sizeof(RenderParam));
                    renderParam->swsContext = img_convert_ctx;
                    renderParam->avCodecContext = codecContext;
                }
                
                if (img_convert_ctx != NULL) {
                    handle_data(frame, renderParam);
                }
            }
        }
    }
    
    return length;
}

void decodeStream(char *cdata, int length) {
    if (cdata != NULL) {
        int len = 0;
        while (1) {
            if (length > INBUF_SIZE) {
                len = INBUF_SIZE;
                length -= INBUF_SIZE;
                
            } else if (length > 0 && length <= INBUF_SIZE) {
                len = length;
                length = 0;
            } else {
                break;
            }
            
            decodeFrame(cdata, len);
            cdata = cdata + len;
            
        }
    } else {
        // stream data is NULL
    }
    
    free(cdata);
}

@end


