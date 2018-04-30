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
    private var activityIndicator = UIActivityIndicatorView()
    private var loadingView = UIView()
    private var loading = false {
        didSet { toggleLoading(on: loading) }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addTestImage()
    }
    
    private func addTestImage() {
        let testImage = UIImage(named: "QRRack")
        guard let image = testImage else { return }
        inputImageView.image = image
        inputImageView.contentMode = .scaleToFill
    }
    
    private func detectBarcodes(inImage image: UIImage) {
//        loading = true
        DispatchQueue.background(delay: 0, background: {
            let barcodeRequest = self.getBarcodeRequest()
            self.detectBarcode(in: image, and: barcodeRequest)
        }) {
            DispatchQueue.main.async {
                self.loading = false
                self.analyzeBarcodes()
            }
        }
    }
    
    private func analyzeBarcodes() {
        for lpn in lpns {
            var nearestLocation = CGPoint.zero
            var distanceToLocation: CGFloat = 0
            for location in locations {
                guard lpn.bottomLeft.y > location.topLeft.y else { continue }
                let newDistance = distance(from: lpn.bottomLeft, to: location.topLeft)
                if distanceToLocation == 0 {
                    distanceToLocation = newDistance
                    nearestLocation = location.topLeft
                } else {
                    nearestLocation = newDistance < distanceToLocation ? location.topLeft : nearestLocation
                    distanceToLocation = newDistance < distanceToLocation ? newDistance : distanceToLocation
                }
            }
            drawLine(from: lpn.bottomLeft, to: nearestLocation)
        }
        
        for rect in lpns {
            self.draw(box: rect, color: UIColor.red)
        }
        for rect in locations {
            self.draw(box: rect, color: UIColor.blue)
        }
    }
    
    private func drawLine(from: CGPoint, to: CGPoint) {
        let fromX = from.x * inputImageView.frame.size.width
        let fromY = (1 - from.y) * inputImageView.frame.size.height
        let fromPoint = CGPoint(x: fromX, y: fromY)
        
        let toX = to.x * inputImageView.frame.size.width
        let toY = (1 - to.y) * inputImageView.frame.size.height
        let toPoint = CGPoint(x: toX, y: toY)
        
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: fromPoint)
        linePath.addLine(to: toPoint)
        line.path = linePath.cgPath
        line.strokeColor = UIColor.cyan.cgColor
        line.lineWidth = 1
        inputImageView.layer.addSublayer(line)
    }
    
    @IBAction private func analyzeImage() {
        guard let image = inputImageView.image else { return }
        detectBarcodes(inImage: image)
    }
    
    func toggleLoading(on: Bool) {
        if on {
            guard activityIndicator.superview == nil, loadingView.superview == nil else { return }
            loadingView = UIView(frame: view.frame)
            loadingView.backgroundColor = UIColor.darkGray
            loadingView.alpha = 0.5
            view.addSubview(loadingView)
            
            activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            activityIndicator.color = UIColor.darkGray
            activityIndicator.center = view.center
            view.addSubview(activityIndicator)
            activityIndicator.startAnimating()
        }
        else {
            guard activityIndicator.superview != nil, loadingView.superview != nil else { return }
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
            
            loadingView.removeFromSuperview()
        }
    }
    
    func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
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
            }
            else {
                self.lpns.append(rect)
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
