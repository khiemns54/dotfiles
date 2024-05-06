import sys
import os
import json
import inspect
import yaml
import subprocess
import time

args = sys.argv
args.pop(0)

SKHD_MAP = {
    "LEFT": "0x7B",
    "DOWN": "0x7D",
    "UP": "0x7E",
    "RIGHT": "0x7C",
    ";": "0x29"
}

YABAI_DIRECTION = {
    "down": "south",
    "up": "north",
    "right": "east",
    "left": "west",
}

DOTFILES = "{}/.dotfiles/script/my_tiling_config.yaml". format(os.environ.get("HOME"))


def main(args):
    global SUB_CMD
    global CONFIG
    global DOTFILES
    SUB_CMD = args.pop(0)
    CONFIG = read_yaml_file(DOTFILES)

    routing(SUB_CMD, args)

def read_yaml_file(filename):
    with open(filename, 'r') as file:
        data = yaml.safe_load(file)
    return data


def run_cmd(cmd):
    print(cmd)
    return subprocess.run([cmd], env=os.environ, stdout=subprocess.PIPE, text=True, shell=True)

def get_target_windows(windows):
    focused_index = 0

    for i, window in enumerate(windows):
        if window.get("has-focus", False):
            focused_index = i
            break

    target_idx = (focused_index + 1) % len(windows)

    return windows[target_idx]


def switch_app(app_name):
    windows = get_app_windows(app_name)

    is_openning = len(windows) != 0
    current_space_id = get_current_space().get("index")

    if not is_openning:
        open_app(app_name)
        retry = 5
        while len(windows) == 0 and retry > 0:
            windows = get_app_windows(app_name)
            time.sleep(1)
            retry = retry - 1
    
    if len(windows) == 0:
        raise "Cannot open app: {}".format(app_name)

    target_window = get_target_windows(windows)
    if target_window.get("is-minimized", True):
        open_app(app_name)

    window_id = target_window.get('id', None)

    if not is_openning:
        yabai_move_window_to_space(window_id, current_space_id)

    yabai_switch_to_window(window_id)


def yabai_switch_to_window(window_id):
    run_cmd("yabai -m config mouse_follows_focus on")
    run_cmd("yabai -m window {} --focus".format(window_id))
    run_cmd("yabai -m config mouse_follows_focus off")


def yabai_move_window_to_space(window_id, space_id):
    run_cmd("yabai -m window {} --space {}".format(window_id, space_id))
    run_cmd("yabai -m space {} --balance".format(space_id))


def get_current_space():
    all_spaces = json.loads(run_cmd("yabai -m query --spaces").stdout)
    space = [w for w in all_spaces if w.get("has-focus", False) == True][0]
    return space

def is_almost_fullscreen(window, display):
    if window.get("has-fullscreen-zoom"):
        return True

    threshold = 0.8
    window_frame = window.get("frame")
    display_frame = display.get("frame")

    window_h = window_frame.get("h")
    window_w = window_frame.get("w")
    display_h = display_frame.get("h")
    display_w = display_frame.get("w")

    if (window_h/ display_h >= threshold) and (window_w/ display_w >= threshold):
        return True

    return False

def is_almost_fullscreen_with_window_id(window_id):
    window = get_window_by_id(window_id)
    if window.get("has-fullscreen-zoom"):
        return True


    display = get_display(window.get("display"))

    return is_almost_fullscreen(window, display)


def get_display(display_idx):
    displays = json.loads(run_cmd("yabai -m query --displays | jq 'map(select(.index == {}))'".format(display_idx)).stdout)

    if len(displays) > 0:
        return displays[0]
    else:
        raise "Cannot find display: {}".format(display_idx)

def get_app_windows(app_name):
    windows = json.loads(run_cmd("yabai -m query --windows | jq 'map(select(.app == \"{}\"))'".format(app_name)).stdout)
    windows = sorted(windows, key = lambda x: x["id"])
    return windows

def get_focus_window():
    windows = json.loads(run_cmd("yabai -m query --windows | jq 'map(select(.\"has-focus\" == true))'").stdout)

    if len(windows) > 0:
        return windows[0]

    return None

def get_current_window():
    window = get_focus_window()
    if window is not None:
        return window

    return None
    
def get_window_by_id(window_id):
    windows = json.loads(run_cmd("yabai -m query --windows | jq 'map(select(.id == {}))'".format(window_id)).stdout)

    if len(windows) > 0:
        return windows[0]
    else:
        raise "Cannot find window: {}".format(window_id)

def open_app(app_name):
    configed_app = [ app for app in CONFIG.get("apps").values() if app["name"] == app_name ][0]
    if configed_app is not None:
        app_name = configed_app["app"]
    run_cmd("open -a \"{}\"".format(app_name))

