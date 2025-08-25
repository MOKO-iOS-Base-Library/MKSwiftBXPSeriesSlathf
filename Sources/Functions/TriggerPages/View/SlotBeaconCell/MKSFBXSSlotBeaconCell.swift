//
//  MKSFBXSSlotBeaconCell.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/23.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSSlotBeaconCellModel {
    var major: String = ""
    var minor: String = ""
    var uuid: String = ""
}

protocol MKSFBXSSlotBeaconCellDelegate: AnyObject {
    func bxs_swf_advContent_majorChanged(major: String)
    func bxs_swf_advContent_minorChanged(minor: String)
    func bxs_swf_advContent_uuidChanged(uuid: String)
}

class MKSFBXSSlotBeaconCell: MKSwiftBaseCell {
    var dataModel: MKSFBXSSlotBeaconCellModel? {
        didSet {
            updateContent()
        }
    }
    
    weak var delegate: MKSFBXSSlotBeaconCellDelegate?
    
    // MARK: - Initialization
    static func initCell(with tableView: UITableView) -> MKSFBXSSlotBeaconCell {
        let identifier = "MKSFBXSSlotBeaconCellIdenty"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKSFBXSSlotBeaconCell
        if cell == nil {
            cell = MKSFBXSSlotBeaconCell(style: .default, reuseIdentifier: identifier)
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupConstraints()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(backView)
        backView.addSubview(leftIcon)
        backView.addSubview(typeLabel)
        backView.addSubview(majorLabel)
        backView.addSubview(majorTextField)
        backView.addSubview(minorLabel)
        backView.addSubview(minorTextField)
        backView.addSubview(uuidLabel)
        backView.addSubview(hexLabel)
        backView.addSubview(uuidTextField)
    }
    
    private func setupConstraints() {
        backView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        leftIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(22)
            make.top.equalToSuperview().offset(10)
            make.height.equalTo(22)
        }
        
        typeLabel.snp.makeConstraints { make in
            make.left.equalTo(leftIcon.snp.right).offset(15)
            make.right.equalToSuperview().offset(-15)
            make.centerY.equalTo(leftIcon)
            make.height.equalTo(typeLabel.font.lineHeight)
        }
        
        majorLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(80)
            make.centerY.equalTo(majorTextField)
            make.height.equalTo(majorLabel.font.lineHeight)
        }
        
        majorTextField.snp.makeConstraints { make in
            make.left.equalTo(majorLabel.snp.right).offset(40)
            make.right.equalToSuperview().offset(-15)
            make.top.equalTo(leftIcon.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        
        minorLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(80)
            make.centerY.equalTo(minorTextField)
            make.height.equalTo(minorLabel.font.lineHeight)
        }
        
        minorTextField.snp.makeConstraints { make in
            make.left.equalTo(minorLabel.snp.right).offset(40)
            make.right.equalToSuperview().offset(-15)
            make.top.equalTo(majorTextField.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        
        uuidLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(80)
            make.centerY.equalTo(uuidTextField)
            make.height.equalTo(uuidLabel.font.lineHeight)
        }
        
        hexLabel.snp.makeConstraints { make in
            make.right.equalTo(uuidTextField.snp.left).offset(-2)
            make.width.equalTo(30)
            make.centerY.equalTo(uuidTextField)
            make.height.equalTo(hexLabel.font.lineHeight)
        }
        
        uuidTextField.snp.makeConstraints { make in
            make.left.equalTo(uuidLabel.snp.right).offset(40)
            make.right.equalToSuperview().offset(-15)
            make.top.equalTo(minorTextField.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
    }
    
    private func updateContent() {
        guard let model = dataModel else { return }
        majorTextField.text = model.major
        minorTextField.text = model.minor
        uuidTextField.text = model.uuid
    }
    
    // MARK: - UI Components
    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
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
    
    private lazy var majorLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(text: "Major")
    }()
    
    private lazy var majorTextField: MKSwiftTextField = {
        let textField = MKSwiftUIAdaptor.createTextField(placeholder: "0~65535",textType: .realNumberOnly)
        textField.maxLength = 5
        textField.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_swf_advContent_majorChanged(major: text)
        }
        return textField
    }()
    
    private lazy var minorLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(text: "Minor")
    }()
    
    private lazy var minorTextField: MKSwiftTextField = {
        let textField = MKSwiftUIAdaptor.createTextField(placeholder: "0~65535",textType: .realNumberOnly)
        textField.maxLength = 5
        textField.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_swf_advContent_minorChanged(minor: text)
        }
        return textField
    }()
    
    private lazy var uuidLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(text: "UUID")
    }()
    
    private lazy var hexLabel: UILabel = {
        let label = UILabel()
        label.textColor = Color.defaultText
        label.font = Font.MKFont(12.0)
        label.textAlignment = .right
        label.text = "0x"
        return label
    }()
    
    private lazy var uuidTextField: MKSwiftTextField = {
        let textField = MKSwiftUIAdaptor.createTextField(placeholder: "16bytes",textType: .hexCharOnly)
        textField.maxLength = 32
        textField.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_swf_advContent_uuidChanged(uuid: text)
        }
        return textField
    }()
}
