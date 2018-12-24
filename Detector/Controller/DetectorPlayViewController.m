//
//  DetectorPlayViewController.m
//  DetectorSample
//
//  Created by conwin on 2018/12/21.
//  Copyright © 2018年 luoyingxing. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "DetectorPlayViewController.h"
#import "DetectorPlayView.h"
#import "DetectorDecoder.h"
#import "DetectorPlayDelegate.h"
#import "DetectorPlayer.h"

#define screenWidth [UIScreen mainScreen].bounds.size.width
#define screenHeight [UIScreen mainScreen].bounds.size.height

@interface DetectorPlayViewController ()<DetectorPlayDelegate>{
    DetectorPlayView *detectorPlayView;
}

@property (nonatomic, strong) DetectorPlayer *detectorPlayer;

@end

@implementation DetectorPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initBaseBar];
    [self initPlayView];
}

- (void) initBaseBar{
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.navigationController.navigationBar.barStyle = UIStatusBarStyleLightContent;
    [self setNeedsStatusBarAppearanceUpdate];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor orangeColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18],
                                                                      NSForegroundColorAttributeName:[UIColor whiteColor]}];
    self.title = @"视频探测器";
    UIButton* backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 80, 44)];
    backButton.titleLabel.font = [UIFont systemFontOfSize:16.0f];
    backButton.adjustsImageWhenHighlighted = NO;
    [backButton setImage:[UIImage imageNamed:@"ic_bar_back.png"] forState:UIControlStateNormal];
    [backButton setTitle:@"返回" forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    backButton.contentHorizontalAlignment =UIControlContentHorizontalAlignmentLeft;
    backButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
}

- (void) initPlayView{
    detectorPlayView = [[DetectorPlayView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenWidth * 9 / 16)];
    [detectorPlayView setVideoSize:screenWidth height:screenWidth * 9 / 16];
    [self.view addSubview:detectorPlayView];
    
    self.detectorPlayer = [[DetectorPlayer alloc] init];
    [self.detectorPlayer initPlayer:@"http://116.204.67.11:17001"];
    [self.detectorPlayer setDetectorPlayDelegate:self];
}

- (void) viewDidAppear:(BOOL)animated{
    [self.detectorPlayer playReal:detectorPlayView tid:@"COWN-3B1-UY-4WS" channel:1];
}

- (void) back:(id)sender{
    [self.detectorPlayer stopReal];
    [self dismissViewControllerAnimated:TRUE completion:^{
        NSLog(@"go back");
    }];
}

- (void) viewDidDisappear:(BOOL)animated{
    [self.detectorPlayer releaseMemory];
}

# pragma mark - DetectorPlayDelegate
- (void)onComplete{
    NSLog(@"onComplete");
}

- (void)onError:(NSString *)info{
    NSLog(@"onError:%@", info);
}

@end
