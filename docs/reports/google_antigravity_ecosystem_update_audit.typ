// =============================================================================
// O'Reilly Crown Quarto Systems Report Specification
// Typst & The Simon Marlow Systems Standard
// Author: Providence Salumu, Principal Systems Engineer
// =============================================================================

#set document(
  title: "Google Antigravity Ecosystem Update Audit: CLI, IDE, and Hub Upstream Release Analysis",
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
      [Google Antigravity Update Audit]
    }
    
    set text(font: "Ubuntu", size: 8pt, fill: rgb("#555555"))
    if calc.even(page-number) {
      grid(
        columns: (1fr, auto),
        align: (left, right),
        [#page-number],
        [#smallcaps[Google Antigravity Ecosystem Update Audit]]
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

#text(font: "Ubuntu", size: 10pt, weight: "bold", fill: rgb("#a91c1c"))[ADVANCED AGENTIC SYSTEMS & DEVELOPMENT ENVIRONMENT AUDIT]
#v(-2pt)
#line(length: 100%, stroke: 0.5pt + rgb("#a91c1c"))
#v(6pt)

#text(font: "Ubuntu", size: 21pt, weight: "bold", fill: rgb("#111111"))[Google Antigravity Ecosystem Update Audit: CLI, IDE, and Hub Upstream Release Analysis]

#v(2pt)
#text(font: "Libertinus Serif", size: 10.5pt, style: "italic", fill: rgb("#4b5563"))[
  Providence Salumu, Principal Systems Engineer \
  Platform Architecture & Developer Tooling Infrastructure \
  Workspace: `nix-config` | Host: `smunix` | Date: October 2026
]

#v(8pt)

= Deconstruction Header & Telemetry Observation

Systems administration conducted a thorough architectural inspection and upstream release audit across the entire Google Antigravity developer suite, encompassing the standalone IDE, the terminal agent CLI, the multi-agent orchestration Hub, and the Python SDK.

#raw(
"Query: are there new updates for antigravity ide or ai or cli?\n" +
"Target Components:\n" +
"  1. Antigravity IDE:            pkgs/google-antigravity-ide.nix\n" +
"  2. Antigravity CLI (agy):      pkgs/google-antigravity-cli.nix\n" +
"  3. Antigravity Hub (2.0):      pkgs/google-antigravity.nix\n" +
"  4. Antigravity Python SDK:     google-antigravity on PyPI",
  lang: "text"
)

The investigation determined that:
1. *Google Antigravity IDE*: The repository pin (`2.5.5`) matches the latest upstream stable release distributed by Google. Zero newer releases have been published for the IDE.
2. *Google Antigravity CLI*: Multiple newer upstream releases exist. The repository is pinned to `1.2.11`, whereas the current upstream release is *`1.2.15`* (published October 2, 2026).
3. *Google Antigravity Hub (2.0)*: Two major upstream releases have shipped. The repository is pinned to `2.17.0`, whereas the current upstream release is *`2.19.1`* (published September 30, 2026).
4. *Live Environment Path Anomaly*: An imperative user-profile installation of `google-antigravity-cli` (`1.2.6`) in `~/.nix-profile/bin/agy` was discovered actively shadowing the declarative system derivation (`1.2.11`) located in `/etc/profiles/per-user/smunix/bin/agy`.

= Field-by-Field Component & Version Matrix

We present the current state across the live runtime, system profile, repository derivations, and upstream channels in @tab:version-matrix.

#figure(
  caption: [Comparative Version Audit Across System and Upstream Tiers],
  diag-table(
    ("Component", "Active Live", "System Profile", "Repo Pin", "Upstream Latest", "Delta"),
    (80pt, 50pt, 55pt, 50pt, 75pt, 50pt),
    (
      [Antigravity CLI],
      [`1.2.6` (stale)],
      [`1.2.11`],
      [`1.2.11`],
      [`1.2.15` (Oct 2026)],
      [+4 releases]
    ),
    (
      [Antigravity Hub],
      [`2.17.0`],
      [`2.17.0`],
      [`2.17.0`],
      [`2.19.1` (Sep 2026)],
      [+2 releases]
    ),
    (
      [Antigravity IDE],
      [`2.5.5`],
      [`2.5.5`],
      [`2.5.5`],
      [`2.5.5` (Current)],
      [Up to date]
    ),
    (
      [Python SDK],
      [N/A],
      [N/A],
      [`0.1.18` (docs)],
      [`0.1.20` (PyPI)],
      [+2 releases]
    )
  )
) <tab:version-matrix>

#definition-box("Binary Shadowing in Dual Profile Environments", [
  When a user imperatively executes `nix-env -i` or `nix profile install`, symlinks are generated in `~/.nix-profile/bin`. In standard interactive shell startup sequences, `~/.nix-profile/bin` precedes `/etc/profiles/per-user/$USER/bin` in the `$PATH` array. Consequently, even when NixOS declaratively rebuilds and upgrades a system package, the older imperatively installed binary takes precedence and shadows the updated system binary.
])

