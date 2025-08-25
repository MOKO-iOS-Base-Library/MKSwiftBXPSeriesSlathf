//
//  MKSFBXSAccelerationParamsCell.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/5.
//

import UIKit
import MKBaseSwiftModule

class MKSFBXSAccelerationParamsCellModel {
    /// 0:1hz,1:10hz,2:25hz,3:50hz,4:100hz
    var samplingRate: Int = 0
    
    /// 0:±2g,1:±4g,2:±8g,3:±16g
    var scale: Int = 0
    var threshold: String = "0"
    
    init() {}
}

protocol MKSFBXSAccelerationParamsCellDelegate: AnyObject {
    func accelerationParamsScaleChanged(_ scale: Int)
    func accelerationParamsSamplingRateChanged(_ samplingRate: Int)
    func accelerationMotionThresholdChanged(_ threshold: String)
}

class MKSFBXSAccelerationParamsCell: MKSwiftBaseCell {
    weak var delegate: MKSFBXSAccelerationParamsCellDelegate?
    
    var dataModel: MKSFBXSAccelerationParamsCellModel? {
        didSet {
            updateContent()
        }
    }
    
    private var scale: Int = 0
    private let scaleList = ["±2g", "±4g", "±8g", "±16g"]
    private let sampleRateList = ["1hz", "10hz", "25hz", "50hz", "100hz"]
    
    // MARK: - Public Methods
    class func initCell(with tableView: UITableView) -> MKSFBXSAccelerationParamsCell {
        let identifier = "MKSFBXSAccelerationParamsCellIdenty"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKSFBXSAccelerationParamsCell
        if cell == nil {
            cell = MKSFBXSAccelerationParamsCell(style: .default, reuseIdentifier: identifier)
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
    
    //MARK: - Super methods
    override func layoutSubviews() {
        super.layoutSubviews()
        setupConstraints()
    }
    
    //MARK: - Event methods
    @objc private func scaleButtonPressed() {
        let currentIndex = scaleList.firstIndex(of: scaleButton.titleLabel?.text ?? "") ?? 0
        let pickView = MKSwiftPickerView()
        pickView.showPickView(with: scaleList, selectedRow: currentIndex) { [weak self] index in
            guard let self = self else { return }
            self.scale = index
            self.scaleButton.setTitle(self.scaleList[index], for: .normal)
            self.updateThresholdUnit()
            self.delegate?.accelerationParamsScaleChanged(index)
        }
    }
    
    @objc private func sampleRateButtonPressed() {
        let currentIndex = sampleRateList.firstIndex(of: sampleRateButton.titleLabel?.text ?? "") ?? 0
        
        let pickView = MKSwiftPickerView()
        pickView.showPickView(with: sampleRateList, selectedRow: currentIndex) { [weak self] index in
            guard let self = self else { return }
            self.sampleRateButton.setTitle(self.sampleRateList[index], for: .normal)
            self.delegate?.accelerationParamsSamplingRateChanged(index)
        }
    }
    
    @objc private func textFieldChanged(text: String) {
        delegate?.accelerationMotionThresholdChanged(text)
    }
    
    //MARK: - Private methods
    private func updateContent() {
        guard let model = dataModel else { return }
        scaleButton.setTitle(scaleList[model.scale], for: .normal)
        sampleRateButton.setTitle(sampleRateList[model.samplingRate], for: .normal)
        scale = model.scale
        textField.text = model.threshold
        updateThresholdUnit()
    }
    
    private func updateThresholdUnit() {
        switch scale {
        case 0: thresholdUnitLabel.text = "x16mg"
        case 1: thresholdUnitLabel.text = "x32mg"
        case 2: thresholdUnitLabel.text = "x62mg"
        case 3: thresholdUnitLabel.text = "x186mg"
        default: thresholdUnitLabel.text = "x3.91mg"
        }
    }
    
    //MARK: - UI
    private func setupUI() {
        contentView.addSubview(backView)
        backView.addSubview(msgLabel)
        backView.addSubview(scaleLabel)
        backView.addSubview(scaleButton)
        backView.addSubview(sampleRateLabel)
        backView.addSubview(sampleRateButton)
        backView.addSubview(thresholdLabel)
        backView.addSubview(textField)
        backView.addSubview(thresholdUnitLabel)
    }
    
    private func setupConstraints() {
        backView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        msgLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.top.equalToSuperview().offset(5)
            make.height.equalTo(15)
        }
        
        scaleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(120)
            make.centerY.equalTo(scaleButton.snp.centerY)
            make.height.equalTo(13)
        }
        
        scaleButton.snp.makeConstraints { make in
            make.right.equalTo(textField.snp.right)
            make.width.equalTo(50)
            make.top.equalTo(msgLabel.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        
        sampleRateLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(120)
            make.centerY.equalTo(sampleRateButton.snp.centerY)
            make.height.equalTo(13)
        }
        
        sampleRateButton.snp.makeConstraints { make in
            make.right.equalTo(textField.snp.right)
            make.width.equalTo(50)
            make.top.equalTo(scaleButton.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        
        thresholdLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(120)
            make.centerY.equalTo(textField.snp.centerY)
            make.height.equalTo(13)
        }
        
        textField.snp.makeConstraints { make in
            make.right.equalTo(thresholdUnitLabel.snp.left).offset(-5)
            make.width.equalTo(50)
            make.top.equalTo(sampleRateButton.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        
        thresholdUnitLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-15)
            make.width.equalTo(70)
            make.centerY.equalTo(textField.snp.centerY)
            make.height.equalTo(12)
        }
    }
    
    //MARK: - Lazy
    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var msgLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(text: "Sensor parameters")
    }()
    
    private lazy var scaleLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(13.0),text: "Full-scale")
    }()
    
    private lazy var scaleButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = Font.MKFont(12.0)
        button.setTitleColor(.darkText, for: .normal)
        button.addTarget(self, action: #selector(scaleButtonPressed), for: .touchUpInside)
        button.layer.borderColor = Color.navBar.cgColor
        button.layer.borderWidth = 0.5
        button.layer.cornerRadius = 6
        return button
    }()
    
    private lazy var sampleRateLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(13.0),text: "Sampling rate")
    }()
    
    private lazy var sampleRateButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = Font.MKFont(12.0)
        button.setTitleColor(.darkText, for: .normal)
        button.addTarget(self, action: #selector(sampleRateButtonPressed), for: .touchUpInside)
        button.layer.borderColor = Color.navBar.cgColor
        button.layer.borderWidth = 0.5
        button.layer.cornerRadius = 6
        return button
    }()
    
    private lazy var thresholdLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(13.0),text: "Motion threshold")
    }()
    
    private lazy var textField: MKSwiftTextField = {
        let field = MKSwiftUIAdaptor.createTextField(placeholder: "1~255",
                                                     textType:.realNumberOnly,
                                                     maxLen: 3)
        field.textChangedBlock = { [weak self] text in
            self?.textFieldChanged(text: text)
        }
        return field
    }()
    
    private lazy var thresholdUnitLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(12.0),text: "x3.91mg")
    }()
}
