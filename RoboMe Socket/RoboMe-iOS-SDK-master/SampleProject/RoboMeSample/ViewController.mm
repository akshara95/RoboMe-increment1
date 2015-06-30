//
//  ViewController.m
//  RoboMeBasicSample
//
//  Copyright (c) 2013 WowWee Group Limited. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
#include <ifaddrs.h>
#include <arpa/inet.h>

#import "AFHTTPRequestOperationManager.h"





//opencv framework
#import <opencv2/objdetect/objdetect.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#import "opencv2/opencv.hpp"

using namespace std;

//static const NSTimeInterval accelerometerMin = 0.1;

#define WELCOME_MSG  0
#define ECHO_MSG     1
#define WARNING_MSG  2

#define READ_TIMEOUT 15.0
#define READ_TIMEOUT_EXTENSION 10.0

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]
#define PORT 1234


@interface ViewController () {
    dispatch_queue_t socketQueue;
    NSMutableArray *connectedSockets;
    BOOL isRunning;
    
    GCDAsyncSocket *listenSocket;
}


@property (nonatomic, strong) RoboMe *roboMe;
@property(nonatomic, strong) CommandPlayer *commandPlayer;

@end
float gravity[] = {0,0,0};
float xPoint=0;
float yPoint=0;
float zPoint=0;
float xPoint1;
float yPoint1;
float zPoint1;
Boolean slope_traversal;


double a;
double b;
double c;

double red_min = 160;
double red_max = 179;


@implementation ViewController

#pragma mark - View Management
double speed=0.3;
CMMotionManager *mManager ;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // create RoboMe object
    self.roboMe = [[RoboMe alloc] initWithDelegate: self];
    
    //[self addGestureRecognizers];
    
    // start listening for events from RoboMe
    [self.roboMe startListening];
    
    // Do any additional setup after loading the view, typically from a nib.
    socketQueue = dispatch_queue_create("socketQueue", NULL);
    
    listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
    
    // Setup an array to store all accepted client connections
    connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
    
    isRunning = NO;
    
    NSLog(@"Ip:%@", [self getIPAddress]);
    
    [self toggleSocketState];   //Starting the Socket
    
    
   
    [self perform:@"SING"];
    
    
    
}

//- (void)viewWillAppear:(BOOL)animated
//{
//    // Add Romo's face to self.view whenever the view will appear
//    [self.Romo addToSuperview:self.view];
//    //[self setupCamera];
//    //[self turnCameraOn];
//}




#pragma mark - RoboMeConnectionDelegate

// Event commands received from RoboMe
- (void)commandReceived:(IncomingRobotCommand)command {
    // Display incoming robot command in text view
    //[self displayText: [NSString stringWithFormat: @"Received: %@" ,[RoboMeCommandHelper incomingRobotCommandToString: command]]];
    
    // To check the type of command from RoboMe is a sensor status use the RoboMeCommandHelper class
    if([RoboMeCommandHelper isSensorStatus: command]){
        // Read the sensor status
      //  SensorStatus *sensors = [RoboMeCommandHelper readSensorStatus: command];
        
        // Update labels
//        [self.edgeLabel setText: (sensors.edge ? @"ON" : @"OFF")];
//        [self.chest20cmLabel setText: (sensors.chest_20cm ? @"ON" : @"OFF")];
//        [self.chest50cmLabel setText: (sensors.chest_50cm ? @"ON" : @"OFF")];
//        [self.cheat100cmLabel setText: (sensors.chest_100cm ? @"ON" : @"OFF")];
    }
}

#pragma mark -
#pragma mark User-Defined Robo Movement

- (NSString *)direction:(NSString *)message {
    
    return @"";
}

