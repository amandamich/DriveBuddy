//
//  Mascot.swift
//  DriveBuddy
//
//  Created by Timothy on 27/11/25.
//

import SwiftUI

struct Mascot: View {
	
	@State private var wave = false
	@State private var blink = false
	@State private var float = false
	@State private var tail = false
	
	let baseStroke = Color(hex: "0D1B2A")
	let mainColor = Color(hex: "FF9C41")
	let suitBlue = Color(hex: "1DA1F2")
	let cream = Color(hex: "FFE8C8")
	
	var body: some View {
		ZStack {
			
			// Floating body motion
			VStack(spacing: 0) {
				
				// HEAD
				ZStack {
					RoundedRectangle(cornerRadius: 35)
						.fill(mainColor)
						.overlay(
							RoundedRectangle(cornerRadius: 35)
								.stroke(baseStroke, lineWidth: 5)
						)
						.frame(width: 160, height: 140)
					
					// Face
					VStack(spacing: -2) {
						HStack(spacing: 38) {
							eye
							eye
						}
						.offset(y: -10)
						
						RoundedRectangle(cornerRadius: 18)
							.fill(cream)
							.frame(width: 95, height: 55)
							.overlay(Circle().fill(Color(hex:"6B3A1E")).frame(width: 16), alignment: .top)
							.overlay(mouth, alignment: .bottom)
							.offset(y: 8)
					}
				}
				
				// BODY
				RoundedRectangle(cornerRadius: 25)
					.fill(suitBlue)
					.frame(width: 140, height: 150)
					.overlay(RoundedRectangle(cornerRadius: 25).stroke(baseStroke, lineWidth: 5))
					.overlay(steeringWheelIcon.offset(y:20))
			}
			.offset(y: float ? -6 : 0)
			.animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: float)
			
			// HAND WAVE
			wavingHand
				.offset(x: 85, y: 60)
				.rotationEffect(.degrees(wave ? 18 : -4), anchor: .bottomLeading)
				.animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: wave)
			
			// TAIL
			tailShape
				.offset(x: -95, y: 90)
				.rotationEffect(.degrees(tail ? 10 : 0), anchor: .bottomTrailing)
				.animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: tail)
		}
		.onAppear {
			wave = true
			blinkCycle()
			float = true
			tail = true
		}
	}
	
	// MARK: - Subcomponents
	
	var eye: some View {
		ZStack {
			Capsule()
				.fill(Color(hex:"18222F"))
				.frame(width: 20, height: blink ? 4 : 26)
			
			Circle()
				.fill(.white)
				.frame(width: 7)
				.offset(x: 4, y: -4)
				.opacity(blink ? 0 : 1)
		}
		.animation(.easeOut(duration: 0.07), value: blink)
	}
	
	var mouth: some View {
		Path { p in
			p.move(to: CGPoint(x: 10, y: 10))
			p.addQuadCurve(to: CGPoint(x: 40, y: 10), control: CGPoint(x: 25, y: 25))
		}
		.stroke(Color(hex:"6B3A1E"), lineWidth: 4)
	}
	
	var wavingHand: some View {
		RoundedRectangle(cornerRadius: 20)
			.fill(mainColor)
			.frame(width: 50, height: 70)
			.overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex:"0D1B2A"), lineWidth: 4))
			.overlay(
				HStack(spacing: 4) {
					Circle().frame(width: 6)
					Circle().frame(width: 6)
					Circle().frame(width: 6)
				}
				.foregroundColor(Color(hex:"0D1B2A"))
				.offset(y: 10)
			)
	}
	
	var steeringWheelIcon: some View {
		Image(systemName:"steeringwheel")
			.font(.system(size: 32, weight: .bold))
			.foregroundColor(.white)
	}
	
	var tailShape: some View {
		Capsule()
			.fill(mainColor)
			.frame(width: 85, height: 36)
			.overlay(Capsule().stroke(Color(hex:"0D1B2A"), lineWidth: 4))
	}
	
	func blinkCycle() {
		Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
			blink = true
			DispatchQueue.main.asyncAfter(deadline:.now()+0.1) { blink = false }
		}
	}
}


#Preview {
    Mascot()
}

import SwiftUI

extension Color {
	init(hex: String) {
		var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
		hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
		
		var rgb: UInt64 = 0
		Scanner(string: hexSanitized).scanHexInt64(&rgb)
		
		let r = Double((rgb >> 16) & 0xFF) / 255
		let g = Double((rgb >> 8) & 0xFF) / 255
		let b = Double(rgb & 0xFF) / 255
		
		self.init(red: r, green: g, blue: b)
	}
}
