//
//  PazMapDirections.swift
//  PazMapDirections
//
//  Created by Pantelis Zirinis on 08/11/2016.
//  Copyright © 2016 paz-labs. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MapKit

// enum to hold possible navigation apps on user's device
public enum PazNavigationApp {
    case AppleMaps
    case GoogleMaps
    case Navigon
    case TomTom
    case Waze
    
    // shortcut to access every value of possible navigation app
    public static let AllValues: [PazNavigationApp] = [.AppleMaps, .GoogleMaps, .Navigon, .TomTom, .Waze]
    
    // property that returns only navigation apps that the user has installed
    public static var AvailableServices: [PazNavigationApp] {
        return self.AllValues.filter { app in app.available }
    }
    
    // name of each app as it will appear on the Alert's options
    public var name: String {
        switch self {
        case .AppleMaps:
            return "Apple Maps"
        case .GoogleMaps:
            return "Google Maps"
        case .Navigon:
            return "Navigon"
        case .TomTom:
            return "TomTom"
        case .Waze:
            return "Waze"
        }
    }
    
    // base of URL used to open the navigation app
    public var urlString: String {
        switch self {
        case .AppleMaps:
            return "http://maps.apple.com"
        case .GoogleMaps:
            return "comgooglemaps://"
        case .Navigon:
            return "navigon://"
        case .TomTom:
            return "tomtomhome://"
        case .Waze:
            return "waze://"
        }
    }
    
    // auxiliar property to transform a string into an URL
    public var url: URL? {
        return URL(string: self.urlString)
    }
    
    // property that checks if a given app is installed
    public var available: Bool {
        guard let url = self.url else {
            return false
        }
        return UIApplication.shared.canOpenURL(url)
    }
    
    /* func to get the full URL (in string version)
     necessary to open the navigation app on the desired coordinates */
    public func directionsUrlString(coordinate: CLLocationCoordinate2D,
                                    name: String = "Destination") -> String {
        
        var urlString = self.urlString
        
        switch self {
        case .AppleMaps:
            urlString.append("?q=\(coordinate.latitude),\(coordinate.longitude)=d&t=h")
            
        case .GoogleMaps:
            urlString.append("?saddr=&daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving")
            
        case .Navigon:
            urlString.append("coordinate/\(name)/\(coordinate.longitude)/\(coordinate.latitude)")
            
        case .TomTom:
            urlString.append("geo:action=navigateto&lat=\(coordinate.latitude)&long=\(coordinate.longitude)&name=\(name)")
            
        case .Waze:
            urlString.append("?ll=\(coordinate.latitude),\(coordinate.longitude)&navigate=yes")
        }
        
        let urlwithPercentEscapes =
            urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString

        return urlwithPercentEscapes
    }

    // wrapper func to turn a string into an URL object
    public func directionsUrl(coordinate: CLLocationCoordinate2D, name: String = "Destination") -> URL? {
        let urlString = self.directionsUrlString(coordinate: coordinate, name: name)
        return URL(string: urlString)
    }
    
    /* func that tries to open a navigation app on a specific set of coordinates
     and informs it's callback if it was successful */
    public func openWithDirections(coordinate: CLLocationCoordinate2D,
                                   name: String = "Destination",
                                   completion: ((Bool) -> Swift.Void)? = nil) {
        
        // Apple Maps can be opened differently than other navigation apps
        if self == .AppleMaps {
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
            mapItem.name = self.name
            
            let success = mapItem.openInMaps(launchOptions:
                [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
            
            completion?(success)
        }
        
        guard let url = self.directionsUrl(coordinate: coordinate, name: name) else {
            completion?(false)
            return
        }
        
        // open the app with appropriate method for your target iOS version
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: {
                (success) in
                print("Open \(url.absoluteString): \(success)")
                completion?(success)
            })
        } else {
            let success = UIApplication.shared.openURL(url)
            completion?(success)
        }
    }
    
    /* func to create an Alert where the options
     are the available navigation apps on the user's device.
     The callback informs if the operation was successful */
    public static func directionsAlertController(coordinate: CLLocationCoordinate2D,
                                                 name: String = "Destination",
                                                 title: String = "Directions Using",
                                                 message: String? = nil,
                                                 completion: ((Bool) -> ())? = nil)
        -> UIAlertController {
            
            let directionsAlertView = UIAlertController(title: title,
                                                        message: nil,
                                                        preferredStyle: .actionSheet)
            
            for navigationApp in PazNavigationApp.AvailableServices {
                
                let action = UIAlertAction(title: navigationApp.name,
                                           style: UIAlertActionStyle.default,
                                           handler: { action in
                                            navigationApp.openWithDirections(coordinate: coordinate,
                                                                             name: name,
                                                                             completion: completion)
                })
                
                directionsAlertView.addAction(action)
            }
            
            let cancelAction = UIAlertAction(title: "Dismiss",
                                             style: UIAlertActionStyle.cancel,
                                             handler: { action in completion?(false) })
            
            directionsAlertView.addAction(cancelAction)
            
            return directionsAlertView
    }
}
