// =============================================================================
// O'Reilly Crown Quarto Systems Report Specification
// Typst & The Simon Marlow Systems Standard
// Author: Providence Salumu, Principal Systems Engineer
// =============================================================================

#set document(
  title: "Remote VPS Telemetry Infrastructure: Declarative Deployment of bottom and btop Across Cloud Nodes",
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
      [VPS Telemetry Deployment Specification]
    }
    
    set text(font: "Ubuntu", size: 8pt, fill: rgb("#555555"))
    if calc.even(page-number) {
      grid(
        columns: (1fr, auto),
        align: (left, right),
        [#page-number],
        [#smallcaps[Remote VPS Telemetry: bottom & btop Deployment]]
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

#text(font: "Ubuntu", size: 10pt, weight: "bold", fill: rgb("#a91c1c"))[INFRASTRUCTURE TELEMETRY & SYSTEM OBSERVABILITY SPECIFICATION]
#v(-2pt)
#line(length: 100%, stroke: 0.5pt + rgb("#a91c1c"))
#v(6pt)

#text(font: "Ubuntu", size: 21pt, weight: "bold", fill: rgb("#111111"))[Remote VPS Telemetry Infrastructure: Declarative Deployment of bottom and btop Across Cloud Nodes]

#v(2pt)
#text(font: "Libertinus Serif", size: 10.5pt, style: "italic", fill: rgb("#4b5563"))[
  Providence Salumu, Principal Systems Engineer \
  Platform Systems Architecture & Low-Latency Infrastructure \
  Nodes: `vps-73025e99`, `vps-52cead61` | Distribution: NixOS 26.05 | Date: October 2026
]

#v(8pt)

= Deconstruction Header & Telemetry Observation

Systems administration initiated the provisioning and declarative deployment of advanced interactive terminal monitoring utilities across both remote cloud VPS nodes in the infrastructure fleet. The operational mandate was initiated as follows:

#raw(
"User Request: install and deploy bottom, btop on both vps servers\n" +
"Target Node 1: vps-73025e99.vps.ovh.ca (148.113.244.62) | User: smunix | Auth: id_ed25519\n" +
"Target Node 2: vps-52cead61.vps.ovh.ca (148.113.254.43) | User: damacs | Auth: id_ed25519_dama\n" +
"Packages:      pkgs.bottom (binary: btm) & pkgs.btop (binary: btop)",
  lang: "text"
)

The engineering objective mandated:
1. Declaratively including `bottom` and `btop` within `environment.systemPackages` across both host manifests (`hosts/vps-73025e99/default.nix` and `hosts/vps-52cead61/default.nix`).
2. Preserving strict host isolation, distinct user identities (`smunix` vs. `damacs`), and differing network policies across both nodes.
3. Executing clean remote deployments and system activation via NixOS infrastructure pipelines.
4. Performing live verification of the compiled binaries (`btm 0.14.2` and `btop 1.4.7`) directly on the running remote kernels.

= Field-by-Field Telemetry & Configuration Matrix

We detail the fleet node architecture and target package attributes in @tab:telemetry.

#figure(
  caption: [Fleet Node Topology & Telemetry Monitoring Matrix],
  diag-table(
    ("Diagnostic Field", "Observed / Configured Value", "System / Kernel Meaning"),
    (95pt, 120pt, 145pt),
    (
      [Primary VPS Node],
      [`vps-73025e99`],
      [Production application node (`148.113.244.62`) hosting Caddy reverse proxy and Hodari Accounting.]
    ),
    (
      [Secondary VPS Node],
      [`vps-52cead61`],
      [Dedicated isolated cloud node (`148.113.254.43`) with strict port-22-only firewall and `damacs` user.]
    ),
    (
      [Telemetry Package 1],
      [`pkgs.bottom` (`btm 0.14.2`)],
      [Rust-based cross-platform graphical process and system monitor leveraging Ratatui and Heim/sysinfo.]
    ),
    (
      [Telemetry Package 2],
      [`pkgs.btop` (`btop 1.4.7`)],
      [High-performance C++20 resource monitor utilizing direct Linux `/proc` and `/sys` virtual filesystem parsers.]
    ),
    (
      [System Package Scope],
      [`environment.systemPackages`],
      [Immutable Nix store derivation symlinked into `/run/current-system/sw/bin/` on both hosts.]
    ),
    (
      [Activation Mechanism],
      [`nixos-rebuild switch`],
      [Atomic system profile generation, generation menu update, and live systemd reload without reboot.]
    )
  )
) <tab:telemetry>

#definition-box("Zero-Daemon Interactive Telemetry", [
  Unlike distributed telemetry stacks (such as Prometheus `node_exporter` or Datadog Agent) that continuously consume resident memory ($30$--$100 space "MB"$), background CPU cycles ($0.5$--$2 %$), and socket file descriptors, *Zero-Daemon Interactive Telemetry* utilities (`bottom`, `btop`, `htop`) incur strictly zero idle overhead. They are invoked on-demand over an interactive SSH pseudo-terminal (PTY), execute bounded kernel stat sampling, and terminate cleanly upon disconnect.
])

