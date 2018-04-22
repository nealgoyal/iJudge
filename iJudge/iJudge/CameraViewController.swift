//
//  CameraViewController.swift
//  iJudge
//
//  Created by Neal Goyal on 4/22/18.
//  Copyright © 2018 Neal Goyal. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import ProjectOxfordFace

enum PhotoType {
    case login
    case signup
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var button: UIButton!

    var captureSession = AVCaptureSession()
    var sessionOutput = AVCapturePhotoOutput()
    var previewLayer = AVCaptureVideoPreviewLayer()
    
    var usersStorageRef: StorageReference!
    var personImage: UIImage!
    var photoType: PhotoType!
    
    var actIdc: UIActivityIndicatorView!
    
    var faceFromPhoto: MPOFace!
    var faceFromFirebase: MPOFace!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let storage = Storage.storage()
        let storageRef = storage.reference(forURL: "gs://ijudge-a4983.appspot.com")
        usersStorageRef = storageRef.child("users")
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
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        if let sampleBuffer = photoSampleBuffer, let previewBuffer = photoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            
            let userID = Auth.auth().currentUser?.uid
            let imageRef = usersStorageRef.child("\(userID!).jpg")
            
            showActivityIndicator(onView: self.view)
            if photoType == PhotoType.signup{
                self.personImage = UIImage(data: dataImage)
                
                let client = MPOFaceServiceClient(subscriptionKey: "e8cd67e49d78462c83d242e9495bca21")!
                
                let data = UIImageJPEGRepresentation(self.personImage!, 0.8)
                
                client.detect(with: data!, returnFaceId: true, returnFaceLandmarks: true, returnFaceAttributes: [], completionBlock: { (faces, error) in
                    
                    if error != nil {
                        print(error!)
                        return
                    }
                    
                    if (faces!.count) > 1 || (faces!.count) == 0 {
                        print("too many or not at all faces")
                        self.failLogin()
                        return
                    }
                    
                    let uploadTask = imageRef.putData(dataImage, metadata: nil, completion: { (metadata, error) in
                        if error != nil {
                            print(error!)
                            return
                        }
                    })
                    
                    uploadTask.resume()
                    
                })
                
                captureSession.stopRunning()
                previewLayer.removeFromSuperlayer()
                
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Logged")
                self.present(vc, animated: true, completion:  nil)
                
            }else if photoType == PhotoType.login {
                //verify the user
                self.personImage = UIImage(data: dataImage)
                
                captureSession.stopRunning()
                
                imageRef.downloadURL(completion: { (url, error) in
                    
                    if error != nil {
                        print(error!)
                        return
                    }
                    
                    
                    self.verify(withURL: url!.absoluteString)
                    
                })
            }
            
        }
    }
    
    func verify(withURL url: String) {
        
        let client = MPOFaceServiceClient(subscriptionKey: "e8cd67e49d78462c83d242e9495bca21")!
        
        let data = UIImageJPEGRepresentation(self.personImage!, 0.8)
        
        
        client.detect(with: data, returnFaceId: true, returnFaceLandmarks: true, returnFaceAttributes: [], completionBlock: { (faces, error) in
            
            if error != nil {
                print(error!)
                return
            }
            
            if (faces!.count) > 1 || (faces!.count) == 0 {
                print("too many or not at all faces")
                self.failLogin()
                self.actIdc.stopAnimating()
                return
            }
            
            self.faceFromPhoto = faces![0]
            
            
            client.detect(withUrl: url, returnFaceId: true, returnFaceLandmarks: true, returnFaceAttributes: [], completionBlock: { (faces, error) in
                if error != nil {
                    print(error!)
                    return
                }
                
                self.faceFromFirebase = faces![0]
                
                client.verify(withFirstFaceId: self.faceFromPhoto.faceId, faceId2: self.faceFromFirebase.faceId, completionBlock: { (result, error) in
                    
                    
                    if error != nil{
                        print(error!)
                        return
                    }
                    
                    self.actIdc.stopAnimating()
                    if result!.isIdentical {
                        // THE PERSON IS THE SAME
                        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Logged")
                        self.present(vc, animated: true, completion: nil)
                    }else {
                        self.failLogin()
                    }
                    
                    
                    
                })
                
            })
            
            
            
        })
        
    }
    
    func showActivityIndicator(onView: UIView) {
        let container: UIView = UIView()
        container.frame = onView.frame
        container.center = onView.center
        container.backgroundColor = UIColor(white: 0, alpha: 0.8)
        
        let loadingView: UIView = UIView()
        loadingView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        loadingView.center = onView.center
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        
        
        actIdc = UIActivityIndicatorView()
        actIdc.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        actIdc.hidesWhenStopped = true
        actIdc.activityIndicatorViewStyle = .whiteLarge
        actIdc.center = CGPoint(x: loadingView.frame.size.width / 2, y: loadingView.frame.size.height / 2)
        
        loadingView.addSubview(actIdc)
        container.addSubview(loadingView)
        onView.addSubview(container)
        
        actIdc.startAnimating()
    }
    
    func failLogin() {
        // THE PERSON IS NOT THE SAME
        let alert = UIAlertController(title: "Failed Login", message: "Not same person", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: { (action) in
            let logvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Login")
            self.present(logvc, animated: true, completion: nil)
        })
        
        alert.addAction(action)
        do {
            try Auth.auth().signOut()
        }catch{
        }
        self.present(alert, animated: true, completion: nil)
        
    }

    @IBAction func takePhoto(_ sender: Any) {
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String : previewPixelType, kCVPixelBufferWidthKey as String : 160, kCVPixelBufferHeightKey as String : 160]
        
        settings.previewPhotoFormat = previewFormat
        sessionOutput.capturePhoto(with: settings, delegate: self)
    }
    
}
