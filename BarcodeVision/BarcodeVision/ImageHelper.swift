//
//  ImageHelper.swift
//  BarcodeVision
//
//  Created by Shawn Roller on 2/9/21.
//  Copyright © 2021 Shawn Roller. All rights reserved.
//

import UIKit
import Accelerate

class ImageHelper {
    /*
     The Core Graphics image representation of the source asset.
     */
    var cgImage: CGImage!
    
    /*
     The format of the source asset.
     */
    lazy var format: vImage_CGImageFormat = {
        guard
            let format = vImage_CGImageFormat(cgImage: cgImage) else {
                fatalError("Unable to create format.")
        }
        
        return format
    }()
    
    /*
     The vImage buffer containing a scaled down copy of the source asset.
     */
    lazy var sourceBuffer: vImage_Buffer = {
        guard
            var sourceImageBuffer = try? vImage_Buffer(cgImage: cgImage,
                                                       format: format),
            
            var scaledBuffer = try? vImage_Buffer(width: Int(sourceImageBuffer.height / 3),
                                                  height: Int(sourceImageBuffer.width / 3),
                                                  bitsPerPixel: format.bitsPerPixel) else {
                                                    fatalError("Unable to create source buffers.")
        }
        
        defer {
            sourceImageBuffer.free()
        }
        
        vImageScale_ARGB8888(&sourceImageBuffer,
                             &scaledBuffer,
                             nil,
                             vImage_Flags(kvImageNoFlags))
        
        return scaledBuffer
    }()
    
    /*
     The 1-channel, 8-bit vImage buffer used as the operation destination.
     */
    lazy var destinationBuffer: vImage_Buffer = {
        guard var destinationBuffer = try? vImage_Buffer(width: Int(sourceBuffer.width),
                                              height: Int(sourceBuffer.height),
                                              bitsPerPixel: 8) else {
                                                fatalError("Unable to create destination buffers.")
        }
        
        return destinationBuffer
    }()
        
    public func getGrayscaleImage(from image: UIImage) -> UIImage {
        self.cgImage = image.cgImage
        
        // Declare the three coefficients that model the eye's sensitivity
        // to color.
        let redCoefficient: Float = 0.2126
        let greenCoefficient: Float = 0.7152
        let blueCoefficient: Float = 0.0722
        
        // Create a 1D matrix containing the three luma coefficients that
        // specify the color-to-grayscale conversion.
        let divisor: Int32 = 0x1000
        let fDivisor = Float(divisor)
        
        var coefficientsMatrix = [
            Int16(redCoefficient * fDivisor),
            Int16(greenCoefficient * fDivisor),
            Int16(blueCoefficient * fDivisor)
        ]
        
        // Use the matrix of coefficients to compute the scalar luminance by
        // returning the dot product of each RGB pixel and the coefficients
        // matrix.
        let preBias: [Int16] = [0, 0, 0, 0]
        let postBias: Int32 = 0
        
        vImageMatrixMultiply_ARGB8888ToPlanar8(&sourceBuffer,
                                               &destinationBuffer,
                                               &coefficientsMatrix,
                                               divisor,
                                               preBias,
                                               postBias,
                                               vImage_Flags(kvImageNoFlags))
        
        // Create a 1-channel, 8-bit grayscale format that's used to
        // generate a displayable image.
        guard let monoFormat = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            colorSpace: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            renderingIntent: .defaultIntent) else {
                return image
        }
        
        // Create a Core Graphics image from the grayscale destination buffer.
        let result = try? destinationBuffer.createCGImage(format: monoFormat)
        
        // Display the grayscale result.
        guard let imageResult = result else {
            return image
        }
        
        return UIImage(cgImage: imageResult)
    }
}

