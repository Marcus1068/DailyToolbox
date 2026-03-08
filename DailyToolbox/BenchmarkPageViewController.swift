//
//  BenchmarkPageViewController.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 25.05.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import SwiftUI

@MainActor
class BenchmarkPageViewController: UIHostingController<BenchmarkView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: BenchmarkView())
    }
}
