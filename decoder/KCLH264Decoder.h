//
//  KCLH264Decoder.h
//  FFmpegH264Decoder
//
//  Created by Chentao on 2017/11/27.
//  Copyright © 2017年 Chentao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseDelegate.h"
#import "OpenGLView20.h"

@interface KCLH264Decoder : NSObject{
    id<ResponseDelegate> responseDelegate;
}

@property (nonatomic, strong) OpenGLView20 *openGLView20;

- (void)initializeDecoder;

- (void)decodeH264Data:(NSData *)data;

- (void)destroyDecoder;

- (void)setResponseDelegate:(id)inDelegate;

@end
