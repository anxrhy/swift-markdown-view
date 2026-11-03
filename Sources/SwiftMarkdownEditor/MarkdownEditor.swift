
import SwiftUI
import SwiftMarkdownView
import SwiftMarkdownEditorCore
import SwiftMarkdownEditorRules
import SwiftMarkdownEditorTextKit

/// A SwiftUI Markdown editor with live syntax highlighting,
/// a formatting toolbar, and a rendered preview.
public struct MarkdownEditor: View {
    @Binding private var text: String

    private let inputRules: InputRuleProcessor
    private let livePreview: Bool
    private let toolbarItems: [MarkdownEditorToolbarItem]

    @StateObject private var ownedController = MarkdownEditorController()
    private let injectedController: MarkdownEditorController?

    @State private var ownedMode: MarkdownEditorMode
    private let injectedMode: Binding<MarkdownEditorMode>?

    @Environment(\.markdownEditorTheme) private var environmentTheme

    private var controller: MarkdownEditorController {
        injectedController ?? ownedController
    }

    private var mode: Binding<MarkdownEditorMode> {
        injectedMode ?? $ownedMode
    }

    private var theme: MarkdownEditorTheme {
        environmentTheme
    }

    private var availableModes: [MarkdownEditorMode] {
        #if os(macOS)
        [.edit, .split, .preview]
        #else
        [.edit, .preview]
        #endif
    }

    // MARK: - Initializers

    public init(
        text: Binding<String>,
        initialMode: MarkdownEditorMode = .edit,
        livePreview: Bool = false,
        inputRules: InputRuleProcessor = .standard,
        toolbar: [MarkdownEditorToolbarItem] = .standard,
        controller: MarkdownEditorController? = nil
    ) {
        self._text = text
        self._ownedMode = State(initialValue: initialMode)
        self.injectedMode = nil
        self.livePreview = livePreview
        self.inputRules = inputRules
        self.toolbarItems = toolbar
        self.injectedController = controller
    }

    public init(
        text: Binding<String>,
        mode: Binding<MarkdownEditorMode>,
        livePreview: Bool = false,
        inputRules: InputRuleProcessor = .standard,
        toolbar: [MarkdownEditorToolbarItem] = .standard,
        controller: MarkdownEditorController? = nil
    ) {
        self._text = text
        self._ownedMode = State(initialValue: mode.wrappedValue)
        self.injectedMode = mode
        self.livePreview = livePreview
        self.inputRules = inputRules
        self.toolbarItems = toolbar
        self.injectedController = controller
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .background(Color(theme.backgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            if mode.wrappedValue != .preview && !toolbarItems.isEmpty {
                MarkdownFormattingToolbar(
                    controller: controller,
                    items: toolbarItems
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch mode.wrappedValue {
        case .edit:
            editor

        case .preview:
            preview

        case .split:
            HStack(spacing: 0) {
                editor
                Divider()
                preview
            }
        }
    }

    // MARK: - Editor

    private var editor: some View {
        MarkdownSourceTextView(
            text: $text,
            theme: theme,
            inputRules: inputRules,
            livePreview: livePreview,
            onMakeTextView: {
                controller.bind($0)
            }
        )
    }

    // MARK: - Preview

    private var preview: some View {
        ScrollView {
            MarkdownView(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var text = """
        # Markdown Editor

        Type **bold**, *italic*, and `code`.

        - one
        - two

        > A quote.
        """

        @State private var mode: MarkdownEditorMode = .split

        var body: some View {
            MarkdownEditor(text: $text, mode: $mode)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Picker("Mode", selection: $mode) {
                            Text("Edit").tag(MarkdownEditorMode.edit)
                            Text("Split").tag(MarkdownEditorMode.split)
                            Text("Preview").tag(MarkdownEditorMode.preview)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }
        }
    }

    return PreviewHost()
}
