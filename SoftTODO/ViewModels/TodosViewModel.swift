import Foundation
import RxSwift
import RxRelay
   
class TodosViewModel {
    
    // 가공되는 최종 데이터
    var todoDatas: BehaviorRelay<[AllTaskDataSection]> = BehaviorRelay(value: [])
    
    // 검색어
    var searchTerm: BehaviorRelay<String> = BehaviorRelay(value: "")
    
    var disposeBag = DisposeBag()
     
    var toDoCurrentPage = 1 // 할일 API에 호출 할 페이지 숫자
    var searchCurrentPage = 1 // 검색 API에 호출 할 페이지 숫자
    var loadingCheck: Bool = false // 로딩중이면 리턴
    
    init() {
        // 검색어를 받아서 불러오기
        searchTerm
            .skip(2)
            .debounce(RxTimeInterval.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] input in
                guard let self = self else {return}
                if input.count > 0 {
                    fetchSearchToDo(searchText: input)
                } else {
                    fetchBeforeRemoveAllToDo(page: 1)
                }
        }).disposed(by: disposeBag)
        
        // 최초로 할일 불러오기
        fetchAllToDo(page: 1)
    }
    
    /// 할일 불러오기
    /// - Parameter page: 할일 불러오기 페이지
    func fetchAllToDo(page: Int) {
        print("TodosViewModel - fetchAllToDo() called")
        if loadingCheck {
            print("로딩 중 입니다.")
            return
        }
        loadingCheck = true
        
        // 서비스 로직
        APIService.getAllTodoAPI(page: page)
            .do(onCompleted: {
                self.loadingCheck = false
            })
            .subscribe(onNext: { [weak self] response in
                guard let self = self else {return}
                toDoCurrentPage = page
                
                switch response {
                case .success(let toDoData):
                    // 마지막 까지 가서 값이 없으면 리턴
                    if toDoData.isEmpty {
                        print("not data")
                        return
                    }
                    
                    var date = toDoData[0].sectionDate
                    
                    for index in 0..<toDoData.count {
                        var toDo: [TaskData] = []
                        toDo.append(TaskData(id: toDoData[index].id, title: toDoData[index].title, isDone: toDoData[index].isDone, time: toDoData[index].time))
                        var currentDatas = todoDatas.value
                        
                        // 처음 값을 넣거나 들어온 값이 다른 섹션(날짜)이면 추가
                        if (index == 0 && todoDatas.value.isEmpty) || date != toDoData[index].sectionDate {
                            
                            currentDatas.append(AllTaskDataSection(sectionDate: toDoData[index].sectionDate, rows: toDo))
                            todoDatas.accept(currentDatas)
                            
                            date = toDoData[index].sectionDate
                            
                        } else { // 기존 날짜와 동일하다면 row만 추가
                            currentDatas[todoDatas.value.count-1].rows.append(contentsOf: toDo)
                            todoDatas.accept(currentDatas)
                        }
                    }
                
                case .failure(let err):
                    print(err)
                }
                
            }).disposed(by: disposeBag)
    }
    
    /// todoDatas에 존재하는 데이터 제거 후 할일 가져오기
    /// - Parameter page: 할일 불러오기 페이지
    func fetchBeforeRemoveAllToDo(page: Int) {
        print("TodosViewModel - fetchBeforeRemoveAllToDo() called")
        if loadingCheck {
            print("로딩 중 입니다.")
            return
        }
        loadingCheck = true
        
        // 서비스 로직
        APIService.getAllTodoAPI(page: page)
            .do(onCompleted: {
                self.loadingCheck = false
            })
            .subscribe(onNext: { [weak self] response in
                guard let self = self else {return}
                toDoCurrentPage = page
                todoDatas.accept([])
                
                switch response {
                case .success(let toDoData):
                    // 마지막 까지 가서 값이 없으면 리턴
                    if toDoData.isEmpty {
                        print("not data")
                        return
                    }
                    
                    var date = toDoData[0].sectionDate
                    
                    for index in 0..<toDoData.count {
                        var toDo: [TaskData] = []
                        toDo.append(TaskData(id: toDoData[index].id, title: toDoData[index].title, isDone: toDoData[index].isDone, time: toDoData[index].time))
                        var currentDatas = todoDatas.value
                        // 처음 값을 넣거나 들어온 값이 다른 섹션(날짜)이면 추가
                        if (index == 0 && todoDatas.value.isEmpty) || date != toDoData[index].sectionDate {
                            currentDatas.append(AllTaskDataSection(sectionDate: toDoData[index].sectionDate, rows: toDo))
                            todoDatas.accept(currentDatas)
                            
                            date = toDoData[index].sectionDate
                            
                        } else { // 기존 날짜와 동일하다면 row만 추가
                            currentDatas[currentDatas.count-1].rows.append(contentsOf: toDo)
                            todoDatas.accept(currentDatas)
                        }
                    }
                    loadingCheck = false
                
                case .failure(let err):
                    print(err)
                }
            }).disposed(by: disposeBag)
    }
    
    /// 할일 더 불러오기
    func fetchAllToDoMore() {
        print("TodosViewModel - fetchAllToDoMore() called")
        fetchAllToDo(page: toDoCurrentPage + 1)
    }
    
    /// 검색 데이터 불러오기
    /// - Parameter searchText: 검색 할 키워드
    func fetchSearchToDo(searchText: String) {
        print("TodosViewModel - fetchSearchToDo() called")
        
        if loadingCheck {
            print("로딩 중 입니다.")
            return
        }
        loadingCheck = true
        
        APIService.getTodoSearch(searchText: searchText, page: 1)
            .subscribe(onNext: { [weak self] searchDatas in
                guard let self = self else {return}
                print(searchDatas)
                switch searchDatas {
                case .success(let searchData):
                    // 불러 온 데이터가 없으면 리턴
                    if searchData.isEmpty {
                        print("검색 데이터 없음")
                        return
                    }
                    
                    var date = searchData[0].sectionDate
                    todoDatas.accept([])
                    
                    for index in 0..<searchData.count {
                        
                        var search: [TaskData] = []
                        search.append(TaskData(id: searchData[index].id, title: searchData[index].title, isDone: searchData[index].isDone, time: searchData[index].time))
                        var currentDatas = todoDatas.value
                        
                        // 처음 값을 넣거나 들어온 값이 다른 섹션(날짜)이면 추가
                        if (index == 0 && todoDatas.value.isEmpty) || date != searchData[index].sectionDate {
                            currentDatas.append(AllTaskDataSection(sectionDate: searchData[index].sectionDate, rows: search))
                            todoDatas.accept(currentDatas)
                            
                            date = searchData[index].sectionDate
                            
                        } else { // 기존 날짜와 동일하다면 row만 추가
                            currentDatas[currentDatas.count-1].rows.append(contentsOf: search)
                            todoDatas.accept(currentDatas)
                        }
                    }
                    loadingCheck = false
                    
                case .failure(let err):
                    print(err)
                }
            }).disposed(by: disposeBag)
    }
    
    /// 검색 데이터 다음 페이지 데이터 불러오기
    /// - Parameter searchText: 검색 할 키워드
    func fetchSearchToDoMore(searchText: String) {
        print("TodosViewModel - fetchSearchToDoMore() called")
        
        if loadingCheck {
            print("로딩 중 입니다.")
            return
        }
        loadingCheck = true
        
        APIService.getTodoSearch(searchText: searchText, page: searchCurrentPage+1)
            .do(onCompleted: {
                self.loadingCheck = false
            })
            .subscribe(onNext: { [weak self] searchDatas in
                guard let self = self else {return}
                searchCurrentPage += 1
                
                switch searchDatas {
                case .success(let searchData):
                    // 불러 온 데이터가 없으면 리턴
                    if searchData.isEmpty {
                        print("검색 데이터 없음")
                        return
                    }
                    
                    var date = todoDatas.value.last?.sectionDate
                    
                    for index in 0..<searchData.count {
                        
                        var search: [TaskData] = []
                        search.append(TaskData(id: searchData[index].id, title: searchData[index].title, isDone: searchData[index].isDone, time: searchData[index].time))
                        var currentDatas = todoDatas.value
                        
                        // 처음 값을 넣거나 들어온 값이 다른 섹션(날짜)이면 추가
                        if (index == 0 && todoDatas.value.isEmpty) || date != searchData[index].sectionDate {
                            currentDatas.append(AllTaskDataSection(sectionDate: searchData[index].sectionDate, rows: search))
                            todoDatas.accept(currentDatas)
                            
                            date = searchData[index].sectionDate
                            
                        } else { // 기존 날짜와 동일하다면 row만 추가
                            currentDatas[currentDatas.count-1].rows.append(contentsOf: search)
                            todoDatas.accept(currentDatas)
                        }
                    }
                    
                case .failure(let err):
                    print(err)
                }
            }).disposed(by: disposeBag)
    }
    
    /// 할일 삭제하기
    /// - Parameters:
    ///   - id: 삭제 할 아이디
    ///   - indexpath: 삭제 할 IndexPath
    func fetchDeleteTodo(id: Int, indexpath: IndexPath) {
        APIService.deleteTodo(id: id)
            .subscribe(onNext: { [weak self] result in
                guard let self = self else {return}
                
                switch result {
                case .success(let data):
                    print(data)
                    
                    var currentDatas = todoDatas.value
                    
                    // 해당하는 아이디의 할일 삭제
                    currentDatas[indexpath.section].rows.remove(at: indexpath.row)
                    
                    // 만약 해당 섹션 셀에 할일이 없다면 섹션도 삭제
                    if currentDatas[indexpath.section].rows.isEmpty {
                        currentDatas.remove(at: indexpath.section)
                    }
                    
                    todoDatas.accept(currentDatas)
                    
                case .failure(let err):
                    print(err)
                }
            }).disposed(by: disposeBag)
    }
    
    /// 체크박스 클릭 시 변경되는 완료 여부
    /// - Parameters:
    ///   - id: 해당하는 할일의 아이디
    ///   - title: 할일 내용
    ///   - isDone: 완료 여부
    func fetchEditAndGetTodo(id: Int, title: String, isDone: Bool) {
        APIService.editTodo(id: id, title: title, isDone: isDone)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else {return}
                
                switch response {
                case .success(let data):
                    self.fetchBeforeRemoveAllToDo(page: 1)
                    
                case .failure(let err):
                    print(err)
                }
            }).disposed(by: disposeBag)
    }
}
