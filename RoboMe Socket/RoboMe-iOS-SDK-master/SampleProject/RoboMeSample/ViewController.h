//
//  ViewController.h
//  RoboMeBasicSample
//
//  Copyright (c) 2013 WowWee Group Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RoboMe/RoboMe.h>
//#import <RMCharacter/RMCharacter.h>
#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import <opencv2/imgproc/imgproc_c.h>

#import <UIKit/UINavigationController.h>

@interface ViewController : UIViewController <RoboMeDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession *_session;
    AVCaptureDevice *_captureDevice;
    
    BOOL _useBackCamera;
    
}

//@property (nonatomic, strong) RMCharacter *Romo;

//@property (weak, nonatomic) IBOutlet UITextView *outputTextView;
//
//@property (weak, nonatomic) IBOutlet UILabel *edgeLabel;
//@property (weak, nonatomic) IBOutlet UILabel *chest20cmLabel;
//@property (weak, nonatomic) IBOutlet UILabel *chest50cmLabel;
//@property (weak, nonatomic) IBOutlet UILabel *cheat100cmLabel;



//- (void)addGestureRecognizers;


- (UIImage*)getUIImageFromIplImage:(IplImage *)iplImage;
- (void)didCaptureIplImage:(IplImage *)iplImage;
- (void)didFinishProcessingImage:(IplImage *)iplImage;

@end
