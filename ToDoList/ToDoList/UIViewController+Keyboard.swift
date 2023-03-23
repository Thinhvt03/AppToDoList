
//

import UIKit

public extension UIViewController {
    func startAvoidingKeyboard() {
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(onKeyboardFrameWillChangeNotificationReceived(_:)),
                         name: UIResponder.keyboardWillChangeFrameNotification,
                         object: nil)
    }

    func stopAvoidingKeyboard() {
        NotificationCenter.default
            .removeObserver(self,
                            name: UIResponder.keyboardWillChangeFrameNotification,
                            object: nil)
    }
    
    @objc
    private func onKeyboardFrameWillChangeNotificationReceived(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else {
            return
        }

        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let safeAreaFrame = view.safeAreaLayoutGuide.layoutFrame.insetBy(dx: 0, dy: -additionalSafeAreaInsets.bottom)
        let intersection = safeAreaFrame.intersection(keyboardFrameInView)

        let keyboardAnimationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
        let animationDuration: TimeInterval = (keyboardAnimationDuration as? NSNumber)?.doubleValue ?? 0
        
        let animationCurveRawNSN = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve = UIView.AnimationOptions(rawValue: animationCurveRaw)

        UIView.animate(withDuration: animationDuration,
                       delay: 0,
                       options: animationCurve,
                       animations: {
            self.additionalSafeAreaInsets.bottom = intersection.height
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    
        
        
    
}
