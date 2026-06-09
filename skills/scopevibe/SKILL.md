---
name: scopevibe
description: Design canvas integration — create and edit .pen files directly from your AI coding agent
---

# ScopeVibe Design Agent

ScopeVibe is a design canvas that works with `.pen` files. You have direct MCP access to the live canvas.

## 1. Check connection first

Before any design work, call `get_selection` (or any read tool). If it fails:
- **Stop immediately.** Do NOT retry in a loop.
- Tell the user: *"The ScopeVibe bridge is not running. Start it with: `npx @open-pencil/mcp-http` — then open a document in ScopeVibe."*

## 2. Standard workflow

```
get_selection / find_nodes    →  understand what's on canvas
render                        →  create UI from JSX
set_layout / set_fill / ...   →  refine properties
get_jsx                       →  verify the result
```

### Phase 1 — Orient
- `get_selection` — what's selected right now
- `find_nodes` — search by name, type, or text
- `get_jsx` — read a node as JSX to understand its structure
- `get_page_tree` — full page hierarchy (use sparingly; expensive)

### Phase 2 — Design
- `render` — **primary creation tool**; takes JSX string, inserts into parent node
- `batch_update` — update multiple nodes in one call (prefer over N separate updates)
- `update_node` — update a single node's properties

### Phase 3 — Refine
| Tool | Use for |
|---|---|
| `set_layout` | Flex/grid, direction, gap, padding, alignment |
| `set_fill` | Background color, gradients, image fills |
| `set_stroke` | Borders |
| `set_text` | Content of text nodes |
| `set_text_properties` | Font, size, weight, line-height |
| `set_radius` | Corner radius |
| `set_effects` | Shadows, blurs |
| `set_opacity` | Opacity |
| `set_constraints` | Responsive pinning |

### Phase 4 — Structure
| Tool | Use for |
|---|---|
| `reparent_node` | Move node to different parent |
| `delete_node` | Remove a node |
| `clone_node` | Duplicate |
| `group_nodes` | Wrap in a group |
| `node_resize` | Set explicit width/height |
| `rename_node` | Keep names semantic |

## Icons (REQUIRED workflow)

Never use placeholder rectangles/circles or emoji in place of icons.

```
1. List ALL icons you need upfront
2. Call fetch_icons({ names: ["lucide:settings", "lucide:bell", ...] })  ← one round-trip
3. Then insert_icon per placement — instant because cached
```

Default icon set: `lucide` — use prefix `lucide:<name>` (e.g. `lucide:settings`, `lucide:bell`, `lucide:search`, `lucide:user`, `lucide:x`, `lucide:plus`, `lucide:trash-2`, `lucide:chevron-right`, `lucide:menu`, `lucide:check`).

Other sets: `mdi`, `heroicons`, `tabler`, `solar`, `ri`.

## Components & instances

- `get_components` — list all components in the file
- `create_component` — turn a node into a reusable component
- `create_instance` — place an instance of a component
- `node_to_component` — convert existing node to component in-place

## Variables / tokens

- `list_collections` / `list_variables` — browse design tokens
- `find_variables` — search by name
- `get_variable` / `set_variable` — read/write a token value
- `create_variable` / `create_collection` — define new tokens
- `bind_variable` — bind a token to a node property

## Export

- `export_image` — export node as PNG/JPG (returns base64)
- `export_svg` — export as SVG
- `describe` — get a human-readable description of a node

## Pages

- `list_pages` / `switch_page` / `create_page`

## Rules

1. **Batch everything** — prefer `batch_update` over multiple single-node updates
2. **Icons always real** — `fetch_icons` first, then `insert_icon`, never emoji/shapes
3. **Never read `.pen` files with text tools** — they're binary; use MCP tools only
4. **Semantic names** — use `rename_node` to keep the layer tree readable
5. **Stop on connection failure** — tell the user, don't loop-retry
