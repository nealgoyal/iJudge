//
//  SignupViewController.swift
//  iJudge
//
//  Created by Neal Goyal on 4/22/18.
//  Copyright © 2018 Neal Goyal. All rights reserved.
//

import UIKit
import Firebase

class SignupViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var pwField: UITextField!
    @IBOutlet weak var pwConField: UITextField!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func signupPressed(_ sender: Any) {
        
        guard emailField.text != "", pwField.text != "", pwConField.text != "" else { return}
        
        
        if pwField.text == pwConField.text {
            
            Auth.auth().createUser(withEmail: emailField.text!, password: pwField.text!, completion: { (user, error) in
                
                if error != nil{
                    print(error!)
                    return
                }
                
                let cameraVC = UIStoryboard(name: "Camera", bundle: nil).instantiateInitialViewController() as! CameraViewController
                
                cameraVC.photoType = .signup
                self.present(cameraVC, animated: true, completion: nil)
                
            })
            
            
        } else {
            let alert = UIAlertController(title: "Password does not match", message: "Please put correct password on both fields", preferredStyle: .alert)
            
            let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
            
            alert.addAction(cancel)
            present(alert, animated: true, completion: nil)
        }
        
    }
    

}
