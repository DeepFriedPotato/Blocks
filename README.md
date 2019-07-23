# Blocks

Blocks is a document-based iOS app in which users add, remove and modify colorful blocks. It serves to demonstrate platform features such as ```UIDocument```. Requires iOS 13.

* Uses ```UIDocumentBrowserViewController```
  - Supports transition through ```UIDocumentBrowserTransitionController```
* Support for multiple windows (```UIScene```)
  - Opening the same document in multiple windows is supported. Any edits are reflected in all windows thanks to notification-based view updates.
  - Scene based state restoration
* Document format
  - Uses Swift Codable to encode data into JSON
  - Utilizes data compression introduced in iOS 13 (Foundation)
  - Supports automatic conflict resolution through a pseudo-CRDT document format.
  - Remote updates are reflected in an open document through diffing.
* Undo/redo support
* Thumbnail extension
