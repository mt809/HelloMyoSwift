import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var accelerationProgressBar: UIProgressView!
    @IBOutlet weak var helloLabel: UILabel!
    @IBOutlet weak var accelerationLabel: UILabel!
    @IBOutlet weak var armLabel: UILabel!
    @IBOutlet weak var gyroscopeLabel: UILabel!
    @IBOutlet weak var lockLabel: UILabel!
    
    var currentPose: TLMPose!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let notifer = NotificationCenter.default
        
        // Data notifications are received through NSNotificationCenter.
        // Posted whenever a TLMMyo connects
        notifer.addObserver(self, selector: #selector(ViewController.didConnectDevice(_:)), name: NSNotification.Name.TLMHubDidConnectDevice, object: nil)
        
        // Posted whenever a TLMMyo disconnects.
        notifer.addObserver(self, selector: #selector(ViewController.didDisconnectDevice(_:)), name: NSNotification.Name.TLMHubDidDisconnectDevice, object: nil)
        
        // Posted whenever the user does a successful Sync Gesture.
        notifer.addObserver(self, selector: #selector(ViewController.didSyncArm(_:)), name: NSNotification.Name.TLMMyoDidReceiveArmSyncEvent, object: nil)
        
        // Posted whenever Myo loses sync with an arm (when Myo is taken off, or moved enough on the user's arm).
        notifer.addObserver(self, selector: #selector(ViewController.didUnSyncArm(_:)), name: NSNotification.Name.TLMMyoDidReceiveArmUnsyncEvent, object: nil)
        
        // Posted whenever Myo is unlocked and the application uses TLMLockingPolicyStandard.
        notifer.addObserver(self, selector: #selector(ViewController.didUnlockDevice(_:)), name: NSNotification.Name.TLMMyoDidReceiveUnlockEvent, object: nil)
        
        // Posted whenever Myo is locked and the application uses TLMLockingPolicyStandard.
        notifer.addObserver(self, selector: #selector(ViewController.didLockDevice(_:)), name: NSNotification.Name.TLMMyoDidReceiveLockEvent, object: nil)
        
        // Posted when a new orientation event is available from a TLMMyo. Notifications are posted at a rate of 50 Hz.
        notifer.addObserver(self, selector: #selector(ViewController.didReceiveOrientationEvent(_:)), name: NSNotification.Name.TLMMyoDidReceiveOrientationEvent, object: nil)
        
        // Posted when a new accelerometer event is available from a TLMMyo. Notifications are posted at a rate of 50 Hz.
        notifer.addObserver(self, selector: #selector(ViewController.didReceiveAccelerometerEvent(_:)), name: NSNotification.Name.TLMMyoDidReceiveAccelerometerEvent, object: nil)
        
        // Posted when a new pose is available from a TLMMyo.
        notifer.addObserver(self, selector: #selector(ViewController.didReceivePoseChange(_:)), name: NSNotification.Name.TLMMyoDidReceivePoseChanged, object: nil)
        
        notifer.addObserver(self, selector: #selector(ViewController.didRecieveGyroScopeEvent(_:)), name: NSNotification.Name.TLMMyoDidReceiveGyroscopeEvent, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didTapSettings(_ sender: AnyObject) {
        // Settings view must be in a navigation controller when presented
        let controller = TLMSettingsViewController.settingsInNavigationController()
        present(controller!, animated: true, completion: nil)
    }
    
    // MARK: NSNotificationCenter Methods
    
    func didConnectDevice(_ notification: Notification) {
        // Access the connected device.
        let userinfo = notification.userInfo
        let myo:TLMMyo = (userinfo![kTLMKeyMyo] as? TLMMyo)!
        print("Connected to %@.", myo.name);
        
        // Align our label to be in the center of the view.
        helloLabel.center = self.view.center
        
        // Set the text of the armLabel to "Perform the Sync Gesture".
        armLabel.text = "Perform the Sync Gesture"
        
        // Set the text of our helloLabel to be "Hello Myo".
        helloLabel.text = "Hello Myo"
        
        // Show the acceleration progress bar
        accelerationProgressBar.isHidden = false
        accelerationLabel.isHidden = false
    }
    
    func didDisconnectDevice(_ notification: Notification) {
        // Access the disconnected device.
        let userinfo = notification.userInfo
        let myo:TLMMyo = (userinfo![kTLMKeyMyo] as? TLMMyo)!
        print("Disconnected from %@.", myo.name);
        
        // Remove the text from our labels when the Myo has disconnected.
        helloLabel.text = ""
        armLabel.text = ""
        lockLabel.text = ""
        
        // Hide the acceleration progress bar.
        accelerationProgressBar.isHidden = true
        accelerationLabel.isHidden = true
    }
    
    func didSyncArm(_ notification: Notification) {
        // Retrieve the arm event from the notification's userInfo with the kTLMKeyArmSyncEvent key.
        let userinfo = notification.userInfo
        let armEvent:TLMArmSyncEvent = userinfo![kTLMKeyArmSyncEvent] as! TLMArmSyncEvent
        
        let arm = armEvent.arm == .right ? "Right" : "Left"
        let direction = armEvent.xDirection == .towardWrist ? "Towards Wrist" : "Toward Elbow"
        armLabel.text = "Arm: \(arm) X-Direction: \(direction)"
        helloLabel.textColor = UIColor.blue
        lockLabel.text = "Locked"
        
        armEvent.myo.vibrate(with: .short)
    }
    
    func didUnSyncArm(_ notification: Notification) {
        
        armLabel.text = "Perform the Sync Gesture"
        helloLabel.text = "Hello Myo"
        helloLabel.textColor = UIColor.black
        lockLabel.text = ""
        
        let userInfo = notification.userInfo
        let armEvent:TLMArmUnsyncEvent = userInfo![kTLMKeyArmUnsyncEvent]! as! TLMArmUnsyncEvent
        armEvent.myo.vibrate(with: .short)
    }
    
    func didUnlockDevice(_ notification: Notification) {
        // Update the label to reflect Myo's lock state.
        lockLabel.text = "Unlocked"
    }
    
    func didLockDevice(_ notification: Notification) {
        // Update the label to reflect Myo's lock state.
        lockLabel.text = "Locked"
    }
    
    func didReceiveOrientationEvent(_ notification: Notification) {
        // Retrieve the orientation from the NSNotification's userInfo with the kTLMKeyOrientationEvent key.
        let userInfo = notification.userInfo
        let orientationEvent:TLMOrientationEvent = userInfo![kTLMKeyOrientationEvent] as! TLMOrientationEvent
        
        // Create Euler angles from the quaternion of the orientation.
        let angles = GLKitPolyfill.getOrientation(orientationEvent)
        let pitch = CGFloat((angles?.pitch.radians)!)
        let yaw = CGFloat((angles?.yaw.radians)!)
        let roll = CGFloat((angles?.roll.radians)!)
        
        // Next, we want to apply a rotation and perspective transformation based on the pitch, yaw, and roll.
        let rotationAndPerspectiveTransform:CATransform3D = CATransform3DConcat(CATransform3DConcat(CATransform3DRotate (CATransform3DIdentity, pitch, -1.0, 0.0, 0.0), CATransform3DRotate(CATransform3DIdentity, yaw, 0.0, 1.0, 0.0)), CATransform3DRotate(CATransform3DIdentity, roll, 0.0, 0.0, -1.0))
        
        // Apply the rotation and perspective transform to helloLabel.
        helloLabel.layer.transform = rotationAndPerspectiveTransform
    }
    
    func didReceiveAccelerometerEvent(_ notification: Notification) {
        // Retrieve the accelerometer event from the NSNotification's userInfo with the kTLMKeyAccelerometerEvent.
        let userInfo = notification.userInfo
        let accelerometerEvent:TLMAccelerometerEvent = userInfo![kTLMKeyAccelerometerEvent] as! TLMAccelerometerEvent
        
        // Get the acceleration vector from the accelerometer event.
        let accelerationVector:TLMVector3 = accelerometerEvent.vector
        
        // Calculate the magnitude of the acceleration vector.
        let magnitude = TLMVector3Length(accelerationVector);
        
        accelerationProgressBar.progress = magnitude / 8.0; //4.0 was
        
        // Note you can also access the x, y, z values of the acceleration (in G's) like below
            let x = accelerationVector.x
            let y = accelerationVector.x
            let z = accelerationVector.x
            accelerationLabel.text = "Acceleration (\(x), \(y), \(z))"
    }
    
    func didReceivePoseChange(_ notification: Notification) {
        // Retrieve the pose from the NSNotification's userInfo with the kTLMKeyPose key.
        let userInfo = notification.userInfo
        let pose:TLMPose = userInfo![kTLMKeyPose] as! TLMPose
        currentPose = pose
        
        // Handle the cases of the TLMPoseType enumeration, and change the color of helloLabel based on the pose we receive.
        switch (pose.type) {
        case .unknown:
            break
        case .rest:
            break
        case .fist:
            helloLabel.text = "Fist"
            helloLabel.font = UIFont(name: "Noteworthy", size: 50)
            helloLabel.textColor = UIColor.green
            break
        case .waveIn:
            helloLabel.text = "Wave In"
            helloLabel.font = UIFont(name: "Courier New", size: 50)
            helloLabel.textColor = UIColor.green
            break
        case .waveOut:
            helloLabel.text = "Wave Out";
            helloLabel.font = UIFont(name: "Snell Roundhand", size: 50)
            helloLabel.textColor = UIColor.green
            break
        case .fingersSpread:
            helloLabel.text = "Fingers Spread";
            helloLabel.font = UIFont(name: "Chalkduster", size: 50)
            helloLabel.textColor = UIColor.green
            break
        case .doubleTap:
            self.helloLabel.text = "Hello Myo";
            self.helloLabel.font = UIFont(name: "Georgia", size: 50)
            self.helloLabel.textColor = UIColor.green
            break
        }
        
        // Unlock the Myo whenever we receive a pose
        if (pose.type == .unknown || pose.type == .rest) {
            
            // Causes the Myo to lock after a short period.
            pose.myo.unlock(with: .timed)
        }
        else {
            // Keeps the Myo unlocked until specified.
            // This is required to keep Myo unlocked while holding a pose, but if a pose is not being held, use
            // TLMUnlockTypeTimed to restart the timer.
            pose.myo.unlock(with: .hold)
            // Indicates that a user action has been performed.
            pose.myo.indicateUserAction()
        }
    }
    
    func didRecieveGyroScopeEvent(_ notification: Notification) {
        let userInfo = notification.userInfo
        let gyroEvent:TLMGyroscopeEvent = userInfo![kTLMKeyGyroscopeEvent] as! TLMGyroscopeEvent
        
        let gyroData = gyroEvent.vector
        // Uncomment to display the gyro values
            let x = gyroData.x
            let y = gyroData.y
            let z = gyroData.z
            gyroscopeLabel.text = "Gyro: (\(x), \(y), \(z))"
    }
}