- (void)perform:(NSString *)command {
    
    NSString *cmd = [command uppercaseString];
    if ([cmd isEqualToString:@"LEFT"]) {
        [self.roboMe sendCommand:kRobot_TurnLeft90Degrees];
    } else if ([cmd isEqualToString:@"RIGHT"]) {
        [self.roboMe sendCommand: kRobot_TurnRight90Degrees];
    } else if ([cmd isEqualToString:@"BACKWARD"]) {
        [self.roboMe sendCommand: kRobot_MoveBackwardFastest];
    } else if ([cmd isEqualToString:@"FORWARD"]) {
        [self.roboMe sendCommand: kRobot_MoveForwardFastest];
    } else if([cmd isEqualToString:@"STOP"]){
        [self.roboMe sendCommand:kRobot_Stop];
    }
    else if([cmd isEqualToString:@"SING"]){
        NSLog(@"Sing");
        if([self.commandPlayer isPlaying]== NO){
            
            NSLog(@"Inside the song block and going to play song");
            [self.commandPlayer playCommand:@"song.mp3"];
        }
    }
    
    else if ([cmd isEqualToString:@"SEND"]){
        
        NSLog(@"Sending message");
        [self sendMessageTwilio];
        
        NSLog(@"Sent the message");
    }
    
    
    //accelerometer
    else if ([cmd isEqualToString:@"GO"]) {
        [self setupCamera];
        [self turnCameraOn];
        
        if(speed <= 0){
            speed = 0.3;
                    [self.roboMe sendCommand: kRobot_MoveForwardSpeed2];;
            NSLog(@"%f",speed);
        }
        else{
            
                    [self.roboMe sendCommand: kRobot_MoveForwardSpeed1];
            NSLog(@"%f",speed);
        }
        NSLog(@"Before Accelerometer");
        [self checkAccelerometer];
        NSLog(@"After Accelreomter");
    }
    
    //taking picture
    
    else if([cmd isEqualToString:@"PICTURE"]){
        [self setupCamera];
        [self turnCameraOn];
       UIImagePickerController *poc = [[UIImagePickerController alloc] init];
        [poc setTitle:@"Take a photo."];
       // [poc setDelegate:self];
        [poc setSourceType:UIImagePickerControllerSourceTypeCamera];
        poc.showsCameraControls = NO;
        NSLog(@"Before taking picture");
        [poc takePicture];
        NSLog(@"Picture is taken");
    }
    
    //camera
    else if ([cmd isEqualToString:@"CAMERA"]) {
        
        NSLog(@"inside>>>>>");
        
        AVCaptureSession *session = [[AVCaptureSession alloc] init];
        NSError *error = nil;
        [session setSessionPreset:AVCaptureSessionPresetLow];
        
        NSArray *devices = [AVCaptureDevice devices];
        for (AVCaptureDevice *device in devices) {
            NSLog(@"Device name: %@", [device localizedName]);
            if([[device localizedName] isEqual:@"Front Camera"]){
                NSLog(@"front camera checked");
                //aquiring the lock
                if ([device isFocusModeSupported:AVCaptureFocusModeLocked]) {
                    
                    if ([device lockForConfiguration:&error]) {
                        device.focusMode = AVCaptureFocusModeLocked;
                        [device unlockForConfiguration];
                    }
                }
                AVCaptureDeviceInput *input =
                [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
                if (!input) {
                    // Handle the error appropriately.
                    NSLog(@"no imput detected");
                    
                }
                else{
                    NSLog(@"input detected");
                    AVCaptureSession *captureSession = session;
                    AVCaptureDeviceInput *captureDeviceInput = input;
                    if ([captureSession canAddInput:captureDeviceInput]) {
                        NSLog(@"success in adding input");
                        [captureSession addInput:captureDeviceInput];
                        AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
                        [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
                        CALayer *rootLayer = [[self view] layer];
                        [rootLayer setMasksToBounds:YES];
                        [previewLayer setFrame:CGRectMake(-70, 0, rootLayer.bounds.size.height, rootLayer.bounds.size.height)];
                        [rootLayer insertSublayer:previewLayer atIndex:0];
                        [captureSession startRunning];
                        
                        
                        
                        //capturing image
                        NSLog(@"before still ");
                        AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
                        NSDictionary *outputSettings = @{ AVVideoCodecKey : AVVideoCodecJPEG};
                        [stillImageOutput setOutputSettings:outputSettings];
                        
                        NSLog( @"%@",stillImageOutput.description);
                        NSLog(@"after still ");
                        
                        AVCaptureConnection *videoConnection = nil;
                        for (AVCaptureConnection *connection in stillImageOutput.connections) {
                            for (AVCaptureInputPort *port in [connection inputPorts]) {
                                if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                                    videoConnection = connection;
                                    break;
                                }
                            }
                            if (videoConnection) { NSLog(@"Got video connection. breaking from loop");break; }
                        }
                    }
                    else {
                        // Handle the failure.
                        NSLog(@"failure in adding input");
                    }
                }
                
                
            }
        }
    }
}
//#pragma mark - Button callbacks
//
//// The methods below send the desired command to RoboMe.
//// Typically you would want to start a timer to repeatly send the
//// command while the button is held down. For simplicity this wasn't
//// included however if you do decide to implement this we recommand
//// sending commands every 500ms for smooth movement.
//// See RoboMeCommandHelper.h for a full list of robot commands
//- (IBAction)moveForwardBtnPressed:(UIButton *)sender {
//    // Adds command to the queue to send to the robot
//    [self.roboMe sendCommand: kRobot_MoveForwardFastest];
//}
//
//- (IBAction)moveBackwardBtnPressed:(UIButton *)sender {
//    [self.roboMe sendCommand: kRobot_MoveBackwardFastest];
//}
//
//- (IBAction)turnLeftBtnPressed:(UIButton *)sender {
//    [self.roboMe sendCommand: kRobot_TurnLeftFastest];
//}
//
//- (IBAction)turnRightBtnPressed:(UIButton *)sender {
//    [self.roboMe sendCommand: kRobot_TurnRightFastest];
//}
//
//- (IBAction)headUpBtnPressed:(UIButton *)sender {
//    [self.roboMe sendCommand: kRobot_HeadTiltAllUp];
//}
//
//- (IBAction)headDownBtnPressed:(UIButton *)sender {
//    [self.roboMe sendCommand: kRobot_HeadTiltAllDown];
//}


//sending message

-(void)sendMessageTwilio
{
    
//    NSString *twilioSID = @"AC13834e7b7d18ffeb52f674846b2017c7";
//    NSString *twilioAuthKey = @"ce7ea32845386f7aa9efbe73e8e1be43";
//    NSString *fromNumber = @"+19784155546";
//    NSString *ToNumber = @"+19804283462";
//   // NSString *bodyMessage;
//    
//    NSLog(@"starting the application");
//    NSString *locationName=@"Kansas";
//    NSString *countryName=@"us";
//    NSLog(@"locationName%@",locationName);
//    NSLog(@"countryName%@",countryName);
//    NSString *urlString=[NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?q=%@,%@",locationName,countryName];
//    
//    NSLog(@"URL String%@", urlString);
//    
//    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//    
//    [manager GET:urlString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        
//        NSDictionary *dict = [responseObject objectForKey:@"main"];
//        
//        NSString *temperature= [dict objectForKey:@"temp"];
//        
//        //NSString *grid_level=[dict objectForKey:@"grid_level"];
//        
//        NSString *humidiity=[dict objectForKey:@"humidity"];
//        
//       // NSString *pressure=[dict objectForKey:@"pressure"];
//        //NSString *sealevel=[dict objectForKey:@"sea_level"];
//        NSString *temp_min=[dict objectForKey:@"temp_min"];
//        NSString *temp_max=[dict objectForKey:@"temp_max"];
//        
//        NSArray *array=[responseObject objectForKey:@"weather"];
//        NSDictionary *dict2=[array objectAtIndex:0];
//        NSString *description=[dict2 objectForKey:@"description"];
//        
//        NSLog(@"Temperature: %@", temperature);
//        NSLog(@"temp_min: %@",temp_min);
//        
//        NSLog(@"description: %@",description);
//        
//        NSString *messageBody = [NSString stringWithFormat:@"Temperature: %@, Min temp: %@, temp max: %@, description: %@, Humidity: %@", temperature,temp_min,temp_max,description,humidiity];
//        
//        
//        //Starting point to send the messages
//        
//        NSString *urlString = [NSString stringWithFormat:@"https://%@:%@@api.twilio.com/2010-04-01/Accounts/%@/SMS/Messages", twilioSID, twilioAuthKey, twilioSID];
//        
//        NSURL *url = [NSURL URLWithString:urlString];
//        
//        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
//        [request setURL:url];
//        [request setHTTPMethod:@"POST"];
//        
//        //Set up the body the request
//        
//        NSString *bodyString = [NSString stringWithFormat:@"From=%@&To=%@&Body=%@", fromNumber,ToNumber,messageBody];
//        
//        NSData *data =[bodyString dataUsingEncoding:NSUTF8StringEncoding];
//        
//        
//        [request setHTTPBody:data];
//        
//        NSError *error;
//        
//        NSURLResponse *response;
//        
//        NSData *receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
//        
//        //Handle the received data
//        
//        if(error){
//            NSLog(@"Error:%@", error);
//        }else{
//            NSString *receivedString = [[NSString alloc]initWithData:receivedData encoding:NSUTF8StringEncoding];
//            NSLog(@"Request sent.%@",receivedString);
//        }
//    }failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        
//        NSLog(@"Error: %@",error);
//        
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                        message:[error description]
//                                                       delegate:nil
//                                              cancelButtonTitle:@"Ok"
//                                              otherButtonTitles:nil, nil];
//        [alert show];
//    }];
//    
}

#pragma mark -
#pragma mark Socket

- (void)toggleSocketState
{
    if(!isRunning)
    {
        NSError *error = nil;
        if(![listenSocket acceptOnPort:PORT error:&error])
        {
            [self log:FORMAT(@"Error starting server: %@", error)];
            return;
        }
        
        [self log:FORMAT(@"Echo server started on port %hu", [listenSocket localPort])];
        isRunning = YES;
    }
    else
    {
        // Stop accepting connections
        [listenSocket disconnect];
        
        // Stop any client connections
        @synchronized(connectedSockets)
        {
            NSUInteger i;
            for (i = 0; i < [connectedSockets count]; i++)
            {
                // Call disconnect on the socket,
                // which will invoke the socketDidDisconnect: method,
                // which will remove the socket from the list.
                [[connectedSockets objectAtIndex:i] disconnect];
            }
        }
        
        [self log:@"Stopped Echo server"];
        isRunning = false;
    }
}

- (void)log:(NSString *)msg {
    NSLog(@"%@", msg);
}

- (NSString *)getIPAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    
    return address;
}

