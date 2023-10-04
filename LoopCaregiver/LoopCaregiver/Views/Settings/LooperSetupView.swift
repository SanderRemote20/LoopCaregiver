//
//  LooperSetupView.swift
//  
//
//  Created by Bill Gestrich on 5/11/22.
//

import Foundation
import SwiftUI
import CodeScanner

struct LooperSetupView: View {
    
    @ObservedObject var accountService: AccountServiceManager
    @ObservedObject var settings: CaregiverSettings
    @State private var nightscoutURLFieldText: String = ""
    @State private var nameFieldText: String = ""
    @State private var apiSecretFieldText: String = ""
    @State private var qrURLFieldText: String = ""
    @State private var errorText: String?
    @State private var showingSignoutAlert = false
    @State private var isShowingScanner = false
    @State private var authenticating = false
    @Binding var path: NavigationPath
    
    var body: some View {
        
        VStack {
            inputFormView
            if authenticating {
                ProgressView("Checking credentials...")
            }
            Spacer()
            Button("Legg til Looper") {
                self.save()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .padding()
            .disabled(disableFormSubmission())
            if let errorText = errorText {
                Text("\(errorText)").foregroundColor(.red)
            }
        }
        .sheet(isPresented: $isShowingScanner) {
            CodeScannerView(codeTypes: [.qr], simulatedData: simulatedOTP(), completion: handleScan)
        }
        .navigationTitle("Legg til Looper")
        .onAppear(perform: {
            if let simCredentials = accountService.simulatorCredentials() {
                nightscoutURLFieldText = simCredentials.url.absoluteString
                nameFieldText = "Jill-\(Int.random(in: 0...100))"
                apiSecretFieldText = simCredentials.secretKey
                qrURLFieldText = simCredentials.otpURL
            }
        })
        
    }
    
    private var inputFormView: some View {
        Form {
            Section {
                VStack {
                    Text("Navn")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField(
                        "Påkrevd",
                        text: $nameFieldText, onCommit:
                            {
                                self.save()
                            })
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                }
                VStack{
                    Text("Nightscout URL")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField(
                        "Påkrevd",
                        text: $nightscoutURLFieldText, onCommit:
                            {
                                self.save()
                            })
                    .autocapitalization(.none)
                    .disableAutocorrection(true)}
                VStack{
                    Text("API Secret")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField(
                        "Påkrevd",
                        text: $apiSecretFieldText
                    ) {
                        self.save()
                    }
                    .autocapitalization(.none)
                    .disableAutocorrection(true)}
                if qrURLFieldText == "" {
                    Button {
                        isShowingScanner = true
                    } label: {
                        Text("Skann QR")
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                } else {
                    TextField(
                        "QR skanner",
                        text: $qrURLFieldText, onCommit:
                            {
                                self.save()
                            }
                    )
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                }
            }
        }
    }
    
    private func disableFormSubmission() -> Bool {
        return !nameFieldValid() || !nightscoutURLFieldValid() || !apiSecretFieldValid() || !qrURLFieldValid() || authenticating
    }
    
    //TODO: This should just check if empty... And have separate methods if valid that can throw errors.
    
    private func nightscoutURLFieldValid() -> Bool {
        return !nightscoutURLFieldText.isEmpty
    }
    
    private func nameFieldValid() -> Bool {
        return !nameFieldText.isEmpty
    }
    
    private func apiSecretFieldValid() -> Bool {
        return !apiSecretFieldText.isEmpty
    }
    
    private func qrURLFieldValid() -> Bool {
        return !qrURLFieldText.isEmpty
    }
    
    private func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        switch result {
        case .success(let result):
            qrURLFieldText = result.string
        case .failure(let error):
            //TODO: Show error message
            errorText = "\(error.localizedDescription)"
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
    
    private func save(){
        Task {
            do {
                errorText = ""
                authenticating = true
                try await save(nightscoutURLText: nightscoutURLFieldText, name: nameFieldText, apiSecret: apiSecretFieldText, otpURL: qrURLFieldText)
                if !path.isEmpty {
                    path.removeLast()
                }

            } catch {
                errorText = "\(error.localizedDescription)"
            }
            
            authenticating = false
        }
    }
    
    func save(nightscoutURLText: String?, name: String?, apiSecret: String?, otpURL: String?) async throws {
        
        guard let name = name, name.count > 0 else {
            throw AccountViewModelError.genericError(message: "Må legge inn navn på Looper")
        }

        guard let nightscoutURLString = nightscoutURLText?.trimmingCharacters(in: CharacterSet(charactersIn: "/")),
                let nightscoutURL = URL(string: nightscoutURLString) else {
            throw AccountViewModelError.genericError(message: "Må legge inn gyldig Nightscout URL")
        }
        
        guard let apiSecret = apiSecret?.trimmingCharacters(in: .whitespacesAndNewlines), apiSecret.count > 0 else {
            throw AccountViewModelError.genericError(message: "Må legge inn API Secret")
        }
        
        guard let otpURL = otpURL, otpURL.count > 0 else {
            throw AccountViewModelError.genericError(message: "Må legge inn OTP URL")
        }

        let looper = Looper(identifier: UUID(), name: name, nightscoutCredentials: NightscoutCredentials(url: nightscoutURL, secretKey: apiSecret, otpURL: otpURL), lastSelectedDate: Date())
        let service = accountService.createLooperService(looper: looper, settings: settings)
        try await service.remoteDataSource.checkAuth()
        
        try accountService.addLooper(looper)
        try accountService.updateActiveLoopUser(looper)
    }
    
    func simulatedOTP() -> String {
        if let url = accountService.simulatorCredentials()?.otpURL {
            return url
        } else {
            return ""
        }
    }
}

enum AccountViewModelError: LocalizedError {
    case genericError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .genericError(let message):
            return message
        }
    }
}
