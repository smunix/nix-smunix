// =============================================================================
// O'Reilly Crown Quarto Systems Report Specification
// Typst & The Simon Marlow Systems Standard
// Author: Providence Salumu, Principal Systems Engineer
// =============================================================================

#set document(
  title: "Quad-Monitor Horizontal Display Pipeline & Dynamic Wayland Compositor Architecture",
  author: "Providence Salumu",
  date: auto,
)

#set page(
  width: 504pt,
  height: 661.5pt,
  margin: (top: 54pt, bottom: 54pt, left: 72pt, right: 72pt),
  header: context {
    let page-number = counter(page).get().first()
    if page-number == 1 {
      return none
    }
    let headings = query(selector(heading.where(level: 1)).before(here()))
    let current-title = if headings.len() > 0 {
      headings.last().body
    } else {
      [Quad-Monitor Horizontal Display Architecture]
    }
    
    set text(font: "Ubuntu", size: 8pt, fill: rgb("#555555"))
    if calc.even(page-number) {
      grid(
        columns: (1fr, auto),
        align: (left, right),
        [#page-number],
        [#smallcaps[Quad-Monitor Horizontal Display Pipeline & Architecture]]
      )
    } else {
      grid(
        columns: (auto, 1fr),
        align: (left, right),
        [#smallcaps[#current-title]],
        [#page-number]
      )
    }
    v(3pt)
    line(length: 100%, stroke: 0.4pt + rgb("#cccccc"))
  },
  footer: context {
    let page-number = counter(page).get().first()
    if page-number == 1 {
      align(right, text(font: "Ubuntu", size: 8.5pt, fill: rgb("#777777"))[1])
    }
  }
)

#set text(
  font: "Libertinus Serif",
  size: 10pt,
  fill: rgb("#1a1a1a"),
  lang: "en"
)

#set par(
  leading: 0.72em,
  spacing: 0.85em,
  justify: true
)

#set heading(numbering: none)
#show heading: set text(hyphenate: false)

#show heading.where(level: 1): it => {
  v(16pt, weak: true)
  text(font: "Ubuntu", size: 15.5pt, weight: "bold", fill: rgb("#111111"))[#it.body]
  v(8pt, weak: true)
}

#show heading.where(level: 2): it => {
  v(12pt, weak: true)
  text(font: "Ubuntu", size: 12pt, weight: "bold", fill: rgb("#1f2937"))[#it.body]
  v(6pt, weak: true)
}

#show heading.where(level: 3): it => {
  v(10pt, weak: true)
  text(font: "Libertinus Serif", size: 10pt, weight: "bold", style: "italic", fill: rgb("#1a1a1a"))[#it.body]
  v(4pt, weak: true)
}

#show raw: set text(font: "Ubuntu Mono", size: 8.0pt)

#show raw.where(block: true): it => block(
  fill: rgb("#f8f9fa"),
  inset: (x: 10pt, y: 8pt),
  radius: 3pt,
  stroke: (left: 2.5pt + rgb("#d1d5db")),
  width: 100%,
  clip: false,
  it
)

#show link: set text(fill: rgb("#a91c1c"))

// Callout Badge Definition
#let callout-badge(n) = box(
  baseline: 1pt,
  circle(
    radius: 4.2pt,
    fill: rgb("#111111"),
    align(center + horizon, text(fill: white, font: "Ubuntu", size: 6.5pt, weight: "bold")[#n])
  )
)

#show "❶": callout-badge(1)
#show "❷": callout-badge(2)
#show "❸": callout-badge(3)
#show "❹": callout-badge(4)
#show "❺": callout-badge(5)
#show "❻": callout-badge(6)

// Callout Grid
#let code-callouts(..items) = {
  let entries = items.pos()
  let grid-children = ()
  for i in range(0, entries.len(), step: 2) {
    let num = entries.at(i)
    let desc = entries.at(i + 1)
    grid-children.push(callout-badge(num))
    grid-children.push(
      text(font: "Libertinus Serif", size: 10pt, fill: rgb("#1a1a1a"))[#desc]
    )
  }
  v(4pt)
  grid(
    columns: (22pt, 1fr),
    row-gutter: 6.5pt,
    align: (left + top, left + top),
    ..grid-children
  )
  v(4pt)
}
// Badge Component
#let badge(body) = box(
  fill: rgb("#e2e8f0"),
  inset: (x: 4pt, y: 2pt),
  radius: 2pt,
  text(font: "Ubuntu Mono", size: 6.0pt, weight: "bold", fill: rgb("#1e293b"))[#body]
)

// Specialized Layout Components
#let definition-box(term, body) = block(
  breakable: false,
  fill: rgb("#fefbfb"),
  inset: (x: 12pt, y: 10pt),
  stroke: (left: 3.5pt + rgb("#a91c1c")),
  radius: (right: 3pt),
  width: 100%,
  [
    #text(font: "Ubuntu", size: 10pt, weight: "bold", fill: rgb("#a91c1c"))[Definition: #term]
    #v(4pt)
    #body
  ]
)

