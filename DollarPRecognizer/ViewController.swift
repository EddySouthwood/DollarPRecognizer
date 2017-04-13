//
//  ViewController.swift
//  DollarPRecognizer
//
//  Created by Ed Southwood on 13/04/2017.
//  Copyright © 2017 Ed Southwood. All rights reserved.
//


import UIKit

class ViewController: UIViewController, UITextFieldDelegate{
    
    private(set) var timer: Timer?
    
    @IBOutlet weak var newTemplate: UITextField!
    @IBOutlet weak var gestureInputArea: UIView!
    @IBOutlet weak var recognitionResult: UILabel!
    
    var recognizer: CustomGesture!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        newTemplate.adjustsFontSizeToFitWidth = true
        
        recognizer = CustomGesture(target: self, action: #selector(ViewController.draw))
        
        gestureInputArea.addGestureRecognizer(recognizer)
        
        self.newTemplate.delegate = self
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func draw(sender: CustomGesture) {
        // Very Hacky drawing implimentation
        
        if sender.pointA != CGPoint.zero || sender.pointB != CGPoint.zero {
            
            addLineTo(fromPoint: sender.pointA, toPoint: sender.pointB, view: gestureInputArea)
            
        }
        
        if self.newTemplate.text! == "" {
            
            if sender.state == .ended {
                
                if sender.gestureResult.score > 0.1 {
                    recognitionResult.text = sender.gestureResult.number + " with score of \(sender.gestureResult.score)"
                } else {
                    recognitionResult.text = "not recognised"
                }
                timer = Timer.scheduledTimer(timeInterval: 0.8,
                                             target: self,
                                             selector: #selector(timerDidFire(_:)),
                                             userInfo: nil,
                                             repeats: false)
            }
        } else{
            if sender.state == .ended {
                
                if sender.dollarPoints.count > 1 { //catches bug when exiting keyboard and making template with one point
                    
                    templates.append((self.newTemplate.text!, sender.dollarPoints))
                    
                    recognitionResult.text = self.newTemplate.text! + " added to templates!"
                    
                    timer = Timer.scheduledTimer(timeInterval: 0.5,
                                                 target: self,
                                                 selector: #selector(timerDidFire(_:)),
                                                 userInfo: nil,
                                                 repeats: false)
                    
                    self.newTemplate.text! = ""
                }
                
                self.view.endEditing(true) //closes keyboard
            }
        }
        
    }
    
    func addLineTo(fromPoint start: CGPoint, toPoint end:CGPoint, view: UIView) {
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: start)
        linePath.addLine(to: end)
        line.path = linePath.cgPath
        line.strokeColor = UIColor.red.cgColor
        line.lineWidth = 3
        line.lineJoin = kCALineJoinRound
        view.layer.addSublayer(line)
    }
    
    func removeAllLinesFromView(view: UIView) {
        view.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }
    
    // Timer for auto delete:
    
    @objc private func timerDidFire(_ timer: Timer) {
        recognitionResult.text = ""
        removeAllLinesFromView(view: gestureInputArea)
    }
    
    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    
}
