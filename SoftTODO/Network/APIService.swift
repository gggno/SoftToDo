import Foundation
import Alamofire
import SwiftyJSON
import RxSwift

class APIService {
    
    /// 모든 할일 불러오기 API 요청
    /// - Parameter page: 불러 올 페이지
    /// - Returns: 불러 온 데이터
    static func getAllTodoAPI(page: Int) -> Observable<Result<[AllTaskData], Error>> {
        let getAllTodoUrl = "################################"
        
        return Observable.create { observer in
            AF.request(getAllTodoUrl, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil)
                .responseDecodable(of: GetAllDoResponse.self) { response in
                    guard let statusCode = response.response?.statusCode else {return}
                    
                    switch response.result {
                    case .success(let allTodoData):
                        print("모든 할일 불러오기 요청 성공")
                        
                        var toDoList: [AllTaskData] = []
                        
                        if let todoDatas = allTodoData.data {
                            for index in 0..<todoDatas.count {
                                guard let sectionDate = todoDatas[index].updatedAt?.titleDate() else {return}
                                
                                guard let id = todoDatas[index].id else {return}
                                guard let title = todoDatas[index].title else {return}
                                guard let isDone = todoDatas[index].isDone else {return}
                                guard let time = todoDatas[index].updatedAt?.currentTime() else {return}
                                
                                toDoList.append(AllTaskData(sectionDate: sectionDate, id: id, title: title, isDone: isDone, time: time))
                            }
                            observer.onNext(.success(toDoList))
                            observer.onCompleted()
                        }
                        
                    case .failure(let err):
                        print("모든 할일 불러오기 에러: \(err)")
                        switch statusCode {
                        case 204:
                            print("statusCode: 204")
                            observer.onError(err)
                        case 400:
                            print("statusCode: 400")
                            observer.onError(err)
                        default:
                            print("statusCode: default")
                            observer.onError(err)
                        }
                    }
                }
            return Disposables.create()
        }
    }
    
    /// 검색 데이터 가져오기 API 요청
    /// - Parameters:
    ///   - searchText: 검색 키워드
    ///   - page: 불러 올 페이지
    /// - Returns: 불러 온 데이터
    static func getTodoSearch(searchText: String, page: Int) -> Observable<Result<[AllTaskData], Error>> {
        let getSearchUrl = "################################"
        let encodingUrl = getSearchUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        return Observable.create { observer in
            AF.request(encodingUrl, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil)
                .responseDecodable(of: GetAllDoResponse.self) { response in
                    guard let statusCode = response.response?.statusCode else {return}
                    
                    switch response.result {
                    case .success(let searchData):
                        print("검색 데이터 가져오기 요청 성공")
                        
//                        if statusCode == 204 {
//                            observer.onError(ApiError.noContent)
//                        }
                        
                        var searchList: [AllTaskData] = []
                        
                        for index in 0..<(searchData.data?.count ?? 0) {
                            guard let sectionDate = searchData.data![index].updatedAt?.titleDate() else {return}
                            
                            guard let id = searchData.data![index].id else {return}
                            guard let title = searchData.data![index].title else {return}
                            guard let isDone = searchData.data![index].isDone else {return}
                            guard let time = searchData.data![index].updatedAt?.currentTime() else {return}
                            
                            searchList.append(AllTaskData(sectionDate: sectionDate, id: id, title: title, isDone: isDone, time: time))
                        }
                        observer.onNext(.success(searchList))
                        
                    case .failure(let err):
                        print("검색 데이터 가져오기 error: \(err)")
                        switch statusCode {
                        case 400:
                            observer.onError(err)
                        default:
                            observer.onError(err)
                        }
                    }
                }
            return Disposables.create()
        }
    }

