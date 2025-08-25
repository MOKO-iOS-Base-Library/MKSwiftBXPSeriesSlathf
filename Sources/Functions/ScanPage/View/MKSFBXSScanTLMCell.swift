//
//  MKSFBXSScanTLMCell.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/6/27.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftBeaconXCustomUI

class MKSFBXSScanTLMCellModel: MKSwiftBXScanBaseModel {
    var version: String = ""
    var mvPerbit: Int = 0
    var temperature: String = ""
    var advertiseCount: String = ""
    var deciSecondsSinceBoot: String = ""
    
    override init() {}
}

class MKSFBXSScanTLMCell: MKSwiftBaseCell {
    var dataModel: MKSFBXSScanTLMCellModel? {
        didSet {
            updateContent()
        }
    }
    
    // MARK: - Constants
    private let offsetX: CGFloat = 10
    private let offsetY: CGFloat = 10
    private let leftIconWidth: CGFloat = 7
    private let leftIconHeight: CGFloat = 7
    private let msgFont = Font.MKFont(12.0)
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    class func initCell(with tableView: UITableView) -> MKSFBXSScanTLMCell {
        let identifier = "MKSFBXSScanTLMCellIdenty"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKSFBXSScanTLMCell
        if cell == nil {
            cell = MKSFBXSScanTLMCell(style: .default, reuseIdentifier: identifier)
        }
        return cell!
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupConstraints()
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        contentView.addSubview(leftIcon)
        contentView.addSubview(typeLabel)
        contentView.addSubview(batteryMsgLabel)
        contentView.addSubview(batteryLabel)
        contentView.addSubview(temperMsgLabel)
        contentView.addSubview(temperatureLabel)
        contentView.addSubview(advLabel)
        contentView.addSubview(advValueLabel)
        contentView.addSubview(timeSinceLabel)
        contentView.addSubview(timeLabel)
    }
    
    private func setupConstraints() {
        leftIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(offsetX)
            make.width.equalTo(leftIconWidth)
            make.top.equalToSuperview().offset(offsetY)
            make.height.equalTo(leftIconHeight)
        }
        
        typeLabel.snp.makeConstraints { make in
            make.left.equalTo(leftIcon.snp.right).offset(5)
            make.right.equalToSuperview().offset(-offsetX)
            make.centerY.equalTo(leftIcon)
            make.height.equalTo(18) // Approximate line height for 15pt font
        }
        
        batteryMsgLabel.snp.makeConstraints { make in
            make.left.equalTo(typeLabel)
            make.width.equalTo(120)
            make.top.equalTo(typeLabel.snp.bottom).offset(5)
            make.height.equalTo(14) // Approximate line height for 12pt font
        }
        
        batteryLabel.snp.makeConstraints { make in
            make.left.equalTo(batteryMsgLabel.snp.right).offset(10)
            make.right.equalToSuperview().offset(-offsetX)
            make.centerY.equalTo(batteryMsgLabel)
            make.height.equalTo(batteryMsgLabel)
        }
        
        temperMsgLabel.snp.makeConstraints { make in
            make.left.equalTo(batteryMsgLabel)
            make.width.equalTo(batteryMsgLabel)
            make.top.equalTo(batteryMsgLabel.snp.bottom).offset(5)
            make.height.equalTo(batteryMsgLabel)
        }
        
        temperatureLabel.snp.makeConstraints { make in
            make.left.equalTo(batteryLabel)
            make.right.equalToSuperview().offset(-offsetX)
            make.centerY.equalTo(temperMsgLabel)
            make.height.equalTo(temperMsgLabel)
        }
        
        advLabel.snp.makeConstraints { make in
            make.left.equalTo(batteryMsgLabel)
            make.width.equalTo(batteryMsgLabel)
            make.top.equalTo(temperMsgLabel.snp.bottom).offset(5)
            make.height.equalTo(batteryMsgLabel)
        }
        
        advValueLabel.snp.makeConstraints { make in
            make.left.equalTo(batteryLabel)
            make.right.equalToSuperview().offset(-offsetX)
            make.centerY.equalTo(advLabel)
            make.height.equalTo(advLabel)
        }
        
        timeSinceLabel.snp.makeConstraints { make in
            make.left.equalTo(batteryMsgLabel)
            make.width.equalTo(batteryMsgLabel)
            make.top.equalTo(advLabel.snp.bottom).offset(5)
            make.height.equalTo(batteryMsgLabel)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(batteryLabel)
            make.right.equalToSuperview().offset(-offsetX)
            make.centerY.equalTo(timeSinceLabel)
            make.height.equalTo(timeSinceLabel)
        }
    }
    
    private func createLabel(text: String = "") -> UILabel {
        let label = UILabel()
        label.textColor = Color.rgb(184, 184, 184)
        label.textAlignment = .left
        label.font = msgFont
        label.text = text
        return label
    }
    
    private func updateContent() {
        guard let dataModel = dataModel else { return }
        
        if dataModel.mvPerbit <= 100 {
            batteryLabel.text = "\(dataModel.mvPerbit)%"
        } else {
            batteryLabel.text = "\(dataModel.mvPerbit)mV"
        }
        
        if let tempValue = Float(dataModel.temperature) {
            temperatureLabel.text = String(format: "%.1f°C", tempValue)
        }
        
        advValueLabel.text = dataModel.advertiseCount
        timeLabel.text = getTimeWithSec(Float(dataModel.deciSecondsSinceBoot) ?? 0)
    }
    
    private func getTimeWithSec(_ second: Float) -> String? {
        guard let seconds = Float(dataModel?.deciSecondsSinceBoot ?? "0") else { return nil }
        let minutes = floor(seconds / 60)
        let sec = seconds - minutes * 60
        let hours1 = floor(seconds / (60 * 60))
        let minutesFinal = minutes - hours1 * 60
        let day = floor(hours1 / 24)
        let hoursFinal = hours1 - 24 * day
        
        return String(format: "%dd%dh%dm%.1fs", Int(day), Int(hoursFinal), Int(minutesFinal), sec)
    }
    
    // MARK: - UI Components
    private lazy var leftIcon: UIImageView = {
        let view = UIImageView()
        view.image = moduleIcon(name: "bxs_swf_littleBluePoint,png", in: .module)
        return view
    }()
    
    private lazy var typeLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(text: "Unencrypted TLM")
    }()
    
    private lazy var batteryMsgLabel: UILabel = createLabel(text: "Battery level")
    private lazy var batteryLabel: UILabel = createLabel(text: "0mV")
    private lazy var temperMsgLabel: UILabel = createLabel(text: "Chip temperature")
    private lazy var temperatureLabel: UILabel = createLabel(text: "0°C")
    private lazy var advLabel: UILabel = createLabel(text: "ADV count")
    private lazy var advValueLabel: UILabel = createLabel(text: "0")
    private lazy var timeSinceLabel: UILabel = createLabel(text: "Running time")
    private lazy var timeLabel: UILabel = createLabel(text: "0s")
}
