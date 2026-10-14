import SwiftUI
import RumisCore

/// Home tab: mirrors app/household/page.tsx (balance/chore/shopping summary,
/// invite card, member list) plus the header from app/household/layout.tsx
/// (notification bell + settings entry point, folded in here as a toolbar
/// since there's no separate layout shell in SwiftUI navigation). Summary
/// cards jump to their tab through `openTab`.
struct HouseholdHomeView: View {
    /// Switches RootTabView's selected tab (1 Gastos, 2 Tareas, 3 Compra).
    var openTab: (Int) -> Void = { _ in }

    @Environment(AppSession.self) private var session
    @Environment(\.isSplashVisible) private var isSplashVisible
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var balanceCents: Int = 0
    @State private var nextChoreAssignment: ChoreAssignment?
    @State private var nextChoreName: String?
    @State private var pendingShoppingCount: Int = 0
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showSettings = false
    @State private var copied = false
    @State private var appeared = false

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
        // With nobody else in the flat yet, inviting is the next step, so
        // it goes before the (empty) member list.
        let inviteFirst = session.members.count <= 1

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    greeting
                        .entrance(appeared, index: 0, reduceMotion: reduceMotion)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(RTheme.destructive)
                    }

                    balanceCard
                        .entrance(appeared, index: 1, reduceMotion: reduceMotion)

                    HStack(spacing: 12) {
                        choreTile
                        shoppingTile
                    }
                    .entrance(appeared, index: 2, reduceMotion: reduceMotion)

                    if inviteFirst {
                        inviteCard(code: household.inviteCode)
                            .entrance(appeared, index: 3, reduceMotion: reduceMotion)
                        membersCard
                            .entrance(appeared, index: 4, reduceMotion: reduceMotion)
                    } else {
                        membersCard
                            .entrance(appeared, index: 3, reduceMotion: reduceMotion)
                        inviteCard(code: household.inviteCode)
                            .entrance(appeared, index: 4, reduceMotion: reduceMotion)
                    }
                }
                .padding(16)
            }
            .background(RTheme.background)
            .navigationTitle(household.name)
            .navigationBarTitleDisplayMode(.inline)
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
        // Cards assemble themselves once the launch splash has lifted, not
        // underneath it where nobody would see it.
        .onAppear {
            if !isSplashVisible { appeared = true }
        }
        .onChange(of: isSplashVisible) { _, visible in
            if !visible { appeared = true }
        }
    }

    // MARK: - Sections

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "es_ES"))))
                .font(.footnote.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(RTheme.mutedForeground)
            Text(greetingText)
                .font(.largeTitle.bold())
                .foregroundStyle(RTheme.foreground)
        }
        .accessibilityElement(children: .combine)
    }

    private var balanceCard: some View {
        Button {
            openTab(1)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Tu balance", systemImage: "eurosign.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Text(Format.formatCents(balanceCents))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText(value: Double(balanceCents)))
                    .redacted(reason: isLoading ? .placeholder : [])

                Text(balanceStatus)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.16), in: Capsule())
                    .redacted(reason: isLoading ? .placeholder : [])
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack(alignment: .topTrailing) {
                    RBrand.gradient
                    RadialGradient(
                        colors: [.white.opacity(0.22), .clear],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 220
                    )
                    Image(systemName: "house.fill")
                        .font(.system(size: 130))
                        .foregroundStyle(.white.opacity(0.07))
                        .offset(x: 28, y: 30)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: RTheme.Radius.xxl, style: .continuous))
            .shadow(color: RBrand.coral.opacity(0.25), radius: 20, y: 10)
        }
        .buttonStyle(.rPressable)
        .accessibilityHint("Abre Gastos")
    }

    private var choreTile: some View {
        SummaryTile(
            systemImage: "checklist",
            title: "Próxima tarea",
            value: nextChoreName ?? "Nada pendiente",
            detail: nextChoreDetail,
            detailTint: nextChoreIsOverdue ? RTheme.destructive : RTheme.mutedForeground,
            isLoading: isLoading
        ) {
            openTab(2)
        }
        .accessibilityHint("Abre Tareas")
    }

    private var shoppingTile: some View {
        SummaryTile(
            systemImage: "cart.fill",
            title: "Compra",
            value: "\(pendingShoppingCount)",
            detail: pendingShoppingCount == 1 ? "artículo pendiente" : "artículos pendientes",
            isLoading: isLoading
        ) {
            openTab(3)
        }
        .contentTransition(.numericText(value: Double(pendingShoppingCount)))
        .accessibilityHint("Abre Compra")
    }

    private var membersCard: some View {
        RCard(
            title: "Compañeros de piso",
            systemImage: "person.2.fill",
            description: session.members.count == 1 ? "1 persona" : "\(session.members.count) personas"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if session.members.isEmpty && !isLoading {
                    Text("Todavía no hay compañeros.")
                        .font(.subheadline)
                        .foregroundStyle(RTheme.mutedForeground)
                }
                ForEach(Array(session.members.enumerated()), id: \.element.id) { index, member in
                    let name = member.profiles?.displayName ?? "Sin nombre"
                    HStack(spacing: 12) {
                        MemberAvatar(name: name, color: ChartPalette.color(at: index))
                        Text(name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RTheme.cardForeground)
                        if member.userId == session.userId {
                            RBadge(text: "Tú", tint: RTheme.accentForeground, background: RTheme.accent)
                        }
                        Spacer()
                        if member.isAdmin {
                            RBadge(text: "Admin")
                        }
                    }
                }
            }
        }
    }

    private func inviteCard(code: String) -> some View {
        RCard(
            title: "Invitar a tu piso",
            systemImage: "person.badge.plus",
            description: "Comparte este código con tus compañeros."
        ) {
            VStack(spacing: 12) {
                Text(code)
                    .font(.system(.largeTitle, design: .monospaced).bold())
                    .tracking(4)
                    .foregroundStyle(RTheme.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RTheme.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: RTheme.Radius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: RTheme.Radius.md)
                            .strokeBorder(RTheme.primary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    )
                    .accessibilityLabel("Código de invitación \(code)")

                HStack(spacing: 10) {
                    Button {
                        UIPasteboard.general.string = code
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { copied = true }
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            withAnimation { copied = false }
                        }
                    } label: {
                        Label(copied ? "Copiado" : "Copiar", systemImage: copied ? "checkmark" : "doc.on.doc")
                            .contentTransition(.symbolEffect(.replace))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.rSecondary)
                    .sensoryFeedback(.success, trigger: copied) { _, isCopied in isCopied }

                    if let shareURL = shareURL(inviteCode: code) {
                        ShareLink(item: shareURL) {
                            Label("WhatsApp", systemImage: "paperplane.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.rPrimary)
                    }
                }
            }
        }
    }

    // MARK: - Derived text

    private var greetingText: String {
        let firstName = session.profile?.displayName?
            .split(separator: " ")
            .first
            .map(String.init)
        guard let firstName, !firstName.isEmpty else { return "Hola" }
        return "Hola, \(firstName)"
    }

    private var balanceStatus: String {
        if balanceCents > 0 { return "Te deben dinero" }
        if balanceCents < 0 { return "Debes dinero" }
        return "Estás al día"
    }

    private var nextChoreIsOverdue: Bool {
        guard let nextChoreAssignment else { return false }
        return Format.isOverdue(nextChoreAssignment.dueDate)
    }

    private var nextChoreDetail: String {
        guard let nextChoreAssignment else { return "Todo hecho" }
        let dueDate = nextChoreAssignment.dueDate
        if Format.isOverdue(dueDate) { return "Atrasada · \(Format.formatDate(dueDate))" }
        if Format.isToday(dueDate) { return "Hoy" }
        if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now),
           Format.isToday(dueDate, now: tomorrow) {
            return "Mañana"
        }
        return Format.formatDate(dueDate)
    }

    private func shareURL(inviteCode: String) -> URL? {
        let joinURL = AppConfig.webBaseURL.appendingPathComponent("join/\(inviteCode)")
        let message = "Únete a nuestro piso en Rumies: \(joinURL.absoluteString)"
        guard let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "https://wa.me/?text=" + encoded)
    }

    // MARK: - Loading

    private func load() async {
        errorMessage = nil
        guard let householdId = session.household?.id, let userId = session.userId else { return }
        do {
            async let expensesTask = expensesRepo.fetchExpenses(householdId: householdId)
            async let sharesTask = expensesRepo.fetchShares(householdId: householdId)
            async let settlementsTask = expensesRepo.fetchSettlements(householdId: householdId)
            async let choresTask = choresRepo.fetchChores(householdId: householdId)
            async let assignmentsTask = choresRepo.fetchAssignments(householdId: householdId)
            async let shoppingTask = shoppingRepo.fetchItems(householdId: householdId)

            let (expenses, shares, settlements, chores, assignments, shoppingItems) = try await (
                expensesTask, sharesTask, settlementsTask, choresTask, assignmentsTask, shoppingTask
            )

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

            let nextAssignment = assignments
                .filter { $0.status == "pending" && $0.assignedTo == userId }
                .sorted { $0.dueDate < $1.dueDate }
                .first

            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                balanceCents = balances.get(userId.uuidString) ?? 0
                nextChoreAssignment = nextAssignment
                nextChoreName = nextAssignment.flatMap { assignment in
                    chores.first { $0.id == assignment.choreId }?.name
                }
                pendingShoppingCount = shoppingItems
                    .filter { !$0.isChecked && ($0.isShared || $0.ownerUserId == userId) }
                    .count
                isLoading = false
            }
        } catch {
            isLoading = false
            errorMessage = "No se ha podido cargar el piso: \(error.localizedDescription)"
        }
    }
}

