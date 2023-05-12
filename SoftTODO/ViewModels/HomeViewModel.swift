import Foundation
import RxSwift
import RxRelay
   
class HomeViewModel {
    
    // 가공되는 최종 데이터
    var todoDatas: BehaviorRelay<[AllTaskDataSection]> = BehaviorRelay(value: [])
    
    // 검색어
    var searchTerm: BehaviorRelay<String> = BehaviorRelay(value: "")
    
    var tableViewScrollToTop: PublishRelay<Void> = PublishRelay()
    
    var disposeBag = DisposeBag()
     
    var toDoCurrentPage = 1 // 할일 API에 호출 할 페이지 숫자
    var searchCurrentPage = 1 // 검색 API에 호출 할 페이지 숫자
    var loadingCheck: Bool = false // 로딩중이면 리턴
    
    init() {
        // 최초로 할일 불러오기
        fetchAllToDo(page: 1)
        
        // 검색어를 받아서 불러오기
        searchTerm
            .skip(2)
            .debounce(RxTimeInterval.milliseconds(500), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { vm, input in
                if input.count > 0 {
                    vm.fetchSearchToDo(searchText: input)
                } else {
                    vm.fetchBeforeRemoveAllToDo(page: 1)
                }
        }).disposed(by: disposeBag)
        
        // 할일 수정, 추가때 노티 받음(AddEditTaskViewModel에서 전달 HomeVM과 AddEditVM의 연관성)
        NotificationCenter
            .default
            .rx
            .notification(.TaskUpdateEvent)
            .withUnretained(self)
            .bind { vm, noti in
                vm.fetchBeforeRemoveAllToDo(page: 1)
            }.disposed(by: disposeBag)
        
        // 셀 체크박스 클릭
        NotificationCenter
            .default
            .rx
            .notification(.CellCheckEvent)
            .withUnretained(self)
            .bind { vm, noti in
                if let indexPath = noti.object as? IndexPath {
                    let sectionData = vm.todoDatas.value[indexPath.section]
                    let cellData = sectionData.rows[indexPath.row]
                    
                    if cellData.isDone == false { // 미완료일때 눌러서 완료로 변경
                        vm.fetchEditAndGetTodo(id: cellData.id, title: cellData.title, isDone: true)
                        
                    } else { // 완료일 때 눌러서 미완료로 변경
                        vm.fetchEditAndGetTodo(id: cellData.id, title: cellData.title, isDone: false)
                    }
                }
            }.disposed(by: disposeBag)
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
            .withUnretained(self)
            .do(onCompleted: {
                self.loadingCheck = false
            })
            .subscribe(onNext: { vm, response in
                vm.toDoCurrentPage = page
                
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
                        var currentDatas = vm.todoDatas.value
                        
                        // 처음 값을 넣거나 들어온 값이 다른 섹션(날짜)이면 추가
                        if (index == 0 && vm.todoDatas.value.isEmpty) || date != toDoData[index].sectionDate {
                            
                            currentDatas.append(AllTaskDataSection(sectionDate: toDoData[index].sectionDate, rows: toDo))
                            vm.todoDatas.accept(currentDatas)
                            
                            date = toDoData[index].sectionDate
                            
                        } else { // 기존 날짜와 동일하다면 row만 추가
                            currentDatas[vm.todoDatas.value.count-1].rows.append(contentsOf: toDo)
                            vm.todoDatas.accept(currentDatas)
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
            .withUnretained(self)
            .do(onCompleted: {
                self.loadingCheck = false
            })
            .subscribe(onNext: { vm, response in
                vm.toDoCurrentPage = page
                vm.todoDatas.accept([])
                
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
                        var currentDatas = vm.todoDatas.value
                        // 처음 값을 넣거나 들어온 값이 다른 섹션(날짜)이면 추가
                        if (index == 0 && vm.todoDatas.value.isEmpty) || date != toDoData[index].sectionDate {
                            currentDatas.append(AllTaskDataSection(sectionDate: toDoData[index].sectionDate, rows: toDo))
                            vm.todoDatas.accept(currentDatas)
                            
                            date = toDoData[index].sectionDate
                            
                        } else { // 기존 날짜와 동일하다면 row만 추가
                            currentDatas[currentDatas.count-1].rows.append(contentsOf: toDo)
                            vm.todoDatas.accept(currentDatas)
                        }
                    }
                    vm.loadingCheck = false
                    vm.tableViewScrollToTop.accept(())
                
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
            .withUnretained(self)
            .subscribe(onNext: { vm, searchDatas in
                print(searchDatas)
                switch searchDatas {
                case .success(let searchData):
                    // 불러 온 데이터가 없으면 리턴
                    if searchData.isEmpty {
                        print("검색 데이터 없음")
                        return
                    }
                    
                    var date = searchData[0].sectionDate
                    vm.todoDatas.accept([])
                    
                    for index in 0..<searchData.count {
                        
                        var search: [TaskData] = []
                        search.append(TaskData(id: searchData[index].id, title: searchData[index].title, isDone: searchData[index].isDone, time: searchData[index].time))
                        var currentDatas = vm.todoDatas.value
                        
                        // 처음 값을 넣거나 들어온 값이 다른 섹션(날짜)이면 추가
                        if (index == 0 && vm.todoDatas.value.isEmpty) || date != searchData[index].sectionDate {
                            currentDatas.append(AllTaskDataSection(sectionDate: searchData[index].sectionDate, rows: search))
                            vm.todoDatas.accept(currentDatas)
                            
                            date = searchData[index].sectionDate
                            
                        } else { // 기존 날짜와 동일하다면 row만 추가
                            currentDatas[currentDatas.count-1].rows.append(contentsOf: search)
                            vm.todoDatas.accept(currentDatas)
                        }
                    }
                    vm.loadingCheck = false
                    
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
            .withUnretained(self)
            .do(onCompleted: {
                self.loadingCheck = false
            })
                .subscribe(onNext: { vm, searchDatas in
                    vm.searchCurrentPage += 1
                
                switch searchDatas {
                case .success(let searchData):
                    // 불러 온 데이터가 없으면 리턴
                    if searchData.isEmpty {
                        print("검색 데이터 없음")
                        return
                    }
                    
                    var date = vm.todoDatas.value.last?.sectionDate
                    
                    for index in 0..<searchData.count {
                        
                        var search: [TaskData] = []
                        search.append(TaskData(id: searchData[index].id, title: searchData[index].title, isDone: searchData[index].isDone, time: searchData[index].time))
                        var currentDatas = vm.todoDatas.value
                        
                        // 처음 값을 넣거나 들어온 값이 다른 섹션(날짜)이면 추가
                        if (index == 0 && vm.todoDatas.value.isEmpty) || date != searchData[index].sectionDate {
                            currentDatas.append(AllTaskDataSection(sectionDate: searchData[index].sectionDate, rows: search))
                            vm.todoDatas.accept(currentDatas)
                            
                            date = searchData[index].sectionDate
                            
                        } else { // 기존 날짜와 동일하다면 row만 추가
                            currentDatas[currentDatas.count-1].rows.append(contentsOf: search)
                            vm.todoDatas.accept(currentDatas)
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
            .withUnretained(self)
            .subscribe(onNext: { vm, result in
                switch result {
                case .success(let data):
                    print(data)
                    
                    var currentDatas = vm.todoDatas.value
                    
                    // 해당하는 아이디의 할일 삭제
                    currentDatas[indexpath.section].rows.remove(at: indexpath.row)
                    
                    // 만약 해당 섹션 셀에 할일이 없다면 섹션도 삭제
                    if currentDatas[indexpath.section].rows.isEmpty {
                        currentDatas.remove(at: indexpath.section)
                    }
                    
                    vm.todoDatas.accept(currentDatas)
                    
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
            .withUnretained(self)
            .subscribe(onNext: { vm, response in
                switch response {
                case .success(_):
                    vm.fetchBeforeRemoveAllToDo(page: 1)
                    
                case .failure(let err):
                    print(err)
                }
            }).disposed(by: disposeBag)
    }
}
