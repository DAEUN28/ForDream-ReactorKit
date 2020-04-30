//
//  UILabel.swift
//  Mongli
//
//  Created by DaEun Kim on 2020/03/20.
//  Copyright © 2020 DaEun Kim. All rights reserved.
//

import UIKit

extension UILabel {
  func setText(_ text: LocalizedString) {
    self.text = text.localized
  }

  func setFont(_ font: Font) {
    self.font = font.uifont
  }
}