= Upstream Build Artifacts & Cryptographic Integrity

To enable immediate, zero-downtime declarative upgrades, the upstream release artifacts for both `1.2.15` and `2.19.1` were retrieved from Google Cloud Storage and verified against their cryptographic SHA-512 hashes in @tab:hashes.

#figure(
  caption: [Upstream Release Endpoints and Cryptographic SRI Checksums],
  diag-table(
    ("Target Package", "Version", "Architecture", "Upstream Storage Bucket URI", "SRI Hash (SHA-512)"),
    (65pt, 35pt, 55pt, 125pt, 80pt),
    (
      [`google-antigravity-cli`],
      [`1.2.15`],
      [`x86_64-linux`],
      [`.../1.2.15-5434575321694208/linux-x64/cli_linux_x64.tar.gz`],
      [#text(size: 6.5pt)[`sha512-bS4u7aDK1urI...`]]
    ),
    (
      [`google-antigravity-cli`],
      [`1.2.15`],
      [`aarch64-linux`],
      [`.../1.2.15-5434575321694208/linux-arm/cli_linux_arm64.tar.gz`],
      [#text(size: 6.5pt)[`sha512-GZ5kGf11Sfop...`]]
    ),
    (
      [`google-antigravity`],
      [`2.19.1`],
      [`x86_64-linux`],
      [`.../2.19.1-6046815158665216/linux-x64/Antigravity.tar.gz`],
      [#text(size: 6.5pt)[`sha512-LgMi1/gHJiaz...`]]
    ),
    (
      [`google-antigravity`],
      [`2.19.1`],
      [`aarch64-linux`],
      [`.../2.19.1-6046815158665216/linux-arm/Antigravity.tar.gz`],
      [#text(size: 6.5pt)[`sha512-F2OTkiZs6Npq...`]]
    )
  )
) <tab:hashes>

= Mechanistic Systems Analysis: Upstream Release Innovations

== Antigravity Hub 2.0: Evolution from 2.17.0 to 2.19.1

1. *Subagent Direct Messaging Protocol*: In version `2.17.0`, communication with a child agent required routing through the parent orchestrator via `send_message`. In `2.19.1`, the Hub conversation bus exposes subagent session endpoints directly to the UI input dispatcher, enabling interactive mid-flight guidance without polluting root trajectory context.
2. *Artifact Vector PDF Serialization*: Enhances the artifact preview pane with a native headless rendering engine that compiles Markdown, structured tables, and Mermaid/vector diagrams directly into high-fidelity PDF documents.
3. *Conversation-Only Non-Destructive Rollback*: Version `2.17.0` coupled turn reversion with filesystem reverts. Version `2.19.1` decouples LLM trajectory history from workspace disk modifications, allowing engineers to undo faulty reasoning branches while retaining working code edits.
4. *Sandboxing & Secret Protection*: Closed an operational gap where dotfiles (`.git`, `.env`, `.vscode`) could be accessed under passive review presets; `2.19.1` enforces mandatory explicit confirmation prompts for security-sensitive paths.

== Antigravity CLI: Evolution from 1.2.11 to 1.2.15

1. *Heap Allocation & Event Loop Latency Reduction*: Version `1.2.15` completely refactors the terminal rendering pipeline. Frame buffer allocations are cached across render ticks, eliminating memory thrashing and stutter during high-speed token streaming.
2. *Instant Quota & Credit Failure Propagation*: Supersedes a defect where exhausted Gemini API quotas triggered repeated $2.5$-minute exponential backoff retry loops; `1.2.15` validates quota headers and terminates failed turns instantly.
3. *Terminal Multiplexer Escape Sequence Sanitation*: Resolves terminal corruption in Ghostty, Kitty, WezTerm, and Zellij caused by malformed cursor-query escape sequences (`Ga=q,f=32...`).
4. *Global Configuration & Rule Access*: Hardens filesystem path resolution for custom rules and skills located in `~/.gemini/config/`, resolving symlink recursion bugs.

= Native Typst Vector Diagram: Antigravity Ecosystem Architecture

#figure(
  caption: [Google Antigravity Client Layering & NixOS Integration],
  block(
    fill: rgb("#fafafa"),
    inset: 12pt,
    radius: 4pt,
    stroke: 0.5pt + rgb("#e5e7eb"),
    width: 100%,
    [
      #align(center)[
        // Tier 1: Cloud
        #block(
          width: 250pt,
          fill: rgb("#18181b"),
          inset: (x: 10pt, y: 7pt),
          radius: 3pt,
          align(center, text(fill: white, font: "Ubuntu", size: 8.5pt, weight: "bold")[
            Google AI Backend & Agentic Runtime \
            #text(size: 7pt, fill: rgb("#9ca3af"), weight: "regular")[Gemini API | Cloud Run Auto-Updater | Vertex AI Gateway]
          ])
        )
        
        #v(4pt)
        #text(font: "Ubuntu", size: 7.5pt, fill: rgb("#a91c1c"), weight: "bold")[↓  gRPC / WebSockets / HTTPS Transport]
        #v(4pt)
        
        // Tier 2: Clients
        #grid(
          columns: (115pt, 115pt, 115pt),
          gutter: 6pt,
          block(
            fill: white,
            inset: 7pt,
            radius: 3pt,
            stroke: 1pt + rgb("#2563eb"),
            align(center, [
              #text(font: "Ubuntu", size: 8pt, weight: "bold", fill: rgb("#1e3a8a"))[Antigravity CLI] \
              #text(font: "Ubuntu Mono", size: 6.8pt)[agy (v1.2.15)] \
              #text(size: 6.5pt, fill: rgb("#4b5563"))[Terminal Agent]
            ])
          ),
          block(
            fill: white,
            inset: 7pt,
            radius: 3pt,
            stroke: 1pt + rgb("#7c3aed"),
            align(center, [
              #text(font: "Ubuntu", size: 8pt, weight: "bold", fill: rgb("#5b21b6"))[Antigravity Hub] \
              #text(font: "Ubuntu Mono", size: 6.8pt)[antigravity (v2.19.1)] \
              #text(size: 6.5pt, fill: rgb("#4b5563"))[Multi-Agent 2.0]
            ])
          ),
          block(
            fill: white,
            inset: 7pt,
            radius: 3pt,
            stroke: 1pt + rgb("#059669"),
            align(center, [
              #text(font: "Ubuntu", size: 8pt, weight: "bold", fill: rgb("#065f46"))[Antigravity IDE] \
              #text(font: "Ubuntu Mono", size: 6.8pt)[agy-ide (v2.5.5)] \
              #text(size: 6.5pt, fill: rgb("#4b5563"))[Standalone GUI]
            ])
          )
        )
        
        #v(4pt)
        #text(font: "Ubuntu", size: 7.5pt, fill: rgb("#a91c1c"), weight: "bold")[↓  NixOS Flake Derivations & System Overlays]
        #v(4pt)
        
        // Tier 3: Workstation Host
        #block(
          width: 350pt,
          fill: white,
          inset: (x: 10pt, y: 7pt),
          radius: 3pt,
          stroke: 1pt + rgb("#374151"),
          align(center, [
            #text(font: "Ubuntu", size: 8.5pt, weight: "bold", fill: rgb("#111111"))[Workstation Host (`smunix`) Integration] \
            #text(size: 7.5pt, fill: rgb("#4b5563"))[
              `modules.ai.clients` & `modules.ide.ides` -> `user.packages` -> Niri Workspace 4 (`programming`)
            ]
          ])
        )
      ]
    ]
  )
)

