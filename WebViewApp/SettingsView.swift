import SwiftUI

struct SettingsView: View {
    @AppStorage("webURL") private var webURL: String = "http://47.115.132.109:8081/"
    @State private var tempURL: String = ""
    @State private var showValidation = false
    @State private var isValidURL = true
    
    var isPresented: Binding<Bool>?
    var onURLChanged: ((String) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Image(systemName: "gearshape")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.accentColor)
                    .padding(.top, 20)
                Text("设置")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 20)
            
            Divider()
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                // URL field
                VStack(alignment: .leading, spacing: 6) {
                    Text("网页地址")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    TextField("输入网页地址", text: $tempURL)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.primary.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(showValidation && !isValidURL ? Color.red.opacity(0.6) : Color.primary.opacity(0.1), lineWidth: 1)
                        )
                    #if os(iOS)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                    #endif
                        .disableAutocorrection(true)
                    
                    if showValidation && !isValidURL {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption2)
                            Text("请输入有效的 URL 地址（以 http:// 或 https:// 开头）")
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                    }
                }
                
                // Current URL info
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("保存后立即生效，下次启动时自动加载此地址。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Reset button
                Button(action: resetToDefault) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                        Text("恢复默认地址")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            Spacer()
            
            Divider()
            
            // Bottom buttons - macOS style
            HStack(spacing: 12) {
                Button("取消") {
                    isPresented?.wrappedValue = false
                }
                .keyboardShortcut(.cancelAction)
                #if os(macOS)
                .buttonStyle(.bordered)
                .controlSize(.regular)
                #endif
                
                Button("保存") {
                    saveURL()
                }
                .keyboardShortcut(.defaultAction)
                #if os(macOS)
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                #else
                .buttonStyle(.borderedProminent)
                #endif
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        #if os(macOS)
        .frame(width: 420, height: 340)
        #endif
        .onAppear {
            tempURL = webURL
        }
    }
    
    private func validateURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()) else {
            return false
        }
        return true
    }
    
    private func saveURL() {
        let trimmedURL = tempURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if validateURL(trimmedURL) {
            webURL = trimmedURL
            isValidURL = true
            showValidation = false
            onURLChanged?(trimmedURL)
            isPresented?.wrappedValue = false
        } else {
            isValidURL = false
            showValidation = true
        }
    }
    
    private func resetToDefault() {
        let defaultURL = "http://47.115.132.109:8081/"
        tempURL = defaultURL
        webURL = defaultURL
        showValidation = false
        isValidURL = true
        onURLChanged?(defaultURL)
    }
}
