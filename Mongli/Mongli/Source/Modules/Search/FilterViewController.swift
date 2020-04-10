//
//  FilterViewController.swift
//  Mongli
//
//  Created by DaEun Kim on 2020/04/04.
//  Copyright © 2020 DaEun Kim. All rights reserved.
//

import UIKit

import RxCocoa
import RxFlow
import RxSwift

final class FilterViewController: UIViewController, Stepper {

  // MARK: Properties

  var steps = PublishRelay<Step>()

  private var didSetupConstraints = false
  private let disposeBag = DisposeBag()

  // MARK: UI

  private let titleLabel = UILabel().then {
    $0.setText(.searchFilterText)
    $0.font = FontManager.hpi20L
    $0.theme.textColor = themed { $0.text }
  }
  private let stackView = UIStackView().then {
    $0.axis = .vertical
    $0.alignment = .fill
    $0.distribution = .fill
    $0.spacing = 36
    $0.translatesAutoresizingMaskIntoConstraints = false
  }
  private let criteriaLabel = UILabel().then {
    $0.setText(.criteria)
    $0.font = FontManager.sys17SB
    $0.theme.textColor = themed { $0.text }
  }
  private let criteriaSegmentedControl = UISegmentedControl().then {
    let criteria: [LocalizedString] = [.title, .content, .noKeyword]
    for i in 0..<3 {
      $0.insertSegment(withTitle: criteria[i].localized, at: i, animated: false)
    }

    $0.selectedSegmentIndex = 0
    $0.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    $0.theme.selectedSegmentTintColor = themed { $0.primary }
    $0.theme.segmentTitleAttribute = themed { $0.segmentedControlTitle }
  }
  private let alignmentLabel = UILabel().then {
    $0.setText(.alignment)
    $0.font = FontManager.sys17SB
    $0.theme.textColor = themed { $0.text }
  }
  private let alignmentSegmentedControl = UISegmentedControl().then {
    let alignments: [LocalizedString] = [.newest, .alphabetically]
    for i in 0..<2 {
      $0.insertSegment(withTitle: alignments[i].localized, at: i, animated: false)
    }

    $0.selectedSegmentIndex = 0
    $0.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    $0.theme.selectedSegmentTintColor = themed { $0.primary }
    $0.theme.segmentTitleAttribute = themed { $0.segmentedControlTitle }
  }
  private let categoryLabel = UILabel().then {
    $0.setText(.category)
    $0.font = FontManager.sys17SB
    $0.theme.textColor = themed { $0.text }
  }
  private let categoryButton = UIButton().then {
    $0.setTitle(.notSelect)
    $0.titleLabel?.font = FontManager.sys14B
    $0.theme.titleColor(from: themed { $0.text }, for: .normal)
  }
  private let periodLabel = UILabel().then {
    $0.setText(.period)
    $0.font = FontManager.sys17SB
    $0.theme.textColor = themed { $0.text }
  }
  private let periodView = PeriodView()
  private let periodTextLabel = UILabel().then {
    $0.setText(.periodText)
    $0.font = FontManager.sys12L
    $0.theme.textColor = themed { $0.text }
  }
  private let closeButton = BottomButton(.close)

  // MARK: Initializing