= Declarative Nix Packaging Specifications

Below are the exact declarative modifications required to update the repository packages to the latest upstream releases.

== Updated CLI Derivation: `pkgs/google-antigravity-cli.nix`

#raw(
"  availableSources = {\n" +
"    x86_64-linux = {\n" +
"      url = \"https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.15-5434575321694208/linux-x64/cli_linux_x64.tar.gz\"; # ❶\n" +
"      hash = \"sha512-bS4u7aDK1urI6LLfESV9aEIQ+NOEou4BHcatDtrPoz4eycVUWJ9v9u8Gl/TDx3e6RrboRjlxHxczd8wVVMZ0Ng==\";                     # ❷\n" +
"    };\n" +
"    aarch64-linux = {\n" +
"      url = \"https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.15-5434575321694208/linux-arm/cli_linux_arm64.tar.gz\"; # ❸\n" +
"      hash = \"sha512-GZ5kGf11Sfopb1HGA1yeAkb57NObZiTEb/mkFvcrC2V5mZxpLJSZ0hip+IdG1g7njQ9ZKzHI+ri+hbDUBTOZHQ==\";                     # ❹\n" +
"    };\n" +
"  };\n" +
"\n" +
"  # Bump version to 1.2.15\n" +
"  version = \"1.2.15\"; # ❺",
  lang: "nix"
)

