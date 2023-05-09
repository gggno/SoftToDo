import UIKit
import RxSwift
import RxCocoa

class AddEditTaskViewController: UIViewController {
    
    var id = 0
    var titleText = ""
    var isDone = false
    var delegate: TaskUpdateDelegate? = nil
    
    var addEditVM: AddEditTaskViewModel = AddEditTaskViewModel()
    
    var disposeBag = DisposeBag()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        
        label.text = "할일 추가"
        label.font = UIFont.systemFont(ofSize: 17, weight: .heavy)
        
        return label
    }()
    
    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        
        label.text = "할일 추가"
        label.font = UIFont.systemFont(ofSize: 34, weight: .heavy)
        
        return label
    }()
    
    lazy var taskTitle: UILabel = {
        let label = UILabel()
        
        label.text = "할일"
        label.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        
        return label
    }()
    
    lazy var taskTextField: UITextField = {
        let textField = UITextField()
        
        textField.leftPadding()
        textField.font = UIFont(name: "SourceSansPro-SemiBold", size: 16)
        textField.attributedPlaceholder = NSAttributedString(string: "Lorem ipsum dolor", attributes: [NSAttributedString.Key.foregroundColor : UIColor(named: "SearchPlaceholderColor")])
        
        textField.backgroundColor = UIColor(named: "SearchbgColor")
        
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor(named: "SearchLineColor")?.cgColor
        
        return textField
    }()
    
    lazy var completeLabel: UILabel = {
        let label = UILabel()
        
        label.text = "완료"
        label.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        
        return label
    }()
    
    lazy var isDoneSwitch: UISwitch = {
        let isDoneSwitch = UISwitch()
        
        return isDoneSwitch
    }()
    
    lazy var completeButton: UIButton = {
        let button = UIButton()
        
        button.backgroundColor = UIColor(named: "CompleteBtnColor")
        button.setTitle("완료", for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 12
        
        return button
    }()
    
    lazy var bottomTextLabel: UILabel = {
        let label = UILabel()
        
        label.text = "If you disable today, the task will be considered as tomorrow"
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(named: "TaskTimeColor")
        
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(named: "vbgColor")
        
        addVCLayoutSetting()
        
        // 완료 버튼 클릭
        completeButton.rx.tap
            .bind(onNext: { [weak self] _ in
                guard let self = self else {return}
                // 여섯 글자 이상이면
                if taskTextField.text!.count >= 6 {
                    if titleLabel.text == "할일 추가" { // 할일 추가인 경우
                        print("ADD completedBtnClicked")
                        addEditVM.fetchAddTodo(title: taskTextField.text!, isDone: false, completion: {
                            self.delegate?.taskUpdate()
                        })
                        
                    } else { // 할일 수정인 경우
                        print("EDIT completedBtnClicked")
                        addEditVM.fetchEditTodo(id: id, title: taskTextField.text!, isDone: isDone) {
                            self.delegate?.taskUpdate()
                        }
                    }
                    dismiss(animated: true)
                    
                } else { // 여섯 글자 미만일 경우
                    let alertController = UIAlertController(title: "글자수 부족", message: "여섯 글자 이상 입력해주세요!", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: {_ in }))
                    present(alertController, animated: true, completion: nil)
                }
            }).disposed(by: disposeBag)
        
        // 완료 미완료 여부를 스위치를 통해 전달
        isDoneSwitch.rx.isOn
            .bind(onNext: { [weak self] enabled in
                guard let self = self else {return}
                if enabled {
                    isDone = true
                } else {
                    isDone = false
                }
            }).disposed(by: disposeBag)
    }
    
    // 전체 레이아웃 구성
    func addVCLayoutSetting() {
        self.view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(26)
        }
        
        self.view.addSubview(subTitleLabel)
        subTitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(48)
            $0.leading.equalToSuperview().offset(29)
            $0.trailing.equalToSuperview().offset(-49)
        }
        
        self.view.addSubview(taskTitle)
        self.taskTitle.snp.makeConstraints {
            $0.top.equalTo(subTitleLabel.snp.bottom).offset(37)
            $0.leading.equalTo(subTitleLabel.snp.leading)
        }
        
        self.view.addSubview(taskTextField)
        self.taskTextField.snp.makeConstraints {
            $0.width.equalTo(241)
            $0.height.equalTo(31)
            $0.leading.equalTo(taskTitle.snp.trailing).offset(33)
            $0.centerY.equalTo(taskTitle.snp.centerY)
        }
        
        self.view.addSubview(completeLabel)
        self.completeLabel.snp.makeConstraints {
            $0.leading.equalTo(taskTitle.snp.leading)
            $0.top.equalTo(taskTitle.snp.bottom).offset(102)
        }
        
        self.view.addSubview(isDoneSwitch)
        self.isDoneSwitch.snp.makeConstraints {
            $0.centerY.equalTo(completeLabel.snp.centerY)
            $0.trailing.equalToSuperview().offset(-34)
        }
        
        self.view.addSubview(completeButton)
        self.completeButton.snp.makeConstraints {
            $0.height.equalTo(46)
            $0.leading.equalTo(completeLabel.snp.leading)
            $0.trailing.equalTo(isDoneSwitch.snp.trailing)
            $0.top.equalTo(completeLabel.snp.bottom).offset(62)
        }
        
        self.view.addSubview(bottomTextLabel)
        self.bottomTextLabel.snp.makeConstraints {
            $0.height.equalTo(36)
            $0.leading.equalTo(completeLabel.snp.leading)
            $0.trailing.equalTo(isDoneSwitch.snp.trailing)
            $0.top.equalTo(completeButton.snp.bottom).offset(15)
        }
    }
    
}
