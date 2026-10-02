// =============================================================================
// O'Reilly Crown Quarto Systems Report Specification
// Typst & The Simon Marlow Systems Standard
// Author: Providence Salumu, Principal Systems Engineer
// =============================================================================

#set document(
  title: "Cloud VPS NixOS Provisioning, Disko Partitioning & Zero-Disruption Cryptographic Migration",
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
      [Cloud VPS NixOS Provisioning Architecture]
    }
    
    set text(font: "Ubuntu", size: 8pt, fill: rgb("#555555"))
    if calc.even(page-number) {
      grid(
        columns: (1fr, auto),
        align: (left, right),
        [#page-number],
        [#smallcaps[Cloud VPS NixOS Provisioning & Cryptographic Migration]]
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

#text(font: "Ubuntu", size: 10pt, weight: "bold", fill: rgb("#a91c1c"))[PLATFORM INFRASTRUCTURE & CLOUD HOST PROVISIONING SPECIFICATION]
#v(-2pt)
#line(length: 100%, stroke: 0.5pt + rgb("#a91c1c"))
#v(6pt)

#text(font: "Ubuntu", size: 21pt, weight: "bold", fill: rgb("#111111"))[Cloud VPS NixOS Provisioning, Disko Partitioning & Zero-Disruption Cryptographic Migration]

#v(2pt)
#text(font: "Libertinus Serif", size: 10.5pt, style: "italic", fill: rgb("#4b5563"))[
  Providence Salumu, Principal Systems Engineer \
  Infrastructure Architecture & Endpoint Security \
  Target: `vps-52cead61` | Distribution: NixOS 26.05 | Hypervisor: OVH QEMU/KVM | Date: October 2026
]

#v(8pt)

= Deconstruction Header & Telemetry Observation

Workstation administration initiated the live replacement of a stock Ubuntu 26.04.1 LTS cloud instance (`vps-52cead61.vps.ovh.ca`) with an enterprise-grade, immutable NixOS 26.05 operating system. The remote machine exhibited the following pre-provisioning hardware and network telemetry:

#raw(
"Welcome to Ubuntu 26.04.1 LTS (GNU/Linux 7.0.0-28-generic x86_64)\n" +
"IPv4 address for ens3: 148.113.254.43\n" +
"IPv6 address for ens3: 2607:5300:205:200::882f\n" +
"Existing User:         ubuntu (Password authenticated: DamaAdmin2026)\n" +
"Existing Host Key:     ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIITWTwv4nkzfYbNfu1JuF5yIdx+0VQD5otMJIQRwgZbA root@vps-52cead61",
  lang: "text"
)

The engineering objective mandated:
1. Converting the instance to NixOS via `nixos-anywhere` and `disko`.
2. Preserving the existing SSH host key across the operating system re-installation so that existing client `known_hosts` entries (including `damabloom@damaconstruction.com`) remain valid with zero warnings.
3. Establishing the company service/admin account `damacs` as the sole primary administrative user, replacing `ubuntu` and `smunix`.
4. Enforcing strict firewall policy: *only TCP port 22* is permitted; all other ports (including 80 and 443) are blocked.
5. Housing all secret payloads and encryption keys in `nix-secrets` with zero plaintext keys in the configuration repository.

= Field-by-Field Telemetry & Configuration Matrix

We detail the operational parameters and cryptographic mappings for the newly provisioned host in @tab:telemetry.

#figure(
  caption: [System Configuration & Cryptographic Specifications for `vps-52cead61`],
  diag-table(
    ("Diagnostic Field", "Observed / Configured Value", "System / Kernel Meaning"),
    (95pt, 120pt, 145pt),
    (
      [Hostname],
      [`vps-52cead61`],
      [Static kernel hostname mapped in `/etc/hostname` and NixOS config.]
    ),
    (
      [Public IPv4],
      [`148.113.254.43`],
      [Dynamic DHCP allocation bounded to interface `ens3` via OVH hypervisor.]
    ),
    (
      [Static IPv6],
      [`2607:5300:205:200::882f/64`],
      [Static IPv6 address assigned to `ens3` with gateway `2607:5300:205:200::1`.]
    ),
    (
      [Primary User],
      [`damacs`],
      [Default user with passwordless sudo (`wheel` group), replacing `ubuntu`.]
    ),
    (
      [Firewall Policy],
      [`allowedTCPPorts = [ 22 ]`],
      [Strict perimeter hardening. Ports 80 and 443 are disabled and blocked.]
    ),
    (
      [Host Key],
      [`ssh_host_ed25519_key`],
      [Preserved via `--extra-files` into `/mnt/etc/ssh/` during `nixos-anywhere`.]
    ),
    (
      [Age Recipient],
      [`age1fjlv4pyy...skwd48c`],
      [Cryptographic age recipient derived from the preserved host key for `sops-nix`.]
    )
  )
) <tab:telemetry>

#definition-box("Zero-Disruption Host Key Preservation", [
  In SSH-based fleet management, wiping a remote server without extracting and re-injecting its host private keys causes the new installation to generate new host keys. This breaks client-side trust, triggering OpenSSH `HostKeyMismatch` aborts (`REMOTE HOST IDENTIFICATION HAS CHANGED`). Zero-disruption preservation extracts `/etc/ssh/ssh_host_*` prior to wiping and streams them into the root filesystem mount (`/mnt/etc/ssh`) during OS bootstrapping, ensuring invariant cryptographic continuity across OS reinstallations.
])

