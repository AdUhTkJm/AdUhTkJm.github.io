#import "@preview/cuti:0.4.0"
#set document(title: "STS2 随机数系统剖析")
#set page(paper: "a4", margin: 2.3cm)
#set text(size: 10.5pt, font: ("Libertinus Serif", "Noto Serif CJK SC"))
#set heading(numbering: "1.1")
#show link: underline

#align(center)[
  #set text(size: 18pt)
  *杀戮尖塔 2 的随机数*
]

= 简介

本文分析《杀戮尖塔 2》中随机数如何决定地图生成、战斗奖励、卡牌洗牌与敌人行动。

= MegaRandom

`MegaRandom` 是 `xoshiro256**` 的实现，以 4 个 `ulong` 作为状态。最初的状态来自一个单独的 64-bit 种子。而状态推进的函数是 `NextULongInner`，我们称它会*消耗一个随机数*。

- `NextDouble()` 消耗一个随机数，取输出的高 53 位。
- `NextFloat()` 消耗一个随机数，取高 24 位。
- `Next()` 消耗一个随机数。它是对 `NextDouble()` 的包装。
- `NextULong()` 消耗一个随机数，直接返回完整的 64 位。
- `NextBytes(span)` 每 8 字节消耗一个随机数。

= Rng 包装层

`Rng` 是游戏所有逻辑实际使用的类。它持有 `int _counter` 与一个 `MegaRandom`。

它的构造函数如下：

- `Rng(ulong seed)`：直接以 `seed` 作为种子。
- `Rng(ulong seed, string name)`：以 `seed + hash64(name)` 作为种子。

它也有一套 `Next...()`，消耗随机数的数量和底层的 MegaRandom 相同。

它还有一个“临时 RNG”的构造函数：`Rng(Player player, ModelId id, ulong mixin = 0)`，这个的种子是 `runSeed + playerSlot + hash64(id.Entry) + mixin`。

== counter

`_counter` 只写入，但*没有任何影响逻辑的地方会读取它*。也就是说，`counter` 既不参与 PRNG 推进，也不参与取模，只是一个“抽了多少次”的诊断数字。多人的 `SyncRngMessage` 会把整个 `SerializableRunRngSet`（包括每个 counter）从主机同步给客户端，注释里连开发者自己都在怀疑这样做是否合适。

== 方法与消耗量速查

#table(
  columns: (30%, 15%, 13%, 42%),
  table.header([*方法*], [*区间*], [*消耗*], [*说明*]),
  [`NextBool`], [50/50], [1], [内部 `Next(2) == 0`],
  [`NextInt(max)` / `NextInt(min,max)`], [`[0,max)` / `[min,max)`], [1], [double 乘法取整],
  [`NextUnsignedInt(min,max)`], [`[min,max)`], [1], [同上],
  [`NextUnsignedLong(min,max)`], [`[min,max)`], [1], [同上；单参重载在 `max == ulong.MaxValue` 时退化为 `NextULong()`],
  [`NextFloat` / `NextDouble`], [`[min,max)`], [1], [],
  [`NextGaussianDouble` / `NextGaussianFloat`], [拒绝采样到 `[0,1]` 内], [每次尝试 2，可多轮], [用 `sqrt/log/cos`],
  [`NextGaussianInt`], [拒绝采样到 `[min,max]` 内], [每次尝试 2，可多轮], [用 `sqrt/log/sin` + `Math.Round`],
  [`NextItem(items)`], [均匀取一个], [1], [空集合返回 default 且 *0 消耗*],
  [`WeightedNextItem(items, w)`], [按权重取], [1], [内部一次 `NextFloat`],
  [`Shuffle(list)`], [原地 Fisher–Yates], [`n-1`], [`for i = n-1 .. 1: swap(i, NextInt(i+1))`],
)

扩展方法（`ListExtensions` / `IEnumerableExtensions`）：

- `UnstableShuffle(rng)`：就是上面那个 Fisher–Yates，消耗 `n-1`。结果依赖列表初始顺序。
- `StableShuffle(rng)`：先 `list.Sort()`（要求元素 `IComparable`），再 `UnstableShuffle`。排序本身不消耗 RNG，所以总消耗仍是 `n-1`，但结果与初始顺序无关。
- `TakeRandom(count, rng)`：对*整个*列表 `UnstableShuffle`（`n-1` 次），再 `Take(count)`。注意消耗按 `n` 而不是 `count`。
- `GrabBag.Grab / GrabAndRemove(rng, predicate)`：加权抽样，每次尝试 1 个 `NextDouble`；若带 `predicate` 且抽到不合条件的元素，会*重新抽取*，因此消耗次数可变。内部的 `GrabIndex(rng, predicate)` 还先检查“是否存在满足条件的元素”，若不存在直接返回且不消耗。

= 种子派生

== 字符串到基础种子

先对种子进行 canonicalization（默认长度 12）。

`RunRngSet(seedString)` 计算：

- 正常情况：`Seed = xxHash64(seedString, seed = 0)`，取 64 位。
- 若字符串以 `old` 开头：`Seed = (uint32) legacyHash(seedString.substring(3))`，即把旧版 32 位哈希零扩展到 64 位。这是旧存档兼容路径。

== 12 条 run 流

`RunRngSet` 在构造时，对 `RunRngType` 枚举的每个成员创建一条流：

```
seed_i = Seed + hash64(snake_case(name_i))      // 无符号 64 位加法，溢出回绕
```

`snake_case` 只是把 `UpFront` 变成 `up_front`、`MonsterAi` 变成 `monster_ai` 这样。

