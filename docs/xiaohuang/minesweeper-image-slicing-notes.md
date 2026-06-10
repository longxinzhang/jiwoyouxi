# 扫雷素材切图流程记录

## 来源

- 会话 ID：`019eaaf6-fa93-79d0-b40b-a76213da9cec`
- 会话文件：`/Users/xiaohuang/.codex/sessions/2026/06/09/rollout-2026-06-09T13-59-33-019eaaf6-fa93-79d0-b40b-a76213da9cec.jsonl`
- 素材目录：`entry/src/main/resources/rawfile/games/minesweeper/`

这个会话不能直接 `codex resume` 继续用时，可以直接读上面的 JSONL 记录查命令和输出。

## 结论

实际负责切图的不是 Photoshop、ImageMagick、Pillow 或 OpenCV，而是本机 shell 里的 `node`。

当时确认过：

- `magick` 不存在，所以没有用 ImageMagick。
- `PIL` / `Pillow` 不存在。
- `cv2` / OpenCV 不存在。
- `sips` 存在，但没有作为主切图工具。
- `ffmpeg` 存在，但没有参与切图。
- `mcp__node_repl.js` 曾用于检测边界，但写文件时报过权限问题，之后改为 shell 里的 `node <<'JS' ... JS` 执行同一套逻辑。

真正落图的方式是：

```sh
node <<'JS'
// 自包含 PNG 解析、抠背景、裁剪、写出 RGBA PNG
JS
```

脚本只依赖 Node 内置模块：

- `fs`：读写 PNG 文件。
- `zlib`：解压 PNG 的 `IDAT` 数据、重新压缩输出 PNG。

没有安装 npm 包，也没有用外部图片库。

## 辅助工具

会话里还用了这些辅助工具：

- `rg --files`：列出素材目录文件。
- `file`：确认源图尺寸、输出图是否为 `RGBA` PNG。
- `view_image`：目视检查源图布局和输出边缘。
- `git status --short`：确认新增了哪些资源，避免误动原图。
- 小段 Node 像素检查：确认透明区域的 alpha 是 `0`，不是把棋盘格背景烤进图里。

`imagegen` skill 只是被查看过说明，没有用来生成或切图。

## 核心处理方式

Node 脚本做了四件事：

1. 解析 PNG。
   - 读 `IHDR` 拿宽高、色彩类型。
   - 合并并 `zlib.inflateSync()` 解压所有 `IDAT`。
   - 反向处理 PNG filter：`None`、`Sub`、`Up`、`Average`、`Paeth`。
   - 统一转成 RGBA buffer。

2. 找背景和前景。
   - 浅色实底背景：从画布四边做 flood fill，只把连接到边缘的浅色背景判为透明。
   - 棋盘格背景：按中性灰/白棋盘格特征，把背景转成透明。
   - 羽毛这类半透明素材：按饱和度、亮度、暖色偏移计算 alpha，保留边缘半透明像素。

3. 裁剪。
   - 自动连通组件检测时，先得到每个组件的 `minX/minY/maxX/maxY`。
   - 对明确目标图标或羽毛，使用人工确认后的 box 坐标。
   - 裁剪后再按非透明像素 trim，并留 2 到 3 像素 padding。

4. 写回 PNG。
   - 手写 PNG encoder。
   - 输出固定为 8-bit `RGBA` PNG。
   - 原始素材图不改，只新增英文命名图片。

## 背景识别策略

### 浅色实底背景

按钮图、普通边框图、扫雷格子图主要用这个策略。

判断条件类似：

```js
const max = Math.max(r, g, b);
const min = Math.min(r, g, b);
const bright = (r + g + b) / 3;
const sat = max - min;

return bright >= 218 && sat <= 52 && r >= 218 && g >= 210 && b >= 198;
```

关键点是从画布边缘 flood fill。这样按钮内部的浅色木纹不会被误删，因为它们不和画布边缘背景连通。

### 棋盘格背景

v3 边框源图和羽毛源图是 RGB，棋盘格已经烤进图里。处理时没有直接按透明通道，因为源图没有透明通道。

v3 边框源图：按中性灰/白棋盘格背景抠掉，再切 8 个边框件。

羽毛源图：先尝试自动检测，发现棋盘格周期/颜色不完全匹配后，改为人工框定 10 根羽毛的位置，再用 `alphaForPixel()` 按颜色特征生成透明和半透明 alpha。

羽毛的判断核心：

```js
const max = Math.max(r, g, b);
const min = Math.min(r, g, b);
const sat = max - min;
const bright = (r + g + b) / 3;
const warm = (r - g) + (g - b) * 0.75;

if (sat <= 3 && bright >= 238) return 0;
if (sat <= 5 && bright >= 250) return 0;
if (sat <= 4 && bright >= 232 && warm < 3) return 0;

const featherStrength = Math.max(sat - 2, 246 - bright, warm * 0.9);
if (featherStrength <= 2) return 0;
if (featherStrength < 16) {
  return Math.max(36, Math.round((featherStrength - 2) / 14 * 180));
}
return 255;
```

