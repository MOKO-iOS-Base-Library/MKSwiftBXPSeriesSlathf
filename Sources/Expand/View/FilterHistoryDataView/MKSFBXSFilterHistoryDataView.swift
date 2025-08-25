//
//  MKSFBXSFilterHistoryDataView.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/7.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import DateTimePicker

protocol MKSFBXSFilterHistoryDataViewDelegate: AnyObject {
    func bxs_swf_dateSelectedView(startPressed startDate: String, endDate: String)
}

class MKSFBXSFilterHistoryDataView: UIView {
    
    weak var delegate: MKSFBXSFilterHistoryDataViewDelegate?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        let dateString = dateFormatter.string(from: Date())
        startDateLabel.text = dateString
        endDateLabel.text = dateString
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Super Methods
    override func layoutSubviews() {
        super.layoutSubviews()
        setupConstraints()
    }
    
    // MARK: - Event Methods
    
    @objc private func startDateButtonPressed() {
        let date = dateFormatter.date(from: startDateLabel.text ?? "") ?? Date()
        
        let picker = DateTimePicker.create()
        picker.selectedDate = date
        picker.highlightColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1)
        picker.completionHandler = { [weak self] selectedDate in
            guard let self = self else { return }
            self.startDateLabel.text = self.dateFormatter.string(from: selectedDate)
        }
        picker.show()
    }
    
    @objc private func endDateButtonPressed() {
        let date = dateFormatter.date(from: endDateLabel.text ?? "") ?? Date()
        
        // 1. 创建配置
        let picker = DateTimePicker.create()
        
        // 2. 配置属性
        picker.selectedDate = date  // 设置初始日期
        picker.highlightColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1)
        picker.isDatePickerOnly = false  // 确保显示时间选择
        
        // 3. 设置回调
        picker.completionHandler = { [weak self] selectedDate in
            guard let self = self else { return }
            self.endDateLabel.text = self.dateFormatter.string(from: selectedDate)
        }
        
        // 4. 显示选择器
        picker.show()
    }
    
    @objc private func startButtonPressed() {
        delegate?.bxs_swf_dateSelectedView(
            startPressed: startDateLabel.text ?? "",
            endDate: endDateLabel.text ?? ""
        )
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        addSubview(topLine)
        addSubview(startLabel)
        addSubview(startDateLabel)
        addSubview(startDateButton)
        addSubview(endLabel)
        addSubview(endDateLabel)
        addSubview(endDateButton)
        addSubview(startButton)
    }
    
    private func setupConstraints() {
        topLine.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        startButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-15)
            make.width.equalTo(80)
            make.centerY.equalToSuperview()
            make.height.equalTo(35)
        }
        
        startDateButton.snp.makeConstraints { make in
            make.right.equalTo(startButton.snp.left).offset(-10)
            make.width.equalTo(25)
            make.top.equalToSuperview().offset(5)
            make.height.equalTo(25)
        }
        
        startLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.width.equalTo(70)
            make.centerY.equalTo(startDateButton.snp.centerY)
            make.height.equalTo(UIFont.systemFont(ofSize: 13).lineHeight)
        }
        
        startDateLabel.snp.makeConstraints { make in
            make.left.equalTo(startLabel.snp.right).offset(2)
            make.right.equalTo(startDateButton.snp.left).offset(-2)
            make.centerY.equalTo(startDateButton.snp.centerY)
            make.height.equalTo(UIFont.systemFont(ofSize: 11).lineHeight)
        }
        
        endDateButton.snp.makeConstraints { make in
            make.right.equalTo(startButton.snp.left).offset(-10)
            make.width.equalTo(25)
            make.top.equalTo(startDateButton.snp.bottom).offset(10)
            make.height.equalTo(25)
        }
        
        endLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.width.equalTo(70)
            make.centerY.equalTo(endDateButton.snp.centerY)
            make.height.equalTo(UIFont.systemFont(ofSize: 13).lineHeight)
        }
        
        endDateLabel.snp.makeConstraints { make in
            make.left.equalTo(endLabel.snp.right).offset(2)
            make.right.equalTo(endDateButton.snp.left).offset(-2)
            make.centerY.equalTo(endDateButton.snp.centerY)
            make.height.equalTo(UIFont.systemFont(ofSize: 11).lineHeight)
        }
    }
    
    // MARK: - UI Components
    
    private lazy var topLine: UIView = {
        let view = UIView()
        view.backgroundColor = Color.defaultText
        return view
    }()
    
    private lazy var startLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(13.0), text: "Start Date:")
    }()
    
    private lazy var startDateLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(11.0))
    }()
    
    private lazy var startDateButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = moduleIcon(name: "bxs_swf_calendar", in: .module)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(startDateButtonPressed), for: .touchUpInside)
        return button
    }()
    
    private lazy var endLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(13.0), text: "End Date:")
    }()
    
    private lazy var endDateLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(11.0))
    }()
    
    private lazy var endDateButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = moduleIcon(name: "bxs_swf_calendar", in: .module)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(endDateButtonPressed), for: .touchUpInside)
        return button
    }()
    
    private lazy var startButton: UIButton = {
        let button = MKSwiftUIAdaptor.createRoundedButton(title: "Start", target: self, action: #selector(startButtonPressed))
        button.titleLabel?.font = Font.MKFont(12.0)
        return button
    }()
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return formatter
    }()
}
