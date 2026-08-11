//
//  SnippetEditorView.swift
//  KeyClip
//

import SwiftUI
import SwiftData

/// A two-pane editor: existing snippets on the left (searchable, selectable)
/// and the edit form on the right, so switching between snippets to edit
/// doesn't require closing and reopening the sheet from the main list.
struct SnippetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Snippet.category), SortDescriptor(\Snippet.trigger)]) private var allSnippets: [Snippet]

    @State private var selectedSnippetID: UUID?
    @State private var trigger: String
    @State private var category: String
    @State private var content: String
    @State private var showsDuplicateError = false
    @State private var listSearchText = ""

    init(editing snippet: Snippet? = nil) {
        _selectedSnippetID = State(initialValue: snippet?.id)
        _trigger = State(initialValue: snippet?.trigger ?? "")
        _category = State(initialValue: snippet?.category ?? "General")
        _content = State(initialValue: snippet?.content ?? "")
    }

    private var selectedSnippet: Snippet? {
        guard let selectedSnippetID else { return nil }
        return allSnippets.first { $0.id == selectedSnippetID }
    }

    private var filteredSnippets: [Snippet] {
        guard !listSearchText.isEmpty else { return allSnippets }
        return allSnippets.filter {
            $0.trigger.localizedCaseInsensitiveContains(listSearchText) ||
            $0.category.localizedCaseInsensitiveContains(listSearchText)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            snippetList
            Divider()
            form
        }
        .frame(width: 560, height: 400)
    }

    private var snippetList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Snippets").font(.headline)
                Spacer()
                Button {
                    selectedSnippetID = nil
                    loadForm(from: nil)
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .help("New Snippet")
            }
            .padding(10)

            TextField("Search...", text: $listSearchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 10)
                .padding(.bottom, 6)

            List(filteredSnippets, selection: $selectedSnippetID) { snippet in
                VStack(alignment: .leading, spacing: 2) {
                    Text(snippet.trigger)
                        .font(.system(.body, design: .monospaced))
                    Text(snippet.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.sidebar)
        }
        .frame(width: 200)
        .onChange(of: selectedSnippetID) { _, newValue in
            loadForm(from: allSnippets.first { $0.id == newValue })
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedSnippet == nil ? "New Snippet" : "Edit Snippet")
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
                if selectedSnippet != nil {
                    Button("Delete", role: .destructive) { delete() }
                }
                Spacer()
                Button("Done") { dismiss() }
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(trigger.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func loadForm(from snippet: Snippet?) {
        trigger = snippet?.trigger ?? ""
        category = snippet?.category ?? "General"
        content = snippet?.content ?? ""
        showsDuplicateError = false
    }

    private func save() {
        let trimmedTrigger = trigger.trimmingCharacters(in: .whitespaces)
        let trimmedCategory = category.trimmingCharacters(in: .whitespaces)
        let isDuplicate = allSnippets.contains { $0.trigger == trimmedTrigger && $0.id != selectedSnippet?.id }
        guard !isDuplicate else {
            showsDuplicateError = true
            return
        }

        if let selectedSnippet {
            selectedSnippet.trigger = trimmedTrigger
            selectedSnippet.category = trimmedCategory.isEmpty ? "General" : trimmedCategory
            selectedSnippet.content = content
        } else {
            let snippet = Snippet(trigger: trimmedTrigger, content: content, category: trimmedCategory.isEmpty ? "General" : trimmedCategory)
            modelContext.insert(snippet)
            selectedSnippetID = snippet.id
        }
        try? modelContext.save()
        SnippetExpansionEngine.shared.refreshTriggers()
    }

    private func delete() {
        guard let selectedSnippet else { return }
        modelContext.delete(selectedSnippet)
        try? modelContext.save()
        SnippetExpansionEngine.shared.refreshTriggers()
        selectedSnippetID = nil
        loadForm(from: nil)
    }
}