#pragma mark -
#pragma mark GCDAsyncSocket Delegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    // This method is executed on the socketQueue (not the main thread)
    
    @synchronized(connectedSockets)
    {
        [connectedSockets addObject:newSocket];
    }
    
    NSString *host = [newSocket connectedHost];
    UInt16 port = [newSocket connectedPort];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            
            [self log:FORMAT(@"Accepted client %@:%hu", host, port)];
            
        }
    });
    
    NSString *welcomeMsg = @"Welcome to the AsyncSocket Echo Server\r\n";
    NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
    
    [newSocket writeData:welcomeData withTimeout:-1 tag:WELCOME_MSG];
    
    
    [newSocket readDataWithTimeout:READ_TIMEOUT tag:0];
    newSocket.delegate = self;
    
    //    [newSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    // This method is executed on the socketQueue (not the main thread)
    
    if (tag == ECHO_MSG)
    {
        [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:100 tag:0];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    
    NSLog(@"== didReadData %@ ==", sock.description);
    
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [self log:msg];
    [self perform:msg];
    [sock readDataWithTimeout:READ_TIMEOUT tag:0];
}

/**
 * This method is called if a read has timed out.
 * It allows us to optionally extend the timeout.
 * We use this method to issue a warning to the user prior to disconnecting them.
 **/
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length
{
    if (elapsed <= READ_TIMEOUT)
    {
        NSString *warningMsg = @"Are you still there?\r\n";
        NSData *warningData = [warningMsg dataUsingEncoding:NSUTF8StringEncoding];
        
        [sock writeData:warningData withTimeout:-1 tag:WARNING_MSG];
        
        return READ_TIMEOUT_EXTENSION;
    }
    
    return 0.0;
}


