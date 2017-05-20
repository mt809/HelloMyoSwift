# Myo Command

Extension of the original [Myo iOS app](https://developer.thalmic.com/downloads) that comes with the SDK in Swift 3

This project is originally based on [llahiru's project] (https://github.com/llahiru/HelloMyoSwift).

<img src="https://github.com/mt809/HelloMyoSwift/blob/master/screenshot.PNG?raw=true" width="250"> 

# Changes

* Added ability to POST gestures to a target IP:Port
* Implemented most if not all of Myo Music's functionality 

# Gesture Types

* Low or "L" gestures are any made below ~0 degrees from the horizotal
* Middle or "M" gestures are any made above ~0 from degrees from the horizotal and below ~45 degrees above the horizotal
* High or "H" gestures are any made above ~45 degrees above the horizontal and below ~85 degrees above the horizotal
* Very High or "VH" gestures are any made above ~85 degrees above the horizontal

# Current Settings

* A Very High Fist (VHF) will change the target device (if it's current target is Phone it will switch to Computer and vice versa) 

## Phone


### Locking Scheme

* Doesn't cuz locking and unlocking all the time is annoying


### Media Control Settings 

* Pause/Play: 1 Finger Spread of any type (LFS, MFS, HFS, VHFS) then a Middle Finger Spread (MFS) in succession
* Previous: 1 Wave Out of and type (LWO, MWO, HWO) then a Middle Wave In (MWI) in succession
* Next: 1 Wave In of and type (LWI, MWI, HWI) then a Middle Wave Out (MWO) in succession

* *Note: Media Controls seem to currently only work consisantly with Apple Music*


## Computer


### Locking Scheme

* A High Double Tap (HDT) toggles the lock


### Current Configuration

* POSTs all gestures **except** Middle Finger Spreads (MFS) to target IP and Port 
* A Middle Finger Spread (MFS) activates the microphone and for as long as the gesture is held. Uses Speech to Text then sends the results to the target IP and Port


