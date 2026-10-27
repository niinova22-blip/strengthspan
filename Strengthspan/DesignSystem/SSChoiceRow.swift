import SwiftUI

/// Large, full-width selectable row for single- and multi-choice questions.
struct SSChoiceRow: View {
    private let title: Text
    private let isSelected: Bool
    private let allowsMultiple: Bool
    private let action: () -> Void

    init(_ titleKey: LocalizedStringKey, isSelected: Bool, allowsMultiple: Bool = false, action: @escaping () -> Void) {
        self.init(title: Text(titleKey), isSelected: isSelected, allowsMultiple: allowsMultiple, action: action)
    }

    init(verbatim title: String, isSelected: Bool, allowsMultiple: Bool = false, action: @escaping () -> Void) {
        self.init(title: Text(verbatim: title), isSelected: isSelected, allowsMultiple: allowsMultiple, action: action)
    }

    private init(title: Text, isSelected: Bool, allowsMultiple: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.allowsMultiple = allowsMultiple
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: SSSpacing.m) {
                title
                    .font(SSFont.body)
                    .foregroundStyle(SSColor.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: indicator)
                    .font(.title3)
                    .foregroundStyle(isSelected ? SSColor.accent : SSColor.separator)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, SSSpacing.l)
            .padding(.vertical, SSSpacing.m)
            .frame(minHeight: SSLayout.minTouchTarget + 4)
            .background(isSelected ? SSColor.accentSoft : SSColor.surface, in: RoundedRectangle(cornerRadius: SSRadius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SSRadius.button, style: .continuous)
                    .strokeBorder(isSelected ? SSColor.accent : SSColor.separator, lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var indicator: String {
        if allowsMultiple {
            return isSelected ? "checkmark.square.fill" : "square"
        }
        return isSelected ? "checkmark.circle.fill" : "circle"
    }
}
