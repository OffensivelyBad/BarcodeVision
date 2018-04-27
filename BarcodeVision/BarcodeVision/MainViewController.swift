//
//  MainViewController.swift
//  BarcodeVision
//
//  Created by Shawn Roller on 4/25/18.
//  Copyright © 2018 Shawn Roller. All rights reserved.
//

import UIKit
import Vision

class MainViewController: UIViewController {

    @IBOutlet weak var inputImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        detectTestImage()
    }
    
    private func detectTestImage() {
        guard let image = UIImage(named: "Rack") else { return }
        inputImageView.image = image
        inputImageView.contentMode = .scaleToFill
        let barcodeRequest = getBarcodeRequest()
        detectBarcode(in: image, and: barcodeRequest)
    }

}

// MARK: - Vision
extension MainViewController {
    
    private func getBarcodeRequest() -> VNDetectBarcodesRequest {
        return VNDetectBarcodesRequest(completionHandler: { [unowned self] (request, error) in
            guard let results = request.results else {
                // TODO: handle no barcodes found
                return
            }
            for result in results {
                guard let barcode = result as? VNBarcodeObservation else { continue }
                print(barcode.payloadStringValue ?? "", terminator: "\n\n")
                
                if let rect = result as? VNRectangleObservation {
                    self.draw(box: rect)
                }
            }
        })
    }
    
    private func detectBarcode(in image: UIImage, and request: VNDetectBarcodesRequest) {
        guard let imageCG = image.cgImage else { return }
        let imageHandler = VNImageRequestHandler(cgImage: imageCG, options: [.properties: ""])
        do {
            try imageHandler.perform([request])
        } catch {
            // TODO: handle errors
            print("error handling image request")
        }
    }
    
}

// MARK: - Rendering
extension MainViewController {
    
    func draw(box: VNRectangleObservation) {
        let x = box.topLeft.x * inputImageView.frame.size.width
        let y = (1 - box.topLeft.y) * inputImageView.frame.size.height
        let width = (box.topRight.x - box.bottomLeft.x) * inputImageView.frame.size.width
        let height = (box.topLeft.y - box.bottomLeft.y) * inputImageView.frame.size.height
        
        let layer = CALayer()
        layer.borderWidth = 2
        layer.frame = CGRect(x: x - layer.borderWidth, y: y - layer.borderWidth, width: width + layer.borderWidth * 2, height: height + layer.borderWidth * 2)
        layer.borderColor = UIColor.red.cgColor
        inputImageView.layer.addSublayer(layer)
    }
    
}
