# CameraKit

## Overview

CameraKit consists of three separate modules: a core SDK that contains camera, lenses, and processing functionality, a reference UI SDK that contains custom elements similar to Snapchat's elements, and a SwiftUI SDK that contains SwiftUI wrappers of the reference UI elements.

### [SCSDKCameraKit](SCSDKCameraKit/index.html)

This is the core SDK and is required to use CameraKit. This SDK provides the core functionality of CameraKit such as fetching and applying lenses, processing frames, providing default camera setups around AVCaptureSesion and ARSession, etc.

### [SCSDKCameraKitReferenceUI](SCSDKCameraKitReferenceUI/index.html)

This is an optional SDK that provides reference UI elements similar to Snapchat's UI as well as a fully-functional Camera view controller that has CameraKit set up and working with sample lenses. The elements provided in this SDK are designed to be used in a modular fashion, so it is easy to use certain UI elements out of the box while changing the design or functionality of other elements.

### [SCSDKCameraKitReferenceSwiftUI](SCSDKCameraKitReferenceSwiftUI/index.html)

This is another optional SDK that provides SwiftUI wrappers around the UIKit elements provided in `SCSDKCameraKitReferenceUI`. As with `SCSDKCameraKitReferenceUI` this SDK also provides a fully-functional Camera view to use that has CameraKit set up and working with sample lenses.
