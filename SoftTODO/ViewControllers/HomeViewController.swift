import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxRelay 
import RxDataSources

class HomeViewController: UIViewController, HomeTableViewCellDelegete, TaskUpdateDelegate {
    
    var todosVM: TodosViewModel = TodosViewModel()
    
    var allTaskDataList: [AllTaskDataSection] = [] // 할일 가져오기
    
    var disposeBag = DisposeBag()
    
    var loadingCheck: Bool = false // 로딩중이면 리턴
    var searchInputWorkItem: DispatchWorkItem? = nil
    
    // 당겨서 새로고침 세팅
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        
        refreshControl.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        refreshControl.attributedTitle = NSAttributedString(string: "당겨서 새로고침")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        
        return refreshControl
    }()
    
    lazy var searchTextField: UITextField = {
        let textField = UITextField()
        
        // 돋보기 아이콘 및 패딩 설정
        textField.setLeftIcon(UIImage(named: "SearchImage")!)
        textField.font = UIFont(name: "SourceSansPro-SemiBold", size: 16)
        textField.attributedPlaceholder = NSAttributedString(string: "할일 검색", attributes: [NSAttributedString.Key.foregroundColor : UIColor(named: "SearchPlaceholderColor")])
        
        textField.backgroundColor = UIColor(named: "SearchbgColor")
        
        textField.layer.cornerRadius = 20
        
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor(named: "SearchLineColor")?.cgColor
        
        return textField
    }()
    
    lazy var homeTableView: UITableView = {
        let tableView = UITableView()
        
        tableView.backgroundColor = .none
        tableView.register(HomeTableViewCell.self, forCellReuseIdentifier: HomeTableViewCell.identifier)
        
        return tableView
    }()
    
    // 할일 추가 플러스 버튼
    lazy var floatingButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .black
        config.cornerStyle = .capsule
        config.image = UIImage(systemName: "plus")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .medium))
        button.configuration = config
        button.layer.shadowRadius = 10
        button.layer.shadowOpacity = 0.3
        button.addTarget(self, action: #selector(plusBtnClicked), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(named: "vbgColor")
        
        homeVCLayoutSetting() // 레이아웃 세팅
        
        // 테이블뷰 설정
        homeTableView.delegate = self
        homeTableView.dataSource = self
        
        homeTableView.rowHeight = UITableView.automaticDimension
        homeTableView.estimatedRowHeight = 100.0
        
        homeTableView.separatorStyle = .none
        
        homeTableView.addSubview(refreshControl)
        
        // 서치바 설정
        // 검색어를 뷰모델에 전달하기
        searchTextField.rx.text.orEmpty
//            .subscribe(onNext: { data in
//                self.todosVM.searchTerm.accept(data)
//            })
            .bind(onNext: self.todosVM.searchTerm.accept(_:))
            .disposed(by: disposeBag)
        
        // 가공된 데이터로 테이블 뷰 업데이트 하기
        self.todosVM
            .todoDatas
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind(onNext: { homeVC, todoList in
                homeVC.allTaskDataList = todoList
                homeVC.homeTableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
    
    // 체크박스 클릭 델리게이트(HomeTableViewCell에서 수행)
    func cellCheckBoxEvent(indexPath: IndexPath) {
        var sectionData = allTaskDataList[indexPath.section]
        var cellData = sectionData.rows[indexPath.row]
        
        if cellData.isDone == false { // 미완료일때 눌러서 완료로 변경
            self.todosVM.fetchEditAndGetTodo(id: cellData.id, title: cellData.title, isDone: true)
            homeTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
            
        } else { // 완료일 때 눌러서 미완료로 변경
            self.todosVM.fetchEditAndGetTodo(id: cellData.id, title: cellData.title, isDone: false)
            homeTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
        }
    }
    
    // 할일 추가, 수정할때 델리게이트(AddTaskVC에서 수행)
    func taskUpdate() {
        self.todosVM.fetchBeforeRemoveAllToDo(page: 1)
        self.homeTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
    }
    
    // 위로 당겨서 새로고침 설정
    @objc func refresh(_ sender: AnyObject) {
        print("위로 당겨서 새로고침")
        
        self.todosVM.fetchBeforeRemoveAllToDo(page: 1)
        DispatchQueue.main.async {
            self.refreshControl.endRefreshing()
        }
    }
    
    // 플러스 버튼 클릭(할일 추가로 이동)
    @objc func plusBtnClicked() {
        print("plusBtnClicked() clicked")
        
        let addVC = AddEditTaskViewController()
        
        // 델리겟 세팅
        addVC.delegate = self
        present(addVC, animated: true)
    }
    
    // 전체 레이아웃 구성
    func homeVCLayoutSetting() {
        view.addSubview(searchTextField)
        searchTextField.snp.makeConstraints {
            $0.height.equalTo(40)
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(55)
            $0.leading.equalToSuperview().offset(16)
        }
        
        view.addSubview(homeTableView)
        homeTableView.snp.makeConstraints {
            $0.top.equalTo(searchTextField.snp.bottom).offset(24)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        view.addSubview(floatingButton)
        floatingButton.snp.makeConstraints {
            $0.size.equalTo(42)
            $0.trailing.equalToSuperview().offset(-18)
            $0.bottom.equalToSuperview().offset(-50)
        }
    }
    
}



// 테이블 뷰
extension HomeViewController: UITableViewDataSource {

    // 헤더 뷰(디자인) 설정
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let dateLabel = UILabel() // 해당하는 날짜 라벨
        dateLabel.font = UIFont(name: "SourceSansPro-Bold", size: 34)

        let titleView = UIView() // 날짜 뷰
        titleView.addSubview(dateLabel)

        if allTaskDataList.count > 0 {
            dateLabel.text = allTaskDataList[section].sectionDate

            dateLabel.snp.makeConstraints {
                $0.height.equalTo(25)
                $0.leading.equalToSuperview().offset(16)
                $0.top.equalToSuperview()
                $0.bottom.equalToSuperview().offset(-6)
            }
        }
        return titleView
    }

    // 섹션이 몇 개인지
    func numberOfSections(in tableView: UITableView) -> Int {
        return allTaskDataList.count
    }

    // 한 섹션 안에 몇 개의 로우인지
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allTaskDataList[section].rows.count
    }

    // 셀 설정
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = homeTableView.dequeueReusableCell(withIdentifier: "HomeTableViewCell") as! HomeTableViewCell
        cell.selectionStyle = .none

        cell.cellIndexPath = indexPath
        cell.delegate = self

        cell.updateUI(cellData: allTaskDataList, index: indexPath)

        return cell
    }

    // 셀 높이 설정(동적)
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// Paginig 처리
extension HomeViewController: UITableViewDelegate {
    
    // Pagination 기능 함수
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let height = scrollView.frame.size.height
        let contentOffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentOffset
        
        // 스크롤이 바닥에 닿았을 때
        if distanceFromBottom < height {
            if self.searchTextField.text == "" {
                self.todosVM.fetchAllToDoMore()
                
            } else {
                self.todosVM.fetchSearchToDoMore(searchText: self.searchTextField.text!)
            }
        }
    }
    
    // 왼쪽에 슬라이드 만들기(수정)
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let modity = UIContextualAction(style: .normal, title: "수정") { (UIContextualAction, UIView, success: @escaping (Bool) -> Void) in
            print("수정 클릭 됨")
            
            let editVC = AddEditTaskViewController()
            
            editVC.titleLabel.text = "할일 수정"
            editVC.subTitleLabel.text = "할일 수정"
            
            editVC.taskTextField.text = self.allTaskDataList[indexPath.section].rows[indexPath.row].title
            
            editVC.id = self.allTaskDataList[indexPath.section].rows[indexPath.row].id
            editVC.isDone = self.allTaskDataList[indexPath.section].rows[indexPath.row].isDone
            
            if self.allTaskDataList[indexPath.section].rows[indexPath.row].isDone == true {
                editVC.isDoneSwitch.isOn = true
            }
            
            // 델리겟 세팅
            editVC.delegate = self
            
            self.present(editVC, animated: true)
            
            success(true)
        }
        modity.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [modity])
    }
    
    // 오른쪽에 슬라이드 만들기(삭제)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let delete = UIContextualAction(style: .normal, title: "삭제") { (UIContextualAction, UIView, success: @escaping (Bool) -> Void) in
            print("삭제 클릭 됨")
            
            // 삭제 하기 전 Alert창 띄우기
            let alert = UIAlertController(title: "삭제", message: "해당 할일을 삭제하시겠습니까?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            alert.addAction(UIAlertAction(title: "삭제", style: .destructive, handler: { _ in
                
                // 삭제 할 아이디
                let targetId = self.allTaskDataList[indexPath.section].rows[indexPath.row].id
                self.todosVM.fetchDeleteTodo(id: targetId, indexpath: indexPath)
            }))
            self.present(alert, animated: true)
            
            success(true)
        }
        delete.backgroundColor = .systemRed
        
        return UISwipeActionsConfiguration(actions:[delete])
    }
    
}

#if DEBUG
import SwiftUI

extension UIViewController {
    
    struct VCRepresentable: UIViewControllerRepresentable {
        
        let uiViewController: UIViewController
        
        func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
            
        }
        
        func makeUIViewController(context: Context) -> some UIViewController {
            return uiViewController
        }
    }
    
    func getRepresentable() -> VCRepresentable {
        return VCRepresentable(uiViewController: self)
    }
}

struct HomeVC_Previews: PreviewProvider {
    static var previews: some View {
        HomeViewController().getRepresentable()
    }
}
#endif
