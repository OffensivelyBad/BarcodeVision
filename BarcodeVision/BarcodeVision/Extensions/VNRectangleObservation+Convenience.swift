//
//  VNRectangleObservation+Convenience.swift
//  BarcodeVision
//
//  Created by Shawn Roller on 5/3/18.
//  Copyright © 2018 Shawn Roller. All rights reserved.
//

import Foundation
import Vision

extension VNRectangleObservation {
    
    func middlePoint() -> CGPoint {
        let midX = ((bottomRight.x - bottomLeft.x) / 2) + bottomLeft.x
        let midY = ((bottomLeft.y - topLeft.y) / 2) + topLeft.y
        return CGPoint(x: midX, y: midY)
    }
    
    func middleBottomPoint() -> CGPoint {
        return CGPoint(x: middlePoint().x, y: bottomLeft.y)
    }
    
    func middleTopPoint() -> CGPoint {
        return CGPoint(x: middlePoint().x, y: topLeft.y)
    }
    
}
