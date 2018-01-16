//
//  PJPopViewManager.swift
//  SparkCampus
//
//  Created by piaojin on 2018/1/6.
//  Copyright © 2018年 ywyw.piaojin. All rights reserved.
//

import UIKit

public enum PopFromDirection {
    case bottom
    case top
    case left
    case right
}

public struct PopViewMargin {
    var left: CGFloat = 0.0
    var right: CGFloat = 0.0
    var bottom: CGFloat = 0.0
    var top: CGFloat = 0.0
    var height: CGFloat = 0.0
    var isInCenter: Bool = false
    
    init() {
        self.init(height: 0.0)
    }
    
    init(height: CGFloat, isInCenter: Bool = false) {
        self.init(left: 0.0, right: 0.0, bottom: 0.0, top: 0.0, height: height, isInCenter: isInCenter)
    }
    
    init(left: CGFloat, right: CGFloat, height: CGFloat = 0.0, isInCenter: Bool = false) {
        self.init(left: left, right: right, bottom: 0.0, top: 0.0, height: height, isInCenter: isInCenter)
    }
    
    init(left: CGFloat, right: CGFloat, top: CGFloat, height: CGFloat = 0.0, isInCenter: Bool = false) {
        self.init(left: left, right: right, bottom: 0.0, top: top, height: height, isInCenter: isInCenter)
    }
    
    init(left: CGFloat, right: CGFloat, bottom: CGFloat, height: CGFloat = 0.0, isInCenter: Bool = false) {
        self.init(left: left, right: right, bottom: bottom, top: 0.0, height: height, isInCenter: isInCenter)
    }
    
    init(left: CGFloat, right: CGFloat, bottom: CGFloat, top: CGFloat, height: CGFloat = 0.0, isInCenter: Bool = false) {
        self.left = left
        self.right = right
        self.bottom = bottom
        self.top = top
        self.height = height
        self.isInCenter = isInCenter
    }
}

public struct PopViewOptions {
    var margin: PopViewMargin = PopViewMargin()
    var popFromDirection: PopFromDirection = .bottom
}

@objc protocol PopViewManagerDelegate: NSObjectProtocol {
    @objc optional func willShow()
    @objc optional func didShow()
    @objc optional func willClose()
    @objc optional func didClose()
    @objc optional func close()
}

extension PopViewManagerDelegate {
    func close() {
        PJPopViewManager.shared.close()
    }
}

open class PJPopViewManager {
    
    static var shared: PJPopViewManager = PJPopViewManager()
    
    weak var rootView: UIView?
    
    weak var showView: UIView?
    
    weak var coverView: UIView?
    
    weak var delegate: PopViewManagerDelegate?
    
    var transform: CGAffineTransform?
    
    var isShow: Bool = false
    
    var coverViewAlpha: CGFloat = 0.5 {
        didSet {
            self.coverView?.alpha = coverViewAlpha
        }
    }
    
    var coverViewColor: UIColor = .black {
        didSet {
            self.coverView?.backgroundColor = coverViewColor
        }
    }
}

extension PJPopViewManager {
    
    func show(_ showView: UIView, option: PopViewOptions = PopViewOptions()) {
        self.show(showView, inView: nil, coverView: nil, option: option)
    }
    
    func show(_ showView: UIView, inView: UIView?, option: PopViewOptions = PopViewOptions()) {
        self.show(showView, inView: inView, coverView: nil, option: option, showDuration: 0.3, isShowCoverView: true)
    }
    
    func show(_ showView: UIView, coverView: UIView?, option: PopViewOptions = PopViewOptions()) {
        self.show(showView, inView: nil, coverView: coverView, option: option)
    }
    
    func show(_ showView: UIView, inView: UIView?, coverView: UIView?, option: PopViewOptions = PopViewOptions()) {
        self.show(showView, inView: inView, coverView: coverView, option: option, showDuration: 0.3, isShowCoverView: true)
    }
    
