//  Copyright Snap Inc. All rights reserved.
//  CameraKitSandbox

import UIKit

/// Protocol used to load an image from url
public protocol LensPickerImageLoader {

    /// Load image from url
    /// - Parameters:
    ///   - url: image url
    ///   - completion: callback with image on success or error on failure
    func loadImage(url: URL, completion: ((_ image: UIImage?, _ error: Error?) -> Void)?)
}

/// Default image loader class which uses a URLSession to load images
public class DefaultLensPickerImageLoader: LensPickerImageLoader {

    public let urlSession: URLSession
    fileprivate var tasks: [URL: URLSessionDataTask] = [:]
    fileprivate let taskQueue = DispatchQueue(label: "com.snap.camerakit.referenceui.imageloader")

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    /// Load image from url (callback queue will be on main)
    /// - Parameters:
    ///   - url: image url
    ///   - completion: callback with image on success or error on failure
    public func loadImage(url: URL, completion: ((UIImage?, Error?) -> Void)?) {
        loadImage(url: url, queue: .main, completion: completion)
    }

    /// Load image from url
    /// - Parameters:
    ///   - url: image url
    ///   - queue: queue to call completion on
    ///   - completion: callback with image on success or error on failure
    public func loadImage(url: URL, queue: DispatchQueue, completion: ((UIImage?, Error?) -> Void)?) {
        let task = urlSession.dataTask(with: url) { [weak self] (data, _, error) in
            self?.removeTask(url: url)
            guard let data = data,
                let image = UIImage(data: data)
            else {
                queue.async {
                    completion?(nil, error)
                }
                return
            }
            queue.async {
                completion?(image, nil)
            }
        }

        addTask(task, for: url)
        task.resume()
    }

    public func cancelImageLoad(from url: URL) {
        taskQueue.async {
            self.tasks[url]?.cancel()
            self.tasks[url] = nil
        }
    }

    fileprivate func addTask(_ task: URLSessionDataTask, for url: URL) {
        taskQueue.async {
            self.tasks[url] = task
        }
    }

    fileprivate func removeTask(url: URL) {
        taskQueue.async {
            self.tasks[url] = nil
        }
    }

}
