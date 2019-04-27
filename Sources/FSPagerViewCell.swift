//
//  FSPagerViewCell.swift
//  FSPagerView
//
//  Created by Wenchao Ding on 17/12/2016.
//  Copyright © 2016 Wenchao Ding. All rights reserved.
//

import UIKit
extension CALayer {
    func applySketchShadow(
        color: UIColor = .black,
        alpha: Float = 0.5,
        x: CGFloat = 0,
        y: CGFloat = 2,
        blur: CGFloat = 4,
        spread: CGFloat = 0)
    {
        shadowColor = color.cgColor
        shadowOpacity = alpha
        shadowOffset = CGSize(width: x, height: y)
        shadowRadius = blur / 2.0
        if spread == 0 {
            shadowPath = nil
        } else {
            let dx = -spread
            let rect = bounds.insetBy(dx: dx, dy: dx)
            shadowPath = UIBezierPath(rect: rect).cgPath
        }
    }
}
open class FSPagerViewCell: UICollectionViewCell , UIGestureRecognizerDelegate {
    
    /// Returns the label used for the main textual content of the pager view cell.
    @objc
    open var textLabel: UILabel? {
        if let _ = _textLabel {
            return _textLabel
        }
          let view =  UIView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))  //let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        let textLabel = UILabel(frame: view.frame) //UILabel(frame: .zero)
        textLabel.textColor = .white
        textLabel.font = UIFont.preferredFont(forTextStyle: .body)
        self.contentView.addSubview(view)
        view.addSubview(textLabel)
        
        textLabel.addObserver(self, forKeyPath: "font", options: [.old,.new], context: kvoContext)
        
        _textLabel = textLabel
        return textLabel
    }
    var isZooming = false
    var myview : UIView?
    var originalImageCenter:CGPoint?
    /// Returns the image view of the pager view cell. Default is nil.
    @objc
    open var imageView: UIImageView? {
        if let _ = _imageView {
            return _imageView
        }
        let imageView = UIImageView(frame: .zero)
        self.myview?.addSubview(imageView)
        //self.contentView.addSubview(imageView)
        _imageView = imageView
        return imageView
    }
    
    
    fileprivate weak var _textLabel: UILabel?
    fileprivate weak var _imageView: UIImageView?
    
    fileprivate let kvoContext = UnsafeMutableRawPointer(bitPattern: 0)
    fileprivate let selectionColor = UIColor(white: 0.2, alpha: 0.2)
    
    fileprivate weak var _selectedForegroundView: UIView?
    fileprivate var selectedForegroundView: UIView? {
        guard _selectedForegroundView == nil else {
            return _selectedForegroundView
        }
        guard let imageView = _imageView else {
            return nil
        }
        let view = UIView(frame: imageView.bounds)
        imageView.addSubview(view)
        _selectedForegroundView = view
        return view
    }
    
    open override var isHighlighted: Bool {
        set {
            super.isHighlighted = newValue
            if newValue {
                self.selectedForegroundView?.layer.backgroundColor = self.selectionColor.cgColor
            } else if !super.isSelected {
                self.selectedForegroundView?.layer.backgroundColor = UIColor.clear.cgColor
            }
        }
        get {
            return super.isHighlighted
        }
    }
    
    open override var isSelected: Bool {
        set {
            super.isSelected = newValue
            self.selectedForegroundView?.layer.backgroundColor = newValue ? self.selectionColor.cgColor : UIColor.clear.cgColor
        }
        get {
            return super.isSelected
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    fileprivate func commonInit() {
        self.contentView.backgroundColor = UIColor.clear
        self.backgroundColor = UIColor.clear
//        self.contentView.layer.shadowColor = UIColor.black.cgColor
//        self.contentView.layer.shadowRadius = 5
//        self.contentView.layer.shadowOpacity = 0.75
//        self.contentView.layer.shadowOffset = .zero

        myview = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        myview?.layer.cornerRadius = 8.0
        myview?.backgroundColor = UIColor.white
        myview?.layer.applySketchShadow(
            color: .black,
            alpha: 0.2,
            x: 0,
            y: 3,
            blur: 8,
            spread: 0)
        self.addSubview(myview!)
        imageView?.isUserInteractionEnabled = true
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(sender:)))
        pinch.delegate = self
        //imageView!.addGestureRecognizer(pinch)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.pan(sender:)))
        pan.delegate = self
       // imageView!.addGestureRecognizer(pan)
    }
    
    deinit {
        if let textLabel = _textLabel {
            textLabel.removeObserver(self, forKeyPath: "font", context: kvoContext)
        }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        if let imageView = _imageView {
            imageView.frame = self.contentView.bounds
        }
        if let textLabel = _textLabel {
            textLabel.superview!.frame = {
                var rect = self.contentView.bounds
                let height = textLabel.font.pointSize*1.5
                rect.size.height = height
                rect.origin.y = self.contentView.frame.height-height
                return rect
            }()
            textLabel.frame = {
                var rect = textLabel.superview!.bounds
                rect = rect.insetBy(dx: 8, dy: 0)
                rect.size.height -= 1
                rect.origin.y += 1
                return rect
            }()
        }
        if let selectedForegroundView = _selectedForegroundView {
            selectedForegroundView.frame = self.contentView.bounds
        }
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == kvoContext {
            if keyPath == "font" {
                self.setNeedsLayout()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    @objc func pinch(sender:UIPinchGestureRecognizer) {
        if sender.state == .began {
            let currentScale = imageView!.frame.size.width / imageView!.bounds.size.width
            let newScale = currentScale*sender.scale
            if newScale > 1 {
                self.isZooming = true
            }
        } else if sender.state == .changed {
            guard let view = sender.view else {return}
            let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX,
                                      y: sender.location(in: view).y - view.bounds.midY)
            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                .scaledBy(x: sender.scale, y: sender.scale)
                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
            let currentScale = imageView!.frame.size.width / imageView!.bounds.size.width
            var newScale = currentScale*sender.scale
            if newScale < 1 {
                newScale = 1
                let transform = CGAffineTransform(scaleX: newScale, y: newScale)
                imageView!.transform = transform
                sender.scale = 1
            }else {
                view.transform = transform
                sender.scale = 1
            }
        } else if sender.state == .ended {
            UIView.animate(withDuration: 0.3, animations: {
                self.imageView!.transform = CGAffineTransform.identity
            }, completion: { _ in
                self.isZooming = false
            })
        }
    }
    
    @objc func pan(sender: UIPanGestureRecognizer) {
        if self.isZooming && sender.state == .began {
            self.originalImageCenter = sender.view?.center
        } else if self.isZooming && sender.state == .changed {
            let translation = sender.translation(in: self)
            if let view = sender.view {
                view.center = CGPoint(x:view.center.x + translation.x,
                                      y:view.center.y + translation.y)
            }
            sender.setTranslation(CGPoint.zero, in: imageView!.superview)
        }
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
