import Foundation

extension String {
    
    // task의 시간 표시 ex) 12:03 AM
    func currentTime() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: self) {
            let timeFormatter = DateFormatter()
            timeFormatter.locale = Locale(identifier: "default")
            timeFormatter.dateFormat = "h:mm a"
            timeFormatter.timeZone = TimeZone.current
            let timeString = timeFormatter.string(from: date)
            
            return timeString
        } else {
            print("Invalid time string")
            return self
        }
    }
    
    // 헤더에 날짜 표시 ex) 2023.04.08
    func titleDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        if let date = dateFormatter.date(from: self) {
            dateFormatter.dateFormat = "yyyy.MM.dd"
            let convertedDate = dateFormatter.string(from: date)
            
            return convertedDate
            
        } else {
            print("Invalid time string")
            return self
        }
    }
    

}
