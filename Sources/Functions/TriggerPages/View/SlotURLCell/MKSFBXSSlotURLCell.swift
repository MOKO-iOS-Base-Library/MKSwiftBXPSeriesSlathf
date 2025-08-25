//
//  MKSFBXSSlotURLCell.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/24.
//

// MKSFBXSSlotURLCell.swift
import UIKit
import SnapKit
import MKBaseSwiftModule

// MARK: - Models and Protocols

class MKSFBXSSlotURLCellModel {
    // 0:@"http://www.",1:@"https://www.",2:@"http://",3:@"https://"
    var urlType: Int = 0
    var urlContent: String = ""
}

protocol MKSFBXSSlotURLCellDelegate: AnyObject {
    func bxs_swf_advContent_urlTypeChanged(_ urlType: Int)
    func bxs_swf_advContent_urlContentChanged(_ content: String)
}

class MKSFBXSSlotURLCell: MKSwiftBaseCell {
    
    // MARK: - Properties
    
    var dataModel: MKSFBXSSlotURLCellModel? {
        didSet {
            updateContent()
        }
    }
    
    weak var delegate: MKSFBXSSlotURLCellDelegate?
    
    // MARK: - Initialization
    
    static func initCell(with tableView: UITableView) -> MKSFBXSSlotURLCell {
        let identifier = "MKSFBXSSlotURLCellIdenty"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKSFBXSSlotURLCell
        if cell == nil {
            cell = MKSFBXSSlotURLCell(style: .default, reuseIdentifier: identifier)
        }
        return cell!
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        contentView.addSubview(backView)
        backView.addSubview(leftIcon)
        backView.addSubview(typeLabel)
        backView.addSubview(msgLabel)
        backView.addSubview(urlTypeLabel)
        backView.addSubview(textField)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backView.snp.remakeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
        
        leftIcon.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(22)
            make.top.equalToSuperview().offset(10)
            make.height.equalTo(22)
        }
        
        typeLabel.snp.remakeConstraints { make in
            make.left.equalTo(leftIcon.snp.right).offset(15)
            make.right.equalToSuperview().offset(-15)
            make.centerY.equalTo(leftIcon.snp.centerY)
            make.height.equalTo(typeLabel.font.lineHeight)
        }
        
        msgLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(40)
            make.centerY.equalTo(textField.snp.centerY)
            make.height.equalTo(msgLabel.font.lineHeight)
        }
        
        urlTypeLabel.snp.remakeConstraints { make in
            make.left.equalTo(msgLabel.snp.right).offset(15)
            make.width.equalTo(80)
            make.centerY.equalTo(textField.snp.centerY)
            make.height.equalTo(urlTypeLabel.font.lineHeight)
        }
        
        textField.snp.remakeConstraints { make in
            make.left.equalTo(urlTypeLabel.snp.right).offset(5)
            make.right.equalToSuperview().offset(-15)
            make.top.equalTo(leftIcon.snp.bottom).offset(15)
            make.height.equalTo(30)
        }
    }
    
    // MARK: - Event Handlers
    
    @objc private func urlTypeLabelPressed() {
        var index = 0
        for (i, type) in urlTypeList.enumerated() {
            if urlTypeLabel.text == type {
                index = i
                break
            }
        }
        
        let pickerView = MKSwiftPickerView()
        pickerView.showPickView(with: urlTypeList, selectedRow: index) { [weak self] currentRow in
            guard let self = self else { return }
            self.urlTypeLabel.text = self.urlTypeList[currentRow]
            self.delegate?.bxs_swf_advContent_urlTypeChanged(currentRow)
        }
    }
    
    // MARK: - Private Methods
    
    private func updateContent() {
        guard let dataModel = dataModel else { return }
        urlTypeLabel.text = urlTypeList[dataModel.urlType]
        textField.text = dataModel.urlContent
    }
    
    // MARK: - UI Components (lazy loading)
    
    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8.0
        return view
    }()
    
    private lazy var leftIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = moduleIcon(name: "bxs_swf_slotAdvContent", in: .module)
        return imageView
    }()
    
    private lazy var typeLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(text: "Adv content")
    }()
    
    private lazy var msgLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(14.0) ,text: "URL")
    }()
    
    private lazy var urlTypeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = Color.rgb(111, 111, 111)
        label.font = Font.MKFont(12.0)
        label.text = "http://www."
        
        label.layer.masksToBounds = true
        label.layer.borderWidth = 0.5
        label.layer.borderColor = UIColor.lightGray.cgColor
        label.layer.cornerRadius = 2.0
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(urlTypeLabelPressed))
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tap)
        
        return label
    }()
    
    private lazy var textField: MKSwiftTextField = {
        let field = MKSwiftUIAdaptor.createTextField(placeholder: "mokoblue.com/",textType: .normal)
        field.maxLength = 17
        field.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_swf_advContent_urlContentChanged(text)
        }
        return field
    }()
    
    private lazy var urlTypeList: [String] = {
        return ["http://www.", "https://www.", "http://", "https://"]
    }()
}
