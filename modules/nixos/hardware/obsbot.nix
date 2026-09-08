{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) escapeShellArgs mkEnableOption mkIf mkOption optionalString types;
  cfg = config.modules.hardware.obsbot;
  obsCfg = config.modules.programs.obs;
  videoDevice = "/dev/${cfg.video.deviceSymlink}";
  virtualCameraDevice = "/dev/video${toString obsCfg.virtualCamera.videoNr}";
  productMatch = optionalString (cfg.usb.productId != null) ", ATTRS{idProduct}==\"${cfg.usb.productId}\"";
  userServiceRequest = optionalString cfg.obs.autoStart '', TAG+="systemd", ENV{SYSTEMD_USER_WANTS}+="obsbot-tail2.service"'';
  pactl = "${pkgs.pulseaudio}/bin/pactl";

  findAudioSource = pkgs.writeScript "find-obsbot-audio-source" ''
    #!${pkgs.python3}/bin/python3
    import json
    import re
    import sys

    pattern = re.compile(sys.argv[1], re.IGNORECASE)
    try:
        sources = json.load(sys.stdin)
    except (json.JSONDecodeError, TypeError):
        sources = []

    for source in sources:
        name = str(source.get("name", ""))
        if name.endswith(".monitor") or name == sys.argv[2]:
            continue
        properties = source.get("properties") or {}
        searchable = " ".join(
            [name, str(source.get("description", ""))]
            + [f"{key}={value}" for key, value in properties.items()]
        )
        if pattern.search(searchable):
            print(name)
            break
  '';

  findRemapModules = pkgs.writeScript "find-obsbot-remap-modules" ''
    #!${pkgs.python3}/bin/python3
    import json
    import sys

    marker = f"source_name={sys.argv[1]}"
    try:
        modules = json.load(sys.stdin)
    except (json.JSONDecodeError, TypeError):
        modules = []

    for module in modules:
        arguments = " ".join(
            str(module.get(key, "")) for key in ("argument", "args", "properties")
        )
        index = module.get("index")
        if marker in arguments and index is not None:
            print(index)
  '';

  cleanupAudio = pkgs.writeShellScript "cleanup-obsbot-audio" ''
    set -u
    stateDir="''${XDG_RUNTIME_DIR:?}/obsbot-tail2"
    stateFile="$stateDir/audio-state"
    previousDefault=""
    moduleId=""

    if [[ -r "$stateFile" ]]; then
      IFS=$'\t' read -r moduleId previousDefault < "$stateFile" || true
    fi

    if [[ -n "$moduleId" ]]; then
      ${pactl} unload-module "$moduleId" >/dev/null 2>&1 || true
    fi

    if [[ -n "$previousDefault" && "$previousDefault" != ${lib.escapeShellArg cfg.audio.virtualSourceName} ]]; then
      ${pactl} set-default-source "$previousDefault" >/dev/null 2>&1 || true
    fi

    ${pkgs.coreutils}/bin/rm -f "$stateFile"
  '';

  prepareObsbot = pkgs.writeShellScript "prepare-obsbot-tail2" ''
    set -euo pipefail
    stateDir="''${XDG_RUNTIME_DIR:?}/obsbot-tail2"
    stateFile="$stateDir/audio-state"
    ${pkgs.coreutils}/bin/mkdir -p "$stateDir"
    ${pkgs.coreutils}/bin/chmod 700 "$stateDir"

    for _attempt in $(${pkgs.coreutils}/bin/seq 1 ${toString cfg.retry.deviceAttempts}); do
      if [[ -e ${lib.escapeShellArg videoDevice} && -e ${lib.escapeShellArg virtualCameraDevice} ]] \
        && ${pactl} info >/dev/null 2>&1; then
        break
      fi
      ${pkgs.coreutils}/bin/sleep ${toString cfg.retry.intervalSeconds}
    done

    if [[ ! -e ${lib.escapeShellArg videoDevice} ]]; then
      echo "The OBSBOT UVC device ${videoDevice} did not appear." >&2
      exit 1
    fi

    if [[ ! -e ${lib.escapeShellArg virtualCameraDevice} ]]; then
      echo "The OBS virtual camera ${virtualCameraDevice} did not appear." >&2
      exit 1
    fi

    if ! ${pactl} info >/dev/null 2>&1; then
      echo "PipeWire's PulseAudio service is unavailable." >&2
      exit 1
    fi

    if ${pkgs.procps}/bin/pgrep -x obs >/dev/null; then
      echo "OBS is already running; refusing to start a second unmanaged instance." >&2
      exit 1
    fi

    ${cleanupAudio}

    if ${lib.boolToString cfg.audio.enable}; then
      source=""
      for _attempt in $(${pkgs.coreutils}/bin/seq 1 ${toString cfg.retry.audioAttempts}); do
        source="$(${pactl} -f json list sources | ${findAudioSource} \
          ${lib.escapeShellArg cfg.audio.sourcePattern} \
          ${lib.escapeShellArg cfg.audio.virtualSourceName})"
        [[ -n "$source" ]] && break
        ${pkgs.coreutils}/bin/sleep ${toString cfg.retry.intervalSeconds}
      done

      if [[ -z "$source" ]]; then
        echo "No PipeWire source matched ${lib.escapeShellArg cfg.audio.sourcePattern}." >&2
        exit 1
      fi

      while IFS= read -r staleModule; do
        [[ -n "$staleModule" ]] && ${pactl} unload-module "$staleModule" >/dev/null 2>&1 || true
      done < <(${pactl} -f json list modules | ${findRemapModules} ${lib.escapeShellArg cfg.audio.virtualSourceName})

      previousDefault="$(${pactl} get-default-source 2>/dev/null || true)"
      [[ "$previousDefault" == ${lib.escapeShellArg cfg.audio.virtualSourceName} ]] && previousDefault=""

      moduleId="$(${pactl} load-module module-remap-source \
        "master=$source" \
        "source_name=${cfg.audio.virtualSourceName}" \
        "source_properties=device.description=${cfg.audio.virtualSourceDescription}" \
        "rate=${toString cfg.audio.sampleRate}" \
        "channels=${toString cfg.audio.channels}")"

      printf '%s\t%s\n' "$moduleId" "$previousDefault" > "$stateFile"
      ${pkgs.coreutils}/bin/chmod 600 "$stateFile"

      for _attempt in $(${pkgs.coreutils}/bin/seq 1 ${toString cfg.retry.audioAttempts}); do
        ${pactl} list short sources | ${pkgs.gnugrep}/bin/grep -Fq $'\t${cfg.audio.virtualSourceName}\t' && break
        ${pkgs.coreutils}/bin/sleep ${toString cfg.retry.intervalSeconds}
      done

      if ! ${pactl} list short sources | ${pkgs.gnugrep}/bin/grep -Fq $'\t${cfg.audio.virtualSourceName}\t'; then
        echo "The virtual microphone ${cfg.audio.virtualSourceName} did not become ready." >&2
        exit 1
      fi

      ${optionalString cfg.audio.setDefault ''
      ${pactl} set-default-source ${lib.escapeShellArg cfg.audio.virtualSourceName}
    ''}
    fi
  '';

  obsCommand = escapeShellArgs [
    "${config.programs.obs-studio.finalPackage}/bin/obs"
    "--startvirtualcam"
    "--minimize-to-tray"
    "--disable-missing-files-check"
    "--collection"
    cfg.obs.collection
    "--profile"
    cfg.obs.profile
    "--scene"
    cfg.obs.scene
  ];

  runObsbot = pkgs.writeShellScript "run-obsbot-tail2" ''
    set -u

    ${optionalString cfg.notify ''
      ${pkgs.libnotify}/bin/notify-send \
        --app-name="OBSBOT" \
        --icon="camera-video" \
        "OBSBOT Tail 2 connected" \
        "Starting OBS with DJI Mic 3 routing and ${virtualCameraDevice}." || true
    ''}

    ${obsCommand} &
    obsPid=$!

    ready=false
    for _attempt in $(${pkgs.coreutils}/bin/seq 1 ${toString cfg.retry.virtualCameraAttempts}); do
      if ! ${pkgs.coreutils}/bin/kill -0 "$obsPid" 2>/dev/null; then
        wait "$obsPid" 2>/dev/null || true
        echo "OBS exited before ${virtualCameraDevice} became capture-capable." >&2
        exit 1
      fi

      if ${pkgs.v4l-utils}/bin/v4l2-ctl --device=${lib.escapeShellArg virtualCameraDevice} --all 2>/dev/null \
        | ${pkgs.gnugrep}/bin/grep -Eq 'Video Capture|Video Capture Multiplanar'; then
        ready=true
        break
      fi

      ${pkgs.coreutils}/bin/sleep ${toString cfg.retry.intervalSeconds}
    done

    if [[ "$ready" != true ]]; then
      echo "OBS did not activate capture capability on ${virtualCameraDevice}." >&2
      ${pkgs.coreutils}/bin/kill -TERM "$obsPid" 2>/dev/null || true
      wait "$obsPid" 2>/dev/null || true
      ${optionalString cfg.notify ''
      ${pkgs.libnotify}/bin/notify-send \
        --urgency=critical \
        --app-name="OBSBOT" \
        "OBS virtual camera failed" \
        "${virtualCameraDevice} did not become capture-capable; systemd will retry." || true
    ''}
      exit 1
    fi

    wait "$obsPid"
  '';
