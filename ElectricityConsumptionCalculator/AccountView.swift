//
//  AccountView.swift
//  Electricity consumption calculator
//
//  Account tab — Google Sign-In, user profile info, sign out
//

import SwiftUI
import GoogleSignInSwift

struct AccountView: View {
    // MARK: - Environment
    @Environment(\.keychainService) private var keychainService
    @Environment(\.authenticationService) private var authenticationService

    // MARK: - State
    @State private var viewModel: AccountViewModel?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                if let viewModel {
                    accountContent(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Account")
        }
        .onAppear {
            if viewModel == nil {
                viewModel = AccountViewModel(
                    keychainService: keychainService,
                    authenticationService: authenticationService
                )
            }
        }
    }
}

// MARK: - Account Content

private extension AccountView {
    @ViewBuilder
    func accountContent(viewModel: AccountViewModel) -> some View {
        if viewModel.isSignedIn {
            signedInSection(viewModel: viewModel)
        } else {
            signedOutSection(viewModel: viewModel)
        }

        if let error = viewModel.authError {
            errorSection(error: error)
        }
    }

    @ViewBuilder
    func signedInSection(viewModel: AccountViewModel) -> some View {
        Section {
            HStack(spacing: 12) {
                if let imageURL = viewModel.userProfileImageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure, .empty:
                            Image(systemName: "person.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        @unknown default:
                            Image(systemName: "person.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.userName ?? "User")
                        .font(.headline)
                    if let email = viewModel.userEmail {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(viewModel.userName ?? "User"), \(viewModel.userEmail ?? "")")
        }

        Section {
            Button(role: .destructive) {
                viewModel.signOut()
            } label: {
                Label("Sign out google", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    @ViewBuilder
    func signedOutSection(viewModel: AccountViewModel) -> some View {
        Section {
            if viewModel.isSigningIn {
                HStack {
                    Spacer()
                    ProgressView("Signing in...")
                    Spacer()
                }
            } else {
                GoogleSignInButton {
                    handleSignInButton(viewModel: viewModel)
                }
            }
        }
    }

    @ViewBuilder
    func errorSection(error: String) -> some View {
        Section {
            Label(error, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
                .font(.footnote)
        }
    }
}

// MARK: - Sign-In Handling

private extension AccountView {
    func handleSignInButton(viewModel: AccountViewModel) {
        GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController()) { signInResult, error in
            viewModel.handleGoogleSignInResult(signInResult: signInResult, error: error)
        }
    }
}

// MARK: - Root View Controller Helper

extension View {
    func getRootViewController() -> UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .init()
        }

        guard let root = screen.windows.first?.rootViewController else {
            return .init()
        }

        return root
    }
}

#Preview {
    AccountView()
        .environment(\.keychainService, KeychainService.shared)
        .environment(\.authenticationService, AuthenticationService.shared)
}
