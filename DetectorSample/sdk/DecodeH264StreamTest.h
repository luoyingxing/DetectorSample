//
//  DecodeH264Stream.h
//  DetectorSample
//
//  Created by conwin on 2018/12/19.
//  Copyright © 2018年 luoyingxing. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "libswscale/swscale.h"
#import "libavcodec/avcodec.h"
#import "libavutil/opt.h"
#import "libavutil/channel_layout.h"
#import "libavutil/common.h"
#import "libavutil/imgutils.h"
#import "libavutil/mathematics.h"
#import "libavutil/samplefmt.h"
#import "ResponseDelegate.h"

@interface DecodeH264StreamTest : NSObject{
    id<ResponseDelegate> responseDelegate;
}

- (void)initialize;

- (void)decode:(NSData *)data;

- (void)destroy;

- (void)setResponseDelegate:(id)inDelegate;

@end
