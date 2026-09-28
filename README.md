<h1 align="center">
      <img align="center" src="data/icons/hicolor/scalable/apps/net.windower.Lumoria.svg" alt="Lumoria" width="175">
    <br><br>
    Lumoria
</h1>

<p align="center">
  <strong>A Linux installer and launcher for Final Fantasy XI.</strong>
</p>

## What is this?

Lumoria is a Windower Community project that brings the tools for playing **Final Fantasy XI** with **Windower 4** on Linux into one place, making setup easier from start to finish.

## How to install

See [Getting Started](https://github.com/Windower/Lumoria/wiki/Getting-Started) in the wiki.

## Ashita v4 alongside Windower (experimental)

Lumoria ships an *Ashita v4 Beta* launcher manifest, but a prefix has exactly one
launcher. To run **Ashita and Windower from the same prefix** (same PlayOnline /
FFXI installation, same Wine runner, DXVK/dgVoodoo and LAA settings), attach the
bundled post-install script instead:

1. Open your Windower prefix, go to **Packages → Scripts → Add** and pick
   `data/manifests/scripts/ashita-v4.json` (installed under
   `<datadir>/lumoria/scripts/ashita-v4.json`). Edit the `ASHITA_DIR` variable in a
   copy of that file first if you want Ashita somewhere other than `drive_c/AshitaV4`.
2. The script clones <https://github.com/AshitaXI/Ashita-v4beta>, copies
   `config/boot/example-retail.ini` to `lumoria-retail.ini`, and installs the
   `vcrun2022`, `gdiplus` and `dotnet48` redists (dotnet48 is only needed by the
   `Ashita.exe` GUI launcher; `Ashita-cli.exe` works without it).
3. Every `config/boot/*.ini` file appears as a launch target (*Boot profile (name)*)
   under the script's group. Pick one as the default launch or create a shortcut for
   it; Lumoria runs `Ashita-cli.exe <profile>.ini` with the Ashita folder as the
   working directory. Use the **Update Ashita** action to `git pull` the release repo.

Ashita does not support Linux officially. Under Wine, load atom0s' `winefix` plugin
(`/load winefix`) or add it to your boot profile's `[ashita.plugins]` list.

## License

GPL-3.0-or-later. See the [LICENSE](LICENSE) file for details.

## Disclaimer

All trademarks or registered trademarks are the property of their respective owners.

**(c) 2002-2012 SQUARE ENIX CO., LTD. All Rights Reserved. Title Design by Yoshitaka Amano. FINAL FANTASY and VANA'DIEL are registered trademarks of Square Enix Co., Ltd. SQUARE ENIX, PLAYONLINE and the PlayOnline logo are trademarks of Square Enix Co., Ltd.**

We are not affiliated with SQUARE ENIX CO., LTD. in any way.

## Special Thanks
- Lutris, Winetricks, and ProtonPlus for inspiration. Learned a lot from tinkering with their projects.
- Thorny for the original Large Address Aware patch.
- taru, Arieh, and Surik from the Windower Discord server for extensive beta testing.
