import SwiftUI

struct AITestView: View {
    @State private var inputText = ""
    @State private var responseText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            Color(hex: "F8FAFC")
                .ignoresSafeArea()

            // Main content
            VStack(spacing: 0) {
                // Header
                testHeader

                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Input section
                        inputSection

                        // Response section
                        responseSection
                    }
                    .padding(16)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Test Header
    private var testHeader: some View {
        HStack(spacing: 0) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "F3F4F6")))
            }

            Spacer()

            HStack(spacing: 10) {
                Image(systemName: "cpu.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(Color(hex: "F97316"))

                Text("AI 测试")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .frame(height: 60)
        .padding(.horizontal, 16)
        .background(Color.white)
        .overlay(Rectangle().fill(Color(hex: "E5E7EB")).frame(height: 0.5), alignment: .bottom)
    }

    // MARK: - Input Section
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("输入提示词")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(hex: "1F2937"))

            TextEditor(text: $inputText)
                .font(.system(size: 14))
                .frame(minHeight: 120)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "F9FAFB"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "E5E7EB"), lineWidth: 1)
                )

            Button(action: {
                Task {
                    await sendRequest()
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.trailing, 8)
                    }

                    Text(isLoading ? "请求中..." : "发送请求")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "F97316"), Color(hex: "FB923C")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(isLoading || inputText.isEmpty)
            .opacity(isLoading || inputText.isEmpty ? 0.6 : 1.0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Response Section
    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI 响应")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))

                Spacer()

                if !responseText.isEmpty {
                    Button(action: {
                        UIPasteboard.general.string = responseText
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                            Text("复制")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(Color(hex: "F97316"))
                    }
                }
            }

            if responseText.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color(hex: "E5E7EB"))

                    Text("发送请求后将显示 AI 响应")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "9CA3AF"))
                }
                .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                ScrollView {
                    Text(responseText)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "1F2937"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "F0FDF4"))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "86EFAC"), lineWidth: 1)
                        )
                }
                .frame(minHeight: 150)
            }

            if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "EF4444"))

                    Text(error)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "EF4444"))
                        .lineLimit(2)

                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "FEF2F2"))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    private func sendRequest() async {
        isLoading = true
        errorMessage = nil
        responseText = ""

        do {
            let response = try await AIChatService.shared.sendMessage(
                inputText,
                lessonId: 1,
                historyMessages: []
            )
            responseText = response
        } catch {
            errorMessage = "请求失败: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        AITestView()
    }
}
