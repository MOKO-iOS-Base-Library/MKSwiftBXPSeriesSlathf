//
//  MKSFBXSRemoteReminderCell.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/21.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSRemoteReminderCellModel {
    var msg: String = ""
    var index: Int = 0
}

protocol MKSFBXSRemoteReminderCellDelegate: AnyObject {
    func bxs_swf_remindButtonPressed(index: Int)
}

class MKSFBXSRemoteReminderCell: MKSwiftBaseCell {
    
    // MARK: - Properties
    var dataModel: MKSFBXSRemoteReminderCellModel? {
        didSet {
            guard let model = dataModel else { return }
            msgLabel.text = model.msg
        }
    }
    
    weak var delegate: MKSFBXSRemoteReminderCellDelegate?
    
    // MARK: - Class Method
    class func cell(with tableView: UITableView) -> MKSFBXSRemoteReminderCell {
        let identifier = "MKSFBXSRemoteReminderCellIdenty"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKSFBXSRemoteReminderCell
        if cell == nil {
            cell = MKSFBXSRemoteReminderCell(style: .default, reuseIdentifier: identifier)
        }
        return cell!
    }
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(msgLabel)
        contentView.addSubview(remindButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        remindButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-15)
            make.width.equalTo(60)
            make.centerY.equalToSuperview()
            make.height.equalTo(35)
        }
        
        msgLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.right.equalTo(remindButton.snp.left).offset(-15)
            make.centerY.equalToSuperview()
            make.height.equalTo(UIFont.systemFont(ofSize: 15).lineHeight)
        }
    }
    
    // MARK: - Action
    @objc private func remindButtonPressed() {
        guard let index = dataModel?.index else { return }
        delegate?.bxs_swf_remindButtonPressed(index: index)
    }
    
    // MARK: - UI Components
    private lazy var msgLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel()
    }()
    
    private lazy var remindButton: UIButton = {
        return MKSwiftUIAdaptor.createRoundedButton(title: "Remind",
                                                    target: self,
                                                    action: #selector(remindButtonPressed))
    }()
}
