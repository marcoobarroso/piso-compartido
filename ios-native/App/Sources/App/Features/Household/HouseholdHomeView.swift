import SwiftUI
import RumisCore

/// Home tab: mirrors app/household/page.tsx (balance/chore/shopping stat
/// row, invite card, member list) plus the header from
/// app/household/layout.tsx (notification bell + settings entry point,
/// folded in here as a toolbar since there's no separate layout shell in
/// SwiftUI navigation).
struct HouseholdHomeView: View {
    @Environment(AppSession.self) private var session

    @State private var members: [HouseholdMember] = []
    @State private var balanceCents: Int = 0
    @State private var nextChoreAssignment: ChoreAssignment?
    @State private var pendingShoppingCount: Int = 0
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showSettings = false
    @State private var copied = false

    private let householdRepo = HouseholdRepository()
    private let expensesRepo = ExpensesRepository()
    private let choresRepo = ChoresRepository()
    private let shoppingRepo = ShoppingRepository()

    var body: some View {
        // `session.household` can go briefly nil while signing out — this
        // view's own @Observable read of it can re-render before its
        // ancestor (ContentView) has swapped it out for LoginView, so
        // guard here instead of force-unwrapping (which crashed on sign
        // out: EXC_BREAKPOINT force-unwrap at this former call site).
        if let household = session.household {
            content(household: household)
        } else {
            ProgressView()
                .tint(RTheme.primary)
        }
    }

    @ViewBuilder
    private func content(household: Household) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(RTheme.destructive)
                    }

                    HStack(spacing: 12) {
                        StatTile(
                            label: "Tu balance",
                            value: Format.formatCents(balanceCents),
                            tint: balanceCents >= 0 ? RTheme.primary : RTheme.destructive
                        )
                        StatTile(
                            label: "Próxima tarea",
                            value: nextChoreLabel,
                            tint: RTheme.primary
                        )
                        StatTile(
                            label: "Compra pendiente",
                            value: "\(pendingShoppingCount)",
                            tint: RTheme.primary
                        )
                    }

                    RCard(title: "Invitar a tu piso", systemImage: "person.badge.plus") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(household.inviteCode)
                                .font(.system(.largeTitle, design: .monospaced).bold())
                                .tracking(4)
                                .foregroundStyle(RTheme.primary)

                            HStack(spacing: 10) {
                                Button {
                                    UIPasteboard.general.string = household.inviteCode
                                    copied = true
                                    Task {
                                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                                        copied = false
                                    }
                                } label: {
                                    Text(copied ? "Copiado" : "Copiar")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.rSecondary)

                                if let shareURL = shareURL(inviteCode: household.inviteCode) {
                                    ShareLink(item: shareURL) {
                                        Text("WhatsApp")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.rPrimary)
                                }
                            }
                        }
                    }

                    RCard(title: "Compañeros de piso", systemImage: "person.2.fill") {
                        VStack(alignment: .leading, spacing: 12) {
                            if members.isEmpty && !isLoading {
                                Text("Todavía no hay compañeros.")
                                    .font(.subheadline)
                                    .foregroundStyle(RTheme.mutedForeground)
                            }
                            ForEach(members) { member in
                                HStack(spacing: 10) {
                                    Text(member.profiles?.displayName ?? "Sin nombre")
                                        .font(.subheadline)
                                        .foregroundStyle(RTheme.cardForeground)
                                    Spacer()
                                    if member.isAdmin {
                                        RBadge(text: "Admin")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(RTheme.background)
            .navigationTitle(household.name)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NotificationBellView()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Ajustes")
                }
            }
            .sheet(isPresented: $showSettings) {
                AccountSettingsView()
            }
            .task {
                await load()
            }
            .refreshable {
                await load()
            }
        }
    }

    private var nextChoreLabel: String {
        guard let nextChoreAssignment else { return "Nada pendiente" }
        return Format.formatDate(nextChoreAssignment.dueDate)
    }

    private func shareURL(inviteCode: String) -> URL? {
        let message = "Únete a nuestro piso en Rumis: https://piso-compartido.vercel.app/join/\(inviteCode)"
        guard let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "https://wa.me/?text=" + encoded)
    }

    private func load() async {
        errorMessage = nil
        guard let householdId = session.household?.id, let userId = session.userId else { return }
        do {
            async let membersTask = householdRepo.fetchMembers(householdId: householdId)
            async let expensesTask = expensesRepo.fetchExpenses(householdId: householdId)
            async let sharesTask = expensesRepo.fetchShares(householdId: householdId)
            async let settlementsTask = expensesRepo.fetchSettlements(householdId: householdId)
            async let assignmentsTask = choresRepo.fetchAssignments(householdId: householdId)
            async let shoppingTask = shoppingRepo.fetchItems(householdId: householdId)

            let (fetchedMembers, expenses, shares, settlements, assignments, shoppingItems) = try await (
                membersTask, expensesTask, sharesTask, settlementsTask, assignmentsTask, shoppingTask
            )

            members = fetchedMembers

            let balances = DebtSimplify.computeBalances(
                expenses: expenses.map { ExpenseInput(paidBy: $0.paidBy.uuidString, amountCents: $0.amountCents) },
                shares: shares.map { ExpenseShareInput(userId: $0.userId.uuidString, shareCents: $0.shareCents) },
                settlements: settlements.map {
                    SettlementInput(
                        fromUserId: $0.fromUserId.uuidString,
                        toUserId: $0.toUserId.uuidString,
                        amountCents: $0.amountCents
                    )
                }
            )
            balanceCents = balances.get(userId.uuidString) ?? 0

            nextChoreAssignment = assignments
                .filter { $0.status == "pending" && $0.assignedTo == userId }
                .sorted { $0.dueDate < $1.dueDate }
                .first

            pendingShoppingCount = shoppingItems
                .filter { !$0.isChecked && ($0.isShared || $0.ownerUserId == userId) }
                .count

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "No se ha podido cargar el piso. Tira hacia abajo para reintentar."
        }
    }
}
