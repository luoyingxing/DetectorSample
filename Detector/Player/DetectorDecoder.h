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

@interface DetectorDecoder : NSObject{
    id<DetectorPlayDelegate> detectorPlayDelegate;
}

@property (nonatomic, strong) DetectorPlayView *detectorPlayView;

- (void)initializeDecoder;

- (void)destroyDecoder;

- (void)decodeH264Data:(NSData *)data;

- (void)setDetectorPlayDelegate:(id)delegate;

@end
