//
//  MKSFBXSSyncTimeCell.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/6.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSSyncTimeCellModel {
    var date: String = ""
}

protocol MKSFBXSSyncTimeCellDelegate: AnyObject {
    func bxs_swf_syncTimeCell_syncTimePressed()
}

class MKSFBXSSyncTimeCell: MKSwiftBaseCell {
    
    var dataModel: MKSFBXSSyncTimeCellModel? {
        didSet {
            updateContent()
        }
    }
    
    weak var delegate: MKSFBXSSyncTimeCellDelegate?
    
    // MARK: - Static Methods
    static func initCell(with tableView: UITableView) -> MKSFBXSSyncTimeCell {
        let identifier = "MKSFBXSSyncTimeCellIdenty"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKSFBXSSyncTimeCell
        if cell == nil {
            cell = MKSFBXSSyncTimeCell(style: .default, reuseIdentifier: identifier)
        }
        return cell!
    }
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Super Methods
    override func layoutSubviews() {
        super.layoutSubviews()
        syncButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-15)
            make.width.equalTo(50)
            make.top.equalToSuperview().offset(10)
            make.height.equalTo(30)
        }
        
        msgLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(15)
            make.trailing.equalTo(syncButton.snp.leading).offset(-10)
            make.centerY.equalTo(syncButton)
            make.height.equalTo(20)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(30)
            make.trailing.equalToSuperview().offset(-30)
            make.top.equalTo(syncButton.snp.bottom).offset(10)
            make.height.equalTo(20)
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(msgLabel)
        contentView.addSubview(syncButton)
        contentView.addSubview(dateLabel)        
    }
    
    // MARK: - Actions
    @objc private func syncButtonPressed() {
        delegate?.bxs_swf_syncTimeCell_syncTimePressed()
    }
    
    // MARK: - Update Content
    private func updateContent() {
        guard let dataModel = dataModel else { return }
        dateLabel.text = dataModel.date
    }
    
    // MARK: - UI Components (lazy loading)
    private lazy var msgLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(text: "Sync Beacon time")
    }()
    
    private lazy var syncButton: UIButton = {
        return MKSwiftUIAdaptor.createRoundedButton(title: "Sync",
                                                    target: self,
                                                    action: #selector(syncButtonPressed))
    }()
    
    private lazy var dateLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(14.0))
    }()
}