= Mechanistic Systems Analysis: bottom vs. btop

To understand the systems engineering tradeoffs between the two deployed monitoring engines, we examine their kernel sampling layers, threading models, and terminal rendering pipelines.

== Architecture of bottom (btm)

`bottom` is implemented in pure Rust, designed around an asynchronous polling model driven by Tokio and the `ratatui` terminal user interface framework:

1. *Sampling Subsystem*: Reads system telemetry via asynchronous worker tasks using `sysinfo` and OS-specific syscall wrappers (`statfs`, `sysinfo`, `sysctl`). Telemetry samples are buffered into bounded ring-buffers (`VecDeque<T>`) representing historical time-series windows (CPU usage per core, memory allocation breakdown, disk I/O throughput, and network interface packet counters).
2. *Event & Rendering Loop*: Terminal rendering is decoupled from metric polling. A high-priority event loop listens on standard input for raw ANSI key events, while a periodic render tick redraws the terminal layout using `ratatui` widgets. The diff engine updates only dirty terminal cells, minimizing SSH pseudo-terminal (PTY) bandwidth saturation over high-latency WAN connections.
3. *Process Tree & Signal Dispatch*: Process enumeration reads `/proc/[pid]/stat` and `/proc/[pid]/status`. The interface provides instant hierarchical process tree visualization, regex filtering, and signal dispatching (`SIGTERM`, `SIGKILL`, `SIGINT`) directly to target process groups.

== Architecture of btop (btop)

`btop` is written in modern C++20 with zero heavy runtime dependencies, optimized for extreme execution speed and minimal CPU overhead:

1. *Direct Kernel procfs/sysfs Parsing*: Bypasses intermediate abstraction libraries, reading directly from Linux `/proc/stat`, `/proc/meminfo`, `/proc/vmstat`, `/proc/net/dev`, and `/sys/class/thermal/`. File descriptors are retained or read via cached buffer pools (`pread`/`readv`), minimizing heap allocations in the tight sampling loop.
2. *Braille UTF-8 Sub-Pixel Graphing*: Rather than coarse block characters (`█`, `▌`), `btop` maps multi-point scalar telemetry into 8-dot Unicode Braille patterns (Unicode range `U+2800`--`U+28FF`). Each character cell provides a $2 times 4$ sub-pixel matrix, yielding four times the vertical resolution of standard ASCII or block graphs.
3. *Multi-Threaded Architecture*: Employs a dedicated data collector thread and a separate drawing thread synchronized via atomic condition variables and lock-free rings. The data collector computes differential CPU tick counters:
  $ Delta "CPU" = ("user"_t - "user"_(t-1)) + ("system"_t - "system"_(t-1)) + ("nice"_t - "nice"_(t-1)) $
  $ "Utilization" = (Delta "CPU") / (Delta "CPU" + ("idle"_t - "idle"_(t-1)) + ("iowait"_t - "iowait"_(t-1))) $
  This guarantees sub-millisecond calculation latency with accurate accounting for CPU frequency scaling and thermal throttling.

= Native Typst Vector Diagram: Telemetry Flow & Kernel Interfaces

#figure(
  caption: [Vertical Telemetry Pipeline: Linux Kernel to SSH Terminal],
  block(
    fill: rgb("#fafafa"),
    inset: 12pt,
    radius: 4pt,
    stroke: 0.5pt + rgb("#e5e7eb"),
    width: 100%,
    [
      #align(center)[
        // Stage 1: Kernel
        #block(
          width: 220pt,
          fill: rgb("#18181b"),
          inset: (x: 10pt, y: 7pt),
          radius: 3pt,
          align(center, text(fill: white, font: "Ubuntu", size: 8.5pt, weight: "bold")[
            Linux Kernel Virtual Filesystems \
            #text(size: 7pt, fill: rgb("#9ca3af"), weight: "regular")[/proc/stat | /proc/meminfo | /sys/class/thermal]
          ])
        )
        
        #v(4pt)
        #text(font: "Ubuntu", size: 7.5pt, fill: rgb("#a91c1c"), weight: "bold")[↓  Zero-Copy sys_read / procfs traversal]
        #v(4pt)
        
        // Stage 2: Userspace Sampling
        #block(
          width: 240pt,
          fill: rgb("#ffffff"),
          inset: (x: 10pt, y: 7pt),
          radius: 3pt,
          stroke: 1pt + rgb("#2563eb"),
          align(center, text(font: "Ubuntu", size: 8.5pt, weight: "bold", fill: rgb("#1e3a8a"))[
            Userspace Telemetry Engines \
            #text(size: 7.5pt, fill: rgb("#4b5563"), weight: "regular")[
              btm (Tokio Async Poller)  |  btop (C++20 Worker Thread)
            ]
          ])
        )
        
        #v(4pt)
        #text(font: "Ubuntu", size: 7.5pt, fill: rgb("#a91c1c"), weight: "bold")[↓  Unicode Braille Matrix & Ratatui Buffer Diff]
        #v(4pt)
        
        // Stage 3: PTY & Terminal
        #block(
          width: 220pt,
          fill: rgb("#ffffff"),
          inset: (x: 10pt, y: 7pt),
          radius: 3pt,
          stroke: 1pt + rgb("#059669"),
          align(center, text(font: "Ubuntu", size: 8.5pt, weight: "bold", fill: rgb("#065f46"))[
            Pseudo-Terminal Multiplexing (PTY) \
            #text(size: 7.5pt, fill: rgb("#4b5563"), weight: "regular")[
              sshd (port 22) -> Encrypted WAN Transport -> Local Client
            ]
          ])
        )
      ]
    ]
  )
)

