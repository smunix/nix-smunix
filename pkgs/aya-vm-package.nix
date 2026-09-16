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
        'Usage: ebpf-vm --shared-directory PATH [-- QEMU_OPTIONS...]' \
        "" \
        'Starts the isolated Aya/eBPF NixOS VM and mounts PATH at /host.' \
        'The parameter also accepts the form --shared-directory=PATH.'
    }

      shared_directory=""
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

      vm_path="$(${pkgs.nix}/bin/nix \
        --extra-experimental-features 'nix-command flakes' \
        build \
        --no-link \
        --print-out-paths \
        "${flakePath}#aya-ebpf-vm")"

      exec "$vm_path/bin/run-aya-ebpf-lab-vm" "''${qemu_args[@]}"
  '';
in {
  inherit runner vm;
}