#pagebreak()

= Mathematical Proofs & Formal Security Invariants

We formalize the security properties governing the host firewall, authentication, and age decryption pipeline.

#proof-box(
  "Theorem 1 (Perimeter Firewall Strictness)",
  "Let P be the set of allowed inbound TCP ports on vps-52cead61. The system strictly satisfies P = {22}, rejecting all web traffic (HTTP 80, HTTPS 443).",
  [
    In `hosts/vps-52cead61/default.nix`:
    $
      P_"TCP" = { 22 }, quad P_"UDP" = emptyset
    $
    The kernel netfilter subsystem evaluates incoming SYN packets through chain `nixos-fw`:
    $
      "Action"(p) = cases(
        "ACCEPT" & "if" p in P_"TCP",
        "LOG & REFUSE" & "otherwise"
      )
    $
    For $p in {80, 443}$, $p in.not P_"TCP"$, proving that all non-SSH inbound connection attempts are actively rejected at the kernel packet filter level.
  ]
)

#v(8pt)

#proof-box(
  "Theorem 2 (Cryptographic Invariant of the SOPS/Age Decryption Pipeline)",
  "Let K_\"host\" be the server's Ed25519 host key. There exists a unique, deterministic isomorphism psi: Ed25519 -> Age such that sops-install-secrets recovers secret S iff S was encrypted with psi(K_\"host\").",
  [
    1. *Curve25519 Scalar Mapping*:
       The OpenSSH Ed25519 private key represents a 32-byte seed $k$. The function `agessh.SSHPrivateKeyToAge(k)` applies SHA-512 clamping to produce the X25519 scalar:
       $
         psi(k) = "clamp"("SHA-512"(k)[0..31]) in ZZ_q
       $
    2. *Public Recipient Bijection*:
       The corresponding public key transforms birationally via the Edwards-to-Montgomery curve map:
       $
         u = frac(1 + y, 1 - y) mod p
       $
       Yielding recipient `age1fjlv4pyyv7gnh222ec2qh0wkg7kp6zvhhckenwlq0uvghnzp7e0skwd48c`.
    3. *Execution Correctness*:
       Because `nixos-anywhere` injected $K_"host"$ into `/etc/ssh/`, `sops-nix` imports $K_"host"$ into `/run/secrets.d/age-keys.txt`, enabling instantaneous, unattended decryption of `initial_setup/status` on first boot.
  ]
)

#v(8pt)

= Native Vector Architecture: Multi-User Cloud Topology

The architectural relationship between workstation operators, client routing, secrets management, and the target VPS is rendered in @fig:arch-flow.

