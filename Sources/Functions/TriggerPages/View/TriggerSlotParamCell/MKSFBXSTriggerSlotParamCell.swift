//
//  MKSFBXSTriggerSlotParamCell.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/24.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

// MARK: - Models and Protocols

class MKSFBXSTriggerSlotParamCellModel {
    var cellType: MKSFBXSSlotType = .null
    var interval: String = ""
    var needChangeAdvDurationRange: Bool = false
    var advDurationMaxValue: Int = 0
    var advDuration: String = ""
    var rssi: Int = 0
    /*
     0:-20dBm
     1:-16dBm
     2:-12dBm
     3:-8dBm
     4:-4dBm
     5:0dBm
     6:3dBm
     7:4dBm
     8:6dBm
     */
    var txPower: Int = 0
}

protocol MKSFBXSTriggerSlotParamCellDelegate: AnyObject {
    func bxs_swf_triggerSlotParam_advIntervalChanged(_ interval: String)
    func bxs_swf_triggerSlotParam_advDurationChanged(_ duration: String)
    func bxs_swf_triggerSlotParam_rssiChanged(_ rssi: Int)
    func bxs_swf_triggerSlotParam_txPowerChanged(_ txPower: Int)
}

class MKSFBXSTriggerSlotParamCell: MKSwiftBaseCell {
    
    // MARK: - Properties
    
    var dataModel: MKSFBXSTriggerSlotParamCellModel? {
        didSet {
            updateContent()
        }
    }
    
    weak var delegate: MKSFBXSTriggerSlotParamCellDelegate?
    
    // MARK: - Initialization
    
