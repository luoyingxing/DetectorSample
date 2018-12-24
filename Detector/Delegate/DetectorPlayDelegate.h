//
//  DetectorPlayDelegate.h
//  DetectorSample
//
//  Created by conwin on 2018/12/21.
//  Copyright © 2018年 luoyingxing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol DetectorPlayDelegate <NSObject>

//这个可以是required，也可以是optional
@required

- (void)onPrepared:(NSInteger) frame;

//播放完成
- (void)onComplete;

//播放出错
- (void)onError:(NSString*)info;

@end
