# Milestone 1 target rectangles

The browser numbers come from opening `showcase/reference.html` in Chrome and
printing `getBoundingClientRect()` for each `div` in the DevTools console.
The engine numbers come from `cd showcase && alr build && alr run` on `main`
(after flex-grow and the SPARK conversion fix, before stretch and alignment).

Milestone 1 is done when every row matches.

| Node | Box | Browser x, y, w, h | Engine x, y, w, h | Match? |
|---|---|---|---|---|
| 1 | root | 0, 0, 800, 600 | 0, 0, 800, 600 | yes |
| 2 | toolbar | 8, 8, 784, 40 | 8, 8, 0, 40 | no |
| 3 | button 1 | 8, 12, 80, 32 | 8, 8, 80, 32 | no |
| 4 | button 2 | 92, 12, 80, 32 | 92, 8, 80, 32 | no |
| 5 | button 3 | 176, 12, 80, 32 | 176, 8, 80, 32 | no |
| 6 | content | 8, 56, 784, 536 | 8, 56, 0, 536 | no |
| 7 | sidebar | 8, 56, 200, 536 | 8, 56, 200, 0 | no |
| 8 | main | 216, 56, 378.667, 536 | 216, 56, 0, 0 | no |
| 9 | panel | 602.667, 56, 189.333, 536 | 224, 56, 0, 0 | no |

Exact browser values for nodes 8 and 9: main w = 378.66668701171875,
panel x = 602.6666870117188, panel w = 189.3333282470703.

## Why each row does not match

- **Node 2 (toolbar), w 0 vs 784:** no `align-items: stretch` yet. The toolbar
  is a child of the root column, so its cross axis is its width, and it has
  no declared width to fall back on.
- **Nodes 3-5 (buttons), y 8 vs 12:** no `align-items: center` yet. The 32 px
  buttons sit at the top of the 40 px toolbar instead of 4 px down.
- **Node 6 (content), w 0 vs 784:** no stretch, same as the toolbar. Its
  height of 536 already matches, because flex-grow works.
- **Node 7 (sidebar), h 0 vs 536:** no stretch. It has a fixed width of 200
  but no height, so it should fill the row's height.
- **Node 8 (main), w 0 h 0 vs 378.667 x 536:** grow works, but content is
  0 wide (node 6), so there is no free space to share. Once content is 784
  wide, grow 2:1 gives main and panel their widths. Its height needs stretch.
- **Node 9 (panel), x 224 vs 602.667:** same cause as node 8. Main is 0 wide,
  so panel is packed right after it (216 + 0 + 8 gap = 224).

## Rounding

The browser rounds layout to 1/64 px; the engine uses 1/256 px steps. With
stretch and grow in place the engine gives main w = 378.668 and panel
x = 602.668, w = 189.332. Whether that counts as a match (for example,
equal when rounded to whole pixels) is a question for Olivier.