def yabai_toggle_fullscreen():
    window = get_focus_window()
    if window is None:
        return

    window_id = window.get("id")
    display = get_display(window.get("display"))
    if is_almost_fullscreen(window, display):
        windows = json.loads(run_cmd("yabai -m query --windows | jq 'map(select(.space == {}))'".format(window.get("space"))).stdout)
        if len(windows) <= 1:
            return

        for i, w in enumerate(windows):
            wid = w.get("id")
            if is_almost_fullscreen(w, display):
                run_cmd("yabai -m window {} --toggle zoom-fullscreen".format(wid))

        run_cmd("yabai -m space --balance")
        return

    run_cmd("yabai -m window {} --toggle zoom-fullscreen".format(window_id))


def close_window():
    run_cmd("yabai -m window --close")

def jump_window(direction):
    direction = direction.lower()
    window = get_current_window()
    if window is None:
        yabai_jump_display(direction)
        return


    window_id = window.get("id")

    if is_almost_fullscreen_with_window_id(window_id):
        if window.get("app") == "xTerminal":
            raise "Implement this"

        yabai_jump_display(direction)

    else:
        yabai_jump(direction)

    space = get_current_space()
    if len(space.get("windows", [])) == 0:
        run_cmd("yabai -m display --focus mouse")

def yabai_jump_display(direction):
    yabai_direction = YABAI_DIRECTION.get(direction, None)

    if yabai_direction is None:
        raise "Invalid direction: {}".format(direction)

    run_cmd("yabai -m config mouse_follows_focus on")
    run_cmd("yabai -m display --focus {}".format(yabai_direction))
    run_cmd("yabai -m config mouse_follows_focus off")


def yabai_jump(direction):
    yabai_direction = YABAI_DIRECTION.get(direction, None)

    if yabai_direction is None:
        raise "Invalid direction: {}".format(direction)


    run_cmd("yabai -m config mouse_follows_focus on")
    output = run_cmd("yabai -m window --focus {}".format(yabai_direction))
    run_cmd("yabai -m config mouse_follows_focus off")

    if output.returncode !=0: 
        yabai_jump_display(direction)


def skhd_key_convert(stroke):
    for old, new in SKHD_MAP.items():
        stroke = stroke.replace(old, new)

    return stroke


def skdh_send_key(stroke):
        run_cmd("skhd -k \"{}\"".format(skhd_key_convert(stroke)))
    
def skhd_switch_mode(mode, flag=True):
    print(mode, flag)
    if flag:
        mode_conf = CONFIG.get("modes").get(mode, {})
        key = mode_conf.get("key", None)

        if key is None:
            print("Invalid mode: {}".format(mode))
            return
        skdh_send_key(key)
        skhd_mode_xbar(mode)
    else:
        skhd_switch_mode("default")


def skhd_mode_xbar(mode):
    name = CONFIG.get("modes").get(mode, {}).get("name", mode)
    run_cmd("echo {} > /tmp/skhd_mode".format(name))
    xbar_refresh_plugin("skhd_mode")


def xbar_refresh_plugin(name):
    file = CONFIG.get("xbar").get(name, {}).get("file")
    if file is None:
        raise "Invalid xbar plugin: {}".format(name)
        return

    cmd = "open -gj \"xbar://app.xbarapp.com/refreshPlugin?path={}\"".format(file)
    run_cmd(cmd)

def generate_skhd():
    from jinja2 import Environment, FileSystemLoader

    folder = "{}/.dotfiles/skhd".format(os.environ.get("HOME"))

    env = Environment(loader=FileSystemLoader(folder))
    env.globals["skhd_key_convert"] = skhd_key_convert
    template = env.get_template("skhd.jinja")

    renderred = template.render(data=CONFIG)

    with open("{}/skhdrc".format(folder), 'w+') as file:
        file.write(renderred)

def routing(sub_cmd, args):
    print(sub_cmd, args)

    router = {
        "switch_app": switch_app,
        "skhd_switch_mode": skhd_switch_mode,
        "skhd_mode_xbar": skhd_mode_xbar,
        "jump_window": jump_window,
        "close_window": close_window,
        "yabai_toggle_fullscreen": yabai_toggle_fullscreen,
        "generate_skhd": generate_skhd,
    }

    func = router.get(sub_cmd, lambda: print("Invalid sub command"))
    params_num = len(inspect.signature(func).parameters)

    if params_num == 0:
        func()
        return 

    func(*args[:params_num])

try:
    main(args)
except Exception as e:
    skhd_switch_mode("default")
    print(e)
    raise e
