//
//  ViewController.m
//  NSURLSessionDemo
//
//  Created by Lonely Stone on 16/3/14.
//  Copyright © 2016年 LonelyStone. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<NSURLSessionDataDelegate,NSURLSessionDelegate,NSURLSessionTaskDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSMutableData *buffer;
@property (nonatomic) float expectLength;

@end

static NSString *urlStr = @"http://f12.topit.me/o129/10129120625790e866.jpg";

@implementation ViewController

- (NSMutableData*)buffer{
    if (!_buffer) {
        _buffer = [NSMutableData data];
    }
    return _buffer;
}

- (NSURLSession*)session {
    if (!_session) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

- (NSURLSessionDataTask*)dataTask {
    if (!_dataTask) {
        _dataTask = [self.session dataTaskWithURL:[NSURL URLWithString:urlStr]];
    }
    return _dataTask;
}

#pragma mark - cancelButtonAction
- (IBAction)cancelButtonAction:(id)sender {
    /*
     NSURLSessionTaskStateRunning    正在请求
     NSURLSessionTaskStateSuspended  延缓
     NSURLSessionTaskStateCanceling  取消
    NSURLSessionTaskStateCompleted   完成
     */
    switch (self.dataTask.state) {
        case NSURLSessionTaskStateRunning:
            //正在运行
            break;
        case NSURLSessionTaskStateSuspended:
            //挂起状态,只有在cancel状态下才能取消请求
            [self.dataTask cancel];
            break;
        case NSURLSessionTaskStateCompleted:
            //完成状态
            break;
        default:
            break;
    }
}

#pragma mark - resumeButtonAction
- (IBAction)resumeButtonAction:(id)sender {
    if (self.dataTask.state == NSURLSessionTaskStateSuspended) {
        //只有处于挂起状态才能恢复请求
        [self.dataTask resume];
    }
}

#pragma mark - pauseButtonAction
- (IBAction)pauseButtonAction:(id)sender {
    if (self.dataTask.state == NSURLSessionTaskStateRunning) {
        //在运行过程中才能暂停
        [self.dataTask suspend];
    }
}

#pragma mark - sessionDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    
    NSInteger length = [response expectedContentLength];
    if (length != -1) {
        
        self.expectLength = [response expectedContentLength];
        
        //继续传输数据
        completionHandler(NSURLSessionResponseAllow);

    }else{
        //如果response中不包含长度信息选择取消请求
        completionHandler(NSURLSessionResponseCancel);
    }
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    [self.buffer appendData:data];
    //更新进度条
    self.progressView.progress = self.buffer.length / self.expectLength;

    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressLabel.text = [NSString stringWithFormat:@"%.2f",self.buffer.length / self.expectLength];
        self.imageView.image = [UIImage imageWithData:self.buffer];
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if (!error) {
        
        //主线程更新UI
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressLabel.text = @"完成";
            [UIView animateWithDuration:1.0 animations:^{
                self.progressLabel.alpha = 0.0;
            }];
            //隐藏进度条
            self.session = nil;
            self.dataTask = nil;
        });
    }else{
        
        NSDictionary *errorInfo = error.userInfo;
        NSString *errorString ;
        if ([errorInfo[@"NSLocalizedDescription"] isEqualToString:@"cancelled"]) {
            
            errorString = @"请求取消,加载失败!";
        }
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:errorString message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.dataTask resume];
    [self.session finishTasksAndInvalidate];
    
    [self showLocalNotification];
}

- (void)showLocalNotification{
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    NSDate *date = [NSDate date];
    localNotification.timeZone = [NSTimeZone systemTimeZone];
    localNotification.fireDate = [date dateByAddingTimeInterval:10];
    localNotification.repeatInterval = 0; //0默认不重复
    localNotification.alertTitle = @"下载提示";
    localNotification.alertBody = @"恭喜,后台下载完成!";
    localNotification.alertAction = @"打开";
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    NSDictionary *dict = @{@"name":@"liuxin"};
    localNotification.userInfo = dict;
    localNotification.applicationIconBadgeNumber = 1;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
