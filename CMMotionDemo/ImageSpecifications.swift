//
//  ImageSpecifications.swift
//  CMMotionDemo
//
//  Created by David Nguyen Truong on 9/17/18.
//  Copyright © 2018 David Nguyen Truong. All rights reserved.
//

import Foundation
import UIKit

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
    
    internal func toString() -> String {
        var s = ""
        s += "Acceleration: \nX:\(accelX!)\nY:\(accelY!)\nZ:\(accelZ!)\n"
        s += "Gyro: \nX:\(gyroX!)\nY:\(gyroY!)\nZ:\(gyroZ!)\n"
        s += "Magnetometer:\nX:\(magneticX!)\nY:\(magneticY!)\nZ:\(magneticZ!)\n"
        s += "Roll: \(roll!)\n, Pitch: \(pitch!)\n, Yaw: \(yaw!)\n"
        return s
    }
}