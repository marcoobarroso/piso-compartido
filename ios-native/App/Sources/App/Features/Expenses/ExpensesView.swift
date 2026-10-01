import SwiftUI
import UIKit
import RumisCore
import Supabase

/// Root view for the Expenses tab: add-expense form, balances & settle-up,
/// settlement history, recurring expenses and the recent expenses list
/// (with Excel export), mirroring app/household/expenses/page.tsx.
struct ExpensesView: View {
    @Environment(AppSession.self) private var session
    @State private var store = ExpensesStore()

    @State private var editingExpense: Expense?
    @State private var exportedFile: ExportedFile?
    @State private var exportError: String?
    @State private var isExporting = false

    var body: some View {
        // `session.household`/`.userId` can go briefly nil while signing
        // out; this view's body reads them directly, so guard instead of
        // force-unwrapping (force-unwrap here crashed on sign out).
        if let household = session.household, let userId = session.userId {
            content(householdId: household.id, userId: userId)
        } else {
            ProgressView()
                .tint(RTheme.primary)
        }
    }

    @ViewBuilder
    private func content(householdId: UUID, userId: UUID) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if let errorMessage = store.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(RTheme.destructive)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                AddExpenseCard(store: store, householdId: householdId, userId: userId)
                BalancesCard(store: store, currentUserId: userId, householdId: householdId)
                SettlementHistoryCard(store: store, householdId: householdId)
                RecurringExpensesCard(store: store, householdId: householdId, userId: userId)
                RecentExpensesCard(
                    store: store,
                    householdId: householdId,
                    onEdit: { expense in editingExpense = expense },
                    onExport: { Task { await exportExcel() } },
                    isExporting: isExporting,
                    exportError: exportError
                )
            }
            .padding(16)
        }
        .background(RTheme.background)
        .task {
            store.setMembers(session.members)
            await store.loadAll(householdId: householdId)
        }
        .refreshable {
            await store.loadAll(householdId: householdId)
        }
        .sheet(item: $editingExpense) { expense in
            EditExpenseSheet(store: store, expense: expense, householdId: householdId)
        }
        .sheet(item: $exportedFile) { file in
            ActivityShareSheet(activityItems: [file.url])
        }
    }

    private func exportExcel() async {
        exportError = nil
        isExporting = true
        defer { isExporting = false }
        do {
            var request = URLRequest(url: URL(string: "https://piso-compartido.vercel.app/household/expenses/export")!)
            let token = try await supabase.auth.session.accessToken
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (fileURL, _) = try await URLSession.shared.download(for: request)
            let destURL = FileManager.default.temporaryDirectory.appendingPathComponent("gastos.xlsx")
            try? FileManager.default.removeItem(at: destURL)
            try FileManager.default.moveItem(at: fileURL, to: destURL)
            exportedFile = ExportedFile(url: destURL)
        } catch {
            exportError = "No se ha podido exportar el Excel. Inténtalo de nuevo."
        }
    }
}

private struct ExportedFile: Identifiable {
    let url: URL
    var id: String { url.path }
}

private struct ActivityShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
