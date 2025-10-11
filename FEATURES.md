# Project Progress Tracker - Feature Roadmap

A combined and prioritized list of potential features for the Project Progress Tracker application.

---

### Tier 1: Critical Productivity Features

*These features are essential for a productive workflow and address the most common user needs.*

#### 1. Comprehensive Keyboard Shortcuts
**Goal:** Add extensive keyboard shortcuts to make the app faster and more efficient for power users.

**Implementation Details:**
- **File:** `Cmd+O` (Open), `Cmd+W` (Close Project)
- **Navigation:** `Cmd+[` (Prev Project), `Cmd+]` (Next Project), `Cmd+1-9` (Switch to Project)
- **View:** `Cmd+R` (Raw Markdown), `Cmd+Plus/Minus` (Zoom), `Cmd+0` (Reset Zoom)
- **Interaction:** `Cmd+F` (Focus Search), `Spacebar` (Toggle Checkbox on selected item)
- **Help:** `Cmd+?` to show a new window listing all shortcuts.

#### 2. Search and Filter
**Goal:** Allow users to quickly find specific tasks or content within large project files.

**Implementation Details:**
- Add a search bar to the main `ContentView`.
- Implement real-time, case-insensitive text filtering.
- Add filter toggles: "All", "Unchecked", "Checked".
- Highlight matching text in the results.
- Preserve search state when switching between projects.
- Create a `SearchManager` class to handle the logic.

#### 3. File Watching and Auto-Reload
**Goal:** Ensure the app stays in sync with the source Markdown file when it's edited externally.

**Implementation Details:**
- Use `DispatchSource` or `FileCoordinator` to monitor file changes.
- On change, show a notification banner with "Reload" and "Dismiss" options.
- Add a "Always reload" preference to bypass the prompt.
- Preserve checkbox states by matching item IDs during a reload.
- Handle file deletion gracefully.
- Create a `FileWatcherManager` to manage the monitoring.

---

### Tier 2: Major New Functionality

*These features introduce significant new capabilities to the app.*

#### 1. In-App Editing (Write-back to File)
**Goal:** Allow users to check/uncheck boxes in the app and have the changes saved directly to the source Markdown file.
- **Note:** This is a complex feature that would fundamentally change the app from a "viewer" to an "editor".

#### 2. Support for Due Dates
**Goal:** Parse, display, and highlight tasks with due dates.
- **Syntax:** `- [ ] My Task due:YYYY-MM-DD`
- **UI:** Display the due date next to the task, and change the color of tasks that are overdue or due soon.

---

### Tier 3: Quality of Life & UI Polish

*These features refine the user experience and add customization.*

- **Global Hotkey:** Implement a system-wide hotkey (e.g., `Cmd+Shift+P`) to instantly show/hide the menu bar panel.
- **Drag-and-Drop Project Reordering:** Allow users to manually reorder projects in the sidebar.
- **Settings/Preferences Window:** Create a dedicated window for app settings (e.g., auto-reload behavior, hotkeys, default zoom level).
- **Task Archiving:** Add a feature to automatically move completed tasks to an "## Archive" section at the bottom of the Markdown file.
- **Onboarding/Help:** Create a simple welcome screen or help guide for new users.

---

### Tier 4: Advanced Features

*Long-term ideas for expanding the app's scope.*

- **Statistics View:** A dedicated view to show charts and stats about project completion over time.
- **Export/Sharing:** Allow users to export the current project view as a PDF or share a progress report.
- **Better Error Recovery:** Implement more robust handling for malformed Markdown or corrupted progress files.