#table(
  columns: (6%, 21%, 23%, 20%, 30%),
  table.header([*索引*], [*枚举名*], [*snake_case*], [*`hash64(name)`*], [*用途*]),
  [0], [`UpFront`], [`up_front`], [`1a8a7b60da243e80`], [跑开始时一次性生成：遭遇表、事件表、boss、遗物袋],
  [1], [`Shuffle`], [`shuffle`], [`2ad1d778c87c9714`], [抽牌堆洗牌（开局与弃牌堆洗回）],
  [2], [`UnknownMapPoint`], [`unknown_map_point`], [`9800ef3164594356`], [未知点房间类型 roll（以及相关 odds）],
  [3], [`CombatCardGeneration`], [`combat_card_generation`], [`a2a21eef44216b8e`], [战斗中生成卡（Attack Potion、Discovery…）],
  [4], [`CombatPotionGeneration`], [`combat_potion_generation`], [`9ea3163cfeb05ac2`], [战斗中生成药水（Alchemize…）],
  [5], [`CombatCardSelection`], [`combat_card_selection`], [`54a326ec000e7a0a`], [战斗中随机选牌（True Grit…）],
  [6], [`CombatEnergyCosts`], [`combat_energy_costs`], [`b2aee0c22bb1887f`], [战斗内随机能量费（Confusion…）],
  [7], [`CombatTargets`], [`combat_targets`], [`5ff62452ac6b3ac2`], [战斗内随机目标（Bouncing Flask…）],
  [8], [`MonsterAi`], [`monster_ai`], [`5aceec82dac3a1a7`], [敌人行动选择],
  [9], [`Niche`], [`niche`], [`1713d477d45afac5`], [杂项一次性随机（怪物 HP、CursedRun…）],
  [10], [`CombatOrbs`], [`combat_orbs`], [`917d243addb36d52`], [战斗中随机充能球（*当前无调用点*）],
  [11], [`TreasureRoomRelics`], [`treasure_room_relics`], [`5e4180a0a992aed6`], [多人宝箱遗物分配/投票],
)

== 3 条 player 流

每个玩家有自己的 `PlayerRngSet`，基础种子与 run 流*不同*：

```
base_j     = hash64(seedString) + playerSlotIndex     // 通常是 Seed + slot
seed_j     = base_j + hash64(snake_case(name_j))
```

其中 `playerSlotIndex` 用的是玩家“槽位索引”，不是 NetId，以保证每日挑战下结果一致。单人时 slot = 0，于是 `base = hash64(seedString) = Seed`。

#table(
  columns: (6%, 21%, 23%, 20%, 30%),
  table.header([*索引*], [*枚举名*], [*snake_case*], [*`hash64(name)`*], [*用途*]),
  [0], [`Rewards`], [`rewards`], [`20f3bf5504146bb3`], [奖励生成（卡牌稀有度、药水、金币、遗物稀有度）],
  [1], [`Shops`], [`shops`], [`da13890c3383cb6b`], [商店（选卡、定价、药水、遗物价格）],
  [2], [`Transformations`], [`transformations`], [`b8623d6522d877f5`], [卡牌转换结果],
)

注意 `"old"` 前缀时有一个不对称：run 流的 `Seed` 用的是*旧 32 位哈希*（只对前缀后的部分），而 player 流的 `base` 用 `hash64` 哈希*整个字符串（含 `old`）*。所以带 `old` 前缀时两者基础种子不同。

= 12 + 3 条流到底独不独立？

分三层来看：

*状态层面：独立。* 每条流都是一个独立的 `MegaRandom` 实例。推进 `MonsterAi` 一百次不会让 `Shuffle` 少抽一格。因此对 seed 搜索来说，可以分线程、分模块地各自模拟一条流，而不用担心“别的系统抽多了会污染我这条流”。

*派生层面：相关。* 所有 15 条流的种子都是“同一个 64-bit 基础种子 + 一个固定常量”。所以它们不是密码学意义上的独立随机源，而是同一随机源的不同确定性函数。`xoshiro256**` 加 SplitMix64 的雪崩性足够好，使它们在统计上不可区分；但严格说，只要知道 `Seed`，就能算出全部 15 条流的完整序列。这带来两个实际影响：

- 命名哈希碰撞会让两条流完全相同。给出 15 个名字的哈希值后可以确认当前没有碰撞。理论上如果未来新增流名字恰好撞上已有哈希（或其加和后等于已有种子的差值），就会出现“两个系统同步给出相同随机数”的诡异现象。
- 不能假设“两条不同的流会给出不同的随机序列”。如果某个 seed 在两条流上取了相同的相对偏移，会得到相关内容；不过因为 `hash64(name)` 是固定的巨大常量，常规情况下偏移互不相同。

*跨 run / player：* run 流的 base 与 player 流的 base 通常是同一个数（单人 slot 0 时都等于 `Seed`），但流的名字不同，所以不会相等。多人时 player 流的 base 还要加槽位索引，因而每个玩家的奖励/商店流*互不相同*，而 run 流*全队共享*。

总结：*实现上把 12 + 3 当作 15 条独立流来模拟是正确的*；但“独立”是工程意义上的，不是数学意义上的。

= 不在 12 + 3 之列的额外派生流

游戏里大量逻辑用的是“临时命名 RNG”，它们不属于 `RunRngSet` / `PlayerRngSet`，但都从同一个基础种子确定性派生。做 seed 搜索时*必须*把它们考虑进去，否则会漏掉地图、事件、遭遇等关键随机。

#table(
  columns: (22%, 40%, 38%),
  table.header([*派生流*], [*种子公式*], [*用途*]),
  [`act_{n}_map`], [`Seed + hash64("act_" + (actIndex+1) + "_map")`], [标准地图生成（每个 act 各一条）],
  [`spoils_map`], [`Seed + hash64("spoils_map")`], [Spoils Map 特制地图],
  [事件 RNG], [`Seed + (isShared ? 0 : slot) + hash64(eventId)`], [事件内部的选项/随机结果],
  [遭遇 RNG], [`Seed + TotalFloor + hash64(encounterId)`], [遭遇内生成同种怪组合/变体],
  [怪物 RNG], [`Seed + col + row + actIndex + combatId`], [怪物皮肤等（非战斗逻辑）；非 mutable 实例退回 `Chaotic`],
  [战斗背景], [`Seed + row + col*747`], [战斗背景变体],
  [`map_point_selection`], [`Seed + hash64("map_point_selection")`], [多人地图点投票平局],
  [`event_synchronizer`], [`Seed + hash64("event_synchronizer")`], [多人事件选项同步平局],
  [`act_selection`], [`hash64(seedString) + hash64("act_selection")`], [开跑时决定 act 变体与 `RandomCharacter`],
  [`bg_music` / `map_jitter_{act}` / `Seed + ActFloor`], [各种], [音乐、地图抖动、投票动画等 UI 效果],
)

另外还有一个*非确定性*的全局流 `Rng.Chaotic`，用 Unix 秒数播种。它不进入存档、不参与多人同步，被大量用于 VFX / SFX / 怪物皮肤等“不影响玩法”的地方（`ToughEgg`、`Cantopole`、各类 screen shake 等）。注意：如果某个本应确定的行为误用了 `Chaotic`，它就会破坏可复现性；目前战斗逻辑核心没有这种用法。

