//
//  FirstViewController.swift
//  UrgentPath
//
//  Created by Jiashun Gou on 4/3/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {
    @IBOutlet weak var planeLocXLabel: UITextField!
    @IBOutlet weak var planeLocYLabel: UITextField!
    @IBOutlet weak var planeLocZLabel: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hello_first()
        var timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func hello_first() {
        //let x = helloworld2()
        //print(x)
    }
    
    // must be internal or public.
    @objc func update() {
        planeLocXLabel.text = String(tmp)
        tmp += 1
    }


}

