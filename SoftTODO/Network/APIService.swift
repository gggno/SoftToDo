import Foundation
import Alamofire
import SwiftyJSON
import RxSwift
import RxAlamofire

class APIService {
    
    /// 모든 할일 불러오기 API 요청
    /// - Parameter page: 불러 올 페이지
    /// - Returns: 불러 온 데이터
    static func getAllTodoAPI(page: Int) -> Observable<Result<[AllTaskData], ApiError>> {
        let getAllTodoUrl = "##################################"
        
        return RxAlamofire.requestData(.get, getAllTodoUrl)
            .flatMap { response, jsonData -> Observable<Result<[AllTaskData], ApiError>> in
                let statusCode = response.statusCode
                if statusCode == 204 {
                    return Observable.error(ApiError.noContent)
                } else if statusCode == 400 {
                    return Observable.error(ApiError.badStatus)
                }
                
                print("모든 할일 불러오기 요청 성공")
                do {
                    let allTodoData = try JSONDecoder().decode(GetAllDoResponse.self, from: jsonData)
                    var toDoList: [AllTaskData] = []
                    
                    if let todoDatas = allTodoData.data {
                        for index in 0..<todoDatas.count {
                            guard let sectionDate = todoDatas[index].updatedAt?.titleDate() else {return Observable.error(ApiError.decodingError)}
                            
                            guard let id = todoDatas[index].id else {return Observable.error(ApiError.decodingError)}
                            guard let title = todoDatas[index].title else {return Observable.error(ApiError.decodingError)}
                            guard let isDone = todoDatas[index].isDone else {return Observable.error(ApiError.decodingError)}
                            guard let time = todoDatas[index].updatedAt?.currentTime() else {return Observable.error(ApiError.decodingError)}
                            
                            toDoList.append(AllTaskData(sectionDate: sectionDate, id: id, title: title, isDone: isDone, time: time))
                        }
                    }
                    return Observable.just(.success(toDoList))
                } catch {
                    return Observable.error(ApiError.decodingError)
                }
            }
    }
            
    /// 검색 데이터 가져오기 API 요청
    /// - Parameters:
    ///   - searchText: 검색 키워드
    ///   - page: 불러 올 페이지
    /// - Returns: 불러 온 데이터
    static func getTodoSearch(searchText: String, page: Int) -> Observable<Result<[AllTaskData], ApiError>> {
        let getSearchUrl = "##################################"
        let encodingUrl = getSearchUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        return RxAlamofire.requestData(.get, encodingUrl)
            .flatMap { response, jsonData -> Observable<Result<[AllTaskData], ApiError>> in
                let statusCode = response.statusCode
                if statusCode == 204 {
                    return Observable.error(ApiError.noContent)
                } else if statusCode == 400 {
                    return Observable.error(ApiError.badStatus)
                }
                
                do {
                    print("검색 데이터 가져오기 요청 성공")
                    let searchData = try JSONDecoder().decode(GetAllDoResponse.self, from: jsonData)
                    var searchList: [AllTaskData] = []
                    
                    for index in 0..<(searchData.data?.count ?? 0) {
                        guard let sectionDate = searchData.data![index].updatedAt?.titleDate() else {return Observable.error(ApiError.decodingError)}
                        
                        guard let id = searchData.data![index].id else {return Observable.error(ApiError.decodingError)}
                        guard let title = searchData.data![index].title else {return Observable.error(ApiError.decodingError)}
                        guard let isDone = searchData.data![index].isDone else {return Observable.error(ApiError.decodingError)}
                        guard let time = searchData.data![index].updatedAt?.currentTime() else {return Observable.error(ApiError.decodingError)}
                        
                        searchList.append(AllTaskData(sectionDate: sectionDate, id: id, title: title, isDone: isDone, time: time))
                    }
                    return Observable.just(.success(searchList))
                } catch {
                    return Observable.error(ApiError.decodingError)
                }
            }
    }

    /// 할일 삭제하기 API 요청
    /// - Parameter id: 삭제할 할일 아이디
    /// - Returns: 성공 여부
    static func deleteTodo(id: Int) -> Observable<Result<DeleteResponse, ApiError>> {
        let deleteTodoUrl = "##################################"
        
        return RxAlamofire.requestData(.delete, deleteTodoUrl)
            .flatMap { response, jsonData -> Observable<Result<DeleteResponse, ApiError>> in
                let statusCode = response.statusCode
                if statusCode == 400 {
                    return Observable.error(ApiError.badStatus)
                }
                print("할일 삭제하기 요청 성공")
                do {
                    let deleteResponse = try JSONDecoder().decode(DeleteResponse.self, from: jsonData)
                    return Observable.just(.success(deleteResponse))
                } catch {
                    return Observable.error(ApiError.decodingError)
                }
            }
    }
    
    /// 할일 추가하기 API 요청
    /// - Parameters:
    ///   - title: 추가할 할일 내용
    ///   - isDone: 완료 여부
    /// - Returns: 성공 여부
    static func addTodo(title: String, isDone: Bool) -> Observable<Result<String, ApiError>> {
        let addTodoUrl = "##################################"
        
        let headers: HTTPHeaders = [
            "accept": "application/json",
            "Content-Type": "application/json",
            "X-CSRF-TOKEN": ""
        ]
        
        let parameters: Parameters = [
            "title": title,
            "is_done": isDone
        ]
        
        return RxAlamofire
            .requestJSON(.post, addTodoUrl, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .map { response, jsonData in
                let statusCode = response.statusCode
                
                switch statusCode {
                case 401:
                    return .failure(ApiError.unAuthorized)
                case 403:
                    return .failure(ApiError.forbidden)
                case 422:
                    return .failure(ApiError.unprocessableContent)
                default:
                    print("할일 추가하기 요청 성공")
                    let json = JSON(jsonData)
                    print(json)
                    let id = json["data"]["id"].rawValue as! Int
                    let title = json["data"]["title"].rawValue as! String
                    let isDone = json["data"]["is_Done"]
                    let message = json["message"].rawValue as! String
                    
                    return .success(message)
                }
            }
    }
    
    /// 할일 수정하기 API 요청
    /// - Parameters:
    ///   - id: 할일 수정 할 아이디
    ///   - title: 할일 수정 할 내용
    ///   - isDone: 완료 여부
    /// - Returns: 성공 여부
    static func editTodo(id: Int, title: String, isDone: Bool) -> Observable<Result<String, ApiError>> {
        let editTodoUrl = "##################################"
        
        let headers: HTTPHeaders = [
            "accept": "application/json",
            "Content-Type": "application/json",
            "X-CSRF-TOKEN": ""
        ]
        
        let parameters: Parameters = [
            "title": title,
            "is_done": isDone
        ]
        
        return RxAlamofire
            .requestJSON(.post, editTodoUrl, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .map { response, jsonData in
                let statusCode = response.statusCode
                if statusCode == 400 {
                    return .failure(ApiError.badStatus)
                }
                
                print("할일 수정하기 요청 성공")
                let json = JSON(jsonData)
                print(json)
                let id = json["data"]["id"].rawValue as! Int
                let title = json["data"]["title"].rawValue as! String
                let isDone = json["data"]["is_Done"]
                let message = json["message"].rawValue as! String
                
                return .success(message)
            }
    }
}
