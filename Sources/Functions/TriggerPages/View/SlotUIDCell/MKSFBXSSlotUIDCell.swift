//
//  MKSFBXSSlotUIDCell.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/24.
//

// MKSFBXSSlotUIDCell.swift
import UIKit
import SnapKit
import MKBaseSwiftModule

// MARK: - Models and Protocols

class MKSFBXSSlotUIDCellModel {
    var namespaceID: String = ""
    var instanceID: String = ""
}

protocol MKSFBXSSlotUIDCellDelegate: AnyObject {
    func bxs_swf_advContent_namespaceIDChanged(_ text: String)
    func bxs_swf_advContent_instanceIDChanged(_ text: String)
}

class MKSFBXSSlotUIDCell: MKSwiftBaseCell {
    
    // MARK: - Properties
    
    var dataModel: MKSFBXSSlotUIDCellModel? {
        didSet {
            updateContent()
        }
    }
    
    weak var delegate: MKSFBXSSlotUIDCellDelegate?
    
    // MARK: - Initialization
    
    static func initCell(with tableView: UITableView) -> MKSFBXSSlotUIDCell {
        let identifier = "MKSFBXSSlotUIDCellIdenty"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKSFBXSSlotUIDCell
        if cell == nil {
            cell = MKSFBXSSlotUIDCell(style: .default, reuseIdentifier: identifier)
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
        backView.addSubview(nameLabel)
        backView.addSubview(nameTextField)
        backView.addSubview(hexNameLabel)
        backView.addSubview(instanceLabel)
        backView.addSubview(instanceTextField)
        backView.addSubview(hexInstanceLabel)
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
        
        nameLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(120)
            make.centerY.equalTo(nameTextField.snp.centerY)
            make.height.equalTo(nameLabel.font.lineHeight)
        }
        
        hexNameLabel.snp.remakeConstraints { make in
            make.left.equalTo(nameLabel.snp.right).offset(5)
            make.width.equalTo(30)
            make.centerY.equalTo(nameTextField.snp.centerY)
            make.height.equalTo(hexNameLabel.font.lineHeight)
        }
        
        nameTextField.snp.remakeConstraints { make in
            make.left.equalTo(hexNameLabel.snp.right).offset(5)
            make.right.equalToSuperview().offset(-15)
            make.top.equalTo(leftIcon.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        
        instanceLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(120)
            make.centerY.equalTo(instanceTextField.snp.centerY)
            make.height.equalTo(instanceLabel.font.lineHeight)
        }
        
        hexInstanceLabel.snp.remakeConstraints { make in
            make.left.equalTo(instanceLabel.snp.right).offset(5)
            make.width.equalTo(30)
            make.centerY.equalTo(instanceTextField.snp.centerY)
            make.height.equalTo(hexInstanceLabel.font.lineHeight)
        }
        
        instanceTextField.snp.remakeConstraints { make in
            make.left.equalTo(hexInstanceLabel.snp.right).offset(5)
            make.right.equalToSuperview().offset(-15)
            make.top.equalTo(nameTextField.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
    }
    
    // MARK: - Private Methods
    
    private func updateContent() {
        guard let dataModel = dataModel else { return }
        nameTextField.text = dataModel.namespaceID
        instanceTextField.text = dataModel.instanceID
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
    
    private lazy var nameLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(text: "Namespace ID")
    }()
    
    private lazy var hexNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = Color.defaultText
        label.font = Font.MKFont(12.0)
        label.textAlignment = .right
        label.text = "0x"
        return label
    }()
    
    private lazy var nameTextField: MKSwiftTextField = {
        let field = MKSwiftUIAdaptor.createTextField(placeholder: "10bytes",textType: .hexCharOnly)
        field.maxLength = 20
        field.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_swf_advContent_namespaceIDChanged(text)
        }
        return field
    }()
    
    private lazy var instanceLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(text: "Instance ID")
    }()
    
    private lazy var hexInstanceLabel: UILabel = {
        let label = UILabel()
        label.textColor = Color.defaultText
        label.font = Font.MKFont(12.0)
        label.textAlignment = .right
        label.text = "0x"
        return label
    }()
    
    private lazy var instanceTextField: MKSwiftTextField = {
        let field = MKSwiftUIAdaptor.createTextField(placeholder: "6bytes",textType: .hexCharOnly)
        field.maxLength = 12
        field.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_swf_advContent_instanceIDChanged(text)
        }
        return field
    }()
}
