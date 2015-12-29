//
//  CommonVideoViewController.m
//  VideoEditingPart2
//
//  Created by Abdul Azeem Khan on 1/24/13.
//  Copyright (c) 2013 com.datainvent. All rights reserved.
//

#import "CommonVideoViewController.h"

@interface CommonVideoViewController ()

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
      
      [self videoOutput];

  }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size
{
  // no-op - override this method in the subclass
}

- (void)videoOutput
{

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
  mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
  mainCompositionInst.frameDuration = CMTimeMake(1, 30);

  [self applyVideoEffectsToComposition:mainCompositionInst size:naturalSize];
    
    [self frameVideosSideBySideWithComposition:mixComposition andVideoComposition:mainCompositionInst];
  
}

- (void)exportDidFinish:(AVAssetExportSession*)session {
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
              
              UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
              [alertController addAction:ok];
              
              [self presentViewController:alertController animated:YES completion:nil];
          }
        });
      }];
    }
  }
}

- (void)frameVideosSideBySideWithComposition:(AVMutableComposition*)composition andVideoComposition:(AVMutableVideoComposition *)videoComposition{
    
    
    
    
    
    
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



@end
