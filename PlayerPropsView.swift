//
//  PlayerPropsView.swift
//  Multi-Sport Parlay Picker
//
//  Player props parlay builder for NBA
//

import SwiftUI
import Combine

// MARK: - Player Props View

struct PlayerPropsView: View {
    @ObservedObject var settings: UnifiedSettingsStore
    @StateObject private var viewModel = PlayerPropsViewModel()
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // Tab 1: Builder
            NavigationView {
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        ProgressView("Loading player stats...")
                            .padding()
                    } else if let error = viewModel.errorMessage {
                        ErrorView(message: error) {
                            Task {
                                // FIX 1: Correctly calling async function
                                await viewModel.loadPlayerStats(settings: settings)
                            }
                        }
                    } else {
                        // Main content
                        ScrollView {
                            VStack(spacing: 16) {
                                categoryPicker
                                playersSection
                                
                                if !viewModel.selectedProps.isEmpty {
                                    parlayBuilderSection
                                }
                            }
                            .padding()
                        }
                    }
                }
                .navigationTitle("Player Props Builder")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Refresh") {
                            Task {
                                // FIX 2: Correctly calling async function
                                await viewModel.loadPlayerStats(settings: settings)
                            }
                        }
                    }
                }
                .onAppear {
                    Task {
                        // FIX 3: Correctly calling async function
                        await viewModel.loadPlayerStats(settings: settings)
                    }
                }
            }
            .tabItem {
                Label("Builder", systemImage: "list.bullet.rectangle.fill")
            }
            .tag(0)
            
            // Tab 2: 3-Leg Risk (Results)
            NavigationView {
                VStack {
                    if viewModel.generatedParlays.isEmpty {
                        ContentUnavailableView(
                            "No Parlays Added",
                            systemImage: "table.badge.xmark",
                            description: Text("Select exactly three unique props on the Builder tab and tap 'Add to Parlay Bets'.")
                        )
                    } else {
                        parlaysSection
                    }
                }
                .navigationTitle("3-Leg Risk")
                .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("3-Leg Risk", systemImage: "chart.bar.doc.horizontal.fill")
            }
            .tag(1)
        }
    }
    
    // MARK: - Category Picker
    
    private var categoryPicker: some View {
        Picker("Category", selection: $viewModel.selectedCategory) {
            Text("Points").tag(StatCategory.points)
            Text("3-Pointers").tag(StatCategory.threes)
            Text("Assists").tag(StatCategory.assists)
            Text("Rebounds").tag(StatCategory.rebounds)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .onChange(of: viewModel.selectedCategory) { _, _ in
            // FIX 4: Correctly calling synchronous method
            viewModel.updateTopPlayers()
        }
    }
    
    // MARK: - Players Section
    
    private var playersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top 10 Players - \(viewModel.selectedCategory.displayName)")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(viewModel.topPlayers) { player in
                PlayerPropRow(
                    player: player,
                    category: viewModel.selectedCategory,
                    isSelected: viewModel.isPlayerSelected(player),
                    onSelect: { overUnder in
                        // FIX 5: Correctly calling synchronous method
                        viewModel.togglePlayerProp(player, category: viewModel.selectedCategory, overUnder: overUnder)
                    }
                )
            }
        }
    }
    
    // MARK: - Parlay Builder Section (Add to Bets Logic)
    
    private var parlayBuilderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Parlay (\(viewModel.selectedProps.count) of 3)")
                    .font(.headline)
                Spacer()
                
                if viewModel.selectedProps.count == 3 {
                    Button("Add to Parlay Bets") {
                        // Action: Save the current 3-leg selection and switch tab
                        viewModel.addCurrentSelectionToParlays()
                        selectedTab = 1
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    // Disabled button to show required count
                    Button("Select \(3 - viewModel.selectedProps.count) more legs") {}
                        .buttonStyle(.bordered)
                        .disabled(true)
                }
                
                Button("Clear") {
                    viewModel.clearSelection()
                }
                .foregroundColor(.red)
            }
            .padding(.horizontal)
            
            ForEach(viewModel.selectedProps) { prop in
                SelectedPropRow(prop: prop) {
                    viewModel.removeProp(prop)
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Parlays Section
    
    private var parlaysSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Saved Parlays (Highest Probability First)")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(viewModel.generatedParlays) { parlay in
                    ParlayCard(parlay: parlay)
                }
            }
        }
    }
}

// MARK: - Supporting Views (REMAINS THE SAME)

struct PlayerPropRow: View {
    let player: PlayerPropData
    let category: StatCategory
    let isSelected: Bool
    let onSelect: (OverUnder) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.abbreviation)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(player.fullName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(player.medianValue(for: category))
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Median (\(player.gamesPlayed)G)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Over/Under buttons with Odds and Probability
            HStack(spacing: 12) {
                // OVER BUTTON
                Button(action: { onSelect(.over) }) {
                    VStack {
                        Text("Over")
                        // Display odds (e.g., +150)
                        Text(player.overOdds != nil ? "(\(player.overOdds! > 0 ? "+" : "")\(player.overOdds!))" : "-")
                            .font(.caption)
                        // Display Implied Probability
                        Text(String(format: "%.1f%%", (player.overProb ?? 0) * 100))
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isSelected ? Color.green.opacity(0.2) : Color(.systemGray6))
                    .foregroundColor(.green)
                    .cornerRadius(8)
                }
                
                // UNDER BUTTON
                Button(action: { onSelect(.under) }) {
                    VStack {
                        Text("Under")
                        // Display odds (e.g., -110)
                        Text(player.underOdds != nil ? "(\(player.underOdds! > 0 ? "+" : "")\(player.underOdds!))" : "-")
                            .font(.caption)
                        // Display Implied Probability
                        Text(String(format: "%.1f%%", (player.underProb ?? 0) * 100))
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isSelected ? Color.red.opacity(0.2) : Color(.systemGray6))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct SelectedPropRow: View {
    let prop: SelectedPlayerProp
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: prop.overUnder == .over ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundColor(prop.overUnder == .over ? .green : .red)
            
            Text(prop.shorthand)
                .font(.headline)
            
            Spacer()
            
            // Display probability and odds next to the selection
            VStack(alignment: .trailing, spacing: 2) {
                Text(prop.odds > 0 ? "+\(prop.odds)" : "\(prop.odds)")
                    .font(.caption)
                    .fontWeight(.bold)
                Text(String(format: "%.1f%%", prop.probability * 100))
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct ParlayCard: View {
    let parlay: GeneratedParlay
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Parlay #\(parlay.id)")
                    .font(.headline)
                Spacer()
                Text(parlay.oddsString)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(parlay.americanOdds > 0 ? .green : .red)
            }
            
            HStack {
                Text("Combined Probability")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(parlay.probabilityString)
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            
            Divider()
            
            ForEach(parlay.legs, id: \.id) { leg in
                HStack {
                    Image(systemName: leg.overUnder == .over ? "arrow.up" : "arrow.down")
                        .foregroundColor(leg.overUnder == .over ? .green : .red)
                    Text(leg.shorthand)
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.1f%%", leg.probability * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("Retry", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    PlayerPropsView(settings: UnifiedSettingsStore())
}
