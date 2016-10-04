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
    
    /*notifer.addObserver(self, selector: "didRecieveGyroScopeEvent:", name: TLMMyoDidReceiveGyroscopeEventNotification, object: nil)*/
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
    helloLabel.center = self.view.center
    
    armLabel.text = "Perform the Sync Gesture"
    helloLabel.text = "Hello Myo"
    
    accelerationProgressBar.isHidden = false
    accelerationLabel.isHidden = false
  }

  func didDisconnectDevice(_ notification: Notification) {
    helloLabel.text = ""
    armLabel.text = ""
    accelerationProgressBar.isHidden = true
    accelerationLabel.isHidden = true
  }
    
    func didSyncArm(_ notification: Notification) {
        
    }
    
    func didUnSyncArm(_ notification: Notification) {
        
    }
    
    func didUnlockDevice(_ notification: Notification) {
        
    }
    
    func didLockDevice(_ notification: Notification) {
        
    }
    
    func didReceiveOrientationEvent(_ notification: Notification) {
        
    }
    
    func didReceiveAccelerometerEvent(_ notification: Notification) {
        
    }
    
    func didReceivePoseChange(_ notification: Notification) {
        
    }

  func didRecognizeArm(_ notification: Notification) {
    let eventData = notification.userInfo as Dictionary<NSString, TLMArmRecognizedEvent>
    let armEvent = eventData[kTLMKeyArmRecognizedEvent]!
    
    var arm = armEvent.arm == .Right ? "Right" : "Left"
    var direction = armEvent.xDirection == .TowardWrist ? "Towards Wrist" : "Toward Elbow"
    armLabel.text = "Arm: \(arm) X-Direction: \(direction)"
    helloLabel.textColor = UIColor.blue
    
    armEvent.myo.vibrateWithLength(.Short)
  }

  func didLoseArm(_ notification: Notification) {
    armLabel.text = "Perform the Sync Gesture"
    helloLabel.text = "Hello Myo"
    helloLabel.textColor = UIColor.black
    
    let eventData = notification.userInfo as Dictionary<NSString, TLMArmLostEvent>
    let armEvent = eventData[kTLMKeyArmLostEvent]!
    armEvent.myo.vibrateWithLength(.Short)
  }

  func didRecieveOrientationEvent(_ notification: Notification) {
    let eventData = notification.userInfo as Dictionary<NSString, TLMOrientationEvent>
    let orientationEvent = eventData[kTLMKeyOrientationEvent]!
    
    let angles = GLKitPolyfill.getOrientation(orientationEvent)
    let pitch = CGFloat(angles.pitch.radians)
    let yaw = CGFloat(angles.yaw.radians)
    let roll = CGFloat(angles.roll.radians)
    let rotationAndPerspectiveTransform:CATransform3D = CATransform3DConcat(CATransform3DConcat(CATransform3DRotate (CATransform3DIdentity, pitch, -1.0, 0.0, 0.0), CATransform3DRotate(CATransform3DIdentity, yaw, 0.0, 1.0, 0.0)), CATransform3DRotate(CATransform3DIdentity, roll, 0.0, 0.0, -1.0))
    
    // Apply the rotation and perspective transform to helloLabel.
    helloLabel.layer.transform = rotationAndPerspectiveTransform
  }

  func didRecieveAccelerationEvent(_ notification: Notification) {
    let eventData = notification.userInfo as Dictionary<NSString, TLMAccelerometerEvent>
    let accelerometerEvent = eventData[kTLMKeyAccelerometerEvent]!

    let acceleration = GLKitPolyfill.getAcceleration(accelerometerEvent);
    accelerationProgressBar.progress = acceleration.magnitude / 4.0;

    // Uncomment to show direction of acceleration
    //    let x = acceleration.x
    //    let y = acceleration.y
    //    let z = acceleration.z
    //    accelerationLabel.text = "Acceleration (\(x), \(y), \(z))"
  }

  func didChangePose(_ notification: Notification) {
    let eventData = notification.userInfo as Dictionary<NSString, TLMPose>
    currentPose = eventData[kTLMKeyPose]!
    
    switch (currentPose.type) {
    case .Fist:
      helloLabel.text = "Fist"
      helloLabel.font = UIFont(name: "Noteworthy", size: 50)
      helloLabel.textColor = UIColor.green
    case .WaveIn:
      helloLabel.text = "Wave In"
      helloLabel.font = UIFont(name: "Courier New", size: 50)
      helloLabel.textColor = UIColor.green
    case .WaveOut:
      helloLabel.text = "Wave Out";
      helloLabel.font = UIFont(name: "Snell Roundhand", size: 50)
      helloLabel.textColor = UIColor.green
    case .FingersSpread:
      helloLabel.text = "Fingers Spread";
      helloLabel.font = UIFont(name: "Chalkduster", size: 50)
      helloLabel.textColor = UIColor.green
    case .ThumbToPinky:
      self.helloLabel.text = "Thumb to Pinky";
      self.helloLabel.font = UIFont(name: "Georgia", size: 50)
      self.helloLabel.textColor = UIColor.green
    default: // .Rest or .Unknown
      helloLabel.text = "Hello Myo"
      helloLabel.font = UIFont(name: "Helvetica Neue", size: 50)
      helloLabel.textColor = UIColor.black
    }
  }

  func didRecieveGyroScopeEvent(_ notification: Notification) {
    let eventData = notification.userInfo as Dictionary<NSString, TLMGyroscopeEvent>
    let gyroEvent = eventData[kTLMKeyGyroscopeEvent]!

    let gyroData = GLKitPolyfill.getGyro(gyroEvent)
    // Uncomment to display the gyro values
    //    let x = gyroData.x
    //    let y = gyroData.y
    //    let z = gyroData.z
    //    gyroscopeLabel.text = "Gyro: (\(x), \(y), \(z))"
  }
}

