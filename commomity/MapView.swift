import SwiftUI
import MapKit

struct MapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.8716, longitude: -122.2727),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    @State private var searchText        = ""
    @State private var availableCities: [String] = []
    @State private var selectedCity: String?      = nil
    @State private var cityMembers: [DisplayConnection] = []
    @State private var isLoadingCities  = false
    @State private var isLoadingMembers = false

    // City list filtered by what the user types in the search bar
    private var filteredCities: [String] {
        guard !searchText.isEmpty else { return availableCities }
        return availableCities.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Full-screen map background
            Map(coordinateRegion: $region)
                .ignoresSafeArea()
                .cornerRadius(AppTheme.cornerRadius)

            VStack(spacing: 0) {

                // ── Title ────────────────────────────────────────────────
                HStack {
                    Text("Community Finder")
                        .font(AppTheme.Fonts.playfair(36, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.leading, 9)
                    Spacer()
                }
                .padding(.top, 10)

                // ── Divider ──────────────────────────────────────────────
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 1)
                    .padding(.top, 4)

                // ── Search bar ───────────────────────────────────────────
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#060101"))
                    TextField("search city…", text: $searchText)
                        .font(AppTheme.Fonts.playfair(24))
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
                        .fill(Color.white.opacity(0.49))
                        .overlay(
                            RoundedRectangle(cornerRadius: 50)
                                .strokeBorder(Color(hex: "#D8D8D8"), lineWidth: 2.3)
                        )
                )
                .padding(.horizontal, 21)
                .padding(.top, 10)

                // ── City picker pills ─────────────────────────────────────
                CityPickerRow(
                    cities:       filteredCities,
                    selectedCity: selectedCity,
                    isLoading:    isLoadingCities,
                    onSelect: { city in
                        if selectedCity == city {
                            selectedCity = nil
                            cityMembers  = []
                        } else {
                            selectedCity = city
                            Task { await loadMembers(for: city) }
                        }
                    }
                )
                .padding(.top, 8)

                Spacer()

                // ── City members popup ────────────────────────────────────
                if let city = selectedCity {
                    HStack {
                        Spacer()
                        CityMembersPopup(
                            cityName:  city,
                            members:   cityMembers,
                            isLoading: isLoadingMembers,
                            onClose: {
                                selectedCity = nil
                                cityMembers  = []
                            }
                        )
                        .padding(.trailing, 18)
                    }
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedCity)
        .task { await loadCities() }
    }

    // MARK: - Data loading

    private func loadCities() async {
        isLoadingCities = true
        defer { isLoadingCities = false }
        do {
            let cities = try await SupabaseService.shared.fetchAvailableCities()
            availableCities = cities.isEmpty ? SampleData.fallbackCities : cities
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
            // Fall back to filtered sample data while DB is being populated
            cityMembers = SampleData.mapCommunity.members.filter { $0.city == city }
        }
    }
}

// MARK: - City Picker Row

private struct CityPickerRow: View {
    let cities:       [String]
    let selectedCity: String?
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
                            onTap:      { onSelect(city) }
                        )
                    }
                }
            }
            .padding(.horizontal, 21)
        }
    }
}

// MARK: - City Pill

private struct CityPill: View {
    let label:      String
    let isSelected: Bool
    let onTap:      () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(AppTheme.Fonts.roboto(14, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : Color(hex: "#301D2E"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 50)
                        .fill(isSelected
                              ? AppTheme.Colors.offeringTag
                              : Color.white.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 50)
                                .strokeBorder(
                                    isSelected ? Color.clear : Color(hex: "#D8D8D8"),
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

// MARK: - City Members Popup

/// Styled after the existing CommunityPopup — dark-gray card, city name,
/// member count, scrollable MemberTile list.
struct CityMembersPopup: View {
    let cityName:  String
    let members:   [DisplayConnection]
    let isLoading: Bool
    let onClose:   () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.Colors.mapPopupBg)
                    .frame(width: 240)

                VStack(alignment: .leading, spacing: 6) {

                    // Header: city name + dismiss button
                    HStack(alignment: .top) {
                        Text(cityName)
                            .font(AppTheme.Fonts.roboto(20, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "#9D9D9D"))
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 14)

                    // Member count / loading indicator
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding(.horizontal, 14)
                    } else {
                        Text("\(members.count) member\(members.count == 1 ? "" : "s")")
                            .font(AppTheme.Fonts.roboto(14, weight: .bold))
                            .foregroundColor(Color(hex: "#9D9D9D"))
                            .padding(.horizontal, 14)
                    }

                    // Member list
                    if isLoading {
                        Color.clear.frame(height: 60)
                    } else if members.isEmpty {
                        Text("No members found in this city.")
                            .font(AppTheme.Fonts.roboto(13))
                            .foregroundColor(Color(hex: "#9D9D9D"))
                            .padding(.horizontal, 14)
                            .padding(.bottom, 14)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 8) {
                                ForEach(members) { member in
                                    MemberTile(member: member)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.bottom, 14)
                        }
                        .frame(maxHeight: 280)
                    }
                }
            }
            .frame(width: 240)

            // Callout pointer (matches the original CommunityPopup)
            Rectangle()
                .fill(AppTheme.Colors.mapPopupBg)
                .frame(width: 16.5, height: 48.5)
                .offset(x: -95)
        }
    }
}

// MARK: - Member Tile

struct MemberTile: View {
    let member: DisplayConnection

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.Colors.tileBackground)
                .frame(height: 50)

            HStack(spacing: 10) {
                AvatarCircle(size: 42)
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(AppTheme.Fonts.roboto(16, weight: .medium))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    Text("\(member.role) – \(member.profession)")
                        .font(AppTheme.Fonts.roboto(12, weight: .medium))
                        .foregroundColor(AppTheme.Colors.connectionBlue)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 8)
        }
    }
}

// MARK: - Fallback cities (used when Supabase returns nothing yet)

extension SampleData {
    static let fallbackCities = [
        "San Francisco", "Oakland", "Berkeley", "Petaluma", "San Jose"
    ]
}

#Preview {
    MapView()
}
