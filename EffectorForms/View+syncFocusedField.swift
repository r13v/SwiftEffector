import Combine
import Effector
import SwiftUI

#if os(iOS)
public extension View {
    func syncFocusedField<Values: FormValues>(
        _ form: EffectorForm<Values>,
        _ focusState: FocusState<PartialKeyPath<Values>?>.Binding
    ) -> some View {
        @Use(form.focusedField)
        var store

        return self
            .onReceive(Just(focusState)) {
                form.focusField($0.wrappedValue)
            }
            .onChange(of: store) {
                focusState.wrappedValue = $0
            }
    }
}
#endif
