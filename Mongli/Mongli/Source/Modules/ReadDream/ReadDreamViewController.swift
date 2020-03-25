//
//  ReadDreamViewController.swift
//  Mongli
//
//  Created by DaEun Kim on 2020/03/20.
//  Copyright © 2020 DaEun Kim. All rights reserved.
//

import UIKit

import ReactorKit
import RxCocoa
import RxFlow
import RxSwift

final class ReadDreamViewController: BaseViewController, View, Stepper {
  var steps = PublishRelay<Step>()

  typealias Reactor = ReadDreamViewReactor

  var reactor: Reactor?

  init(_ reactor: Reactor) {
    super.init()
    self.reactor = reactor
  }

  required convenience init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func bind(reactor: Reactor) {

  }
}