//accelorometer dat collection
//- (void)startUpdatesWithSliderValue:(int)sliderValue
//{
//    
//    NSLog(@"in startUpdateswithSliderValue Accelerometer");
//    NSTimeInterval delta = 0.05;
//    NSTimeInterval updateInterval = accelerometerMin + delta * sliderValue;
//    
//    CMMotionManager *mManager = [(AppDelegate *) [[UIApplication sharedApplication] delegate] sharedManager];
//    
//    if([mManager isAccelerometerAvailable]) {
//        
//        [mManager setAccelerometerUpdateInterval:updateInterval];
//        
//        [mManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
//            
//            a = accelerometerData.acceleration.x;
//            b = accelerometerData.acceleration.y;
//            c = accelerometerData.acceleration.z;
//            NSLog(@"x %f y %f z %f", a, b, c);
//            
//            if ((a <= 0.35 & a>= -0.35) & (b <= -0.75 & b >= -0.93) & (c<=0.62 & c>= -0.67)) {
//                [self.roboMe sendCommand:kRobot_MoveForwardSpeed3];
//                NSLog(@"Block1");
//            }
//            //declination
//            else if ((a <= 0.35 & a >= -0.35) & (b >= -1.0 & b <= -0.80 )& (c >= -0.55 & c<= -0.11)){
//                [self.roboMe sendCommand: kRobot_MoveForwardSlowest];
//                NSLog(@"Block2");
//            }
//            
//            else if ((a <= 0.35 & a >= -0.35)& ((b <= 1.0 & b >= -0.80) || (b >= -1.0 & b <= -0.80) )& (c >= -0.19 & c<= 0.50)){
//                [self.roboMe sendCommand:kRobot_MoveForwardSpeed3];
//                NSLog(@"Block3");
//            }
//            else if ((a >= 0.03 & a < 0.06) & (b >= -0.96 & b <= -0.85 )& (c >=0.38 & c<= 0.50)){
//                [self.roboMe sendCommand:kRobot_MoveForwardSpeed4];
//                NSLog(@"Block4");
//            }
//            else if ((a <= 0.35 & a >= -0.35)& ((b <= 1.0 & b >= -0.80) || (b >= -1.0 & b <= -0.80) )& (c >= -0.19 & c<= 0.50)){
//                [self.roboMe sendCommand:kRobot_MoveForwardSpeed5];
//                NSLog(@"Block5");
//            }
//            // inclination to high
//            else if ((a <= 0.35 & a >= -0.35) & ((b <= -0.02 & b >= -0.50) || (b >= -0.55 & b <= -0.75 ) )& (c >= -1.10 & c <= -0.76)){
//                [self.roboMe sendCommand:kRobot_MoveForwardFastest];
//                NSLog(@"Block6");
//            }
//            else if ((a <= 0.35 & a >= -0.35) & (b <= -0.55 & b >= -0.75 )& (c >= -0.81 & c<= -0.75)){
//                [self.roboMe sendCommand:kRobot_MoveForwardSpeed2];
//                NSLog(@"Block7");
//            }
//            else if ((a <= 0.35 & a >= -0.35) & ((b <= -0.02 & b >= -0.50) || (b >= -0.55 & b <= -0.75 ) )& (c >= -1.10 & c <= -0.76)){
//                [self.roboMe sendCommand:kRobot_MoveForwardSpeed3];
//                NSLog(@"Block8");
//            }
//            else if (((a <= 0.35 & a >= -0.35) & (b >= -0.02 & b <= 0.7 )& (c <=1.10 & c >= 0.76))){
//                
//                NSLog(@"Block9");
//                [self.roboMe sendCommand:kRobot_Stop];
//                [self.roboMe sendCommand:kRobot_IncreaseMood];
//                
//                
//            }
//            
//            //stopn in excess decination
//            
//            else if ((a >= 0.35 & a <= -0.35)& (b >= 1.0 & b <= -0.80 )& (c >= 0.50 & c<= 0.70)){
//                
//                
//                
//                [self.roboMe sendCommand:kRobot_Stop];
//                
//            }
//            else {
//                [self.roboMe sendCommand:kRobot_MoveForwardSpeed3];
//                
//            }
//            
//        }];
//    }
//    
//}



