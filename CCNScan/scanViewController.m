//
//  scanViewController.m
//  CCNScan
//
//  Created by zcc on 16/4/14.
//  Copyright © 2016年 CCN. All rights reserved.
//

#import "scanViewController.h"
#import "resultViewController.h"
#import <AVFoundation/AVFoundation.h>


@interface scanViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate,AVCaptureMetadataOutputObjectsDelegate>{
    UIImagePickerController *imagePicker;
}

@property ( strong , nonatomic ) AVCaptureDevice * device;
@property ( strong , nonatomic ) AVCaptureDeviceInput * input;
@property ( strong , nonatomic ) AVCaptureMetadataOutput * output;
@property ( strong , nonatomic ) AVCaptureSession * session;
@property ( strong , nonatomic ) AVCaptureVideoPreviewLayer * previewLayer;

@property (nonatomic,assign)BOOL isScanSuccess;

@end

@implementation scanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.modalPresentationCapturesStatusBarAppearance = NO;
    
    UIBarButtonItem *navRightButton = [[UIBarButtonItem alloc]initWithTitle:@"相册" style:UIBarButtonItemStylePlain target:self action:@selector(choicePhoto)];
    self.navigationItem.rightBarButtonItem = navRightButton;
    self.navigationItem.title = @"二维码/条码";
    //劣质扫描框
    [self initBgView];//此处可随意替换UI
    
    //开始扫描
    [self startScan];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear: animated];
    if (_session != nil) {
        [self.session startRunning];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear: animated];
    [self.session stopRunning];
}

- (void)startScan
{
    [self.session addInput:self.input];
    [self.session addOutput:self.output];
    //扫码类型，需要先将输出流添加到捕捉会话后再进行设置
    [self.output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    //设置输出流delegate,在主线程刷新UI
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    //预览层
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    self.previewLayer.frame = self.view.bounds;
    //设置扫描范围 output.rectOfInterest
    
    [self.session startRunning];
    
}

//可重写view的drawrect方法直接画，这里因为懒，所以直接从古早项目中粘贴过来。
- (void)initBgView{
    
    UIView *bgView = [[UIView alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:bgView];
    //基准线
    UIView* line = [[UIView alloc] initWithFrame:CGRectMake(mainWidth/16, mainHeight/2-0.5, mainWidth/8*7, 1)];
    line.backgroundColor = [UIColor redColor];
    [bgView addSubview:line];
    //上部
    UIView* upView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, mainWidth, mainHeight/6)];
    upView.alpha = 0.4;
    upView.backgroundColor = [UIColor blackColor];
    [bgView addSubview:upView];
    //说明
    UILabel * labIntroudction= [[UILabel alloc] init];
    labIntroudction.backgroundColor = [UIColor clearColor];
    labIntroudction.frame=CGRectMake(mainWidth/20, mainHeight/24, mainWidth/10*9, 50);
    labIntroudction.numberOfLines=2;
    labIntroudction.textColor=[UIColor whiteColor];
    labIntroudction.text=@"将二维码置于矩形方框内，离手机摄像头10CM左右，系统会自动识别。";
    [upView addSubview:labIntroudction];
    //左侧
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, mainHeight/6, mainWidth/16, mainHeight/12*7)];
    leftView.alpha = 0.4;
    leftView.backgroundColor = [UIColor blackColor];
    [bgView addSubview:leftView];
    //右侧
    UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(mainWidth/16*15, mainHeight/6, mainWidth/16, mainHeight/12*7)];
    rightView.alpha = 0.4;
    rightView.backgroundColor = [UIColor blackColor];
    [bgView addSubview:rightView];
    //底部
    UIView * downView = [[UIView alloc] initWithFrame:CGRectMake(0, mainHeight/4*3, mainWidth, mainHeight/4)];
    downView.alpha = 0.4;
    downView.backgroundColor = [UIColor blackColor];
    [bgView addSubview:downView];
}

//扫码回调
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (!_isScanSuccess){
        NSString *content = @"";
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects.firstObject;
        content = metadataObject.stringValue;
        
        if (![content isEqualToString:@""]) {
            //震动
            [self playBeep];
            _isScanSuccess = YES;
            
            resultViewController *result = [[resultViewController alloc]init];
            result.content = content;
            [self.navigationController pushViewController:result animated:NO];
        }else{
            NSLog(@"没内容");
        }

    }
}

#pragma mark - 从相册识别二维码
- (void)choicePhoto{
    imagePicker = [[UIImagePickerController alloc]init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

//音效震动
- (void)playBeep
{
    SystemSoundID soundID;
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"滴-2"ofType:@"mp3"]], &soundID);
    
    AudioServicesPlaySystemSound(soundID);
    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

#pragma mark - ImagePickerDelegate
-(void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *content = @"" ;
    //取出选中的图片
    UIImage *pickImage = info[UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImagePNGRepresentation(pickImage);
    CIImage *ciImage = [CIImage imageWithData:imageData];
    
    //创建探测器
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyLow}];
    NSArray *feature = [detector featuresInImage:ciImage];
    
    //取出探测到的数据
    for (CIQRCodeFeature *result in feature) {
        content = result.messageString;
    }
    __weak typeof(self) weakSelf = self;
    //选中图片后先返回扫描页面，然后跳转到新页面进行展示
    [picker dismissViewControllerAnimated:NO completion:^{
      
        if (![content isEqualToString:@""]) {
            //震动
            [weakSelf playBeep];
            resultViewController *result = [[resultViewController alloc]init];
            result.content = content;
            [weakSelf.navigationController pushViewController:result animated:NO];
        }else{
            NSLog(@"没扫到东西");
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (AVCaptureDevice *)device
{
    if (_device == nil) {
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return _device;
}

- (AVCaptureDeviceInput *)input
{
    if (_input == nil) {
        _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    }
    return _input;
}

- (AVCaptureSession *)session
{
    if (_session == nil) {
        _session = [[AVCaptureSession alloc] init];
    }
    return _session;
}

- (AVCaptureVideoPreviewLayer *)previewLayer
{
    if (_previewLayer == nil) {
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    }
    return _previewLayer;
}

- (AVCaptureMetadataOutput *)output
{
    if (_output == nil) {
        _output = [[AVCaptureMetadataOutput alloc] init];
    }
    return _output;
}



@end
