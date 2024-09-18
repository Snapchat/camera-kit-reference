# ``CameraKitBasicSample``
Camera Kit SDK brings Snap's AR platform to your app or website. This project simply shows how you can build a single AR experience in your app. Integrating Camera Kit more generally is described in [Camera Kit iOS](./README.md). This document talks about the steps getting Camera Kit running quickly and applying a single AR experience.

Note: the numbered steps below match those in code comments in ``CameraKitBasicSample``.

 ## Credentials

Before you start, enter your API Token by navigating to [my-lenses](https://my-lenses.snapchat.com/) and tapping on "Apps" and then selecting the Snap Kit app to run. Also get the ID of the Lens you want to apply and the ID of the it's Lens group. Create constants for these so you can pass them into Camera Kit.  

```swift 
private enum Constants {
    static let apiToken = "REPLACE-THIS-WITH-YOUR-OWN-APP-SPECIFIC-VALUE"
    static let lensId = "REPLACE-THIS-WITH-YOUR-OWN-APP-SPECIFIC-VALUE"
    static let groupId = "REPLACE-THIS-WITH-YOUR-OWN-APP-SPECIFIC-VALUE"
}
```

## Setup Camera Kit

In ``setupCameraKit()`` you will need to create a Camera Kit Session and run it.  

You need to do two things before you can apply a Lens to a camera video feed. We will do these in ``setupCameraKit()``

**(1)** Create a Camera Kit ```Session```. A ``Session`` is the main entry point into Camera Kit  

``` swift
self.cameraKit = Session(sessionConfig: SessionConfig(apiToken: Constants.apiToken), lensesConfig: LensesConfig(cacheConfig: CacheConfig(lensContentMaxSize: 150 * 1024 * 1024)), errorHandler: nil)
```

**(2)** Then attach inputs and output and start the ``Session``. Camera Kit takes two kinds of inputs. ``AVSessionInput`` is a light wrapper around iOS's ``AVCaptureSession``. Similarly, ``ARSessionInput`` is a wrapper around ``ARSession``. These are inputs into Camera Kit. 

``` swift
let input = AVSessionInput(session: captureSession)
let arInput = ARSessionInput()
```

**(3)** You need an output to display the camera feed after AR experiences are applied by Camera Kit. 

```swift 
previewView.automaticallyConfiguresTouchHandler = true
cameraKit.add(output: previewView)
```

**(4)** The Camera Kit ``Session`` is ready to go. Now you can start the session. 

``` swift
cameraKit.start(input: input, arInput: arInput)
```

 **(5)** Observe a particular Lens

This code adds an observer to see a particular Lens in a particular Lens group.  

```swift 
cameraKit.lenses.repository.addObserver(self, specificLensID: Constants.lensId, inGroupID: Constants.groupId)
```

 **(6)**  Start the input with ``startRunning()``. Not this method is synchronous and should not be called on the main thread.

``` swift     
DispatchQueue.global(qos: .background).async {
	input.startRunning()
}
```

## Apply a Lens

**(7)** Create a convenience method to apply the Lens. This method applies a Lens in a serial background queue. This way Lens applications remain in order and do not block the main thread. 

``` swift
public func apply(lens: Lens) {
    lensQueue.async { [weak self] in
        guard let self = self else { return }
        self.cameraKit.lenses.processor?.apply(lens: lens, launchData: nil) {
          success in
            if success {
                print("\(lens.name ?? "Unnamed") (\(lens.id)) Applied")
            } else {
                print("Lens failed to apply")
            }
        }
    }
}
```


## Observe a specific Lens

Before Camera Kit can apply a Lens, we need to a Lens observer. Conform the class that implements the ``Session`` to ``SCCameraKitLensRepositorySpecificObserver``. This protocol allows conformers to be notified of changes to specific Lenses in groups that the repository has available.

**(8)** Implement the protocol methods to observe a Lens

``` swift
extension CameraViewController: LensRepositorySpecificObserver {
func repository(_ repository: LensRepository, didUpdate lens: Lens, forGroupID groupID: String) {
    apply(lens: lens) // We will implement this method in step (5)
}
```

In production you will also want to handle errors by implementing the ``repository(_:didFailToUpdateLensID:forGroupID:error:)`` method. Here we just print it to console.
