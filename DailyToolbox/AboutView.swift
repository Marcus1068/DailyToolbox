/*

Copyright 2020 Marcus Deuß

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

//
//  AboutView.swift
//  DailyToolbox
//
//  Created by Marcus Deuß on 23.04.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import SwiftUI
import MessageUI
import UIKit

// MARK: - Mail Compose (UIViewControllerRepresentable)

private struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let recipients: [String]
    let body: String
    @Binding var isPresented: Bool

    func makeCoordinator() -> Coordinator { Coordinator($isPresented) }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(recipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate, @unchecked Sendable {
        let isPresented: Binding<Bool>
        init(_ isPresented: Binding<Bool>) { self.isPresented = isPresented }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            let binding = isPresented
            Task { @MainActor in binding.wrappedValue = false }
        }
    }
}

// MARK: - About View

struct AboutView: View {

    @State private var showMail = false
    @State private var showMailError = false

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\("Version"): \(v) (\(b))"
    }

    private var deviceInfo: String {
        let name = UIDevice.current.name
        let os   = UIDevice.current.systemVersion
        return "\("Running on") \(name) \(os)"
    }

    private var mailSubject: String {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "DailyToolbox"
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        return "\(appName) \(version) \(Global.support)"
    }

    // MARK: Body

    var body: some View {
        ZStack {
            background
            GlassEffectContainer {
                ScrollView {
                    VStack(spacing: 28) {
                        heroSection
                        infoCard
                        actionButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 28)
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showMail) {
            MailComposeView(
                subject: mailSubject,
                recipients: [Global.emailAdr],
                body: "I have some suggestions: ",
                isPresented: $showMail
            )
        }
        .alert(Global.emailNotSent, isPresented: $showMailError) {
            Button(Global.ok) {}
        } message: {
            Text("\(Global.emailDevice)\n\(Global.emailConfig)")
        }
    }

    // MARK: - Background

    private var background: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                Color(red: 0.06, green: 0.18, blue: 0.62),
                Color(red: 0.14, green: 0.26, blue: 0.74),
                Color(red: 0.32, green: 0.10, blue: 0.64),
                Color(red: 0.05, green: 0.36, blue: 0.78),
                Color(red: 0.18, green: 0.44, blue: 0.86),
                Color(red: 0.48, green: 0.14, blue: 0.70),
                Color(red: 0.04, green: 0.54, blue: 0.80),
                Color(red: 0.10, green: 0.60, blue: 0.86),
                Color(red: 0.38, green: 0.24, blue: 0.76)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 18) {
            Image("about Icon")
                .resizable()
                .scaledToFit()
                .frame(width: 116, height: 116)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.65), .white.opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                }
                .shadow(color: Color(red: 0.15, green: 0.35, blue: 1.0).opacity(0.55),
                        radius: 28, x: 0, y: 14)

            VStack(spacing: 6) {
                Text("DailyToolbox")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(appVersion)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))

                Text(deviceInfo)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Info Card

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("© 2020–2025 Marcus Deuß", systemImage: "c.circle")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.90))

            Divider()
                .overlay(.white.opacity(0.18))

            Label("Apache License 2.0", systemImage: "doc.text")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.72))

            Label("Open Source on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            actionRow(
                icon: "envelope.fill",
                iconColor: Color(red: 0.25, green: 0.65, blue: 1.0),
                title: Global.appFeedback,
                subtitle: "Send us your thoughts"
            ) {
                if MFMailComposeViewController.canSendMail() {
                    showMail = true
                } else {
                    showMailError = true
                }
            }

            actionRow(
                icon: "info.circle.fill",
                iconColor: Color(red: 0.28, green: 0.82, blue: 0.50),
                title: Global.appInformation,
                subtitle: "Website & documentation"
            ) {
                openURL(Global.website)
            }

            actionRow(
                icon: "lock.shield.fill",
                iconColor: Color(red: 0.95, green: 0.55, blue: 0.20),
                title: Global.appPrivacy,
                subtitle: "Privacy policy"
            ) {
                openURL(Global.privacy)
            }
        }
    }

    @ViewBuilder
    private func actionRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.22))
                        .frame(width: 46, height: 46)
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.glass)
    }

    // MARK: - Helpers

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        AboutView()
    }
}
