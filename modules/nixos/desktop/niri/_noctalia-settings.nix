{
  fontScale,
  homeDirectory,
  wallpaper,
  wallpaperDirectory,
}: {
  accessibility.ui_scale = fontScale;

  theme = {
    mode = "dark";
    shell_mode = "dark";
    source = "wallpaper";
    wallpaper_scheme = "soft";
    pure_black_dark = false;
  };

  shell = {
    font_family = "Maple Mono NF CN";
    corner_radius_scale = 1.0;
    button_borders = false;
    input_borders = true;
    popup_borders = true;
    card_borders = false;
    popup_shadows = true;
    telemetry_enabled = false;
    setup_wizard_enabled = false;
    settings_show_advanced = true;
    niri_overview_type_to_launch_enabled = true;
    polkit_agent = true;
    clipboard_enabled = true;
    clipboard_keep_from_closed_apps = true;
    clipboard_history_max_entries = 250;
    clipboard_image_action_command = "satty -f -";

    animation = {
      enabled = true;
      speed = 1.0;
    };

    shadow = {
      direction = "down_right";
      alpha = 0.45;
    };

    panel = {
      transparency_mode = "glass";
      borders = false;
      shadow = true;
      list_item_background = false;
      launcher_placement = "floating";
      clipboard_placement = "floating";
      control_center_placement = "attached";
      wallpaper_placement = "attached";
      session_placement = "attached";
      polkit_placement = "floating";
      launcher_position = "center";
      clipboard_position = "center";
      polkit_position = "center";
      open_near_click_control_center = true;
      open_near_click_wallpaper = true;
      open_near_click_session = true;
    };

    launcher = {
      categories = true;
      show_icons = true;
      show_app_origin_indicator = true;
      compact = false;
      app_grid = false;
      show_app_actions = true;
      sort_by_usage = true;
      fetch_exchange_rates = false;
    };

    screenshot = {
      save_to_file = true;
      directory = "${homeDirectory}/Pictures/Screenshots";
      copy_to_clipboard = true;
      freeze_screen = true;
      confirm_region = false;
      show_cursor = false;
    };
  };

  bar = {
    order = ["default"];
    default = {
      position = "top";
      enabled = true;
      auto_hide = false;
      smart_auto_hide = false;
      reserve_space = true;
      layer = "top";
      thickness = 38;
      background_opacity = 0.0;
      border_width = 0.0;
      shadow = true;
      radius = 12;
      margin_ends = 5;
      margin_edge = 5;
      padding = 2;
      widget_spacing = 6;
      scale = 1.0;
      font_scale = fontScale;
      font_weight = 600;
      font_family = "Maple Mono NF CN";
      capsule = true;
      capsule_fill = "surface";
      capsule_opacity = 0.82;
      capsule_radius = 10.0;
      capsule_padding = 7;
      start = [
        "launcher"
        "clock"
        "group:system-stats"
        "active-window"
        "media"
      ];
      center = ["workspaces"];
      end = [
        "group:status"
        "control-center"
      ];
      capsule_group = [
        {
          id = "system-stats";
          members = [
            "cpu"
            "memory"
            "disk"
            "download"
            "upload"
          ];
          fill = "surface";
          padding = 7.0;
          radius = 10.0;
          opacity = 0.82;
          widget_spacing = 5;
          enabled = true;
        }
        {
          id = "status";
          members = [
            "privacy"
            "notifications"
            "battery"
            "volume"
            "brightness"
            "tray"
          ];
          fill = "surface";
          padding = 7.0;
          radius = 10.0;
          opacity = 0.82;
          widget_spacing = 6;
          enabled = true;
        }
      ];
    };
  };

  widget = {
    launcher = {
      type = "launcher";
      capsule = true;
    };
    clock = {
      type = "clock";
      format = "{:%H:%M %a, %b %d}";
      capsule = true;
    };
    cpu = {
      type = "sysmon";
      stat = "cpu_usage";
      visualization = "none";
      show_value = true;
      label_show_units = true;
      show_glyph = true;
    };
    memory = {
      type = "sysmon";
      stat = "ram_pct";
      visualization = "none";
      show_value = true;
      label_show_units = true;
      show_glyph = true;
    };
    disk = {
      type = "sysmon";
      stat = "disk_used_pct";
      path = "/";
      visualization = "none";
      show_value = true;
      label_show_units = true;
      show_glyph = true;
    };
    download = {
      type = "sysmon";
      stat = "net_rx";
      visualization = "none";
      network_speed_unit = "auto";
      network_speed_compact = true;
      show_value = true;
      show_glyph = true;
    };
    upload = {
      type = "sysmon";
      stat = "net_tx";
      visualization = "none";
      network_speed_unit = "auto";
      network_speed_compact = true;
      show_value = true;
      show_glyph = true;
    };
    active-window = {
      type = "active_window";
      max_length = 145;
      title_scroll = "on_hover";
    };
    media = {
      type = "media";
      artist_first = false;
      min_length = 80;
      max_length = 180;
      art_size = 22;
      title_scroll = "on_hover";
      hide_when_no_media = true;
    };
    workspaces = {
      type = "workspaces";
      style = "regular";
      show_labels = true;
      show_icons = false;
      label_source = "name";
      max_label_chars = 12;
      labels_only_when_occupied = false;
      hide_when_empty = false;
      pill_scale = fontScale;
      active_pill_size = 2.2;
      inactive_pill_size = 1.0;
      focused_color = "primary";
      occupied_color = "secondary";
      empty_color = "surface_variant";
      capsule = false;
    };
    privacy.type = "privacy";
    notifications.type = "notifications";
    battery.type = "battery";
    volume.type = "volume";
    brightness.type = "brightness";
    tray.type = "tray";
    control-center.type = "control-center";
  };

  desktop_widgets = {
    enabled = true;
    schema_version = 2;
    widget_order = [
      "clock-main"
      "weather-main"
      "media-main"
    ];
    grid = {
      visible = false;
      cell_size = 16;
      major_interval = 4;
    };
    widget = {
      clock-main = {
        type = "clock";
        cx = 100.0;
        cy = 170.0;
        box_width = 120.0;
        box_height = 105.0;
        settings = {
          clock_style = "digital";
          format = "{:%H\n%M}";
          center_text = true;
          color = "on_surface";
          shadow = true;
          background = true;
          background_color = "surface";
          background_opacity = 0.82;
          background_radius = 16.0;
          background_padding = 16.0;
        };
      };
      weather-main = {
        type = "weather";
        cx = 320.0;
        cy = 170.0;
        box_width = 280.0;
        box_height = 105.0;
        settings = {
          color = "on_surface";
          shadow = true;
          show_forecast = false;
          background = true;
          background_color = "surface";
          background_opacity = 0.82;
          background_radius = 16.0;
          background_padding = 16.0;
        };
      };
      media-main = {
        type = "media_player";
        cx = 230.0;
        cy = 315.0;
        box_width = 380.0;
        box_height = 110.0;
        settings = {
          layout = "horizontal";
          color = "on_surface";
          shadow = true;
          hide_when_no_media = false;
          background = true;
          background_color = "surface";
          background_opacity = 0.82;
          background_radius = 16.0;
          background_padding = 16.0;
        };
      };
    };
  };

  wallpaper = {
    enabled = true;
    fill_mode = "crop";
    fill_color = "#11111b";
    directory = wallpaperDirectory;
    transition = [
      "fade"
      "wipe"
      "disc"
      "stripes"
    ];
    transition_duration = 1500;
    edge_smoothness = 0.2;
    transition_on_startup = true;
    default.path = wallpaper;
    automation = {
      enabled = false;
      interval_seconds = 600;
      order = "random";
      recursive = true;
    };
  };

  backdrop = {
    enabled = true;
    blur_intensity = 0.4;
    tint_intensity = 0.6;
  };

  notification = {
    enable_daemon = true;
    show_app_name = true;
    show_actions = true;
    position = "top_right";
    layer = "top";
    scale = 1.0;
    background_opacity = 0.88;
    border = false;
    offset_x = 12;
    offset_y = 8;
    collapse_on_dismiss = true;
    max_visible = 5;
    history_retention_hours = 168;
  };

  audio = {
    enable_overdrive = false;
    enable_sounds = false;
    sound_volume = 0.5;
  };

  brightness = {
    enable_ddcutil = false;
    minimum_brightness = 0.05;
    sync_all_monitors = false;
  };

  location = {
    auto_locate = true;
  };

  weather = {
    enabled = true;
    refresh_minutes = 30;
    unit = "metric";
    effects = true;
  };

  system.monitor = {
    enabled = true;
    cpu_poll_seconds = 2.0;
    gpu_poll_seconds = 0.0;
    memory_poll_seconds = 2.0;
    network_poll_seconds = 3.0;
    disk_poll_seconds = 10.0;
  };

  idle = {
    behavior_order = [
      "lock"
      "screen-off"
      "suspend"
    ];
    pre_action_fade_seconds = 2.0;
    behavior = {
      lock = {
        timeout = 600;
        action = "lock";
        enabled = true;
      };
      screen-off = {
        timeout = 660;
        action = "screen_off";
        enabled = true;
      };
      suspend = {
        timeout = 1800;
        action = "lock_and_suspend";
        enabled = false;
      };
    };
  };
}