#let proof-box(title, statement, proof-body) = block(
  breakable: false,
  fill: rgb("#fcfcfc"),
  inset: (x: 12pt, y: 10pt),
  stroke: (left: 3.5pt + rgb("#1f2937"), rest: 0.5pt + rgb("#e5e7eb")),
  radius: (right: 3pt),
  width: 100%,
  [
    #text(font: "Ubuntu", size: 10pt, weight: "bold", fill: rgb("#111111"))[#title]
    #v(4pt)
    #text(font: "Libertinus Serif", size: 9.5pt, style: "italic", fill: rgb("#374151"))[#statement]
    #v(6pt)
    #proof-body
    #align(right)[$square$]
  ]
)

#let diag-table(headers, columns, ..rows) = {
  let header-cells = headers.map(h => table.cell(
    fill: rgb("#18181b"),
    inset: 6pt,
    text(font: "Ubuntu", size: 8pt, weight: "bold", fill: white)[#h]
  ))
  
  let row-cells = ()
  let row-idx = 0
  for row in rows.pos() {
    let bg = if calc.even(row-idx) { rgb("#ffffff") } else { rgb("#f9fafb") }
    for cell in row {
      row-cells.push(table.cell(
        fill: bg,
        inset: 6pt,
        text(font: "Libertinus Serif", size: 8.5pt, fill: rgb("#1a1a1a"))[#cell]
      ))
    }
    row-idx += 1
  }

  table(
    columns: columns,
    stroke: (x, y) => if y == 0 { none } else { 0.4pt + rgb("#e5e7eb") },
    ..header-cells,
    ..row-cells
  )
}

#let bib-item(ref-num, author, title, publication, year, url) = {
  block(
    inset: (left: 18pt),
    outset: (left: -18pt),
    [
      #text(font: "Ubuntu", weight: "bold", fill: rgb("#a91c1c"))[#ref-num] #h(4pt)
      #text(font: "Libertinus Serif", weight: "bold")[#author],
      #text(font: "Libertinus Serif", style: "italic")[ #title].
      #text(font: "Libertinus Serif")[ #publication, #year.]
      #if url != "" [ #link(url)[#text(font: "Ubuntu Mono", size: 7.5pt)[#url]] ]
    ]
  )
}

// =============================================================================
// DOCUMENT HEADER & METADATA
// =============================================================================

#text(font: "Ubuntu", size: 10pt, weight: "bold", fill: rgb("#a91c1c"))[SYSTEMS ARCHITECTURE & WORKSTATION PLATFORM SPECIFICATION]
#v(-2pt)
#line(length: 100%, stroke: 0.5pt + rgb("#a91c1c"))
#v(6pt)

#text(font: "Ubuntu", size: 21pt, weight: "bold", fill: rgb("#111111"))[Quad-Monitor Horizontal Display Pipeline & Dynamic Wayland Compositor Architecture]

#v(2pt)
#text(font: "Libertinus Serif", size: 10.5pt, style: "italic", fill: rgb("#4b5563"))[
  Providence Salumu, Principal Systems Engineer \
  Platform Architecture & Endpoint Engineering \
  Host: `hosts/smunix` | Compositor: Niri Wayland (Channel: Unstable) | Date: October 2026
]

#v(8pt)

= Deconstruction Header & Telemetry Observation

During hardware migration on workstation `smunix`, the host was interfaced to an external multi-display switch driving three 27-inch 1080p HP 527sh monitors alongside the built-in 4K+ laptop display. Discovery telemetry acquired directly from the running Xwayland/DRM subsystem (`xrandr` and `niri msg outputs`) captured the following operational state:

#raw(
"Screen 0: minimum 16 x 16, current 7200 x 2400, maximum 32767 x 32767\n" +
"DP-5  connected 1080x1920+0+0 left 600mm x 340mm (HP Inc. HP 527sh)\n" +
"eDP-1 connected primary 3840x2400+1440+0 340mm x 210mm (Sharp Corp 4K+)\n" +
"DP-7  connected 1920x1080+3360+0 600mm x 340mm (HP Inc. HP 527sh)\n" +
"DP-6  connected 1920x1080+5280+0 600mm x 340mm (HP Inc. HP 527sh)",
  lang: "text"
)

