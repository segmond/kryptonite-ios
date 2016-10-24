//
//  ApproveController.swift
//  Kryptonite
//
//  Created by Alex Grinman on 10/23/16.
//  Copyright © 2016 KryptCo. All rights reserved.
//

import UIKit
import AVFoundation

class ApproveController:UIViewController {
    
    @IBOutlet weak var contentView:UIView!
    @IBOutlet weak var contentVisible:NSLayoutConstraint!
    
    @IBOutlet weak var resultView:UIView!
    @IBOutlet weak var resultViewHeight:NSLayoutConstraint!
    @IBOutlet weak var resultLabel:UILabel!

    
    @IBOutlet weak var deviceLabel:UILabel!
    @IBOutlet weak var commandLabel:UILabel!
    
    @IBOutlet weak var checkBox:M13Checkbox!
    @IBOutlet weak var arcView:UIView!

    var rejectColor = UIColor(hex: 0xFF6361)
    
    var heightCover:CGFloat = 174.0
    
    var request:Request?
    var session:Session?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 0)
        contentView.layer.shadowOpacity = 0.2
        contentView.layer.shadowRadius = 3
        contentView.layer.masksToBounds = false
        
        checkBox.animationDuration = 1.0
        
        resultViewHeight.constant = 0
        resultLabel.alpha = 0
        
        if let session = session, let request = request {
            deviceLabel.text = session.pairing.displayName.uppercased()
            commandLabel.text = "$ " + (request.sign?.command ?? "Unknown Command")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.animate(withDuration: 1.3) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimatingLoader()

        
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    
    //MARK: Animation
    
    
    func startAnimatingLoader() {
        let frameSize = arcView.frame.size
        let lineWidth = checkBox.checkmarkLineWidth
    
        let innerCircle = CAShapeLayer()
        innerCircle.path = UIBezierPath(ovalIn: CGRect(x: 0.0, y: 0.0, width: frameSize.width, height: frameSize.height)).cgPath
        
        innerCircle.lineWidth = lineWidth
        innerCircle.strokeStart = 0.1
        innerCircle.strokeEnd = 0.3
        innerCircle.lineCap = kCALineCapRound
        innerCircle.fillColor = UIColor.clear.cgColor
        innerCircle.strokeColor = UIColor.app.cgColor
        arcView.layer.addSublayer(innerCircle)
        
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotateAnimation.toValue = CGFloat(M_PI*2.0)
        rotateAnimation.duration = 1.0
        rotateAnimation.isCumulative = true
        rotateAnimation.repeatCount = .infinity
        arcView.layer.add(rotateAnimation, forKey: "rotation")

    }
    
    
    //MARK: Response
    @IBAction func approveOnce() {
        if #available(iOS 10.0, *) {
            UIImpactFeedbackGenerator(style: UIImpactFeedbackStyle.heavy).impactOccurred()
        }
        
        guard let request = request, let session = session else {
            log("no valid request or session", .error)
            return
        }
        
        do {
            let resp = try Silo.shared.lockResponseFor(request: request, session: session, signatureAllowed: true)
            try Silo.shared.send(session: session, response: resp, completionHandler: nil)
            
        } catch (let e) {
            log("send error \(e)", .error)
            self.showWarning(title: "Error", body: "Could not approve request. \(e)")
            return
        }
        
        self.resultLabel.text = "Allowed once".uppercased()
        
        UIView.animate(withDuration: 0.3, animations: {
            
            self.resultLabel.alpha = 1.0
            self.arcView.alpha = 0
            self.resultViewHeight.constant = self.heightCover
            self.view.layoutIfNeeded()
            
            
        }) { (_) in
            
            self.checkBox.toggleCheckState(true)
                dispatchAfter(delay: 1.5) {
                    self.animateDismiss()
                }
        }
        

    }
    
    @IBAction func approveOneHour() {
        
        if #available(iOS 10.0, *) {
            UIImpactFeedbackGenerator(style: UIImpactFeedbackStyle.heavy).impactOccurred()
        }
        
        guard let request = request, let session = session else {
            log("no valid request or session", .error)
            return
        }
        
        do {
            Policy.allowFor(time: Policy.Interval.oneHour)
            let resp = try Silo.shared.lockResponseFor(request: request, session: session, signatureAllowed: true)
            try Silo.shared.send(session: session, response: resp, completionHandler: nil)
            
        } catch (let e) {
            log("send error \(e)", .error)
            self.showWarning(title: "Error", body: "Could not approve request. \(e)")
            return
        }
        
        self.resultLabel.text = "Allowed for 1 hour".uppercased()
        
        UIView.animate(withDuration: 0.3, animations: {
            
            self.resultLabel.alpha = 1.0
            self.arcView.alpha = 0
            self.resultViewHeight.constant = self.heightCover
            self.view.layoutIfNeeded()
            
            
        }) { (_) in
            self.checkBox.toggleCheckState(true)
            dispatchAfter(delay: 1.5) {
                self.animateDismiss()
            }
        }

    }
    
    
    
    @IBAction func dismissReject() {

        if #available(iOS 10.0, *) {
            UIImpactFeedbackGenerator(style: UIImpactFeedbackStyle.heavy).impactOccurred()
        }
        
        do {
            if let request = request, let session = session {
                let resp = try Silo.shared.lockResponseFor(request: request, session: session, signatureAllowed: false)
                try Silo.shared.send(session: session, response: resp, completionHandler: nil)
            }
            
        } catch (let e) {
            log("send error \(e)", .error)
        }
        
        self.resultLabel.text = "Rejected".uppercased()
        self.resultView.backgroundColor = rejectColor
        self.checkBox.secondaryCheckmarkTintColor = rejectColor
        self.checkBox.tintColor = rejectColor
        
        UIView.animate(withDuration: 0.3, animations: {
            self.resultLabel.alpha = 1.0
            self.arcView.alpha = 0
            self.resultViewHeight.constant = self.heightCover
            self.view.layoutIfNeeded()
            
        }) { (_) in
            self.checkBox.setCheckState(M13Checkbox.CheckState.mixed, animated: true)
            dispatchAfter(delay: 1.5) {
                self.animateDismiss()
            }
        }

    }
    
    func animateDismiss() {
        UIView.animate(withDuration: 0.1) {
            self.view.backgroundColor = UIColor.clear
        }
        
        self.dismiss(animated: true, completion: nil)
    }
}
