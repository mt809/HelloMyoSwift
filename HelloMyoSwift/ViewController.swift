import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var recStatus: UIImageView!      //shows microphone image audio is being recorded
    @IBOutlet weak var computer: UIImageView!
    @IBOutlet weak var iphone: UIImageView!
    @IBOutlet weak var lockimg: UIImageView!
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var lastPose: UIImageView!
    @IBOutlet weak var vhf: UIImageView!            //imagesViews for each type of gesture
    @IBOutlet weak var vhfs: UIImageView!
    @IBOutlet weak var hdt: UIImageView!
    @IBOutlet weak var hwi: UIImageView!
    @IBOutlet weak var hwo: UIImageView!
    @IBOutlet weak var hfs: UIImageView!
    @IBOutlet weak var hf: UIImageView!
    @IBOutlet weak var mdt: UIImageView!
    @IBOutlet weak var mwi: UIImageView!
    @IBOutlet weak var mfs: UIImageView!
    @IBOutlet weak var mwo: UIImageView!
    @IBOutlet weak var mf: UIImageView!
    @IBOutlet weak var ldt: UIImageView!
    @IBOutlet weak var lwi: UIImageView!
    @IBOutlet weak var lfs: UIImageView!
    @IBOutlet weak var lwo: UIImageView!
    @IBOutlet weak var lf: UIImageView!
    @IBOutlet weak var ipAddressTF: UITextField!
    @IBOutlet weak var portTF: UITextField!
    @IBOutlet weak var lastpitchL: UILabel!
    
    let tr = SpeechT()
    let speechSynthesizer = Speaker()
    
    var pitch: CGFloat!                             //set by pose event on start (holds instantaneous pitch when a new pose begins)
    var iniPitch: CGFloat!                          //set by an orientation event
    var currentPose: TLMPose!
    var host: Int!
    var lock: Bool!                                 //lock variable used when computer is the set as the target
    var tosend = ""                                 //used to hold next message to be sent (only used when computer is the target)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TLMHub.shared().shouldNotifyInBackground = true
        TLMHub.shared().shouldSendUsageData = false
        self.ipAddressTF.delegate = self
        self.portTF.delegate = self
        let notifer = NotificationCenter.default
        self.pitch = 0
        self.host = 0
        self.lock = true
        self.iniPitch = 0
        tr.onTranscriptionCompletion = {
            [unowned self]
            transcription in
            
            self.textView.text = transcription
            var pre = "sp+"
            
            if self.tr.extmov == true {
                pre = "q+"
                self.tr.extmov = false
            }
            let toSend = pre + transcription
            self.sendcmd(text: toSend)
            
            //let instruction = transcription.components(separatedBy: " ")
            // Parse the string into individual Instructions
            
        }
        
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
        lockimg.image = #imageLiteral(resourceName: "locked.PNG")
        iphone.image = #imageLiteral(resourceName: "ipho2sol.png")
        computer.image = #imageLiteral(resourceName: "bcomp2.png")
        textView.text = "make a speech command..."
        
    }
    
    func sendcmd(text: String){
        let word = "http://" + ipAddressTF.text! + ":" + portTF.text!
        var request = URLRequest(url: URL(string: word)!)
        request.httpMethod = "POST"
        let postString = "cm" + text
        print(postString)
        request.httpBody = postString.data(using: .utf8)
        let task
            = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {                                                 // check for fundamental networking error
                    print("error=\(error)")
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                    print("statusCode should be 200, but is \(httpStatus.statusCode)")
                    print("response = \(response)")
                }
                
                let responseString = String(data: data, encoding: .utf8)
                print("responseString = \(responseString)")
                if responseString != "Received" {
                    self.speechSynthesizer.speak(responseString!)
                    
                }
                
        }
        task.resume()
        
    }
    
    func didDisconnectDevice(_ notification: Notification) {
        // Access the disconnected device.
        let userinfo = notification.userInfo
        let myo:TLMMyo = (userinfo![kTLMKeyMyo] as? TLMMyo)!
        print("Disconnected from %@.", myo.name);
        lockimg.image = #imageLiteral(resourceName: "notconn.png")
        lastPose.image = #imageLiteral(resourceName: "blankDark.png")
        lastpitchL.text = ""
        iphone.image = #imageLiteral(resourceName: "ipho2solgrey.png")
        computer.image = #imageLiteral(resourceName: "greycomp.png")
        textView.text = "Connect a Myo..."
        // Remove the text from our labels when the Myo has disconnected.
    }
    
    func didSyncArm(_ notification: Notification) {
        // Retrieve the arm event from the notification's userInfo with the kTLMKeyArmSyncEvent key.
        let userinfo = notification.userInfo
        let armEvent:TLMArmSyncEvent = userinfo![kTLMKeyArmSyncEvent] as! TLMArmSyncEvent
        
        //let arm = armEvent.arm == .right ? "Right" : "Left"
        //let direction = armEvent.xDirection == .towardWrist ? "Towards Wrist" : "Toward Elbow"
        
        
        armEvent.myo.vibrate(with: .short)
    }
    
    func didUnSyncArm(_ notification: Notification) {
        
        //armLabel.text = "Perform the Sync Gesture"
        //helloLabel.text = "Hello Myo"
        //helloLabel.textColor = UIColor.black
        //lockLabel.text = ""
        
        let userInfo = notification.userInfo
        let armEvent:TLMArmUnsyncEvent = userInfo![kTLMKeyArmUnsyncEvent]! as! TLMArmUnsyncEvent
        armEvent.myo.vibrate(with: .short)
    }
    
    func didUnlockDevice(_ notification: Notification) {
        // Update the label to reflect Myo's lock state.
        //lockLabel.text = "Unlocked"
        lockimg.image = #imageLiteral(resourceName: "unlocked.png")
    }
    
    func didLockDevice(_ notification: Notification) {
        // Update the label to reflect Myo's lock state.
        //lockLabel.text = "Locked"
        lockimg.image = #imageLiteral(resourceName: "locked.PNG")
    }
    
    func didReceiveOrientationEvent(_ notification: Notification) {
        // Retrieve the orientation from the NSNotification's userInfo with the kTLMKeyOrientationEvent key.
        let userInfo = notification.userInfo
        let orientationEvent:TLMOrientationEvent = userInfo![kTLMKeyOrientationEvent] as! TLMOrientationEvent
        
        // Create Euler angles from the quaternion of the orientation.
        let angles = GLKitPolyfill.getOrientation(orientationEvent)
        let pitch = CGFloat((angles?.pitch.radians)!)
        //let yaw = CGFloat((angles?.yaw.radians)!)
        //let roll = CGFloat((angles?.roll.radians)!)
        
        // Next, we want to apply a rotation and perspective transformation based on the pitch, yaw, and roll.
        self.iniPitch = pitch
        // Apply the rotation and perspective transform to helloLabel.
        //helloLabel.layer.transform = rotationAndPerspectiveTransform
    }
    
    func didReceiveAccelerometerEvent(_ notification: Notification) {
        // Retrieve the accelerometer event from the NSNotification's userInfo with the kTLMKeyAccelerometerEvent.
        let userInfo = notification.userInfo
        let accelerometerEvent:TLMAccelerometerEvent = userInfo![kTLMKeyAccelerometerEvent] as! TLMAccelerometerEvent
        
        // Get the acceleration vector from the accelerometer event.
        //let accelerationVector:TLMVector3 = accelerometerEvent.vector
        // Calculate the magnitude of the acceleration vector.
        //let magnitude = TLMVector3Length(accelerationVector);
        
        //accelerationProgressBar.progress = magnitude / 8.0; //4.0 was
        
        // Note you can also access the x, y, z values of the acceleration (in G's) like below
        //let x = accelerationVector.x
        //let y = accelerationVector.y
        //let z = accelerationVector.z
        //accelerationLabel.text = "Acceleration (\(x), \(y), \(z))"
    }
    
    func didReceivePoseChange(_ notification: Notification) {
        // Retrieve the pose from the NSNotification's userInfo with the kTLMKeyPose key.
        let userInfo = notification.userInfo
        let pose:TLMPose = userInfo![kTLMKeyPose] as! TLMPose
        currentPose = pose
        setImagesToDefault()
        let vhthresh = 1.0      //boundary between a very high and a high pose
        let mthresh = 0.2       //boundary between a high and a middle pose
        let lthresh = -0.3      //boundary between a middle and a low pose
        self.pitch = iniPitch
        if tr.isTranscribing {
            print("Stopped Recording")
            tr.stop()
            recStatus.isHidden = true
        }
        
        switch (pose.type) {
        case .unknown:
            break
        case .rest:
            break
        case .fist:
            if host == 0 {
                if(self.pitch<CGFloat(lthresh)){
                    lf.image = #imageLiteral(resourceName: "flight.png")
                    lastPose.image = #imageLiteral(resourceName: "fsemiDark.png")
                    lastpitchL.text = "L"
                    
                }
                if(self.pitch>CGFloat(lthresh) && self.pitch<CGFloat(mthresh)){
                    mf.image = #imageLiteral(resourceName: "flight.png")
                    lastPose.image = #imageLiteral(resourceName: "fsemiDark.png")
                    lastpitchL.text = "M"
                    
                }
                if(self.pitch>CGFloat(mthresh) && self.pitch<CGFloat(vhthresh)){
                    hf.image = #imageLiteral(resourceName: "flight.png")
                    lastPose.image = #imageLiteral(resourceName: "fsemiDark.png")
                    lastpitchL.text = "H"
                    
                }
                if(self.pitch>CGFloat(vhthresh)){
                    vhf.image = #imageLiteral(resourceName: "flight.png")
                    lastPose.image = #imageLiteral(resourceName: "fsemiDark.png")
                    lastpitchL.text = "VH"
                    host = 1
                    lock = true
                    self.lockimg.image = #imageLiteral(resourceName: "locked.PNG")
                    TLMHub.shared().lockingPolicy = .none
                    computer.image = #imageLiteral(resourceName: "comp2.png")
                    iphone.image = #imageLiteral(resourceName: "bipho2sol.png")
                }
            } else if host == 1 {
                if lock == false {
                    if(self.pitch<CGFloat(lthresh)){
                        lf.image = #imageLiteral(resourceName: "flight.png")
                        lastPose.image = #imageLiteral(resourceName: "fsemiDark.png")
                        lastpitchL.text = "L"
                        tosend = "ges+lf"
                        
                    }
                    if(self.pitch>CGFloat(lthresh) && self.pitch<CGFloat(mthresh)){
                        mf.image = #imageLiteral(resourceName: "flight.png")
                        lastPose.image = #imageLiteral(resourceName: "fsemiDark.png")
                        lastpitchL.text = "M"
                        tosend = "ges+mf"
                        
                    }
                    if(self.pitch>CGFloat(mthresh) && self.pitch<CGFloat(vhthresh)){
                        hf.image = #imageLiteral(resourceName: "flight.png")
                        lastPose.image = #imageLiteral(resourceName: "fsemiDark.png")
                        lastpitchL.text = "H"
                        tosend = "ges+hf"
                        
                    }
                    if(self.pitch>CGFloat(vhthresh)){
                        vhf.image = #imageLiteral(resourceName: "flight.png")
                        lastPose.image = #imageLiteral(resourceName: "fsemiDark.png")
                        lastpitchL.text = "VH"
                        host = 0
                        TLMHub.shared().lockingPolicy = .standard
                        computer.image = #imageLiteral(resourceName: "bcomp2.png")
                        iphone.image = #imageLiteral(resourceName: "ipho2sol.png")
                    }
                }
                
            }
            break
        case .waveIn:
            if host == 0 {
                if(self.pitch<CGFloat(lthresh)){
                    lwi.image = #imageLiteral(resourceName: "wilight.png")
                    lastPose.image = #imageLiteral(resourceName: "wisemiDark.png")
                    lastpitchL.text = "L"
                }
                if(self.pitch>CGFloat(lthresh) && self.pitch<CGFloat(mthresh)){
                    mwi.image = #imageLiteral(resourceName: "wilight.png")
                    lastPose.image = #imageLiteral(resourceName: "wisemiDark.png")
                    lastpitchL.text = "M"
                }
                if(self.pitch>CGFloat(mthresh)){
                    hwi.image = #imageLiteral(resourceName: "wilight.png")
                    lastPose.image = #imageLiteral(resourceName: "wisemiDark.png")
                    lastpitchL.text = "H"
                }
                
            } else if host == 1 {
                if lock == false {
                    if(self.pitch<CGFloat(lthresh)){
                        lwi.image = #imageLiteral(resourceName: "wilight.png")
                        lastPose.image = #imageLiteral(resourceName: "wisemiDark.png")
                        lastpitchL.text = "L"
                        tosend = "ges+lwi"
                    }
                    if(self.pitch>CGFloat(lthresh) && self.pitch<CGFloat(mthresh)){
                        mwi.image = #imageLiteral(resourceName: "wilight.png")
                        lastPose.image = #imageLiteral(resourceName: "wisemiDark.png")
                        lastpitchL.text = "M"
                        tosend = "ges+mwi"
                        
                    }
                    if(self.pitch>CGFloat(mthresh)){
                        hwi.image = #imageLiteral(resourceName: "wilight.png")
                        lastPose.image = #imageLiteral(resourceName: "wisemiDark.png")
                        lastpitchL.text = "H"
                        tosend = "ges+hwi"
                    }
                }
            }
            break
        case .waveOut:
            if host == 0 {
                if(self.pitch<CGFloat(lthresh)){
                    lwo.image = #imageLiteral(resourceName: "wolight.png")
                    lastPose.image = #imageLiteral(resourceName: "wosemiDark.png")
                    lastpitchL.text = "L"
                }
                if(self.pitch>CGFloat(lthresh) && self.pitch<CGFloat(mthresh)){
                    mwo.image = #imageLiteral(resourceName: "wolight.png")
                    lastPose.image = #imageLiteral(resourceName: "wosemiDark.png")
                    lastpitchL.text = "M"
                }
                if(self.pitch>CGFloat(mthresh)){
                    hwo.image = #imageLiteral(resourceName: "wolight.png")
                    lastPose.image = #imageLiteral(resourceName: "wosemiDark.png")
                    lastpitchL.text = "H"
                }
            } else if host == 1 {
                if lock == false {
                    if(self.pitch<CGFloat(lthresh)){
                        lwo.image = #imageLiteral(resourceName: "wolight.png")
                        lastPose.image = #imageLiteral(resourceName: "wosemiDark.png")
                        lastpitchL.text = "L"
                        tosend = "ges+lwo"
                    }
                    if(self.pitch>CGFloat(lthresh) && self.pitch<CGFloat(mthresh)){
                        mwo.image = #imageLiteral(resourceName: "wolight.png")
                        lastPose.image = #imageLiteral(resourceName: "wosemiDark.png")
                        lastpitchL.text = "M"
                        tosend = "ges+mwo"
                    }
                    if(self.pitch>CGFloat(mthresh)){
                        hwo.image = #imageLiteral(resourceName: "wolight.png")
                        lastPose.image = #imageLiteral(resourceName: "wosemiDark.png")
                        lastpitchL.text = "H"
                        tosend = "ges+hwo"
                    }
                }
            }
            break
        case .fingersSpread:
            if host == 0 {
                if(self.pitch<CGFloat(lthresh)){
                    lfs.image = #imageLiteral(resourceName: "fslight.png")
                    lastPose.image = #imageLiteral(resourceName: "fssemiDark.png")
                    lastpitchL.text = "L"
                }
                if(self.pitch>CGFloat(lthresh) && self.pitch<CGFloat(mthresh)){
                    mfs.image = #imageLiteral(resourceName: "fslight.png")
                    lastPose.image = #imageLiteral(resourceName: "fssemiDark.png")
                    lastpitchL.text = "M"
                }
                if(self.pitch>CGFloat(mthresh) && self.pitch<CGFloat(vhthresh)){
                    hfs.image = #imageLiteral(resourceName: "fslight.png")
                    lastPose.image = #imageLiteral(resourceName: "fssemiDark.png")
                    lastpitchL.text = "H"
                }
                if(self.pitch>CGFloat(vhthresh)){
                    vhfs.image = #imageLiteral(resourceName: "fslight.png")
                    lastPose.image = #imageLiteral(resourceName: "fssemiDark.png")
                    lastpitchL.text = "VH"
                    
                }
            } else if host == 1 {
                if lock == false {
                    if(self.pitch<CGFloat(lthresh)){
                        lfs.image = #imageLiteral(resourceName: "fslight.png")
                        lastPose.image = #imageLiteral(resourceName: "fssemiDark.png")
                        lastpitchL.text = "L"
                        tosend = "ges+lfs"
                    }
                    if(self.pitch>CGFloat(lthresh) && self.pitch<CGFloat(mthresh)){
                        mfs.image = #imageLiteral(resourceName: "fslight.png")
                        lastPose.image = #imageLiteral(resourceName: "fssemiDark.png")
                        lastpitchL.text = "M"
                        tosend = "ges+mfs"
                        speechSynthesizer.stop()
                        if tr.isTranscribing == false {
                            tr.start()
                            recStatus.image = #imageLiteral(resourceName: "wmic.png")
                            recStatus.isHidden = false
                        }
                    }
                    if(self.pitch>CGFloat(mthresh) && self.pitch<CGFloat(vhthresh)){
                        hfs.image = #imageLiteral(resourceName: "fslight.png")
                        lastPose.image = #imageLiteral(resourceName: "fssemiDark.png")
                        lastpitchL.text = "H"
                        tosend = "ges+hfs"
                    }
                    if(self.pitch>CGFloat(vhthresh)){
                        vhfs.image = #imageLiteral(resourceName: "fslight.png")
                        lastPose.image = #imageLiteral(resourceName: "fssemiDark.png")
                        lastpitchL.text = "VH"
                        tosend = "ges+vhf"
                    }
                }
            }
            
            break
        case .doubleTap:
            if host == 0 {
                if(self.pitch<CGFloat(lthresh)){
                    ldt.image = #imageLiteral(resourceName: "dtlight.png")
                    lastPose.image = #imageLiteral(resourceName: "dt.png")
                    lastpitchL.text = "L"
                }
                if(self.pitch>CGFloat(lthresh) && self.pitch<CGFloat(mthresh)){
                    mdt.image = #imageLiteral(resourceName: "dtlight.png")
                    lastPose.image = #imageLiteral(resourceName: "dt.png")
                    lastpitchL.text = "M"
                }
                if(self.pitch>CGFloat(mthresh)){
                    hdt.image = #imageLiteral(resourceName: "dtlight.png")
                    lastPose.image = #imageLiteral(resourceName: "dt.png")
                    lastpitchL.text = "H"
                }
                
            } else if host == 1 {
                var flipped = 0
                if lock! == true {
                    if(self.pitch>CGFloat(mthresh)){
                        self.lock = false
                        self.lockimg.image = #imageLiteral(resourceName: "unlocked.png")
                        flipped = 1
                        pose.myo.vibrate(with: .short)
                    }
                    
                }
                if flipped == 0 {
                    if lock! == false {
                        if(self.pitch<CGFloat(lthresh)){
                            ldt.image = #imageLiteral(resourceName: "dtlight.png")
                            lastPose.image = #imageLiteral(resourceName: "dt.png")
                            lastpitchL.text = "L"
                            tosend = "ges+ldt"
                        }
                        if(self.pitch>CGFloat(lthresh) && self.pitch<CGFloat(mthresh)){
                            mdt.image = #imageLiteral(resourceName: "dtlight.png")
                            lastPose.image = #imageLiteral(resourceName: "dt.png")
                            lastpitchL.text = "M"
                            tosend = "ges+mdt"
                        }
                        if(self.pitch>CGFloat(mthresh)){
                            //hdt.image = #imageLiteral(resourceName: "dtlight.png")
                            self.lock = true
                            self.lockimg.image = #imageLiteral(resourceName: "locked.PNG")
                            pose.myo.vibrate(with: .short)
                        }
                    }
                }
                
                
                //            if lock == true {
                //                if(self.pitch>CGFloat(mthresh)){
                //                    //hdt.image =
                //                    //lastPose.image = #imageLiteral(resourceName: "dt.png")
                //                    //lastpitchL.text = "H"
                //                    if host == 0 {
                //                        lock = false
                //                        lockimg.image = #imageLiteral(resourceName: "unlocked.png")
                //                        var pose = currentPose
                //                        let when = DispatchTime.now() + 2 // change 2 to desired number of seconds
                //                        DispatchQueue.main.asyncAfter(deadline: when) {
                //                            if self.currentPose == pose {
                //                                self.lock = false
                //                            } else {
                //                                self.lock = true
                //                                self.lockimg.image = #imageLiteral(resourceName: "locked.PNG")
                //                            }
                //                        }
                //                    } else if host == 1 {
                //                        if lock == true {
                //                            lock = false
                //                        } else {
                //                            lock = true
                //                        }
                //                    }
                //                }
                //            }
                break
            }
            if host == 0 {
                if (pose.type == .unknown || pose.type == .rest) {
                    
                    // Causes the Myo to lock after a short period.
                    pose.myo.unlock(with: .timed)
                } else {
                    // Keeps the Myo unlocked until specified.
                    // This is required to keep Myo unlocked while holding a pose, but if a pose is not being held, use
                    // TLMUnlockTypeTimed to restart the timer.
                    pose.myo.unlock(with: .hold)
                    // Indicates that a user action has been performed.
                    pose.myo.indicateUserAction()
                    self.lockimg.image = #imageLiteral(resourceName: "unlocked.png")
                }
            }
            
        }
        if (currentPose.type == .doubleTap || currentPose.type == .fist || currentPose.type == .fingersSpread || currentPose.type == .waveIn || currentPose.type == .waveOut) && lock == false {
            sendcmd(text: tosend)
        }
        
    }
    
    func didRecieveGyroScopeEvent(_ notification: Notification) {
        let userInfo = notification.userInfo
        let gyroEvent:TLMGyroscopeEvent = userInfo![kTLMKeyGyroscopeEvent] as! TLMGyroscopeEvent
        
        //let gyroData = gyroEvent.vector
        // Uncomment to display the gyro values
        //let x = gyroData.x
        //let y = gyroData.y
        //let z = gyroData.z
        //gyroscopeLabel.text = "Gyro: (\(x), \(y), \(z))"
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.ipAddressTF.resignFirstResponder()
        self.portTF.resignFirstResponder()
        return true
    }
    
    func setImagesToDefault(){
        lfs.image = #imageLiteral(resourceName: "fssemiDark.png")
        mfs.image = #imageLiteral(resourceName: "fssemiDark.png")
        hfs.image = #imageLiteral(resourceName: "fssemiDark.png")
        vhfs.image = #imageLiteral(resourceName: "fssemiDark.png")
        lf.image = #imageLiteral(resourceName: "fsemiDark.png")
        mf.image = #imageLiteral(resourceName: "fsemiDark.png")
        hf.image = #imageLiteral(resourceName: "fsemiDark.png")
        vhf.image = #imageLiteral(resourceName: "fsemiDark.png")
        lwo.image = #imageLiteral(resourceName: "wosemiDark.png")
        mwo.image = #imageLiteral(resourceName: "wosemiDark.png")
        hwo.image = #imageLiteral(resourceName: "wosemiDark.png")
        lwi.image = #imageLiteral(resourceName: "wisemiDark.png")
        mwi.image = #imageLiteral(resourceName: "wisemiDark.png")
        hwi.image = #imageLiteral(resourceName: "wisemiDark.png")
        ldt.image = #imageLiteral(resourceName: "dt.png")
        mdt.image = #imageLiteral(resourceName: "dt.png")
        hdt.image = #imageLiteral(resourceName: "dt.png")
    }
    
}

