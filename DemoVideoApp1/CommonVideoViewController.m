//
//  CommonVideoViewController.m
//  VideoEditingPart2
//
//  Created by Abdul Azeem Khan on 1/24/13.
//  Copyright (c) 2013 com.datainvent. All rights reserved.
//

#import "CommonVideoViewController.h"

@interface CommonVideoViewController (){
    NSURL *savedUrlFirst;
    NSURL *savedUrlSecond;
    BOOL isOverlappingCompleted;
    CGSize savedRenderSize;
}

@end

@implementation CommonVideoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (BOOL)startMediaBrowserFromViewController:(UIViewController*)controller usingDelegate:(id)delegate {
  // 2 - Get image picker
    
    savedUrlFirst = nil;
    savedUrlSecond = nil;
    
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    // Hides the controls for moving & scaling pictures, or for
    // trimming movies. To instead show the controls, use YES.
    mediaUI.delegate = delegate;
    mediaUI.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    mediaUI.allowsEditing = NO;
    mediaUI.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;//UIImagePickerControllerCameraCaptureMode.Video
    mediaUI.videoQuality = UIImagePickerControllerQualityTypeHigh;
    mediaUI.videoMaximumDuration = 20.0;
    
    // 3 - Display image picker
    [controller presentViewController:mediaUI animated:YES completion:^{
    }];
    return YES;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  // 1 - Get media type
  NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];

  // 2 - Dismiss image picker
  [self dismissViewControllerAnimated:YES completion:nil];

  // 3 - Handle video selection
  if (CFStringCompare ((__bridge_retained CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
      self.videoAsset = [AVAsset assetWithURL:[info objectForKey:UIImagePickerControllerMediaURL]];
      
      for (int i = 0; i < 2; i++){
          [self firstVideoOutput];
      }
  }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size
{
  // no-op - override this method in the subclass
}

- (void)firstVideoOutput
{
    isOverlappingCompleted = false;

  // 2 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
  AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];

  // 3 - Video track
  AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                      preferredTrackID:kCMPersistentTrackID_Invalid];
  [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, self.videoAsset.duration)
                      ofTrack:[[self.videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                       atTime:kCMTimeZero error:nil];

  // 3.1 - Create AVMutableVideoCompositionInstruction
  AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
  mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, self.videoAsset.duration);

  // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
  AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
  AVAssetTrack *videoAssetTrack = [[self.videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
  UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
  BOOL isVideoAssetPortrait_  = NO;
  CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
  if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
    videoAssetOrientation_ = UIImageOrientationRight;
    isVideoAssetPortrait_ = YES;
  }
  if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
    videoAssetOrientation_ =  UIImageOrientationLeft;
    isVideoAssetPortrait_ = YES;
  }
  if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
    videoAssetOrientation_ =  UIImageOrientationUp;
  }
  if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
    videoAssetOrientation_ = UIImageOrientationDown;
  }
  [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];

  [videolayerInstruction setOpacity:0.0 atTime:self.videoAsset.duration];

  // 3.3 - Add instructions
  mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];

  AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];

  CGSize naturalSize;
  if(isVideoAssetPortrait_){
    naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
  } else {
    naturalSize = videoAssetTrack.naturalSize;
  }

  float renderWidth, renderHeight;
  renderWidth = naturalSize.width;
  renderHeight = naturalSize.height;
  mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
  savedRenderSize = mainCompositionInst.renderSize;
  mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
  mainCompositionInst.frameDuration = CMTimeMake(1, 30);

  [self applyVideoEffectsToComposition:mainCompositionInst size:naturalSize];
    
  [self exportVideoToLibraryWithComposition:mixComposition andVideoComposition:mainCompositionInst];
  
}


- (void)exportVideoToLibraryWithComposition:(AVMutableComposition*)composition andVideoComposition:(AVMutableVideoComposition *)videoComposition{
    
    // 4 - Get path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:
                             [NSString stringWithFormat:@"FinalVideo-%d.mov",arc4random() % 1000]];
    NSURL *url = [NSURL fileURLWithPath:myPathDocs];
    
    // 5 - Create exporter
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=url;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = videoComposition;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self exportDidFinish:exporter];
        });
    }];

}


- (void)exportDidFinish:(AVAssetExportSession*)session {
    
    if (isOverlappingCompleted) {
        if (session.status == AVAssetExportSessionStatusCompleted) {
            NSURL *outputURL = session.outputURL;
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
                [library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (error) {
                            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:@"Video Saving Failed" preferredStyle:UIAlertControllerStyleAlert];
                            
                            UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                            [alertController addAction:ok];
                            
                            [self presentViewController:alertController animated:YES completion:nil];
                            
                        } else {
                            
                            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Video saved" message:@"Saved to photo album" preferredStyle:UIAlertControllerStyleAlert];
                            
                            
                            savedUrlFirst = nil;
                            savedUrlSecond = nil;

                            UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                            [alertController addAction:ok];
                            
                            [self presentViewController:alertController animated:YES completion:nil];
                        }
                    });
                }];
            }
        }
    }else{
        
        
        if (savedUrlFirst == nil){
            savedUrlFirst = session.outputURL;
        }else if (savedUrlSecond == nil){
            savedUrlSecond = session.outputURL;
        }
        
        if (savedUrlFirst != nil && savedUrlSecond != nil){
            [self overlapVideos];
        }
        
    }
    
    
}


