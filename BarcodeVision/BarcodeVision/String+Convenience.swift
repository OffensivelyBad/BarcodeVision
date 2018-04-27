//
//  String+Convenience.swift
//  BarcodeVision
//
//  Created by Shawn Roller on 4/27/18.
//  Copyright © 2018 Shawn Roller. All rights reserved.
//

import Foundation

extension String {
    
    func isLocation() -> Bool {
        return self.components(separatedBy: "-").count == 4
    }
    
}
