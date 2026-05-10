import AVFoundation
import UIKit

/// 权限相关的轻量帮助方法。
/// PhotosPicker (iOS 14+) 不需要相册权限即可选择，因此只处理相机。
enum PermissionManager {
    enum CameraStatus {
        case authorized
        case denied        // 用户曾拒绝，需引导去设置
        case restricted    // 家长控制等限制
        case notDetermined // 首次申请
    }

    /// 检查并按需请求相机权限。完成回调在主线程触发。
    static func requestCameraAccess(completion: @escaping (CameraStatus) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            completion(.authorized)
        case .denied:
            completion(.denied)
        case .restricted:
            completion(.restricted)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted ? .authorized : .denied)
                }
            }
        @unknown default:
            completion(.denied)
        }
    }

    /// 跳转到 App 在系统设置里的页面。
    static func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
