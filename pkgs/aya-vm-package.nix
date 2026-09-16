{
  flakePath,
  nixpkgs,
  pkgs,
  system,
}: let
  vm =
    (nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./aya-vm.nix
        {
          nixpkgs.pkgs = pkgs;
        }
      ];
    }).config.system.build.vm;

  runner = pkgs.writeShellScriptBin "ebpf-vm" ''
    set -euo pipefail

    usage() {
      printf '%s\n' \
        'Usage: ebpf-vm --shared-directory PATH [--ssh-public-key PATH] [-- QEMU_OPTIONS...]' \
        "" \
        'Starts the isolated Aya/eBPF NixOS VM and mounts PATH at /host.' \
        'The shared-directory parameter also accepts --shared-directory=PATH.' \
        'The SSH key parameter also accepts --ssh-public-key=PATH.' \
        'Without an explicit SSH key, standard public-key files under ~/.ssh are searched.' \
        'Use --no-ssh-key to retain password-only SSH access.'
    }

    shared_directory=""
    ssh_public_key_file="''${EBPF_VM_SSH_PUBLIC_KEY_FILE:-}"
    ssh_key_disabled=0
    qemu_args=()

    while (($# > 0)); do
      case "$1" in
        --shared-directory)
          if (($# < 2)); then
            printf '%s\n' 'ebpf-vm: --shared-directory requires a path' >&2
            usage >&2
            exit 2
          fi
          shared_directory="$2"
          shift 2
          ;;
        --shared-directory=*)
          shared_directory="''${1#*=}"
          shift
          ;;
        --ssh-public-key)
          if (($# < 2)); then
            printf '%s\n' 'ebpf-vm: --ssh-public-key requires a path' >&2
            usage >&2
            exit 2
          fi
          ssh_public_key_file="$2"
          shift 2
          ;;
        --ssh-public-key=*)
          ssh_public_key_file="''${1#*=}"
          shift
          ;;
        --no-ssh-key)
          ssh_key_disabled=1
          shift
          ;;
        --help|-h)
          usage
          exit 0
          ;;
        --)
          shift
          qemu_args+=("$@")
          break
          ;;
        *)
          printf 'ebpf-vm: unknown argument: %s\n' "$1" >&2
          usage >&2
          exit 2
          ;;
      esac
    done

    if [[ -z "$shared_directory" ]]; then
      printf '%s\n' 'ebpf-vm: --shared-directory PATH is required' >&2
      usage >&2
      exit 2
    fi

    if [[ ! -d "$shared_directory" ]]; then
      printf 'ebpf-vm: shared directory does not exist: %s\n' "$shared_directory" >&2
      exit 2
    fi

    export AYA_SHARED_DIRECTORY
    AYA_SHARED_DIRECTORY="$(${pkgs.coreutils}/bin/realpath -- "$shared_directory")"

    if ((ssh_key_disabled)); then
      unset AYA_SSH_PUBLIC_KEY
      printf '%s\n' 'ebpf-vm: SSH key injection disabled; use the dev password to connect.' >&2
    else
      if [[ -z "$ssh_public_key_file" && -n "''${HOME:-}" ]]; then
        for candidate in \
          "$HOME/.ssh/id_ed25519.pub" \
          "$HOME/.ssh/id_ed25519_sk.pub" \
          "$HOME/.ssh/id_ecdsa.pub" \
          "$HOME/.ssh/id_ecdsa_sk.pub" \
          "$HOME/.ssh/id_rsa.pub"; do
          if [[ -f "$candidate" ]]; then
            ssh_public_key_file="$candidate"
            break
          fi
        done
      fi

      if [[ -n "$ssh_public_key_file" ]]; then
        if [[ ! -f "$ssh_public_key_file" ]]; then
          printf 'ebpf-vm: SSH public key does not exist: %s\n' "$ssh_public_key_file" >&2
          exit 2
        fi

        ssh_key_lines=()
        while IFS= read -r line || [[ -n "$line" ]]; do
          line="''${line%$'\r'}"
          [[ "$line" =~ ^[[:space:]]*$ ]] || ssh_key_lines+=("$line")
        done < "$ssh_public_key_file"

        if ((''${#ssh_key_lines[@]} != 1)); then
          printf '%s\n' 'ebpf-vm: SSH public key file must contain exactly one nonempty key' >&2
          exit 2
        fi

        export AYA_SSH_PUBLIC_KEY="''${ssh_key_lines[0]}"
        case "''${AYA_SSH_PUBLIC_KEY%% *}" in
          ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|sk-ssh-ed25519@openssh.com|sk-ecdsa-sha2-nistp256@openssh.com) ;;
          *)
            printf '%s\n' 'ebpf-vm: the selected file is not a supported OpenSSH public key' >&2
            exit 2
            ;;
        esac

        if ! ${pkgs.openssh}/bin/ssh-keygen -l -f "$ssh_public_key_file" >/dev/null 2>&1; then
          printf 'ebpf-vm: invalid SSH public key: %s\n' "$ssh_public_key_file" >&2
          exit 2
        fi

        printf 'ebpf-vm: authorizing host public key %s for guest user dev\n' \
          "$(${pkgs.coreutils}/bin/realpath -- "$ssh_public_key_file")" >&2
      else
        unset AYA_SSH_PUBLIC_KEY
        printf '%s\n' \
          'ebpf-vm: no host SSH public key found; use dev/dev or pass --ssh-public-key PATH.' >&2
      fi
    fi

    vm_path="$(${pkgs.nix}/bin/nix \
      --extra-experimental-features 'nix-command flakes' \
      build \
      --impure \
      --no-link \
      --print-out-paths \
      "${flakePath}#aya-ebpf-vm")"

    exec "$vm_path/bin/run-aya-ebpf-lab-vm" "''${qemu_args[@]}"
  '';
in {
  inherit runner vm;
}
