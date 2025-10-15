# VideoCull - Development TODO List
**Status:** File loading and playback complete ✅
**Current Phase:** Timeline interactivity and export workflow
---
## Priority 1: Timeline Interactivity & Selection Management
### Selection Manipulation
- [ ] **Draggable selection edges** - Allow users to drag IN/OUT points on timeline
  - [ ] Hit detection on selection boundaries (5-10px hot zone)
  - [ ] Visual feedback during drag (cursor change, highlight)
  - [ ] Constrain dragging to valid ranges (can't drag past other edge)
  - [ ] Update selection object in real-time during drag
- [ ] **Keyframe snapping** - Snap selections to I-frames for clean cuts
  - [ ] Implement snap-to-keyframe when dragging selection edges
  - [ ] Visual indicators for keyframe positions on timeline
  - [ ] Option to toggle snapping on/off (hold Shift to disable?)
  - [ ] Snap threshold setting in preferences
- [ ] **Multiple selection visualization** - Better display when selections overlap
  - [ ] Vertical stacking or layering of overlapping selections
  - [ ] Clear visual hierarchy (active vs inactive selections)
  - [ ] Smooth transitions when adding/removing selections
### Selection Context Menu
- [ ] Right-click menu on timeline selections
  - [ ] Delete selection
  - [ ] Change color (submenu with color options)
  - [ ] Split selection at current playhead position
  - [ ] Duplicate selection
  - [ ] Set as active selection
### Active Selection Enhancement
- [ ] Visual distinction between active and queued selections
  - [ ] Animated dashed border (currently static)
  - [ ] Pulse effect when selection is created
  - [ ] Clear "ghost" preview before OUT point is set
---
## Priority 2: Queue View Functionality
### Queue Management
- [ ] **Drag to reorder** - Rearrange export order
  - [ ] Implement drag-and-drop within queue list
  - [ ] Visual feedback during drag (row follows cursor)
  - [ ] Drop indicator line between rows
  - [ ] Update export order in model
- [ ] **Batch operations** - Multi-select in queue
  - [ ] Checkbox column for selection
  - [ ] Select all / deselect all buttons
  - [ ] Batch delete selected clips
  - [ ] Batch color change
  - [ ] Batch naming preset application
- [ ] **Preview thumbnails** - Visual reference in queue
  - [ ] Generate thumbnail at IN point for each clip
  - [ ] Cache thumbnails for performance
  - [ ] Click thumbnail to seek to that clip
  - [ ] Hover thumbnail to show duration overlay
### Queue Editing
- [ ] **Direct editing from queue**
  - [ ] Double-click IN/OUT/Duration to edit timecode
  - [ ] Inline editing of output filename
  - [ ] Jump to source video + selection on timeline
  - [ ] Validate edited timecodes
---
## Priority 3: Export Progress & Feedback
### Progress Implementation
- [ ] **Real FFmpeg progress parsing**
  - [ ] Parse FFmpeg stderr for progress updates
  - [ ] Extract current time / total duration
  - [ ] Calculate percentage complete
  - [ ] Display estimated time remaining
- [ ] **Overall queue progress**
  - [ ] Track completed vs total clips
  - [ ] Show overall percentage
  - [ ] Cumulative progress bar
  - [ ] Time elapsed / estimated total time
### Export Controls
- [ ] **Skip current clip button** - Wire up functionality
  - [ ] Terminate current FFmpeg process
  - [ ] Move to next clip in queue
  - [ ] Mark skipped clip (different color/icon)
  - [ ] Option to retry skipped clips
- [ ] **Pause/Resume export**
  - [ ] Pause after current clip completes
  - [ ] Resume from paused state
  - [ ] Visual indication of paused state
  - [ ] Preserve progress when paused
- [ ] **Stop all exports**
  - [ ] Clean termination of FFmpeg
  - [ ] Confirmation dialog
  - [ ] Report on completed vs remaining clips
  - [ ] Option to resume or clear queue
### Error Handling
- [ ] **Robust error recovery**
  - [ ] Specific error messages (disk full, codec issue, etc.)
  - [ ] Retry failed exports with options
  - [ ] Skip and continue vs stop all
  - [ ] Error log accessible from UI
  - [ ] Export report at completion
---
## Priority 4: Current Selection View Enhancement
### Core Functionality
- [ ] **"Add to Queue" button implementation**
  - [ ] Validate selection (OUT > IN, reasonable duration)
  - [ ] Add to queue with current naming preset
  - [ ] Clear active selection after adding
  - [ ] Visual feedback (animation, toast notification)
  - [ ] Auto-advance to next unmarked section (optional setting)
### Visual Feedback
- [ ] **Invalid selection indicators**
  - [ ] Red highlight when OUT is before or equal to IN
  - [ ] Disable "Add to Queue" button for invalid selections
  - [ ] Helpful error message tooltip
  - [ ] Visual cue on timeline (red overlay?)
- [ ] **Quick color picker**
  - [ ] Color swatch buttons next to "Add to Queue"
  - [ ] Set selection color before adding to queue
  - [ ] Remember last used color
  - [ ] Keyboard shortcuts for colors (1-5 keys?)
---
## Secondary Features (Polish & Workflow)
### Keyboard Shortcuts Enhancement
- [ ] **Additional shortcuts**
  - [ ] A - Add current selection to queue
  - [ ] Q - Quick color picker menu
  - [ ] Delete/Backspace - Remove selected clip from queue
  - [ ] Cmd+Shift+Delete - Clear entire queue
  - [ ] Arrow keys to navigate queue
### Timeline Improvements
- [ ] **Zoom controls**
  - [ ] Zoom in/out on timeline (Cmd +/- or pinch gesture)
  - [ ] Zoom to fit selected region
  - [ ] Zoom to fit all selections
  - [ ] Maintain playhead position during zoom
- [ ] **Timeline markers**
  - [ ] User-placed markers for reference
  - [ ] Marker labels/notes
  - [ ] Jump to marker shortcuts
  - [ ] Export markers to metadata
### Waveform Enhancements
- [ ] **Waveform color coding**
  - [ ] Different color for selections vs unselected regions
  - [ ] Peak indicators for loud sections
  - [ ] Zoom-dependent detail level
---
## Performance Optimizations
### Video Loading
- [ ] **Async metadata loading**
  - [ ] Background thread for FFprobe
  - [ ] Progress indicator during load
  - [ ] Batch loading for multiple files
  - [ ] Cache metadata between sessions
### Timeline Rendering
- [ ] **Efficient waveform generation**
  - [ ] Progressive loading (rough → detailed)
  - [ ] Memoization of waveform data
  - [ ] On-demand generation only when visible
  - [ ] Worker thread for audio analysis
### Queue Performance
- [ ] **Large queue handling**
  - [ ] Virtual scrolling for 100+ items
  - [ ] Lazy loading of thumbnails
  - [ ] Pagination if needed
---
## User Experience Polish
### Onboarding
- [ ] **First-run experience**
  - [ ] Welcome screen with quick tutorial
  - [ ] Interactive guide for first video import
  - [ ] Keyboard shortcut cheat sheet
  - [ ] Link to full documentation
### Tooltips & Help
- [ ] **Context-sensitive help**
  - [ ] Tooltips for all buttons and controls
  - [ ] Help icons with detailed explanations
  - [ ] In-app documentation viewer
  - [ ] Video tutorials linked from Help menu
### Preferences Expansion
- [ ] **Additional settings**
  - [ ] Default selection color
  - [ ] Auto-add to queue behavior
  - [ ] Export quality presets
  - [ ] Temporary file location
  - [ ] FFmpeg path customization
---
## Advanced Features (Future)
### Metadata & Organization
- [ ] **Clip metadata**
  - [ ] Notes/description per selection
  - [ ] Tags for organization
  - [ ] Search/filter by metadata
  - [ ] Export metadata to CSV
### Project Management
- [ ] **Save/Load sessions**
  - [ ] Save current queue and selections
  - [ ] Project file format (.penumbra?)
  - [ ] Recent projects list
  - [ ] Auto-save preferences
### Batch Processing
- [ ] **Multi-video operations**
  - [ ] Apply same selections across multiple videos
  - [ ] Batch color grading/filters (if adding processing)
  - [ ] Template system for repeated workflows
### Integration
- [ ] **External tools**
  - [ ] Send to Final Cut Pro / Premiere
  - [ ] Export EDL/XML for NLE import
  - [ ] Integration with cloud storage
---
## Bug Fixes & Known Issues
### Current Issues to Address
- [ ] Scrubbing performance with long videos
- [ ] Memory usage with multiple large files
- [ ] Timeline accuracy near video start/end
- [ ] Selection persistence when switching videos
- [ ] Timecode correction edge cases
---
## Testing & Quality Assurance
### Test Coverage
- [ ] Unit tests for core functionality
  - [ ] Selection validation logic
  - [ ] Timecode calculations
  - [ ] Naming preset system
  - [ ] FFmpeg command generation
- [ ] Integration tests
  - [ ] End-to-end export workflow
  - [ ] Multiple file handling
  - [ ] Queue operations
- [ ] Manual testing scenarios
  - [ ] Various video codecs/containers
  - [ ] Edge cases (very short/long clips)
  - [ ] Error conditions (disk full, corrupted files)
---
## Documentation
### User Documentation
- [ ] User manual/guide
- [ ] Video tutorials
- [ ] FAQ section
- [ ] Keyboard shortcuts reference card
### Developer Documentation
- [ ] Code architecture overview
- [ ] API documentation
- [ ] Contribution guidelines
- [ ] Build instructions
---
## Release Preparation
### Pre-Release Checklist
- [ ] Icon and app assets
- [ ] App signing and notarization
- [ ] Privacy policy / terms
- [ ] App Store metadata
- [ ] Beta testing program
- [ ] Crash reporting integration
---
**Next Immediate Action:** Implement timeline selection edge dragging with keyframe snapping - this is the most critical workflow improvement.
**Estimated Timeline:**
- Priority 1: 2-3 weeks
- Priority 2: 1-2 weeks
- Priority 3: 1 week
- Priority 4: 3-4 days
---
*Last Updated: [Current Date]*
*Project Phase: Core Functionality Complete, Interactive Features In Progress*