    func show(_ showView: UIView, inView: UIView?, coverView: UIView?, option: PopViewOptions?, showDuration: TimeInterval = 0.3, isShowCoverView: Bool = true) {
        if self.isShow {
            return
        }
        self.delegate?.willShow?()
        if let rootView = inView {
            self.rootView = rootView
        } else {
            self.rootView = UIApplication.shared.keyWindow
        }
        
        if (self.rootView?.frame)! == .zero {
            print("warn: rootView frame is zero")
        }
        
        //蒙层单独创建,防止多次调用错乱
        if isShowCoverView {
            let tempCoverView = coverView != nil ? coverView! : UIView()
            if coverView == nil {
                tempCoverView.backgroundColor = self.coverViewColor
                tempCoverView.alpha = self.coverViewAlpha
            }
            tempCoverView.translatesAutoresizingMaskIntoConstraints = false
            self.rootView?.addSubview(tempCoverView)
            tempCoverView.leftAnchor.constraint(equalTo: (self.rootView?.leftAnchor)!).isActive = true
            tempCoverView.rightAnchor.constraint(equalTo: (self.rootView?.rightAnchor)!).isActive = true
            tempCoverView.topAnchor.constraint(equalTo: (self.rootView?.topAnchor)!).isActive = true
            tempCoverView.bottomAnchor.constraint(equalTo: (self.rootView?.bottomAnchor)!).isActive = true
            tempCoverView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapCoverView))
            tempCoverView.addGestureRecognizer(tap)
            self.coverView = tempCoverView
        }
        
        self.showView = showView
        var p: PopViewOptions = PopViewOptions()
        if let op = option {
            p = op
            if op.margin.height == 0.0 {
                p.margin.height = showView.frame.size.height
            }
        } else {
            p.margin.height = showView.frame.size.height
        }

        self.rootView?.addSubview(self.showView!)
        self.showView?.translatesAutoresizingMaskIntoConstraints = false
        self.showView?.isHidden = true
        self.prepareOutScreen(showView: self.showView!, option: p)
        self.showView?.isHidden = false
        UIView.animate(withDuration: showDuration) {
            self.showView?.transform = CGAffineTransform.identity
        }
        self.isShow = true
        self.delegate?.didShow?()
    }
    
    func prepareOutScreen(showView: UIView, option: PopViewOptions) {
        
        var translationX: CGFloat = 0.0
        var translationY: CGFloat = 0.0
        self.showView?.heightAnchor.constraint(equalToConstant: option.margin.height).isActive = true
        showView.leftAnchor.constraint(equalTo: (self.rootView?.leftAnchor)!, constant: option.margin.left).isActive = true
        showView.rightAnchor.constraint(equalTo: (self.rootView?.rightAnchor)!, constant: -option.margin.right
            ).isActive = true
        switch option.popFromDirection {
        case .bottom, .top:
            if option.popFromDirection == .bottom {
                var maxBottom = option.margin.bottom
                if option.margin.isInCenter {
                    showView.centerYAnchor.constraint(equalTo: (self.rootView?.centerYAnchor)!).isActive = true
                    maxBottom = (self.rootView?.frame.size.height)! / 2.0
                } else {
                    showView.bottomAnchor.constraint(equalTo: (self.rootView?.bottomAnchor)!, constant: -option.margin.bottom).isActive = true
                }
                translationY = maxBottom + option.margin.height
            } else {
                var maxTop = option.margin.top
                if option.margin.isInCenter {
                    showView.centerYAnchor.constraint(equalTo: (self.rootView?.centerYAnchor)!).isActive = true
                    maxTop = (self.rootView?.frame.size.height)! / 2.0
                } else {
                    showView.topAnchor.constraint(equalTo: (self.rootView?.topAnchor)!, constant: -option.margin.top).isActive = true
                }
                translationY = -(maxTop + option.margin.height)
            }
            break
            //左右方向的情况,showView的width以left,right的间隔为准,并且必须居中
        case .left, .right:
            showView.centerYAnchor.constraint(equalTo: (self.rootView?.centerYAnchor)!).isActive = true
            if option.popFromDirection == .left {
                translationX = -(self.rootView?.bounds.size.width)! + option.margin.right
            } else {
                translationX = (self.rootView?.bounds.size.width)! - option.margin.left
            }
            break
        }
        self.transform = CGAffineTransform(translationX: translationX,y: translationY)
        showView.transform = self.transform!
    }
    
    func close(_ closeDuration: TimeInterval = 0.3) {
        self.delegate?.willClose?()
        UIView.animate(withDuration: closeDuration, animations: {
            self.coverView?.isHidden = true
            self.showView?.transform = self.transform!
        }) { (finished) in
            self.showView?.removeFromSuperview()
            self.coverView?.removeFromSuperview()
            self.showView = nil
            self.coverView = nil
            self.rootView = nil
            self.transform = nil
            self.isShow = false
        }
        self.delegate?.didClose?()
    }
    
    @objc func tapCoverView() {
        if self.delegate != nil {
            self.delegate?.close()
        } else {
            self.close()
        }
    }
}
