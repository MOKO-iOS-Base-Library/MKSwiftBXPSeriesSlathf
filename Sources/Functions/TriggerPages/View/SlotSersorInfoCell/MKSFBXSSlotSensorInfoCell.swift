//
//  MKSFBXSSlotSensorInfoCell.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/24.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

// MARK: - Models and Protocols

class MKSFBXSSlotSensorInfoCellModel {
    var deviceName: String = ""
    var tagID: String = ""
}

protocol MKSFBXSSlotSensorInfoCellDelegate: AnyObject {
    func bxs_swf_advContent_tagInfo_deviceNameChanged(_ text: String)
    func bxs_swf_advContent_tagInfo_tagIDChanged(_ text: String)
}

class MKSFBXSSlotSensorInfoCell: MKSwiftBaseCell {
    
    // MARK: - Properties
    
    var dataModel: MKSFBXSSlotSensorInfoCellModel? {
        didSet {
            updateContent()
        }
    }
    
    weak var delegate: MKSFBXSSlotSensorInfoCellDelegate?

    // MARK: - Initialization
    
    static func initCell(with tableView: UITableView) -> MKSFBXSSlotSensorInfoCell {
        let identifier = "MKSFBXSSlotSensorInfoCellIdenth"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKSFBXSSlotSensorInfoCell
        if cell == nil {
            cell = MKSFBXSSlotSensorInfoCell(style: .default, reuseIdentifier: identifier)
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
        backView.addSubview(icon)
        backView.addSubview(msgLabel)
        backView.addSubview(deviceNameLabel)
        backView.addSubview(nameTextField)
        backView.addSubview(tagIDLabel)
        backView.addSubview(xLabel)
        backView.addSubview(tagIDTextField)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backView.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(5)
            make.right.equalToSuperview().offset(-5)
            make.top.equalToSuperview().offset(5)
            make.bottom.equalToSuperview().offset(-5)
        }
        
        icon.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.width.equalTo(22)
            make.top.equalToSuperview().offset(5)
            make.height.equalTo(22)
        }
        
        msgLabel.snp.remakeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalTo(icon.snp.centerY)
            make.height.equalTo(msgLabel.font.lineHeight)
        }
        
        deviceNameLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.width.equalTo(110)
            make.centerY.equalTo(nameTextField.snp.centerY)
            make.height.equalTo(deviceNameLabel.font.lineHeight)
        }
        
        nameTextField.snp.remakeConstraints { make in
            make.left.equalTo(deviceNameLabel.snp.right).offset(30)
            make.right.equalToSuperview().offset(-10)
            make.top.equalTo(icon.snp.bottom).offset(10)
            make.height.equalTo(25)
        }
        
        tagIDLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.width.equalTo(110)
            make.centerY.equalTo(tagIDTextField.snp.centerY)
            make.height.equalTo(tagIDLabel.font.lineHeight)
        }
        
        xLabel.snp.remakeConstraints { make in
            make.left.equalTo(tagIDLabel.snp.right).offset(10)
            make.width.equalTo(15)
            make.centerY.equalTo(tagIDTextField.snp.centerY)
            make.height.equalTo(xLabel.font.lineHeight)
        }
        
        tagIDTextField.snp.remakeConstraints { make in
            make.left.equalTo(xLabel.snp.right).offset(5)
            make.right.equalToSuperview().offset(-10)
            make.top.equalTo(nameTextField.snp.bottom).offset(10)
            make.height.equalTo(25)
        }
    }
    
    // MARK: - Private Methods
    
    private func updateContent() {
        guard let dataModel = dataModel else { return }
        nameTextField.text = dataModel.deviceName
        tagIDTextField.text = dataModel.tagID
    }
    
    // MARK: - UI Components (lazy loading)
    
    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8.0
        return view
    }()
    
    private lazy var icon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = moduleIcon(name: "bxs_swf_slotAdvContent", in: .module)
        return imageView
    }()
    
    private lazy var msgLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(text: "Adv content")
    }()
    
    private lazy var deviceNameLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(13.0), text: "Device name")
    }()
    
    private lazy var nameTextField: MKSwiftTextField = {
        let field = MKSwiftUIAdaptor.createTextField(placeholder: "1 - 20 characters.",textType: .normal)
        field.maxLength = 20
        field.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_swf_advContent_tagInfo_deviceNameChanged(text)
        }
        return field
    }()
    
    private lazy var tagIDLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(13.0), text: "Tag ID")
    }()
    
    private lazy var xLabel: UILabel = {
        let label = UILabel()
        label.textColor = Color.defaultText
        label.textAlignment = .right
        label.font = Font.MKFont(11.0)
        label.text = "0x"
        return label
    }()
    
    private lazy var tagIDTextField: MKSwiftTextField = {
        let field = MKSwiftUIAdaptor.createTextField(placeholder: "1-6 bytes",textType: .hexCharOnly)
        field.maxLength = 12
        field.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_swf_advContent_tagInfo_tagIDChanged(text)
        }
        return field
    }()
}
