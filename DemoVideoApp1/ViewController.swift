//
//  ViewController.swift
//  DemoVideoApp1
//
//  Created by Manish Kumar on 28/12/15.
//  Copyright © 2015 Innofied Solutions Pvt. Ltd. All rights reserved.
//

import UIKit
import MobileCoreServices

class ViewController: CommonVideoViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func openCamera(sender: UIButton) {
        startMediaBrowserFromViewController(self, usingDelegate: self)
    }
    
   
    @IBAction func openGalleryForViewingVideo(sender: AnyObject) {
        
        // 1 - Early exit if there's no video file selected
        if (self.videoAsset == nil) {
            
            let alertController = UIAlertController(title: "Error", message: "Please open camera for taking video first", preferredStyle: UIAlertControllerStyle.Alert)
            
            let ok = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Destructive, handler: nil)
            
            alertController.addAction(ok)
            
            self.presentViewController(alertController, animated: true, completion: nil)
            
            return;
        }

        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum){
            let imagePicker = UIImagePickerController()//[[UIImagePickerController alloc] init];
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum
            imagePicker.mediaTypes = [kUTTypeMovie as String]
            imagePicker.allowsEditing = false
            imagePicker.modalPresentationStyle = .Custom
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        
    }
    
    override func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    
    override func applyVideoEffectsToComposition(composition : AVMutableVideoComposition , size : CGSize){
        
        let widthBar : CGFloat?
        
        if size.height > size.width {
            widthBar = size.width
        }else{
            widthBar = size.height
        }

        //main overlay
        let overlayLayer = CALayer()
        let overlayImage =  UIImage(named: "mask.png")
        overlayLayer.contents = overlayImage!.CGImage as? AnyObject
        overlayLayer.frame = CGRectMake((size.width - widthBar!)/2.0, (size.height - widthBar!)/2.0, widthBar!, widthBar!)
        overlayLayer.masksToBounds = true
        
        
        //starting overlay
        let startOverlayImage = Utility.getImageWithColor(UIColor.blackColor(), size: CGSizeMake(widthBar!, widthBar!))
        let startOverlayLayer = CALayer()
        startOverlayLayer.contents = startOverlayImage.CGImage as? AnyObject
        if size.width > size.height {
            startOverlayLayer.frame = CGRectMake(0, 0,(size.width - widthBar!)/2.0, widthBar!)
        }else{
            startOverlayLayer.frame = CGRectMake(0, 0, widthBar!, (size.height - widthBar!)/2.0)
        }
        startOverlayLayer.masksToBounds = true
        
        
        //ending overlay
        let endOverlayImage = Utility.getImageWithColor(UIColor.blackColor(), size: CGSizeMake(widthBar!, widthBar!))
        let endOverlayLayer = CALayer()
        endOverlayLayer.contents = endOverlayImage.CGImage as? AnyObject
        if size.width > size.height {
            endOverlayLayer.frame = CGRectMake((size.width - widthBar!)/2.0 + widthBar!, 0,(size.width - widthBar!)/2.0, widthBar!)
        }else{
            endOverlayLayer.frame = CGRectMake(0.0, (size.height - widthBar!)/2.0 + widthBar! , widthBar!,(size.height - widthBar!)/2.0)
        }
        endOverlayLayer.masksToBounds = true

        // 2 - set up the parent layer
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRectMake(0, 0, size.width, size.height)
        videoLayer.frame = CGRectMake(0, 0, size.width, size.height)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(startOverlayLayer)
        parentLayer.addSublayer(overlayLayer)
        parentLayer.addSublayer(endOverlayLayer)

        
        composition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
    }
    
}




/*
override func applyVideoEffectsToComposition(composition : AVMutableVideoComposition , size : CGSize){

let borderImage = Utility.getImageWithColor(UIColor.blackColor(), size: size)

let backgroundLayer = CALayer()
backgroundLayer.contents = [borderImage.CGImage] as? AnyObject
backgroundLayer.frame = CGRectMake(0, 0, size.width, size.height)
backgroundLayer.masksToBounds = true

let widthBar : CGFloat?

if size.height > size.width {
widthBar = size.width
}else{
widthBar = size.height
}

let videoLayer = CALayer()
videoLayer.frame = CGRectMake(0.0, 0.0, size.width, size.height);
videoLayer.cornerRadius = widthBar!/2.0
videoLayer.masksToBounds = true




let parentLayer = CALayer()
parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
parentLayer.addSublayer(backgroundLayer)
parentLayer.addSublayer(videoLayer)

composition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
}*/

