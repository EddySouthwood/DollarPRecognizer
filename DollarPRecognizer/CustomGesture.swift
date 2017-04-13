//
//  CustomGesture.swift
//  DollarPRecognizer
//
//  Created by Ed Southwood on 13/04/2017.
//  Copyright © 2017 Ed Southwood. All rights reserved.
//


import Foundation
import UIKit
import UIKit.UIGestureRecognizerSubclass

class CustomGesture: UIGestureRecognizer{
    
    // Multi-stroke
    
    public var enableMultipleStrokes: Bool = true
    public var allowedTimeBetweenMultipleStrokes: TimeInterval = 0.5
    private(set) var timer: Timer?
    
    // initialise variables
    
    public var startPoint: CGPoint = CGPoint.zero
    public var dollarPoints = [point]()
    public var strokeID = -1
    public var gestureResult: (number: String, score: CGFloat) = ("",0.0)
    
    // clean up
    
    public var pointA = CGPoint.zero
    public var pointB = CGPoint.zero
    
    override public func reset() {
        
        super.reset()
        
        strokeID = -1
        dollarPoints = [point]()
        startPoint = CGPoint.zero
        pointA = CGPoint.zero
        pointB = CGPoint.zero
        invalidateTimer()
        
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        
        invalidateTimer()
        
        if let touch = touches.first {
            startPoint = touch.location(in: self.view)
            strokeID = strokeID + 1
            dollarPoints.append(point(point: startPoint, strokeID: strokeID))
            
        }
        
        if state == .possible {
            state = .began
        }
        
    }
    
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        
        super.touchesMoved(touches, with: event)
        
        if let touch = touches.first {
            
            let nextPoint = touch.location(in: self.view)
            dollarPoints.append(point(point: nextPoint, strokeID: strokeID))
            
        }
        
        if dollarPoints.count > 1 {
            
            let pointsAandB = Array(dollarPoints.suffix(2))
            
            if (pointsAandB[0]).strokeID == (pointsAandB[1]).strokeID {
                
                pointA = (pointsAandB[0]).point
                pointB = (pointsAandB[1]).point
                
            }
        }
        
        state = .changed
        
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        
        super.touchesEnded(touches, with: event)
        
        if enableMultipleStrokes {
            timer = Timer.scheduledTimer(timeInterval: allowedTimeBetweenMultipleStrokes,
                                         target: self,
                                         selector: #selector(timerDidFire(_:)),
                                         userInfo: nil,
                                         repeats: false)
        } else { //Single stroke mode
            gestureResult = pRecogniser(points: &dollarPoints, templates: templates)
            state = .ended
        }
        
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        
        super.touchesCancelled(touches, with: event)
        
        state = .ended
        
    }
    
    //MARK: Timer code
    
    @objc private func timerDidFire(_ timer: Timer) {
        
        if dollarPoints.count > 1 {
            gestureResult = pRecogniser(points: &dollarPoints, templates: templates)
        }
        
        state = .ended
    }
    
    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    
}
