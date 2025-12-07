//
//  PlayerPropsView.swift
//  NBA Player Parlay
//
//  Player props parlay builder with lines and combinations
//

import SwiftUI

// MARK: - Player Props View

struct PlayerPropsView: View {
    @ObservedObject var settings: UnifiedSettingsStore
    @StateObject private var viewModel = PlayerPropsViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView("Loading player stats...")
                        .padding()
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        Task {
                            await viewModel.loadPlayerStats(settings: settings)
                        }
                    }
                } else {
                    // Main content
                    ScrollView {
                        VStack(spacing: 16) {
                            // Category selector
                            categoryPicker
                            
                            // Top 10 players in selected category
                            playersSection
                            
                            // Generate button at bottom
                            if !viewModel.availableProps.isEmpty {
                                generateButton
                            }
                            
                            // Generated parlays table
                            if !viewModel.generatedParlays.isEmpty {
                                parlaysTable
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Player Props Parlay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await viewModel.loadPlayerStats(settings: settings)
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadPlayerStats(settings: settings)
                }
            }
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
        .onChange(of: viewModel.selectedCategory) { oldValue, newValue in
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
                PlayerPropRowWithLines(
                    player: player,
                    category: viewModel.selectedCategory,
                    selectedProps: viewModel.selectedPropIDs,
                    onSelectOver: {
                        viewModel.togglePlayerProp(player, category: viewModel.selectedCategory, overUnder: .over)
                    },
                    onSelectUnder: {
                        viewModel.togglePlayerProp(player, category: viewModel.selectedCategory, overUnder: .under)
                    }
                )
            }
        }
    }
    
    // MARK: - Generate Button
    
    private var generateButton: some View {
        Button(action: {
            viewModel.generateAllCombinations()
        }) {
            HStack {
                Image(systemName: "chart.bar.fill")
                Text("Generate All 3-Leg Parlays")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Parlays Table
    
    private var parlaysTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("All 3-Leg Parlays")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.generatedParlays.count) combinations")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Table Header
            HStack {
                Text("#")
                    .frame(width: 30, alignment: .leading)
                    .font(.caption)
                    .fontWeight(.bold)
                
                Text("Leg 1")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.caption)
                    .fontWeight(.bold)
                
                Text("Leg 2")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.caption)
                    .fontWeight(.bold)
                
                Text("Leg 3")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.caption)
                    .fontWeight(.bold)
                
                Text("Prob")
                    .frame(width: 60, alignment: .trailing)
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray5))
            
            // Table Rows
            ForEach(Array(viewModel.generatedParlays.enumerated()), id: \.element.id) { index, parlay in
                ParlayTableRow(rank: index + 1, parlay: parlay)
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Player Prop Row With Lines

struct PlayerPropRowWithLines: View {
    let player: PlayerPropData
    let category: StatCategory
    let selectedProps: Set<String>
    let onSelectOver: () -> Void
    let onSelectUnder: () -> Void
    
    var isOverSelected: Bool {
        selectedProps.contains("\(player.playerID)-\(category.rawValue)-over")
    }
    
    var isUnderSelected: Bool {
        selectedProps.contains("\(player.playerID)-\(category.rawValue)-under")
    }
    
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
            
            // Over/Under buttons with lines
            HStack(spacing: 12) {
                Button(action: onSelectOver) {
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                            Text("Over")
                        }
                        Text(player.overLine(for: category))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isOverSelected ? Color.green : Color(.systemGray6))
                    .foregroundColor(isOverSelected ? .white : .green)
                    .cornerRadius(8)
                }
                
                Button(action: onSelectUnder) {
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Under")
                        }
                        Text(player.underLine(for: category))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isUnderSelected ? Color.red : Color(.systemGray6))
                    .foregroundColor(isUnderSelected ? .white : .red)
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

// MARK: - Parlay Table Row

struct ParlayTableRow: View {
    let rank: Int
    let parlay: GeneratedParlay
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(rank)")
                .frame(width: 30, alignment: .leading)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(parlay.legs[0].shorthand)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.caption)
            
            Text(parlay.legs[1].shorthand)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.caption)
            
            Text(parlay.legs[2].shorthand)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.caption)
            
            Text(parlay.probabilityString)
                .frame(width: 60, alignment: .trailing)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(rank % 2 == 0 ? Color(.systemGray6).opacity(0.3) : Color.clear)
    }
}

// MARK: - Error View

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