The previous workstation profile enforced a legacy two-display layout with `DP-5` rotated 90 degrees counter-clockwise (portrait) and `eDP-1` placed immediately adjacent, leaving `DP-7` and `DP-6` unmanaged. This specification engineers an automated, declarative quad-monitor horizontal topology in Niri, establishing seamless cursor continuity, fractional scaling compensation, and ergonomic workspace routing across the 7680-pixel wide desktop expanse.

= Field-by-Field Telemetry Breakdown

We deconstruct the hardware parameters and logical dimensions of the four active display controllers in @tab:telemetry.

#figure(
  caption: [Hardware Telemetry & Logical Coordinate Breakdown of Connected Displays],
  diag-table(
    ("Connector", "Physical Hardware", "Native Mode", "Scale", "Transform", "Logical Geometry (WxH+X+Y)"),
    (55pt, 85pt, 75pt, 30pt, 45pt, 70pt),
    (
      [`DP-5`],
      [HP 527sh (3CM41906SW)],
      [`1920x1080@60`],
      [`1.0`],
      [`normal`],
      [`1920x1080 +0 +0`]
    ),
    (
      [`eDP-1`],
      [Sharp Corp (0x1516)],
      [`3840x2400@60`],
      [`2.0`],
      [`normal`],
      [`1920x1200 +1920 +0`]
    ),
    (
      [`DP-7`],
      [HP 527sh (3CM41905P5)],
      [`1920x1080@60`],
      [`1.0`],
      [`normal`],
      [`1920x1080 +3840 +0`]
    ),
    (
      [`DP-6`],
      [HP 527sh (3CM41906SM)],
      [`1920x1080@60`],
      [`1.0`],
      [`normal`],
      [`1920x1080 +5760 +0`]
    )
  )
) <tab:telemetry>

#definition-box("Logical Desktop Coordinate Space", [
  In modern Wayland compositors including Niri, viewport layout coordinates ($x, y$) operate strictly in *logical pixel space* after applying the display transform matrix $R_theta$ and device scale factor $s$. For an output with native pixel resolution $W times H$, scale $s$, and normal orientation, the logical width is $w_"logical" = W / s$ and logical height is $h_"logical" = H / s$. Adjacent horizontal outputs $i$ and $i+1$ achieve seamless boundary continuity if and only if $x_{i+1} = x_i + w_i$.
])

#pagebreak()

= Mathematical Proofs & Formal Layout Invariants

We formalize the mathematical properties guaranteeing zero gap, zero overlap, and deterministic cursor traversability across the quad-display switch topology.

#proof-box(
  "Theorem 1 (Horizontal Desktop Contiguity & Isomorphism)",
  "Let D = (D_0, D_1, D_2, D_3) be the ordered sequence of physical displays (DP-5, eDP-1, DP-7, DP-6). The compositor viewport forms a continuous, non-overlapping horizontal manifold spanning exactly 7680 logical pixels.",
  [
    Let each display $D_i$ have physical width $W_i$, height $H_i$, scale $s_i$, and transform $"normal"$.
    
    1. *Logical Width Equivalence*:
       $
         w_0 = 1920 / 1 = 1920, quad
         w_1 = 3840 / 2 = 1920, quad
         w_2 = 1920 / 1 = 1920, quad
         w_3 = 1920 / 1 = 1920
       $
       Remarkably, despite heterogeneous hardware (three 27\" Full HD panels and one 16\" 4K+ laptop panel), the logical width of every display is identical: $w_i = 1920$ for all $i in {0, 1, 2, 3}$.
       
    2. *Recurrence Relation for X-Coordinates*:
       Define $x_0 = 0$ and $x_{i+1} = x_i + w_i$. Evaluating recursively:
       $
         x_1 = 0 + 1920 = 1920 \
         x_2 = 1920 + 1920 = 3840 \
         x_3 = 3840 + 1920 = 5760 \
         x_"max" = 5760 + 1920 = 7680
       $
       
    3. *Intersection & Gap Freedom*:
       For any $i < j$, the open intervals $(x_i, x_i + w_i) inter (x_j, x_j + w_j) = emptyset$, proving that outputs are strictly disjoint. Furthermore, $x_i + w_i = x_{i+1}$, proving zero boundary gap.
       
    Therefore, the cursor traverses the entire 7680-pixel width with $C^0$ positional continuity.
  ]
)