#code-callouts(
  1, [Upstream build artifact URL for Linux x86_64 architecture.],
  2, [Cryptographic SHA-512 SRI hash verified against raw downloaded tarball.],
  3, [Upstream build artifact URL for Linux ARM64 architecture.],
  4, [Cryptographic SHA-512 SRI hash for ARM64 binary payload.],
  5, [Package version string aligned with internal build manifest.]
)

== Updated Hub Derivation: `pkgs/google-antigravity.nix`

#raw(
"  availableSources = {\n" +
"    x86_64-linux = {\n" +
"      url = \"https://storage.googleapis.com/antigravity-public/antigravity-hub/2.19.1-6046815158665216/linux-x64/Antigravity.tar.gz\";   # ❶\n" +
"      hash = \"sha512-LgMi1/gHJiazDwnwyQ6W45C6NSRlNzzXNuGks4WJ1v+EMe3p3qs4fzl/KJLYmf1T1/TOkXENr5uOI+dfgYLBDg==\";                       # ❷\n" +
"    };\n" +
"    aarch64-linux = {\n" +
"      url = \"https://storage.googleapis.com/antigravity-public/antigravity-hub/2.19.1-6046815158665216/linux-arm/Antigravity.tar.gz\";   # ❸\n" +
"      hash = \"sha512-F2OTkiZs6NpqKenwrr2VIrXDNaTCkswSB05hspWls687cfm4N4rOjQLK9XWd7+NrO30GDhPjGC5BOJlmfdsZeQ==\";                       # ❹\n" +
"    };\n" +
"  };\n" +
"\n" +
"  # Bump version to 2.19.1\n" +
"  version = \"2.19.1\"; # ❺",
  lang: "nix"
)

#code-callouts(
  1, [Google Cloud Storage public bucket URI for Antigravity 2.0 Hub (x86_64).],
  2, [Cryptographic SHA-512 SRI checksum for x86_64 Electron archive.],
  3, [Google Cloud Storage public bucket URI for Antigravity 2.0 Hub (ARM64).],
  4, [Cryptographic SHA-512 SRI checksum for ARM64 Electron archive.],
  5, [Updated package version string matching upstream changelog tag.]
)

= Actionable Remediation & Upgrade Procedure

1. *Eliminate Binary Shadowing in User Profile*:
   ```sh
   nix-env -e google-antigravity-cli
   ```
2. *Apply Declarative Version Bumps*:
   Update `pkgs/google-antigravity-cli.nix` to `1.2.15` and `pkgs/google-antigravity.nix` to `2.19.1` using the verified SRI hashes.
3. *Rebuild and Activate System Configuration*:
   ```sh
   sudo nixos-rebuild switch --flake .#smunix
   ```
4. *Verify Runtime Binaries*:
   ```sh
   agy --version        # Must output 1.2.15
   antigravity --version # Launches Hub 2.19.1
   agy-ide --version    # Retains 2.5.5
   ```

= Landmark References

#bib-item("[1]", "Google DeepMind", "Antigravity: Autonomous Multi-Agent Development Platform & IDE", "Google Antigravity Documentation Portal", "2026", "https://antigravity.google/docs")

#bib-item("[2]", "Google DeepMind", "Antigravity Release Notes & System Changelog", "Google Antigravity Engineering", "2026", "https://antigravity.google/docs/changelog")

#bib-item("[3]", "Simon Marlow", "Parallel and Concurrent Programming in Haskell: Techniques for Multicore and Multithreaded Programming", "O'Reilly Media", "2013", "https://www.oreilly.com/library/view/parallel-and-concurrent/9781449335939/")