int count = 0 ;
-(void) checkAccelerometer
{
    NSLog(@"In Accelerometer");
    
    NSTimeInterval delta = 0.005;
    NSTimeInterval updateInterval = 1 + delta * 2;
    
    NSLog(@"Before CMManager");
    mManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedManager];
    
    NSLog(@"After CMManager");
    // float alpha = (float) 0.2;
    //ViewController * __weak weakSelf = self;
    
    //  while()
    if ([mManager isAccelerometerAvailable] == YES) {
        [mManager setAccelerometerUpdateInterval:updateInterval];
        
        [mManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            
            xPoint1  = xPoint;
            yPoint1 = yPoint;
            zPoint1 = zPoint;
            xPoint =  accelerometerData.acceleration.x;
            yPoint =  accelerometerData.acceleration.y;
            zPoint =  accelerometerData.acceleration.z;
            
            
            if(zPoint - zPoint1 < 0 && yPoint - yPoint1 > 0.01)
            {
                slope_traversal = true;
                if(speed < 0.6){
                    speed = speed + 0.5;
                    [self.roboMe sendCommand: kRobot_MoveForwardFastest];}
                NSLog(@"IN z-z1 <0 and y-y1 > 0.15");
                NSLog(@"Speed : %f", speed);
                
            }
            else if(yPoint - yPoint1 < 0.01 &&zPoint-zPoint1<0){
                
                slope_traversal=true;
                
                if(speed > 0.4){
                    speed = speed - 0.3;
                    [self.roboMe sendCommand: kRobot_MoveForwardSpeed3];
                }
                
                NSLog(@"IN z-z1 <0 and y-y1 < 0.15");
                NSLog(@"Speed : %f", speed);
                
            }
            
            else if(yPoint - yPoint1 < 0.005&& yPoint - yPoint1 > -0.001)
            {
                if(slope_traversal)
                {
                    [self.roboMe sendCommand: kRobot_Stop];

                   // [super dealloc];
                    slope_traversal = false;
                   // self.Romo.expression=RMCharacterExpressionChuckle;
                    //self.Romo.emotion=RMCharacterEmotionHappy;
                    
                    [self.roboMe sendCommand:kRobot_IncreaseMood];
                    
                    
                    
                    sleep(2);
                    
                    [self.roboMe sendCommand: kRobot_MoveForwardSpeed1];
                }
                
            }
            
            else if (zPoint-zPoint1==0){
                
                if(speed < 0.6){
                    speed = speed + 0.3;
                    
                    [self.roboMe sendCommand: kRobot_MoveForwardSpeed2];
                    
                }
                NSLog(@"Z DIff : %f", zPoint1-zPoint1);
                NSLog(@"Y Diff : %f", yPoint-yPoint1);
                
                NSLog(@"In Else");
            }
            else if(zPoint - zPoint1 > 2)
            {
                
                if(speed > 0.4){
                    speed = speed - 0.3;
                    [self.roboMe sendCommand: kRobot_MoveForwardSlowest];
                }
                NSLog(@"IN z-z1 <0 and y-y1 < 0.15");
                NSLog(@"Speed : %f", speed);
                
            }
            
            
        }];
        
    }
    else
    {
        NSLog(@"Accelerometer not available");
    }
    
    
}