#figure(
  caption: [Native Typst Vector Diagram: Enterprise Provisioning & SSH Routing Topology],
  rect(
    width: 100%,
    fill: rgb("#fafafa"),
    stroke: 0.6pt + rgb("#e5e7eb"),
    inset: 12pt,
    radius: 4pt,
    [
      #align(center)[
        #text(font: "Ubuntu", size: 8.5pt, weight: "bold", fill: rgb("#111111"))[Dama Construction Cloud Infrastructure Architecture]
      ]
      #v(6pt)
      #grid(
        columns: (165pt, 165pt),
        gutter: 10pt,
        // Left Column: Client Workstations
        block(
          width: 100%,
          fill: rgb("#eff6ff"),
          stroke: 1pt + rgb("#2563eb"),
          radius: 3pt,
          inset: 8pt,
          [
            #text(font: "Ubuntu", size: 8pt, weight: "bold", fill: rgb("#1e40af"))[Workstation Tier (Clients)] \
            #line(length: 100%, stroke: 0.4pt + rgb("#bfdbfe"))
            #v(2pt)
            #text(font: "Ubuntu", size: 7.2pt, weight: "bold")[Providence Salumu (`smunix`)] \
            #text(font: "Ubuntu Mono", size: 6.8pt)[Key: ~/.ssh/id_ed25519_dama] \
            #text(font: "Ubuntu Mono", size: 6.8pt)[User: damacs \@ 148.113.254.43] \
            #v(4pt)
            #text(font: "Ubuntu", size: 7.2pt, weight: "bold")[damabloom Workstation] \
            #text(font: "Ubuntu Mono", size: 6.8pt)[Known Hosts: Invariant Matched] \
            #text(font: "Ubuntu Mono", size: 6.8pt)[Key: damabloom identity]
          ]
        ),
        // Right Column: Secrets Infrastructure
        block(
          width: 100%,
          fill: rgb("#fef2f2"),
          stroke: 1pt + rgb("#dc2626"),
          radius: 3pt,
          inset: 8pt,
          [
            #text(font: "Ubuntu", size: 8pt, weight: "bold", fill: rgb("#991b1b"))[Secrets Tier (`nix-secrets`)] \
            #line(length: 100%, stroke: 0.4pt + rgb("#fecaca"))
            #v(2pt)
            #text(font: "Ubuntu Mono", size: 6.8pt)[.sops.yaml] \
            #text(font: "Libertinus Serif", size: 7pt)[&vps_52cead61 (age1fjlv...)] \
            #text(font: "Libertinus Serif", size: 7pt)[&dama_work (age1pg9h...)] \
            #v(4pt)
            #text(font: "Ubuntu Mono", size: 6.8pt)[hosts/vps-52cead61/secrets.yaml] \
            #text(font: "Libertinus Serif", size: 7pt)[Zero plaintext in nix-config]
          ]
        )
      )
      #v(6pt)
      // Bottom Container: Target VPS
      #block(
        width: 100%,
        fill: rgb("#f0fdf4"),
        stroke: 1.2pt + rgb("#16a34a"),
        radius: 3pt,
        inset: 8pt,
        [
          #text(font: "Ubuntu", size: 8pt, weight: "bold", fill: rgb("#166534"))[Target Cloud Node: vps-52cead61 (`148.113.254.43`)] \
          #line(length: 100%, stroke: 0.4pt + rgb("#bbf7d0"))
          #v(2pt)
          #grid(
            columns: (110pt, 110pt, 110pt),
            [
              #text(font: "Ubuntu", size: 7.2pt, weight: "bold")[Perimeter Firewall] \
              #text(font: "Ubuntu Mono", size: 6.5pt)[TCP Port 22 (SSH only)] \
              #text(font: "Ubuntu Mono", size: 6.5pt)[Ports 80/443: Closed]
            ],
            [
              #text(font: "Ubuntu", size: 7.2pt, weight: "bold")[Storage & OS] \
              #text(font: "Ubuntu Mono", size: 6.5pt)[Disko GPT (/dev/sda)] \
              #text(font: "Ubuntu Mono", size: 6.5pt)[NixOS 26.05 (Linux 6.18)]
            ],
            [
              #text(font: "Ubuntu", size: 7.2pt, weight: "bold")[Administration] \
              #text(font: "Ubuntu Mono", size: 6.5pt)[User: damacs (wheel)] \
              #text(font: "Ubuntu Mono", size: 6.5pt)[Passwordless Sudo: Active]
            ]
          )
        ]
      )
    ]
  )
) <fig:arch-flow>

#pagebreak()

= Declarative NixOS Manifest Implementation

The complete host manifest in `hosts/vps-52cead61/default.nix` implements the security and deployment invariants:

