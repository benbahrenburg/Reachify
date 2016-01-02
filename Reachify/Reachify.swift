//
//  Reachify.swift
//  Reachify
//
//  Created by Ben Bahrenburg on 1/2/16.
//  Copyright © 2016 bencoding.com. All rights reserved.
//

import Foundation
import SystemConfiguration

class Reachify {
    
    enum ConnectionType {
        case Unknown
        case Offline
        case Mobile
        case Wifi
    }
    
    var online : Bool {
        get {
            return self.isOnline()
        }
    }
    
    func MapEnum(flags : SCNetworkReachabilityFlags) -> ConnectionType {
        let connectionRequired = flags.contains(.ConnectionRequired)
        let isReachable = flags.contains(.Reachable)
        
        if !connectionRequired && isReachable {
            let wifiCheck = flags.contains(.IsWWAN)
            if wifiCheck {
                return .Mobile
            } else {
                return .Wifi
            }
        }
        
        return .Offline
    }
    
    func getNetworkStatus() -> ConnectionType {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return ConnectionType.Unknown
        }
        
        return MapEnum(flags)
    }
    
    func isWifi() -> Bool {
        return getNetworkStatus() == ConnectionType.Wifi
    }
    
    func isOnline() -> Bool {
        let status = getNetworkStatus()
        return status == ConnectionType.Wifi || status == ConnectionType.Mobile
    }
    
    func isAddressAvailable(address : String,
        timeout : Double = 10.0,
        httpMethod : String = "HEAD",
        completionHandler:(isReachable:Bool) -> Void) {

            let url = NSURL(string: address)!

            let request = NSMutableURLRequest(URL: url, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: timeout)
        
            request.HTTPMethod = httpMethod
        
            NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {(data, response, error) in
            
                if let reply = response as? NSHTTPURLResponse {
                    completionHandler(isReachable: (reply.statusCode == 200))
                } else {
                    completionHandler(isReachable: false)
                }
            
            }).resume()
    }
    
}