- (void)setupCamera
{
    _captureDevice = nil;
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices)
    {
        if (device.position == AVCaptureDevicePositionFront && !_useBackCamera)
        {
            _captureDevice = device;
            break;
        }
//        if (device.position == AVCaptureDevicePositionBack && _useBackCamera)
//        {
//            _captureDevice = device;
//            break;
//        }
    }
    
    if (!_captureDevice)
        _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}


- (void)turnCameraOn
{
    NSError *error;
    
    _session = [[AVCaptureSession alloc] init];
    [_session beginConfiguration];
    [_session setSessionPreset:AVCaptureSessionPresetMedium];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];
    
    if (input == nil)
        NSLog(@"%@", error);
    
    [_session addInput:input];
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [output setSampleBufferDelegate:self queue:dispatch_queue_create("myQueue", NULL)];
    output.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
    output.alwaysDiscardsLateVideoFrames = YES;
    
    [_session addOutput:output];
    
    [_session commitConfiguration];
    [_session startRunning];
    NSLog(@"Camera turned on");
}


- (void)turnCameraOff
{
    [_session stopRunning];
    _session = nil;
}


- (void)captureOutput:(AVCaptureVideoDataOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    //NSLog(@"didoutSampleBuffer executed");
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    IplImage *iplimage;
    if (baseAddress)
    {
        iplimage = cvCreateImageHeader(cvSize(width, height), IPL_DEPTH_8U, 4);
        iplimage->imageData = (char*)baseAddress;
    }
    
    IplImage *workingCopy = cvCreateImage(cvSize(height, width), IPL_DEPTH_8U, 4);
    
    if (_captureDevice.position == AVCaptureDevicePositionFront)
    {
        cvTranspose(iplimage, workingCopy);
    }
    else
    {
        cvTranspose(iplimage, workingCopy);
        cvFlip(workingCopy, nil, 1);
    }
    
    cvReleaseImageHeader(&iplimage);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    // NSLog(@"before invoking didcaptureImlImage");
    [self didCaptureIplImage:workingCopy];
}


