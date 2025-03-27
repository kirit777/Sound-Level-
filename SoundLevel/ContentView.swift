import SwiftUI
import AVFoundation

class SoundLevelMonitor: ObservableObject {
    private var audioEngine = AVAudioEngine()
    
    @Published var decibels: Float = 0.0
    
    func startMonitoring() {
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            let level = self.getSoundLevel(buffer: buffer)
            DispatchQueue.main.async {
                self.decibels = level
            }
        }
        
        try? audioEngine.start()
    }
    
    func stopMonitoring() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
    
    private func getSoundLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let channelDataArray = Array(UnsafeBufferPointer(start: channelData[0], count: Int(buffer.frameLength)))
        let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength) + Float.ulpOfOne)
        let level = 20 * log10(rms)
        return max(level + 100, 0)
    }
}

struct ContentView: View {
    @StateObject private var monitor = SoundLevelMonitor()
    
    func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("Microphone access granted")
            } else {
                print("Microphone access denied")
            }
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Sound Level Monitor")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                    .padding()
                
                Text("\(String(format: "%.2f", monitor.decibels)) dB")
                    .font(.system(size: 50, weight: .heavy, design: .monospaced))
                    .foregroundColor(monitor.decibels > 70 ? .red : .green)
                    .shadow(radius: 5)
                    .scaleEffect(1.2)
                    .animation(.spring(), value: monitor.decibels)
                    
                Spacer()
                
                Button(action: requestMicrophonePermission) {
                    Text("Request Permission")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }
                .padding(.horizontal)
                
                HStack {
                    Button(action: monitor.startMonitoring) {
                        Text("Start Monitoring")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                    
                    Button(action: monitor.stopMonitoring) {
                        Text("Stop Monitoring")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