具体哈希值：`act_1_map = 0ffb9c396e72be02`，`act_2_map = 99340b7c8e70b466`，`act_3_map = 9fcfc55e1de92c3d`，`spoils_map = 4a8eeb4df5358d74`，`map_point_selection = 67e571f7ae8246fb`，`event_synchronizer = 3869c75951d7e6e4`，`act_selection = 79a5d5299dc62d50`。

= 地图生成（`act_{n}_map` 流）

标准地图由 `StandardActMap` 生成。以 Overgrowth 为例（`BaseNumberOfRooms = 15`，多人 -1）：

- `_mapLength = rooms + 1 = 16`，网格是 `7` 列 × `16` 行（行 0..15）。
- 起点 `StartingMapPoint = (3, 0)`（Ancient 类型），boss `BossMapPoint = (3, 16)`，双 boss 在 `(3, 17)`。

== 消耗顺序

1. `GetMapPointTypes(mapRng)`。各 act 重载不同，例如：
   - Overgrowth / Underdocks：`restCount = NextGaussianInt(7, 1, 6, 7)`（结果 6 或 7），`unknownCount = NextGaussianInt(12, 1, 10, 14)`（结果 10..14）。
   - Hive：`restCount = NextGaussianInt(6, 1, 6, 7)`，`unknownCount = 同上 - 1`。
   - Glory：`restCount = NextInt(5, 7)`，`unknownCount = 同上 - 1`。
   - `NumOfElites = round(5 * (SwarmingElites ? 1.6 : 1))`，`NumOfShops = 3`（不消耗 RNG）。
   两个高斯调用都是拒绝采样，会消耗*可变*数量的输出。
2. `GenerateMap()`：循环 7 次，每次 `NextInt(0, 7)` 挑一个 row 1 的起点列。`i == 1` 时会检查是否与已有点重复，若重复则再抽（通常不触发）。row 1 的每个点标记为 Monster。最后把 row 15 的所有点连到 boss。
3. 对每个起点 `PathGenerate()`：只要当前行的行号小于 `_mapLength - 1`（即 15），就调用一次 `GenerateNextCoord()` 生成下一行坐标。
   - `GenerateNextCoord` 把 `[-1, 0, 1]`（列偏移）放进一个 3 元素列表，`StableShuffle(_rng)` 后按打乱顺序尝试。
   - `StableShuffle` 对 3 元素列表消耗固定 `2` 次 `NextInt`。*候选交叉判定失败不会额外消耗 RNG*，只是换下一个已打乱的候选。
   - 所以每条路径固定消耗 `(15 - 起点行) * 2 = 14 * 2 = 28` 次；7 条路径共 196 次（不含起点列抽取）。
4. `AssignPointTypes()`：
   - 固定行：最后一行（row 15）全为 RestSite；row `GetRowCount() - 7 = 9` 为 Treasure；row 1 全为 Monster；起点为 Ancient，boss 行（含第二 boss）为 Boss。不消耗 RNG。
   - 其余类型（RestSite / Shop / Elite / Unknown 按 `_pointTypeCounts` 数量）放进队列，交给 `AssignRemainingTypesToRandomPoints`：最多 3 轮，每轮把“当前所有 Unassigned 点”`StableShuffle`（`k-1` 次），再依次尝试分配（`GetNextValidPointType` 轮转队列，不消耗 RNG）。
   - `StandardActMap` 里还有 `EnsureRowsContainsPointType` / `AssignPointTypesToRandomRows`，但在本类中是*死代码*，未被调用（Spoils 地图里有类似逻辑）。
5. `MapPathPruning.PruneAndRepair(...)`，最多 3 轮：
   - `PruneDuplicateSegments`：找出所有重复路径段，对每个“重复段组”做 `UnstableShuffle`（消耗 `m-1`），尝试剪枝；剪掉就重来。最多循环 50 次，超过会抛异常。
   - `RepairPrunedPointTypes`：依次对 Shop / Elite / RestSite / Unknown 做修复，每次把“可修改的 Monster 点”`StableShuffle`（`k-1`），再把前面的点改成目标类型。
   - 消耗次数完全取决于地图形状，且可能多次迭代。
6. `MapPostProcessing`（CenterGrid / SpreadAdjacentMapPoints / StraightenPaths）*不消耗 RNG*。

因此，地图流的消耗是“算法决定的可变量”，不是固定次数。搜索时只要有一处判定分支不同，后续抽取就整体错位。

== 地图重生成

`EnterAct` 时用 `act_{n}_map` 重新生成对应 act 的地图；因为每条 act 的流种子只依赖 act 索引，act 1 地图形状不影响 act 2 地图。

`GoldenCompass` 遗物会触发 `RunManager.GenerateMap()`。`GenerateMap` 首先照常构造一个 `StandardActMap`（因此 `act_{n}_map` 的 RNG 仍被完整消耗一次），随后 `Hook.ModifyGeneratedMap` 把它换成 `GoldenPathActMap`——一张固定点类型序列的单路径地图，其构造*不再*消耗任何 RNG。`BigGameHunter` 修正器则在 hook 里用*同一个* `act_{n}_map` 流再构造一个 `StandardActMap`（传入 `MapPointTypeCounts` 覆盖：精英数量 ×2.5、忽略点类型规则），从而得到一张不同的地图。

= 未知地图点的房间类型（`UnknownMapPoint` 流）

`RunOddsSet.UnknownMapPoint` 直接持有 `RunRngSet.UnknownMapPoint` 这条流，并保存各房型的“当前 odds”。

`UnknownMapPointOdds.Roll(blacklist, runState)` 的逻辑：

- *新手保护*：若 `UnlockState.NumberOfRuns == 0`，统计历史上进入过的 Unknown 点数量：少于 2 个直接返回 Event，恰好 2 个直接返回 Monster，两种情况都*不消耗 RNG*。
- 否则抽一次 `NextFloat()`，按累积阈值判定：
  - Monster 基准 0.1，Treasure 0.02，Shop 0.03；Elite 基准是 `-1`，表示“永不出现”。
  - 累计未超过抽到的数，则为 Event（`EventOdds = max(0, 1 - 正 odds 之和)`）。
- roll 之后更新 odds（pity 机制）：roll 中的类型重置为其基准值；其余*允许*的类型 `+= 基准值`（Elite 基准为负，所以不增长）。注意这会让 Monster / Treasure / Shop 越来越容易出现，直到被 roll 中。
- `ResetToBase()` 在换幕时调用。

hook 可以改变“允许的房型集合”（`GoldenCompass` 强制只允许 Event、`JuzuBracelet`/`LanternKey` 等）或改 odds（`DeadlyEvents` 开启 Elite）。