// MARK: - Pieces

/// Square summary card on Inicio: icon chip, label, big value and a detail
/// line, tappable as a whole.
private struct SummaryTile: View {
    let systemImage: String
    let title: String
    let value: String
    let detail: String
    var detailTint: Color = RTheme.mutedForeground
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: RTheme.Radius.sm)
                            .fill(RTheme.accent)
                        Image(systemName: systemImage)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RTheme.accentForeground)
                    }
                    .frame(width: 32, height: 32)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RTheme.mutedForeground)
                }

                Spacer(minLength: 0)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(RTheme.mutedForeground)
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(RTheme.cardForeground)
                    .lineLimit(2, reservesSpace: true)
                    .minimumScaleFactor(0.7)
                    .redacted(reason: isLoading ? .placeholder : [])
                Text(detail)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(detailTint)
                    .lineLimit(1)
                    .redacted(reason: isLoading ? .placeholder : [])
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
            .background(RTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: RTheme.Radius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RTheme.Radius.xl, style: .continuous)
                    .strokeBorder(RTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.rPressable)
    }
}

/// Initials in a tinted circle, colored per member like their chart series.
private struct MemberAvatar: View {
    let name: String
    let color: Color

    var body: some View {
        Text(initials)
            .font(.caption.weight(.bold))
            .foregroundStyle(color)
            .frame(width: 34, height: 34)
            .background(color.opacity(0.18), in: Circle())
            .overlay(Circle().strokeBorder(color.opacity(0.35), lineWidth: 1))
            .accessibilityHidden(true)
    }

    private var initials: String {
        let letters = name.split(separator: " ").prefix(2).compactMap(\.first)
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }
}

/// Soft rise-and-settle entrance, staggered by `index`.
private struct Entrance: ViewModifier {
    let shown: Bool
    let index: Int
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 18)
            .scaleEffect(shown || reduceMotion ? 1 : 0.97, anchor: .top)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.25)
                    : .spring(response: 0.5, dampingFraction: 0.82).delay(0.05 + Double(index) * 0.07),
                value: shown
            )
    }
}

private extension View {
    func entrance(_ shown: Bool, index: Int, reduceMotion: Bool) -> some View {
        modifier(Entrance(shown: shown, index: index, reduceMotion: reduceMotion))
    }
}
