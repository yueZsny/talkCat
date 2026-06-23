# 像素猫猫精灵图画图指南

## 用 Aseprite 画

推荐使用 [Aseprite](https://aseprite.org/)（像素画行业标准，Steam 上 ¥70）。

### 新建文件

```
File → New
  Width:  128  (4 列 × 32px)
  Height: 192  (6 行 × 32px)
  Color Mode: RGBA
  Background: Transparent
```

### 布局模板

```
┌─────┬─────┬─────┬─────┐
│ 待机0 │ 待机1 │ 待机2 │ 待机3 │  ← 行0: idle (4帧循环)
├─────┼─────┼─────┼─────┤
│ 走路0 │ 走路1 │ 走路2 │ 走路3 │  ← 行1: walk (4帧循环)
├─────┼─────┼─────┼─────┤
│ 开心0 │ 开心1 │      │      │  ← 行2: happy (2帧)
├─────┼─────┼─────┼─────┤
│ 难过0 │ 难过1 │      │      │  ← 行3: sad (2帧)
├─────┼─────┼─────┼─────┤
│ 惊讶0 │      │      │      │  ← 行4: surprised (1帧)
├─────┼─────┼─────┼─────┤
│ 睡觉0 │ 睡觉1 │      │      │  ← 行5: sleep (2帧)
└─────┴─────┴─────┴─────┘
```

### 导出

```
File → Export Sprite Sheet
  Output: cat_sheet.png
  Sprite Size: 32×32 px
  ✅ Merge all frames
```

把 `cat_sheet.png` 放到 `flutter_app/assets/sprites/cat/` 目录下。

---

## 或者用 Piskel（免费在线版）

1. 打开 https://www.piskelapp.com/
2. New Sprite → 32×32 → Create
3. 画完帧后 → Export → PNG Sprite Sheet
4. 下载后将多个 Sheet 拼接成 4 列 6 行的大图

---

## 如果不想自己画

也可以从这些网站找免费的像素猫精灵图：

| 站点 | 地址 | 说明 |
|------|------|------|
| itch.io | https://itch.io/game-assets/free/tag-pixel-art | 大量免费像素素材 |
| OpenGameArt | https://opengameart.org/ | 开源游戏素材 |
| Kenney | https://kenney.nl/ | 高质量免费素材 |

找到后裁剪成 32×32 帧并排成 4 列 6 行即可。