= Declarative NixOS System Configuration

The declarative manifests for both hosts were updated to add `bottom` and `btop` alongside the foundational administration toolset (`curl`, `git`, `htop`, `tmux`, `vim`).

== Host Manifest: `hosts/vps-73025e99/default.nix`

#raw(
"  # Basic system packages for remote server administration\n" +
"  environment.systemPackages = with pkgs; [\n" +
"    bottom                          # ❶ Rust-based graphical monitor\n" +
"    btop                            # ❷ C++20 resource monitor\n" +
"    curl                            # ❸ HTTP/HTTPS diagnostic client\n" +
"    git                             # ❹ Version control engine\n" +
"    htop                            # ❺ Standard interactive top\n" +
"    tmux                            # ❻ Terminal multiplexer\n" +
"    vim                             # ❼ Modal text editor\n" +
"  ];",
  lang: "nix"
)

#code-callouts(
  1, [Declarative inclusion of `pkgs.bottom`, compiling binary `/run/current-system/sw/bin/btm`.],
  2, [Declarative inclusion of `pkgs.btop`, compiling binary `/run/current-system/sw/bin/btop`.],
  3, [Low-level transport diagnostic utility for auditing HTTP reverse proxies and web services.],
  4, [Standard Git distributed version control client supporting automated repository updates.],
  5, [Classical ncurses interactive process viewer for rapid process hierarchy inspection.],
  6, [Persistent terminal session multiplexer preventing disconnection during lengthy remote operations.]
)

== Host Manifest: `hosts/vps-52cead61/default.nix`

#raw(
"  # Basic system packages for remote server administration\n" +
"  environment.systemPackages = with pkgs; [\n" +
"    bottom                          # ❶ Declarative bottom monitor\n" +
"    btop                            # ❷ Declarative btop monitor\n" +
"    curl\n" +
"    git\n" +
"    htop\n" +
"    tmux\n" +
"    vim\n" +
"  ];",
  lang: "nix"
)

= Remote Verification & Live Telemetry Validation

Following deployment and configuration activation, both nodes were queried over their respective cryptographic SSH channels. The verification results confirm full operational availability.

#figure(
  caption: [Live Post-Deployment Verification Matrix Across Remote Nodes],
  diag-table(
    ("Host Node", "Command Executed", "Observed Standard Output", "Status"),
    (80pt, 120pt, 120pt, 40pt),
    (
      [`vps-73025e99`],
      [`btm --version`],
      [`bottom 0.14.2`],
      [PASS]
    ),
    (
      [`vps-73025e99`],
      [`btop --version`],
      [`btop version: 1.4.7 (g++ 15.2.0)`],
      [PASS]
    ),
    (
      [`vps-52cead61`],
      [`btm --version`],
      [`bottom 0.14.2`],
      [PASS]
    ),
    (
      [`vps-52cead61`],
      [`btop --version`],
      [`btop version: 1.4.7 (g++ 15.2.0)`],
      [PASS]
    )
  )
)

= Landmark References

#bib-item("[1]", "Clement Tsang", "bottom: Yet another cross-platform graphical process/system monitor", "GitHub Open Source Repository", "2024", "https://github.com/ClementTsang/bottom")

#bib-item("[2]", "Aristocratos (Jakob P. Liljenberg)", "btop: Resource monitor that shows usage and stats for processor, memory, disks, network and processes", "GitHub Open Source Repository", "2024", "https://github.com/aristocratos/btop")

#bib-item("[3]", "Simon Marlow", "Parallel and Concurrent Programming in Haskell: Techniques for Multicore and Multithreaded Programming", "O'Reilly Media", "2013", "https://www.oreilly.com/library/view/parallel-and-concurrent/9781449335939/")

#bib-item("[4]", "Eelco Dolstra", "The Purely Functional Software Deployment Model", "PhD Thesis, Utrecht University", "2006", "https://edolstra.github.io/pubs/phd-thesis.pdf")
