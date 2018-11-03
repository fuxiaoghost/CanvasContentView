//
//  CanvasContentView.swift
//  CanvasTest
//
//  Created by Kirn on 2018/10/27.
//  Copyright © 2018 Kirn. All rights reserved.
//

import UIKit

class CanvasContentView: UIView {
    /// 画布
    var canvasView: UIView? = nil {
        didSet {
            if self.canvasView != nil {
                self.addSubview(self.canvasView!);
                self.canvasView?.backgroundColor = UIColor.white;
                // 移动到容器中心
                self.canvasView!.center = CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2);
                // transform归零，设置为单位矩阵
                self.canvasView!.transform = CGAffineTransform.identity;
            }
        }
    }
    
    /// 最小缩放比
    var minScale: CGFloat = 0.1;
    
    /// 最大缩放比
    var maxScale: CGFloat = 40;
    
    weak var delegate: CanvasContentViewDelegate?;
    
    // 手势参数
    private var gestureParams:(from: CGPoint, lastTouchs: Int, rotation: CGFloat, scale: CGFloat, translation: CGPoint) = (CGPoint.zero, 0 , 0, 1, CGPoint.zero);
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.backgroundColor = UIColor(white: 0.125, alpha: 1);
        // 双指点击
        let doubleTouchesGesture = UITapGestureRecognizer(target: self, action: #selector(gestureRecognizer(gesture:)));
        doubleTouchesGesture.numberOfTapsRequired = 1;
        doubleTouchesGesture.numberOfTouchesRequired = 2;
        doubleTouchesGesture.delegate = self;
        self.addGestureRecognizer(doubleTouchesGesture);
        
        // 三指点击
        let tripleTouchesGesture = UITapGestureRecognizer(target: self, action: #selector(gestureRecognizer(gesture:)));
        tripleTouchesGesture.numberOfTapsRequired = 1;
        tripleTouchesGesture.numberOfTouchesRequired = 3;
        tripleTouchesGesture.delegate = self;
        self.addGestureRecognizer(tripleTouchesGesture);
        
        // 缩放
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(gestureRecognizer(gesture:)));
        pinchGesture.delegate = self;
        self.addGestureRecognizer(pinchGesture);
        
        // 移动
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(gestureRecognizer(gesture:)));
        panGesture.minimumNumberOfTouches = 2;
        panGesture.delegate = self;
        self.addGestureRecognizer(panGesture);
        
        // 旋转
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(gestureRecognizer(gesture:)));
        rotationGesture.delegate = self;
        self.addGestureRecognizer(rotationGesture)
    }
}

extension CanvasContentView {
    func scaleToFit(animated: Bool) {
        if let view = self.canvasView {
            let scaleX = self.bounds.size.width / view.bounds.size.width;
            let scaleY = self.bounds.size.height / view.bounds.size.height;
            let scale = min(scaleX, scaleY);
            self.gestureParams.scale = scale;
            if animated {
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 10, options: .curveEaseOut, animations: {
                    self.resetTransform();
                }, completion: nil);
            }else {
                self.resetTransform();
            }
        }
    }
}

extension CanvasContentView {
    private func resetTransform() {
        if self.canvasView != nil {
            self.canvasView!.center = CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2);
            self.canvasView!.transform = CGAffineTransform.identity.scaledBy(x: self.gestureParams.scale, y: self.gestureParams.scale);
        }
    }
    
    private func scaleAt(center: CGPoint, scale: CGFloat) {
        // x' = Sx(x - x0) + x0
        // y' = Sy(y - y0) + y0
        let formerScale = self.gestureParams.scale;
        self.gestureParams.scale = scale * self.gestureParams.scale;
        self.gestureParams.scale = min(max(self.minScale, self.gestureParams.scale), self.maxScale);
        let currentScale = self.gestureParams.scale/formerScale;
        
        let x = self.canvasView!.center.x;
        let y = self.canvasView!.center.y;
        let x1 = currentScale * (x - center.x) + center.x;
        let y1 = currentScale * (y - center.y) + center.y;
        self.canvasView!.center = CGPoint(x: x1, y: y1);
        self.canvasView!.transform =  CGAffineTransform.identity.rotated(by: self.gestureParams.rotation).scaledBy(x: self.gestureParams.scale, y: self.gestureParams.scale);
    }
    
    private func rotateAt(center: CGPoint, rotation: CGFloat) {
        self.gestureParams.rotation = self.gestureParams.rotation + rotation;
        // x = (x1 - x0)cosθ - (y1 - y0)sinθ + x0
        // y = (y1 - y0)cosθ + (x1 - x0)sinθ + y0
        let x1 = self.canvasView!.center.x;
        let y1 = self.canvasView!.center.y;
        let x0 = center.x;
        let y0 = self.bounds.size.height - center.y;
        let x = (x1 - x0) * cos(rotation) - (y1 - y0) * sin(rotation) + x0
        let y = (y1 - y0) * cos(rotation) + (x1 - x0) * sin(rotation) + y0;
        
        self.canvasView!.center = CGPoint(x: x, y: y);
        self.canvasView!.transform =  CGAffineTransform.identity.rotated(by: self.gestureParams.rotation).scaledBy(x: self.gestureParams.scale, y: self.gestureParams.scale);
    }
    
    private func translate(x: CGFloat, y: CGFloat) {
        self.gestureParams.translation = CGPoint(x: self.gestureParams.translation.x + x, y: self.gestureParams.translation.y + y);
        self.canvasView!.center = CGPoint(x: self.canvasView!.center.x + x, y: self.canvasView!.center.y + y);
    }
}

