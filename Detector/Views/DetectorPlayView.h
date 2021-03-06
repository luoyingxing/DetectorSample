//
//  DetectorPlayView.h
//  DetectorSample
//
//  Created by conwin on 2018/12/21.
//  Copyright © 2018年 luoyingxing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGL.h>
#include <sys/time.h>

@interface DetectorPlayView : UIView{
    /**
     OpenGL绘图上下文
     */
    EAGLContext *_glContext;
    
    /**
     帧缓冲区
     */
    GLuint _framebuffer;
    
    /**
     渲染缓冲区
     */
    GLuint _renderBuffer;
    
    /**
     着色器句柄
     */
    GLuint _program;
    
    /**
     YUV纹理数组
     */
    GLuint _textureYUV[3];
    
    /**
     视频宽度
     */
    GLuint _videoW;
    
    /**
     视频高度
     */
    GLuint _videoH;
    
    GLsizei _viewScale;
    
    //void *_pYuvData;
    
#ifdef DEBUG
    struct timeval      _time;
    NSInteger           _frameRate;
#endif
}

# pragma mark - 接口
//设置视频尺寸
- (void)setVideoSize:(GLuint)width height:(GLuint)height;

//显示yuv420p数据，传入相应的视频尺寸
- (void)displayYUV420pData:(void *)data width:(NSInteger)w height:(NSInteger)h;

//清除画面
- (void)clearFrame;

@end
