//
//  ImageSpecifications.swift
//  CMMotionDemo
//
//  Created by David Nguyen Truong on 9/17/18.
//  Copyright © 2018 David Nguyen Truong. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

class ImageSpecifications {
    
    internal var accelX: Double!
    internal var accelY: Double!
    internal var accelZ: Double!
    
    internal var gyroX: Double!
    internal var gyroY: Double!
    internal var gyroZ: Double!
    
    internal var magneticX: Double!
    internal var magneticY: Double!
    internal var magneticZ: Double!
    
    internal var roll: Double!
    internal var pitch: Double!
    internal var yaw: Double!
    
    internal var degree: Double!
    internal var ring: Int!
    
    internal func toString() -> String {
        var s = ""
        s += "Acceleration: \nX:\(accelX!)\nY:\(accelY!)\nZ:\(accelZ!)\n"
        s += "Gyro: \nX:\(gyroX!)\nY:\(gyroY!)\nZ:\(gyroZ!)\n"
        s += "Magnetometer:\nX:\(magneticX!)\nY:\(magneticY!)\nZ:\(magneticZ!)\n"
        s += "Roll: \(roll!)\n, Pitch: \(pitch!)\n, Yaw: \(yaw!)\n"
        return s
    }
    
    internal func toJson() -> JSON {
        var dictionary = [String: Any]()
        var sensorDictionary = [String: Any]()
//        var accelDic = [String: String]()
//        accelDic["x"] = "\(accelX!)"
//        accelDic["y"] = "\(accelY!)"
//        accelDic["z"] = "\(accelZ!)"
//        sensorDictionary["anccelerometr"] = accelDic
//        var gyroDic = [String: String]()
//        gyroDic["x"] = "\(gyroX!)"
//        gyroDic["y"] = "\(gyroY!)"
//        gyroDic["z"] = "\(gyroZ!)"
//        sensorDictionary["gyroscope"] = gyroDic
//        var magneDic = [String: String]()
//        magneDic["x"] = "\(magneticX!)"
//        magneDic["y"] = "\(magneticY!)"
//        magneDic["z"] = "\(magneticZ!)"
//        sensorDictionary["magnetometr"] = magneDic
        var rpy = [String: String]()
        rpy["roll"] = "\(roll!)"
        rpy["pitch"] = "\(pitch!)"
        rpy["yaw"] = "\(yaw!)"
        sensorDictionary["roll_pitch_yaw"] = rpy
        dictionary["degrees"] = "\(degree!)"
        dictionary["ring"] = "\(ring!)"
        dictionary["sensors"] = sensorDictionary
        let json = JSON(dictionary)
        return json
    }
}
