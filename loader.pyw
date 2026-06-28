"""
    🧠 Brainrot Injector - Steal a Brainrot Script Loader
    Press INSERT to toggle the loader UI.
    Pure Python + Tkinter - No external dependencies.
"""

import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
import json
import os
import sys
import ctypes
import ctypes.wintypes
import threading
import time
import subprocess

# ── Constants ──────────────────────────────────────────────
APP_NAME = "Brainrot Injector"
APP_VERSION = "v2.0"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(SCRIPT_DIR, "loader_config.json")

ACCENT_COLOR = "#C840E9"
ACCENT_DARK = "#8B1FB5"
ACCENT_GLOW = "#E080FF"
BG_PRIMARY = "#0D0D0F"
BG_SECONDARY = "#16161A"
BG_CARD = "#1A1A20"
BG_HOVER = "#22222A"
TEXT_PRIMARY = "#E8E8EE"
TEXT_SECONDARY = "#88889A"
SUCCESS_GREEN = "#2ECC71"
DANGER_RED = "#E74C3C"
WARNING_ORANGE = "#F39C12"

FONT_TITLE = ("Segoe UI", 18, "bold")
FONT_HEADING = ("Segoe UI", 13, "bold")
FONT_BODY = ("Segoe UI", 11)
FONT_SMALL = ("Segoe UI", 9)
FONT_MONO = ("Consolas", 10)
FONT_BUTTON = ("Segoe UI", 11, "bold")

WM_HOTKEY = 0x0312
MOD_NOREPEAT = 0x4000
VK_INSERT = 0x2D


