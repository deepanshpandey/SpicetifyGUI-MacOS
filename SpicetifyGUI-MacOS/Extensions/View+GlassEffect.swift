// View+GlassEffect.swift
import SwiftUI

extension View {
    /// Applies a liquid glass effect with blur and vibrancy
    func liquidGlass(
        cornerRadius: CGFloat = 16,
        opacity: Double = 0.8,
        blurRadius: CGFloat = 20
    ) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(opacity)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                .white.opacity(0.1),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
    }
    
    /// Applies a frosted glass card effect
    func frostedGlass(
        cornerRadius: CGFloat = 12,
        material: Material = .regular
    ) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(material)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            }
    }
    
    /// Applies a glass button effect with hover animation
    func glassButton(isPressed: Bool = false) -> some View {
        self
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
                    .opacity(isPressed ? 0.6 : 0.8)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
    
    /// Applies a shimmer effect for loading states
    func shimmer(active: Bool = true) -> some View {
        self
            .overlay {
                if active {
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(0.3),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .rotationEffect(.degrees(30))
                            .offset(x: -geometry.size.width)
                            .animation(
                                .linear(duration: 1.5)
                                    .repeatForever(autoreverses: false),
                                value: active
                            )
                    }
                    .mask(self)
                }
            }
    }
    
    /// Applies a glow effect
    func glow(color: Color, radius: CGFloat = 20, opacity: Double = 0.6) -> some View {
        self
            .shadow(color: color.opacity(opacity), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(opacity * 0.5), radius: radius / 2, x: 0, y: 0)
    }
    
    /// Applies a glass panel background
    func glassPanel(padding: CGFloat = 20) -> some View {
        self
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.1),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
            }
    }
    
    /// Applies a modern card style with glass effect
    func modernCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.thickMaterial)
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.25), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
    }
    
    /// Applies a subtle bounce animation
    func bounceAnimation(trigger: Bool) -> some View {
        self
            .scaleEffect(trigger ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: trigger)
    }
    
    /// Applies a floating animation
    func floatingAnimation(active: Bool = true) -> some View {
        self
            .offset(y: active ? -5 : 0)
            .animation(
                .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true),
                value: active
            )
    }
}

// Custom Material extension for more glass variations
extension Material {
    static var lightGlass: Material { .ultraThinMaterial }
    static var mediumGlass: Material { .thinMaterial }
    static var heavyGlass: Material { .regularMaterial }
}

// Color extensions for glass effects
extension Color {
    static var glassWhite: Color { .white.opacity(0.1) }
    static var glassBorder: Color { .white.opacity(0.2) }
    static var glassShadow: Color { .black.opacity(0.1) }
}