    static func initCell(with tableView: UITableView) -> MKSFBXSTriggerSlotParamCell {
        let identifier = "MKSFBXSTriggerSlotParamCellIdenty"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKSFBXSTriggerSlotParamCell
        if cell == nil {
            cell = MKSFBXSTriggerSlotParamCell(style: .default, reuseIdentifier: identifier)
        }
        return cell!
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    // MARK: - Event Handlers
    
    @objc private func rssiSliderValueChanged() {
        var value = String(format: "%.f", rssiSlider.value)
        if value == "-0" { value = "0" }
        rssiValueLabel.text = value + "dBm"
        delegate?.bxs_swf_triggerSlotParam_rssiChanged(Int(value)!)
    }
    
    @objc private func txPowerSliderValueChanged() {
        let value = String(format: "%.f", txPowerSlider.value)
        txPowerValueLabel.text = txPowerValueText(Int(value)!)
        delegate?.bxs_swf_triggerSlotParam_txPowerChanged(Int(value)!)
    }
    
    // MARK: - Private Methods
    
    private func updateContent() {
        guard let dataModel = dataModel else { return }
        
        if backView.superview != nil {
            backView.removeFromSuperview()
        }
        backView.subviews.forEach { $0.removeFromSuperview() }
        
        if dataModel.cellType == .null {
            return
        }
        
        contentView.addSubview(backView)
        backView.snp.remakeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
        
        if dataModel.needChangeAdvDurationRange {
            advDurationField.placeholder = "0 ~ \(dataModel.advDurationMaxValue)"
            if dataModel.advDurationMaxValue < 10 {
                advDurationField.maxLength = 1
            } else if dataModel.advDurationMaxValue < 100 {
                advDurationField.maxLength = 2
            } else if dataModel.advDurationMaxValue < 1000 {
                advDurationField.maxLength = 3
            } else if dataModel.advDurationMaxValue < 10000 {
                advDurationField.maxLength = 4
            } else {
                advDurationField.maxLength = 5
            }
        } else {
            advDurationField.placeholder = "0~65535"
            advDurationField.maxLength = 5
        }
        
        setupTxPowerParams()
        
        if dataModel.cellType == .tlm {
            addTLMSubViews()
            intervalField.text = dataModel.interval
            advDurationField.text = dataModel.advDuration
            txPowerSlider.value = Float(dataModel.txPower)
            txPowerValueLabel.text = txPowerValueText(dataModel.txPower)
            setupTopViews()
            setupTLMSliderUI()
            return
        }
        
        addNormalSubViews()
        setupTopViews()
        setupNormalSliderUI()
        intervalField.text = dataModel.interval
        advDurationField.text = dataModel.advDuration
        rssiSlider.value = Float(dataModel.rssi)
        let value = String(format: "%.f", rssiSlider.value)
        rssiValueLabel.text = value + "dBm"
        txPowerSlider.value = Float(dataModel.txPower)
        txPowerValueLabel.text = txPowerValueText(dataModel.txPower)
        updateRssiMsg()
    }
    
    private func setupTxPowerParams() {
        txPowerLabel.attributedText = MKSwiftUIAdaptor.createAttributedString(strings: ["Tx power", "   (-20,-16,-12,-8,-4,0,+3,+4,+6)"], fonts: [Font.MKFont(13.0),Font.MKFont(12.0)], colors: [Color.defaultText,Color.rgb(223, 223, 223)])
        txPowerSlider.maximumValue = 8
        txPowerSlider.minimumValue = 0
    }
    
    private func txPowerValueText(_ value: Int) -> String {
        switch value {
        case 0: return "-20dBm"
        case 1: return "-16dBm"
        case 2: return "-12dBm"
        case 3: return "-8dBm"
        case 4: return "-4dBm"
        case 5: return "0dBm"
        case 6: return "3dBm"
        case 7: return "4dBm"
        default: return "6dBm"
        }
    }
    
    private func updateRssiMsg() {
        guard let dataModel = dataModel else { return }
        
        if dataModel.cellType == .null || dataModel.cellType == .tlm {
            return
        }
        
        let text: String
        if dataModel.cellType == .uid || dataModel.cellType == .url {
            text = "RSSI@0m"
        } else if dataModel.cellType == .beacon {
            text = "RSSI@1m"
        } else if dataModel.cellType == .sensorInfo {
            text = "Ranging data"
        } else {
            return
        }
        
        rssiLabel.attributedText = MKSwiftUIAdaptor.createAttributedString(strings: [text, "   (-100dBm ~ 0dBm)"], fonts: [Font.MKFont(13.0),Font.MKFont(12.0)], colors: [Color.defaultText,Color.rgb(223, 223, 223)])
    }
    
    private func addNormalSubViews() {
        backView.addSubview(leftIcon)
        backView.addSubview(msgLabel)
        backView.addSubview(intervalLabel)
        backView.addSubview(intervalField)
        backView.addSubview(intervalUnitLabel)
        backView.addSubview(advDurationLabel)
        backView.addSubview(advDurationField)
        backView.addSubview(advDurationUnitLabel)
        backView.addSubview(rssiLabel)
        backView.addSubview(rssiSlider)
        backView.addSubview(rssiValueLabel)
        backView.addSubview(txPowerLabel)
        backView.addSubview(txPowerSlider)
        backView.addSubview(txPowerValueLabel)
    }
    
    private func addTLMSubViews() {
        backView.addSubview(leftIcon)
        backView.addSubview(msgLabel)
        backView.addSubview(intervalLabel)
        backView.addSubview(intervalField)
        backView.addSubview(intervalUnitLabel)
        backView.addSubview(advDurationLabel)
        backView.addSubview(advDurationField)
        backView.addSubview(advDurationUnitLabel)
        
        backView.addSubview(txPowerLabel)
        backView.addSubview(txPowerSlider)
        backView.addSubview(txPowerValueLabel)
    }
    
    private func setupTopViews() {
        leftIcon.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(22)
            make.top.equalToSuperview().offset(10)
            make.height.equalTo(22)
        }
        
        msgLabel.snp.remakeConstraints { make in
            make.left.equalTo(leftIcon.snp.right).offset(15)
            make.right.equalToSuperview().offset(-15)
            make.centerY.equalTo(leftIcon.snp.centerY)
            make.height.equalTo(msgLabel.font.lineHeight)
        }
        
        intervalUnitLabel.snp.remakeConstraints { make in
            make.right.equalToSuperview().offset(-15)
            make.width.equalTo(50)
            make.centerY.equalTo(intervalField.snp.centerY)
            make.height.equalTo(intervalUnitLabel.font.lineHeight)
        }
        
        intervalField.snp.remakeConstraints { make in
            make.right.equalTo(intervalUnitLabel.snp.left).offset(-5)
            make.width.equalTo(60)
            make.top.equalTo(leftIcon.snp.bottom).offset(10)
            make.height.equalTo(25)
        }
        
        intervalLabel.snp.remakeConstraints { make in
            make.left.equalTo(leftIcon.snp.left)
            make.right.equalTo(intervalField.snp.left).offset(-10)
            make.centerY.equalTo(intervalField.snp.centerY)
            make.height.equalTo(intervalLabel.font.lineHeight)
        }
        
        advDurationUnitLabel.snp.remakeConstraints { make in
            make.right.equalToSuperview().offset(-15)
            make.width.equalTo(50)
            make.centerY.equalTo(advDurationField.snp.centerY)
            make.height.equalTo(advDurationUnitLabel.font.lineHeight)
        }
        
        advDurationField.snp.remakeConstraints { make in
            make.right.equalTo(advDurationUnitLabel.snp.left).offset(-5)
            make.width.equalTo(60)
            make.top.equalTo(intervalField.snp.bottom).offset(10)
            make.height.equalTo(25)
        }
        
        advDurationLabel.snp.remakeConstraints { make in
            make.left.equalTo(leftIcon.snp.left)
            make.right.equalTo(advDurationField.snp.left).offset(-10)
            make.centerY.equalTo(advDurationField.snp.centerY)
            make.height.equalTo(advDurationLabel.font.lineHeight)
        }
    }
    