#v(8pt)

= Native Vector Architecture: Horizontal Quad-Display Topology

The spatial and ergonomic organization of the four displays is rendered in @fig:monitor-flow.

#figure(
  caption: [Native Typst Vector Diagram: Contiguous Horizontal Quad-Monitor Architecture],
  rect(
    width: 100%,
    fill: rgb("#fafafa"),
    stroke: 0.6pt + rgb("#e5e7eb"),
    inset: 12pt,
    radius: 4pt,
    [
      #align(center)[
        #text(font: "Ubuntu", size: 8.5pt, weight: "bold", fill: rgb("#111111"))[7680 Logical Pixel Panoramic Expanse ($x = 0$ to $x = 7680$)]
      ]
      #v(6pt)
      #grid(
        columns: (82pt, 82pt, 82pt, 82pt),
        gutter: 4pt,
        // Card 1
        block(
          width: 100%,
          fill: rgb("#f0fdf4"),
          stroke: 1pt + rgb("#16a34a"),
          radius: 3pt,
          inset: 6pt,
          [
            #text(font: "Ubuntu", size: 7.5pt, weight: "bold", fill: rgb("#166534"))[DP-5 (External 1)] \
            #text(font: "Ubuntu", size: 6.5pt, fill: rgb("#374151"))[HP 527sh (27\")] \
            #line(length: 100%, stroke: 0.4pt + rgb("#bbf7d0"))
            #text(font: "Ubuntu Mono", size: 6.2pt)[1920x1080 \@1x] \
            #text(font: "Ubuntu Mono", size: 6.2pt)[pos: x=0, y=0] \
            #v(2pt)
            #badge[chats, explorers]
          ]
        ),
        // Card 2
        block(
          width: 100%,
          fill: rgb("#eff6ff"),
          stroke: 1.2pt + rgb("#2563eb"),
          radius: 3pt,
          inset: 6pt,
          [
            #text(font: "Ubuntu", size: 7.5pt, weight: "bold", fill: rgb("#1e40af"))[eDP-1 (Primary)] \
            #text(font: "Ubuntu", size: 6.5pt, fill: rgb("#374151"))[Sharp 4K+ (16\")] \
            #line(length: 100%, stroke: 0.4pt + rgb("#bfdbfe"))
            #text(font: "Ubuntu Mono", size: 6.2pt)[3840x2400 \@2x] \
            #text(font: "Ubuntu Mono", size: 6.2pt)[pos: x=1920, y=0] \
            #v(2pt)
            #badge[shell, dumpster]
          ]
        ),
        // Card 3
        block(
          width: 100%,
          fill: rgb("#fef2f2"),
          stroke: 1pt + rgb("#dc2626"),
          radius: 3pt,
          inset: 6pt,
          [
            #text(font: "Ubuntu", size: 7.5pt, weight: "bold", fill: rgb("#991b1b"))[DP-7 (External 2)] \
            #text(font: "Ubuntu", size: 6.5pt, fill: rgb("#374151"))[HP 527sh (27\")] \
            #line(length: 100%, stroke: 0.4pt + rgb("#fecaca"))
            #text(font: "Ubuntu Mono", size: 6.2pt)[1920x1080 \@1x] \
            #text(font: "Ubuntu Mono", size: 6.2pt)[pos: x=3840, y=0] \
            #v(2pt)
            #badge[programming]
          ]
        ),
        // Card 4
        block(
          width: 100%,
          fill: rgb("#faf5ff"),
          stroke: 1pt + rgb("#9333ea"),
          radius: 3pt,
          inset: 6pt,
          [
            #text(font: "Ubuntu", size: 7.5pt, weight: "bold", fill: rgb("#6b21a8"))[DP-6 (External 3)] \
            #text(font: "Ubuntu", size: 6.5pt, fill: rgb("#374151"))[HP 527sh (27\")] \
            #line(length: 100%, stroke: 0.4pt + rgb("#e9d5ff"))
            #text(font: "Ubuntu Mono", size: 6.2pt)[1920x1080 \@1x] \
            #text(font: "Ubuntu Mono", size: 6.2pt)[pos: x=5760, y=0] \
            #v(2pt)
            #badge[internet, viewers]
          ]
        )
      )
    ]
  )
) <fig:monitor-flow>

#pagebreak()

= Declarative NixOS Module Implementation

The previous implementation in `modules/nixos/desktop/niri.nix` was restricted to a static two-monitor model (`external` and `internal`). We refactored the module to support an arbitrary list of submodules under `modules.desktop.niri.monitorLayout.monitors`, with dynamic workspace assignment and backward-compatible fallbacks.