## 会话里实际切出的资源

### 按钮素材

输入：按钮素材源图

输出：

- `panel_wood_long.png`：`1312x333`
- `button_blue_flower.png`：`414x192`
- `button_wood_small_left.png`：`406x176`
- `button_wood_small_right.png`：`410x175`
- `button_green.png`：`556x209`
- `button_yellow.png`：`554x209`

### 方格子扫雷区

输入：方格子扫雷区源图

输出：

- `board_grid_frame.png`：`845x831`
- `tile_hay_cover.png`：`213x228`
- `tile_open_plain.png`：`210x223`
- `tile_open_inset.png`：`210x225`
- `tile_flag.png`：`212x227`
- `tile_mine.png`：`212x239`
- `tile_cracked.png`：`211x226`
- 另外还有底部木框拼接件，后续 v3 边框出来后，最终目录里主要保留的是 `board_border_v3_*` 这批。

### 扫雷区域边框图

输入：扫雷区域边框源图

输出过 `board_border_*` 早期版本。

后面用户要求删掉 v2 并切 v3，所以最终更重要的是 v3。

### 棋子和重置图标

输入：棋子和重置图标源图

输出：

- `icon_flag_piece.png`：`186x200`
- `icon_reset.png`：`179x185`

### v3 边框

输入：v3 边框源图

输出：

- `board_border_v3_corner_top_left.png`：`248x187`
- `board_border_v3_edge_top.png`：`526x79`
- `board_border_v3_corner_top_right.png`：`247x185`
- `board_border_v3_edge_left.png`：`65x457`
- `board_border_v3_edge_right.png`：`64x457`
- `board_border_v3_corner_bottom_left.png`：`240x191`
- `board_border_v3_edge_bottom.png`：`531x77`
- `board_border_v3_corner_bottom_right.png`：`244x191`

会话里还检查过透明像素：角落 alpha 为 `0`，说明预览里的棋盘格不是图片背景。

### 羽毛

输入：羽毛源图

输出：

- `feather_01.png`：`174x208`
- `feather_02.png`：`247x315`
- `feather_03.png`：`145x304`
- `feather_04.png`：`188x225`
- `feather_05.png`：`169x315`
- `feather_06.png`：`223x300`
- `feather_07.png`：`145x211`
- `feather_08.png`：`234x271`
- `feather_09.png`：`281x159`
- `feather_10.png`：`189x259`

这些图都有透明和半透明像素，角落 alpha 检查为 `0`。

### 失败/成功弹窗

输入：失败弹窗源图和成功弹窗源图

输出：

- `popup_failure_card.png`：失败弹窗底图。
- `popup_success_card.png`：成功弹窗底图。

处理方式和其他 RGB 源图一致：先确认尺寸和背景特征，再按边缘背景或棋盘格背景生成透明区域，最后保留弹窗主体和必要阴影。

## 复用步骤

以后再切类似素材，按这个顺序走：

1. 找源图和尺寸。

```sh
rg --files entry/src/main/resources/rawfile/games/minesweeper
file entry/src/main/resources/rawfile/games/minesweeper/*.png
```

2. 目视确认布局。

用 `view_image` 看源图，判断是：

- 浅色实底背景。
- 棋盘格背景。
- 已经自带 alpha。
- 需要人工指定 box。

3. 写 Node 临时脚本。

脚本结构固定：

```js
const fs = require('fs');
const zlib = require('zlib');

// parsePng(): PNG -> { width, height, data: RGBA buffer }
// encodePng(): RGBA buffer -> PNG bytes
// background/flood/component/crop helpers

const dir = 'entry/src/main/resources/rawfile/games/minesweeper';
const img = parsePng(fs.readFileSync(`${dir}/源图.png`));

const assets = [
  ['output_name.png', { minX: 0, minY: 0, maxX: 100, maxY: 100 }],
];

for (const [name, box] of assets) {
  const crop = cropWithAlpha(img, box);
  fs.writeFileSync(`${dir}/${name}`, encodePng(crop.width, crop.height, crop.data));
}
```

4. 验证输出。

```sh
file entry/src/main/resources/rawfile/games/minesweeper/output_name.png
git status --short entry/src/main/resources/rawfile/games/minesweeper
```

期望输出是 `8-bit/color RGBA, non-interlaced`。

5. 抽样看图和测 alpha。

- 用 `view_image` 看边界是否完整。
- 用 Node 读 PNG，检查角落或外部透明区 alpha 是否为 `0`。

## 注意事项

- 原图不要覆盖，所有输出单独英文命名。
- 中文文件名只作为源素材名保留，输出资源名统一小写英文、数字、下划线。
- 自动检测不到时，不要硬调阈值太久；直接目视给 box，后续用 alpha 规则抠背景。
- 棋盘格出现在预览里不一定是背景没抠掉，要用 alpha 像素检查确认。
- `mcp__node_repl.js` 适合快速试算法，但在这个仓库里可能没有写权限；真正落文件用 shell 里的 `node`。