class BrainrotInjector:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title(APP_NAME)
        self.root.geometry("680x520")
        self.root.configure(bg=BG_PRIMARY)
        self.root.resizable(True, True)
        self.root.minsize(580, 420)
        self.root.update_idletasks()
        sw = self.root.winfo_screenwidth()
        sh = self.root.winfo_screenheight()
        w = 680
        h = 520
        x = (sw - w) // 2
        y = (sh - h) // 2
        self.root.geometry(f"{w}x{h}+{x}+{y}")
        self.root.attributes("-alpha", 0.96)
        try:
            DWMWA_USE_IMMERSIVE_DARK_MODE = 20
            ctypes.windll.dwmapi.DwmSetWindowAttribute(
                ctypes.windll.user32.GetParent(self.root.winfo_id()),
                DWMWA_USE_IMMERSIVE_DARK_MODE,
                ctypes.byref(ctypes.c_int(1)),
                ctypes.sizeof(ctypes.c_int)
            )
        except:
            pass

        self.scripts = {}
        self.injected = False
        self.hotkey_id = 1
        self.running = True
        self.load_config()
        self.scan_scripts()
        self.build_ui()
        self.register_hotkey()
        self.root.protocol("WM_DELETE_WINDOW", self.on_close)
        self.root.bind("<Configure>", self.on_resize)
        self.poll_hotkeys()

    def load_config(self):
        self.config = {
            "auto_inject": False,
            "topmost": False,
            "selected_scripts": ["features.lua", "auto_farm.lua", "esp.lua"],
            "executor_path": "",
            "fps_cap": 240
        }
        try:
            if os.path.exists(CONFIG_PATH):
                with open(CONFIG_PATH, "r") as f:
                    saved = json.load(f)
                    self.config.update(saved)
        except:
            pass

    def save_config(self):
        try:
            with open(CONFIG_PATH, "w") as f:
                json.dump(self.config, f, indent=2)
        except:
            pass

    def scan_scripts(self):
        self.scripts = {}
        order = ["main.lua", "config.lua", "lib.lua", "features.lua",
                  "teleports.lua", "auto_farm.lua", "esp.lua", "gui.lua"]
        for fname in order:
            fpath = os.path.join(SCRIPT_DIR, fname)
            if os.path.exists(fpath):
                size = os.path.getsize(fpath)
                self.scripts[fname] = {
                    "path": fpath,
                    "size": size,
                    "selected": tk.BooleanVar(
                        value=fname in self.config.get("selected_scripts",
                        ["features.lua", "auto_farm.lua", "esp.lua"])
                    )
                }

    def register_hotkey(self):
        try:
            hwnd = ctypes.windll.user32.GetParent(self.root.winfo_id())
            result = ctypes.windll.user32.RegisterHotKey(
                hwnd, self.hotkey_id, MOD_NOREPEAT, VK_INSERT
            )
            if result == 0:
                self.log("Failed to register INSERT hotkey", "warning")
        except Exception as e:
            self.log(f"Hotkey error: {e}", "warning")

    def unregister_hotkey(self):
        try:
            hwnd = ctypes.windll.user32.GetParent(self.root.winfo_id())
            ctypes.windll.user32.UnregisterHotKey(hwnd, self.hotkey_id)
        except:
            pass

    def poll_hotkeys(self):
        def poll():
            while self.running:
                try:
                    msg = ctypes.wintypes.MSG()
                    if ctypes.windll.user32.PeekMessageW(
                        ctypes.byref(msg),
                        ctypes.windll.user32.GetParent(self.root.winfo_id()),
                        WM_HOTKEY, WM_HOTKEY, 1
                    ):
                        if msg.message == WM_HOTKEY:
                            self.root.after(0, self.toggle_visibility)
                    time.sleep(0.05)
                except:
                    time.sleep(0.1)
        t = threading.Thread(target=poll, daemon=True)
        t.start()

    def toggle_visibility(self):
        if self.root.state() == "withdrawn":
            self.root.deiconify()
            self.root.lift()
            self.root.focus_force()
            self.log("Loader shown (INSERT)", "dim")
        else:
            self.root.withdraw()
            self.log("Loader hidden (INSERT) - press INSERT to show", "dim")

    def build_ui(self):
        self.main_container = tk.Frame(self.root, bg=BG_PRIMARY)
        self.main_container.pack(fill=tk.BOTH, expand=True, padx=0, pady=0)

        self.title_frame = tk.Frame(self.main_container, bg=BG_SECONDARY, height=54)
        self.title_frame.pack(fill=tk.X, side=tk.TOP)
        self.title_frame.pack_propagate(False)

        logo_label = tk.Label(
            self.title_frame, text="🧠", font=("Segoe UI", 24),
            bg=BG_SECONDARY, fg=TEXT_PRIMARY
        )
        logo_label.pack(side=tk.LEFT, padx=(14, 6), pady=8)

        title_text = tk.Label(
            self.title_frame, text=APP_NAME, font=FONT_TITLE,
            bg=BG_SECONDARY, fg=ACCENT_COLOR
        )
        title_text.pack(side=tk.LEFT, pady=10)

        version_label = tk.Label(
            self.title_frame, text=APP_VERSION, font=FONT_SMALL,
            bg=BG_SECONDARY, fg=TEXT_SECONDARY
        )
        version_label.pack(side=tk.LEFT, padx=(6, 0), pady=14)

        self.status_dot = tk.Canvas(self.title_frame, width=12, height=12,
                                      bg=BG_SECONDARY, highlightthickness=0)
        self.status_dot.pack(side=tk.RIGHT, padx=(0, 8), pady=20)
        self.draw_status_dot(SUCCESS_GREEN)

        self.status_label = tk.Label(
            self.title_frame, text="READY", font=FONT_SMALL,
            bg=BG_SECONDARY, fg=SUCCESS_GREEN
        )
        self.status_label.pack(side=tk.RIGHT, padx=(2, 14), pady=16)

        min_btn = self.make_title_button(self.title_frame, "─", self.minimize_window)
        min_btn.pack(side=tk.RIGHT, padx=(0, 2), pady=14)

        close_btn = self.make_title_button(self.title_frame, "✕", self.on_close, DANGER_RED)
        close_btn.pack(side=tk.RIGHT, padx=(0, 10), pady=14)

        sep = tk.Frame(self.main_container, bg=ACCENT_COLOR, height=2)
        sep.pack(fill=tk.X, side=tk.TOP)

        content = tk.Frame(self.main_container, bg=BG_PRIMARY)
        content.pack(fill=tk.BOTH, expand=True, side=tk.TOP, padx=0, pady=0)

        left_panel = tk.Frame(content, bg=BG_PRIMARY, width=340)
        left_panel.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(10, 5), pady=10)
        left_panel.pack_propagate(False)

        list_header = tk.Frame(left_panel, bg=BG_CARD, height=36)
        list_header.pack(fill=tk.X, pady=(0, 4))
        list_header.pack_propagate(False)

        tk.Label(list_header, text="SCRIPTS", font=FONT_HEADING,
                 bg=BG_CARD, fg=TEXT_PRIMARY).pack(side=tk.LEFT, padx=12, pady=6)

        select_all_btn = self.make_small_button(list_header, "All",
            lambda: self.toggle_all(True))
        select_all_btn.pack(side=tk.RIGHT, padx=(2, 2), pady=5)

        select_none_btn = self.make_small_button(list_header, "None",
            lambda: self.toggle_all(False))
        select_none_btn.pack(side=tk.RIGHT, padx=(2, 2), pady=5)

        list_outer = tk.Frame(left_panel, bg=BG_CARD)
        list_outer.pack(fill=tk.BOTH, expand=True)

        self.script_canvas = tk.Canvas(list_outer, bg=BG_CARD, highlightthickness=0)
        self.script_scrollbar = tk.Scrollbar(list_outer, orient=tk.VERTICAL,
                                               command=self.script_canvas.yview)
        self.script_frame = tk.Frame(self.script_canvas, bg=BG_CARD)

        self.script_canvas.configure(yscrollcommand=self.script_scrollbar.set)
        self.script_canvas_window = self.script_canvas.create_window((0, 0),
            window=self.script_frame, anchor=tk.NW, tags="script_frame")

        self.script_canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=0, pady=0)
        self.script_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        self.script_frame.bind("<Configure>", lambda e: self.script_canvas.configure(
            scrollregion=self.script_canvas.bbox("all")))
        self.script_canvas.bind("<Configure>", lambda e: self.script_canvas.itemconfig(
            self.script_canvas_window, width=e.width))

        def on_mousewheel(event):
            self.script_canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")
        self.script_canvas.bind("<Enter>", lambda e: self.script_canvas.bind_all("<MouseWheel>", on_mousewheel))
        self.script_canvas.bind("<Leave>", lambda e: self.script_canvas.unbind_all("<MouseWheel>"))

        self.populate_script_list()

        right_panel = tk.Frame(content, bg=BG_PRIMARY, width=310)
        right_panel.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True, padx=(5, 10), pady=10)
        right_panel.pack_propagate(False)

        action_card = tk.Frame(right_panel, bg=BG_CARD)
        action_card.pack(fill=tk.X, pady=(0, 6))

        tk.Label(action_card, text="ACTIONS", font=FONT_HEADING,
                 bg=BG_CARD, fg=TEXT_PRIMARY).pack(anchor=tk.W, padx=12, pady=(10, 6))

        self.inject_btn = self.make_glow_button(
            action_card, "INJECT", self.inject_scripts
        )
        self.inject_btn.pack(fill=tk.X, padx=12, pady=(4, 2))

        copy_btn = self.make_outline_button(
            action_card, "Copy Combined Script", self.copy_combined
        )
        copy_btn.pack(fill=tk.X, padx=12, pady=2)

        folder_btn = self.make_outline_button(
            action_card, "Open Script Folder", self.open_folder
        )
        folder_btn.pack(fill=tk.X, padx=12, pady=(2, 2))

        opt_frame = tk.Frame(action_card, bg=BG_CARD)
        opt_frame.pack(fill=tk.X, padx=12, pady=(4, 10))

        self.auto_inject_var = tk.BooleanVar(value=self.config.get("auto_inject", False))
        auto_cb = tk.Checkbutton(
            opt_frame, text="Auto-inject on launch", variable=self.auto_inject_var,
            bg=BG_CARD, fg=TEXT_PRIMARY, selectcolor=BG_HOVER,
            activebackground=BG_CARD, activeforeground=ACCENT_COLOR,
            font=FONT_SMALL, command=self.on_auto_inject_toggle
        )
        auto_cb.pack(side=tk.LEFT)

        self.topmost_var = tk.BooleanVar(value=self.config.get("topmost", False))
        top_cb = tk.Checkbutton(
            opt_frame, text="Always on top", variable=self.topmost_var,
            bg=BG_CARD, fg=TEXT_PRIMARY, selectcolor=BG_HOVER,
            activebackground=BG_CARD, activeforeground=ACCENT_COLOR,
            font=FONT_SMALL, command=self.on_topmost_toggle
        )
        top_cb.pack(side=tk.LEFT, padx=(12, 0))

        console_frame = tk.Frame(right_panel, bg=BG_CARD)
        console_frame.pack(fill=tk.BOTH, expand=True)

        console_header = tk.Frame(console_frame, bg=BG_CARD, height=30)
        console_header.pack(fill=tk.X)
        console_header.pack_propagate(False)

        tk.Label(console_header, text="CONSOLE", font=FONT_SMALL,
                 bg=BG_CARD, fg=TEXT_SECONDARY).pack(side=tk.LEFT, padx=10, pady=4)

        clear_btn = self.make_small_button(console_header, "Clear", self.clear_console)
        clear_btn.pack(side=tk.RIGHT, padx=8, pady=2)

        self.console = scrolledtext.ScrolledText(
            console_frame, bg=BG_SECONDARY, fg=TEXT_PRIMARY,
            insertbackground=ACCENT_COLOR, selectbackground=ACCENT_DARK,
            font=FONT_MONO, wrap=tk.WORD, relief=tk.FLAT,
            borderwidth=0, padx=10, pady=8
        )
        self.console.pack(fill=tk.BOTH, expand=True, padx=0, pady=(0, 0))
        self.console.configure(state=tk.DISABLED)

        self.console.tag_config("info", foreground=TEXT_PRIMARY)
        self.console.tag_config("success", foreground=SUCCESS_GREEN)
        self.console.tag_config("warning", foreground=WARNING_ORANGE)
        self.console.tag_config("error", foreground=DANGER_RED)
        self.console.tag_config("accent", foreground=ACCENT_COLOR)
        self.console.tag_config("dim", foreground=TEXT_SECONDARY)

        footer = tk.Frame(self.main_container, bg=BG_SECONDARY, height=22)
        footer.pack(fill=tk.X, side=tk.BOTTOM)
        footer.pack_propagate(False)

        tk.Label(footer, text="Press INSERT to toggle  |  Steal a Brainrot",
                 font=("Segoe UI", 7), bg=BG_SECONDARY, fg=TEXT_SECONDARY).pack(pady=3)

        self.log("Brainrot Injector started", "accent")
        self.log(f"Script directory: {SCRIPT_DIR}", "dim")
        self.log(f"{len(self.scripts)} scripts detected", "info")
        self.log("Press INSERT to hide/show this window", "dim")
        self.log("Ready to inject", "success")

    def populate_script_list(self):
        descriptions = {
            "main.lua": "Entry point - loads all modules",
            "config.lua": "Settings & configuration",
            "lib.lua": "Core library & utilities",
            "features.lua": "Player enhancements (fly, aimbot, etc)",
            "teleports.lua": "Map teleports & locations",
            "auto_farm.lua": "Auto collect, click, equip",
            "esp.lua": "Player & item ESP visuals",
            "gui.lua": "In-game GUI for all features"
        }
        for fname, data in self.scripts.items():
            card = tk.Frame(self.script_frame, bg=BG_CARD)
            card.pack(fill=tk.X, padx=0, pady=1)
            cb = tk.Checkbutton(
                card, variable=data["selected"],
                bg=BG_CARD, fg=TEXT_PRIMARY, selectcolor=BG_HOVER,
                activebackground=BG_CARD, activeforeground=ACCENT_COLOR,
                font=FONT_BODY
            )
            cb.pack(side=tk.LEFT, padx=(8, 4), pady=7)
            info_frame = tk.Frame(card, bg=BG_CARD)
            info_frame.pack(side=tk.LEFT, fill=tk.X, expand=True, pady=6)
            name_label = tk.Label(
                info_frame, text=fname, font=FONT_BODY,
                bg=BG_CARD, fg=TEXT_PRIMARY, anchor=tk.W
            )
            name_label.pack(anchor=tk.W)
            desc = descriptions.get(fname, "")
            size_kb = data["size"] / 1024
            desc_label = tk.Label(
                info_frame,
                text=f"{desc}  •  {size_kb:.1f} KB",
                font=FONT_SMALL, bg=BG_CARD, fg=TEXT_SECONDARY, anchor=tk.W
            )
            desc_label.pack(anchor=tk.W)
            for widget in [card, info_frame, name_label, desc_label, cb]:
                widget.bind("<Enter>", lambda e, c=card: self._on_card_enter(c))
                widget.bind("<Leave>", lambda e, c=card: self._on_card_leave(c))

    def _on_card_enter(self, card):
        card.configure(bg=BG_HOVER)
        for child in card.winfo_children():
            try:
                if isinstance(child, (tk.Frame, tk.Label)):
                    child.configure(bg=BG_HOVER)
                if isinstance(child, tk.Frame):
                    for sub in child.winfo_children():
                        if isinstance(sub, (tk.Frame, tk.Label)):
                            sub.configure(bg=BG_HOVER)
            except:
                pass

    def _on_card_leave(self, card):
        card.configure(bg=BG_CARD)
        for child in card.winfo_children():
            try:
                if isinstance(child, (tk.Frame, tk.Label)):
                    child.configure(bg=BG_CARD)
                if isinstance(child, tk.Frame):
                    for sub in child.winfo_children():
                        if isinstance(sub, (tk.Frame, tk.Label)):
                            sub.configure(bg=BG_CARD)
            except:
                pass

    def make_title_button(self, parent, text, command, hover_color="#333340"):
        btn = tk.Label(parent, text=text, font=("Segoe UI", 13),
                       bg=BG_SECONDARY, fg=TEXT_SECONDARY,
                       padx=10, cursor="hand2")
        btn.bind("<Button-1>", lambda e: command())
        btn.bind("<Enter>", lambda e: btn.configure(bg=hover_color, fg="#FFFFFF"))
        btn.bind("<Leave>", lambda e: btn.configure(bg=BG_SECONDARY, fg=TEXT_SECONDARY))
        return btn

    def make_small_button(self, parent, text, command):
        btn = tk.Label(parent, text=text, font=FONT_SMALL,
                       bg=BG_HOVER, fg=TEXT_PRIMARY,
                       padx=10, pady=2, cursor="hand2")
        btn.bind("<Button-1>", lambda e: command())
        btn.bind("<Enter>", lambda e: btn.configure(bg=ACCENT_DARK, fg="#FFFFFF"))
        btn.bind("<Leave>", lambda e: btn.configure(bg=BG_HOVER, fg=TEXT_PRIMARY))
        return btn

    def make_glow_button(self, parent, text, command):
        frame = tk.Frame(parent, bg=ACCENT_COLOR)
        btn = tk.Label(frame, text=text, font=FONT_BUTTON,
                       bg=ACCENT_COLOR, fg="#FFFFFF",
                       padx=20, pady=10, cursor="hand2")
        btn.pack(fill=tk.BOTH, expand=True)
        btn.bind("<Button-1>", lambda e: command())
        btn.bind("<Enter>", lambda e: [
            frame.configure(bg=ACCENT_GLOW),
            btn.configure(bg=ACCENT_GLOW)
        ])
        btn.bind("<Leave>", lambda e: [
            frame.configure(bg=ACCENT_COLOR),
            btn.configure(bg=ACCENT_COLOR)
        ])
        return frame

    def make_outline_button(self, parent, text, command):
        frame = tk.Frame(parent, bg=BG_CARD, highlightbackground=BG_HOVER,
                         highlightthickness=1)
        btn = tk.Label(frame, text=text, font=FONT_BODY,
                       bg=BG_CARD, fg=TEXT_PRIMARY,
                       padx=16, pady=7, cursor="hand2")
        btn.pack(fill=tk.BOTH, expand=True)
        btn.bind("<Button-1>", lambda e: command())
        btn.bind("<Enter>", lambda e: [
            frame.configure(highlightbackground=ACCENT_COLOR),
            btn.configure(fg=ACCENT_COLOR)
        ])
        btn.bind("<Leave>", lambda e: [
            frame.configure(highlightbackground=BG_HOVER),
            btn.configure(fg=TEXT_PRIMARY)
        ])
        return frame

    def draw_status_dot(self, color):
        try:
            self.status_dot.delete("all")
            self.status_dot.create_oval(1, 1, 11, 11, fill=color, outline="")
        except:
            pass

    def toggle_all(self, state):
        for fname, data in self.scripts.items():
            data["selected"].set(state)
        self.save_selected()

    def save_selected(self):
        selected = [fname for fname, data in self.scripts.items() if data["selected"].get()]
        self.config["selected_scripts"] = selected
        self.save_config()

    def on_auto_inject_toggle(self):
        self.config["auto_inject"] = self.auto_inject_var.get()
        self.save_config()

    def on_topmost_toggle(self):
        self.config["topmost"] = self.topmost_var.get()
        self.root.attributes("-topmost", self.topmost_var.get())
        self.save_config()

    def get_combined_script(self):
        order = ["main.lua", "config.lua", "lib.lua", "features.lua",
                  "teleports.lua", "auto_farm.lua", "esp.lua", "gui.lua"]
        combined = []
        combined.append("--[[ Brainrot Injector Combined Script ]]")
        combined.append(f"-- Generated: {time.strftime('%Y-%m-%d %H:%M:%S')}")
        combined.append("-- Modules: " + ", ".join(
            [f for f in order if f in self.scripts and self.scripts[f]["selected"].get()]))
        combined.append("")
        for fname in order:
            if fname in self.scripts and self.scripts[fname]["selected"].get():
                fpath = self.scripts[fname]["path"]
                try:
                    with open(fpath, "r", encoding="utf-8") as f:
                        content = f.read()
                    combined.append(f"\n-- ====== {fname} ======\n")
                    combined.append(content)
                    combined.append("\n")
                except Exception as e:
                    self.log(f"Error reading {fname}: {e}", "error")
        return "\n".join(combined)

    def inject_scripts(self):
        self.save_selected()
        selected_count = sum(1 for data in self.scripts.values() if data["selected"].get())
        if selected_count == 0:
            self.log("No scripts selected! Check at least one script.", "warning")
            return
        if "main.lua" not in self.scripts or not self.scripts["main.lua"]["selected"].get():
            self.log("Warning: main.lua is not selected. The script may not work correctly.", "warning")
        self.log(f"Injecting {selected_count} script(s)...", "accent")
        combined = self.get_combined_script()
        self.root.clipboard_clear()
        self.root.clipboard_append(combined)
        self.draw_status_dot(SUCCESS_GREEN)
        self.status_label.configure(text="INJECTED", fg=SUCCESS_GREEN)
        self.injected = True
        total_size = len(combined.encode('utf-8'))
        self.log(f"Combined script ready ({total_size:,} bytes)", "success")
        self.log("Script copied to clipboard - paste into your executor!", "success")
        self.log("Tip: Use Ctrl+V in your executor to paste", "dim")
        self.flash_inject_button()

    def flash_inject_button(self):
        original = SUCCESS_GREEN
        self.inject_btn.configure(bg=original)
        for child in self.inject_btn.winfo_children():
            child.configure(bg=original)
        def revert():
            self.inject_btn.configure(bg=ACCENT_COLOR)
            for child in self.inject_btn.winfo_children():
                child.configure(bg=ACCENT_COLOR)
        self.root.after(600, revert)

    def copy_combined(self):
        self.save_selected()
        selected_count = sum(1 for data in self.scripts.values() if data["selected"].get())
        if selected_count == 0:
            self.log("No scripts selected!", "warning")
            return
        combined = self.get_combined_script()
        self.root.clipboard_clear()
        self.root.clipboard_append(combined)
        self.log(f"Copied {selected_count} script(s) to clipboard", "success")

    def open_folder(self):
        os.startfile(SCRIPT_DIR)
        self.log("Opened script folder", "info")

    def clear_console(self):
        self.console.configure(state=tk.NORMAL)
        self.console.delete("1.0", tk.END)
        self.console.configure(state=tk.DISABLED)

    def log(self, message, tag="info"):
        self.console.configure(state=tk.NORMAL)
        timestamp = time.strftime("%H:%M:%S")
        self.console.insert(tk.END, f"[{timestamp}] ", "dim")
        self.console.insert(tk.END, f"{message}\n", tag)
        self.console.see(tk.END)
        self.console.configure(state=tk.DISABLED)

    def minimize_window(self):
        self.root.iconify()
        self.log("Window minimized - press INSERT to restore", "dim")

    def on_close(self):
        self.save_config()
        self.running = False
        self.unregister_hotkey()
        self.root.destroy()
        sys.exit(0)

    def on_resize(self, event):
        pass

    def run(self):
        self.log("Welcome! Select scripts and click INJECT.", "info")
        self.root.mainloop()


def main():
    app = BrainrotInjector()
    if app.config.get("auto_inject", False):
        app.root.after(500, app.inject_scripts)
    app.run()


if __name__ == "__main__":
    main()