in {
  options.modules.hardware.obsbot = {
    enable = mkEnableOption "OBSBOT Tail 2 UVC integration, DJI Mic 3 routing, and OBS automation";

    usb = {
      vendorId = mkOption {
        type = types.strMatching "^[0-9A-Fa-f]{4}$";
        default = "3564";
        description = "USB vendor ID used to match the Tail 2 parent device.";
      };
      productId = mkOption {
        type = types.nullOr (types.strMatching "^[0-9A-Fa-f]{4}$");
        default = null;
        description = "Optional Tail 2 UVC product ID used to narrow the udev rule.";
      };
    };

    video.deviceSymlink = mkOption {
      type = types.strMatching "^[A-Za-z0-9._-]+$";
      default = "obsbot-tail2";
      description = "Stable device symlink created below /dev for the primary Tail 2 capture interface.";
    };

    audio = {
      enable = mkEnableOption "automatic DJI Mic 3 routing from the Tail 2 UVC audio source";
      sourcePattern = mkOption {
        type = types.str;
        default = "(obsbot|tail[ _-]?2|3564)";
        description = "Case-insensitive regular expression used to locate the Tail 2 UVC PipeWire source.";
      };
      virtualSourceName = mkOption {
        type = types.strMatching "^[A-Za-z0-9._-]+$";
        default = "obsbot_dji_mic";
        description = "Stable PipeWire/PulseAudio source name exposed to OBS.";
      };
      virtualSourceDescription = mkOption {
        type = types.strMatching "^[A-Za-z0-9._-]+$";
        default = "OBSBOT_DJI_Mic_3";
        description = "Display-safe description assigned to the virtual microphone.";
      };
      sampleRate = mkOption {
        type = types.ints.positive;
        default = 48000;
        description = "Sample rate requested for the virtual microphone.";
      };
      channels = mkOption {
        type = types.ints.between 1 8;
        default = 2;
        description = "Channel count requested for the virtual microphone.";
      };
      setDefault = mkOption {
        type = types.bool;
        default = true;
        description = "Whether the OBSBOT virtual microphone becomes the default source while OBS runs.";
      };
    };

    obs = {
      autoStart = mkEnableOption "OBS startup and virtual-camera verification when the Tail 2 appears";
      collection = mkOption {
        type = types.strMatching ".+";
        default = "Tail 2";
        description = "Existing OBS scene collection selected during automatic startup.";
      };
      profile = mkOption {
        type = types.strMatching ".+";
        default = "Tail 2";
        description = "Existing OBS profile selected during automatic startup.";
      };
      scene = mkOption {
        type = types.strMatching ".+";
        default = "Tail 2";
        description = "Existing OBS scene selected during automatic startup.";
      };
    };

    retry = {
      deviceAttempts = mkOption {
        type = types.ints.positive;
        default = 40;
        description = "Attempts made while waiting for physical and virtual video devices.";
      };
      audioAttempts = mkOption {
        type = types.ints.positive;
        default = 40;
        description = "Attempts made while locating and creating the PipeWire audio source.";
      };
      virtualCameraAttempts = mkOption {
        type = types.ints.positive;
        default = 40;
        description = "Attempts made while waiting for OBS to activate the virtual camera.";
      };
      intervalSeconds = mkOption {
        type = types.numbers.positive;
        default = 0.5;
        description = "Delay between readiness checks.";
      };
      restartDelaySeconds = mkOption {
        type = types.ints.positive;
        default = 5;
        description = "Delay before systemd retries a failed OBS startup.";
      };
      startLimitBurst = mkOption {
        type = types.ints.positive;
        default = 3;
        description = "Maximum failed starts permitted during the start-limit interval.";
      };
      startLimitIntervalSeconds = mkOption {
        type = types.ints.positive;
        default = 120;
        description = "Interval used to bound repeated failed OBS starts.";
      };
    };

    notify = mkOption {
      type = types.bool;
      default = true;
      description = "Whether startup and virtual-camera failures generate desktop notifications.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = obsCfg.enable;
        message = "modules.hardware.obsbot requires modules.programs.obs.enable.";
      }
      {
        assertion = !cfg.obs.autoStart || obsCfg.virtualCamera.enable;
        message = "modules.hardware.obsbot.obs.autoStart requires modules.programs.obs.virtualCamera.enable.";
      }
      {
        assertion = !cfg.audio.enable || cfg.obs.autoStart;
        message = "modules.hardware.obsbot.audio requires modules.hardware.obsbot.obs.autoStart.";
      }
      {
        assertion = !cfg.audio.enable || (config.services.pipewire.enable && config.services.pipewire.pulse.enable);
        message = "modules.hardware.obsbot.audio requires PipeWire and its PulseAudio compatibility service.";
      }
    ];

    user.packages = [pkgs.pulseaudio];

    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="video4linux", KERNEL=="video[0-9]*", ATTR{index}=="0", ATTRS{idVendor}=="${cfg.usb.vendorId}"${productMatch}, ENV{ID_V4L_CAPABILITIES}=="*:capture:*", SYMLINK+="${cfg.video.deviceSymlink}"${userServiceRequest}
    '';

    hm.systemd.user.services.obsbot-tail2 = mkIf cfg.obs.autoStart {
      Unit = {
        Description = "Route OBSBOT audio and start OBS for the Tail 2";
        After = [
          "graphical-session.target"
          "pipewire.service"
          "pipewire-pulse.service"
          "wireplumber.service"
        ];
        Wants = [
          "pipewire.service"
          "pipewire-pulse.service"
          "wireplumber.service"
        ];
        PartOf = ["graphical-session.target"];
        ConditionPathExists = videoDevice;
        StartLimitBurst = cfg.retry.startLimitBurst;
        StartLimitIntervalSec = cfg.retry.startLimitIntervalSeconds;
      };

      Service = {
        Type = "simple";
        ExecStartPre = prepareObsbot;
        ExecStart = runObsbot;
        ExecStopPost = cleanupAudio;
        Restart = "on-failure";
        RestartSec = cfg.retry.restartDelaySeconds;
        TimeoutStopSec = 15;
        Environment = lib.optional cfg.audio.enable "PULSE_SOURCE=${cfg.audio.virtualSourceName}";
      };

      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
