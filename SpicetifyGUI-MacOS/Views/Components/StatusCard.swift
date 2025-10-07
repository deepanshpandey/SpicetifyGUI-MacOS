// StatusCard.swift
import SwiftUI

struct StatusCard: View {
    let status: SpicetifyStatus
    @State private var isHovering = false
    
    var body: some View {
        GlassCard(padding: 24, cornerRadius: 20) {
            HStack(spacing: 20) {
                // Status Icon
                ZStack {
                    Circle()
                        .fill(status.color.opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .fill(status.color.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .blur(radius: 10)
                    
                    Image(systemName: status.iconName)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(status.color)
                        .symbolEffect(.bounce, value: status)
                }
                .glow(color: status.color, radius: 20, opacity: 0.4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Status")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(status.displayText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text(status.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
        }
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

