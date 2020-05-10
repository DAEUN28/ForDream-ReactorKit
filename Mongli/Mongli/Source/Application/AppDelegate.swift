//
//  AppDelegate.swift
//  Mongli
//
//  Created by DaEun Kim on 2020/03/15.
//  Copyright © 2020 DaEun Kim. All rights reserved.
//

import AuthenticationServices
import UIKit

import Firebase
import RxFlow
import RxSwift
import RxCocoa

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  var coordinator = FlowCoordinator()
  private let disposeBag = DisposeBag()

  private let authService = AuthService()
  private let dreamService = DreamService()
  private let appleIDProvider = ASAuthorizationAppleIDProvider()

  private lazy var appStepper: AppStepper? = {
    guard let window = self.window else { return nil }
    return AppStepper(self.authService)
  }()
  private lazy var appFlow: AppFlow? = {
    guard let window = self.window else { return nil }
    return AppFlow(window,
                   authService: self.authService,
                   dreamService: self.dreamService,
                   appleIDProvider: self.appleIDProvider)
  }()

  // MARK: App Life Cycle

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    guard let flow = self.appFlow, let stepper = self.appStepper else { return true }

    // logout
//     StorageManager.shared.deleteAll()

    // Setup Rxflow
    self.coordinator.coordinate(flow: flow, with: stepper)

    self.coordinator.rx.willNavigate.bind { flow, step in
      print("🚀 will navigate to flow=\(flow) and step=\(step) 🚀")
    }
    .disposed(by: self.disposeBag)

    self.coordinator.rx.didNavigate.bind { flow, step in
      print("🚀 did navigate to flow=\(flow) and step=\(step) 🚀")
    }
    .disposed(by: self.disposeBag)

    // Setup Firebase

    FirebaseApp.configure()
    AnalyticsManager.setUserID()

    return true
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    if UITraitCollection.current.userInterfaceStyle == .dark {
      themeService.switch(.dark)
    } else {
      themeService.switch(.light)
    }
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    guard let uid = StorageManager.shared.readUser()?.uid else { return }

    appleIDProvider.getCredentialState(forUserID: uid) { [unowned self] state, _ in
      switch state {
      case .authorized: return
      default:
        self.authService.deleteUser().asObservable().bind { [unowned self]  in
          switch $0 {
          case .success: self.appStepper?.steps.accept(MongliStep.signInIsRequired)
          case .error(let error): self.appStepper?.steps.accept(MongliStep.toast(error.message))
          }
        }
        .disposed(by: self.disposeBag)
      }
    }
  }
}

extension AppDelegate {
  func signInIsRequired() {
    appStepper?.steps.accept(MongliStep.signInIsRequired)
  }
}
