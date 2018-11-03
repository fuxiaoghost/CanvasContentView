//
//  ViewController.swift
//  CanvasTest
//
//  Created by Kirn on 2018/10/27.
//  Copyright © 2018 Kirn. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let canvasView = CanvasView.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100));
        canvasView.backgroundColor = UIColor.white;
        canvasView.isMultipleTouchEnabled = true;
        let canvasContentView = CanvasContentView.init(frame: self.view.bounds);
        canvasContentView.canvasView = canvasView;
        self.view.addSubview(canvasContentView);
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            canvasContentView.scaleToFit(animated: true);
        }
    }


}