- (void) overlapVideos{
    
    //First load your videos using AVURLAsset. Make sure you give the correct path of your videos.
    
    AVURLAsset* firstAsset = [AVURLAsset URLAssetWithURL:savedUrlFirst options:nil];
    AVURLAsset * secondAsset = [AVURLAsset URLAssetWithURL:savedUrlSecond options:nil];
    
    //Create AVMutableComposition Object which will hold our multiple AVMutableCompositionTrack or we can say it will hold our multiple videos.
    AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
    
    //Now we are creating the first AVMutableCompositionTrack containing our first video and add it to our AVMutableComposition object.
    AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    //Now we set the length of the firstTrack equal to the length of the firstAsset and add the firstAsset to out newly created track at kCMTimeZero so video plays from the start of the track.
    [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstAsset.duration) ofTrack:[[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    //Repeat the same process for the 2nd track as we did above for the first track.
    AVMutableCompositionTrack *secondTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [secondTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondAsset.duration) ofTrack:[[secondAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    //See how we are creating AVMutableVideoCompositionInstruction object. This object will contain the array of our AVMutableVideoCompositionLayerInstruction objects. You set the duration of the layer. You should add the length equal to the length of the longer asset in terms of duration.
    AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
    MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, firstAsset.duration);
    
    //We will be creating 2 AVMutableVideoCompositionLayerInstruction objects. Each for our 2 AVMutableCompositionTrack. Here we are creating AVMutableVideoCompositionLayerInstruction for out first track. See how we make use of Affinetransform to move and scale our First Track. So it is displayed at the bottom of the screen in smaller size.(First track in the one that remains on top).
    //Note: You have to apply transformation to scale and move according to your video size.
    
    AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
    

    CGAffineTransform move = CGAffineTransformMakeTranslation(savedRenderSize.width / 2.0 + 70.0 -(savedRenderSize.width - savedRenderSize.height)/2.0, 50.0);
    CGAffineTransform Scale = CGAffineTransformMakeScale(0.9f,0.9f);
    CGAffineTransform Rotate = CGAffineTransformMakeRotation(M_PI * 180/180);
    CGAffineTransform rotateTranslate = CGAffineTransformTranslate(Rotate,-savedRenderSize.width,-savedRenderSize.height);
    [FirstlayerInstruction setTransform:CGAffineTransformConcat(rotateTranslate, CGAffineTransformConcat(move, Scale)) atTime:kCMTimeZero];


    [FirstlayerInstruction setCropRectangle:CGRectMake((savedRenderSize.width - savedRenderSize.height)/2.0 , 0.0, savedRenderSize.height, savedRenderSize.height) atTime:kCMTimeZero];

    
    //Here we are creating AVMutableVideoCompositionLayerInstruction for our second track.see how we make use of Affinetransform to move and scale our second Track.
    AVMutableVideoCompositionLayerInstruction *SecondlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:secondTrack];
    CGAffineTransform SecondScale = CGAffineTransformMakeScale(0.9f,0.9f);
    CGAffineTransform SecondMove = CGAffineTransformMakeTranslation(-(savedRenderSize.width - savedRenderSize.height)/2.0 + 50.0, 50.0);
    [SecondlayerInstruction setTransform:CGAffineTransformConcat(SecondScale,SecondMove) atTime:kCMTimeZero];
    [SecondlayerInstruction setCropRectangle:CGRectMake((savedRenderSize.width - savedRenderSize.height)/2.0 , 0.0, savedRenderSize.height, savedRenderSize.height) atTime:kCMTimeZero];

    
    //Now we add our 2 created AVMutableVideoCompositionLayerInstruction objects to our AVMutableVideoCompositionInstruction in form of an array.
    MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,SecondlayerInstruction,nil];;
    
    //Now we create AVMutableVideoComposition object.We can add multiple AVMutableVideoCompositionInstruction to this object.We have only one AVMutableVideoCompositionInstruction object in our example.You can use multiple AVMutableVideoCompositionInstruction objects to add multiple layers of effects such as fade and transition but make sure that time ranges of the AVMutableVideoCompositionInstruction objects dont overlap.
    AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
    MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
    MainCompositionInst.frameDuration = CMTimeMake(1, 30);
    MainCompositionInst.renderSize = savedRenderSize;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"OverlapVideo-%d.mov",arc4random() % 1000]];
    
    
    
    if([[NSFileManager defaultManager] fileExistsAtPath:myPathDocs])
    {
        [[NSFileManager defaultManager] removeItemAtPath:myPathDocs error:nil];
    }
    
    NSURL *url = [NSURL fileURLWithPath:myPathDocs];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=url;
    [exporter setVideoComposition:MainCompositionInst];
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    
    isOverlappingCompleted = true;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self exportDidFinish:exporter];
        });
    }];
    
}


@end
