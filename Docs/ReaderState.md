# 阅读器状态说明

## 各层负责什么

- `AppState`：打开、关闭阅读器，保存最后阅读的章节；不管理阅读页里的图片位置。
- `ReaderState`：当前图片、可滚动的图片列表、后台预取和工具栏。所有修改都在主线程执行。
- `ComicReader`：渲染图片，把可见图片变化传给 `ReaderState`；横竖阅读模式仍由 `@AppStorage` 保存。
- `ContentButton`：自己保存目录弹窗是否打开，选择章节时调用 `jumpToChapter`。

## 哪些状态需要保存

| 状态 | 含义 |
| --- | --- |
| `currentImage` | 当前读到的图片，是阅读位置的唯一来源；空章节时为 `nil`。 |
| `imageList` | 当前这轮阅读已经展开的图片，接近末尾时追加后续章节。它保存 URL 和序号，不保存图片位图。 |
| `startChapterIndex` | 此轮阅读从哪章开始；没有图片时用来显示所选章节。 |
| `readingID` | 手动跳章时更新，用于重建滚动视图、拒绝旧滚动回调。 |
| `imageSizes` | 按 URL 保存图片尺寸，可跨章节复用，变化会通知视图更新。 |
| `requestedImageURLs` | 已发起过预取的 URL 集合；不是“图片已加载成功”的标记。 |
| `showToolbar` / `hideTask` | 工具栏可见状态和自动隐藏计时任务。 |

这些状态只有 `ReaderState` 能修改。视图通过事件方法更新它们。

## 哪些状态不再单独保存

- 当前章节：`currentImage.chapterIndex`；没有图片时使用 `startChapterIndex`。
- 当前页码：`currentImage.indexInChapter + 1`。
- 下一章：从 `imageList` 最后一张图片的章节推导，跳过没有图片的章节。
- `imageIndex`、`nextChapterIndex`、与图片列表等长的 `imageLoaded` 数组已删除。
- `preloaded` 已删除。阅读器立即显示图片或占位图，后台预取不控制页面的显示与隐藏。

## 只看这几个事件

1. **进入阅读器**：初始化所选章节和第一张图片，`start()` 准备后续图片、显示工具栏。
2. **滚动**：`visibleImagesChanged` 找出最靠前的可见图片，更新 `currentImage`，再追加章节和预取。
3. **手动跳章**：`jumpToChapter` 替换图片列表，把 `currentImage` 指向第一张，更新 `readingID`。
4. **切换横竖模式**：视图用 `currentImage` 恢复位置，不改变章节和页码状态。
5. **退出**：`close()` 取消工具栏计时，通过 `onClose` 将当前章节交回 `AppState`。

## 为什么还有少量检查

检查集中在输入边界：初始化时处理失效的历史位置，选章时检查章节范围，滚动时拒绝旧 `readingID` 和空的可见列表，图片回调时拒绝无效尺寸。

内部不再反复检查图片索引：当前图片直接来自本轮列表，不通过一个独立、可失效的索引读取。图片预取只更新 URL 对应的尺寸，因此旧请求完成时也不需要比较阅读 ID。

后台图片请求仍由现有 `ApiClient` 执行；这次整理没有解决大图内存占用、预取限流和请求取消问题。

## 验证

在项目根目录运行 `sh Tests/run-reader-state-tests.sh`。测试编译实际的状态和模型，使用假的图片请求，覆盖跳章、旧滚动回调、短章节、空章节、图片回调和关闭行为。
