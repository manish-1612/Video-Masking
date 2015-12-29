//
//  Utility.swift
//  genesisgetfit
//
//  Created by Milan Kamilya on 21/07/15.
//  Copyright (c) 2015 Innofied Solution Pvt. Ltd. All rights reserved.
//

import UIKit

typealias DownloadImageCallbackBlock = (image: UIImage?, error: NSError?) -> Void


struct ScreenSize
{
    static let SCREEN_WIDTH = UIScreen.mainScreen().bounds.size.width
    static let SCREEN_HEIGHT = UIScreen.mainScreen().bounds.size.height
    static let SCREEN_MAX_LENGTH = max(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
    static let SCREEN_MIN_LENGTH = min(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
}

struct DeviceType
{
     static let IS_IPHONE_4_OR_LESS =  UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH < 568.0
     static let IS_IPHONE_5 = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH == 568.0
     static let IS_IPHONE_6 = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH == 667.0
     static let IS_IPHONE_6P = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH == 736.0
}

enum TimeComponentType {
    case Milisecond
    case Second
    case Minute
    case Hour
    case Day
    case Month
    case Year
}

class Utility: NSObject {
   
    
//    static func getDateStringFromNSDate(dateLocal: NSDate) -> String {
//        let dateFormatter = NSDateFormatter()
//        dateFormatter.timeZone = NSTimeZone.localTimeZone()
//        dateFormatter.dateFormat = GFConstants.AppStrings.DateFormatForBirthday
//        let dateStr: String = dateFormatter.stringFromDate(dateLocal)
//        return dateStr
//    }
    
    static func logAllAvailavleFonts() {
        let fontFamilies = UIFont.familyNames();
        
        for fontFamilyName in fontFamilies {
            let fontNames = UIFont.fontNamesForFamilyName(fontFamilyName )
            print("\n\(fontFamilyName):")
            for fontName in fontNames {
                print("\t \(fontName)")
            }
        }
    }
    
    
    
    static func getKeyboardHeight() -> CGFloat{
        if DeviceType.IS_IPHONE_4_OR_LESS {
            return 224.0
        } else if DeviceType.IS_IPHONE_5 {
            return 224.0
        } else if DeviceType.IS_IPHONE_6 {
            return 225.0
        } else {
            return 236.0
        }
    }
    
    
    static func jsonDataFromJSONFile(fileName: String?) -> AnyObject?{
        var data: AnyObject?
        if let path = NSBundle.mainBundle().pathForResource(fileName, ofType: "json") {
            if let jsonData = NSData(contentsOfFile: path) {
                
                do {
                    data = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .MutableContainers)
                    return data
                } catch {
                    print("\(error)")
                }
            }
        }
        return nil
    }
    
    
    static func getStretchContentFactor() -> CGFloat{
        
        if DeviceType.IS_IPHONE_4_OR_LESS{
            //setting top space constraint for logo
            return 0.85
            
        }else if DeviceType.IS_IPHONE_5{
            //setting top space constraint for logo
            return 1.0
            
        }else if DeviceType.IS_IPHONE_6{
            //setting top space constraint for logo
            return 1.15
            
        }else if DeviceType.IS_IPHONE_6P{
            //setting top space constraint for logo
            return 1.3
        }else{
            return 1.0
        }
    }
    

    
    class func setPlaceHolderAttributeForTextField(textField : UITextField , attributes : NSDictionary , placeHolderString : String){
        //set placeholder colour for text field
        if textField.respondsToSelector("setAttributedPlaceholder:"){
            textField.attributedPlaceholder = NSAttributedString(string: placeHolderString, attributes: attributes as? [String : AnyObject])
        }else{
            print("Cannot set placeholder text's color, because deployment target is earlier than iOS 6.0")
            //TODO: Add fall-back code to set placeholder color.
        }
    }

    
    
    class func serializeDataToJSON(data: NSData) -> AnyObject?{
        do {
            return try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)
        } catch {
            print("JSON Serilizaition Error : \(error)")
        }
        return nil
    }
    
    class func jsonStringFromDictionary(dict: Dictionary<String,AnyObject>) -> String? {
        
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(dict, options: .PrettyPrinted)
            return String(data: jsonData, encoding: NSUTF8StringEncoding)
        } catch {
            return nil
        }
    }
    
    static func storyBoardFileName() -> String {
        
        var storyBoardKey: NSString = ""
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            storyBoardKey = "UIMainStoryboardFile"
        } else if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
             storyBoardKey = "UIMainStoryboardFile~ipad"
        }
        return NSBundle.mainBundle().infoDictionary?[storyBoardKey as String] as! String
    }
    
    static func applicationVersion() -> String{
        return NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String;
    }
    
    static func applicationBuildVersion() -> String{
        return NSBundle.mainBundle().infoDictionary!["CFBundleVersion"] as! String
    }
    static func applicationPListProperty(key: String) -> AnyObject{
        return NSBundle.mainBundle().infoDictionary![key]!
    }
    
    static func downloadImageAsynchronously(url: NSURL, callback:DownloadImageCallbackBlock) {
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
                dispatch_async(dispatch_get_main_queue()) {
                    print("Finished downloading \"\(url.lastPathComponent)")
                    callback(image: UIImage(data: data!), error: error)
                }
            }.resume()
    }
    
    static func getAlertViewController(title: String, message: String) -> UIAlertController {
        let alertViewController: UIAlertController! = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let okAction : UIAlertAction = UIAlertAction(title: "Ok", style: .Cancel) { (alertViewController) -> Void in
            
        }
        
        alertViewController.addAction(okAction)
        
        return alertViewController
    }
    
    static func getDifferenceBetweenStartDate(startDate : NSDate, endDate : NSDate, inComponentType : TimeComponentType ) -> Double {
        let differenceInMilisecond: Double = startDate.timeIntervalSinceDate(endDate)
        var result: Double = 0.0
        
        switch inComponentType {
            
            case .Milisecond :
                result =  differenceInMilisecond
            case .Second :
                result =  (differenceInMilisecond / 1000.0)
            case .Minute :
                result =  differenceInMilisecond / 60000.0
            case .Hour :
                result =  differenceInMilisecond / 3600000.0
            case .Day :
                result =  differenceInMilisecond / 86400000.0
            case .Month :
                result =  differenceInMilisecond / 2592000000.0
            case .Year :
                result = differenceInMilisecond / 315360000000.0
            
        }
        
        return result
    }
    
    
    class func errorStringFromDictionary(errorDictionary : [NSObject : AnyObject]) -> String{
        
        var errorString = ""
        
        let newDictionary = NSDictionary(dictionary: errorDictionary)
        let keyArray  : [String] = (newDictionary.allKeys as? [String])!
        
        if keyArray.count > 0{
            errorString = (newDictionary.objectForKey(keyArray.first!) as? String)!
        }
        
        return errorString
        
    }
    
    
    
    class func getImageWithColor(color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRectMake(0, 0, size.width, size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    
   
}
