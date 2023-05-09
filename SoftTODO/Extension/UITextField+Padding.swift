import Foundation
import UIKit

extension UITextField {
    func setLeftIcon(_ icon: UIImage) {

        let leftPadding = 15 // 왼쪽 padding
        let rightPadding = 13
        let size = 16 // 이미지 사이즈
        

        let outerView = UIView(frame: CGRect(x: 0, y: 0, width: size+leftPadding+rightPadding, height: size) )
        let iconView  = UIImageView(frame: CGRect(x: leftPadding, y: 0, width: size, height: size))
        iconView.image = icon
        outerView.addSubview(iconView)

        leftView = outerView
        leftViewMode = .always
      }
    
    // 왼쪽에 패딩주기
    func leftPadding() {
        let leftPadding = 5
        let outerView = UIView(frame: CGRect(x: 0, y: 0, width: leftPadding, height: 15) )
        
        leftView = outerView
        leftViewMode = .always
        
    }
}
