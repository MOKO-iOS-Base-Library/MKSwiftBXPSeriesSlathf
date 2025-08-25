//
//  MKSFBXSFilterTempHistoryHeaderView.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/19.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

// MARK: - Protocol
protocol MKSFBXSFilterTempHistoryHeaderViewDelegate: AnyObject {
    func bxs_swf_filterHTHistoryHeaderView_switchButtonPressed(_ selected: Bool)
    func bxs_swf_filterHTHistoryHeaderView_exportButtonPressed()
}

class MKSFBXSFilterTempHistoryHeaderView: UIView {
    
    // MARK: - Protocol
    weak var delegate: MKSFBXSFilterTempHistoryHeaderViewDelegate?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        switchButton.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(40)
            make.top.equalTo(5)
            make.height.equalTo(30)
        }
        
        switchLabel.snp.makeConstraints { make in
            make.left.equalTo(switchButton.snp.left)
            make.right.equalTo(switchButton.snp.right)
            make.top.equalTo(switchButton.snp.bottom).offset(2)
            make.height.equalTo(Font.MKFont(10.0).lineHeight)
        }
        
        exportButton.snp.makeConstraints { make in
            make.left.equalTo(switchButton.snp.right).offset(30)
            make.width.equalTo(40)
            make.centerY.equalTo(switchButton.snp.centerY)
            make.height.equalTo(30)
        }
        
        exportLabel.snp.makeConstraints { make in
            make.left.equalTo(exportButton.snp.left)
            make.right.equalTo(exportButton.snp.right)
            make.top.equalTo(exportButton.snp.bottom).offset(2)
            make.height.equalTo(Font.MKFont(10.0).lineHeight)
        }
        
        sumLabel.snp.makeConstraints { make in
            make.left.equalTo(exportButton.snp.right).offset(30)
            make.right.equalTo(-15)
            make.centerY.equalTo(switchButton.snp.centerY)
            make.height.equalTo(Font.MKFont(10.0).lineHeight)
        }
    }
    
    // MARK: - Public Methods
    func updateSumRecord(_ record: String) {
        sumLabel.text = "Records: \(record)"
    }
    
    // MARK: - Event Methods
    @objc private func switchButtonPressed() {
        switchButton.isSelected = !switchButton.isSelected
        let icon = switchButton.isSelected ? moduleIcon(name: "bxs_swf_exportHT_curveSelected", in: .module) : moduleIcon(name: "bxs_swf_exportHT_tableSelected", in: .module)
        switchButton.setImage(icon, for: .normal)
        delegate?.bxs_swf_filterHTHistoryHeaderView_switchButtonPressed(switchButton.isSelected)
    }
    
    @objc private func exportButtonPressed() {
        delegate?.bxs_swf_filterHTHistoryHeaderView_exportButtonPressed()
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        addSubview(switchButton)
        addSubview(switchLabel)
        addSubview(exportButton)
        addSubview(exportLabel)
        addSubview(sumLabel)
    }
    
    // MARK: - UI Components
    private lazy var exportButton: UIButton = {
        let button = UIButton()
        button.setImage(moduleIcon(name: "bxs_swf_slotExportEnableIcon", in: .module), for: .normal)
        button.addTarget(self, action: #selector(exportButtonPressed), for: .touchUpInside)
        return button
    }()
    
    private lazy var exportLabel: UILabel = {
        let label = UILabel()
        label.textColor = Color.defaultText
        label.textAlignment = .center
        label.font = Font.MKFont(10.0)
        label.text = "Export"
        return label
    }()
    
    private lazy var switchButton: UIButton = {
        let button = UIButton()
        button.setImage(moduleIcon(name: "bxs_swf_exportHT_tableSelected", in: .module), for: .normal)
        button.addTarget(self, action: #selector(switchButtonPressed), for: .touchUpInside)
        return button
    }()
    
    private lazy var switchLabel: UILabel = {
        let label = UILabel()
        label.textColor = Color.defaultText
        label.textAlignment = .center
        label.font = Font.MKFont(10.0)
        label.text = "Display"
        return label
    }()
    
    private lazy var sumLabel: UILabel = {
        let label = UILabel()
        label.textColor = Color.defaultText
        label.textAlignment = .left
        label.font = Font.MKFont(13.0)
        label.text = "Records: N/A"
        return label
    }()
}
