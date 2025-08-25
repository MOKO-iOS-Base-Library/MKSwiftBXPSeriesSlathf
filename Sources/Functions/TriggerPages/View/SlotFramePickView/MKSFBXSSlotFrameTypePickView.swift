//
//  MKSFBXSSlotFrameTypePickView.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/23.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

protocol MKSFBXSSlotFrameTypePickViewDelegate: AnyObject {
    func bxs_swf_slotFrameTypeChanged(frameType: MKSFBXSSlotType)
}

class MKSFBXSSlotFrameTypePickView: UIView {
    weak var delegate: MKSFBXSSlotFrameTypePickViewDelegate?
    
    private var frameType: MKSFBXSSlotType = .null
    private let dataList = ["TLM", "UID", "URL", "iBeacon", "Sensor info", "No Data"]
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupConstraints()
    }
    
    // MARK: - Public Methods
    func updateFrameType(_ frameType: MKSFBXSSlotType) {
        guard dataList.indices.contains(frameType.rawValue) else { return }
        pickerView.reloadAllComponents()
        self.frameType = frameType
        pickerView.selectRow(frameType.rawValue, inComponent: 0, animated: true)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        addSubview(backView)
        backView.addSubview(leftIcon)
        backView.addSubview(typeLabel)
        backView.addSubview(pickerView)
    }
    
    private func setupConstraints() {
        backView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        leftIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(22)
            make.centerY.equalToSuperview()
            make.height.equalTo(22)
        }
        
        typeLabel.snp.makeConstraints { make in
            make.left.equalTo(leftIcon.snp.right).offset(15)
            make.width.equalTo(100)
            make.centerY.equalToSuperview()
            make.height.equalTo(typeLabel.font.lineHeight)
        }
        
        pickerView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-15)
            make.width.equalTo(100)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
        }
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
        imageView.image = moduleIcon(name: "bxs_swf_slotFrameType", in: .module)
        return imageView
    }()
    
    private lazy var typeLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(text: "Frame type")
    }()
    
    private lazy var pickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        picker.layer.masksToBounds = true
        picker.layer.borderColor = Color.navBar.cgColor
        picker.layer.borderWidth = 0.5
        picker.layer.cornerRadius = 4
        return picker
    }()
}

extension MKSFBXSSlotFrameTypePickView: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataList.count
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let titleLabel: UILabel
        if let label = view as? UILabel {
            titleLabel = label
        } else {
            titleLabel = UILabel()
            titleLabel.textColor = Color.defaultText
            titleLabel.adjustsFontSizeToFitWidth = true
            titleLabel.textAlignment = .center
            titleLabel.font = Font.MKFont(12.0)
        }
        
        if row == frameType.rawValue {
            titleLabel.attributedText = attributedTitle(forRow: row, component: component)
        } else {
            titleLabel.text = self.pickerView(pickerView, titleForRow: row, forComponent: component)
        }
        
        return titleLabel
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return dataList[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return attributedTitle(forRow: row, component: component)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        frameType = MKSFBXSSlotType(rawValue: row)!
        pickerView.reloadAllComponents()
        delegate?.bxs_swf_slotFrameTypeChanged(frameType: frameType)
    }
    
    private func attributedTitle(forRow row: Int, component: Int) -> NSAttributedString {
        return MKSwiftUIAdaptor.createAttributedString(strings: [dataList[row]], fonts: [Font.MKFont(13.0)], colors: [Color.navBar])
    }
}
