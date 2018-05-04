//
//  MainViewController.swift
//  BarcodeVision
//
//  Created by Shawn Roller on 4/25/18.
//  Copyright © 2018 Shawn Roller. All rights reserved.
//

import UIKit
import Vision

struct CaseContents {
    var caseName: String
    var rect: VNRectangleObservation
    var lpns: [String]
}

class MainViewController: UIViewController {

    enum Mode {
        case cycleCount, xray
    }
    
    @IBOutlet weak var inputImageView: UIImageView!
    private var locations = [VNRectangleObservation]()
    private var lpns = [VNRectangleObservation]()
    private var casesWithContents = [CaseContents]()
    private var activityIndicator = UIActivityIndicatorView()
    private var loadingView = UIView()
    private var mode = Mode.xray
    private var loading = false {
        didSet { toggleLoading(on: loading) }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addButtons()
        addTestImage()
    }
    
    private func addButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Import", style: .plain, target: self, action: #selector(MainViewController.importPhoto))
    }
    
    @objc private func importPhoto() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    private func addTestImage() {
        let testImage = UIImage(named: "QRRack")
        guard let image = testImage else { return }
        inputImageView.image = image
        inputImageView.contentMode = .scaleToFill
    }
    
    private func detectBarcodes(inImage image: UIImage) {
        loading = true
        DispatchQueue.background(delay: 0, background: {
            let barcodeRequest = self.getBarcodeRequest()
            self.detectBarcode(in: image, and: barcodeRequest)
        }) {
            DispatchQueue.main.async {
                switch self.mode {
                case .cycleCount:
                    self.loading = false
                    self.analyzeBarcodes()
                case .xray:
                    self.analyzeContents(forIndex: 0)
                }
            }
        }
    }
    
    private func analyzeContents(forIndex index: Int) {
        guard index < casesWithContents.count else {
            self.loading = false
            displayContents()
            return
        }
        let theCase = casesWithContents[index]
        getContents(forCase: theCase) { (contents) in
            self.casesWithContents[index] = contents
            self.analyzeContents(forIndex: index + 1)
        }
    }
    
    private func getContents(forCase theCase: CaseContents, completion: (_ contents: CaseContents) -> Void) {
        // This would be an API call to get the data
        completion(CaseContents(caseName: theCase.caseName, rect: theCase.rect, lpns: ["LPN1234567890", "LPN0987654321", "LPN1111111111", "LPN2222222222"]))
    }
    
    private func displayContents() {
        for theCase in casesWithContents {
            let lpnX = theCase.rect.bottomRight.x
            var lpnY = theCase.rect.bottomRight.y
            for lpn in theCase.lpns {
                let lpnHeight: CGFloat = 50
                let lpnWidth: CGFloat = 100
                let point = getTranslatedPoint(fromPoint: CGPoint(x: lpnX, y: lpnY))
                let lpnLabel = UILabel(frame: CGRect(x: point.x, y: point.y, width: lpnWidth, height: lpnHeight))
                lpnLabel.text = lpn
                view.addSubview(lpnLabel)
                lpnY += lpnHeight
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
                    nearestLocation = location.middlePoint()
                } else {
                    nearestLocation = newDistance < distanceToLocation ? location.middlePoint() : nearestLocation
                    distanceToLocation = newDistance < distanceToLocation ? newDistance : distanceToLocation
                }
            }
            drawLine(from: lpn.middleBottomPoint(), to: nearestLocation)
        }
        
        for rect in lpns {
            self.draw(box: rect, color: UIColor.red)
        }
        for rect in locations {
            self.draw(box: rect, color: UIColor.blue)
        }
    }
    
    private func getTranslatedPoint(fromPoint point: CGPoint) -> CGPoint {
        let x = point.x * inputImageView.frame.size.width
        let y = (1 - point.y) * inputImageView.frame.size.height
        return CGPoint(x: x, y: y)
    }
    
    private func drawLine(from: CGPoint, to: CGPoint) {
        let fromPoint = getTranslatedPoint(fromPoint: from)
        let toPoint = getTranslatedPoint(fromPoint: to)
        
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: fromPoint)
        linePath.addLine(to: toPoint)
        line.path = linePath.cgPath
        line.strokeColor = UIColor.cyan.cgColor
        line.lineWidth = 1
        inputImageView.layer.addSublayer(line)
    }
    
    private func clearImageLayers() {
        inputImageView.layer.sublayers = nil
        lpns.removeAll(keepingCapacity: false)
        locations.removeAll(keepingCapacity: false)
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
                let caseWithContents = CaseContents(caseName: payloadString, rect: rect, lpns: [])
                self.casesWithContents.append(caseWithContents)
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

// MARK: - PickerControllerDelegate
extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else { return }
        clearImageLayers()
        self.inputImageView.image = image
        dismiss(animated: true)
    }
    
}

