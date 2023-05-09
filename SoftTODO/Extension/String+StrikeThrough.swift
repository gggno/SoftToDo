//
//  String+strike.swift
//  SoftTODO
//
//  Created by 정근호 on 2023/04/09.
//

import Foundation
import UIKit

extension String {
    
    // 완료된 task 중간 줄 처리
    func strikeThrough() -> NSAttributedString {
        let attributeString =  NSMutableAttributedString(string: self)
        attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0,attributeString.length))
        
        return attributeString
    }
}
