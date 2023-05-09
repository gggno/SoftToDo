import Foundation

struct AllTaskDataSection {
    
    var sectionDate: String
    var rows: [TaskData]
}

// 섹션이 추가된
struct AllTaskData {
    let sectionDate: String
    
    let id: Int
    let title: String
    let isDone: Bool
    let time: String
}

// 섹션이 없는
struct TaskData {
    let id: Int
    let title: String
    let isDone: Bool
    let time: String
}
