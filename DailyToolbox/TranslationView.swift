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
//  TranslationView.swift
//  DailyToolbox
//

import SwiftUI
import WebKit

// MARK: - Language Pair

private enum LeoLanguage: String, CaseIterable, Identifiable {
    case english = "englisch-deutsch"
    case french  = "franz%C3%B6sisch-deutsch"
    case spanish = "spanisch-deutsch"
    case italian = "italienisch-deutsch"
    case russian = "russisch-deutsch"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .french:  return "🇫🇷"
        case .spanish: return "🇪🇸"
        case .italian: return "🇮🇹"
        case .russian: return "🇷🇺"
        }
    }

    var shortLabel: String {
        switch self {
        case .english: return "EN↔DE"
        case .french:  return "FR↔DE"
        case .spanish: return "ES↔DE"
        case .italian: return "IT↔DE"
        case .russian: return "RU↔DE"
        }
    }

    func searchURL(for word: String) -> URL {
        let encoded = word.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed) ?? word
        return URL(string: "https://dict.leo.org/\(rawValue)/\(encoded)")
            ?? LeoLanguage.defaultURL
    }

    static var defaultURL: URL {
        URL(string: "https://dict.leo.org/dict/mobile.php")!
    }
}

// MARK: - Web View Model

@Observable
@MainActor
final class LeoWebViewModel: NSObject {
    var isLoading:    Bool = false
    var canGoBack:    Bool = false
    var canGoForward: Bool = false
    var progress:     Double = 0

    private weak var webView: WKWebView?
    private var progressObserver: NSKeyValueObservation?

    func attach(_ wv: WKWebView) {
        webView = wv
        wv.navigationDelegate = self
        progressObserver = wv.observe(\.estimatedProgress, options: [.new]) { [weak self] wv, _ in
            Task { @MainActor [weak self] in
                self?.progress = wv.estimatedProgress
            }
        }
    }

    func goBack()    { webView?.goBack() }
    func goForward() { webView?.goForward() }
    func reload()    { webView?.reload() }

    func load(_ url: URL) {
        webView?.load(URLRequest(url: url))
    }

    private func sync(from wv: WKWebView) {
        canGoBack    = wv.canGoBack
        canGoForward = wv.canGoForward
    }
}

extension LeoWebViewModel: @preconcurrency WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        isLoading = true; sync(from: webView)
    }
    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        isLoading = false; sync(from: webView)
    }
    func webView(_ webView: WKWebView, didFail _: WKNavigation!, withError _: Error) {
        isLoading = false
    }
    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation _: WKNavigation!, withError _: Error) {
        isLoading = false
    }
}

// MARK: - WebView Representable

private struct LeoWebViewRepresentable: UIViewRepresentable {
    let initialURL: URL
    let viewModel:  LeoWebViewModel

    func makeUIView(context: Context) -> WKWebView {
        let wv = WKWebView()
        wv.allowsBackForwardNavigationGestures = true
        wv.scrollView.contentInsetAdjustmentBehavior = .automatic
        viewModel.attach(wv)
        viewModel.load(initialURL)
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) { }
}

// MARK: - Main View

struct TranslationView: View {

    @State private var viewModel     = LeoWebViewModel()
    @State private var searchText:     String        = ""
    @State private var selectedLang:   LeoLanguage   = .english
    @FocusState private var searchFocused: Bool

    private let accentTeal  = Color(red: 0.20, green: 0.82, blue: 0.75)
    private let accentBlue  = Color(red: 0.28, green: 0.60, blue: 1.00)

    // MARK: Body

    var body: some View {
        ZStack(alignment: .top) {
            // WebView fills the whole screen
            LeoWebViewRepresentable(
                initialURL: LeoLanguage.defaultURL,
                viewModel: viewModel
            )
            .ignoresSafeArea(edges: .bottom)

            // Glass overlays
            GlassEffectContainer {
                VStack(spacing: 0) {
                    topOverlay
                    Spacer()
                    bottomBar
                }
            }
        }
        .navigationTitle(NSLocalizedString("Translation", comment: "Translation"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: Top Overlay

    private var topOverlay: some View {
        VStack(spacing: 10) {
            // Search row
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accentTeal.opacity(0.80))

                    TextField(
                        NSLocalizedString("Search word…", comment: ""),
                        text: $searchText
                    )
                    .focused($searchFocused)
                    .font(.body)
                    .foregroundStyle(.white)
                    .tint(accentTeal)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { performSearch() }

                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white.opacity(0.38))
                                .font(.system(size: 15))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button(action: performSearch) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accentTeal, accentBlue],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                }
                .buttonStyle(.plain)
                .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(searchText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.35 : 1)
            }

            // Language selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LeoLanguage.allCases) { lang in
                        Button {
                            selectedLang = lang
                            if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                                performSearch()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(lang.flag).font(.caption)
                                Text(lang.shortLabel)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(
                                        selectedLang == lang
                                            ? accentTeal
                                            : .white.opacity(0.65)
                                    )
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(
                            selectedLang == lang
                                ? .regular.tint(Color(red: 0.04, green: 0.28, blue: 0.28))
                                : .regular,
                            in: Capsule()
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .glassEffect(
            .regular.tint(Color(red: 0.02, green: 0.14, blue: 0.18)),
            in: RoundedRectangle(cornerRadius: 0, style: .continuous)
        )
    }

    // MARK: Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 0) {
            // Back
            Button {
                searchFocused = false
                viewModel.goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(viewModel.canGoBack ? .white : .white.opacity(0.25))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canGoBack)

            // Progress / Reload
            Button {
                searchFocused = false
                viewModel.reload()
            } label: {
                ZStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white.opacity(0.70))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.70))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Leo home
            Button {
                searchFocused = false
                viewModel.load(LeoLanguage.defaultURL)
            } label: {
                Image(systemName: "house")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.70))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Forward
            Button {
                searchFocused = false
                viewModel.goForward()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(viewModel.canGoForward ? .white : .white.opacity(0.25))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canGoForward)
        }
        .glassEffect(
            .regular.tint(Color(red: 0.02, green: 0.10, blue: 0.16)),
            in: RoundedRectangle(cornerRadius: 0, style: .continuous)
        )
        .overlay(alignment: .top) {
            // Loading progress bar
            if viewModel.isLoading {
                GeometryReader { geo in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [accentTeal, accentBlue],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * viewModel.progress, height: 2)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.progress)
                }
                .frame(height: 2)
            }
        }
    }

    // MARK: Search Action

    private func performSearch() {
        let word = searchText.trimmingCharacters(in: .whitespaces)
        guard !word.isEmpty else { return }
        searchFocused = false
        viewModel.load(selectedLang.searchURL(for: word))
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        TranslationView()
    }
}
