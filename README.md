# ImmersionLK

---

![alt tag](https://i.gyazo.com/b23a6e0f407bae660682f2bab59a61c3.jpg)

---

This is a fork and modification of [Immersion-WoTLK](https://github.com/s0h2x/Immersion-WotLK) addon for World of Warcraft: Wrath of the Lich King (3.3.5a).  

It adds support for additional input handling, including secure keybinding manager for keyboard/mouse and ConsolePortLK integration

---

## Changes

- Secure frame handling to avoid UI taint
- secure input mapping for keyboard keys and gamepads via ConsolePortLK

---

## Installation

1. Download the latest release.
2. Extract and copy the `Immersion` folder to your `Interface/AddOns` directory.
3. Ensure the `Immersion` folder contains the main `.toc` file.
4. Launch WoW 3.3.5a and enjoy.

---

## License & Credits

This project is released under the **Artistic License 2.0**, the same license as the original Immersion addon.

**MIT-licensed files from [s0h2x/Immersion-WotLK](https://github.com/s0h2x/Immersion-WotLK)** remain under MIT License and are contained in the **Methods** directory.

- Immersion: Sebastian Lindfors ([Artistic License 2.0](LICENSE.md))
- 3.3.5a Backport: Emin Farajov ([MIT](Methods/LICENSE.md))
- ConsolePortLK enhancements: Leandro Araújo