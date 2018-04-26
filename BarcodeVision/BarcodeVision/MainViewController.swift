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
    
    // Vision properties
    private var barcodeRequest = VNDetectBarcodesRequest()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }

}

// MARK: - Vision
extension MainViewController {
    
    private func setupBarcodeRequest() {
        barcodeRequest = VNDetectBarcodesRequest(completionHandler: { (request, error) in
            guard let results = request.results else {
                // TODO: handle no barcodes found
                return
            }
            for result in results {
                guard let barcode = result as? VNBarcodeObservation else { continue }
                print(barcode.payloadStringValue ?? "", terminator: "\n\n")
                
                if let rect = result as? VNRectangleObservation {
                    // TODO: draw a box around the barcode
                }
            }
        })
    }
    
}
