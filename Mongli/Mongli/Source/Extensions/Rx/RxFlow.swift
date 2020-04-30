//
//  RxFlow.swift
//  Mongli
//
//  Created by DaEun Kim on 2020/03/20.
//  Copyright © 2020 DaEun Kim. All rights reserved.
//

import Foundation

import RxCocoa
import RxFlow
import RxSwift

extension OneStepper {
  convenience init(_ step: MongliStep) {
    self.init(withSingleStep: step)
  }
}

extension PublishRelay where Element == Step {
  func accept(step: MongliStep) {
    self.accept(step)
  }
}

extension BehaviorRelay where Element == Step {
  func accept(step: MongliStep) {
    self.accept(step)
  }
}