= 战斗奖励（player `Rewards` 流）

一个房间结束时的奖励列表在 `RewardsSet` 中生成：

- 普通战斗（Monster）：`GoldReward`、可能一个 `PotionReward`、`CardReward`（3 选 1）。
- 精英（Elite）：`GoldReward`、可能 `PotionReward`、`CardReward`、`RelicReward`。
- Boss：`GoldReward`、可能 `PotionReward`、`CardReward`（Boss 卡池稀有度 roll 为必出 Rare）。

== 消耗顺序

关键：`WithRewardsFromRoom` 构造列表时，先调用 `RollForPotionAndAddTo` 决定“有没有药水奖励”（1 次 `NextFloat`）；随后 `GenerateWithoutOffering` 按*插入顺序*逐个 `Populate()`：

1. `GoldReward.Populate`：`NextInt(min, max+1)`，1 次。
2. `PotionReward.Populate`（仅当药水判定成功）：`PotionFactory.CreateRandomPotionOutOfCombat`，即 1 次 `NextFloat`（稀有度：不高于 0.1 为 Rare、不高于 0.35 为 Uncommon，否则 Common）+ 1 次 `NextItem`（在同稀有度里选）。
3. `CardReward.Populate`：对 3 张卡各执行一次（`CardFactory.CreateForReward`）：
   - 稀有度 roll：1 次 `NextFloat`；
   - 选卡：1 次 `NextItem`；
   - 升级 roll：`RollForUpgrade` *无条件*抽 1 次 `NextFloat`，即使这张卡不可升级（`num` 在 `IsUpgradable` 判定之前就算好了）。
   即每张卡 3 次，共 9 次。
4. `RelicReward.Populate`：`RelicFactory.RollRarity` → 1 次 `NextFloat`（低于 0.5 Common、低于 0.83 Uncommon，否则 Rare），然后从 `RelicGrabBag` 对应稀有度的双端队列前/后取（无 RNG）。

所以一次不掉药的普通战斗在 `Rewards` 上共抽：药水判定 1 + 金币 1 + 卡 9 = 11 次；掉药水再 +2。精英再加遗物稀有度 1 次（以及可能的药水）。

== 稀有度与药水的 pity 机制

`PlayerOddsSet` 让 `CardRarityOdds` 和 `PotionRewardOdds` 都持有 `Rewards` 流。

- `CardRarityOdds`：`CurrentValue`（初始 `-0.05`）作为“rare 额外概率偏移”。`Roll(type)` 抽 1 次 `NextFloat` 后：若出 Rare 则 `CurrentValue = -0.05`，否则 `CurrentValue = min(CurrentValue + 0.01, 0.4)`（`Scarcity` ascension 下增长为 0.005）。每个 act 的升级概率还会加载 `actIndex`（每进入一个 act 非稀有卡升级率 +0.125，`Scarcity` 下 0.25）。
- `RollWithBaseOdds` 与 `RollWithoutChangingFutureOdds` 都用基础概率且*不*改变 `CurrentValue`。商店的稀有度 roll 用后者。
- `PotionRewardOdds`：初始 0.4。`Roll(player, roomType)` 抽 1 次 `NextFloat`；若中则 `CurrentValue -= 0.1`，否则 `+= 0.1`；精英额外加 0.125（= `0.25 * 0.5`）。另外 `Hook.ShouldForcePotionReward` 若为真，函数*直接返回真且不抽 RNG*。

需要注意的是：因为 `CardRarityOdds` 的 roll 与金币/药水/选卡共用 `Rewards` 流，"前面某个奖励是否被生成"会直接改变后面卡牌稀有度的判定序列。

= 商店（player `Shops` 流，但会与 `Rewards` 交错）

`MerchantInventory.CreateForNormalMerchant(player)` 的构造顺序：

1. `PopulateCharacterCardEntries`：
   - 1 次 `Shops.NextInt(5)` 决定 5 张角色卡里哪一张打折。
   - 5 张角色卡（Attack / Attack / Skill / Skill / Power）各自：
     - 稀有度 roll → *`Rewards`*.NextFloat（`CardRarityOdds` 持有 `Rewards`，`RollWithoutChangingFutureOdds(Shop)`，不改变 pity 状态）；
     - 选卡 → `Shops.NextItem`；
     - 升级 roll → *`Rewards`*.NextFloat（`RollForUpgrade` 默认用 `Rewards`，此处基础概率是 `-999999999`，永远不升级但仍然抽）；
     - 定价 `Shops.NextFloat(0.95, 1.05)`；
     - 打折那张会再调一次定价，因此多 1 次 `Shops.NextFloat`。
2. `PopulateColorlessCardEntries`：2 张（Uncommon、Rare），无稀有度 roll；选卡 `Shops`、升级 `Rewards`、定价 `Shops`。
3. `PopulateRelicEntries`：3 个遗物（前两个 `RelicFactory.RollRarity` → *`Rewards`*.NextFloat，第三个固定 Shop 稀有度），每个定价 `Shops.NextFloat(0.85, 1.15)`。
4. `PopulatePotionEntries`：3 个药水各自 1 次 `Shops.NextFloat`（稀有度）+ 1 次 `Shops.NextItem`（选择）+ 1 次 `Shops.NextFloat`（定价 `0.95..1.05`）。

补货（`RestockAfterPurchase`）会继续消耗：遗物补货用 `RollRarity`（`Rewards`）+ 定价（`Shops`），药水补货用 `Shops`。

结论：走过一个商店会*交错*消耗 `Shops` 和 `Rewards`（以及遗物稀有度用的 `Rewards`）。搜索时不能假设“商店只动 Shops 流”。

= 卡牌转换（player `Transformations` 流）

`CardCmd.Transform` / `CardTransformation.GetReplacement` → `CardFactory.CreateRandomCardForTransform`：

- 先按原有卡牌过滤出可转换的候选池（同稀有度或特殊规则、排除原卡、战斗中排除不可生成卡）；
- 再从候选池 `NextItem`，每条转换消耗 1 次。
- 多条转换会先按 `(pile, index)` 排序（`PileIndexSort`）再逐个取，顺序会影响消耗顺序。

战斗中发生的转换（如 `EntropyPower`）改用 `CombatCardSelection` 流，而不是 `Transformations`。

= 卡牌洗牌（`Shuffle` 流）