#pragma mark - Image processing


static void ReleaseDataCallback(void *info, const void *data, size_t size)
{
#pragma unused(data)
#pragma unused(size)
    //  IplImage *iplImage = info;
    //  cvReleaseImage(&iplImage);
}


- (CGImageRef)getCGImageFromIplImage:(IplImage*)iplImage
{
    // NSLog(@"getCGImageFromIplImage invoked");
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = iplImage->widthStep;
    
    size_t bitsPerPixel;
    CGColorSpaceRef space;
    
    if (iplImage->nChannels == 1)
    {
        bitsPerPixel = 8;
        space = CGColorSpaceCreateDeviceGray();
    }
    else if (iplImage->nChannels == 3)
    {
        bitsPerPixel = 24;
        space = CGColorSpaceCreateDeviceRGB();
    }
    else if (iplImage->nChannels == 4)
    {
        bitsPerPixel = 32;
        space = CGColorSpaceCreateDeviceRGB();
    }
    else
    {
        abort();
    }
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNone;
    CGDataProviderRef provider = CGDataProviderCreateWithData(iplImage,
                                                              iplImage->imageData,
                                                              0,
                                                              ReleaseDataCallback);
    const CGFloat *decode = NULL;
    bool shouldInterpolate = true;
    CGColorRenderingIntent intent = kCGRenderingIntentDefault;
    
    CGImageRef cgImageRef = CGImageCreate(iplImage->width,
                                          iplImage->height,
                                          bitsPerComponent,
                                          bitsPerPixel,
                                          bytesPerRow,
                                          space,
                                          bitmapInfo,
                                          provider,
                                          decode,
                                          shouldInterpolate,
                                          intent);
    CGColorSpaceRelease(space);
    CGDataProviderRelease(provider);
    return cgImageRef;
}


- (UIImage*)getUIImageFromIplImage:(IplImage*)iplImage
{
    // NSLog(@"getUIImageFromIplImage invoked");
    CGImageRef cgImage = [self getCGImageFromIplImage:iplImage];
    UIImage *uiImage = [[UIImage alloc] initWithCGImage:cgImage
                                                  scale:1.0
                                            orientation:UIImageOrientationUp];
    
    CGImageRelease(cgImage);
    return uiImage;
}


#pragma mark - Captured Ipl Image