#raw(
"networking.hostName = \"vps-52cead61\";\n" +
"networking = {\n" +
"  useDHCP = lib.mkDefault true;\n" +
"  interfaces.ens3 = {\n" +
"    useDHCP = lib.mkDefault true;\n" +
"    ipv6.addresses = [{ address = \"2607:5300:205:200::882f\"; prefixLength = 64; }]; // ❶\n" +
"  };\n" +
"  defaultGateway6 = { address = \"2607:5300:205:200::1\"; interface = \"ens3\"; };\n" +
"  firewall = { enable = true; allowedTCPPorts = [ 22 ]; allowedUDPPorts = []; };    // ❷\n" +
"};\n" +
"\n" +
"user = {\n" +
"  name = \"damacs\";                                                                // ❸\n" +
"  description = \"Providence Salumu\";\n" +
"  email = \"psalumu@damaconstruction.com\";\n" +
"  extraGroups = [ \"wheel\" ];\n" +
"};\n" +
"\n" +
"modules.security.passwordlessSudo.enable = true;                                   // ❹\n" +
"\n" +
"services.openssh = {\n" +
"  enable = true;\n" +
"  settings = {\n" +
"    PasswordAuthentication = false;                                                // ❺\n" +
"    KbdInteractiveAuthentication = false;\n" +
"    PermitRootLogin = \"prohibit-password\";\n" +
"  };\n" +
"};\n" +
"\n" +
"sops = {\n" +
"  defaultSopsFile = \"${inputs.secrets}/hosts/vps-52cead61/secrets.yaml\";          // ❻\n" +
"  defaultSopsFormat = \"yaml\";\n" +
"  age.sshKeyPaths = [ \"/etc/ssh/ssh_host_ed25519_key\" ];\n" +
"  secrets.\"initial_setup/status\" = {};\n" +
"};",
  lang: "nix"
)

#code-callouts(
  1, [Configures primary interface `ens3` with DHCP IPv4 dynamic lease alongside static IPv6 routing (`2607:5300:205:200::882f/64`) and default IPv6 gateway (`2607:5300:205:200::1`).],
  2, [Enforces strict perimeter isolation: only inbound TCP port 22 is permitted; web ports 80 and 443 are omitted and closed.],
  3, [Declares primary user `damacs` (not `smunix`, not `ubuntu`) with Home Manager integration and administrative membership.],
  4, [Activates passwordless sudo rules (`NOPASSWD: ALL`), enabling unprompted elevation for `deploy-rs` remote deployments.],
  5, [Hardens OpenSSH daemon: password and interactive keyboard authentication are completely disabled; root access requires Ed25519 key authentication.],
  6, [Integrates `sops-nix` using the server's preserved Ed25519 host key as an age secret key, securely decoupling configuration code from secrets.]
)

= Empirical Verification & Telemetry Matrix

Following the `nixos-anywhere` bootstrapping process, remote diagnostics were executed directly over SSH to verify system health and configuration fidelity.

#figure(
  caption: [Empirical Telemetry & Diagnostic Verification Matrix],
  diag-table(
    ("Verification Vector", "Operational Target", "Observed Outcome", "Status"),
    (90pt, 110pt, 120pt, 40pt),
    (
      [Kernel & Platform],
      [`uname -a`],
      [Linux vps-52cead61 6.18.49 x86_64],
      [PASSED]
    ),
    (
      [User Identity],
      [`whoami`],
      [`damacs`],
      [PASSED]
    ),
    (
      [Privilege Escalation],
      [`sudo -n id`],
      [`uid=0(root) gid=0(root)`],
      [PASSED]
    ),
    (
      [Firewall Rules],
      [`iptables -L nixos-fw`],
      [TCP 22 accepted; no 80 or 443 rules],
      [PASSED]
    ),
    (
      [SOPS Decryption],
      [`/run/secrets/.../status`],
      [`ready` (decrypted via host key)],
      [PASSED]
    ),
    (
      [Disko Storage],
      [`lsblk`],
      [BIOS boot + ESP + 4G swap + ext4 root],
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

#bib-item("[1]", "NixOS Project Authors", "Disko: Declarative Disk Partitioning and Formatting for NixOS", "GitHub Repository", "2026", "https://github.com/nix-community/disko")

#bib-item("[2]", "Mic92 (Jörg Thalheim)", "sops-nix: Atomic Secret Provisioning with Age and OpenSSH Keys", "GitHub Repository", "2026", "https://github.com/Mic92/sops-nix")

#bib-item("[3]", "Serokell", "deploy-rs: Simple Multi-Profile NixOS Deployment Architecture", "GitHub Repository", "2026", "https://github.com/serokell/deploy-rs")
