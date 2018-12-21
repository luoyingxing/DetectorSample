//
//  DetectorPlayer.h
//  DetectorSample
//
//  Created by conwin on 2018/12/21.
//  Copyright © 2018年 luoyingxing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DetectorPlayer.h"
#import "DetectorPlayView.h"
#import "ResponseDelegate.h"

@interface DetectorPlayer : NSObject{
    id<ResponseDelegate> responseDelegate;
}

@property (nonatomic, strong) DetectorPlayView *detectorPlayView;

- (void)initializeDecoder;

- (void)decodeH264Data:(NSData *)data;

- (void)destroyDecoder;

- (void)setResponseDelegate:(id)inDelegate;

@end
