//
//  SnippetEditorView.swift
//  KeyClip
//

import SwiftUI
import SwiftData

struct SnippetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allSnippets: [Snippet]

    private let editingSnippet: Snippet?

    @State private var trigger: String
    @State private var category: String
    @State private var content: String
    @State private var showsDuplicateError = false

    init(editing snippet: Snippet? = nil) {
        self.editingSnippet = snippet
        _trigger = State(initialValue: snippet?.trigger ?? "")
        _category = State(initialValue: snippet?.category ?? "General")
        _content = State(initialValue: snippet?.content ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(editingSnippet == nil ? "New Snippet" : "Edit Snippet")
                .font(.headline)

            TextField("Trigger (e.g. ;email)", text: $trigger)
                .textFieldStyle(.roundedBorder)
            TextField("Category", text: $category)
                .textFieldStyle(.roundedBorder)

            Text("Expansion")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $content)
                .frame(minHeight: 120)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3)))

            if showsDuplicateError {
                Text("Another snippet already uses this trigger.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(trigger.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 360)
    }

    private func save() {
        let trimmedTrigger = trigger.trimmingCharacters(in: .whitespaces)
        let trimmedCategory = category.trimmingCharacters(in: .whitespaces)
        let isDuplicate = allSnippets.contains { $0.trigger == trimmedTrigger && $0.id != editingSnippet?.id }
        guard !isDuplicate else {
            showsDuplicateError = true
            return
        }

        if let editingSnippet {
            editingSnippet.trigger = trimmedTrigger
            editingSnippet.category = trimmedCategory.isEmpty ? "General" : trimmedCategory
            editingSnippet.content = content
        } else {
            let snippet = Snippet(trigger: trimmedTrigger, content: content, category: trimmedCategory.isEmpty ? "General" : trimmedCategory)
            modelContext.insert(snippet)
        }
        try? modelContext.save()
        SnippetExpansionEngine.shared.refreshTriggers()
        dismiss()
    }
}