- *战斗开始*：`CombatManager.SetUpCombat` 对每个玩家调用 `player.PopulateCombatState(player.RunState.Rng.Shuffle, state)`。玩家按 `state.Players` 顺序逐个把自己的整副牌 `UnstableShuffle` 进抽牌堆。多人时因为共享同一条 `Shuffle` 流，“谁先洗”会影响后面所有人的起手牌。
- *弃牌堆洗回*：`CardPileCmd.Shuffle` 把弃牌堆和当前抽牌堆合并成一张表，`StableShuffle(player.RunState.Rng.Shuffle)`（先排序再 Fisher–Yates）。
- 其余使用同一条流的还有：`Reboot`、`BottledPotential`（都走 `CardPileCmd.Shuffle`）、`Uproar`、`Catastrophe`、`BeatDown`、`StampedePower`、以及“把牌插到随机位置”的 `CardPilePosition.Random`（`NextInt(count+1)` 或 `NextItem`）。
- `Hook.ModifyShuffleOrder` 允许遗物重排结果（例如把某些牌置顶），但*不额外抽取 RNG*。

一个细节：`StableShuffle` 会先排序，所以“牌在牌堆里的物理顺序”不影响结果，只影响牌面集合与 RNG；而 `UnstableShuffle` 会受初始顺序影响。`TakeRandom` 会先把整表打乱再取前 k 张，所以消耗按表大小而不是 k。

= 战斗内其它流

#table(
  columns: (24%, 36%, 40%),
  table.header([*流*], [*触发者举例*], [*主要消耗模式*]),
  [`CombatCardGeneration`], [Attack Potion、Discovery、White Noise、Crossbow、Toolbox], [`GetDistinctForCombat` 走 `TakeRandom`（整表 `n-1`）；`GetForCombat` 走 `NextItem` × count],
  [`CombatPotionGeneration`], [Alchemize、Alchemical Coffer、Entropic Brew], [`PotionFactory.CreateRandomPotionInCombat`：1 `NextFloat` + 1 `NextItem`],
  [`CombatCardSelection`], [True Grit、Cinder、Hidden Gem、Mummified Hand、Bookmark、Drain Power], [`NextItem` / `StableShuffle` / `UnstableShuffle` / `TakeRandom` 混合],
  [`CombatEnergyCosts`], [Confusion、Snecko Oil、Slither], [`NextInt(4)`],
  [`CombatTargets`], [Bouncing Flask、Juggernaut、Lightning Orb、各类随机目标], [`NextItem`],
  [`CombatOrbs`], [（枚举存在，但代码库中*无调用点*）], [—],
  [`Niche`], [怪物初始 HP（`SetUniqueMonsterHpValue`）、CursedRun、Pandora's Box、Astrolabe、Whetstone 等], [`NextInt` / `NextItem(HashSet)` / `StableShuffle`],
)

`Niche` 值得特别注意：怪物 HP 在 `CombatState.CreateCreature` 里抽取，多个怪的 HP 抽取顺序取决于战场创建顺序，因此“谁先被放进场地”会改变后续所有抽 HP 的结果。此外 `ToughEgg` 召唤小怪时也用 `Niche.NextInt`。

`CombatOrbs` 目前是死流（没有调用点）。如果游戏后续给 Chaos 类效果接上它，搜索器需要更新。

= 敌人行动（`MonsterAi` 流）

敌人行动由一个“状态机图”决定：

- `MonsterModel.RollMove(targets)` → `MoveStateMachine.RollMove(targets, Creature, RunRng.MonsterAi)`。
- 每个怪物都有一个 `MonsterMoveStateMachine`，节点类型有三种：
  - `RandomBranchState`：按权重随机选一个后继。`GetNextState` 消耗 1 次 `NextFloat(max_weight)`（权重可以是动态 lambda，读取 state log、cooldown、重复次数）。
  - `ConditionalBranchState`：按条件选后继，*不消耗 RNG*。
  - `MoveState`：固定后继，*不消耗 RNG*。
- `MonsterMoveStateMachine.FindNextMoveState` 的逻辑：
  - 若 `!currentState.CanTransitionAway`，或“还没出过手且当前是 MoveState”，直接返回，*不抽任何 RNG*；
  - 否则循环 `GetNextState(owner, rng)`，直到落入一个 `MoveState`。每次经过一个 `RandomBranchState` 抽 1 次 `NextFloat`，经过条件/固定节点抽 0 次。
  因此“一次 RollMove 抽多少次”等于“这次转移路径上经过了多少个随机分支节点”，可以是 0、1 或更多。
- `MonsterModel.RunRng` 被设为整个 `RunState.Rng`，也就是说*所有敌人共享同一条 `MonsterAi` 流*。战斗中的 roll 顺序（敌人行动顺序）因此非常关键。
- 其它使用 `MonsterAi` 的地方：`Fabricator` 用 `NextItem` 选召唤目标；`FlutterPower` 会调用一次 `GetNextState` 来“偷看”下一步，这也会消耗流。

“敌人行动”不是单点随机，而是一个由状态机图结构决定的、随战斗历史变化的可变消耗序列。搜索器必须完整实现每个怪物的状态机图与权重函数。

= 其它：`UpFront`、事件、遭遇、遗物袋

== `UpFront`（跑开始时一次性消耗）

`InitializeNewRun`：

- 共享遗物袋 `Populate`：对每个稀有度的 deque 做 `UnstableShuffle`；
- 每个玩家的遗物袋 `Populate`：同样对 deque 做 `UnstableShuffle`。

`GenerateRooms`：

- 共享 Ancient 列表 `UnstableShuffle`；
- 对 act 2 及以后，逐个 `NextInt(count+1)` 决定分配多少个 shared Ancient；
- 每个 act 调 `GenerateRooms`：
  - 事件列表 `UnstableShuffle`（`n-1` 次）；
  - 三个 `GrabBag`（weak / normal / elite 遭遇）逐次 `GrabAndRemove(rng, predicate)`：每次尝试 1 个 `NextDouble`，predicate（不与上一个共享 tag）不满足会重抽；
  - boss `NextItem`；
  - Ancient `NextItem`（从已解锁的 Ancient 里选）；
- 若启用 DoubleBoss ascension，最后再 `NextItem` 选第二 boss。

注意 `GenerateRooms` 在跑开始时*一次性*为所有 act 生成，所以整局的遭遇/事件顺序在开局就定下来了（中途读档时会用保存的 `RoomSet`）。

== 事件 / 遭遇 / 怪物

