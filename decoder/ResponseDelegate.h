//
//  ResponseDelegate.h
//  FFmpegH264Decoder
//
//  Created by conwin on 2018/12/18.
//  Copyright © 2018年 Chentao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol ResponseDelegate <NSObject>

@required//这个可以是required，也可以是optional

-(void) dispatch:(UIImage*) image;

-(void) dispatchs:(uint8_t) data;

@end
