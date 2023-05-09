import Foundation
import RxSwift

class AddEditTaskViewModel {
    
    var disposebag = DisposeBag()
    
    var delegate: TaskUpdateDelegate? = nil
    
    /// 할일 추가하기
    /// - Parameters:
    ///   - title: 할일 내용
    ///   - isDone: 완료 여부
    func fetchAddTodo(title: String, isDone: Bool, completion: @escaping () -> Void) {
        APIService.addTodo(title: title, isDone: isDone)
            .subscribe(onNext: { response in
                switch response {
                case .success(let str):
                    print(str)
                    completion()
                    
                case .failure(let err):
                    print(err)
                }}).disposed(by: disposebag)
    }
    
    /// 할일 수정하기
    /// - Parameters:
    ///   - id: 수정 할 할일의 아이디
    ///   - title: 수정 할 내용
    ///   - isDone: 완료 여부
    func fetchEditTodo(id: Int, title: String, isDone: Bool, completion: @escaping () -> Void) {
        APIService.editTodo(id: id, title: title, isDone: isDone)
            .subscribe(onNext: { response in
                switch response {
                case .success(let data):
                    print(data)
                    completion()
                    
                case .failure(let err):
                    print(err)
                }
            }).disposed(by: disposebag)
    }
}
