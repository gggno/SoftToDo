import Foundation
import UIKit
import SnapKit

class HomeTableViewCell: UITableViewCell {
    static let identifier = "HomeTableViewCell"
    
    var cellIndexPath: IndexPath? = nil
    
    lazy var checkBoxButton: UIButton = {
        let button = UIButton(type: .system)
        
        button.setImage(UIImage(systemName: "square"), for: .normal)
        button.tintColor = UIColor.black
        button.addTarget(self, action: #selector(handlerCheckBoxBtnClicked(_:)), for: .touchUpInside)
        
        return button
    }()
    
    lazy var taskLabel: UILabel = {
        let label = UILabel()
        
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        
        label.textColor = UIColor(named: "TaskTextColor")
        
        return label
    }()
    
    lazy var timeLabel: UILabel = {
        let label = UILabel()
        
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor(named: "TaskTimeColor")
        
        return label
    }()
    
    lazy var taskBgView: UIView = {
        let view = UIView()
        view.addSubview(checkBoxButton)
        view.addSubview(taskLabel)
        view.addSubview(timeLabel)
        
        view.backgroundColor = .clear 
        
        return view
    }()
    
    // MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
        
        setupAutoLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureCell(isSelected: Bool) {
        checkBoxButton.setImage(UIImage(systemName: "checkmark.square.fill"), for: .normal)
        taskLabel.text?.strikeThrough()
        timeLabel.text?.strikeThrough()
    }
    
    @objc fileprivate func handlerCheckBoxBtnClicked(_ sender: UIButton) {
        print("handlerCheckBoxBtnClicked()")
        
        if let indexPath = cellIndexPath {
            NotificationCenter.default.post(name: .CellCheckEvent, object: indexPath)
        }
        
    }
    
    // 셀 UI 적용
    func updateUI(cellData: [AllTaskDataSection], index: IndexPath) {
        if cellData.count > 0 {

            let sectionData = cellData[index.section]
            let cellData = sectionData.rows[index.row]

            // 초기화
            self.taskLabel.attributedText = nil
            self.taskLabel.text = nil
            self.timeLabel.attributedText = nil
            self.timeLabel.text = nil

            if cellData.isDone == true { // 할일 완료일때(검정색 체크박스, 중간줄)
                self.checkBoxButton.setImage(UIImage(systemName: "checkmark.square.fill"), for: .normal)
                self.taskLabel.attributedText = cellData.title.strikeThrough()
                self.timeLabel.attributedText = cellData.time.strikeThrough()

            } else { // 할일 미완료일때(흰색 빈 박스, 일반 텍스트)
                self.checkBoxButton.setImage(UIImage(systemName: "square"), for: .normal)
                self.taskLabel.text = cellData.title
                self.timeLabel.text = cellData.time
            }
        }
    }
    
    // 셀 레이아웃 설정
    func setupAutoLayout() {
        // 테이블 뷰 셀은 contentView다.
        self.contentView.addSubview(taskBgView)
        
        checkBoxButton.snp.makeConstraints {
            $0.size.equalTo(25)
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(1)
        }
        
        taskLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(1)
            $0.leading.equalTo(checkBoxButton.snp.trailing).offset(13)
            $0.trailing.equalToSuperview()
        }
        
        timeLabel.snp.makeConstraints {
            $0.top.equalTo(taskLabel.snp.bottom).offset(13)
            $0.bottom.equalToSuperview().offset(-1)
            $0.leading.equalTo(taskLabel)
        }
        
        taskBgView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.leading.equalToSuperview().offset(18)
            $0.trailing.equalToSuperview().offset(-23)
            $0.bottom.equalToSuperview().offset(-21)
        }
    }
    
}
