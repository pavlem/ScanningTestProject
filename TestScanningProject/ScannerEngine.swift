//
//  ScannerEngine.swift
//  ScanAndGo
//
//  Created by Pavle Mijatovic on 11/9/18.
//  Copyright © 2018 Salling Group. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

enum ScanningType: Int {
    case barCode
    case qrCode
    case barAndQRCode
}

// MARK: - Protocols
protocol ScannerEngineDelegate: class {
    func handleMetaDataObjects(metadataObjects: [Any])
    func handle(scannedString: String)
    func noInfoScanned()
}

extension ScannerEngineDelegate {
    func handleMetaDataObjects(metadataObjects: [Any]) {}
    func handle(scannedString: String) {}
    func noInfoScanned() {}
}

// MARK: - Class
class ScannerEngine: NSObject {
    
    // MARK: - API
    weak var delegate: ScannerEngineDelegate?
    
    func start() {
        startRunning()
    }
    
    func stop() {
        stopRunning()
    }
    
    func stopDetection() {
        isScannerRunning = false
    }
    
    func startDetection() {
        isScannerRunning = true
    }
    
    func setScanner(onViewController viewController: UIViewController, scanningVideoLayer: UIView?, scanningTimeOut: Double? = nil) {
        setScanner(onViewController: viewController, videoLayer: scanningVideoLayer, scanningTimeOut: scanningTimeOut)
    }

    // MARK: - Properties
    // MARK: Vars
    private var scanningTimeOut: Double?
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var scanningType: ScanningType
    private var isScannerTimeoutInProgress = false
    private var isScannerRunning = true
    // MARK: Calculated
    private var barCodeTypes: [AVMetadataObject.ObjectType] {
        return [.ean8, .ean13, .pdf417, .code128, .interleaved2of5]
    }

    // MARK: - Inits
    init(scanningType: ScanningType) {
        self.scanningType = scanningType
    }
}

// MARK: - ScannerEngine + Scanner
extension ScannerEngine {
    
    func getSupportedCodeTypes(scanningType: ScanningType) -> [AVMetadataObject.ObjectType] {
        switch scanningType {
        case .barCode:
            return barCodeTypes
        case .qrCode:
            return [.qr]
        case .barAndQRCode:
            return barCodeTypes + [.qr]
        }
    }
    
    // MARK: Scanner Handling
    private func setScanner(onViewController scannerVC: UIViewController, videoLayer: UIView?, scanningTimeOut: Double? = nil) {
        let view = scannerVC.view!
        
        // Setting ScanningTimeOut if there is any
        if let timeout = scanningTimeOut {
            self.scanningTimeOut = timeout
        }
        
        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video as the media type parameter.
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            guard captureDevice != nil else { return }
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            
            // Initialize the captureSession object.
            captureSession = AVCaptureSession()
            
            // Set the input device on the capture session.
            captureSession?.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = getSupportedCodeTypes(scanningType: self.scanningType)
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = videoLayer == nil ? view.layer.bounds : videoLayer!.layer.bounds
            
            // add videoPreviewLayer to custom view or to the main view of our VC
            if let videoLayerLocal = videoLayer {
                
                if !view.subviews.contains(videoLayerLocal) {
                    view.addSubview(videoLayerLocal)
                }
                
                videoLayerLocal.layer.addSublayer(videoPreviewLayer!)
                view.sendSubviewToBack(videoLayerLocal)
            } else {
                view.layer.addSublayer(videoPreviewLayer!)
            }
            
            // Start video capture.
            captureSession?.startRunning()
        } catch {
            print(error)
        }
    }
    
    private func stopRunning() {
        captureSession?.stopRunning()
    }
    
    private func startRunning() {
        guard captureSession?.isRunning == false else { return }
        captureSession?.startRunning()
    }
    
    private func isQRSessionStopped() -> Bool {
        return !isSessionRunning()
    }
    
    private func isSessionRunning() -> Bool {
        if let captureSession = self.captureSession {
            return captureSession.isRunning ? true : false
        }
        return false
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension ScannerEngine: AVCaptureMetadataOutputObjectsDelegate {    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard isScannerRunning else { return }
        guard isScannerTimeoutInProgress == false else { return }
        
        if metadataObjects.count > 0 {
            if let scanningTimeOut = scanningTimeOut {
                waitFor(timeInterval: scanningTimeOut)
            }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            delegate?.handleMetaDataObjects(metadataObjects: metadataObjects)
            let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            if let stringValue = metadataObj.stringValue {
                delegate?.handle(scannedString: stringValue)
            }
        } else {
            delegate?.noInfoScanned()
        }
    }
    
    func waitFor(timeInterval: Double) {
        isScannerTimeoutInProgress = true
        DispatchQueue.global(qos: .userInitiated).async {
            Thread.sleep(forTimeInterval: timeInterval)
            self.isScannerTimeoutInProgress = false
        }
    }
}
