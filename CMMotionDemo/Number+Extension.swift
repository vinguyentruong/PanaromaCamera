//
//  Number+Extension.swift
//  CMMotionDemo
//
//  Created by David Nguyen Truong on 9/16/18.
//  Copyright © 2018 David Nguyen Truong. All rights reserved.
//

import Foundation
import UIKit

extension BinaryInteger {
    var degreesToRadians: CGFloat { return CGFloat(Int(self)) * .pi / 180 }
    var radiansToDegrees: CGFloat { return CGFloat(Int(self)) * 180 / .pi }
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}