- `EventModel`：开始时用 `Seed + (isShared ? 0 : slot) + hash64(eventId)` 建一条 RNG，事件内部所有随机（随机选项、随机奖励）都走它。
- `EncounterModel`：`GenerateMonstersWithSlots` 用 `Seed + TotalFloor + hash64(encounterId)` 建 RNG，用于 `GenerateMonsters`（同种怪的数量/组合/变体）。`TotalFloor` 表示进入该遭遇时的总层数。
- `MonsterModel.Rng`：每只怪一条 `Seed + col + row + actIndex + combatId` 的流，用于皮肤等“希望被同步但不影响玩法”的事情。

== 遗物袋与宝箱

- `RelicGrabBag` 在 `UpFront` 上整体洗牌；奖励时按稀有度从前端（普通奖励）或后端（商店）取，取走即移出，因此*同一局不会重复出现*（除非 refresh 重填）。取用本身不消耗 RNG。
- `TreasureRoomRelics`：多人宝箱里每个玩家各抽一个遗物稀有度（`RollRarity`，用 `Rewards`）并从共享袋取；投票/平局用 `TreasureRoomRelics` 流。


= 先古之民（Ancient）

每一幕的地图第 0 行都是一个先古之民事件。它不是普通事件：玩家进入时不会“抽”事件，而是由开局时已经生成的 `RoomSet.Ancient` 决定；然后该事件用自己的随机流从一组硬编码的遗物池里给出 3 个选项，玩家选 1 个。先古之民因此是 *seed-only* 的：选哪一位、给哪 3 个遗物，都只依赖种子（以及角色/牌组这类有限状态）。

== 选哪一位先古之民

`RunManager.GenerateRooms` 在开局、与遭遇/事件/boss 同一条 `UpFront` 流上完成：

- `UnlockState.SharedAncients`（全解锁时只有 `Darv`）先 `UnstableShuffle`；
- 从第 2 幕开始，每一幕做一次 `NextInt(list.Count + 1)`，取出前缀作为该幕的 shared 子集；取走的从列表里删除；
- 每一幕的 `ActModel.GenerateRooms` 末尾：
  `NextItem(GetUnlockedAncients(unlockState) ++ sharedSubset)`。

各幕的本地 Ancient 列表是固定的：

#table(
  columns: (18%, 40%, 42%),
  table.header([*幕*], [*本地 Ancient*], [*备注*]),
  [Overgrowth], [`NEOW`], [只有 Neow],
  [Underdocks], [`NEOW`], [只有 Neow],
  [Hive], [`OROBAS`, `PAEL`, `TEZCATARA`], [加上 shared 子集],
  [Glory], [`NONUPEIPE`, `TANX`, `VAKUU`], [加上 shared 子集],
)

所以实际结果里，第 2/3 幕可能是本地 Ancient，也可能是 `Darv`。选中的 Ancient 只是一个 `ModelId`，不会立刻消耗事件流。

== 遗物选项的事件流

进入先古之民时，`EventModel.BeginEvent` 建一条独立的流：

```
Rng(eventSeed = runSeed + (isShared ? 0 : slot) + hash64(Ancient.Entry))
```

Ancient 都是非 shared 事件；单人时 `slot = 0`。注意这条流的种子只含 `runSeed`、`slot` 和 Ancient 的 `Entry`，与 `UpFront` 的当前状态无关。因此“哪一位 Ancient”由 `UpFront` 决定，而“它给什么”由另一条流决定。

`Rng.NextItem` 在非空集合上消耗 1 次；`Rng.NextBool` 消耗 1 次；`UnstableShuffle(n)` 消耗 `n-1` 次。

== 各 Ancient 的选项生成

下面的“池”都是按声明顺序排列的；`NextItem` 是均匀抽取，`UnstableShuffle` 是 Fisher–Yates。所有 Ancient 都返回恰好 3 个选项。

=== Neow（第 1 幕）

1. 从 10 个诅咒/负面遗物里过滤掉 `IsAllowedAtNeow` 为 false 的，然后 `NextItem` 选 1 个：
   `CURSED_PEARL`、`DOWSING_ROD`、`HEFTY_TABLET`、`LARGE_CAPSULE`、`LEAFY_POULTICE`、`NEOWS_BONES`、`NEOWS_SACRIFICE`、`PRECARIOUS_SHEARS`、`SILKEN_TRESS`、`SILVER_CRUCIBLE`。
2. 从 14 个正面遗物里删掉与诅咒对应的上位/替代品：
   - `CURSED_PEARL` → 删 `GOLDEN_PEARL`
   - `HEFTY_TABLET` → 删 `ARCANE_SCROLL`
   - `LEAFY_POULTICE` → 删 `NEW_LEAF`
   - `PRECARIOUS_SHEARS` → 删 `PRECISE_SCISSORS`
   - `NEOWS_SACRIFICE` → 删 `PHIAL_HOLSTER`、`LOST_COFFER`
3. 三次独立的 `NextBool`，各把一对里的一个加入正面列表：
   - 若诅咒不是 `LARGE_CAPSULE`：`LAVA_ROCK` 或 `SMALL_CAPSULE`
   - `NUTRITIOUS_OYSTER` 或 `STONE_HUMIDIFIER`
   - `NEOWS_TALISMAN` 或 `POMANDER`
4. 再做一次 `IsAllowedAtNeow` 过滤（多人限制：单人保留 `WINGED_BOOTS`，多人保留 `MASSIVE_SCROLL`；`SILVER_CRUCIBLE` 仅单人；`KALEIDOSCOPE`/`SCROLL_BOXES` 需要卡池全解锁）。
5. 正面列表 `UnstableShuffle` 后取前 2 个，再追加第 1 步选出的诅咒，顺序为 `[正面1, 正面2, 诅咒]`。

所以 Neow 的前两个选项是“从同一张正面表里不放回地抽 2 个”，第三个是诅咒；正面表的大小和内容会随诅咒与三次 `NextBool` 改变。单人全解锁时正面表初始为 13 个（14 减去 `MASSIVE_SCROLL`），最终规模在 13–16 之间。

=== Orobas（第 2 幕）

1. 从“除当前角色外的 4 个角色”里 `NextItem` 选一个，记为 `C`。
2. `NextFloat()`：小于 `0.3333333f`（约 1/3）时选项为 `PRISMATIC_GEM`，否则为 `SEA_GLASS:<C>`。
3. 第一个选项从 `[ELECTRIC_SHRYMP, GLASS_EYE] ++ [上一步的选项]` 里均匀抽 1 个。
4. 第二个选项从 `[ALCHEMICAL_COFFER, DRIFTWOOD, RADIANT_PEARL, SAND_CASTLE]` 里抽。
5. 第三个选项从 `[TOUCH_OF_OROBAS, ARCHAIC_TOOTH]` 里抽；标准角色起始遗物/起始牌齐全，两个都可用。