    private func setupTLMSliderUI() {
        txPowerLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.top.equalTo(advDurationField.snp.bottom).offset(15)
            make.right.equalTo(-15)
            make.height.equalTo(txPowerLabel.font.lineHeight)
        }
        
        txPowerSlider.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(txPowerValueLabel.snp.left).offset(-5)
            make.top.equalTo(txPowerLabel.snp.bottom).offset(5)
            make.height.equalTo(10)
        }
        
        txPowerValueLabel.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(60)
            make.centerY.equalTo(txPowerSlider.snp.centerY)
            make.height.equalTo(txPowerValueLabel.font.lineHeight)
        }
    }
    
    private func setupNormalSliderUI() {
        rssiLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.top.equalTo(advDurationField.snp.bottom).offset(15)
            make.right.equalTo(-15)
            make.height.equalTo(rssiLabel.font.lineHeight)
        }
        
        rssiSlider.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(rssiValueLabel.snp.left).offset(-5)
            make.top.equalTo(rssiLabel.snp.bottom).offset(5)
            make.height.equalTo(10)
        }
        
        rssiValueLabel.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(60)
            make.centerY.equalTo(rssiSlider.snp.centerY)
            make.height.equalTo(rssiValueLabel.font.lineHeight)
        }
        
        txPowerLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.top.equalTo(rssiSlider.snp.bottom).offset(15)
            make.right.equalTo(-15)
            make.height.equalTo(txPowerLabel.font.lineHeight)
        }
        
        txPowerSlider.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(txPowerValueLabel.snp.left).offset(-5)
            make.top.equalTo(txPowerLabel.snp.bottom).offset(5)
            make.height.equalTo(10)
        }
        
        txPowerValueLabel.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(60)
            make.centerY.equalTo(txPowerSlider.snp.centerY)
            make.height.equalTo(txPowerValueLabel.font.lineHeight)
        }
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
        imageView.image = moduleIcon(name: "bxs_swf_slot_baseParams", in: .module)
        return imageView
    }()
    
    private lazy var msgLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(text: "Parameters")
    }()
    
    private lazy var intervalLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(12.0) ,text: "Adv interval")
    }()
    
    private lazy var intervalField: MKSwiftTextField = {
        let field = MKSwiftUIAdaptor.createTextField(placeholder: "1~100",textType: .realNumberOnly)
        field.font = Font.MKFont(12.0)
        field.maxLength = 3
        field.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_swf_triggerSlotParam_advIntervalChanged(text)
        }
        return field
    }()
    
    private lazy var intervalUnitLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(12.0) ,text: "x100ms")
    }()
    
    private lazy var advDurationLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(12.0) ,text: "Total adv duration")
    }()
    
    private lazy var advDurationField: MKSwiftTextField = {
        let field = MKSwiftUIAdaptor.createTextField(placeholder: "0~65535",textType: .realNumberOnly)
        field.font = Font.MKFont(12.0)
        field.maxLength = 5
        field.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_swf_triggerSlotParam_advDurationChanged(text)
        }
        return field
    }()
    
    private lazy var advDurationUnitLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(12.0) ,text: "s")
    }()
    
    private lazy var rssiLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        return label
    }()
    
    private lazy var rssiSlider: MKSwiftSlider = {
        let slider = MKSwiftSlider()
        slider.maximumValue = 0
        slider.minimumValue = -100
        slider.addTarget(self, action: #selector(rssiSliderValueChanged), for: .valueChanged)
        return slider
    }()
    
    private lazy var rssiValueLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(11.0))
    }()
    
    private lazy var txPowerLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.attributedText = MKSwiftUIAdaptor.createAttributedString(strings: ["Tx power", "   (-20,-16,-12,-8,-4,0,+3,+4,+6)"], fonts: [Font.MKFont(13.0),Font.MKFont(12.0)], colors: [Color.defaultText,Color.rgb(223, 223, 223)])
        return label
    }()
    
    private lazy var txPowerSlider: MKSwiftSlider = {
        let slider = MKSwiftSlider()
        slider.maximumValue = 8
        slider.minimumValue = 0
        slider.value = 0
        slider.addTarget(self, action: #selector(txPowerSliderValueChanged), for: .valueChanged)
        return slider
    }()
    
    private lazy var txPowerValueLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(11.0))
    }()
}