    /// 할일 삭제하기 API 요청
    /// - Parameter id: 삭제할 할일 아이디
    /// - Returns: 성공 여부
    static func deleteTodo(id: Int) -> Observable<Result<DeleteResponse, Error>> {
        let deleteTodoUrl = "################################"
        
        return Observable.create { observer in
            AF.request(deleteTodoUrl, method: .delete, parameters: nil, encoding: URLEncoding.default, headers: nil)
                .responseDecodable(of: DeleteResponse.self) { response in
                    guard let statusCode = response.response?.statusCode else {return}

                    switch response.result {
                    case .success(let data):
                        print("할일 삭제하기 요청 성공")
                        observer.onNext(.success(data))
                        
                    case .failure(let err):
                        print("할일 삭제하기 error: \(err)")
                        switch statusCode {
                        case 400:
                            observer.onError(err)
                        default:
                            observer.onError(err)
                        }
                    }
                }
            return Disposables.create()
        }
    }
    
    /// 할일 추가하기 API 요청
    /// - Parameters:
    ///   - title: 추가할 할일 내용
    ///   - isDone: 완료 여부
    /// - Returns: 성공 여부
    static func addTodo(title: String, isDone: Bool) -> Observable<Result<String, Error>> {
        let addTodoUrl = "################################"
        
        let headers: HTTPHeaders = [
            "accept": "application/json",
            "Content-Type": "application/json",
            "X-CSRF-TOKEN": ""
        ]
        
        let parameters: Parameters = [
            "title": title,
            "is_done": isDone
        ]
        
        return Observable.create { observer in
            AF.request(addTodoUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                guard let statusCode = response.response?.statusCode else {return}
                
                switch response.result {
                case .success(let value):
                    print("할일 추가하기 요청 성공")
                    let json = JSON(value)
                    print(json)
                    let id = json["data"]["id"].rawValue as! Int
                    let title = json["data"]["title"].rawValue as! String
                    let isDone = json["data"]["is_Done"]
                    let message = json["message"].rawValue as! String
                    
                    observer.onNext(.success(message))
                    
                case .failure(let error):
                    print("할일 추가하기 error: \(error)")
                    switch statusCode {
                    case 401:
                        observer.onError(error)
                    case 403:
                        observer.onError(error)
                    case 422:
                        observer.onError(error)
                    default:
                        observer.onError(error)
                    }
                }
            }
            return Disposables.create()
        }
    }
    
    /// 할일 수정하기 API 요청
    /// - Parameters:
    ///   - id: 할일 수정 할 아이디
    ///   - title: 할일 수정 할 내용
    ///   - isDone: 완료 여부
    /// - Returns: 성공 여부
    static func editTodo(id: Int, title: String, isDone: Bool) -> Observable<Result<String, Error>> {
        let editTodoUrl = "################################"
        
        let headers: HTTPHeaders = [
            "accept": "application/json",
            "Content-Type": "application/json",
            "X-CSRF-TOKEN": ""
        ]
        
        let parameters: Parameters = [
            "title": title,
            "is_done": isDone
        ]
        
        return Observable.create { observer in
            AF.request(editTodoUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                guard let statusCode = response.response?.statusCode else {return}
                
                switch response.result {
                case .success(let value):
                    print("할일 수정하기 요청 성공")
                    let json = JSON(value)
                    print(json)
                    let id = json["data"]["id"].rawValue as! Int
                    let title = json["data"]["title"].rawValue as! String
                    let isDone = json["data"]["is_Done"]
                    let message = json["message"].rawValue as! String
                    
                    observer.onNext(.success(message))
                    
                case .failure(let error):
                    print("할일 수정하기 error: \(error)")
                    switch statusCode {
                    case 400:
                        observer.onError(error)
                    default:
                        observer.onError(error)
                    }
                }
            }
            return Disposables.create()
        }
    }
    
    // 할일 추가 후 할일 목록 불러오기
//    static func addAndGetAllTodo(title: String, isDone: Bool, completion: @escaping (Result<[AllTaskData], ApiError>) -> Void) {
//        self.addTodo(title: title, isDone: isDone) { string in
//            switch string {
//            case .success(_):
//                getAllTodoAPI(page: 1) { response in
//                    switch response {
//                    case .success(let todoData):
//                        completion(.success(todoData))
//                    
//                    case .failure(let err):
//                        print(err)
//                        completion(.failure(err))
//                    }
//                }
//            case .failure(let err):
//                print(err)
//                completion(.failure(err))
//            }
//        }
//    }
    
}