`SEA_GLASS` 是“角色专属遗物”，同一张遗物对不同角色给出不同卡牌，因此输出需要带上角色 Entry。

=== Pael（第 2 幕）

1. 从 `[PAELS_FLESH, PAELS_HORN, PAELS_TEARS]` 均匀抽第一个选项。
2. 第二个选项的列表：
   - 基础 `[PAELS_WING]`；
   - 若牌组中有至少 3 张 `Goopy` 可附魔的牌（Defend 类），加入 `PAELS_CLAW`；
   - 若有至少 5 张可移除的牌，加入 `PAELS_TOOTH`；
   - 然后执行 `list.AddRange(list)`，也就是把当前列表 *整体再追加一遍*；
   - 最后加入 `PAELS_GROWTH`。
   因此 `PAELS_WING/CLAW/TOOTH` 的权重各是 `PAELS_GROWTH` 的 2 倍。例如两个条件都满足时：`[WING, CLAW, TOOTH, WING, CLAW, TOOTH, GROWTH]`，前三个各 2/7，Growth 1/7。
3. 第三个选项从 `[PAELS_EYE, PAELS_BLOOD]` 里抽；若玩家没有事件宠物，再加入 `PAELS_LEGION`。

=== Tezcatara（第 2 幕）

1. 从 `[VERY_HOT_COCOA, YUMMY_COOKIE]` 抽；若牌组里有任意 Basic 稀有度的 Strike，则加入 `NUTRITIOUS_SOUP`。
2. 从 `[BIIIG_HUG, STORYBOOK, TOASTY_MITTENS]` 抽。
3. 从 `[GOLDEN_COMPASS, PUMPKIN_CANDLE, TOY_BOX, SEAL_OF_GOLD]` 抽。

=== Nonupeipe（第 3 幕）

列表为 9 个遗物：
`BLESSED_ANTLER`、`BRILLIANT_SCARF`、`DELICATE_FROND`、`DIAMOND_DIADEM`、`FUR_COAT`、`GLITTER`、`JEWELRY_BOX`、`LOOMING_FRUIT`、`SIGNET_RING`。
若牌组中有至少 4 张 `Swift` 可附魔的牌，再加入 `BEAUTIFUL_BRACELET`。整体 `UnstableShuffle` 后取前 3 个。

=== Tanx（第 3 幕）

列表为 9 个遗物：
`CLAWS`、`CROSSBOW`、`IRON_CLUB`、`MEAT_CLEAVER`、`SAI`、`SPIKED_GAUNTLETS`、`TANXS_WHISTLE`、`THROWING_AXE`、`WAR_HAMMER`。
若牌组中有至少 3 张 `Instinct` 可附魔的牌（Attack），加入 `TRI_BOOMERANG`。整体 `UnstableShuffle` 后取前 3 个。

=== Vakuu（第 3 幕）

三个池各自独立洗牌，各取第一个：

- `[BLOOD_SOAKED_ROSE, WHISPERING_EARRING, FIDDLE]`
- `[PRESERVED_FOG, SERE_TALON, DISTINGUISHED_CAPE]`
- `[CHOICES_PARADOX, MUSIC_BOX, LORDS_PARASOL, JEWELED_MASK]`

洗牌消耗 `2 + 2 + 3 = 7` 次。

=== Darv（shared，第 2/3 幕可能出现）

Darv 的池按“集合”组织，每个集合只有一个遗物：

#table(
  columns: (25%, 30%, 45%),
  table.header([*遗物*], [*条件*], [*说明*]),
  [`ASTROLABE`], [总是], [],
  [`BLACK_STAR`], [总是], [],
  [`CALLING_BELL`], [总是], [],
  [`EMPTY_CAGE`], [总是], [],
  [`PANDORAS_BOX`], [没有 `ClearsPlayerDeck` 修正], [],
  [`RUNIC_PYRAMID`], [总是], [],
  [`SNECKO_EYE`], [总是], [],
  [`ECTOPLASM`], [`actIndex == 1`], [只在第 2 幕],
  [`SOZU`], [`actIndex == 1`], [只在第 2 幕],
  [`PHILOSOPHERS_STONE`], [`actIndex >= 1`], [第 2/3 幕],
  [`VELVET_CHOKER`], [`actIndex >= 1`], [第 2/3 幕],
)

生成步骤：

1. 对每个满足条件的集合，`NextItem(唯一遗物)` 消耗 1 次，得到该遗物；
2. 把这些遗物 `UnstableShuffle`；
3. `NextBool()`：50% 取前 2 个再加 `DUSTY_TOME`，50% 直接取前 3 个。

所以第 1 幕若 Darv 出现（一般不会）有 7 个集合；第 2 幕 11 个；第 3 幕 9 个。消耗分别是 `2×7 = 14`、`2×11 = 22`、`2×9 = 18` 次。

== 实现与假设

`include/sts2/Rooms.hpp` 与 `src/Rooms.cpp` 复刻开局 `UpFront` 的完整消耗顺序（遗物袋、shared Ancient 分配、每幕事件/遭遇/boss/Ancient），并给出每一幕的 `ActRooms`。`include/sts2/Ancients.hpp` 与 `src/Ancients.cpp` 复刻上面每个 Ancient 的选项生成，返回 `AncientOption{relic, character}`。

当前实现假设：

- 完全解锁（所有 epoch、所有角色、所有卡池）；未实现的解锁过滤会改变事件/遭遇列表长度和 shared Ancient 列表；
- 无 modifier 的标准新跑；
- 牌组相关的开关按角色 *起始牌组* 计算（`DeckGates`）。第 2/3 幕的真实牌组可能已经变化，调用方可以显式覆盖这些布尔量；
- `PlayerContext::playerCount` 用于 Neow 的单人/多人限制；单人时 `slot = 0`。多人时每个玩家的 `slot` 不同，事件流也不同。

`SeedProfile` 已经把每一幕的 `ActRooms` 与当前角色的 `AncientChoices` 挂在种子上，命令行工具 `seed_profile --character SILENT --rooms` 可以直接查看。

= 对 seed 搜索者的实务结论