// MARK: - UIGestureRecognizerDelegate
extension CanvasContentView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true;
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer is UIPanGestureRecognizer || gestureRecognizer is UIRotationGestureRecognizer || gestureRecognizer is UIPinchGestureRecognizer) && otherGestureRecognizer is UITapGestureRecognizer {
            if otherGestureRecognizer.numberOfTouches == 3 {
                return false;
            }
            return true;
        }
        return false;
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true;
    }
}

// MARK: - Gestures
extension CanvasContentView {
    @objc func gestureRecognizer(gesture: UIGestureRecognizer) {
        if self.canvasView != nil {
            switch gesture {
            case is UIPinchGestureRecognizer:
                let pinchGesture = gesture as! UIPinchGestureRecognizer;
                if pinchGesture.state == .began || pinchGesture.state == .changed {
                    // 计算缩放的中心点和缩放比例，每次缩放的比例需要累计
                    var center = pinchGesture.location(in: self);
                    if pinchGesture.numberOfTouches == 2 {
                        let center0 = pinchGesture.location(ofTouch: 0, in: self);
                        let center1 = pinchGesture.location(ofTouch: 1, in: self);
                        center = CGPoint(x: (center0.x + center1.x)/2, y: (center0.y + center1.y)/2);
                    }
                    self.scaleAt(center: center, scale: pinchGesture.scale);
                    pinchGesture.scale = 1;
                    self.delegate?.canvasContentView(self, scale: self.gestureParams.scale);
                }
                break;
            case is UIPanGestureRecognizer:
                let panGesture = gesture as! UIPanGestureRecognizer;
                let location = panGesture.location(in: self);
                if  panGesture.state == .began {
                    // 记录开始位置
                    self.gestureParams.from = location;
                    self.gestureParams.lastTouchs = gesture.numberOfTouches;
                }else if panGesture.state == .changed {
                    if self.gestureParams.lastTouchs != panGesture.numberOfTouches {
                        self.gestureParams.from = location;
                    }
                    // 计算偏移量
                    self.gestureParams.lastTouchs = panGesture.numberOfTouches;
                    let x = location.x - self.gestureParams.from.x;
                    let y = location.y - self.gestureParams.from.y;
                    self.gestureParams.from = location;
                    self.translate(x: x, y: y);
                    self.delegate?.canvasContentView(self, x: x, y: y);
                }
                break;
            case is UIRotationGestureRecognizer:
                let rotatioGesture = gesture as! UIRotationGestureRecognizer;
                if rotatioGesture.state == .began || rotatioGesture.state == .changed {
                    // 计算旋转的中心点和旋转角度，每次旋转的角度需要累计
                    var center = rotatioGesture.location(in: self);
                    if rotatioGesture.numberOfTouches == 2 {
                        let center0 = rotatioGesture.location(ofTouch: 0, in: self);
                        let center1 = rotatioGesture.location(ofTouch: 1, in: self);
                        center = CGPoint(x: (center0.x + center1.x)/2, y: (center0.y + center1.y)/2);
                    }
                    self.rotateAt(center: center, rotation: rotatioGesture.rotation);
                    rotatioGesture.rotation = 0;
                    self.delegate?.canvasContentView(self, rotation: self.gestureParams.rotation);
                }
                break;
            case is UITapGestureRecognizer:
                let tapGesture = gesture as! UITapGestureRecognizer;
                if tapGesture.numberOfTouches == 2 {
                    self.delegate?.canvasContentView(self, tapTouches: 2);
                }else if tapGesture.numberOfTouches == 3 {
                    self.delegate?.canvasContentView(self, tapTouches: 3);
                }
                break;
            default:
                break;
            }
        }
    }
}

protocol CanvasContentViewDelegate: class {
    func canvasContentView(_ view: CanvasContentView, scale: CGFloat);
    func canvasContentView(_ view: CanvasContentView, rotation: CGFloat);
    func canvasContentView(_ view: CanvasContentView, x: CGFloat, y: CGFloat);
    func canvasContentView(_ view: CanvasContentView, tapTouches: Int);
}
