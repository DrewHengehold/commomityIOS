import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @Environment(UserSessionManager.self) private var session

    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.8716, longitude: -122.2727),
        span: MKCoordinateSpan(latitudeDelta: 1.5, longitudeDelta: 1.5)
    ))
    @State private var searchText        = ""
    @State private var availableCities: [String] = []
    @State private var selectedCity: String?      = nil
    @State private var cityMembers: [DisplayConnection] = []
    @State private var isLoadingCities  = false
    @State private var isLoadingMembers = false
    @State private var joinedCities: Set<String>  = []
    @State private var isJoining        = false

    private var filteredCities: [String] {
        guard !searchText.isEmpty else { return availableCities }
        return availableCities.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack(alignment: .top) {

            // ── Full-screen map ───────────────────────────────────────────
            Map(position: $position)
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss panel on map tap
                    if selectedCity != nil {
                        selectedCity = nil
                        cityMembers  = []
                    }
                }

            // ── Overlay UI ────────────────────────────────────────────────
            VStack(spacing: 0) {

                // Title
                HStack {
                    Text("Community Finder")
                        .font(AppTheme.Fonts.playfair(32, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.leading, 12)
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.bottom, 6)

                // Divider
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 1)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#060101"))
                    TextField("search city…", text: $searchText)
                        .font(AppTheme.Fonts.playfair(20))
                        .foregroundColor(Color(hex: "#160606"))
                        .autocorrectionDisabled()
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color(hex: "#8C8C8C"))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 50)
                        .fill(Color.white.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 50)
                                .strokeBorder(Color(hex: "#D8D8D8"), lineWidth: 2.3)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.top, 10)

                // City pills
                CityPickerRow(
                    cities:       filteredCities,
                    selectedCity: selectedCity,
                    joinedCities: joinedCities,
                    isLoading:    isLoadingCities,
                    onSelect: { city in
                        if selectedCity == city {
                            selectedCity = nil
                            cityMembers  = []
                        } else {
                            selectedCity = city
                            Task {
                                await loadMembers(for: city)
                                await flyTo(city: city)
                            }
                        }
                    }
                )
                .padding(.top, 8)

                Spacer()
            }

            // ── Bottom panel ──────────────────────────────────────────────
            if let city = selectedCity {
                VStack {
                    Spacer()
                    CityBottomPanel(
                        cityName:    city,
                        members:     cityMembers,
                        isLoading:   isLoadingMembers,
                        isJoined:    joinedCities.contains(city),
                        isJoining:   isJoining,
                        onClose: {
                            selectedCity = nil
                            cityMembers  = []
                        },
                        onJoin: {
                            Task { await joinCity(city) }
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: selectedCity)
        .task { await loadCities() }
    }

    // MARK: - Data loading

    private func loadCities() async {
        isLoadingCities = true
        defer { isLoadingCities = false }
        do {
            let cities = try await SupabaseService.shared.fetchAvailableCities()
            // Merge live DB cities with the broad fallback list so every city
            // is discoverable even before anyone registers there.
            let merged = Array(Set(cities + SampleData.fallbackCities)).sorted()
            availableCities = merged
        } catch {
            availableCities = SampleData.fallbackCities
        }
    }

    private func loadMembers(for city: String) async {
        isLoadingMembers = true
        cityMembers      = []
        defer { isLoadingMembers = false }
        do {
            cityMembers = try await SupabaseService.shared.fetchUsersInCity(city)
        } catch {
            cityMembers = SampleData.mapCommunity.members.filter { $0.city == city }
        }
    }

    private func flyTo(city: String) async {
        await withCheckedContinuation { continuation in
            CLGeocoder().geocodeAddressString(city) { placemarks, _ in
                if let coord = placemarks?.first?.location?.coordinate {
                    Task { @MainActor in
                        withAnimation(.easeInOut(duration: 0.7)) {
                            position = .region(MKCoordinateRegion(
                                center: coord,
                                span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                            ))
                        }
                    }
                }
                continuation.resume()
            }
        }
    }

    private func joinCity(_ city: String) async {
        guard let userId = session.currentUserId else { return }
        isJoining = true
        defer { isJoining = false }
        do {
            try await SupabaseService.shared.addUserLocation(userId: userId, city: city)
            joinedCities.insert(city)
        } catch {
            // Stub not yet implemented — optimistically mark joined for now
            joinedCities.insert(city)
        }
    }
}

// MARK: - City Picker Row

private struct CityPickerRow: View {
    let cities:       [String]
    let selectedCity: String?
    let joinedCities: Set<String>
    let isLoading:    Bool
    let onSelect:     (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .padding(.horizontal, 12)
                } else if cities.isEmpty {
                    Text("No cities found")
                        .font(AppTheme.Fonts.roboto(14))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                } else {
                    ForEach(cities, id: \.self) { city in
                        CityPill(
                            label:      city,
                            isSelected: city == selectedCity,
                            isJoined:   joinedCities.contains(city),
                            onTap:      { onSelect(city) }
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
        }
    }
}

// MARK: - City Pill

private struct CityPill: View {
    let label:      String
    let isSelected: Bool
    let isJoined:   Bool
    let onTap:      () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                if isJoined {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white : AppTheme.Colors.offeringTag)
                }
                Text(label)
                    .font(AppTheme.Fonts.roboto(14, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : Color(hex: "#301D2E"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 50)
                    .fill(isSelected
                          ? AppTheme.Colors.offeringTag
                          : Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 50)
                            .strokeBorder(
                                isSelected
                                    ? Color.clear
                                    : (isJoined
                                       ? AppTheme.Colors.offeringTag
                                       : Color(hex: "#D8D8D8")),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - City Bottom Panel

struct CityBottomPanel: View {
    let cityName:  String
    let members:   [DisplayConnection]
    let isLoading: Bool
    let isJoined:  Bool
    let isJoining: Bool
    let onClose:   () -> Void
    let onJoin:    () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // ── Header row ────────────────────────────────────────────────
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(cityName)
                        .font(AppTheme.Fonts.playfair(26, weight: .bold))
                        .foregroundColor(.black)
                    Text(isLoading ? "Loading…" : "\(members.count) member\(members.count == 1 ? "" : "s")")
                        .font(AppTheme.Fonts.roboto(13))
                        .foregroundColor(AppTheme.Colors.subtitleGray)
                }

                Spacer()

                // Join / Joined button
                Button(action: onJoin) {
                    HStack(spacing: 5) {
                        if isJoining {
                            ProgressView()
                                .scaleEffect(0.75)
                                .tint(.white)
                        } else if isJoined {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                        }
                        Text(isJoined ? "Joined" : "Join")
                            .font(AppTheme.Fonts.roboto(14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 50)
                            .fill(isJoined
                                  ? AppTheme.Colors.subtitleGray
                                  : AppTheme.Colors.offeringTag)
                    )
                }
                .disabled(isJoined || isJoining)

                // Dismiss button
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#6B6B6B"))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color(hex: "#F0F0F0")))
                }
                .padding(.leading, 6)
            }

            // ── Member cards ──────────────────────────────────────────────
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .frame(height: 90)
                    Spacer()
                }
            } else if members.isEmpty {
                Text("No members in \(cityName) yet — be the first to join!")
                    .font(AppTheme.Fonts.roboto(14))
                    .foregroundColor(AppTheme.Colors.subtitleGray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 72)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(members) { member in
                            MemberCard(member: member)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: -4)
        )
    }
}

// MARK: - Member Card  (horizontal scroll tile)

struct MemberCard: View {
    let member: DisplayConnection

    var body: some View {
        VStack(spacing: 8) {
            AvatarCircle(size: 54)

            VStack(spacing: 2) {
                Text(member.name.components(separatedBy: " ").first ?? member.name)
                    .font(AppTheme.Fonts.roboto(13, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(1)

                Text(member.profession)
                    .font(AppTheme.Fonts.roboto(11))
                    .foregroundColor(AppTheme.Colors.subtitleGray)
                    .lineLimit(1)

                Text(member.role)
                    .font(AppTheme.Fonts.roboto(11, weight: .medium))
                    .foregroundColor(AppTheme.Colors.connectionBlue)
                    .lineLimit(1)
            }
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#F7F7F7"))
        )
    }
}

// MARK: - Preview

#Preview {
    struct Preview: View {
        @State var session = UserSessionManager()
        var body: some View {
            MapView()
                .environment(session)
        }
    }
    return Preview()
}