//- (void)didCaptureIplImage:(IplImage *)iplImage
//{
//    IplImage *rgbImage = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);
//    cvCvtColor(iplImage, rgbImage, CV_BGR2RGB);
//    cvReleaseImage(&iplImage);
//
//    [self didFinishProcessingImage:rgbImage];
//}


#pragma mark - didFinishProcessingImage


- (void)didFinishProcessingImage:(IplImage *)iplImage
{
    //   NSLog(@"didFinishProcessingImage invoked");
    dispatch_async(dispatch_get_main_queue(), ^{
        //UIImage *uiImage =
        [self getUIImageFromIplImage:iplImage];
        //_imageView.image = uiImage;
    });
}



- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if (sock != listenSocket)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                [self log:FORMAT(@"Client Disconnected")];
            }
        });
        
        @synchronized(connectedSockets)
        {
            [connectedSockets removeObject:sock];
        }
    }
}


static BOOL _debug = NO;

- (void)didCaptureIplImage:(IplImage *)iplImage
{
    //ipl image is in BGR format, it needs to be converted to RGB for display in UIImageView
    IplImage *imgRGB = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplImage, imgRGB, CV_BGR2RGB);
    cv::Mat matRGB = cv::Mat(imgRGB);
    
    //ipl imaeg is also converted to HSV; hue is used to find certain color
    IplImage *imgHSV = cvCreateImage(cvGetSize(iplImage), 8, 3);
    cvCvtColor(iplImage, imgHSV, CV_BGR2HSV);
    
    IplImage *imgThreshed = cvCreateImage(cvGetSize(iplImage), 8, 1);
    
    //it is important to release all images EXCEPT the one that is going to be passed to
    //the didFinishProcessingImage: method and displayed in the UIImageView
    cvReleaseImage(&iplImage);
    
    //filter all pixels in defined range, everything in range will be white, everything else
    //is going to be black
    cvInRangeS(imgHSV, cvScalar(160, 100, 100), cvScalar(179, 255, 255), imgThreshed);
    
    cvReleaseImage(&imgHSV);
    
    cv::Mat matThreshed = cv::Mat(imgThreshed);
    
    //smooths edges
    cv::GaussianBlur(matThreshed,
                     matThreshed,
                     cv::Size(9, 9),
                     2,
                     2);
    
    //debug shows threshold image, otherwise the circles are detected in the
    //threshold image and shown in the RGB image
    if (_debug)
    {
        cvReleaseImage(&imgRGB);
        [self didFinishProcessingImage:imgThreshed];
    }
    else
    {
        std::vector<cv::Vec3f> circles;
        
        //get circles
        HoughCircles(matThreshed,
                     circles,
                     CV_HOUGH_GRADIENT,
                     2,
                     matThreshed.rows / 4,
                     150,
                     75,
                     10,
                     150);
        
        for (size_t i = 0; i < circles.size(); i++)
        {
            cout << "Circle position x = " << (int)circles[i][0] << ", y = " << (int)circles[i][1] << ", radius = " << (int)circles[i][2] << "\n";
            
            cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
            
            int radius = cvRound(circles[i][2]);
            
            circle(matRGB, center, 3, cvScalar(0, 255, 0), -1, 8, 0);
            circle(matRGB, center, radius, cvScalar(0, 0, 255), 3, 8, 0);
            
            [self.roboMe sendCommand: kRobot_Stop];
            //[self dealloc];
            //NSLog(@"robome stopped");
            //self.Romo.expression=RMCharacterExpressionChuckle;
            //self.Romo.emotion=RMCharacterEmotionHappy;
        }
        
        //threshed image is not needed any more and needs to be released
        cvReleaseImage(&imgThreshed);
        
        //imgRGB will be released once it is not needed, the didFinishProcessingImage:
        //method will take care of that
        [self didFinishProcessingImage:imgRGB];
    }
}


//clear video session
- (void)dealloc {
    AVCaptureInput* input = [_session.inputs objectAtIndex:0];
    [_session removeInput:input];
    AVCaptureVideoDataOutput* output = [_session.outputs objectAtIndex:0];
    [_session removeOutput:output];
    [_session stopRunning];
}
@end
