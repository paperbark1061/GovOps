import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    @State private var email = "matt@govops.au"
    @State private var password = "demo1234"
    @State private var showPassword = false
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)

                        Text("Welcome to GovOps")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Sign in to access government ICT opportunities")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Login form
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            TextField("your@email.com", text: $email)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .focused($focusedField, equals: .email)
                                .padding(14)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            HStack {
                                if showPassword {
                                    TextField("Password", text: $password)
                                        .focused($focusedField, equals: .password)
                                } else {
                                    SecureField("Password", text: $password)
                                        .focused($focusedField, equals: .password)
                                }

                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .textContentType(.password)
                            .padding(14)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 4)

                    // Error message
                    if let error = authService.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Sign in button
                    Button(action: signIn) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormValid ? Color.blue : Color.blue.opacity(0.4))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(!isFormValid || authService.isLoading)

                    // Divider
                    HStack {
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                        Text("or")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                    }

                    // Demo access
                    Button(action: {
                        authService.loginAsDemo()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("Continue with Demo Access")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(14)
                    }

                    // Subscription info
                    VStack(spacing: 8) {
                        Text("Subscription Plans")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        VStack(spacing: 4) {
                            PlanRow(name: "Demo", price: "Free", detail: "Full access for testing")
                            PlanRow(name: "Per Login", price: "$4.99", detail: "7-day access per login")
                            PlanRow(name: "Monthly", price: "$14.99/mo", detail: "Unlimited access")
                            PlanRow(name: "Annual", price: "$119.99/yr", detail: "Save 33%")
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty &&
        email.contains("@")
    }

    private func signIn() {
        focusedField = nil
        authService.login(email: email, password: password)
        // Sheet will auto-dismiss when SplashView detects isAuthenticated change
    }
}

struct PlanRow: View {
    let name: String
    let price: String
    let detail: String

    var body: some View {
        HStack {
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 65, alignment: .leading)

            Text(price)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .frame(width: 75, alignment: .leading)

            Text(detail)
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService.shared)
}
