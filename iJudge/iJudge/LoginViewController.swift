//
//  LoginViewController.swift
//  iJudge
//
//  Created by Neal Goyal on 4/22/18.
//  Copyright © 2018 Neal Goyal. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var pwField: UITextField!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func loginPressed(_ sender: Any) {
        guard emailField.text != "", pwField.text != "" else {return}
        
        
        Auth.auth().signIn(withEmail: emailField.text!, password: pwField.text!, completion: { (user, error) in
            if error != nil {
                print(error!)
                return
            }
            
            let cameraVC = UIStoryboard(name: "Camera", bundle: nil).instantiateInitialViewController() as! CameraViewController
            
            cameraVC.photoType = PhotoType.login
            self.present(cameraVC, animated: true, completion: nil)
            
        })
    }
    

}
