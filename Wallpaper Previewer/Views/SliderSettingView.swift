//
//  SliderSettingView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 05/10/2023.
//

import SwiftUI

struct SliderSettingView<V>: View  where V : BinaryFloatingPoint & CVarArg, V.Stride : BinaryFloatingPoint{
    
    let title: String
    let label: String
    var value: Binding<V>
    let range: ClosedRange<V>
    let step: V.Stride
    let onEditingChanged: (Bool) -> Void
    let valueDisplayFormat: String
    
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
            HStack {
                Slider(
                    value: value,
                    in: range,
                    step: step
                ) {
                    Text(label)
                } onEditingChanged: { isEditing in
                    onEditingChanged(isEditing)
                }
                Text(String(format: valueDisplayFormat, value.wrappedValue))
            }
        }
    }
}

#Preview {
    SliderSettingView<Double>(
        title: "Threshold",
        label: "Wall segmentation threshold",
        value: Binding.constant(0.44),
        range: 0...1,
        step: 0.01,
        onEditingChanged: { _ in},
        valueDisplayFormat: "%.2f"
    )
}
