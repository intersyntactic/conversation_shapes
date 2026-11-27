# is_conversation_shapes

**Discontinued.** Use
[is_conversation_vocabulary](https://pub.dev/packages/is_conversation_vocabulary),
which holds this package's conversation types beside the reply types that
were `is_conversation_reply_vocabulary`.

Moving over:

- `UserSaid`, `SourceMessageId`, `Quote`, `QuotedAuthor` (`KnownAuthor`,
  `UnknownAuthor`) and `WhatChanged` (`Edited`, `Deleted`, `Restored`) keep
  their names and their JSON, byte for byte, `shape` field included.
  `UserSaid.shapeName` and `WhatChanged.shapeNames` are still there.
- `ReplyText` in `is_conversation_vocabulary` is a reply's checked text, not
  this package's trajectory node. The node, `ReplyChunk`, `UserSaidChanged`
  and `AgentName` are gone: nothing built them.

This last release changes no code, so a pinned app keeps working until it
moves.