  convenience init(_ query: SearchQuery) {
    self.init()

    let criteria = self.criteriaSegmentedControl.rx.selectedSegmentIndex
    let alignment = self.alignmentSegmentedControl.rx.selectedSegmentIndex
    let category = BehaviorRelay<Category?>(value: nil)
    let startDate = BehaviorRelay<Date?>(value: nil)
    let endDate = BehaviorRelay<Date?>(value: nil)
    let period = Observable.combineLatest(startDate, endDate) { start, end -> String? in
      guard let start = start, let end = end else { return nil }
      return dateFormatter.string(from: start) + "~" + dateFormatter.string(from: end)
    }
    let searchQuery = Observable.combineLatest(criteria, alignment, category, period) {
      SearchQuery(query.page, $0, $1, $2?.rawValue, $3, $0 == 2 ? nil : query.keyword)
    }

    self.criteriaSegmentedControl.selectedSegmentIndex = query.criteria
    self.alignmentSegmentedControl.selectedSegmentIndex = query.alignment
    category.accept(Category(query.category))

    if let startString = query.period?.components(separatedBy: "~").first,
      let endString = query.period?.components(separatedBy: "~").last,
      let start = dateFormatter.date(from: startString),
      let end = dateFormatter.date(from: endString) {
      startDate.accept(start)
      endDate.accept(end)
    }

    self.categoryButton.rx.tap
      .bind { [weak self] in
        self?.presentCategoryPicker(select: category.value) { category.accept($0) }
      }
      .disposed(by: self.disposeBag)
    category.map { $0?.toName().localized ?? LocalizedString.notSelect.localized }
      .bind(to: self.categoryButton.rx.title())
      .disposed(by: self.disposeBag)

    self.periodView.startDateButton.rx.tap
      .bind { [weak self] in
        self?.presentDatepickerActionSheet(select: startDate.value) { startDate.accept($0) }
      }
      .disposed(by: self.disposeBag)
    self.periodView.endDateButton.rx.tap
      .bind { [weak self] in
        self?.presentDatepickerActionSheet(select: endDate.value) { endDate.accept($0) }
      }
      .disposed(by: self.disposeBag)
    startDate.map { dateFormatter.string(for: $0) ?? LocalizedString.notSelect.localized }
      .bind(to: self.periodView.startDateButton.rx.title())
      .disposed(by: self.disposeBag)
    endDate.map { dateFormatter.string(for: $0) ?? LocalizedString.notSelect.localized }
      .bind(to: self.periodView.endDateButton.rx.title())
      .disposed(by: self.disposeBag)

    self.closeButton.rx.tap.withLatestFrom(searchQuery)
      .bind { [weak self] in self?.steps.accept(MongliStep.filterIsComplete($0)) }
      .disposed(by: self.disposeBag)
  }

  required convenience init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: View Life Cycle

  override func viewDidLoad() {
    self.isModalInPresentation = true
    self.view.theme.backgroundColor = themed { $0.background }

    self.view.addSubview(self.titleLabel)
    self.view.addSubview(self.stackView)
    self.view.addSubview(self.closeButton)
  }

  // MARK: Layout

  override func updateViewConstraints() {
    if !self.didSetupConstraints {
      self.titleLabel.snp.makeConstraints {
        $0.top.equalToSafeArea(self.view).inset(20)
        $0.leading.equalToSuperview().inset(20)
      }
      self.stackView.snp.makeConstraints {
        $0.top.equalTo(self.titleLabel.snp.bottom).offset(28)
        $0.bottom.equalTo(self.closeButton.snp.top).offset(-24)
        $0.leading.equalToSuperview().inset(28)
        $0.trailing.equalToSuperview().inset(28)
      }

      let views: [(UIView, UIView, UIView?)]
        = [(self.criteriaLabel, self.criteriaSegmentedControl, nil),
           (self.alignmentLabel, self.alignmentSegmentedControl, nil),
           (self.categoryLabel, self.categoryButton, nil),
           (self.periodLabel, self.periodView, self.periodTextLabel)]

      for (title, sub, desc) in views {
        self.stackView.addArrangedSubview(self.makeView(title, sub, desc))
      }

      self.closeButton.snp.makeConstraints {
        $0.bottom.equalToSafeArea(self.view).inset(24)
        $0.leading.equalToSuperview().inset(32)
        $0.trailing.equalToSuperview().inset(32)
      }
      self.didSetupConstraints = true
    }
    super.updateViewConstraints()
  }
}

// MARK: Private Functions

extension FilterViewController {
  private func makeView(_ titleView: UIView, _ subView: UIView, _ descView: UIView?) -> UIView {
    let containerView = UIView()
    containerView.addSubview(titleView)
    containerView.addSubview(subView)

    titleView.snp.makeConstraints {
      $0.top.equalToSuperview()
      $0.leading.equalToSuperview()
      $0.trailing.equalToSuperview()
    }

    if let descView = descView {
      containerView.addSubview(descView)
      descView.snp.makeConstraints {
        $0.top.equalTo(titleView.snp.bottom).offset(12)
        $0.leading.equalToSuperview()
        $0.trailing.equalToSuperview()
      }
      subView.snp.makeConstraints {
        $0.top.equalTo(descView.snp.bottom).offset(12)
        $0.bottom.equalToSuperview()
        $0.leading.equalToSuperview()
        $0.trailing.equalToSuperview()
      }
      return containerView
    }

    subView.snp.makeConstraints {
      $0.top.equalTo(titleView.snp.bottom).offset(12)
      $0.bottom.equalToSuperview()
      $0.leading.equalToSuperview()
      $0.trailing.equalToSuperview()
    }
    return containerView
  }

