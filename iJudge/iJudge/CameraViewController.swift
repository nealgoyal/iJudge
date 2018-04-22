//
//  CameraViewController.swift
//  iJudge
//
//  Created by Neal Goyal on 4/22/18.
//  Copyright © 2018 Neal Goyal. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var button: UIButton!
    
    var captureSession = AVCaptureSession()
    var sessionOutput = AVCapturePhotoOutput()
    var previewLayer = AVCaptureVideoPreviewLayer()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let deviceSession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInTelephotoCamera, .builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        
        for device in (deviceSession.devices) {
            if device.position == AVCaptureDevice.Position.front {
                do {
                    let input = try AVCaptureDeviceInput(device: device)
                    if captureSession.canAddInput(input) {
                        captureSession.addInput(input)
                        
                        if captureSession.canAddOutput(sessionOutput) {
                            captureSession.addOutput(sessionOutput)
                            
                            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                            previewLayer.connection?.videoOrientation = .portrait
                            
                            cameraView.layer.addSublayer(previewLayer)
                            cameraView.addSubview(button)
                            
                            previewLayer.position = CGPoint (x: self.cameraView.frame.width / 2, y: self.cameraView.frame.height / 2)
                            previewLayer.bounds = cameraView.frame
                            
                            captureSession.startRunning()
                        }
                    }
                    
                } catch let avError {
                    print(avError)
                }
                
            }
        }
        
    }

    @IBAction func takePhoto(_ sender: Any) {
    }
    
}
