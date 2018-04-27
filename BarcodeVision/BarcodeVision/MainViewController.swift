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
    private var locations = [VNRectangleObservation]()
    private var lpns = [VNRectangleObservation]()
    private var testImage = UIImage(named: "QRRack")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addTestImage()
    }
    
    private func addTestImage() {
        guard let image = testImage else { return }
        inputImageView.image = image
        inputImageView.contentMode = .scaleToFill
    }
    
    private func detectTestImage() {
        guard let image = testImage else { return }
        let barcodeRequest = getBarcodeRequest()
        detectBarcode(in: image, and: barcodeRequest)
    }
    
    @IBAction private func analyzeImage() {
        detectTestImage()
    }

}

// MARK: - Vision
extension MainViewController {
    
    private func getBarcodeRequest() -> VNDetectBarcodesRequest {
        return VNDetectBarcodesRequest(completionHandler: { [unowned self] (request, error) in
            guard let results = request.results, error == nil else {
                // TODO: handle no barcodes found
                return
            }
            self.processBarcodeResults(results)
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
    
    private func processBarcodeResults(_ results: [Any]) {
        for result in results {
            guard let barcode = result as? VNBarcodeObservation else { continue }
            guard let payloadString = barcode.payloadStringValue else { continue }
            guard let rect = result as? VNRectangleObservation else { continue }
            
            print(payloadString, terminator: "\n\n")

            if payloadString.isLocation() {
                self.locations.append(rect)
                self.draw(box: rect, color: UIColor.blue)
            }
            else {
                self.lpns.append(rect)
                self.draw(box: rect, color: UIColor.red)
            }
        }
    }
    
}

// MARK: - Rendering
extension MainViewController {
    
    func draw(box: VNRectangleObservation, color: UIColor) {
        let x = box.topLeft.x * inputImageView.frame.size.width
        let y = (1 - box.topLeft.y) * inputImageView.frame.size.height
        let width = (box.topRight.x - box.bottomLeft.x) * inputImageView.frame.size.width
        let height = (box.topLeft.y - box.bottomLeft.y) * inputImageView.frame.size.height
        
        let layer = CALayer()
        layer.borderWidth = 2
        layer.frame = CGRect(x: x - layer.borderWidth, y: y - layer.borderWidth, width: width + layer.borderWidth * 2, height: height + layer.borderWidth * 2)
        layer.borderColor = color.cgColor
        inputImageView.layer.addSublayer(layer)
    }
    
}
