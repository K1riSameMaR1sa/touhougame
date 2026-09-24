# Touhou Game

## 项目简介

这是一个基于 Godot 4 的竖版弹幕原型项目，当前聚焦在一条简单的 Stage 1-1 关卡流程：玩家移动射击、boss 释放 spell card、UI 展示状态与结算，以及开始菜单/暂停/继续/失败/通关等流程支持。

项目目前属于“可运行原型”，目标是保留清晰的脚本结构并为后续扩展提供稳定的关卡与状态管理入口，而不是追求完整的全作系统。

## 当前功能

- 真实开始菜单：`Start` / `开始游戏` 按钮，支持键盘 `Enter` / `Space` 开始；`Exit` / `Esc` 可退出。
- 游戏内暂停：`P` 或 `Esc` 切换暂停；暂停面板包含 `Continue` / `继续`、`Restart` / `重新开始`、`Return Title` / `返回标题`。
- Continue 流程：玩家死亡后会弹出明确的继续面板，提供 `Continue` 和 `Return Title` / `Game Over` 选项。
- Game Over 面板：展示最终分数，支持 `Retry` / 重试和返回标题。
- Stage Clear 面板：boss 击败后显示 `Stage Clear`、最终分数和剩余状态，并支持重新开始或返回标题。
- 关卡加载：`StageManager` 从 `data/stages.json`、`data/bosses.json` 和 `data/spell_cards.json` 加载并校验配置，boss 的 HP、spell card 阶段与颜色等来自 JSON。
- 基础弹幕与碰撞：玩家子弹、敌方弹幕、boss 攻击模式、碰撞判定与 bomb 清屏已实现。

## 运行环境与启动方式

开发环境：

- Godot 4.7.2 稳定版（Windows）
- 运行文件：`E:\.copilot\Godot\Godot_v4.7.2-stable_win64.exe`
- 项目入口：`E:\.copilot\touhougame\project.godot`

启动方式：

1. 双击运行 `E:\.copilot\Godot\Godot_v4.7.2-stable_win64.exe`。
2. 通过 `Project -> Open` 打开 `E:\.copilot\touhougame\project.godot`。
3. 按 `F5` / `Run` 运行项目，或直接用命令行启动：

```powershell
"E:\.copilot\Godot\Godot_v4.7.2-stable_win64.exe" --path "E:\.copilot\touhougame"
```

## 操作键位

- `WASD` / `方向键`：移动
- `J` / `Space`：射击
- `X`：Bomb / 清屏
- `Enter` / `Space`（在标题界面）：开始游戏
- `P` / `Esc`：暂停 / 继续
- `Esc`（标题界面）：退出游戏
- `R`（Game Over 时）：重试

## 目录结构

```text
TouhouGame/
├── project.godot              # Godot 项目入口
├── README.md                  # 项目说明
├── data/
│   ├── stages.json            # 关卡与 boss 引用
│   ├── bosses.json            # Boss 属性与符卡顺序
│   └── spell_cards.json       # 符卡模式参数
├── scenes/
│   └── GameRoot.tscn         # 当前游戏主场景
├── scripts/
│   ├── GameRoot.gd           # 游戏主流程、UI、暂停/结算控制
│   ├── StageManager.gd       # JSON 配置加载、校验与组合
│   ├── Player.gd             # 玩家控制与受击逻辑
│   ├── Boss.gd               # Boss 生命、阶段与攻击脚本
│   ├── Bullet.gd             # 子弹逻辑
│   └── autoload/
│       └── GameState.gd      # 全局分数、生命、Bomb 和流程状态
└── .godot/                   # Godot 自动生成缓存
```

## JSON 关卡 / 符卡配置说明

关卡配置拆分为三个 JSON 文件。`StageManager` 会在启动时验证文件格式、必填字段、数值范围、ID 唯一性和跨文件引用；任何错误都会禁用开始按钮并输出明确错误。

`data/stages.json` 的关卡字段如下：

- `id`：关卡唯一 ID，例如 `stage_1_1`
- `name`：阶段名，例如 `Stage 1-1`
- `boss_id`：引用 `bosses.json` 中的 Boss ID

`data/bosses.json` 的字段包括 `name`、`hp`、`phase_thresholds` 和 `spell_cards`；`spell_cards` 中的 ID 引用 `spell_cards.json`。

`data/spell_cards.json` 的每项包含：

- `name`：符卡名
- `duration`：持续时间
- `pattern`：模式名（例如 `starlit_bloom`、`lunar_spiral`、`abyss_ring`）
- `color`：攻击颜色
- `threshold`：boss HP 低于该百分比时触发该符卡
- `fire_interval`：发弹间隔

当前实现仍然按 `threshold` 来切换 boss 攻击模式，并读取其中的 `pattern` / `color` / `duration` 控制发弹。

## 开发验证命令

建议在修改脚本后使用以下命令进行解析与 smoke check：

```powershell
"E:\.copilot\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path "E:\.copilot\touhougame" --editor --quit
```

上述命令会检查项目脚本/场景是否可被 Godot 正确解析。若需要更短的运行验证，可再进行一次 headless 启动：

```powershell
"E:\.copilot\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path "E:\.copilot\touhougame" --quit
```

## 当前已知限制 / 后续计划

已知限制：

- 当前项目仍然是单关卡原型，不包含多关卡选择或存档系统。
- Boss 攻击模式相对简单，尚未实现更复杂的分阶段 AI、特效和副本系统。
- 仅保留了基础 UI 与状态流转，尚未扩展完整菜单音效与动画。

后续计划：

- 拆分更多场景（标题、暂停、结算、HUD）以进一步清晰化结构。
- 引入更完整的 boss AI 与随机弹幕节奏设计。
- 扩展生命值、得分、Bomb 与连击/评级系统。
- 逐步增加第二关/第三关配置与 JSON 数据驱动设计。

## 备注

本说明尽量基于当前项目已实现功能编写，未夸大未完成的内容；后续如新增关卡、音效、存档或更丰富的 UI，将在 README 中同步补充。