- *顺序敏感*：同一条流上，调用顺序决定结果。不同抽取方法只要都消耗 1 次输出就可以互换位置吗？不行——虽然消耗量相同，但取样算法不同（`NextInt` 取整 vs `NextFloat` 的位切片）会给出不同的值，而结果是否符合条件又会影响后续调用（例如“稀有度 roll 出 Rare 会重置 pity 值”）。必须严格复刻调用序列。
- *可变消耗*：高斯（`NextGaussianInt/Double`）、`GrabBag` 的 predicate 拒绝、地图剪枝、`GrabIndex` 的存在性预判，都会让消耗次数随数据变化。不要只统计“平均次数”，要逐字复刻算法。
- *跨流独立，但可交错*：15 条流彼此独立，可以分别模拟；但某些系统（商店、遗物稀有度）会跨流交错使用 `Shops` 与 `Rewards`，搜索时要按真实顺序在正确的流上抽取。
- *counter 无意义*：不要把 `counter` 当作“第几次抽取”来算结果；要真正推进 xoshiro 状态。
- *展示顺序 ≠ 消耗顺序*：奖励按 `RewardsSetIndex`（Gold=1、Potion=2、Relic=3、Card=5）排序展示，但 RNG 按插入顺序消耗。
- *平台/版本一致性*：底层是整数运算加 `double`，但 `Math.Log/Sin/Cos/Sqrt/Round` 的跨平台尾数可能不同（`Math.Round` 是 banker's rounding）。做 seed 搜索时最好用与游戏相同的语义，或对候选种子做一次实测校验。
- *存档/读档无关*：RNG 状态（4 个 u64）被精确序列化，读档恢复后后续结果与不读档一致；`counter` 不参与。
- *多人差异*：`RunRngSet` 全队共享且由主机在开战时同步；`PlayerRngSet` 每玩家一份且不跨网同步，所以有些随机（事件里的 `_rngOverride`）会特意改用共享流避免分歧。搜索多人局时要注意每玩家流的基础种子加了槽位索引。
- *`old` 前缀*：旧存档种子用旧 32 位哈希作为 run 流基础种子，但 player 流仍用 xxh64 哈希整串；行为与普通种子不同。
- *死代码/死流*：`StandardActMap` 的 `EnsureRowsContainsPointType` / `AssignPointTypesToRandomRows` 未被调用；`CombatOrbs` 流当前无调用点。搜索器要么忽略它们，要么在游戏更新后重新核对。

= 附录 A：12 + 3 条流清单

#table(
  columns: (22%, 53%, 25%),
  table.header([*run 流*], [*用途*], [*hash64(name)*]),
  [`UpFront`], [跑开始时一次性生成：遭遇/事件/boss/遗物袋], [`1a8a7b60da243e80`],
  [`Shuffle`], [抽牌堆洗牌], [`2ad1d778c87c9714`],
  [`UnknownMapPoint`], [未知点房型 roll + odds], [`9800ef3164594356`],
  [`CombatCardGeneration`], [战斗中生成卡], [`a2a21eef44216b8e`],
  [`CombatPotionGeneration`], [战斗中生成药水], [`9ea3163cfeb05ac2`],
  [`CombatCardSelection`], [战斗中随机选牌], [`54a326ec000e7a0a`],
  [`CombatEnergyCosts`], [战斗内随机能量费], [`b2aee0c22bb1887f`],
  [`CombatTargets`], [战斗内随机目标], [`5ff62452ac6b3ac2`],
  [`MonsterAi`], [敌人行动选择], [`5aceec82dac3a1a7`],
  [`Niche`], [杂项一次性随机], [`1713d477d45afac5`],
  [`CombatOrbs`], [战斗内随机充能球（当前未使用）], [`917d243addb36d52`],
  [`TreasureRoomRelics`], [多人宝箱遗物分配/投票], [`5e4180a0a992aed6`],
)

#table(
  columns: (22%, 53%, 25%),
  table.header([*player 流*], [*用途*], [*hash64(name)*]),
  [`Rewards`], [奖励生成（卡牌稀有度、药水、金币、遗物稀有度）], [`20f3bf5504146bb3`],
  [`Shops`], [商店（选卡、定价、药水）], [`da13890c3383cb6b`],
  [`Transformations`], [卡牌转换结果], [`b8623d6522d877f5`],
)

= 附录 B：额外命名流派生公式

对每个名字 `N`，种子都是 `base + hash64(N)`（`base` 为 `Seed` 或 `Seed + slot`，取决于上下文）：

- `act_1_map` / `act_2_map` / `act_3_map`：`0ffb9c396e72be02` / `99340b7c8e70b466` / `9fcfc55e1de92c3d`
- `spoils_map`：`4a8eeb4df5358d74`
- `map_point_selection`：`67e571f7ae8246fb`
- `event_synchronizer`：`3869c75951d7e6e4`
- `act_selection`：`79a5d5299dc62d50`
- `bg_music`：`e6e1b5736962a82b`
- `map_jitter_0`：`48d95ad6fd318f54`
- 事件：`Seed + slot_or_0 + hash64(eventId)`
- 遭遇：`Seed + TotalFloor + hash64(encounterId)`
- 怪物：`Seed + col + row + actIndex + combatId`
- 战斗背景：`Seed + row + col*747`

= 附录 C：常见操作的消耗汇总

#table(
  columns: (38%, 22%, 40%),
  table.header([*操作*], [*流*], [*消耗*]),
  [开局生成整局遭遇/事件/boss/遗物袋], [`UpFront`], [一次性，含若干 `UnstableShuffle` 与带 predicate 的 `GrabAndRemove`],
  [生成一个 act 的地图], [`act_{n}_map`], [2 次高斯（可变）+ 7 次 `NextInt` + 路径 2×行数 + 类型分配 + 剪枝（可变）],
  [进入一个未知点], [`UnknownMapPoint`], [通常 1 次 `NextFloat`（新手保护时不抽）],
  [结束一次普通战斗（无药水）], [`Rewards`], [1 + 1 + 9 = 11 次],
  [结束一次精英（无药水）], [`Rewards`], [11 + 1（遗物稀有度）= 12 次],
  [逛一次商店], [`Shops` + `Rewards`], [交错；角色卡 5 张 + 无色 2 张 + 遗物 3 + 药水 3],
  [一张卡转换], [`Transformations`], [1 次 `NextItem`],
  [战斗开始洗牌], [`Shuffle`], [每个玩家 `n-1` 次],
  [弃牌堆洗回], [`Shuffle`], [`n-1` 次],
  [敌人选择下一次行动], [`MonsterAi`], [转移路径上的随机分支节点数量（0 起）],
  [怪物初始 HP], [`Niche`], [每只 `NextItem(HashSet)` 或 `NextInt`],
)
