//
//  ScannerVC.swift
//  TestScanningProject
//
//  Created by Pavle Mijatovic on 9/18/19.
//  Copyright © 2019 Pavle Mijatovic. All rights reserved.
//

import UIKit
import AVFoundation

class ScannerVC: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var videoLayer: UIView!
    @IBOutlet weak var resultLbl: UILabel!
    
    // MARK: Constants
    private let scanningTimeOut = 1.5
    // MARK: Var
    private var scannerEngine: ScannerEngine?
    private var videoLayerView: UIView?
    
    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.layoutSubviews() // to get the correct frames
        setScannerEngine()
    }
    
    // MARK: - Helper
    private func setScannerEngine() {
        
        // 1. Initialize ScannerEngine with: qrCode, barCode or barAndQRCode
        scannerEngine = ScannerEngine(scanningType: .barCode)
        
        // 2. Set delegate for feedback (scanning data to read)
        scannerEngine?.delegate = self
        
        // 3. Set scanner's:
        // # view controller,
        // # layer where to show the video stream and
        // # timeout between scanning.
        
        // for no timeout do not set anything, in this case the scannig will be done all the time
        // for scanningVideoLayer = nil, scanning video will be shown across the entire screen
        // if you wish some cornerRadius, set it on "videoLayer" before
        
        scannerEngine?.setScanner(onViewController: self, scanningVideoLayer: videoLayer, scanningTimeOut: self.scanningTimeOut)
    }
    
    // MARK: - Actions
    @IBAction func stopScanner(_ sender: Any) {
        scannerEngine?.stop()
        resultLbl.text = "RESULT"
    }
    
    @IBAction func startScanner(_ sender: Any) {
        scannerEngine?.start()
    }
    
    @IBAction func stopBarCodeDetection(_ sender: Any) {
        scannerEngine?.stopDetection()
    }
    
    @IBAction func startBarCodeDeteection(_ sender: Any) {
        scannerEngine?.startDetection()
    }
}

// MARK: - ScannerEngineDelegate
extension ScannerVC: ScannerEngineDelegate {
    func handle(scannedString: String) {
        print(scannedString)
        resultLbl.text = scannedString
    }
    
    func noInfoScanned() {
        print("noInfoScanned()")
    }
}