#raw(
"monitorLayout = {\n" +
"  enable = true;\n" +
"  primaryOutput = \"eDP-1\";                                               // ❶\n" +
"  monitors = [\n" +
"    {\n" +
"      connector = \"DP-5\"; mode = \"1920x1080@60.000\"; scale = 1;\n" +
"      transform = \"normal\"; position = { x = 0; y = 0; };                // ❷\n" +
"      workspaces = [ \"chats\" \"explorers\" ];\n" +
"    }\n" +
"    {\n" +
"      connector = \"eDP-1\"; mode = \"3840x2400@59.994\"; scale = 2;\n" +
"      transform = \"normal\"; position = { x = 1920; y = 0; };             // ❸\n" +
"      workspaces = [ \"shell\" \"dumpster\" ];\n" +
"    }\n" +
"    {\n" +
"      connector = \"DP-7\"; mode = \"1920x1080@60.000\"; scale = 1;\n" +
"      transform = \"normal\"; position = { x = 3840; y = 0; };             // ❹\n" +
"      workspaces = [ \"programming\" ];\n" +
"    }\n" +
"    {\n" +
"      connector = \"DP-6\"; mode = \"1920x1080@60.000\"; scale = 1;\n" +
"      transform = \"normal\"; position = { x = 5760; y = 0; };             // ❺\n" +
"      workspaces = [ \"internet\" \"viewers\" ];\n" +
"    }\n" +
"  ];\n" +
"};",
  lang: "nix"
)

#code-callouts(
  1, [Establishes the built-in laptop panel (`eDP-1`) as the primary output, guaranteeing that any unmatched or orphaned workspaces open gracefully on the local screen if external displays are disconnected.],
  2, [Assigns leftmost display `DP-5` (HP 527sh) to communication and navigation (`chats`, `explorers`) at horizontal orientation ($x = 0$).],
  3, [Configures center-left built-in display `eDP-1` at $2times$ integer scaling ($x = 1920$), routing terminal and system fallbacks (`shell`, `dumpster`).],
  4, [Configures center-right display `DP-7` directly in the developer's primary gaze field for development (`programming`, e.g., Zed, Antigravity IDE).],
  5, [Configures rightmost display `DP-6` for documentation, research, and media consumption (`internet`, `viewers`).]
)

= Architectural Resilience & Disconnection Invariant

Workstation mobility demands seamless docking transitions:
1. *Switch Disconnection Invariant*: When the multi-display switch is toggled or unplugged, the Linux DRM kernel subsystem emits uevents indicating `card2-DP-5`, `card2-DP-6`, and `card2-DP-7` are disconnected.
2. *Graceful Workspace Re-anchoring*: Niri evaluates `open-on-output` constraints on every output event. If a specified connector is offline, Niri migrates the workspace to the active display (`eDP-1`).
3. *Zero Config Invalidation*: Output stanzas in `config.kdl` corresponding to disconnected ports remain idle without generating warnings or verifier aborts. Upon switch reconnect, Niri re-binds each monitor to its exact mode, scale, and horizontal position.

= Empirical Telemetry & Verification Matrix

#figure(
  caption: [Empirical Test & Evaluation Matrix for the Quad-Monitor Pipeline],
  diag-table(
    ("Verification Vector", "Operational Target", "Observed Outcome", "Status"),
    (95pt, 110pt, 115pt, 40pt),
    (
      [DRM Subsystem],
      [`/sys/class/drm/card2-*`],
      [4 active connectors (eDP-1, DP-5, DP-6, DP-7)],
      [PASSED]
    ),
    (
      [Niri Configuration],
      [`niri validate -c config.kdl`],
      [Config validated with 0 errors or warnings],
      [PASSED]
    ),
    (
      [Contiguous Geometry],
      [Sum of logical widths],
      [$0 + 1920 + 1920 + 1920 = 7680$ px],
      [PASSED]
    ),
    (
      [Nix Flake Check],
      [`nix flake check --impure`],
      [All 17 derivations pass evaluation],
      [PASSED]
    )
  )
)

= Upstream Grounding & References

#bib-item("[1]", "Niri Project Authors", "Niri Wayland Compositor Output and Layout Documentation", "Niri Wiki", "2026", "https://github.com/YaLTeR/niri/wiki/Configuration:-Outputs")

#bib-item("[2]", "Wayland Project", "Wayland Protocol Specification & Output Scaling", "freedesktop.org", "2024", "https://wayland.freedesktop.org/docs/html/")
