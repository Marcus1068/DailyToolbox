/*

Copyright 2020-2026 Marcus Deuß

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

extension LeoWebViewModel: WKNavigationDelegate {
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
    @AppStorage("translation.history") private var historyJSON: String = "[]"
    @State private var showHistory = false

    private let accentTeal  = Color(red: 0.20, green: 0.82, blue: 0.75)
    private let accentBlue  = Color(red: 0.28, green: 0.60, blue: 1.00)

    private var searchHistory: [String] {
        guard let data = historyJSON.data(using: .utf8),
              let history = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return history
    }

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
        .navigationTitle("Translation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showHistory) {
            NavigationStack {
                List(searchHistory, id: \.self) { word in
                    Button {
                        searchText = word
                        showHistory = false
                        performSearch()
                    } label: {
                        Text(word)
                            .foregroundStyle(Color.primary)
                    }
                }
                .navigationTitle("Recent Searches")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { showHistory = false }
                    }
                }
            }
        }
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
                        "Search word…",
                        text: $searchText
                    )
                    .focused($searchFocused)
                    .font(.body)
                    .foregroundStyle(Color.primary)
                    .tint(accentTeal)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { performSearch() }

                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.primary.opacity(0.38))
                                .font(.system(size: 15))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))

                Button { showHistory = true } label: {
                    Image(systemName: "clock")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(
                            searchHistory.isEmpty
                                ? Color.primary.opacity(0.25)
                                : Color.primary.opacity(0.70)
                        )
                }
                .buttonStyle(.plain)
                .disabled(searchHistory.isEmpty)

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
            ScrollView(.horizontal) {
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
                                            : Color.primary.opacity(0.65)
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
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .glassEffect(
            .regular.tint(Color(red: 0.02, green: 0.14, blue: 0.18)),
            in: RoundedRectangle(cornerRadius: 0)
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
                    .foregroundStyle(viewModel.canGoBack ? Color.primary : Color.primary.opacity(0.25))
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
                            .tint(Color.primary.opacity(0.70))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.primary.opacity(0.70))
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
                    .foregroundStyle(Color.primary.opacity(0.70))
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
                    .foregroundStyle(viewModel.canGoForward ? Color.primary : Color.primary.opacity(0.25))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canGoForward)
        }
        .glassEffect(
            .regular.tint(Color(red: 0.02, green: 0.10, blue: 0.16)),
            in: RoundedRectangle(cornerRadius: 0)
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
        // Append to history (keep last 10, deduplicate)
        var history = searchHistory
        history.removeAll { $0 == word }
        history.insert(word, at: 0)
        if history.count > 10 { history = Array(history.prefix(10)) }
        if let data = try? JSONEncoder().encode(history),
           let json = String(data: data, encoding: .utf8) { historyJSON = json }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TranslationView()
    }
}
