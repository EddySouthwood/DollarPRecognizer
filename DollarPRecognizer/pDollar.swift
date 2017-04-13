//
//  pDollar.swift
//  DollarPRecognizer
//
//  Created by Ed Southwood on 13/04/2017.
//  Copyright © 2017 Ed Southwood. All rights reserved.
//

import Foundation
import UIKit

struct point {
    
    var point : CGPoint
    var strokeID : Int
    
    init() {
        point = CGPoint.zero
        strokeID = 0
    }
    
    init(point: CGPoint) {
        self.point = point //use the self bit to beable to use the same variable name
        strokeID = 0
    }
    
    init(point: CGPoint, strokeID: Int) {
        self.point = point
        self.strokeID = strokeID
    }
    
    init(point: (Double, Double), strokeID: Int) {
        self.point = CGPoint(x: point.0, y: point.1)
        self.strokeID = strokeID
    }
    
}

func translateToOrigin (points: inout [point], n: Int) -> [point] { //inout keyword allows variables passed to the function to be modified
    
    var c: CGPoint = CGPoint.zero //this becomes the centroid
    
    for p in points {
        
        c.x = c.x + p.point.x
        c.y = c.y + p.point.y
        
    }
    
    c.x = c.x/CGFloat(n)
    c.y = c.y/CGFloat(n)
    
    for index in points.indices {
        
        points[index].point.x = points[index].point.x - c.x
        points[index].point.y = points[index].point.y - c.y
        
    }
    
    return points
    
}

func scale (points: inout [point]) -> [point] {
    
    var x_min: CGFloat = CGFloat.infinity
    var x_max: CGFloat = 0
    var y_min: CGFloat = CGFloat.infinity
    var y_max: CGFloat = 0
    
    for p in points {
        
        x_min = min(x_min, p.point.x)
        y_min = min(y_min, p.point.y)
        x_max = max(x_max, p.point.x)
        y_max = max(y_max, p.point.y)
        
    }
    
    let scale = max((x_max - x_min), (y_max - y_min))
    
    for index in points.indices {
        
        points[index].point.x = (points[index].point.x - x_min)/scale
        points[index].point.y = (points[index].point.y - y_min)/scale
        
    }
    
    return points
    
}

func pathLength (points: [point]) -> CGFloat {
    
    var d : CGFloat = 0
    
    for x in points.indices {
        
        if x != 0 { //ignore first point to enable finding distance between points
            
            if points[x].strokeID == points[x-1].strokeID { //check points are in the same stroke
                
                d = d + euclidianDistance(a: points[x].point, b: points[x-1].point)
            }
        }
    }
    
    return d
}

func euclidianDistance(a: CGPoint, b: CGPoint) -> CGFloat {
    
    return (((a.x - b.x) * (a.x - b.x)) + ((a.y - b.y) * (a.y - b.y))).squareRoot()
    
}

func resample (points: inout [point], n: Int) -> [point] {
    
    let I = pathLength(points: points) / CGFloat(n - 1)
    
    var D : CGFloat = 0
    
    var d : CGFloat = 0
    
    var q = point()
    
    var newPoints = [point]()
    
    newPoints.append(points[0])
    
    var x = 0
    
    var indices = 1
    
    while x < indices {
        
        if x != 0 { //ignore first point
            
            if points[x].strokeID == points[x-1].strokeID { //check points are in the same stroke
                
                d = euclidianDistance(a: points[x-1].point, b: points[x].point)
                if ((D + d) > I) || fabs((D + d) - I) < 0.000000000001 { //required since D + d == I evaluated to false when they appeared equal due to floating point errors - this is optomised for 64bit processors
                    
                    q.point.x = points[x-1].point.x + ((I - D)/d) * (points[x].point.x - points[x-1].point.x)
                    q.point.y = points[x-1].point.y + ((I - D)/d) * (points[x].point.y - points[x-1].point.y)
                    
                    q.strokeID = points[x].strokeID
                    
                    newPoints.append(q)
                    
                    points.insert(q, at: x)
                    
                    D = 0
                } else {
                    
                    D = D + d
                    
                }
            }
        }
        
        x = x + 1
        indices = points.count
    }
    
    return newPoints
}

func normalize (points: inout [point], n: Int) {
    points = resample(points: &points, n: n)
    _ = scale(points: &points) // _ = ignores the return value of the function
    _ = translateToOrigin(points: &points, n: n)
    
}

func cloudDistance (points: [point], template: [point], n: Int, start: Int) -> CGFloat {
    
    var sum : CGFloat = 0
    
    var matched = Array(repeating: false, count: n)
    
    var i = start
    
    var min : CGFloat
    
    var d : CGFloat
    
    var index : Int = 0
    
    repeat {
        
        min = CGFloat.infinity
        
        for j in matched.indices {
            
            if !matched[j] {
                
                d = euclidianDistance(a: points[i].point, b: template[j].point)
                
                if d < min {
                    
                    min = d
                    index = j
                    
                }
                
            }
            
        }
        
        matched[index] = true
        let weight = 1 - CGFloat(((i - start + n) % n))/CGFloat(n)
        sum = sum + weight * min
        i = (i + 1) % n
        
    } while i != start
    
    return sum
    
}

func greedyCloudMatch(points: [point], template: [point], n: Int) -> CGFloat {
    
    let E = 0.5
    
    let step = Int(floor(pow(Double(n),(1-E))))
    
    var minimum = CGFloat.infinity
    
    for i in stride(from: 0, to: n, by: step) {
        
        let d1 = cloudDistance(points: points, template: template, n: n, start: i)
        let d2 = cloudDistance(points: template, template: points, n: n, start: i)
        minimum = min(minimum,d1,d2)
        
    }
    
    return minimum
    
}

// changed to give a better return result

func pRecogniser(points: inout [point], templates: [ (String , [point] ) ]) -> (String,CGFloat) {
    
    let n = 32 //this is where n is set for the rest of the functions
    normalize(points: &points, n: n)
    var score = CGFloat.infinity
    //var result : [point] = templates[0].1 //forced to avoid an error should be written over in the loop
    var result = "none"
    
    
    for i in templates.indices {
        
        //normalize(points: &templates[i].1, n: n) // this should already be done Remove later - and code can be simplified
        let d = greedyCloudMatch(points: points, template: templates[i].1, n: n)
        
        if score > d {
            
            score = d
            result = templates[i].0
            
        }
    }
    
    score = max(((2.0 - score)/2.0), 0.0)
    return (result,score)
}