  private func presentCategoryPicker(select category: Category? = nil, _ handler: @escaping (Category?) -> Void) {
    let picker = UIPickerView()
    Observable.just(Category.categories)
      .bind(to: picker.rx.itemTitles) { return $1.toName().localized }
      .disposed(by: self.disposeBag)
    if let selectedRow = category?.rawValue {
      picker.selectRow(selectedRow, inComponent: 0, animated: false)
    }

    let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    let select = UIAlertAction(title: LocalizedString.select.localized,
                               style: .default) { _ in handler(Category(rawValue: picker.selectedRow(inComponent: 0))) }
    let notSelect = UIAlertAction(title: LocalizedString.notSelect.localized,
                                  style: .default) { _ in handler(nil) }
    let cancel = UIAlertAction(title: LocalizedString.cancel.localized, style: .cancel)
    actionSheet.view.addSubview(picker)
    actionSheet.addAction(select)
    actionSheet.addAction(notSelect)
    actionSheet.addAction(cancel)

    actionSheet.view.snp.makeConstraints {
      $0.height.equalTo(320)
    }
    picker.snp.makeConstraints {
      $0.height.equalTo(150)
      $0.top.equalToSuperview()
      $0.leading.equalToSuperview()
      $0.trailing.equalToSuperview()
    }

    self.present(actionSheet, animated: true)
  }

  private func presentDatepickerActionSheet(select date: Date? = nil, _ handler: @escaping (Date?) -> Void) {
    let datePicker = UIDatePicker()
    datePicker.locale = Locale.current
    datePicker.datePickerMode = .date
    if let date = date { datePicker.date = date }

    let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    let select = UIAlertAction(title: LocalizedString.select.localized,
                               style: .default) { _ in handler(datePicker.date) }
    let notSelect = UIAlertAction(title: LocalizedString.notSelect.localized,
                                  style: .default) { _ in handler(nil) }
    let cancel = UIAlertAction(title: LocalizedString.cancel.localized, style: .cancel)
    actionSheet.view.addSubview(datePicker)
    actionSheet.addAction(select)
    actionSheet.addAction(notSelect)
    actionSheet.addAction(cancel)

    actionSheet.view.snp.makeConstraints {
      $0.height.equalTo(320)
    }
    datePicker.snp.makeConstraints {
      $0.height.equalTo(150)
      $0.leading.equalToSuperview()
      $0.trailing.equalToSuperview()
    }

    self.present(actionSheet, animated: true)
  }
}

// MARK: PeriodView

private final class PeriodView: UIView {

  private var didSetupConstraints = false

  private let dashLabel = UILabel().then {
    $0.text = "~"
    $0.font = FontManager.sys14B
    $0.theme.textColor = themed { $0.text }
  }
  let startDateButton = UIButton().then {
    $0.setTitle(.notSelect)
    $0.titleLabel?.font = FontManager.sys14B
    $0.theme.titleColor(from: themed { $0.text }, for: .normal)
  }
  let endDateButton = UIButton().then {
    $0.setTitle(.notSelect)
    $0.titleLabel?.font = FontManager.sys14B
    $0.theme.titleColor(from: themed { $0.text }, for: .normal)
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    self.addSubview(self.dashLabel)
    self.addSubview(self.startDateButton)
    self.addSubview(self.endDateButton)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func updateConstraints() {
    if !self.didSetupConstraints {
      self.dashLabel.snp.makeConstraints {
        $0.centerX.equalToSuperview()
        $0.centerY.equalTo(self.startDateButton.snp.centerY)
      }
      self.startDateButton.snp.makeConstraints {
        $0.top.equalToSuperview()
        $0.trailing.equalTo(self.dashLabel.snp.leading).offset(-8)
      }
      self.endDateButton.snp.makeConstraints {
        $0.top.equalToSuperview()
        $0.leading.equalTo(self.dashLabel.snp.trailing).offset(8)
      }
      self.didSetupConstraints = true
    }
    super.updateConstraints()
  }
}