//
//  SCNVector3Math.swift
//  MeasurAR
//
//  Created by Markus Mühlberger on 09/18/2017.
//  Copyright © 2017 Markus Muehlberger. All rights reserved.
//

import Foundation
import ARKit

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func += (left: inout SCNVector3, right: SCNVector3) {
    left = left + right
}

func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}
