# FlexEQ

FlexEQ is an Omarchy Quickshell bar widget for quick audio control. Its compact bar button opens a native, theme-aware panel for output volume, mute, output selection, audio backend detection, and EasyEffects access for detailed equalizer settings.

## Features

- Native Omarchy bar integration with a `♫` volume indicator.
- Uses the active Omarchy theme for the panel and widget controls.
- Controls the default output volume and mute state with `pactl`.
- Lists PulseAudio/PipeWire Pulse-compatible output devices and sets the default sink.
- Detects PipeWire, PulseAudio, or ALSA and reports when no audio server is available.
- Detects EasyEffects and provides a shortcut to its full parametric equalizer and preset controls.

## Requirements

- Omarchy 4.x / Quickshell plugin host
- `pactl` from `libpulse` for audio controls and sink selection
- Optional: `easyeffects` for parametric EQ and presets
- `wpctl` and/or `amixer` for backend detection fallbacks

## Install

From this repository:

```sh
omarchy plugin add <repository-url> --enable
```

Or copy the folder to `~/.config/omarchy/plugins/flexeq.audio/`, then enable and position it:

```sh
omarchy plugin enable flexeq.audio
omarchy bar move flexeq.audio --section right
```

The plugin can also be added from Omarchy's Setup → Plugins UI and moved to the home bar section you prefer.

## Audio support notes

FlexEQ uses `pactl` for volume and output routing, so it works with PipeWire's PulseAudio compatibility server as well as PulseAudio. ALSA is detected and reported, but direct ALSA controls are not yet exposed in the panel. Detailed EQ processing is delegated to EasyEffects when it is installed; this avoids silently inserting a filter chain into the user's active audio graph.

## Development

```sh
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" BarWidget.qml Panel.qml
```

## License

MIT
