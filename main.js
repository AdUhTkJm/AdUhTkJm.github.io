// Use var here to view these as attributes of globalThis
// This is to facilitate save_import()

var tick_persec = 5;
var $ = function(x) { return document.getElementById(x); }
var sprintf = (x, ...args) => args.length ? sprintf(x.replace('$', "" + args[0]), ...args.slice(1)) : x;
var divs = [];
var current_nav = 'bonfire';
var resources = ['food', 'wood', 'person', 'thought', 'stone', 'mineral', 'fur', 'discovered_area', 'paper',
    'copper', 'carbon', 'iron', 'glass', 'steel', 'gold', 'titanium', 'uranium', 'faith', 'insight', 'magic',
    'REE', 'dark_matter', 'element_126', 'antimatter', 'energy_crystal', 'unobtainium', 'ancient_bio',
    'book', 'structure', 'alloy', 'telescope', 'supply', 'superconductor',
    'memory', 'history', 'relic'];
var craftables = ['book', 'structure', 'alloy', 'telescope', 'supply', 'superconductor'];
var time = 0;
var debug = 0;
var physics = 0;
var chemistry = 0;
var maths = 0;
var magics = 0;
var electricity = 0;
var pollution = 0;
var pollution_guided = 0;
var elements = [['carbon', 3000], ['iron', 12000], ['gold', 20000], ['uranium', 250000]];
var genetics_upgrades = [];
var autoc_ratio = 0.95;
var autoc_storage = 0.8;
var autou_ratio = 0.2;
var autou_storage = 0.2;
var priorities = {};
var global_prod = [];
var highest_lvl = 0;
var last_memory = 0;
var memory_elapsed = 5000;

let dictionary = {
    'food': {
        name: '食物',
        storage: 1000,
        capacity: 5000,
        unlocked: true
    },
    'wood': {
        name: '木材',
        storage: 0,
        capacity: 1000,
        unlocked: true
    },
    'thought': {
        name: '思考',
        storage: 0,
        capacity: -1,
        unlocked: false
    },
    'stone': {
        name: '石头',
        storage: 0,
        capacity: 1500,
        unlocked: false
    },
    'fur': {
        name: '毛皮',
        storage: 0,
        capacity: 100,
        unlocked: false
    },
    'person': {
        name: '人数',
        storage: 5,
        capacity: 5,
        unlocked: true
    },
    'discovered_area': {
        name: '探索',
        storage: 0,
        capacity: -1,
        unlocked: false
    },
    'paper': {
        name: '纸',
        storage: 0,
        capacity: 2000,
        unlocked: false
    },
    'mineral': {
        name: '矿石',
        storage: 0,
        capacity: 1500,
        unlocked: false
    },
    'copper': {
        name: '铜',
        storage: 0,
        capacity: 500,
        unlocked: false
    },
    'carbon': {
        name: '煤炭',
        storage: 0,
        capacity: 250,
        unlocked: false
    },
    'iron': {
        name: '铁',
        storage: 0,
        capacity: 750,
        unlocked: false
    },
    'glass': {
        name: '玻璃',
        storage: 0,
        capacity: 160,
        unlocked: false
    },
    'steel': {
        name: '钢',
        storage: 0,
        capacity: 50,
        unlocked: false
    },
    'gold': {
        name: '贵金属',
        storage: 0,
        capacity: 100,
        unlocked: false
    },
    'titanium': {
        name: '钛',
        storage: 0,
        capacity: 1000,
        unlocked: false
    },
    'uranium': {
        name: '铀',
        storage: 0,
        capacity: 25,
        unlocked: false
    },
    'REE': {
        name: '稀土元素',
        storage: 0,
        capacity: 35000,
        spatial: true,
        unlocked: false
    },
    'dark_matter': {
        name: '暗物质',
        storage: 0,
        capacity: 20000,
        spatial: true,
        unlocked: false
    },
    'element_126': {
        name: '超重原子',
        storage: 0,
        capacity: 17500,
        spatial: true,
        unlocked: false
    },
    'antimatter': {
        name: '反物质',
        storage: 0,
        capacity: 1,
        spatial: true,
        unlocked: false
    },
    'energy_crystal': {
        name: '能量晶体',
        storage: 0,
        capacity: 100000,
        spatial: true,
        unlocked: false
    },
    'unobtainium': {
        name: '难得素',
        storage: 0,
        capacity: 350,
        spatial: true,
        unlocked: false
    },
    'ancient_bio': {
        name: '古代生物',
        storage: 0,
        capacity: -1,
        spatial: true,
        unlocked: false
    },
    'faith': {
        name: '信仰',
        storage: 0,
        capacity: -1,
        unlocked: false
    },
    'insight': {
        name: '洞察',
        storage: 0,
        capacity: 60,
        unlocked: false
    },
    'magic': {
        name: '法力',
        storage: 0,
        capacity: 60,
        unlocked: false
    },
    'memory': {
        name: '记忆',
        storage: 0,
        capacity: -1,
        special: true,
        unlocked: false
    },
    'history': {
        name: '历史',
        storage: 0,
        capacity: -1,
        special: true,
        unlocked: false
    },
    'relic': {
        name: '遗物',
        storage: 0,
        capacity: -1,
        special: true,
        unlocked: false
    },


    'fire': {
        name: '火堆',
        level: 0,
        ratio: 1.68,
        on: 0,
        togglable: true,
        clicked: function() {
            if (construct('fire') && !get("thought").unlocked) {
                unlock("thought"); add_navigation("thoughts"); push_button("discussion", "thoughts");
                setguide("空闲的人们围坐在火堆旁，开始思考。然而随着思考的增多，遗忘将不可避免，思考的产量也会受到阻碍。所幸思考并不会被消耗，因此只要慢慢积累，也可以积攒起不小的数量。");
            }
        },
        show: "温暖的火焰让大家更有干劲。<br>点燃后，空闲的人们将产出<b>思考</b>",
        mutant: function() {
            let consume = 2, buff = 2;
            if (get("heat_concentration").upgraded)
                consume *= 2, buff = 7.5;
            if (get("heat").upgraded)
                buff = 8;
            return sprintf("<br>每秒消耗$，令思考产量+$%", fuel_text(consume), buff);
        },
        price: [["wood", 10]],
        unlocked: false
    },
    'warehouse': {
        name: '仓库',
        level: 0,
        ratio: 1.3,
        on: 0,
        togglable: false,
        clicked: function() { construct('warehouse'); },
        show: "能够增加存储。",
        price: [["wood", 50]],
        unlocked: false
    },
    'warehouse_2': {
        name: '货仓',
        level: 0,
        ratio: 1.24,
        on: 0,
        togglable: false,
        clicked: function() { construct('warehouse_2'); },
        show: "能够少量增加存储。",
        price: [["structure", 3.5]],
        unlocked: false
    },
    'harbor': {
        name: '港口',
        level: 0,
        ratio: 1.26,
        on: 0,
        togglable: false,
        clicked: function() { construct('harbor'); },
        show: "能够大量增加存储。",
        price: [["alloy", 15], ["structure", 60]],
        unlocked: false
    },
    'workshop': {
        name: '工坊',
        level: 0,
        ratio: 1.35,
        on: 0,
        togglable: false,
        clicked: function() {
            if (construct('workshop') && !get("crafts").unlocked) {
                if (get("professional").on != 1) {
                    add_navigation("crafts");
                    setguide("解锁了合成材料与工匠。")
                }
                push_button("book", "crafts");
                push_button("map", "bonfire");
                if (!get('structure').unlocked && get('architecture_basics').upgraded)
                    push_button("structure", "crafts");
            }
        },
        show: "四个木头合成一个工作台。<br>合成效率+",
        mutant: function() {
            let value = (get("magic_workshop").upgraded ? 0.06 : 0.045) * (1 + get("titanium_workshop").upgraded * 0.2);
            return percentage(value);
        },
        price: [["wood", 40], ["stone", 160]],
        unlocked: false
    },
    'workshop_2': {
        name: '车间',
        level: 0,
        ratio: 1.35,
        togglable: false,
        clicked: function() { construct("workshop_2"); },
        show: "嘎嘎——机械——嘎嘎——<br>工匠的速度+10%<br>手动合成效率+3.5%，工匠合成效率+7%",
        price: [["iron", 110], ["stone", 150]],
        upgraded: false,
        unlocked: false
    },
    'map': {
        name: '地图',
        level: 0,
        ratio: 1.4,
        togglable: false,
        clicked: function() { construct("map"); },
        show: "将过往的探索知识记录进地图。<br>探索产出增加8%<br><b>建造地图不消耗探索</b>",
        price: [["discovered_area", 50]],
        upgraded: false,
        unlocked: false
    },
    'paper_factory': {
        name: '造纸厂',
        level: 0,
        ratio: 1.22,
        on: 0,
        togglable: true,
        clicked: function() { construct('paper_factory'); },
        show: "用于造纸。",
        mutant: function() {
            let text = sprintf("<br>每秒消耗$，产出1纸", fuel_text(5));
            return text;
        },
        price: [["wood", 80], ["stone", 40]],
        unlocked: false
    },
    'wood_factory': {
        name: '木材厂',
        level: 0,
        ratio: 1.24,
        on: 0,
        togglable: false,
        clicked: function() {  construct('wood_factory'); },
        show: "咔咔响着的工具正在加工木材。<br>木材产量+20%",
        price: [["wood", 30], ["stone", 105], ["iron", 125]],
        unlocked: false
    },
    'mine': {
        name: '矿井',
        level: 0,
        ratio: 1.28,
        on: 0,
        togglable: false,
        clicked: function() { if (construct('mine') && !get("mineral").unlocked) { unlock("mineral"); push_button("miner", "society"); } },
        show: "昏暗的矿井里摇曳着油灯。<br>允许开采<b>矿石</b><br>石头与矿石产量+20%",
        mutant: function() {
            let text = "";
            if (get("carbon_reveal").upgraded)
                text += "<br>每秒产出0.25煤";
            if (get("uranium_extraction").upgraded)
                text += "与0.0007铀";
            return text;
        },
        price: [["wood", 125]],
        unlocked: false
    },
    'smelter': {
        name: '冶炼窑',
        level: 0,
        ratio: 1.9,
        on: 0,
        togglable: true,
        clicked: function() { if (!construct('smelter')) return; unlock("copper"); },
        show: "用于冶炼矿石。<br>",
        mutant: function() {
            let text = sprintf("每秒消耗$以及2矿石，产出各类矿物", fuel_text(5));
            if (!get("mineral_research").upgraded)
                return text;
            let x = get("discovered_area").storage;
            for (let i = 0; i < elements.length; i++)
                if (elements[i][1] > x)
                    return text + "<br>还需要" + format(elements[i][1] - x) + "探索才能发现下一个元素";
            return text + "<br>所有自然元素资源都已经发现";
        },
        price: [["stone", 200], ["mineral", 200]],
        unlocked: false
    },
    'small_house': {
        name: '小屋',
        level: 0,
        ratio: 2.2,
        on: 0,
        togglable: false,
        clicked: function() { let num = construct("small_house"); get("person").storage += num; get("person").capacity += num; },
        show: "吸引更多无家可归的人入住。<br>每个小屋可以居住1个人。",
        price: [["wood", 60], ["stone", 30]],
        unlocked: false
    },
    'apartment': {
        name: '公寓',
        level: 0,
        ratio: 1.55,
        on: 0,
        togglable: false,
        clicked: function() { let num = construct("apartment"); get("person").storage += 3 * num; get("person").capacity += 3 * num; },
        show: "通了电的公寓能够让人们生活得更快乐。<br>每个公寓可以居住3个人，同时提升1%稳定度。<br>消耗2电力；电力不足时依然可用，但稳定度-3%",
        price: [["glass", 300], ["alloy", 20], ["structure", 135]],
        unlocked: false
    },
    'library': {
        name: '图书馆',
        level: 0,
        ratio: 1.27,
        on: 0,
        togglable: false,
        clicked: function() {
            if (construct('library') && !get("book_categorization").unlocked) {
                push_button('book_categorization', 'thoughts');
                push_button("writing_training", "thoughts");
            }
        },
        mutant: function() {
            let base = "";
            let buff = 1 + 7.5 * get("zlibrary").upgraded;
            if (get("writing_training").upgraded)
                base += sprintf("<br>使书的成本-$%", 1 * buff);
            if (get("education").upgraded)
                base += sprintf("<br>每秒产出$书", buff == 1 ? 0.02 : format(0.02 * buff));
            return base;
        },
        show: "存放各种书籍并且分类整理。<br>增加书的效果以及效果上限",
        price: [["wood", 30], ["stone", 15], ["paper", 20]],
        unlocked: false
    },
    'research_lab': {
        name: '研究所',
        level: 0,
        ratio: 1.38,
        on: 0,
        togglable: false,
        clicked: function() { construct('research_lab'); },
        show: "放着很多实验装置，看上去让人忍不住摸一摸。<br>商讨的效果增加10%<br>遗忘的指数减少0.0025",
        price: [["copper", 50], ["iron", 35], ["wood", 200], ["stone", 60]],
        unlocked: false
    },
    'observatory': {
        name: '天文台',
        level: 0,
        ratio: 1.2,
        on: 0,
        togglable: false,
        clicked: function() { construct('observatory'); },
        show: "晚上可以通过望远镜看到满天的星星。<br>思考产量增加75%",
        price: [["copper", 4000], ["iron", 6000], ["glass", 3750], ["structure", 600]],
        unlocked: false
    },
    'university': {
        name: '大学',
        level: 0,
        ratio: 1.22,
        on: 0,
        togglable: false,
        clicked: function() { construct('university'); },
        show: "风景优美，适合摸鱼。<br>每个大学使每名教授的合成速度+10%",
        mutant: function() {
            let base = "";
            if (get("research_fund").upgraded)
                base += "，同时每秒产出0.25思考";
            if (get("techno_explosion").upgraded)
                base += "<br>每个大学每秒产出0.001洞察，并且使洞察上限+60";
            return base;
        },
        price: [["stone", 6000], ["book", 100], ["structure", 125]],
        unlocked: false
    },
    'furnace': {
        name: '熔炉',
        level: 0,
        ratio: 1.35,
        on: 0,
        togglable: true,
        clicked: function() { construct('furnace'); },
        show: "构建一个大熔炉，一次可以塞很多东西进去。",
        mutant: function() {
            let text = "";
            text += sprintf("<br>每秒消耗$以及3石头，产出0.5玻璃", fuel_text(15));
            if (get("steel").unlocked)
                text += sprintf("<br>还可以消耗5矿石，冶炼各类金属");
            return text;
        },
        price: [["iron", 150], ["copper", 250], ["structure", 30]],
        unlocked: false
    },
    'blast_furnace': {
        name: '冶炼高炉',
        level: 0,
        ratio: 1.35,
        on: 0,
        togglable: true,
        clicked: function() { construct('blast_furnace'); },
        show: "专门用来冶炼贵金属的炉子。",
        mutant: function() {
            let text = sprintf("<br>每秒消耗$以及12.5矿石，冶炼贵金属", fuel_text(40));
            return text;
        },
        price: [["steel", 100], ["copper", 300], ["iron", 250], ["structure", 60]],
        unlocked: false
    },
    'factory': {
        name: '工厂',
        level: 0,
        ratio: 1.35,
        on: 0,
        togglable: true,
        clicked: function() {
            if (construct('factory') && get("element_analysis").upgraded && !get("titanium").unlocked) {
                unlock("titanium");
                push_button("titanium_equip", "thoughts");
                push_button("titanium_workshop", "thoughts");
            }
        },
        show: "允许熔炼钛。<br>合成效率+10%<br>每秒产生1污染<br>消耗2电力",
        price: [["steel", 400], ["alloy", 50], ["structure", 75]],
        unlocked: false
    },
    'collider': {
        name: '对撞机',
        level: 0,
        ratio: 1.26,
        on: 0,
        togglable: true,
        clicked: function() {
            if (construct("collider") && !get("atomic_fission").unlocked)
                push_button("atomic_fission", "thoughts");
        },
        show: "通过高能粒子对撞，研究更深层的知识。",
        mutant: function() {
            let doubled = get("heavy_element_collision").upgraded;
            let base = sprintf("<br>科学加成提高$%", doubled ? 3 : 1.5);
            if (doubled)
                base += "<br>每秒消耗5贵金属与0.015铀";
            return base + "<br>消耗15电力";
        },
        price: [["copper", 13500], ["titanium", 1800], ["structure", 2000], ["book", 1000]],
        unlocked: false
    },
    'crossroad': {
        name: '交通枢纽',
        level: 0,
        ratio: 1.31,
        on: 0,
        togglable: true,
        clicked: function() { construct('crossroad'); },
        show: "物资的运输更加方便了。<br>每秒产生1.5污染",
        mutant: function() {
            let flight = get("flight").upgraded;
            let text = sprintf("<br>每秒消耗$，使大部分物资产量+$%，储量+$%", fuel_text(175 * (1 + 0.5 * flight)), 1.5 * (1 + 1.5 * flight), 3 * (1 + 1.5 * flight));
            return text;
        },
        price: [["alloy", 70], ["copper", 3000]],
        unlocked: false
    },
    'bank': {
        name: '银行',
        level: 0,
        ratio: 1.27,
        on: 0,
        togglable: false,
        clicked: function() {
            if (!construct('bank')) return;
        },
        show: "有人发现，贵金属堆在仓库里会慢慢变少。<br>为了解决这个问题，银行应运而生。<br>提升贵金属上限",
        price: [["gold", 2.5], ["paper", 60], ["iron", 50], ["structure", 10]],
        unlocked: false
    },
    'brewery': {
        name: '酿酒厂',
        level: 0,
        ratio: 1.64,
        on: 0,
        togglable: true,
        clicked: function() { if (!construct('brewery')) return; },
        show: "把吃不完的食物都酿成酒。",
        mutant: function() {
            let text = sprintf("<br>为全局产量提供$%加成，但是食物产量-$%", get("magic_alcohol").upgraded ? 4 : 2, get("magic_alcohol").upgraded ? 6 : 3);
            return text;
        },
        price: [["food", 2500], ["copper", 700], ["structure", 18]],
        unlocked: false
    },
    'chemlab': {
        name: '化学实验室',
        level: 0,
        ratio: 1.3,
        on: 0,
        togglable: false,
        clicked: function() { construct('chemlab'); },
        show: "与研究所不同，里面摆的仪器都闪闪发光。<br>遗忘的分母增加5%，燃料消耗减少1.5%",
        price: [["steel", 350], ["copper", 60], ["glass", 150], ["structure", 30]],
        unlocked: false
    },
    'power_station': {
        name: '发电站',
        level: 0,
        ratio: 1.22,
        on: 0,
        togglable: true,
        clicked: function() { construct('power_station'); },
        show: "通过内燃机带动转子，切割磁感线而产生电流。",
        mutant: function() {
            let text = sprintf("<br>每秒消耗$，产出0.7污染，电力+5", fuel_text(75));
            return text;
        },
        price: [["steel", 250], ["copper", 640], ["stone", 1100], ["alloy", 15]],
        unlocked: false
    },
    'wind_power_station': {
        name: '风力发电站',
        level: 0,
        ratio: 1.3,
        on: 0,
        togglable: true,
        clicked: function() { construct('wind_power_station'); },
        show: "利用清洁的能源发电。<br>电力+3",
        price: [["wood", 4000], ["stone", 6400], ["structure", 40]],
        unlocked: false
    },
    'fission_powerplant': {
        name: '裂变反应堆',
        level: 0,
        ratio: 1.36,
        on: 0,
        togglable: true,
        clicked: function() { construct('fission_powerplant'); },
        show: "利用原子的能量。<br>铀上限+25<br>每秒产出30污染，电力+45<br>每秒消耗0.1铀",
        price: [["steel", 2500], ["titanium", 1750], ["structure", 3000], ["alloy", 300]],
        unlocked: false
    },
    'cathedral': {
        name: '教堂',
        level: 0,
        ratio: 1.45,
        on: 0,
        togglable: false,
        clicked: function() { construct('cathedral'); },
        show: "净化心灵的场所。<br>每个居民每秒产出1信仰",
        mutant: function() {
            let base = "";
            if (get("sincerity").upgraded) 
                base += "<br>每个教堂增加1%稳定度，并且使信仰加成提升1%";
            if (get("arcane").upgraded)
                base += "<br>每个教堂每秒产出0.001法力，并且使法力上限+60";
            return base;
        },
        price: [["wood", 1125], ["stone", 2700], ["glass", 450], ["fur", 150], ["structure", 50]],
        unlocked: false
    },
    'theater': {
        name: '剧场',
        level: 0,
        ratio: 1.45,
        on: 0,
        togglable: false,
        clicked: function() { construct('theater'); },
        show: "娱乐场所，雅俗共赏。<br>稳定度+2%",
        price: [["wood", 2025], ["stone", 3800], ["glass", 600], ["fur", 80], ["structure", 125]],
        unlocked: false
    },
    'AsHg_collector': {
        name: '砷汞富集器',
        level: 0,
        ratio: 2.1,
        on: 0,
        togglable: true,
        collected: 0,
        clicked: function() { construct('AsHg_collector'); },
        show: "收集有毒物质，主要由工业设施产生。<br>每秒吸收12污染，但消耗2电力<br>",
        mutant: function() { return "已经收集了" + format(get("AsHg_collector").collected) + "污染物" },
        price: [["steel", 2000], ["copper", 10000], ["alloy", 300], ["titanium", 175], ["structure", 500]],
        unlocked: false
    },

    /*

    -- SPACE

    */
   
    'moon_base': {
        name: '月球基地',
        level: 0,
        ratio: 1.26,
        on: 0,
        togglable: true,
        spatial: "moon",
        require: 3,
        clicked: function() {
            if (construct('moon_base') && !get("REE").unlocked)
                unlock("REE");
        },
        show: "巨大的综合设施，支持研究与生活。",
        mutant: function() {
            let text = sprintf("<br>每秒消耗$，产出0.2稀土元素<br>稀土元素上限+3500<br>需要3名宇航员<br>消耗18电力", fuel_text(5000));
            return text;
        },
        price: [["steel", 18000], ["alloy", 1800], ["structure", 6000], ["glass", 5000]],
        unlocked: false
    },
    'moon_living_quarter': {
        name: '生活区',
        level: 0,
        ratio: 1.28,
        on: 0,
        togglable: true,
        spatial: "moon",
        require: 0,
        clicked: function() {
            let num = construct('moon_living_quarter');
            if (!num)
                return;
            get("person").storage += 2 * num;
            get("person").capacity += 2 * num;
        },
        show: "两个人在月球上定居。<br>食物运输损耗极其严重，每秒需要额外消耗0.01补给",
        price: [["mineral", 64000], ["carbon", 8000], ["REE", 3000], ["food", 500000]],
        unlocked: false
    },
    'moon_exotic_lab': {
        name: '外星材料实验室',
        level: 0,
        ratio: 1.28,
        on: 0,
        togglable: true,
        spatial: "moon",
        require: 2,
        clicked: function() {
            if (construct("moon_exotic_lab") && !get("dark_matter").unlocked)
                unlock("dark_matter");
        },
        show: "研究源于外星的材料。<br>每秒消耗80书，产出0.1暗物质<br>需要2名宇航员<br>消耗4电力",
        price: [["steel", 22000], ["copper", 18000], ["iron", 12000], ["titanium", 3000], ["REE", 7000]],
        unlocked: false
    },
    'moon_pollution_tube': {
        name: '地外污染管道',
        level: 0,
        ratio: 1.28,
        on: 0,
        togglable: false,
        spatial: "moon",
        require: 0,
        clicked: function() {
            construct("moon_pollution_tube");
        },
        show: "将无法处理的污染排放到太空。<br>每秒减少60污染",
        price: [["alloy", 2000], ["dark_matter", 1000], ["telescope", 5000]],
        unlocked: false
    },
    'LHC': {
        name: '大型强子对撞机',
        level: 0,
        on: 0,
        ratio: 1,
        togglable: false,
        spatial: "moon",
        clicked: function() {
            if (get("LHC").level >= 25)
                return;
            let success = construct("LHC");
            if (success && get("LHC").level >= 25) {
                push_button("LHC_consumption", "thoughts");
                push_button("antimatter_research", "thoughts");
            }
        },
        show: "将两个原子对撞，期待核的融合。<br>每秒产出0.0035超重原子<br>",
        mutant: function() {
            let text = "";
            if (get("LHC").level >= 25) {
                text += "<font color='green'>已建成</font>";
            } else
                text += sprintf("<font color='red'>还需要建造$段</font>", 25 - get("LHC").level);
            return text;
        },
        price: [["titanium", 1500], ["steel", 18000], ["alloy", 875], ["structure", 3000], ["gold", 7200], ["uranium", 25]],
        unlocked: false
    },
    'mars_reform_device': {
        name: '火星重塑器',
        level: 0,
        ratio: 1,
        on: 0,
        togglable: false,
        spatial: "mars",
        require: 0,
        clicked: function() {
            if (get("mars_reform_device").level >= 100)
                return;
            let success = construct("mars_reform_device");
            if (success && get("mars_reform_device").level >= 100) {
                get("person").storage += 16;
                push_button("mars_shipment", "thoughts");
                push_button("mars_manufacture", "thoughts");
                push_button("mars_site_research", "thoughts");
                setguide("火星已经可以入住。对于如何开发火星，人们涌现出了许多思考。");
            }
        },
        show: "重塑火星的大气与温度，让其与地球一致。<br>",
        mutant: function() {
            let text = "";
            let self = get("mars_reform_device");
            if (self.level == 100) {
                text += "<font color='green'>已建成</font>";
                text += "<br>火星已经完全重塑。<br>可供16人入住";
            } else {
                text += sprintf("<font color='red'>还需要建成$%；建成后可供16人入住</font><br>构建1%火星重塑器。", 100 - self.level);
            }
            return text;
        },
        price: [["steel", 2500], ["titanium", 1200], ["uranium", 175], ["element_126", 100], ["REE", 600], ["supply", 1],  ["superconductor", 75]],
        unlocked: false
    },
    'mars_cargo': {
        name: '货运港',
        level: 0,
        ratio: 1.28,
        on: 0,
        togglable: false,
        spatial: "mars",
        require: 0,
        clicked: function() {
            construct("mars_cargo");
        },
        show: "从港口向整个太阳系运输物资。<br>大幅度增加存储<br>使补给消耗-1%",
        price: [["dark_matter", 1250], ["discovered_area", 7500000]],
        unlocked: false
    },
    'mars_unmanned_factory': {
        name: '无人组装厂',
        level: 0,
        ratio: 1.17,
        on: 0,
        togglable: false,
        spatial: "mars",
        require: 0,
        clicked: function() {
            construct("mars_unmanned_factory");
        },
        show: "组装各类自动机械，减少驻留太空的人口。<br>计算宇航员时，额外+2",
        price: [["wood", 80000], ["stone", 120000], ["steel", 7500], ["copper", 8500]],
        unlocked: false
    },
    'mars_site': {
        name: '火星基地',
        level: 0,
        ratio: 1.31,
        on: 0,
        togglable: true,
        spatial: "mars",
        require: 2,
        clicked: function() {
            if (!construct("mars_site"))
                return;
            if (!get("relics_station").unlocked) {
                push_button("relics_station", "space_mars");
            }
        },
        show: "提取古代火星生物的DNA，并尝试克隆它们。<br>每秒产出0.001古生物<br><font color='red'>这个产出无法被大部分加成影响</font><br>需要2名宇航员<br>消耗16电力",
        price: [["ancient_bio", 1], ["element_126", 775], ["alloy", 1010], ["structure", 3680]],
        unlocked: false
    },
    'relics_station': {
        name: '火星遗物站',
        level: 0,
        ratio: 1.45,
        on: 0,
        togglable: false,
        spatial: "mars",
        require: 0,
        clicked: function() {
            construct("relics_station");
        },
        show: "提取古代生命的遗物。<br>古代生命的产量+5%<br><font color='green'>进行高级重置时，额外获得1<b>遗物</b></font>",
        price: [["ancient_bio", 2500]],
        unlocked: false
    },
    'mercury_station': {
        name: '水星科考站',
        level: 0,
        ratio: 1.26,
        on: 0,
        togglable: true,
        spatial: "mercury",
        require: 1,
        clicked: function() {
            construct("mercury_station");
        },
        show: "利用水星的高温，进行各种制造活动。",
        mutant: function() {
            let text = "";
            let elec = 7;
            if (get("energy_crystal_research").upgraded)
                text += "<br>每秒消耗250矿石，0.3铀与0.03超重元素，制造1能量晶体<br>这个消耗不视作燃料";
            if (get("dyson_sphere").upgraded) {
                text += "<br>使戴森球的成本-3%";
                elec += 1;
            }
            return text + sprintf("<br>需要1名宇航员<br>消耗$电力", elec);
        },
        price: [["supply", 400], ["superconductor", 440], ["structure", 25000]],
        unlocked: false
    },
    'mercury_storage': {
        name: '水星储存站',
        level: 0,
        ratio: 1.31,
        on: 0,
        togglable: false,
        spatial: "mercury",
        require: 0,
        clicked: function() {
            construct("mercury_storage");
        },
        show: "绝大多数资源的储量+8%<br>能量晶体的储量+100.000K",
        price: [["stone", 525000], ["energy_crystal", 100000]],
        unlocked: false
    },
    'asteroid_station': {
        name: '小行星带采矿站',
        level: 0,
        ratio: 1.29,
        on: 0,
        togglable: true,
        spatial: "asteroid",
        require: 6,
        clicked: function() {
            construct("asteroid_station");
        },
        show: "在小行星带采集从未见过的合金。<br>每秒开采0.0008难得素<br>难得素的储量上限+100<br>每秒消耗70能量晶体<br>需要6名宇航员<br>消耗17.5电力",
        price: [["titanium", 11000], ["REE", 60000], ["alloy", 7000]],
        unlocked: false
    },
    'dyson_sphere': {
        name: '戴森球',
        level: 0,
        ratio: 1,
        on: 0,
        togglable: false,
        spatial: "sun",
        require: 0,
        clicked: function() {
            if (get("dyson_sphere").level >= 100)
                return;
            let success = construct("dyson_sphere");
            if (success && get("dyson_sphere").level >= 100) {
                push_button("dyson_experiment", "thoughts");
                setguide("有些人依旧不满意戴森球的效率。他们提出了利用戴森球的更高效的方法。");
            }
        },
        show: "围绕太阳建造戴森球，提取近乎无穷的能量。<br>",
        mutant: function() {
            let text = "";
            let self = get("dyson_sphere");
            if (self.level == 100) {
                text += "<font color='green'>已建成</font>";
                text += sprintf("<br>戴森球已经完成。<br>提供$电力，这个值随着时间增加", format(time / 600));
            } else {
                text += sprintf("<font color='red'>还需要建成$%</font><br>构建1%戴森球。", 100 - self.level);
            }
            return text;
        },
        price: [["titanium", 10000], ["steel", 30000], ["glass", 7000], ["energy_crystal", 2048], ["superconductor", 1000], ["unobtainium", 750], ["structure", 20000]],
        unlocked: false
    },


    /*

    -- BASIC THOUGHTS

    */

    'discussion': {
        name: '商讨',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if(!upgrade('discussion')) return; push_button("storage_upgrade", "thoughts"); push_button("sun_indicator", "thoughts"); push_button("stoneage", "thoughts"); },
        show: "大家意识到聚集在一起讨论可能有助于知识的获取。<br>每个空闲的人额外增加5%思考产出",
        price: [["thought", 1]],
        upgraded: false,
        unlocked: false
    },
    'storage_upgrade': {
        name: '仓储',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('storage_upgrade')) return; push_button('warehouse', 'bonfire'); },
        show: "用木头划分一块地方，用来存储资源。<br>解锁<b>仓库</b>",
        price: [["thought", 5]],
        upgraded: false,
        unlocked: false
    },
    'sun_indicator': {
        name: '日晷',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('sun_indicator')) return; push_button('record', 'thoughts'); push_button('directions', 'thoughts') },
        show: "你们的自然科学知识极少，但仍然知道太阳东升西落。",
        price: [["thought", 10]],
        upgraded: false,
        unlocked: false
    },
    'directions': {
        name: '方向辨别',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('directions')) return; },
        show: "天上的星体能够指引方向。<br>白天可以依靠太阳，夜晚则是依靠那些像勺子一样的七颗星星。<br>探索产量+50%",
        price: [["thought", 85]],
        upgraded: false,
        unlocked: false
    },
    'record': {
        name: '记录',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('record')) return;  },
        show: "用树枝画出符号或图画，来减缓遗忘的速度。<br>遗忘的分母+900%<br><b>商讨</b>的效果提升至10%",
        price: [["thought", 50]],
        upgraded: false,
        unlocked: false
    },
    'stoneage': {
        name: '石器时代',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('stoneage')) return; unlock('stone'); push_button('stone_sword', 'thoughts'); push_button('stone_ax', 'thoughts');
                                push_button('slingshot', 'thoughts'); push_button('quarry_worker', 'society'); push_button('workshop', 'bonfire'); push_button('craftsman', 'thoughts'); },
        show: "你们明白石头是最容易利用的资源。<br>解锁<b>采石者</b>",
        price: [["thought", 20]],
        upgraded: false,
        unlocked: false
    },
    'craftsman': {
        name: '工匠',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('craftsman')) return;
            for (let i = 0; i < craftables.length; i++) {
                let res = craftables[i];
                if (get(res).unlocked && !get("craftsman_" + res).unlocked) {
                    push_button("craftsman_" + res, "society");
                }
            }
        },
        show: "指派工匠在工坊里制作工艺品。",
        price: [["thought", 105]],
        upgraded: false,
        unlocked: false
    },
    'stone_sword': {
        name: '石剑',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('stone_sword')) return; push_button('adventurer', 'society'); push_button('botany_knowledge', 'thoughts');
                                unlock('discovered_area'); push_button('first_contact', 'thoughts'); },
        show: "不算很锋利，但是配上你们这群年轻人的臂力，也足够刺穿野兽的皮肤。<br>解锁<b>探索</b>",
        price: [["thought", 30], ["stone", 150], ["wood", 100]],
        upgraded: false,
        unlocked: false
    },
    'stone_ax': {
        name: '石斧',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('stone_ax')) return; unlock('fur'); },
        show: "不仅是砍伐树木，还能帮助采集者狩猎一些小东西。<br>采集者的食物与木材产量增加50%<br>以食物产量的0.5%产出<b>毛皮</b>",
        price: [["thought", 50], ["stone", 200], ["wood", 150]],
        upgraded: false,
        unlocked: false
    },
    'slingshot': {
        name: '弹弓',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('slingshot')) return; get("collector").name = "猎人"; },
        show: "你们能运用弹弓来达到比手扔石头更好的效果。<br>采集者变为<b>猎人</b>，食物产量增加50%，但每秒消耗2石头",
        price: [["thought", 120], ["fur", 50]],
        upgraded: false,
        unlocked: false
    },
    'botany_knowledge': {
        name: '植物研究',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('botany_knowledge')) return; push_button("carnival", "thoughts"); },
        show: "你们学会了运用探索中发现的植物。<br>探索能够给予记忆少量的加成",
        mutant: function() {
            let text = "";
            if (!get("memory").unlocked)
                text += "<br><b>记忆</b>还没有解锁；它会随着游戏进程自然解锁。";
            return text;
        },
        price: [["thought", 350]],
        upgraded: false,
        unlocked: false
    },
    'first_contact': {
        name: '初次接触',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('first_contact')) return; push_button('paper_craft', 'thoughts'); push_button('copper_usage', 'thoughts');
                push_button('architecture_basics', 'thoughts'); push_button('basic_science', 'thoughts'); get("person").storage++; get("person").capacity++;  },
        show: "你们找到了一个逃难的人，他愿意加入你们。<br>他看起来博学多才，你们可以从他那里得到各种各样的知识。<br>人数+1",
        price: [["discovered_area", 80 + 40 * (Math.random() - 0.5)]],
        upgraded: false,
        unlocked: false
    },
    'architecture_basics': {
        name: '建筑基础',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('architecture_basics')) return; push_button('small_house', 'bonfire');
                push_button('warehouse_2', 'bonfire'); if (get('crafts').unlocked) push_button('structure', 'crafts'); },
        show: "能够建造一个人的容身之所，还能够搭建一些大型结构。<br>解锁<b>小屋</b>与<b>货仓</b>",
        price: [["thought", 90]],
        upgraded: false,
        unlocked: false
    },
    'paper_craft': {
        name: '造纸术',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('paper_craft')) return; unlock('paper'); push_button('paper_factory', 'bonfire'); push_button('library', 'bonfire'); },
        show: "你们学会了用木材造出纸来。<br>解锁<b>造纸厂</b>",
        price: [["thought", 75]],
        upgraded: false,
        unlocked: false
    },
    'book_categorization': {
        name: '图书分类法',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('book_categorization')) return; },
        show: "更加细致而严格的图书分类法。<br>加强图书馆的效率，并增强它抑制遗忘的作用",
        price: [["thought", 180], ["paper", 60]],
        upgraded: false,
        unlocked: false
    },
    'writing_training': {
        name: '写作训练',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('writing_training')) return; },
        show: "图书馆将会开设写作训练班。<br>每个图书馆可以让书的成本-1%（叠乘）",
        price: [["thought", 200], ["paper", 120], ["fur", 30]],
        upgraded: false,
        unlocked: false
    },

    /*
    
    -- SCIENTIFIC

    */

    'basic_science': {
        name: '基础科学',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('basic_science')) return; push_button('+-*/', 'thoughts'); push_button('newton_1', 'thoughts'); push_button("genetics", "thoughts"); },
        show: "你们懂得了世界运行的规律，当然，是最基本的那一部分。<br>解锁一系列科学思考；增加书的效果并提升它的作用上限。",
        price: [["thought", 100], ["book", 3]],
        upgraded: false,
        unlocked: false
    },

    /*
    
    -- MATHS

    */

    '+-*/': {
        name: '四则运算',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('+-*/')) return; maths++; push_button('math_basics', 'thoughts'); },
        show: "<b>数学研究</b><br>你们理解了简单的运算。<br>思考产量提升30%",
        price: [["thought", 200], ["book", 5]],
        upgraded: false,
        unlocked: false
    },
    'math_basics': {
        name: '数学基础',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('math_basics')) return; maths++; get("book").price[0][1] *= 0.5; get("book").price[1][1] *= 0.5;
            push_button('rationals', 'thoughts'); },
        show: "<b>数学研究</b><br>你们了解了数学的基础，并且建立了基本的逻辑能力。<br>书的价格降低50%",
        price: [["thought", 250], ["book", 10]],
        upgraded: false,
        unlocked: false
    },
    'rationals': {
        name: '有理数',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('rationals')) return; maths++; push_button("algebra", "thoughts") },
        show: "<b>数学研究</b><br>从整数过渡到分数的一大步。<br><b>前置研究，无效果</b>",
        price: [["thought", 280], ["book", 23.5]],
        upgraded: false,
        unlocked: false
    },
    'algebra': {
        name: '代数',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('algebra')) return; maths++; push_button_if("newton_2", "thoughts", "newton_3");
                                push_button("functions", "thoughts"); push_button('equations', 'thoughts'); },
        show: "<b>数学研究</b><br>a与b和的平方大于等于四倍的它们的积。<br>书对思考产出的效果增加15%",
        price: [["thought", 340], ["book", 30]],
        upgraded: false,
        unlocked: false
    },
    'equations': {
        name: '方程解法',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('equations')) return; maths++; push_button_if("differential_equations", "thoughts", "calculus"); },
        show: "<b>数学研究</b><br>什么是x？<br>思考可以少量提升科学加成。",
        price: [["thought", 825], ["book", 214]],
        upgraded: false,
        unlocked: false
    },
    'functions': {
        name: '初等函数',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('functions')) return; maths++; push_button("epsilon", "thoughts"); push_button("kaiseki_geometry", "thoughts"); },
        show: "<b>数学研究</b><br>随着变化而变化的量。<br>牛顿第二定律的效果增加20%",
        price: [["thought", 575], ["book", 167]],
        upgraded: false,
        unlocked: false
    },
    'kaiseki_geometry': {
        name: '解析几何',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('kaiseki_geometry')) return; maths++; push_button("sin_cos_tan", "thoughts"); },
        show: "<b>数学研究</b><br>经过60分钟的检查，发现这里少了一个负号。<br>全体建筑的价格增长底数-0.002",
        price: [["thought", 1135], ["book", 290]],
        upgraded: false,
        unlocked: false
    },
    'sin_cos_tan': {
        name: '三角函数',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('sin_cos_tan')) return; maths++; push_button("engineering_maths", "thoughts"); },
        show: "<b>数学研究</b><br>邻边比上对边是…？<br>工坊为建筑结构提供的合成效率额外+3%",
        price: [["thought", 1420], ["book", 330], ["paper", 5000]],
        upgraded: false,
        unlocked: false
    },
    'engineering_maths': {
        name: '工程数学',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('engineering_maths')) return; maths++; },
        show: "<b>数学研究</b><br>让价格增长的底数减少0.003<br>同时，还能让无数数学学子脑袋变秃。",
        price: [["thought", 4620], ["book", 700], ["paper", 12000]],
        upgraded: false,
        unlocked: false
    },
    'epsilon': {
        name: '无穷小量',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('epsilon')) return; maths++; push_button_if("kinetics", "thoughts", "newton_2"); push_button_if("calculus", "thoughts", "kinetics"); },
        show: "<b>数学研究</b><br>缺乏一个严格定义，但是神奇般地能用。<br>所有思考的成本-1.2%",
        price: [["thought", 1000], ["book", 260]],
        upgraded: false,
        unlocked: false
    },
    'calculus': {
        name: '微积分',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('calculus')) return; maths++; push_button_if("differential_equations", "thoughts", "equations"); },
        show: "<b>数学研究</b><br>逐渐明晰化的定义。<br>跨时代的数学发现，能够对整个科学起到不可估量的作用。<br>牛顿第二定律效果+40%",
        price: [["thought", 2000], ["book", 430]],
        upgraded: false,
        unlocked: false
    },
    'differential_equations': {
        name: '微分方程',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('differential_equations')) return; maths++; },
        show: "<b>数学研究</b><br>在各种学科中都有广泛的应用。<br>牛顿第一定律效果+10%",
        price: [["thought", 4000], ["book", 1000]],
        upgraded: false,
        unlocked: false
    },


    /*
    
    -- PHYSICS

    */

    'newton_1': {
        name: '牛顿第一定律',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('newton_1')) return; physics++; push_button('newton_3', 'thoughts'); },
        show: "<b>物理研究</b><br>不受力的物体总保持匀速直线运动或静止。<br>每个物理研究令记忆的效果额外提升0.5%",
        price: [["thought", 300], ["book", 21]],
        upgraded: false,
        unlocked: false
    },
    'newton_3': {
        name: '牛顿第三定律',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('newton_3')) return; physics++; push_button_if('newton_2', 'thoughts', 'algebra');
                push_button('stellars', 'thoughts'); push_button('E_and_P', 'thoughts'); },
        show: "<b>物理研究</b><br>作用力和反作用力是相等的。<br>总有人问，为什么东西还能动起来呢？<br>全部建筑成本-5%",
        price: [["thought", 350], ["book", 100]],
        upgraded: false,
        unlocked: false
    },
    'E_and_P': {
        name: '能量与动量',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('E_and_P')) return; physics++; push_button('heat', 'thoughts'); },
        show: "<b>物理研究</b><br>本质上是通过牛顿定律规定的物理量。<br>牛顿定律的效果+20%",
        price: [["thought", 410], ["book", 70]],
        upgraded: false,
        unlocked: false
    },
    'heat': {
        name: '热量',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('heat')) return; physics++; push_button('vehicle', 'thoughts'); },
        show: "<b>物理研究</b><br>掌握对热量的更好利用方法。<br>火堆的效果变为+8%<br>冶金产出+10%",
        price: [["thought", 500], ["wood", 5000], ["carbon", 350]],
        upgraded: false,
        unlocked: false
    },
    'vehicle': {
        name: '内燃机',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('vehicle')) return; physics++; push_button('transportations', 'thoughts'); push_button('electricity', 'thoughts'); },
        show: "<b>物理研究</b><br>吸气，压缩，做功，排气。<br>所有燃料消耗-10%",
        price: [["thought", 700], ["alloy", 15], ["steel", 150]],
        upgraded: false,
        unlocked: false
    },
    'transportations': {
        name: '交通工具',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('transportations')) return; push_button('crossroad', 'bonfire'); },
        show: "内燃机可以带动轮子，这样就不需要马来拉车了。<br>解锁<b>交通枢纽</b>",
        price: [["thought", 900], ["alloy", 37.5], ["steel", 300]],
        upgraded: false,
        unlocked: false
    },
    'electricity': {
        name: '电力',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('electricity'))
                return;
            physics++;
            push_button('power_station', 'bonfire');
            push_button('illumination', 'thoughts');
            push_button('home_powered', 'thoughts');
            push_button_if('surveillance', 'thoughts', 'laws');
            push_button('factories', 'thoughts');
            push_button("wind_power_station", "thoughts");
            setguide("解锁电力系统。当供电不足的时候，需要电力的建筑将会停止工作。");
        },
        show: "<b>物理研究</b><br>第一次观察到电磁感应，并且通过它来发电。<br>解锁电力系统",
        price: [["thought", 1200], ["alloy", 50], ["steel", 600], ["book", 70]],
        upgraded: false,
        unlocked: false
    },
    'factories': {
        name: '工厂',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('factories')) return; push_button('factory', 'bonfire'); },
        show: "利用电力更好地处理物品。<br>解锁<b>工厂</b>，能够熔炼<b>钛</b>",
        price: [["thought", 1300], ["alloy", 25]],
        upgraded: false,
        unlocked: false
    },
    'illumination': {
        name: '照明',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('illumination')) return; push_button("theater", "bonfire"); },
        show: "夜晚不再令人惧怕。<br>解锁<b>剧场</b><br>还可以利用多余的电力举办晚间活动，提升稳定度<br>",
        price: [["thought", 1300], ["paper", 3200]],
        upgraded: false,
        unlocked: false
    },
    'home_powered': {
        name: '住宅供电',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('home_powered')) return; push_button('apartment', 'bonfire'); },
        show: "解锁一种新的住宅，供多人使用，内部通电。<br>人们决定把它叫做“公寓”。",
        price: [["thought", 1750]],
        upgraded: false,
        unlocked: false
    },
    'newton_2': {
        name: '牛顿第二定律',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('newton_2')) return; physics++; push_button_if('kinetics', 'thoughts', 'epsilon');
                push_button('research_lab', 'bonfire'); },
        show: "<b>物理研究</b><br>F=ma<br>每个数学研究令记忆的效果额外提升0.5%",
        price: [["thought", 550], ["book", 85]],
        upgraded: false,
        unlocked: false
    },
    'stellars': {
        name: '天体',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('stellars')) return; physics++; push_button('kepler', 'thoughts'); push_button('optics', 'thoughts'); push_button('observatory', 'bonfire'); },
        show: "<b>物理研究</b><br>天上的大火球是什么？<br>解锁<b>天文台</b>",
        price: [["thought", 800], ["book", 120], ["structure", 80]],
        upgraded: false,
        unlocked: false
    },
    'kepler': {
        name: '开普勒三定律',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('kepler')) return; physics++; push_button("gravity", "thoughts"); },
        show: "<b>物理研究</b><br>摸清楚天体运行的规律。<br>天文台的效果增加40%",
        price: [["thought", 1375], ["book", 175], ["glass", 400]],
        upgraded: false,
        unlocked: false
    },
    'gravity': {
        name: '万有引力',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('gravity')) return; physics++; },
        show: "<b>物理研究</b><br>两个物体之间一定会存在相互吸引的力。<br>牛顿第一定律的效果+20%",
        price: [["thought", 1585], ["book", 420]],
        upgraded: false,
        unlocked: false
    },
    'optics': {
        name: '光学',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('optics'))
                return;
            physics++;
            push_button("telescope", "crafts");
            push_button("inflection_law", "thoughts");
        },
        show: "<b>物理研究</b><br>用校正过的望远镜更好地观察天体。<br>解锁<b>望远镜</b>",
        price: [["thought", 1025], ["book", 255], ["glass", 500]],
        upgraded: false,
        unlocked: false
    },
    'inflection_law': {
        name: '折射定律',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('inflection_law')) return; physics++; },
        show: "<b>物理研究</b><br>把筷子伸到水面下就像折断了一样。<br>望远镜的效率提高20%",
        price: [["thought", 1370], ["book", 390], ["glass", 600]],
        upgraded: false,
        unlocked: false
    },
    'kinetics': {
        name: '运动学',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('kinetics')) return; physics++; push_button('engineering_mechanics', 'thoughts'); push_button_if("calculus", "thoughts", "epsilon"); },
        show: "<b>物理研究</b><br>小木块在光滑的平面上滑来滑去。<br>牛顿定律的效果+30%<br>开普勒三定律的效果+50%",
        price: [["thought", 2000], ["book", 605]],
        upgraded: false,
        unlocked: false
    },
    'engineering_mechanics': {
        name: '工程力学',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('engineering_mechanics')) return; physics++; push_button('flight', 'thoughts'); },
        show: "<b>物理研究</b><br>让价格增长的底数减少0.01<br>同时，还能让无数物理学子脑袋变秃。",
        price: [["thought", 2275], ["book", 2440]],
        upgraded: false,
        unlocked: false
    },
    'flight': {
        name: '飞行器',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('flight')) return; physics++; push_button_if("rocket", "thoughts", "atomic_fission"); },
        show: "<b>物理研究</b><br>一双翅膀和一架轻巧的机械。<br>交通枢纽的效果+150%，但燃料消耗+50%",
        price: [["thought", 2500], ["book", 4500], ["titanium", 4000], ["structure", 6000]],
        upgraded: false,
        unlocked: false
    },
    'atomic_fission': {
        name: '核裂变',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade("atomic_fission"))
                return;
            physics++;
            push_button("mine_upgrade", "thoughts");
            push_button("fission_powerplant", "bonfire");
            push_button("heavy_element_collision", "thoughts");
            push_button_if("rocket", "thoughts", "flight");
        },
        show: "<b>物理研究</b><br>从人类的视野之外爆发出的惊人力量。<br>解锁裂变反应堆，以极高的污染为代价产出大量电力<br>需要<b>铀</b>运作；铀可以通过探索发现",
        price: [["thought", 2825], ["book", 7000], ["alloy", 600], ["titanium", 3000]],
        upgraded: false,
        unlocked: false
    },
    'mine_upgrade': {
        name: '矿井升级',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('mine_upgrade'))
                return;
        },
        show: "铀的提取需要大量矿石，这让矿井的升级迫在眉睫。<br>矿井的煤产量+60%，铀产量+10%",
        price: [["thought", 3100], ["carbon", 6000], ["uranium", 50]],
        upgraded: false,
        unlocked: false
    },
    'heavy_element_collision': {
        name: '高能对撞',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('heavy_element_collision'))
                return;
            push_button("atomic_stable_island", "thoughts");
        },
        show: "利用更重的粒子，大幅提高对撞机的能力。<br>对撞机会少量消耗铀和贵金属，但是效果+100%",
        price: [["thought", 4675], ["book", 16000], ["gold", 8000], ["uranium", 100]],
        upgraded: false,
        unlocked: false
    },
    'rocket': {
        name: '火箭',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('rocket'))
                return;
            add_navigation("space");
            push_button("moon_probe", "thoughts");
            setguide("<b>太空</b>已经解锁，但人们对它一无所知。为了进一步探索太空，必不可少的是研究<b>月球探测</b>与建造<b>月球基地</b>");
        },
        show: "向天空发起第一次挑战。<br>解锁<b>太空</b>面板<br>",
        price: [["thought", 5500], ["book", 32000], ["titanium", 600], ["structure", 4000], ["steel", 10000], ["uranium", 150]],
        upgraded: false,
        unlocked: false
    },

    /**
     * 
     *  ANTIMATTER-STAGE TECH & METAPHYSICS
     * 
     */

    'atomic_stable_island': {
        name: '原子核稳定岛',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('atomic_stable_island'))
                return;
            physics++;
            push_button("LHC", "space_moon");
            unlock("element_126");
        },
        show: "<b>物理研究</b><br>一些超重的原子核并不会瞬间裂变，这让我们能找到126号元素的踪迹。<br>解锁<b>大型强子对撞机</b>",
        price: [["thought", 9750], ["gold", 30000], ["uranium", 275]],
        upgraded: false,
        unlocked: false
    },
    'LHC_consumption': {
        name: '对撞机电力调度',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('LHC_consumption'))
                return;
        },
        show: "将多余的电力抽调一部分，用于增强大型强子对撞机的效果。<br>电力能够增强超重元素的产出",
        price: [["thought", 10125], ["gold", 33500], ["uranium", 400]],
        upgraded: false,
        unlocked: false
    },
    'antimatter_research': {
        name: '反物质',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('antimatter_research'))
                return;
            unlock("antimatter");
            push_button("electromagnetic_capture", "thoughts");
            push_button_if("phase_shift", "thoughts", "techno_explosion");
            push_button_if("manasource_access", "thoughts", "arcane");
        },
        show: "剧烈地消耗能量，从而凭空生成物质。<br>大型强子对撞机每秒产出0.000001（即1.000 µ）反物质",
        price: [["thought", 11025], ["uranium", 500], ["element_126", 300]],
        upgraded: false,
        unlocked: false
    },
    'electromagnetic_capture': {
        name: '电磁束缚',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('electromagnetic_capture'))
                return;
            push_button("antimatter_storage", "thoughts");
        },
        show: "通常的物质无法与反物质相容，只有施加电磁束缚才能防止无时无刻不在的损耗。<br>电力可以增强反物质的产出，并且反物质的产量+100%",
        price: [["thought", 13075], ["book", 600000]],
        upgraded: false,
        unlocked: false
    },
    'phase_shift': {
        name: '移相',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('phase_shift'))
                return;
            physics++;
            push_button("supercritical_phase_shifter", "technology");
        },
        show: "利用正反物质湮灭引发空间不稳，令物质发生移相。<br>解锁科技<b>超临界移相器</b>",
        price: [["insight", 1250], ["REE", 7500], ["antimatter", 0.1]],
        upgraded: false,
        unlocked: false
    },
    'manasource_access': {
        name: '根源接续',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('manasource_access'))
                return;
            magics++;
            push_button("mundus_tree", "metaphysics");
        },
        show: "将反物质作为全新的触媒，窥见大源的奥秘。<br>解锁玄学<b>世界树</b>",
        price: [["thought", 13850], ["mana", 1800], ["antimatter", 0.01]],
        upgraded: false,
        unlocked: false
    },

    /*
    
    -- SPACE UPGRADES
    
    */

    'moon_probe': {
        name: '月球探测',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('moon_probe'))
                return;
            push_button_if("moon_base_research", "thoughts", "artificial_biome");
            unlock("astronaut");
            unlock("supply");
            unlock("craftsman_supply");
        },
        show: "向月球发送无人机，探查其上的情况。<br>",
        mutant: function() {
            if (!get("artificial_biome").upgraded)
                return "<font color='red'>如果要建立月球基地，必须先构建<b>人造生物圈</b></font>";
            
            return "能够开始研究<b>月球基地</b>"
        },
        price: [["thought", 6500], ["book", 50000], ["titanium", 1500], ["steel", 17500], ["uranium", 225]],
        upgraded: false,
        unlocked: false
    },
    'moon_base_research': {
        name: '月球基地',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('moon_base_research'))
                return;
            push_button("moon_back", "thoughts");
            push_button("moon_titanium", "thoughts");
            push_button("moon_living", "thoughts");
            push_button("mars_launch", "thoughts");
            push_button("moon_base", "space_moon");
        },
        show: "在月球上建立复杂的综合设施，供研究与生活使用。<br>解锁建筑<b>月球基地</b>",
        price: [["thought", 8000], ["steel", 16000]],
        upgraded: false,
        unlocked: false
    },
    'moon_back': {
        name: '月球背面',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('moon_back'))
                return;
            push_button("exotic_tech", "thoughts");
        },
        show: "在月球背面发现了本不应该存在的建筑。",
        mutant: function() {
            let text = "";
            if (get("education").upgraded)
                text += "<br>有人说这是外星留下的遗迹，值得系统研究。<br>解锁进一步的月球研究";
            if (get("faithful").upgraded)
                text += "<br>有人说这是神明留下的启示，值得虔诚祭祀。<br>解锁进一步的月球研究";
            return text;
        },
        price: [["thought", 9150], ["discovered_area", 5000000]],
        upgraded: false,
        unlocked: false
    },
    'moon_living': {
        name: '月球生活区',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('moon_living'))
                return;
            push_button("moon_living_quarter", "space_moon");
        },
        show: "在月球基地增加一个附属的生活区。<br>解锁<b>生活区</b>",
        price: [["thought", 10125], ["book", 500000], ["uranium", 250]],
        upgraded: false,
        unlocked: false
    },
    'moon_titanium': {
        name: '月球钛提取',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('moon_titanium'))
                return;
        },
        show: "月球富含钛元素。改装月球基地，使它能产生钛。<br>月球基地每秒产出0.2钛",
        price: [["thought", 9775], ["titanium", 2000], ["REE", 10500]],
        upgraded: false,
        unlocked: false
    },
    'exotic_tech': {
        name: '外星技术',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('exotic_tech'))
                return;
            physics++;
            push_button("moon_exotic_lab", "space_moon");
            push_button("superconductivity", "thoughts");
            push_button("space_pollution", "thoughts");
        },
        show: "<b>物理研究</b><br>围绕着月球背面的建筑设立实验室。<br>解锁<b>外星材料实验室</b>",
        price: [["thought", 10800], ["REE", 14000]],
        upgraded: false,
        unlocked: false
    },
    'superconductivity': {
        name: '超导体',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('superconductivity'))
                return;
            physics++;
            unlock("superconductor");
            unlock("craftsman_superconductor");
        },
        show: "<b>物理研究</b><br>通过对外星技术的进一步研究，掌握了常温下的超导体技术。<br>解锁<b>超导体</b>",
        price: [["thought", 12600], ["dark_matter", 12000]],
        upgraded: false,
        unlocked: false
    },
    'space_pollution': {
        name: '太空污染',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('space_pollution'))
                return;
            push_button("moon_pollution_tube", "space_moon");
        },
        show: "将污染排放入太空。解锁<b>地外污染管道</b>",
        price: [["thought", 13000], ["book", 2000000]],
        upgraded: false,
        unlocked: false
    },
    'mars_launch': {
        name: '火星救援',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('mars_launch'))
                return;
            push_button("mars_reform", "thoughts");
            push_button("elem126_power", "thoughts");
        },
        show: "向火星发射火箭。<br>解锁<b>火星</b>有关的思考和建筑",
        price: [["thought", 15200], ["uranium", 250], ["superconductor", 800]],
        upgraded: false,
        unlocked: false
    },
    'mars_reform': {
        name: '火星重塑',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('mars_reform'))
                return;
            push_button("mars_reform_device", "space_mars");
        },
        show: "火星是太阳系中与地球最相近的星球。<br>提出火星改造计划，使它能够支撑生命。",
        price: [["thought", 17000], ["book", 5000000]],
        upgraded: false,
        unlocked: false
    },
    'mars_shipment': {
        name: '火星货运',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('mars_shipment'))
                return;
            push_button("mars_fuel", "thoughts");
            push_button("mars_cargo", "space_mars");
        },
        show: "将火星作为第二个物资运输中心，减少补给的消耗。<br>解锁<b>货运港</b>",
        price: [["thought", 19125], ["steel", 40000]],
        upgraded: false,
        unlocked: false
    },
    'mars_fuel': {
        name: '火星飞船中心',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('mars_fuel'))
                return;
        },
        show: "火星的质量较小，从这里发射的火箭也只需要更少的燃料。<br>所有燃料消耗-10%",
        price: [["thought", 22500], ["carbon", 75000]],
        upgraded: false,
        unlocked: false
    },
    'mars_manufacture': {
        name: '火星组装站',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('mars_manufacture'))
                return;
            unlock("mars_unmanned_factory", "space_mars");
        },
        show: "在火星大片未开发的地带建立无人组装厂。<br>解锁<b>组装厂</b>",
        price: [["thought", 22500], ["carbon", 75000]],
        upgraded: false,
        unlocked: false
    },
    'mars_site_research': {
        name: '火星基地',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('mars_site_research'))
                return;
            unlock("ancient_bio");
            get("ancient_bio").storage = 1;
            push_button("mars_site", "space_mars");
            push_button_if("paleobiology", "thoughts", "education");
            push_button_if("ancient_theology", "thoughts", "faithful");
        },
        show: "在火星上发现了生命留存的痕迹。<br>建造<b>火星基地</b>，研究古代生命",
        price: [["thought", 26000]],
        upgraded: false,
        unlocked: false
    },
    'paleobiology': {
        name: '古生物学',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('paleobiology'))
                return;
            push_button("sequencing_center", "technology");
            push_button("dna_peculiarity", "thoughts");
        },
        show: "研究古代生物，找出高效复制它们的方法。<br>解锁<b>测序中心</b>",
        price: [["thought", 30000], ["insight", 1580], ["book", 7500000]],
        upgraded: false,
        unlocked: false
    },
    'dna_peculiarity': {
        name: '奇异DNA',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (get("sequencing_center").level < 10 || !upgrade('dna_peculiarity'))
                return;
            push_button("dna_replica", "thoughts");
        },
        show: "古代生物的某些DNA位点含有化学上不可能稳定存在的碱基。<br><font color='red'>至少需要10个测序中心才能研究</font><br>测序中心的效果+15%",
        price: [["thought", 33250], ["insight", 2700], ["ancient_bio", 50], ["book", 1000000]],
        upgraded: false,
        unlocked: false
    },
    'dna_replica': {
        name: '基因复刻',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('dna_replica'))
                return;
            push_button("self_clone", "thoughts");
            get("ancient_resonance").unlocked = false;
            self_reload();
        },
        show: "科学家们相信古代生物DNA的特殊结构为奇异碱基提供了存在的环境。<br>虽然不完全理解其中的原理，科学家们设法合成出了完全一致的分子。<br>每个化学实验室为古代生物提供1%加成",
        mutant: function() {
            if (!get("perfect_insight").upgraded)
                return "";
            return "<br><font color='red'>与<b>古代共鸣</b>互斥</font>";
        },
        price: [["thought", 55000], ["insight", 3500], ["ancient_bio", 100], ["book", 12500000]],
        upgraded: false,
        unlocked: false
    },
    'ancient_theology': {
        name: '古代神学',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('ancient_theology'))
                return;
            push_button("deification", "thoughts");
        },
        show: "将古代生物作为神明，为它们献上祭品。<br>信仰可以加成古代生物的产出",
        price: [["thought", 30000], ["magic", 1280], ["ancient_bio", 15]],
        upgraded: false,
        unlocked: false
    },
    'deification': {
        name: '神化',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('deification'))
                return;
            push_button("temple", "metaphysics");
            push_button("ancient_resonance", "thoughts");
        },
        show: "为古代生物创作传说，传播它们的信仰。<br>解锁<b>寺庙</b>",
        price: [["thought", 33250], ["magic", 2700], ["ancient_bio", 150]],
        upgraded: false,
        unlocked: false
    },
    'ancient_resonance': {
        name: '古代共鸣',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade("ancient_resonance"))
                return;
            get("dna_replica").unlocked = false;
            self_reload();
            // TODO: path to 3rd reset
        },
        show: "将古代生物用作材料，感受与它的共鸣。<br>古代生物的数量将会略微加成信仰的效果<br>不会有超过2500古代生物起效<br><font color='red>警告：这个路线尚未完成</font>",
        mutant: function() {
            if (!get("perfect_insight").upgraded)
                return "";
            return "<br><font color='red'>与<b>基因复刻</b>互斥</font>";
        },
        price: [["thought", 55000], ["magic", 3500], ["ancient_bio", 1500]],
        upgraded: false,
        unlocked: false
    },
    'elem126_power': {
        name: '超重原子发电机',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('elem126_power'))
                return;
            push_button("mercury_discovery", "thoughts");
            push_button("asteroid_discovery", "thoughts");
        },
        show: "为飞船搭载超重原子发电机，让它们更容易逃逸火星，到达更远的星球。<br>解锁<b>水星</b>与<b>小行星带</b>",
        price: [["thought", 31250], ["element_126", 1180]],
        upgraded: false,
        unlocked: false
    },
    'mercury_discovery': {
        name: '水星探索',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('mercury_discovery'))
                return;
            push_button("energy_crystal_research", "thoughts");
            push_button("mercury_station", "space_mercury");
            push_button("sun_launch", "thoughts");
        },
        show: "水星离太阳太近，无法供人居住。<br>然而，我们能利用水星的高温节省大量能量。<br>建造<b>水星科考站</b>，以备将来的工业制造",
        price: [["thought", 36000], ["element_126", 600], ["uranium", 300]],
        upgraded: false,
        unlocked: false
    },
    'energy_crystal_research': {
        name: '能量晶体',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('energy_crystal_research'))
                return;
            unlock("energy_crystal");
            push_button("ec_storage", "thoughts");
        },
        show: "将多余的能量存储在特别的晶体中，便于太空旅行。<br>水星科考站可以产出<b>能量晶体</b>",
        price: [["thought", 40000], ["mineral", 100000], ["uranium", 325]],
        upgraded: false,
        unlocked: false
    },
    'ec_storage': {
        name: '能量晶体储藏室',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('ec_storage'))
                return;
            push_button("mercury_storage", "space_mercury");
        },
        show: "易燃易爆的能量晶体需要特别小心地储存。<br>在水星上建立<b>储存站</b>，储存各类物资",
        price: [["thought", 44000], ["energy_crystal", 1024], ["book", 5000000]],
        upgraded: false,
        unlocked: false
    },
    'asteroid_discovery': {
        name: '小行星带探索',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('asteroid_discovery'))
                return;
            push_button("asteroid_station", "space_asteroid");
            unlock("unobtainium");
        },
        show: "小行星带是矿产的丰富宝库。<br>向小行星带发射飞船，准备采矿。",
        price: [["thought", 48000], ["energy_crystal", 2048], ["alloy", 25000]],
        upgraded: false,
        unlocked: false
    },
    'sun_launch': {
        name: '戴森球计划',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('sun_launch'))
                return;
            push_button("dyson_sphere", "space_sun");
        },
        show: "从水星发射太阳探测器，试图围绕太阳建造戴森球。<br>每个水星科考站可以使戴森球的价格-3%，但额外消耗1电力",
        price: [["thought", 52000], ["energy_crystal", 16384], ["superconductor", 5000], ["unobtainium", 650]],
        upgraded: false,
        unlocked: false
    },
    'dyson_experiment': {
        name: '戴森球实验',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            let gain = prestige_gain(2);
            let want = confirm(sprintf("这会触发重置。你将获取$记忆、$历史与$遗物，然后从头开始发展文明。确定要这么做吗？", gain.memory, gain.history, gain.relic));
            if (!want || !upgrade('dyson_experiment')) {
                self_reload();
                return;
            }
            prestige(2);
        },
        show: "试图高效地利用戴森球。<br><font color='red'>稍有差池，就可能让太阳不稳定，从而摧毁整个文明</font>",
        mutant: function() {
            let gain = prestige_gain(2);
            text = sprintf("<br><br>获得<font color='green'>$</font>记忆<br>获得<font color='green'>$</font>历史<br>获得<font color='green'>$</font>遗物", gain.memory, gain.history, gain.relic);
            return text;
        },
        price: [["thought", 55000]],
        upgraded: false,
        unlocked: false
    },


    /*
    
    -- CHEMISTRY

    */

    'mineral_research': {
        name: '矿物研究',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('mineral_research')) return; chemistry++; push_button('metal_forge', 'thoughts'); push_button('basic_materials', 'thoughts');
                                push_button('elements', 'thoughts');},
        show: "<b>化学研究</b><br>你发现这块石头与别的不一样。<br>在探索达到一定值的时候，冶炼能够产出新的资源",
        price: [["thought", 200], ["book", 25]],
        upgraded: false,
        unlocked: false
    },
    'metal_forge': {
        name: '金属锻造',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('metal_forge')) return; chemistry++; },
        show: "<b>化学研究</b><br>三块铁和两个木棍可以合成铁斧。<br>猎人、矿工与探险者的产出+15%",
        price: [["thought", 360], ["copper", 2700], ["iron", 1550]],
        upgraded: false,
        unlocked: false
    },
    'basic_materials': {
        name: '基本材料',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('basic_materials')) return; chemistry++; unlock("glass"); push_button("furnace", "bonfire"); push_button("basic_instruments", "thoughts"); },
        show: "<b>化学研究</b><br>在熔炉中煅烧沙子会得到一种透明的材料。<br>解锁<b>熔炉</b>与<b>玻璃</b><br>熔炉熔炼玻璃需要消耗石头",
        price: [["thought", 425], ["book", 55], ["carbon", 50], ["stone", 600]],
        upgraded: false,
        unlocked: false
    },
    'basic_instruments': {
        name: '基础仪器',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('basic_instruments')) return; chemistry++; push_button('chemlab', 'bonfire'); },
        show: "<b>化学研究</b><br>玻璃和铁组成的仪器，都长得很像但是用途各不相同。<br>解锁<b>化学实验室</b>",
        price: [["thought", 600], ["book", 120], ["glass", 125], ["iron", 200]],
        upgraded: false,
        unlocked: false
    },
    'elements': {
        name: '元素论',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('elements')) return; chemistry++; push_button('atoms_and_molecules', 'thoughts'); push_button("pv_nrt", "thoughts");
                                push_button("element_analysis", "thoughts"); },
        show: "<b>化学研究</b><br>过去残存的资料显示一共有118种元素。<br>每个化学研究增加0.5%记忆加成",
        price: [["thought", 350], ["book", 65], ["iron", 75]],
        upgraded: false,
        unlocked: false
    },
    'atoms_and_molecules': {
        name: '原子论与分子学说',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('atoms_and_molecules')) return; chemistry++; },
        show: "<b>化学研究</b><br>想像极小尺度的样子。<br>有100思考不再计入遗忘",
        price: [["thought", 450], ["book", 110]],
        upgraded: false,
        unlocked: false
    },
    'pv_nrt': {
        name: '理想气体状态方程',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('pv_nrt')) return; chemistry++; },
        show: "<b>化学研究</b><br>pV=nRT<br>化学研究也计入物理研究之中",
        price: [["thought", 550], ["book", 235]],
        upgraded: false,
        unlocked: false
    },
    'element_analysis': {
        name: '元素分析',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('element_analysis'))
                return;
            chemistry++;
            push_button("AsHg", "thoughts");
            push_button("organic", "thoughts");
            push_button("periodic_table", "thoughts");
            push_button("redox", "thoughts");
            if (get("factory").level)
                unlock("titanium");
        },
        show: "<b>化学研究</b><br>大量的探索与分析，使人们认识到了自然元素中的65种。<br>解锁化学分支的进一步研究",
        price: [["thought", 1350], ["discovered_area", 150000], ["book", 440]],
        upgraded: false,
        unlocked: false
    },
    'redox': {
        name: '氧化还原',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('redox')) return; chemistry++; },
        show: "<b>化学研究</b><br>对已经了解的反应机制的研究，增加了不常见金属的产量。<br>钛的产量+100%",
        price: [["thought", 1440], ["copper", 6000], ["iron", 6000], ["carbon", 6000]],
        upgraded: false,
        unlocked: false
    },
    'periodic_table': {
        name: '元素周期表',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade("periodic_table"))
                return;
            chemistry++;
            push_button("collider", "bonfire");
        },
        show: "<b>化学研究</b><br>不仅归纳了已发现的元素，更为没发现的留出了位置。<br>解锁<b>对撞机</b>，以触碰未知的领域",
        price: [["thought", 1500], ["book", 75]],
        upgraded: false,
        unlocked: false
    },
    'organic': {
        name: '有机化学',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('organic')) return; chemistry++; push_button_if("GM", "thoughts", "inherit");  },
        show: "<b>化学研究</b><br>第一次在人体外获得了尿素。<br>每个化学研究额外增加0.1%全局产量",
        price: [["thought", 1800]],
        upgraded: false,
        unlocked: false
    },
    'AsHg': {
        name: '砷汞富集器',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('AsHg'))
                return;
            push_button('AsHg_collector', 'bonfire');
            push_button_if("pollution_reuse", "thoughts", "alchemy");
        },
        show: "建造一个能够净化重金属、收集有毒物质的装置。",
        price: [["thought", 1950], ["book", 1000], ["stone", 30000]],
        upgraded: false,
        unlocked: false
    },
    'AsHg_experiment': {
        name: '污染物处理实验',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            let want = confirm(sprintf("这会触发重置。你将获取$记忆，然后从头开始发展文明。确定要这么做吗？", prestige_gain(1).memory));
            if (!want || !upgrade('AsHg_experiment')) {
                self_reload();
                return;
            }
            prestige(1);
        },
        show: "有人想出了一个更好地处理砷汞富集器内的物质的方法。<br><font color='red'>一旦泄漏，能毁灭整个文明</font>",
        mutant: function() {
            text = sprintf("<br><br>获得<font color='green'>$</font>记忆", prestige_gain(1).memory);
            return text;
        },
        price: [["thought", 2035]],
        upgraded: false,
        unlocked: false
    },

    /*

    -- BIOLOGY

    */
    'genetics': {
        name: '基因',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('genetics'))
                return;
            push_button("inherit", "thoughts"); 
            push_button("memory_study", "thoughts");
        },
        show: "一望无际的豌豆田。<br>发现遗传的奥秘，激起人们对生物学的兴趣。<br>解锁进一步的研究",
        price: [["thought", 1350], ["book", 200]],
        upgraded: false,
        unlocked: false
    },
    'inherit': {
        name: '遗传学',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('inherit'))
                return;
            push_button_if("GM", "thoughts", "organic");
            push_button("artificial_biome", "thoughts");
        },
        show: "掌握遗传因子（基因）的移动规律。<br>植物研究的效果增加100%",
        price: [["thought", 1775], ["book", 290]],
        upgraded: false,
        unlocked: false
    },
    'GM': {
        name: '基因工程',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (stability() < 1.2 || !upgrade('GM')) return; add_navigation("gene"); if(!get("structurize").upgraded) push_button("structurize", "gene"); },
        show: "尝试编辑我们自己的基因。<br><font color=red>稳定度低于120%时，将因伦理争议而无法研究</font><br>解锁基因界面，可以购买在重置时保留的升级。",
        price: [["thought", 2250], ["book", 650]],
        upgraded: false,
        unlocked: false
    },
    'memory_study': {
        name: '记忆研究',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('memory_study')) 
                return;
        },
        show: "研究人脑的运作原理，探寻记忆的奥秘。<br>令额外2%的记忆生效",
        price: [["thought", 1980], ["book", 2000], ["memory", 1]],
        upgraded: false,
        unlocked: false
    },
    'artificial_biome': {
        name: '人造生物圈',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('artificial_biome'))
                return;
            push_button_if("moon_base_research", "thoughts", "moon_probe");
        },
        show: "投入大量资金，培植新的诱变物种，构成自给自足的生物圈。<br>植物研究的效果再增加100%",
        price: [["thought", 3125], ["book", 20250], ["gold", 2500], ["uranium", 25]],
        upgraded: false,
        unlocked: false
    },

    /*

    -- SMELTING AND USAGES OF ELEMENTS

    */

    'copper_usage': {
        name: '铜',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('copper_usage')) return; push_button("heat_concentration", "thoughts"); push_button("mineral_research", "thoughts"); },
        show: "你们知道了铜的存在。只要发现矿洞，就可以开采矿石了。<br>至于如何冶炼，恐怕还需要一段时间的摸索。",
        price: [["thought", 80]],
        upgraded: false,
        unlocked: false
    },
    'heat_concentration': {
        name: '集中加热',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('heat_concentration')) return; push_button('smelting', 'thoughts'); push_button('mine', 'bonfire'); },
        show: "改变火堆的构造，使得它的效果更强，但木材消耗也更多。<br>这种方法或许也可以用于冶炼矿石。<br>火堆的木材消耗翻倍，但是效果变为+7.5%",
        price: [["thought", 100]],
        upgraded: false,
        unlocked: false
    },
    'smelting': {
        name: '熔炼',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('smelting')) return; push_button('smelter', 'bonfire'); push_button('copper_ax', 'thoughts');
            push_button('copper_pickaxe', 'thoughts'); push_button('copper_sword', 'thoughts'); },
        show: "尽管与过去繁荣的文明掌握的火法炼铜大相径庭，这种土方法好歹还是能产出铜单质的。<br>解锁<b>铜</b>以及相关升级。",
        price: [["thought", 125]],
        upgraded: false,
        unlocked: false
    },
    'copper_ax': {
        name: '铜斧',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('copper_ax')) return; },
        show: "将石头斧子替换成铜的。<br>木材与食物的产量再增加50%。",
        price: [["thought", 150], ["copper", 50]],
        upgraded: false,
        unlocked: false
    },
    'copper_pickaxe': {
        name: '铜镐',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('copper_pickaxe')) return;
            let quar = get("quarry_worker");
            get("person").storage += quar.on;
            quar.unlocked = false;
            self_reload();
        },
        show: "能够用比石头更加坚硬的东西开采石头。<br>采石者不再存在，矿工每秒产出5石头<br>矿石产量+100%",
        price: [["thought", 160], ["copper", 100]],
        upgraded: false,
        unlocked: false
    },
    'copper_sword': {
        name: '铜剑',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('copper_sword')) return; },
        show: "小心不要割到手，不然可能会破伤风。<br>探索产量与猎人的食物产量+30%",
        price: [["thought", 200], ["copper", 200]],
        upgraded: false,
        unlocked: false
    },
    'carbon_usage': {
        name: '木炭技术',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('carbon_usage')) return; push_button("carbon_reveal", "thoughts"); },
        show: "将木材和煤炭混在一起使用。<br>作为燃料的木材消耗-50%，且煤按照原本燃烧的木材的5%被消耗<br>金属冶炼的效果+10%",
        price: [["thought", 235], ["carbon", 30], ["wood", 75]],
        upgraded: false,
        unlocked: false
    },
    'carbon_reveal': {
        name: '煤开采',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('carbon_reveal')) return; },
        show: "煤炭可以从矿井中开采了。",
        price: [["thought", 260], ["structure", 40]],
        upgraded: false,
        unlocked: false
    },
    'iron_ax': {
        name: '铁斧',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('iron_ax')) return; },
        show: "铁斧除了爱生锈之外，没有什么不好的。<br>猎人的效率+30%",
        price: [["thought", 330], ["iron", 600]],
        upgraded: false,
        unlocked: false
    },
    'iron_sword': {
        name: '铁剑',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('iron_sword')) return; },
        show: "用起来和看起来都很舒服，比铜的好多了。<br>猎人收集食物的效率+35%<br>探索产出+45%",
        price: [["thought", 350], ["iron", 1000]],
        upgraded: false,
        unlocked: false
    },
    'iron_pickax': {
        name: '铁镐',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('iron_pickax')) return; },
        show: "铁镐可以开采钻石矿。等等，钻石在哪里？<br>石头和矿石产出+25%",
        price: [["thought", 400], ["iron", 2050]],
        upgraded: false,
        unlocked: false
    },
    'iron_shield': {
        name: '铁盾',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('iron_shield')) return; },
        show: "全副武装。<br>探索产量增加75%",
        price: [["thought", 305], ["iron", 450]],
        upgraded: false,
        unlocked: false
    },
    'wood_process': {
        name: '切削器',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('wood_process')) return; push_button("wood_factory", "bonfire"); push_button("mechanics", "thoughts"); },
        show: "以铁质工具切削木头。<br>解锁<b>木材厂</b>",
        price: [["thought", 290], ["iron", 300]],
        upgraded: false,
        unlocked: false
    },
    'mechanics': {
        name: '机械',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('mechanics')) return; push_button("workshop_2", "bonfire"); },
        show: "建造铁质的机床。<br>解锁<b>车间</b>",
        price: [["thought", 360], ["iron", 500]],
        upgraded: false,
        unlocked: false
    },
    'iron_enhancement': {
        name: '增强铁',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('iron_enhancement')) return; unlock("steel"); push_button("alloy", "crafts"); push_button("harbor", "bonfire"); },
        show: "铁容易生锈，并且有的时候太脆了。<br>利用化学方法，能够脱去其中一部分碳，让铁更适用于建筑。<br>熔炉每秒额外消耗5矿石，产生<b>钢</b><br>解锁<b>合金</b>",
        price: [["thought", 600], ["iron", 1000], ["carbon", 2500]],
        upgraded: false,
        unlocked: false
    },
    'titanium_equip': {
        name: '钛合金装备',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('titanium_equip')) return; },
        show: "很硬的金属，很好的装备。<br>猎人、矿工和探险者的产出+50%",
        price: [["thought", 1390], ["titanium", 60], ["alloy", 50]],
        upgraded: false,
        unlocked: false
    },
    'titanium_workshop': {
        name: '钛合金生产线',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('titanium_workshop')) return; },
        show: "再次升级机床。<br>工坊与车间的效率变为1.2倍，且工匠的产出+100%",
        price: [["thought", 1390], ["titanium", 60], ["alloy", 50]],
        upgraded: false,
        unlocked: false
    },
    'uranium_extraction': {
        name: '铀开采',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('uranium_extraction')) return; },
        show: "矿井的石头里似乎有一些特别的元素。<br>矿井可以少量地产出铀",
        price: [["thought", 2550], ["titanium", 300], ["alloy", 60], ["structure", 375]],
        upgraded: false,
        unlocked: false
    },

    /*

    -- DOMESTIC AND ABROAD

    */

    'carnival': {
        name: '狂欢节',
        level: 0,
        thought: 1,
        active: true,
        togglable: false,
        clicked: function() { if (!upgrade('carnival')) return; push_button("brewery", "bonfire"); },
        show: "肆意挥霍食物可以增强人们的幸福感。<br>稳定度+20%，但是食物的消耗量+400%<br>解锁<b>酿酒厂</b><br><color='green'>食物不足时自动取消</color>",
        mutant: function() {
            // Currently brewery and potion factory are not unlocked; this will remain accurate
            let text = sprintf("<br><font color='red'>你现在的食物产量需要达到$/s才能稳定触发加成</font>", format(food_eaten() * 4));
            return text;
        },
        price: [["thought", 110], ["food", 25000]],
        upgraded: false,
        unlocked: false
    },
    'management': {
        name: '管理',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('management')) return; push_button("government", "thoughts"); push_button("education", "thoughts"); 
                                push_button("faithful", "thoughts"); },
        show: "你成为了一群人的领袖。<br>稳定度变为-0.9%/人",
        price: [["thought", 225]],
        upgraded: false,
        unlocked: false
    },
    'education': {
        name: '教育',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('education'))
                return;
            if (!get("perfect_insight").upgraded)
                get("faithful").unlocked = false;
            self_reload();
            push_button("university", "bonfire");
            push_button("research_fund", "thoughts");

            unlock("professor");
        },
        show: "<b>与信仰互斥</b><br>解锁教授与大学，取代工匠合成书<br>图书馆开始缓慢产出书",
        price: [["thought", 625], ["gold", 40], ["structure", 50]],
        upgraded: false,
        unlocked: false
    },
    'research_fund': {
        name: '研究基金',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('research_fund')) return; push_button("anthropology", "thoughts"); },
        show: "给大学拨款，让它们能够直接产出思考。",
        price: [["gold", 500]],
        upgraded: false,
        unlocked: false
    },
    'anthropology': {
        name: '人类学',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('anthropology'))
                return;
            if (!get("memory").unlocked)
                unlock("memory");
            get("memory").storage += 3;
            save_item("memory", get("memory").storage);
            push_button("fundamental", "thoughts")
        },
        show: "开始真正地深入研究上一个文明。<br>立即获得3记忆<br>思考的总量可以加成记忆的效果",
        price: [["thought", 1005], ["gold", 1000], ["book", 150]],
        upgraded: false,
        unlocked: false
    },
    'fundamental': {
        name: '基础研究',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('fundamental')) return; push_button("techno_explosion", "thoughts"); },
        show: "对理论的探索可以不时地指导现实。<br>大学开始提升科学加成。",
        price: [["thought", 1200], ["book", 220]],
        upgraded: false,
        unlocked: false
    },
    'techno_explosion': {
        name: '技术爆炸',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('techno_explosion'))
                return;
            unlock("insight");
            push_button("photoelectric", "thoughts");
            push_button("two_slit_diffraction", "thoughts");
            push_button("zlibrary", "thoughts");
            push_button("atomic_clock", "technology");
            add_navigation("technology");
        },
        show: "基础的突破层出不穷，人们的生活日新月异。<br>大学与教授开始产出<b>洞察</b>，解锁<b>科技</b>",
        price: [["book", 1000]],
        upgraded: false,
        unlocked: false
    },
    'photoelectric': {
        name: '光电效应',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('photoelectric'))
                return;
            physics++;
            push_button_if("relativity", "thoughts", "two_slit_diffraction");
        },
        show: "<b>物理研究</b><br>光电效应证明光是一种粒子。<br>教授现在可以略微增加科学加成",
        price: [["thought", 1270], ["insight", 100], ["copper", 15000]],
        upgraded: false,
        unlocked: false
    },
    'two_slit_diffraction': {
        name: '双缝衍射',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('two_slit_diffraction'))
                return;
            physics++;
            push_button_if("relativity", "thoughts", "photoelectric");
        },
        show: "<b>物理研究</b><br>双缝衍射证明光是一种波。<br>洞察现在可以略微增加科学加成",
        price: [["thought", 1315], ["glass", 8000]],
        upgraded: false,
        unlocked: false
    },
    'zlibrary': {
        name: '网络图书馆',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('zlibrary'))
                return;
            push_button("inspiration", "thoughts");
            push_button("search_engine", "thoughts");
            push_button("arXiv", "technology");
        },
        show: "将浩如烟海的书籍全部储存在网络上。<br>图书馆的效果+750%，但是每个图书馆消耗0.5电力<br><font color='green'>即使电力不足，图书馆的加成依旧可用</font><br>解锁<b>网络论文库</b>",
        price: [["book", 6000]],
        upgraded: false,
        unlocked: false
    },
    'inspiration': {
        name: '灵感激发',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('inspiration'))
                return;
        },
        show: "激发人们的灵感，产出更多的科学成果。<br>原子钟额外给予1个数学研究和1个化学研究",
        price: [["thought", 1810], ["gold", 2000], ["book", 3750]],
        upgraded: false,
        unlocked: false
    },
    'search_engine': {
        name: '搜索引擎',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('search_engine'))
                return;
            push_button("AI_prototype", "thoughts");
        },
        show: "随时随地搜索想要的信息。<br>每个网络论文库使30思考不计入遗忘",
        price: [["thought", 1725], ["titanium", 200]],
        upgraded: false,
        unlocked: false
    },
    'AI_prototype': {
        name: '人工智能原型',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('AI_prototype'))
                return;
            push_button("AI", "technology");
        },
        show: "统计互联网上的所有数据，以机器生成人类的语言。<br>解锁科技<b>人工智能</b>",
        price: [["insight", 800], ["book", 4000]],
        upgraded: false,
        unlocked: false
    },
    'relativity': {
        name: '相对论',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('relativity'))
                return;
            physics++;
            push_button("HE_lab", "technology");
            push_button("atomic_fusion", "thoughts");
        },
        show: "吹散悬在物理学大厦上的一朵乌云。<br>洞察产量+100%<br>解锁科技<b>高能物理实验室</b>",
        price: [["thought", 1315], ["glass", 8000]],
        upgraded: false,
        unlocked: false
    },
    'atomic_fusion': {
        name: '核聚变',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('atomic_fusion'))
                return;
            physics++;
            push_button("fusion_energizer", "thoughts");
            push_button("fusion_powerplant", "technology");
        },
        show: "以无尽的氢为原料，产出无尽的能源。<br>解锁科技<b>聚变发电厂</b>",
        price: [["thought", 1525], ["insight", 400], ["stone", 40000], ["iron", 6000]],
        upgraded: false,
        unlocked: false
    },
    'fusion_energizer': {
        name: '聚变供能',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('fusion_energizer'))
                return;
        },
        show: "完全取代低效的石油燃料，部分取代污染的裂变能源。<br>每秒减少48污染<br>铀的成本-15%",
        price: [["thought", 1675], ["insight", 600], ["uranium", 100]],
        upgraded: false,
        unlocked: false
    },
    'faithful': {
        name: '信仰',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade("faithful"))
                return;
            if (!get("perfect_insight").upgraded)
                get("education").unlocked = false;
            self_reload();
            push_button("cathedral", "bonfire");
            unlock("priest");
            unlock("faith");
            push_button("sincerity", "thoughts");
        },
        show: "<b>与教育互斥</b><br>解锁教堂与牧师，能够缓慢产出信仰来换取产量加成。",
        price: [["thought", 625], ["gold", 40], ["structure", 50]],
        upgraded: false,
        unlocked: false
    },
    'sincerity': {
        name: '虔诚',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade("sincerity")) return; push_button("worship", "thoughts"); },
        show: "花钱装饰教堂、培训牧师。<br>教堂能够提升稳定度，并且开始提升信仰的加成",
        price: [["gold", 500]],
        upgraded: false,
        unlocked: false
    },
    'worship': {
        name: '敬拜',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade("worship")) return; push_button("myth", "thoughts") },
        show: "将上一个文明视为神明背后的神明。<br>教堂现在可以根据信仰的总量略微加成全局产量",
        price: [["thought", 1005], ["gold", 1000], ["book", 150]],
        upgraded: false,
        unlocked: false
    },
    'myth': {
        name: '传说',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('myth')) return; push_button("arcane", "thoughts"); },
        show: "根据口口相传的神迹，推算仪式与魔法的咒语。<br>信仰的产量+30%",
        price: [["thought", 1200],  ["book", 220]],
        upgraded: false,
        unlocked: false
    },
    'arcane': {
        name: '奥秘',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('arcane'))
                return;
            unlock("magic");
            add_navigation("metaphysics");
            push_button("planetarium", "metaphysics");
            push_button("astrology", "thoughts");
            push_button("magic_theory", "thoughts");
            magics++;
        },
        show: "推翻当下的科学，建立魔法的世界。<br>教堂与牧师开始产出<b>法力</b>，解锁<b>玄学</b>",
        price: [["book", 1000]],
        upgraded: false,
        unlocked: false
    },
    'astrology': {
        name: '占星术',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('astrology'))
                return;
            magics++;
        },
        show: "观测恒星与行星的运动，干预物质与思维的运转。<br>使遗忘的指数-0.5<br>",
        price: [["thought", 1270], ["magic", 100], ["telescope", 500]],
        upgraded: false,
        unlocked: false
    },
    'magic_theory': {
        name: '魔法理论',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('magic_theory'))
                return;
            magics++;
            push_button("alchemy", "thoughts");
            push_button("potions", "thoughts");
        },
        show: "科学虽然大部推翻，但它推崇的方法依旧可靠。<br>每个魔法研究给予3%科学加成",
        price: [["thought", 1315], ["glass", 8000]],
        upgraded: false,
        unlocked: false
    },
    'alchemy': {
        name: '炼金术',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('alchemy'))
                return;
            magics++;
            push_button("alchemy_tower", "metaphysics");
            push_button("nibelungenlied", "thoughts");
            push_button_if("pollution_reuse", "thoughts", "AsHg");
        },
        show: "肆意地转化物质。<br>解锁玄学<b>炼金塔</b>",
        price: [["thought", 1410], ["stone", 24000]],
        upgraded: false,
        unlocked: false
    },
    'potions': {
        name: '炼药术',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('potions'))
                return;
            magics++;
            push_button("potion_factory", "metaphysics");
            push_button("magic_alcohol", "thoughts");
        },
        show: "小心地混合物质。<br>解锁玄学<b>炼药工厂</b>",
        price: [["thought", 1475], ["food", 90000]],
        upgraded: false,
        unlocked: false
    },
    'nibelungenlied': {
        name: '尼伯龙根之歌',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('nibelungenlied'))
                return;
            magics++;
            push_button("autoalchemy", "thoughts");
            push_button("magic_workshop", "thoughts");
        },
        show: "搜集已然死去的物质，加强法术的本源效力。<br>探索将会加成炼金塔和炼药工厂的效果",
        price: [["thought", 1580], ["discovered_area", 350000]],
        upgraded: false,
        unlocked: false
    },
    'autoalchemy': {
        name: '炼金阵眼',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('autoalchemy'))
                return;
            magics++;
            push_button("magic_powered", "thoughts");
        },
        show: "将炼金所得的物质再次祭炼，产生自发运转的炼金阵。<br>炼金塔的法力消耗-50%",
        price: [["thought", 1625], ["alloy", 300]],
        upgraded: false,
        unlocked: false
    },
    'magic_alcohol': {
        name: '灵酒',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('magic_alcohol'))
                return;
            magics++;
            push_button("magic_insight", "thoughts");
        },
        show: "将酿酒产的产出物用魔法祝福，增加人们的快感。<br>希望不会有更多人酒精中毒。<br>酿酒厂的正面与负面效果均+100%",
        price: [["thought", 1780], ["food", 155000]],
        upgraded: false,
        unlocked: false
    },
    'magic_powered': {
        name: '法术发电',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('magic_powered'))
                return;
            magics++;
            push_button("magic_powerplant", "metaphysics");
        },
        show: "通过构建稳定的法阵，产出永不枯竭的能源。<br>解锁玄学<b>法术发电厂</b>",
        price: [["thought", 1770], ["alloy", 150], ["structure", 150]],
        upgraded: false,
        unlocked: false
    },
    'magic_insight': {
        name: '灵视',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (stability() < 1.3 || !upgrade('magic_insight'))
                return;
            magics++;
        },
        show: "饮用含有魔力的液体，与天地共鸣，看到不该看到的信息。<br><font color='red'>至少需要130%稳定度才能研究</font><br>稳定度-3%<br>遗忘的效果变为60%",
        price: [["thought", 1855]],
        upgraded: false,
        unlocked: false
    },
    'magic_workshop': {
        name: '法术工坊',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('magic_workshop'))
                return;
            magics++;
        },
        show: "通过炼金术的发现，增强制造业的能力。<br>工匠的速度+100%<br>每个工坊提供的基础合成效率变为6%",
        price: [["thought", 1950], ["alloy", 550], ["book", 1200]],
        upgraded: false,
        unlocked: false
    },
    'pollution_reuse': {
        name: '污染物再利用',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('pollution_reuse'))
                return;
            magics++;
        },
        show: "提取砷汞富集器的内容物，并用炼金方法将其转化。<br>砷汞富集器收集的总污染量会提升科学加成<br>砷汞富集器的吸收速度+100%",
        price: [["thought", 2200], ["book", 1000], ["alloy", 100], ["structure", 500]],
        upgraded: false,
        unlocked: false
    },
    'government': {
        name: '政府',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('government')) return; push_button("laws", "thoughts"); },
        show: "一个人管不过来的话，多几个人来管就好了。<br>成立政府，稳定度变为-0.8%/人<br><font color='red'>贵金属的产量减少5%</font>",
        price: [["thought", 420], ["gold", 30], ["stone", 2500]],
        upgraded: false,
        unlocked: false
    },
    'laws': {
        name: '法律',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('laws')) return; push_button_if("surveillance", "thoughts", "electricity"); },
        show: "利用国家强制力维护稳定。<br>稳定度变为-0.7%/人",
        price: [["thought", 1000], ["gold", 400], ["iron", 1200]],
        upgraded: false,
        unlocked: false
    },
    'surveillance': {
        name: '监控',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() { if (!upgrade('surveillance')) return; },
        show: "设立大量的摄像头，监视每个人的一举一动。<br>稳定度变为-0.3%/人，但是额外-7%",
        price: [["thought", 2300], ["iron", 8000], ["copper", 6000], ["gold", 1200]],
        upgraded: false,
        unlocked: false
    },

    /*

    -- METAPHYSICS

    */
    'planetarium': {
        name: '星象仪',
        level: 0,
        ratio: 1.32,
        metaphysics: true,
        togglable: false,
        clicked: function() { if (!construct('planetarium')) return; },
        show: "念动晦涩的咒语，向星空借取力量。<br>",
        mutant: function() {
            let text = sprintf("信仰的效果+$%<br>每秒产出0.001法力<br>天文台的效果+135%", format(10 + 1 * get("temple").level));
            return text;
        },
        price: [["magic", 200], ["telescope", 1000]],
        unlocked: false
    },
    'alchemy_tower': {
        name: '炼金塔',
        level: 0,
        on: 0,
        ratio: 1.41,
        metaphysics: true,
        togglable: true,
        clicked: function() { if (!construct('alchemy_tower')) return; },
        show: "催动繁琐的法阵，向元素祈求回应。<br>每秒生产10铜，6.0铁，8.0煤，40钢，15贵金属以及1.0钛<br>每秒消耗0.003法力",
        price: [["magic", 150], ["stone", 28000], ["copper", 8400]],
        unlocked: false
    },
    'potion_factory': {
        name: '炼药工厂',
        level: 0,
        on: 0,
        ratio: 1.3,
        metaphysics: true,
        togglable: true,
        clicked: function() { if (!construct('potion_factory')) return; },
        show: "混合未知的物质，向世界发问原理。<br>",
        mutant: function() {
            let text = sprintf("每座炼药工厂可以让每个教堂使全局产量+$%<br>每秒消耗250食物", format((0.1 + 0.01 * get("temple").level) * (1 + Math.log(1 + get("discovered_area").storage) / Math.log(1.125) / 1000)));
            return text;
        },
        price: [["magic", 250], ["food", 100000], ["iron", 5000]],
        unlocked: false
    },
    'magic_powerplant': {
        name: '法术发电厂',
        level: 0,
        on: 0,
        ratio: 1.22,
        metaphysics: true,
        togglable: true,
        clicked: function() { if (!construct('magic_powerplant')) return; },
        show: "沟通天地的能量，向人类提供便利。<br>电力+20<br>不造成污染<br>每秒消耗0.01法力",
        price: [["magic", 600], ["copper", 10000], ["iron", 6000]],
        unlocked: false
    },
    'mundus_tree': {
        name: '世界树',
        level: 0,
        on: 0,
        ratio: 1,
        metaphysics: true,
        togglable: false,
        clicked: function() {
            if (get("mundus_tree").level >= 30)
                return;
            let success = construct("mundus_tree");
            if (success && get("mundus_tree").level >= 30) {
                // unlocks TODO
            }
        },
        show: "贯穿法术的根源，向人间输送魔力。<br>信仰和法力的产量+100%，且信仰的效果+48%",
        mutant: function() {
            let text = "";
            if (get("mundus_tree").level >= 30) {
                text += "<font color='green'>已建成</font>";
            } else
                text += sprintf("<font color='red'>还需要建造$段</font>", 30 - get("mundus_tree").level);
            return text;
        },
        price: [["magic", 900], ["wood", 1000000]],
        unlocked: false
    },
    'temple': {
        name: '寺庙',
        level: 0,
        on: 0,
        ratio: 1.36,
        metaphysics: true,
        togglable: false,
        clicked: function() { if (!construct('temple')) return; },
        show: "遵从远古的信念，向过去寻求知识。<br>古代生物的产量+15%<br>炼药工厂的加成数值增加0.01%<br>星象仪的加成数值增加2.5%<br>法术发电厂的发电+2<br>炼金塔的成本-5%",
        price: [["magic", 1600], ["ancient_bio", 50], ["glass", 20000]],
        unlocked: false
    },

    /*

    -- TECHNOLOGY

    */
    'atomic_clock': {
        name: '原子钟',
        level: 0,
        on: 0,
        ratio: 1.3,
        technology: true,
        togglable: false,
        clicked: function() { if (!construct('atomic_clock')) return; },
        show: "以铯原子的振动精确地测量时间。<br>洞察产量+20%<br>获得1个额外的物理研究",
        mutant: function() {
            let text = "";
            if (get("inspiration").upgraded)
                text += "<br>获得1个额外的数学研究<br>获得1个额外的化学研究";
            return text;
        },
        price: [["insight", 100], ["titanium", 300], ["alloy", 200], ["mineral", 30000]],
        unlocked: false
    },
    'HE_lab': {
        name: '高能物理实验室',
        level: 0,
        on: 0,
        ratio: 1.3,
        technology: true,
        togglable: true,
        clicked: function() { if (!construct('HE_lab')) return; },
        show: "在对撞机的基础上改造，合成不见于自然的元素。<br>每个高能物理实验室让每个对撞机使得全局加成+0.1%<br>产生2污染<br>消耗15电力",
        price: [["insight", 200], ["alloy", 100], ["structure", 1500]],
        unlocked: false
    },
    'arXiv': {
        name: '网络论文库',
        level: 0,
        on: 0,
        ratio: 1.38,
        technology: true,
        togglable: false,
        clicked: function() { if (!construct('arXiv')) return; },
        show: "将论文储存在网络上，让科学知识不分国界。<br>所有思考的成本-0.8%<br>所有建筑的价格-0.6%",
        mutant: function() {
            let text = "";
            if (get("search_engine").upgraded)
                text += "<br>使30思考不计入遗忘";
            return text;
        },
        price: [["insight", 250], ["book", 10000]],
        unlocked: false
    },
    'fusion_powerplant': {
        name: '聚变发电厂',
        level: 0,
        on: 0,
        ratio: 1.22,
        technology: true,
        togglable: true,
        clicked: function() { if (!construct('fusion_powerplant')) return; },
        show: "通过聚变产生近乎无限的能量。<br>电力+60<br>不产生污染<br>每秒消耗0.045洞察",
        price: [["insight", 300], ["copper", 8000], ["iron", 6000], ["gold", 1000], ["stone", 12500], ["structure", 1300]],
        unlocked: false
    },
    'AI': {
        name: '人工智能',
        level: 0,
        on: 0,
        ratio: 1.29,
        technology: true,
        togglable: true,
        clicked: function() { if (!construct('AI')) return; },
        show: "辅助人们进行几乎一切工作。<br>冶炼产量+10%<br>探索产量+40%<br>科学加成+10%<br>工匠制作效率+25%<br>稳定度+2%<br>猎人、矿工与探险者产出+15%<br>消耗50电力",
        price: [["insight", 800], ["titanium", 5500], ["alloy", 1500], ["structure", 75000]],
        unlocked: false
    },
    'supercritical_phase_shifter': {
        name: '超临界移相器',
        level: 0,
        on: 0,
        ratio: 1.33,
        technology: true,
        togglable: true,
        clicked: function() {
            if (!construct('supercritical_phase_shifter'))
                return;
        },
        show: "达到“炼金”的极致，肆意地转化物质。<br>每秒消耗1000矿石、12.5 µ反物质与40建筑结构，令全体资源的产出+14%",
        price: [["insight", 1125], ["antimatter", 0.01], ["glass", 400000], ["dark_matter", 550]],
        unlocked: false
    },
    'sequencing_center': {
        name: '测序中心',
        level: 0,
        on: 0,
        ratio: 1.24,
        technology: true,
        togglable: false,
        clicked: function() { if (!construct('sequencing_center')) return; },
        show: "完成古代生物的基因图谱。<br>",
        mutant: function() {
            let text = sprintf("古代生物的产量+$%", format(22.5 * (1 + 0.15 * get("dna_peculiarity").upgraded)));
            return text;
        },
        price: [["insight", 1750], ["ancient_bio", 15], ["book", 1350000]],
        unlocked: false
    },

    /*
     
    -- 3rd RESET: TECHNOLOGY PATH

    */
    'self_clone': {
        name: '自我克隆',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (get("sequencing_center").level <= 15 || !upgrade("self_clone"))
                return;
            push_button("colive", "thoughts");
            push_button("biounite", "thoughts");
            push_button("source_study", "thoughts");
        },
        show: "向古代生物的基因中添加新合成的碱基，让它们开始高效地自我复制。<br>需要15个测序中心才能研究<br>记忆加成开始对古代生物生效",
        price: [["thought", 100000], ["ancient_bio", 200], ["unobtainium", 1000]],
        upgraded: false,
        unlocked: false
    },
    'colive': {
        name: '伴生',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (stability() < 1.5 || !upgrade("colive"))
                return;
        },
        show: "将古代生物注入胚胎，让它增强新生人类的体质。<br><font color='red'>稳定度需要达到150%才能研究</font><br>宇航员的补给消耗-15%<br>每个宇航员按照1.2人计算",
        price: [["thought", 112500], ["insight", 6000], ["ancient_bio", 2000], ["book", 1e8]],
        upgraded: false,
        unlocked: false
    },
    'biounite': {
        name: '生物融合',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade("biounite"))
                return;
        },
        show: "将古代生物改造为低成本的生物计算机，嵌入生活的方方面面。<br>电力消耗-10%，而且可以随着古代生物的量进一步降低",
        price: [["thought", 117500], ["ancient_bio", 3000], ["gold", 200000], ["REE", 1.5e6], ["alloy", 70000]],
        upgraded: false,
        unlocked: false
    },
    'source_study': {
        name: '溯源',
        level: 0,
        thought: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade("source_study"))
                return;
        },
        show: "尝试追寻古代生物产生的源头与进化的痕迹。<br>前置研究，无效果",
        price: [["thought", 128000], ["insight", 7000], ["discovered_area", 1e8]],
        upgraded: false,
        unlocked: false
    },

    /*

    -- GENETICS

    */

    'structurize': {
        name: '结构化',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('structurize'))
                return;
            push_button("reform", "gene");
            push_button("memory_stablize", "gene");
            push_button("craftive", "gene");
            push_button("autocraft", "gene");
            push_button("hoarding", "gene");
            push_button("remnants", "gene");
        },
        show: "价格增长底数减少0.005。",
        price: [["memory", 25]],
        upgraded: false,
        unlocked: false
    },
    'reform': {
        name: '空间重构',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('reform'))
                return;
            push_button("over_optimization", "gene");
        },
        show: "价格增长底数减少0.005。",
        price: [["memory", 225]],
        upgraded: false,
        unlocked: false
    },
    'over_optimization': {
        name: '过优化',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() { if (!upgrade('over_optimization')) return; push_button("spatial_fold", "gene"); },
        show: "价格增长底数减少0.01。",
        price: [["memory", 750]],
        upgraded: false,
        unlocked: false
    },
    'spatial_fold': {
        name: '空间折叠',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() { if (!upgrade('spatial_fold')) return; },
        show: "价格增长底数减少0.015。",
        price: [["memory", 2250]],
        upgraded: false,
        unlocked: false
    },
    'space_distortion': {
        name: '空间扭曲',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() { if (!upgrade('space_distortion')) return; },
        show: "价格增长底数减少0.02。",
        price: [["memory", 4500]],
        upgraded: false,
        unlocked: false
    },
    'hoarding': {
        name: '囤积癖',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('hoarding'))
                return;
            push_button("closed_packing", "gene");
        },
        show: "每1记忆使得大部分资源的储存上限+0.015%。",
        price: [["memory", 100]],
        upgraded: false,
        unlocked: false
    },
    'closed_packing': {
        name: '最密堆积',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() { if (!upgrade('closed_packing')) return; },
        show: "每1记忆使得大部分资源的储存上限额外+0.015%。",
        price: [["memory", 600]],
        upgraded: false,
        unlocked: false
    },
    'memory_stablize': {
        name: '记忆固化',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('memory_stablize'))
                return;
            push_button("reform", "gene");
            push_button("memory_inherit", "gene");
            push_button("restep", "gene");
            push_button("governed", "gene");
        },
        show: "有1%思考（至少100）不再计入遗忘。",
        price: [["memory", 200]],
        upgraded: false,
        unlocked: false
    },
    'memory_inherit': {
        name: '记忆遗传',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() { if (!upgrade('memory_inherit')) return; push_button("memory_implant", "gene"); },
        show: "不再计入遗忘的思考增加至3.5%（至少350）。",
        price: [["memory", 1000]],
        upgraded: false,
        unlocked: false
    },
    'memory_implant': {
        name: '记忆植入',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('memory_implant'))
                return;
        },
        show: "不再计入遗忘的思考增加至8%（至少800）。",
        price: [["memory", 4000]],
        upgraded: false,
        unlocked: false
    },
    'governed': {
        name: '统一化',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('governed'))
                return;
            push_button("normalized", "gene");
        },
        show: "人数超出12时才开始减少稳定度；每人少减少0.05%稳定度。",
        price: [["memory", 175]],
        upgraded: false,
        unlocked: false
    },
    'normalized': {
        name: '归一化',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('normalized'))
                return;
        },
        show: "人数超出15时才开始减少稳定度；每人额外少减少0.05%稳定度。",
        price: [["memory", 400]],
        upgraded: false,
        unlocked: false
    },
    'craftive': {
        name: '心灵手巧',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('craftive')) 
                return;
            push_button("literacy", "gene");
        },
        show: "工匠的效率提高100%；手动制作的效率提高10%。",
        price: [["memory", 100]],
        upgraded: false,
        unlocked: false
    },
    'literacy': {
        name: '文学化',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('literacy'))
                return;
            push_button("scientize", "gene");
            push_button("reasonize", "gene");
        },
        show: "书的合成效率+100%（与其它加成乘算）。<br>工匠合成书的效率+50%。",
        price: [["memory", 375]],
        upgraded: false,
        unlocked: false
    },
    'scientize': {
        name: '科学化',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() { if (!upgrade('scientize')) return; },
        show: "书的成本-25%。<br>工匠合成书的效率+50%。",
        price: [["memory", 400]],
        upgraded: false,
        unlocked: false
    },
    'reasonize': {
        name: '理性化',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('reasonize'))
                return;
            push_button("rigidize", "gene");
        },
        show: "大学与教堂的成本-10%。<br>全体科技与玄学的成本-10%。",
        price: [["memory", 600]],
        upgraded: false,
        unlocked: false
    },
    'rigidize': {
        name: '严谨化',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('rigidize'))
                return;
            push_button_if("perfect_insight", "gene", "contigential");
        },
        show: "大学与教堂的成本额外-10%，且价格增长底数-0.04。<br>全体科技与玄学的成本额外-10%，且价格增长底数-0.04。",
        price: [["memory", 1500]],
        upgraded: false,
        unlocked: false
    },
    'perfect_insight': {
        name: '完美思绪',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade("perfect_insight"))
                return;
        },
        show: "科技与玄学现在可以同时研究。",
        price: [["memory", 4000]],
        upgraded: false,
        unlocked: false
    },
    'restep': {
        name: '回溯',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade("restep"))
                return;
            push_button("anti_flow", "gene");
            memory_elapsed = 4000;
        },
        show: "有额外2%的记忆生效，且记忆的效果+2%。<br>记忆获取的间隔减少20年；每次额外获得1记忆。",
        price: [["memory", 150]],
        upgraded: false,
        unlocked: false
    },
    'anti_flow': {
        name: '逆流',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('anti_flow'))
                return;
            push_button("memory_retrace", "gene");
            memory_elapsed = 3000;
        },
        show: "有额外4%的记忆生效，且记忆的效果+4%。<br>记忆获取的间隔减少20年；每次额外获得3记忆。",
        price: [["memory", 750]],
        upgraded: false,
        unlocked: false
    },
    'memory_retrace': {
        name: '追忆',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade('memory_retrace'))
                return;
            push_button("urgent", "gene");
            memory_elapsed = 2000;
        },
        show: "有额外6%的记忆生效，且记忆的效果+6%。<br>记忆获取的间隔减少20年；每次额外获得5记忆。",
        price: [["memory", 1750]],
        upgraded: false,
        unlocked: false
    },
    'urgent': {
        name: '紧迫感',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade("urgent"))
                return;
            push_button("frightened", "gene");
        },
        show: "最高危机等级额外+1<br>危机等级对产量的加成提高20%<br>当危机等级不低于4时，初始人数+5",
        price: [["memory", 2000]],
        upgraded: false,
        unlocked: false
    },
    'frightened': {
        name: '恐惧感',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade("frightened"))
                return;
            push_button("contigential", "gene");
        },
        show: "最高危机等级额外+2<br>危机等级对产量的加成提高35%<br>当危机等级不低于8时，遗忘的指数-0.2",
        price: [["memory", 2500]],
        upgraded: false,
        unlocked: false
    },
    'contigential': {
        name: '危机感',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade("contigential"))
                return;
            push_button_if("perfect_insight", "gene", "rigidize");
        },
        show: "最高危机等级额外+3；危机等级对产量的加成提高45%<br>当危机等级不低于12时，记忆的效果+50%",
        price: [["memory", 3000]],
        upgraded: false,
        unlocked: false
    },
    'remnants': {
        name: '遗迹',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade("remnants"))
                return;
            push_button("monument", "gene");
        },
        show: "下一周目开始时，立即解锁思考“初次接触”及其之前的全部内容",
        price: [["memory", 150]],
        upgraded: false,
        unlocked: false
    },
    'monument': {
        name: '纪念碑',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade("monument"))
                return;
        },
        show: "下一周目开始时，立即获得1000.000书",
        price: [["memory", 300]],
        upgraded: false,
        unlocked: false
    },
    'autocraft': {
        name: '自加工',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade("autocraft"))
                return;
            push_button("autoupgrade", "gene");
        },
        show: "解锁自动合成功能。<br>当某种物资即将达到上限时，自动将其合成为工艺制品。<br>视作手动合成：无法享受工匠加成，也可能被挑战禁用。<br>刷新网页后生效。",
        price: [["memory", 25]],
        upgraded: false,
        unlocked: false
    },
    'autoupgrade': {
        name: '自激发',
        level: 0,
        genetics: 1,
        togglable: false,
        clicked: function() {
            if (!upgrade("autoupgrade"))
                return;
        },
        show: "解锁自动研究功能。<br>当资源足够支付“思考”标签中某个研究的成本时，自动将其研究<br>不会进行导致重置或相互冲突的研究",
        price: [["memory", 175]],
        upgraded: false,
        unlocked: false
    },

    /*

    -- JOBS

    */

    'collector': {
        name: '采集者',
        togglable: true,
        on: 0,
        clicked: function() { turn_on('collector', 1); },
        show: "在周围的森林中采集浆果充饥，也会带回来一些枯枝备用。<br>每秒产出5食物以及2木材",
        unlocked: true
    },
    'quarry_worker': {
        name: '采石者',
        togglable: true,
        on: 0,
        clicked: function() { turn_on('quarry_worker', 1); },
        show: "寻找形状合适的石头，或者将不合适的稍稍加工。<br>每秒产出3石头",
        unlocked: false
    },
    'adventurer': {
        name: '探险者',
        togglable: true,
        on: 0,
        clicked: function() { turn_on('adventurer', 1); },
        show: "探索周围的森林。<br>每秒产出1探索",
        unlocked: false
    },
    'miner': {
        name: '矿工',
        togglable: true,
        on: 0,
        clicked: function() { turn_on('miner', 1); },
        show: "进入矿井或者矿洞，冒着危险开采矿石。<br>每秒产出0.5矿石",
        unlocked: false
    },
    'astronaut': {
        name: '宇航员',
        togglable: true,
        on: 0,
        clicked: function() { turn_on('astronaut', 1); },
        show: "经过严苛的训练才能进入太空。<br>太空的各类建筑需要宇航员才能运作<br>每秒消耗0.01补给",
        unlocked: false
    },
    'professor': {
        name: '教授',
        togglable: true,
        on: 0,
        clicked: function() { turn_on('professor', 1); },
        show: "在大学中讲课，促进书的产出。<br>每秒消耗对应的原材料，制作0.05书",
        mutant: function() {
            let text = "";
            if (get("techno_explosion").upgraded)
                text += "<br>每秒产出0.001洞察";
            
            let eff = craft_effect("book", false);
            let unary = eff * 0.025 * (1 + get("workshop_2").level * 0.1 + get("university").level * 0.1);
            text += "<br>工艺制作加成：" + percentage(eff - 1, true);
            text += sprintf("<br>单人产量：<font color='green'>$</font>/s", format(unary));
            text += sprintf("<br>总产量：<font color='green'>$</font>/s", format(unary * get("professor").on));
            return text;
        },
        unlocked: false
    },
    'priest': {
        name: '牧师',
        togglable: true,
        on: 0,
        clicked: function() { turn_on('priest', 1); },
        show: "在各处布道，不过有很大一部分喜欢留在教堂。<br>信仰加成+2.5%",
        mutant: function() {
            let text = "";
            if (get("arcane").upgraded)
                text += "<br>每秒产出0.001法力";
            return text;
        },
        unlocked: false
    },
    'craftsman_book': {
        name: '工匠-书',
        togglable: true,
        on: 0,
        clicked: function() { turn_on('craftsman_book', 1); },
        show: "每秒消耗对应的原材料，制作0.005书。",
        unlocked: false
    },
    'craftsman_structure': {
        name: '工匠-建筑结构',
        togglable: true,
        on: 0,
        clicked: function() { turn_on('craftsman_structure', 1); },
        show: "每秒消耗对应的原材料，制作0.005建筑结构。",
        unlocked: false
    },
    'craftsman_alloy': {
        name: '工匠-合金',
        togglable: true,
        on: 0,
        clicked: function() { turn_on('craftsman_alloy', 1); },
        show: "每秒消耗对应的原材料，制作0.005合金。",
        unlocked: false
    },
    'craftsman_telescope': {
        name: '工匠-望远镜',
        togglable: true,
        on: 0,
        clicked: function() { turn_on('craftsman_telescope', 1); },
        show: "每秒消耗对应的原材料，制作0.005望远镜。",
        unlocked: false
    },
    'craftsman_supply': {
        name: '工匠-补给',
        togglable: true,
        on: 0,
        clicked: function() { turn_on('craftsman_supply', 1); },
        show: "每秒消耗对应的原材料，制作0.005补给。",
        unlocked: false
    },
    'craftsman_superconductor': {
        name: '工匠-超导体',
        togglable: true,
        on: 0,
        clicked: function() { turn_on('craftsman_superconductor', 1); },
        show: "每秒消耗对应的原材料，制作0.005超导体。",
        unlocked: false
    },


    /*

    -- CRAFTINGS

    */

    'book': {
        name: '书',
        storage: 0,
        togglable: false,
        clicked: function() { craft("book"); },
        show: "书可以略微减缓遗忘的速度以及增加思考的产出。<br><b>该效果有上限</b>",
        price: [["paper", 30], ["fur", 10]],
        upgraded: false,
        craftable: true,
        unlocked: false
    },
    'structure': {
        name: '建筑结构',
        storage: 0,
        togglable: false,
        clicked: function() { craft("structure"); },
        show: "木头和石头做成的大型结构，在建筑中频繁用到。",
        price: [["wood", 150], ["stone", 200]],
        upgraded: false,
        craftable: true,
        unlocked: false
    },
    'alloy': {
        name: '合金',
        storage: 0,
        togglable: false,
        clicked: function() { craft("alloy"); },
        show: "以铁为主的合金。比建筑结构更加坚固，因此使用更加频繁。",
        price: [["iron", 250], ["copper", 350], ["carbon", 450]],
        upgraded: false,
        craftable: true,
        unlocked: false
    },
    'telescope': {
        name: '望远镜',
        storage: 0,
        togglable: false,
        clicked: function() { craft("telescope"); },
        show: "两个简单的凸透镜的组合。<br>使天文台的效果增加0.1%<br><b>该效果有上限</b>",
        price: [["glass", 200]],
        upgraded: false,
        craftable: true,
        unlocked: false
    },
    'supply': {
        name: '补给',
        storage: 0,
        togglable: false,
        clicked: function() { craft("supply"); },
        show: "为宇航员准备的食物。",
        price: [["food", 100000]],
        upgraded: false,
        craftable: true,
        unlocked: false
    },
    'superconductor': {
        name: '超导体',
        storage: 0,
        togglable: false,
        clicked: function() { craft("superconductor"); },
        show: "在常温下没有电阻，是曾经科学家们梦寐以求的材料。",
        price: [["steel", 75000], ["mineral", 20000], ["REE", 2000], ["dark_matter", 800]],
        upgraded: false,
        craftable: true,
        unlocked: false
    },

    /*

    -- CHALLENGES

    */
    'catastrophe': {
        name: '灾难',
        level: 3,
        on: 0,
        challenge: "default",
        togglable: true,
        clicked: function() {},
        show: "上一场文明毁灭得过于突然，他们留下的记忆语焉不详。<br>1级：生效的记忆数量-75%<br>2级：记忆的效果只有25%<br>3级：在2级的基础上，记忆的生效数量-100%",
        unlocked: false
    },
    'memory_loss': {
        name: '失忆',
        level: 3,
        on: 0,
        challenge: "default",
        togglable: true,
        clicked: function() {},
        show: "思考并不容易，遗忘困扰着所有人。<br>1级：遗忘的基础指数变为3.5<br>2级：遗忘的基础指数变为4，并且效果+50%<br>3级：遗忘的基础指数变为4.5，并且效果+100%",
        unlocked: false
    },
    'clumsy': {
        name: '笨拙',
        level: 3,
        on: 0,
        challenge: "default",
        togglable: true,
        clicked: function() {},
        show: "在笨拙的操作中，制作原料常常有惊人的损耗。<br>1级：合成效率-15%<br>2级：合成效率-30%，成本增加25%<br>" +
            "3级：合成效率-45%，基础成本+50%",
        unlocked: false
    },
    'gluttony': {
        name: '暴食',
        level: 3,
        on: 0,
        challenge: "default",
        togglable: true,
        clicked: function() {},
        show: "对食物的贪婪正在困扰着整个种族。<br>1级：食物的消耗量变为人数的二次函数<br>2级：食物的消耗量变为人数的三次函数<br>3级：在2级的基础上，食物的消耗量额外+200%",
        unlocked: false
    },
    'professional': {
        name: '专业要求',
        level: 1,
        on: 0,
        challenge: "default",
        togglable: true,
        clicked: function() {},
        show: "人们不希望业余的人来掺和复杂物品的制作。<br>现在只能通过工匠合成物品。<br><b>价值2危机等级</b>",
        unlocked: false
    },
    'redundancy': {
        name: '冗余',
        level: 3,
        on: 0,
        challenge: "default",
        togglable: true,
        clicked: function() {},
        show: "在利用有限的空间时，人们总是在做无用功。<br>1级：价格增长底数增加0.02<br>2级：价格增长底数增加0.04<br>3级：价格增长底数增加0.06",
        unlocked: false
    },
    'inefficiency': {
        name: '低效',
        level: 3,
        on: 0,
        challenge: "space",
        togglable: true,
        clicked: function() {},
        show: "燃烧的能量消散殆尽，补给的运输难以为继。<br>1级：燃料与补给的消耗+20%<br>2级：燃料与补给的消耗+75%<br>3级：燃料与补给的消耗+160%",
        unlocked: false
    },
    'unordered': {
        name: '失序',
        level: 3,
        on: 0,
        challenge: "space",
        togglable: true,
        clicked: function() {},
        show: "散乱的资源散落一地，无人愿意整理。<br>1级：资源上限降低10%<br>2级：资源上限降低35%<br>3级：资源上限降低60%",
        unlocked: false
    },
    'resistance': {
        name: '电阻',
        level: 3,
        on: 0,
        challenge: "space",
        togglable: true,
        clicked: function() {},
        show: "电力的传输损耗惊人。<br>1级：耗电量+20%<br>2级：耗电量+50%<br>3级：耗电量+50%，且发电量-50%",
        unlocked: false
    },
    'kenka': {
        name: '喧哗',
        level: 3,
        on: 0,
        challenge: "space",
        togglable: true,
        clicked: function() {},
        show: "自由的想法层出不穷，你的管理成效不佳。<br>1级：稳定度给予的加成-50%<br>2级：稳定度给予的加成-75%，且稳定度-10%<br>3级：稳定度给予的加成-90%，且稳定度-20%",
        unlocked: false
    },
    'endeavour': {
        name: '启航',
        level: 0,
        on: 0,
        challenge: "space",
        togglable: false,
        clicked: function() {
            get("challenge").unlocked = false;
            $("float").style.display = "none";
            init_0();
            render_craft();
            render_auto();
        },
        show: "开始重建文明<br>完成过的最高危机等级将会提供永久加成<br>危机等级加成本周目的记忆获取",
        mutant: function() { return "<br><font color = 'red'>危机等级 " + challenge_level() + "</font>"; },
        unlocked: false
    },

    /*

    -- DIVS

    */

    'bonfire': {
        name: '野外',
        unlocked: false
    },
    'space': {
        name: '太空',
        unlocked: false
    },
    'society': {
        name: '人力',
        unlocked: false
    },
    'thoughts': {
        name: '思考',
        unlocked: false
    },
    'crafts': {
        name: '制作',
        unlocked: false
    },
    'metaphysics': {
        name: '玄学',
        unlocked: false
    },
    'technology': {
        name: '科技',
        unlocked: false
    },
    'gene': {
        name: '基因',
        unlocked: false
    },
    'settings_auto': {
        name: '自动',
        unlocked: false
    },
    'statistics': {
        name: '统计',
        unlocked: true
    },
    'challenge': {
        name: '挑战',
        unlocked: false
    },
}

let get = function(x) {
    return dictionary[x] ?? load_item(x);
}

let unlock = function(x) {
    get(x).unlocked = true;
    if (get(x).craftable)
        render_craft();
}

let derationate = function(id) {
    let x = get(id).ratio;
    x += get("redundancy").on * 0.02;
    let after = x;
    after -= 0.01 * get("engineering_mechanics").upgraded;
    after -= 0.003 * get("engineering_maths").upgraded;
    after -= 0.002 * get("kaiseki_geometry").upgraded;
    after -= 0.005 * get("reform").upgraded;
    after -= 0.005 * get("structurize").upgraded;
    after -= 0.01 * get("over_optimization").upgraded;
    after -= 0.015 * get("spatial_fold").upgraded;
    after -= 0.02 * get("space_distortion").upgraded;
    after -= 0.0005 * get_level();
    after -= 0.001 * Math.sqrt(1 + get("relic").storage);

    if (get(id).technology || get(id).metaphysics || id == "university" || id == "cathedral") {
        after -= 0.04 * get("rigidize").upgraded;
    }

    return x - dim(x - after, x - 1.01);
}

let construct = function(x) {
    let limited = {
        LHC: 25,
        mundus_tree: 30,
        dyson_sphere: 100,
        mars_reform_device: 100,
    };

    let building = get(x);
    if (limited[x] && building.level >= limited[x])
        return 0;
    let ev = window.event;
    let price = requirement(x);
    if (price.find(function(need) { return get(need[0]).storage < need[1]; }) !== undefined)
        return 0;
    price.forEach(function(need) { if (is_consumed(need[0])) get(need[0]).storage -= need[1] });
    building.level += 1;
    if (building.togglable && (building.on !== 0 || building.level === 1))
        building.on += 1;
    $(x).innerHTML = building.name + " (" + (building.togglable ? building.on + "/" : "") +  building.level + ")";
    show($(x), x);
    if (ev.shiftKey)
        return 1 + construct(x);
    return 1;
}

let turn_on = function(x, delta) {
    let ev = window.event;
    let mult = 1;
    if (ev.ctrlKey)
        mult = 100;
    else if (ev.altKey)
        mult = 10;
    delta *= mult;
    let building = get(x);
    if (!building.togglable)
        return;
    if (building.level === undefined) {
        if (ev.shiftKey)
            delta = (delta < 0 ? -building.on : get("person").storage);
        let old_on = building.on, old_ava = get("person").storage;
        building.on += delta;
        get("person").storage -= delta;
        if (get("person").storage < 0 || building.on < 0 || get("person").storage > get("person").capacity) {
            get("person").storage = old_ava;
            building.on = old_on;
        }
        $(x).innerHTML = building.name + " (" + building.on + ")";
    } else {
        if (ev.shiftKey)
            delta = (delta < 0 ? -1e9 : 1e9);
        building.on += delta;
        building.on = Math.min(building.level, Math.max(building.on, 0));
        $(x).innerHTML = building.name + " (" + building.on + "/" +  building.level + ")";
    }	
}

let is_consumed = function(x) {
    return ["thought", "discovered_area"].find(function(y) { return x == y; }) === undefined;
}

let is_craftable = function(x) {
    return get(x).craftable;
}

let upgrade_genetics = function(x) {
    if (genetics_upgrades.findIndex((y) => y == x) == -1)
        genetics_upgrades.push(x);
}

let upgrade = function(x, enforce) {
    let science = get(x);
    if (science.genetics && enforce)
        upgrade_genetics(x);
    if (science.upgraded) {
        self_reload();
        return true;
    }
    let price = enforce ? [] : requirement(x);
    if (price.find(function(need) { return get(need[0]).storage < need[1]; }) !== undefined)
        return false;
    price.forEach(function(need) {
        if (is_consumed(need[0]))
            get(need[0]).storage -= need[1];
        if (need[0] == "memory")
            save_item("memory", get(need[0]).storage);
        if (!is_craftable(need[0]))
            return;
        let x = need[0];
        $(x).innerHTML = get(x).name + ": " + format(get(x).storage);
    });
    science.upgraded = true;
    self_reload();
    if (science.genetics && !enforce)
        upgrade_genetics(x);
    return true;
}

let craft_effect = function(x, is_manual) {
    let base = 1;
    base += (get("magic_workshop").upgraded ? 0.06 : 0.045) * get("workshop").level * (1 + get("titanium_workshop").upgraded * 0.2);
    base += (0.035 * get("workshop_2").level * (1 + get("titanium_workshop").upgraded * 0.2) * (1 + !is_manual));
    base += 0.1 * (electricity > 0) * get("factory").on;
    base += 0.25 * (electricity > 0) * get("AI").on;

    if (x == "book") {
        if (get("literacy").upgraded)
            base *= 2;
        if (!is_manual)
            base *= 1 + 0.5 * get("literacy").upgraded + 0.5 * get("scientize").upgraded;
    }
    if (x == "structure") {
        if (get("sin_cos_tan").upgraded)
            base += 0.03 * get("workshop").level;
    }

    base *= (1 + (get("craftive").upgraded ? (is_manual ? 0.1 : 1) : 0));
    base *= (1 + (get("magic_workshop").upgraded ? (is_manual ? 0.1 : 1) : 0));
    base *= (1 - 0.15 * get("clumsy").on);
    if (!is_manual) {
        base *= (1 + global_buffs() * 0.15);
        base *= (1 + get("titanium_workshop").upgraded);
    }
    return base;
}

let craft = function(x, n, is_percent) {
    let more = (get("clumsy").on >= 2 ? 0.75 + 0.25 * get("clumsy").on : 1);
    let ev = window.event;
    let mult = 1;
    let craft = get(x);
    let price = requirement(x);
    let craftmax = price.reduce(function(mult, need) { return Math.min(mult, parseInt(get(need[0]).storage / need[1] / more)); }, 1e9);
    if (is_percent && n) {
        mult = craftmax * n / 100;
    } else if (n) {
        mult = Math.min(craftmax, n);
    } else if (ev.shiftKey) {
        mult = craftmax;
    } else if (ev.ctrlKey) {
        mult = Math.min(craftmax, 100);
    } else if (ev.altKey) {
        mult = Math.min(craftmax, 10);
    }
    mult = Math.trunc(mult);
    if (price.find(function(need) { return get(need[0]).storage < mult * need[1] * more; }) !== undefined)
        return false;
    price.forEach(function(need) { if (is_consumed(need[0])) get(need[0]).storage -= mult * need[1] * more; });
    craft.storage += mult * craft_effect(x, true);
    $(x).innerHTML = get(x).name + ": " + format(craft.storage);
    // show($(x), x);
    return true;
}

let format = function(x) {
    let sign = (x < 0 ? -1 : 1);
    let text = "<BUG>";
    x *= sign;
    if (x < 1e-9)
        return "0.000";

    if (x < 1e21)
        text = (x / 1e18).toFixed(3) + "E";
    if (x < 1e18)
        text = (x / 1e15).toFixed(3) + "P";
    if (x < 1e15)
        text = (x / 1e12).toFixed(3) + "T";
    if (x < 1e12)
        text = (x / 1e9).toFixed(3) + "G";
    if (x < 1e9)
        text = (x / 1e6).toFixed(3) + "M";
    if (x < 1e6)
        text = (x / 1e3).toFixed(3) + "K";
    if (x < 1e3)
        text = x.toFixed(3);
    if (x < 1e-3)
        text = (x * 1e6).toFixed(3) + "µ";
    return (sign == 1 ? "" : "-") + text;
}

let time_format = function(x) {
    x = parseInt(x);
    if (x <= 60)
        return x + "s";
    if (x <= 3600)
        return parseInt(x / 60) + "min " + (x % 60) + "s";
    if (x <= 86400)
        return parseInt(x / 3600) + "h " + parseInt((x % 3600) / 60) + "min " + (x % 60) + "s";
    if (x <= 31536000)
        return parseInt(x / 86400) + "d " + parseInt((x % 86400) / 3600) + "h";
    return "永不";
}

let requirement = function(id) {
    // Deep clone price; normal cloning won't have effect since price is an array of arrays
    let price = JSON.parse(JSON.stringify(get(id).price));
    let what = get(id);
    let building_ratio = 1 - get("newton_3").upgraded * 0.05;
    let science_ratio = 1 - get("epsilon").upgraded * 0.012;

    building_ratio *= Math.pow(0.994, get("arXiv").level);
    science_ratio *= Math.pow(0.992, get("arXiv").level);
    if (id == "alchemy_tower")
        building_ratio *= Math.pow(0.95, get("temple").level);
    if (id == "dyson_sphere")
        building_ratio *= Math.pow(0.97, get("mercury_station").level);
    for (let i = 0; i < price.length; i++) {
        let elem = price[i];
        let requirement = 0;
        if (what.level === undefined || what.genetics)
            requirement = elem[1];
        else if (what.ratio == 1)
            requirement = elem[1] * science_ratio;
        else
            requirement = elem[1] * Math.pow(derationate(id), what.level) * building_ratio;
        if (what.technology || what.metaphysics || id == "university" || id == "cathedral")
            requirement *= 1 - 0.1 * get("reasonize").upgraded - 0.1 * get("rigidize").upgraded;
        if (what.craftable && get("clumsy").on >= 2)
            requirement *= 1 + 0.25 * (get("clumsy").on - 1);
        if (id == "book" && get("scientize").upgraded)
            requirement *= 0.75;
        if (id == "book" && get("writing_training").upgraded)
            requirement *= Math.pow(0.99 - 0.075 * get("zlibrary").upgraded, get("library").level);
        if (elem[0] == "uranium" && get("fusion_energizer").upgraded)
            requirement *= 0.85;
        price[i][1] = requirement;
    }
    return price;
}

let price_string = function(x) {
    let res = get(x);
    let prod = production();
    if (res.price === undefined)
        return "";
    return "<br>" + requirement(x).reduce(function(total, elem) {
        let requirement = elem[1];
        let text = total + "<br>" + get(elem[0]).name + ": ";
        if (requirement > get(elem[0]).storage) { // not enough resource
            text += "<font color=red>" + format(requirement);
            if (prod[elem[0]] > 0)
                text += "  [" + time_format((requirement - get(elem[0]).storage) / prod[elem[0]]) + "]";
            text += "</font>";
        } else text += format(requirement);
        
        return text;
    }, "");

}

// diminishing returns, the same as KittensGame
// x -> 3L/4 + (1 - (L/4) / ((x - 3L/4) + L/4)) if x is above 3L/4
let dim = function(x, limit) {
    return x < limit * 0.75 ? x : (16 * x * limit - 9 * limit * limit) / (16 * x - 8 * limit);
}

let challenge_level = function() {
    return get("clumsy").on + get("catastrophe").on + get("memory_loss").on + 2 * get("professional").on + get("gluttony").on + get("redundancy").on +
           get("kenka").on + get("unordered").on + get("inefficiency").on + get("resistance").on;
}

let show_type = null;
let show_string = function(id) {
    let base = get(id).show + (get(id).mutant ? get(id).mutant() : "") + price_string(id);
    if (is_craftable(id)) {
        let eff = percentage(craft_effect(id, true) - 1, true);
        base += "<br>工艺制作加成：" + eff;
    }
    if (id.startsWith("craftsman_")) {
        let eff = craft_effect(id.substring(10), false);
        let unary = eff * 0.0025 * (1 + get("workshop_2").level * 0.1);
        base += "<br>工艺制作加成：" + percentage(eff - 1, true);
        base += sprintf("<br>单人产量：<font color='green'>$</font>/s", format(unary));
        base += sprintf("<br>总产量：<font color='green'>$</font>/s", format(unary * get(id).on));
    }
    return base;
}

let show = function(self, type) {
    if (self == null || type == null)
        return;
    show_type = type;

    let float = $("float");
    let text = show_string(type);
    float.innerHTML = text;
    float.style.display = "block";
    let estimated_h = float.offsetHeight;

    let place = self.getBoundingClientRect();
    let height = window.innerHeight;
    let x = place.left + place.width + 50 * get(type).togglable;
    let y = Math.min(height - estimated_h - 15, place.top) + window.scrollY;
    float.style.left = x + "px";
    float.style.top = y + "px";
}

let hide = function() {
    show_self = null;
    show_type = null;
    $("float").style.display = "none";
}

let save_item = function(id, val) {
    localStorage.setItem(id, JSON.stringify( { value: val }));
}

let load_item = function(id) {
    if (localStorage.getItem(id) == null) {
        console.log("item not loaded: ", id);
        return null;
    }
    return JSON.parse(localStorage.getItem(id)).value;
}

let to_base64 = function(text) {
    return btoa(String.fromCharCode(...new TextEncoder().encode(text)));
}
  
let from_base64 = function(text) {
    return new TextDecoder().decode(Uint8Array.from(atob(text), (c) => c.charCodeAt(0)));
}

let save_import = function() {
    let save_str = prompt("请将存档粘贴到此处：");
    let object = JSON.parse(from_base64(save_str));
    console.log(object);
    let keys = Object.keys(object);
    for (let i = 0; i < keys.length; i++) {
        let key = keys[i];
        if (object[key].from_save) {
            globalThis[key] = object[key].value;
        }
        else assign(key, object[key]);
    }
    save();
    location.reload();
}

let save_export = function() {
    save();
    let temp_config = {};
    Object.keys(localStorage).forEach((key) => key != "saving" && (temp_config[key] = { value: load_item(key), from_save: true }));
    let save_blob = new Blob([to_base64(JSON.stringify(Object.assign(temp_config, dictionary)))], { type: "text/plain" });
    let download_link = document.createElement("a");
    let date = new Date();
    download_link.download  = sprintf("AdCaelum savefile $-$-$ $-$-$.txt",
        date.getFullYear(), date.getMonth() + 1, date.getDate(),
        date.getHours(), date.getMinutes(), date.getSeconds());
    download_link.href = window.URL.createObjectURL(save_blob);
    download_link.style.display = "none";
    document.body.appendChild(download_link);

    download_link.click();
}

let save = function() {
    save_item("time", time);
    save_item("physics", physics);
    save_item("chemistry", chemistry);
    save_item("maths", maths);
    save_item("magics", magics);
    save_item("current_nav", current_nav);
    save_item("electricity", electricity);
    save_item("pollution", pollution);
    save_item("pollution_guided", pollution_guided);
    save_item("autoc_storage", autoc_storage);
    save_item("autoc_ratio", autoc_ratio);
    save_item("autou_storage", autou_storage);
    save_item("autou_ratio", autou_ratio);
    save_item("genetics_upgrades", genetics_upgrades);
    save_item("last_memory", last_memory);
    save_item("memory_elapsed", memory_elapsed);
    save_item("highest_lvl", highest_lvl);
    save_item("priorities", priorities);
    save_item("memory", get("memory").storage);
    save_item("history", get("history").storage);
    save_item("relic", get("relic").storage);
    save_item("saving", JSON.stringify(dictionary));
}

let activate_gene = function() {
    if (!load_item("genetics_upgrades"))
        return;
    
    genetics_upgrades = load_item("genetics_upgrades");
    for (let i = 0; i < genetics_upgrades.length; i++) {
        upgrade(genetics_upgrades[i], true);
        get(genetics_upgrades[i]).clicked();
    }

    
    if (get("remnants").upgraded && !get("first_contact").upgraded) {
        add_navigation("thoughts");
        [
            "discussion", "storage_upgrade", "sun_indicator",
            "record", "directions", "stoneage", "craftsman",
            "slingshot", "stone_sword", "stone_ax", "first_contact"
        ].forEach((id) => {
            upgrade(id, true);
            get(id).clicked();
        });
    }
    if (get("urgent").upgraded && challenge_level() >= 4) {
        get("person").capacity += 5;
        get("person").storage += 5;
    }
    if (get("monument").upgraded && !get("book").unlocked) {
        unlock("book");
        get("book").storage += 1000;
    }
    if (get("autocraft").upgraded) {
        add_navigation("settings_auto");
    }
}

let assign = function(id, val) {
    if (!dictionary[id]) {
        console.log("item not found at assign(): ", id);
        return;
    }
    let clicked = dictionary[id].clicked;
    let mutant = dictionary[id].mutant;
    dictionary[id] = val;
    dictionary[id].clicked = clicked;
    dictionary[id].mutant = mutant;
}

let load = function() {
    let saving = load_item("saving");
        
    time = load_item("time");
    memory_elapsed = load_item("memory_elapsed") ?? 5000;
    last_memory = load_item("last_memory") ?? 0;
    physics = load_item("physics") ?? 0;
    chemistry = load_item("chemistry") ?? 0;
    maths = load_item("maths") ?? 0;
    magics = load_item("magics") ?? 0;
    electricity = load_item("electricity") ?? 0;
    pollution = load_item("pollution") ?? 0;
    pollution_guided = load_item("pollution_guided") ?? 0;
    current_nav = load_item("current_nav") ?? "bonfire";
    autoc_ratio = load_item("autoc_ratio") ?? 0.95;
    autoc_storage = load_item("autoc_storage") ?? 0.8;
    autou_ratio = load_item("autou_ratio") ?? 0.2;
    autou_storage = load_item("autou_storage") ?? 0.2;
    highest_lvl = load_item("highest_lvl") ?? 0;
    genetics_upgrades = load_item("genetics_upgrades") ?? [];
    priorities = load_item("priorities") ?? {};
    get("memory").storage = load_item("memory") ?? 0;
    get("history").storage = load_item("history") ?? 0;
    get("relic").storage = load_item("relic") ?? 0;

    if (load_item("to_prestige") == 1) {
        init_1();
        save_item("to_prestige", 0);
        return true;
    }
    if (!saving) {
        init_0();
        return false;
    }
    let dict = JSON.parse(saving);
    let keys = Object.keys(dict);
    for (let i = 0; i < keys.length; i++) {
        assign(keys[i], dict[keys[i]]);
    }
    
    self_reload();
    render_craft();
    render_auto();
    
    activate_gene();
    change_navigation(current_nav);
    return true;
}

let delete_save = function(no_reload) {
    save_item("saving", "");
    save_item("time", 0);
    save_item("physics", 0);
    save_item("chemistry", 0);
    save_item("maths", 0);
    save_item("magics", 0);
    save_item("last_memory", 0);
    save_item("current_nav", "bonfire");
    save_item("electricity", 0);
    save_item("pollution", 0);
    save_item("pollution_guided", 0);
    save_item("memory", get("memory").storage);
    save_item("history", get("history").storage);
    save_item("relic", get("relic").storage);
    save_item("genetics_upgrades", genetics_upgrades);
    save_item("highest_lvl", highest_lvl);
    if (!no_reload)
        location.reload();
}

let hard_reset = function() {
    let text = prompt("硬重置会永久删除你的存档！如果一定要这么做，请输入'Yes'。");
    if (!(text == "Yes" || text == "yes" || text == "'Yes'" || text == "Y" || text == "y"))
        return;
    localStorage.clear();
    location.reload();
}

let change_navigation = function(x) {
    let lis = $("nav").getElementsByTagName("li");
    for (let i = 0; i < lis.length; i++)
        lis[i].class = "";
    for (let i = 0; i < divs.length; i++)
        $(divs[i]).style.display = "none";
    $(x).style.display = "block";
    current_nav = x;
    self_reload();
    refresh_button();
}

let add_navigation = function(x) {
    $("nav").innerHTML += "<li onclick=\"change_navigation('" + x + "')\">" + get(x).name +"</li>";
    unlock(x);
    divs.push(x);
}

let setguide = function(text) {
    let guide = $("guide");
    guide.innerHTML = text + "<br>" + guide.innerHTML;
}

let push_button_0 = function(x, place, disable_click) {
    let content = $("content_" + place);
    let last_row = content.rows[content.rows.length - 1];

    let td = document.createElement("td");
    if (last_row.cells.length < 2) {
        last_row.appendChild(td);
    } else {
        let tr = document.createElement("tr");
        tr.appendChild(td);
        content.appendChild(tr);
    }
    let item = get(x);
    unlock(x);

    let button = document.createElement("button");
    button.id = x;
    button.className = "button-border";
    if (item.togglable)
        button.className += " game-button-togglable";
    else
        button.className += " game-button";

    button.innerHTML = item.name;
    td.appendChild(button);

    if (!disable_click)
        $(x).onclick = item.clicked;
    $(x).onmouseover = show.bind(null, $(x), x);
    $(x).onmouseleave = hide;

    if (item.togglable) {
        let plus = document.createElement("button");
        plus.id = x + '+';
        plus.className = "button-border toggler";
        plus.innerHTML = "+";
        td.appendChild(plus);

        let minus = document.createElement("button");
        minus.id = x + '-';
        minus.className = "button-border toggler";
        minus.innerHTML = "-";
        td.appendChild(minus);

        if (!disable_click) {
            $(plus.id).onclick = turn_on.bind(null, x, 1);
            $(minus.id).onclick = turn_on.bind(null, x, -1);
        }
    }
}

let push_button = function(x, place) {
    if (place == "crafts" && get("craftsman").upgraded)
        push_button_0("craftsman_" + x, "society");
    push_button_0(x, place, false);
    
    self_reload();
}

let push_button_if = function(x, place, condition) {
    if (!get(condition).upgraded)
        return;
    push_button(x, place);
}

// refreshes all buttons in all divs
let self_reload = function() {
    // deal with special circumstances
    let displayed = "display: block";
    if (get("craftsman").upgraded)
        $("craftsman_show").style = displayed;
    if (get("moon_probe").upgraded)
        $("moon_show").style = displayed;
    if (get("mars_launch").upgraded)
        $("mars_show").style = displayed;
    if (get("mercury_discovery").upgraded)
        $("mercury_show").style = displayed;
    if (get("asteroid_discovery").upgraded)
        $("asteroid_show").style = displayed;
    if (get("sun_launch").upgraded)
        $("sun_show").style = displayed;

    let keys = Object.keys(dictionary);
    let empty = "<tr></tr>";

    // first, clear all tabs and buttons
    $("nav").innerHTML = "";
    $("content_bonfire").innerHTML = empty;
    $("content_space_moon").innerHTML = empty;
    $("content_space_mercury").innerHTML = empty;
    $("content_space_mars").innerHTML = empty;
    $("content_space_asteroid").innerHTML = empty;
    $("content_space_sun").innerHTML = empty;
    $("content_thoughts").innerHTML = empty;
    $("content_thoughts_completed").innerHTML = empty;
    $("content_society").innerHTML = empty;
    $("content_society_craftsman").innerHTML = empty;
    $("content_crafts").innerHTML = empty;
    $("content_challenge_default").innerHTML = empty;
    $("content_challenge_space").innerHTML = empty;
    $("content_gene").innerHTML = empty;
    $("content_gene_completed").innerHTML = empty;
    $("content_metaphysics").innerHTML = empty;
    $("content_technology").innerHTML = empty;

    // then, add the available buttons and tabs back
    for (let i = 0; i < keys.length; i++) {
        let building_text = (item) =>
            item.name + (item.level == 0 ? "" : (" (" + (item.togglable ? item.on + "/" : "") + item.level + ")"));
        let name = keys[i];
        let item = dictionary[keys[i]];
        if (!item.unlocked) continue;
        if (!item.show) { // it is a resource or a navigation tab
            if (resources.find(function(elem) { return elem == name; }) !== undefined) continue;
            add_navigation(name);
            continue;
        }
        if (item.challenge) {
            push_button_0(name, "challenge_" + item.challenge);
            $(name).innerHTML = item.name + " (" + item.on + "/" + item.level + ")";
        } else if (item.genetics) {
            if (!item.upgraded)
                push_button_0(name, "gene");
            else if ($("show_completed_gene").checked)
                push_button_0(name, "gene_completed", true);
        } else if (item.spatial) {
            push_button_0(name, "space_" + item.spatial);
            $(name).innerHTML = building_text(item);
        } else if (item.metaphysics) {
            push_button_0(name, "metaphysics");
            $(name).innerHTML = building_text(item);
        } else if (item.technology) {
            push_button_0(name, "technology");
            $(name).innerHTML = building_text(item);
        } else if (is_craftable(name)) {
            push_button_0(name, "crafts");
            $(name).innerHTML = item.name + ": " + format(item.storage);
        } else if (item.thought) {
            if (!item.upgraded)
                push_button_0(name, "thoughts");
            else if ($("show_completed_thoughts").checked)
                push_button_0(name, "thoughts_completed", true);
        } else if (!item.price) {
            push_button_0(name, name.startsWith("craftsman_") ? "society_craftsman" : "society");
            $(name).innerHTML = item.name + " (" + item.on + ")";
        } else {
            push_button_0(name, "bonfire");
            $(name).innerHTML = building_text(item);
        }
    }
}

let botany = function() {
    if (!get("botany_knowledge").upgraded)
        return 0;
    let base = Math.log(1 + get("discovered_area").storage) / Math.log(1.125) / 1500;
    base *= (1 + get("inherit").upgraded);
    base *= (1 + get("artificial_biome").upgraded);
    return base;
}

let forgetting_ignored = function() {
    let base = 0;
    base += get("atoms_and_molecules").upgraded * 100;
    base += get("arXiv").level * 30;

    let from_crispr = 0;
    if (get("memory_stablize").upgraded)
        from_crispr = 0.01;
    if (get("memory_inherit").upgraded)
        from_crispr = 0.035;
    if (get("memory_implant").upgraded)
        from_crispr = 0.08;

    return base + Math.max(get("thought").storage, 10000) * from_crispr;
}

let forgetting_ratio = function() {
    let deration = 0.0001 * get("book").storage;
    deration *= 1 + get("basic_science").upgraded;
    deration = dim(deration, 0.3);
    deration *= 1 + 0.01 * get("library").level * get("book_categorization").upgraded * (1 + 7.5 * get("zlibrary").upgraded);
    deration += 0.0025 * get("research_lab").level;

    let deration_max = 0.1 * (1 + 0.6 * get("basic_science").upgraded);
    deration_max += 0.001 * get("research_lab").level;
    deration_max += 0.001 * get("library").level * (1 + 7.5 * get("zlibrary").upgraded);
    deration_max = dim(deration_max, 0.5);

    let base_ratio = 3 + get("memory_loss").on * 0.5;
    base_ratio -= 0.5 * get("astrology").upgraded;
    base_ratio -= 0.2 * get("frightened").upgraded * (challenge_level() >= 8);

    return base_ratio - dim(deration, deration_max);
}

let forgetting_denominator = function() {
    let denominator = 4e5;
    denominator *= (1 + 9 * get("record").upgraded);
    denominator += 10 * dim(get("book").storage, 10000) * (1 + 9 * get("basic_science").upgraded);
    denominator *= (1 + 0.05 * get("chemlab").level);
    denominator /= (1 - 0.4 * get("magic_insight").upgraded);
    let mult = 1 + Math.max(0, get("memory_loss").on * 0.5 - 0.5);
    return denominator / mult;
}

let forgetting = function() {
    return 1 + Math.pow(Math.max(0, get("thought").storage - forgetting_ignored()), forgetting_ratio()) / forgetting_denominator();
}

let book_effect = function() {
    let base = 1 + dim(get("book").storage * 0.01, 4);
    base *= (1 + 0.002 * get("library").level * (1 + 7.5 * get("zlibrary").upgraded) * (1 + get("book_categorization").upgraded));
    base *= (1 + get("algebra").upgraded * 0.15);
    return base;
}

let newton_1 = function() {
    let base = physics * 0.005;
    if (get("pv_nrt").upgraded)
        base += chemistry * 0.005;
    base += get("atomic_clock").level * 0.005;
    base *= (1 + get("kinetics").upgraded * 0.3 + get("gravity").upgraded * 0.2 + get("differential_equations").upgraded * 0.1 + get("E_and_P").upgraded * 0.2);
    return base;
}

let newton_2 = function() {
    if (!get("newton_2").upgraded)
        return 0;

    let base = maths;
    if (get("inspiration").upgraded)
        base += get("atomic_clock").level;
    base *= (1 + get("kinetics").upgraded * 0.3 + get("functions").upgraded * 0.2 + get("calculus").upgraded * 0.4 + get("E_and_P").upgraded * 0.2);
    return base * 0.005;
}

let element_buff = function() {
    let base = chemistry;
    if (get("inspiration").upgraded)
        base += get("atomic_clock").level;

    let eff = 0.005 * get("elements").upgraded + 0.001 * get("organic").upgraded;
    return base * eff;
}

let magic_buff = function() {
    if (!get("magic_theory").upgraded)
        return 0;
    let base = magics * 0.03;
    return base;
}

let science_buff = function() {
    let base = 0;
    base += newton_1() + newton_2() + element_buff() + botany() + magic_buff();
    base += get("AI").on * 0.1;

    if (get("collider").level)
        base += 0.015 * get("collider").on * (1 + get("heavy_element_collision").upgraded);

    let equations_buff = 0;
    if (get("equations").upgraded)
        equations_buff = Math.log(get("thought").storage + 1) / Math.log(2) / 100;
    base *= (1 + equations_buff);

    let fundamental_buff = 0;
    if (get("atomic_fusion").upgraded)
        fundamental_buff = Math.sqrt(get("university").level) / 10;
    base *= (1 + fundamental_buff);

    let pollution_buff = 0;
    if (get("pollution_reuse").upgraded)
        pollution_buff = Math.log(get("AsHg_collector").collected / 10 + 1) / Math.log(3) / 100;
    base *= (1 + pollution_buff);

    let photoelectric_buff = 0;
    if (get("photoelectric").upgraded)
        photoelectric_buff = Math.sqrt(get("professor").on) / 20;
    base *= (1 + photoelectric_buff);

    let diffraction_buff = 0;
    if (get("two_slit_diffraction").upgraded)
        diffraction_buff = Math.log(get("insight").storage + 1) / Math.log(2) / 60;
    base *= (1 + diffraction_buff);
    
    return base;
}

let pollution_debuff = function() {
    return Math.log(1 + pollution) / 100;
}

let stability = function() {
    let person = get("person").capacity - 10 - 2 * get("governed").upgraded - 3 * get("normalized").upgraded;
    let base = 0.01 - 0.001 * get("management").upgraded - 0.001 * get("government").upgraded
                    - 0.001 * get("laws").upgraded - 0.004 * get("surveillance").upgraded
                    - 0.0005 * get("governed").upgraded - 0.0005 * get("normalized").upgraded;
    if (person < 0)
        person = 0;
    let pollu = pollution_debuff();
    let alter = get("theater").level * 0.02;

    if (electricity >= 0) {
        alter += get("illumination").upgraded * Math.sqrt(electricity) / 100;
        alter += get("apartment").level * 0.01;
        alter += get("AI").on * 0.02;
    } else {
        alter -= get("apartment").level * 0.03;
    }
    if (get("carnival").active)
        alter += 0.2;
    if (get("sincerity").upgraded)
        alter += get("cathedral").level * 0.01;
    if (get("surveillance").upgraded)
        alter -= 0.07;
    if (get("magic_insight").upgraded)
        alter -= 0.03;
    if (get("kenka").on)
        alter -= [0, 0.1, 0.2][get("kenka").on - 1];
    return 1 - person * base - pollu + alter;
}

let fuel_text = function(wood) {
    wood *= fuel_ratio();

    let text = "";
    if (!get("carbon_usage").upgraded)
        text += sprintf("$木材", format(wood));
    else
        text += sprintf("$木材与$煤", format(wood * 0.5), format(wood * 0.05));
    return text;
}

let fuel_ratio = function() {
    let base = 1;
    base *= (1 - 0.1 * get("vehicle").upgraded);
    base *= (1 - 0.1 * get("mars_fuel").upgraded);
    base *= Math.pow(0.985, get("chemlab").level);
    base *= [1, 1.2, 1.75, 2.6][get("inefficiency").on];
    return base;
}

let fuel_consumption = function() {
    let base = get("fire").on * 2 * (1 + 0.5 * get("heat_concentration").upgraded);
    base += get("paper_factory").on * 5;
    base += get("smelter").on * 5;
    base += get("furnace").on * 15;
    base += get("blast_furnace").on * 40;
    base += get("power_station").on * 75;
    base += get("crossroad").on * 175;
    base += get("moon_base").on * 5000;
    return base * fuel_ratio();
}

let faith_buff = function() {
    let base = Math.log(1 + get("faith").storage * 2) / 45;
    base *= (1 + get("sincerity").upgraded * get("cathedral").level * 0.01);
    base *= (1 + get("priest").on * 0.025);
    base *= (1 + get("planetarium").level * 0.1);
    base *= (1 + get("ancient_resonance").upgraded * dim(get("ancient_bio").storage, 2500) * 0.0001);
    base *= (1 + get("mundus_tree").level * 0.48);
    return base;
}

let memory_buff = function() {
    let effective = get("memory").storage;
    let ratio = 1;
    if (get("catastrophe").on == 1)
        ratio = 0.25;
    if (get("catastrophe").on == 3)
        ratio = 0;
    ratio += 0.02 * get("memory_study").upgraded;
    ratio += 0.02 * get("restep").upgraded;
    ratio += 0.04 * get("anti_flow").upgraded;
    ratio += 0.06 * get("memory_retrace").upgraded;
    effective *= ratio;

    let buff = 1;
    buff += 0.02 * get("restep").upgraded;
    buff += 0.04 * get("anti_flow").upgraded;
    buff += 0.06 * get("memory_retrace").upgraded;
    buff *= (1 + science_buff());
    buff *= (1 + (challenge_level() >= 12) * 0.5 * get("contigential").upgraded);
    if (get("catastrophe").on >= 2)
        buff *= 0.25;
    if (get("anthropology").upgraded)
        buff *= 1 + Math.log(1 + get("thought").storage / 100) / 100;

    let max = 2;
    max *= 1 + Math.log(1 + get("history").storage) / Math.log(4) / 200;
    return dim(Math.sqrt(effective) / 30, max) * buff;
}

let potion_buff = function() {
    let base = 0.001 + 0.0001 * get("temple").level;
    base *= 1 + Math.log(1 + get("discovered_area").storage) / Math.log(1.125) / 1000;
    base *= get("cathedral").level;
    base *= get("potion_factory").on;
    return base;
}

let get_level = function() {
    let base = highest_lvl;
    base += get("urgent").upgraded * 1;
    base += get("frightened").upgraded * 2;
    base += get("contigential").upgraded * 3;
    return base;
}

let global_buffs = function() {
    return 1
        * (get("food").storage <= 1e-8 ? 0.25 : 1)
        * (stability() < 0.5 ? 0.25 : stability() < 1 ? stability() : 1 + (stability() - 1) * [1, 0.5, 0.25, 0.1][get("kenka").on])
        * (1 + memory_buff())
        * (1 + potion_buff())
        * (1 + faith_buff())
        * (1 + get("brewery").on * 0.02 * (1 + 1 * get("magic_alcohol").upgraded))
        * (1 + get_level() * 0.02 * (1 + 0.2 * get("urgent").upgraded + 0.35 * get("frightened").upgraded + 0.45 * get("contigential").upgraded))
        * (1 + get("HE_lab").on * get("collider").on * 0.001)
        * (1 + get("supercritical_phase_shifter").on * 0.14)
        * (1 + Math.log(1 + get("faith").storage / 1000) / 2000 * get("cathedral").level * get("worship").upgraded)
        * (debug ? 100000 : 1);
}

let food_eaten = function() {
    let person = get("person").capacity;
    let level = get("gluttony").on;
    let eaten = 0;

    if (level == 0)
        eaten = person * 3;
    if (level == 1)
        eaten = 0.5 * person * person + 2.75;
    if (level == 2)
        eaten = 0.01 * person * person * person + 13.75;
    if (level == 3)
        eaten *= 3;
    
    eaten *= (1 + 4 * get("carnival").active);
    eaten += 15 * get("brewery").on;
    eaten += 250 * get("potion_factory").on;
    return eaten;
}

let alchemy_tower_buff = function() {
    if (!get("nibelungenlied").upgraded)
        return 1;
    let base = 1 + Math.log(1 + get("discovered_area").storage) / Math.log(1.125) / 750;
    return base;
}

let elec_usage = function() {
    let base = 0;
    base += get("apartment").level * 2;
    base += get("factory").on * 2;
    base += get("AsHg_collector").on * 2;
    base += get("collider").on * 15;
    base += get("zlibrary").upgraded * get("library").level * 0.5;
    base += get("AI").on * 50;
    base += get("HE_lab").on * 15;
    base += get("moon_base").on * 18;
    base += get("moon_exotic_lab").on * 4;
    base += get("mars_site").on * 16;
    base += get("mercury_station").on * (7 + 1 * get("sun_launch").upgraded);
    base += get("asteroid_station").on * 17.5;
    if (get("resistance").on == 1)
        base *= 1.2;
    else if (get("resistance").on >= 2)
        base *= 1.5;
    return base;
}

let elec_produce = function() {
    let base = get("power_station").on * 5;
    base += get("wind_power_station").on * 3;
    base += get("fission_powerplant").on * 45;
    base += get("magic_powerplant").on * (20 + 2 * get("temple").level);
    base += get("fusion_powerplant").on * 60;
    base += get("dyson_sphere").level >= 100 ? time / 600 : 0;
    if (get("resistance").on == 3)
        base *= 0.5;
    return base;
}

let food_base = function() {
    result = get("collector").on * 5;
    result *= (1 + get("stone_ax").upgraded * 0.5 + get("slingshot").upgraded * 0.5 + get("copper_ax").upgraded * 0.5
                    + get("copper_sword").upgraded * 0.3 + get("iron_ax").upgraded * 0.3 + get("iron_sword").upgraded * 0.35
                    + get("metal_forge").upgraded * 0.15 + get("titanium_equip").upgraded * 0.5);
    result *= (1 + get("AI").on * 0.15);
    return result;
}

let production = function() {
    let prod = {};
    let global_buff = global_buffs();
    let crossroaded = 1 + get("crossroad").on * 0.015 * (1 + 1.5 * get("flight").upgraded);
    let fuel_total = fuel_consumption();
            
    prod.person = 0;

    prod.food = food_base();
    prod.food *= global_buff * crossroaded;
    prod.food *= Math.pow(get("magic_alcohol").upgraded ? 0.94 : 0.97, get("brewery").on);
    prod.food *= (get("food").storage <= 1e-8 ? 4 : 1);     // mitigates the debuff of hunger
    prod.food -= food_eaten();

    prod.wood = get("collector").on * 2;
    prod.wood *= (1 + get("stone_ax").upgraded * 0.5 + get("copper_ax").upgraded * 0.5 + get("iron_ax").upgraded * 0.3
                    + get("metal_forge").upgraded * 0.15 + get("titanium_equip").upgraded * 0.5);
    prod.wood *= (1 + get("AI").on * 0.15);
    prod.wood *= (1 + get("wood_factory").level * 0.2)
    prod.wood *= global_buff * crossroaded;
    prod.wood -= fuel_total * (1 - get("carbon_usage").upgraded * 0.5);

    prod.thought = (get("person").storage * 0.15 + (get("research_fund").upgraded ? get("university").level * 0.25 : 0));
    prod.thought *= (1 + (0.02 + 0.055 * get("heat_concentration").upgraded + 0.005 * get("heat").upgraded) * get("fire").on);
    prod.thought *= (1 + get("+-*/").upgraded * 0.3);
    prod.thought *= (1 + get("discussion").upgraded * (0.05 + 0.05 * get("record").upgraded) * (1 + 0.1 * get("research_lab").level) * get("person").storage);
    prod.thought *= (1 + get("observatory").level * 0.75 * (1 + 0.4 * get("kepler").upgraded + 0.2 * get("kinetics").upgraded + dim(0.001 * get("telescope").storage, 0.5) * (1 + get("inflection_law").upgraded * 0.2) * (1 + get("planetarium").level * 1.35)))
    prod.thought *= book_effect();
    prod.thought /= forgetting();
    prod.thought *= global_buff;
    if (!get("fire").on)
        prod.thought = 0;

    prod.stone =
            (get("copper_pickaxe").upgraded ? (get("miner").on * 5) : (get("quarry_worker").on * 3))
        * global_buff
        * crossroaded
        * (1 + get("titanium_equip").upgraded * 0.5 + get("iron_pickax").upgraded * 0.25)
        * (1 + get("mine").level * 0.2)
        - 2 * get("slingshot").upgraded * get("collector").on
        - 3 * get("furnace").on * get("basic_materials").upgraded;

    prod.fur = 0.005 * food_base();
    prod.fur *= global_buff * crossroaded;
    if (!get("stone_ax").upgraded)
        prod.fur = 0;

    prod.discovered_area = get("adventurer").on * 1;
    prod.discovered_area *= (1 + get("AI").on * 0.4);
    prod.discovered_area *= (1 + get("directions").upgraded * 0.5);
    prod.discovered_area *= (1 + get("iron_sword").upgraded * 0.45 + get("iron_shield").upgraded * 0.75
                               + get("metal_forge").upgraded * 0.15 + get("copper_sword").upgraded * 0.3
                               + get("titanium_equip").upgraded * 0.5);
    prod.discovered_area *= (1 + get("map").level * 0.08);
    prod.discovered_area *= global_buff;

    prod.paper = get("paper_factory").on * 1;
    prod.paper *= global_buff * crossroaded;

    prod.mineral = get("miner").on * 0.5;
    prod.mineral *= (1 + get("copper_pickaxe").upgraded * 1 + get("iron_pickax").upgraded * 0.25 + get("metal_forge").upgraded * 0.15 + get("titanium_equip").upgraded * 0.5);
    prod.mineral *= (1 + get("mine").level * 0.2);
    prod.mineral *= global_buff * crossroaded;
    prod.mineral -= get("smelter").on * 2;
    prod.mineral -= get("furnace").on * (5 * get("steel").unlocked);
    prod.mineral -= get("blast_furnace").on * 12.5;
    prod.mineral -= get("mercury_station").on * 250;
    prod.mineral -= get("supercritical_phase_shifter").on * 1000;

    prod.copper = get("smelter").on * 1;
    prod.copper *= (1 + get("carbon_usage").upgraded * 0.1) * (1 + get("heat").upgraded * 0.1);
    prod.copper *= (1 + get("AI").on * 0.1);
    prod.copper += get("alchemy_tower").on * 10 * alchemy_tower_buff();
    prod.copper *= global_buff * crossroaded;
    if (!get("copper").unlocked)
        prod.copper = 0;

    prod.carbon = (get("carbon_reveal").upgraded ? get("mine").level * 0.25 : 0);
    prod.carbon *= (1 + 0.6 * get("mine_upgrade").upgraded);
    prod.carbon += get("smelter").on * 0.75;
    prod.carbon += get("alchemy_tower").on * 8 * alchemy_tower_buff();;
    prod.carbon *= global_buff * crossroaded;
    prod.carbon -= fuel_total * (get("carbon_usage").upgraded * 0.05);
    if (!get("carbon").unlocked)
        prod.carbon = 0;

    prod.iron = get("smelter").on * 0.75;
    prod.iron *= (1 + get("carbon_usage").upgraded * 0.1) * (1 + get("heat").upgraded * 0.1);
    prod.iron *= (1 + get("AI").on * 0.1);
    prod.iron += get("alchemy_tower").on * 6 * alchemy_tower_buff();
    prod.iron *= global_buff * crossroaded;
    if (!get("iron").unlocked)
        prod["iron"] = 0;

    prod.glass = get("furnace").on * 0.5;
    prod.glass *= global_buff * crossroaded;

    prod.steel = get("furnace").on * 1 * (1 + get("carbon_usage").upgraded * 0.1) * (1 + get("heat").upgraded * 0.1);
    prod.steel *= (1 + get("AI").on * 0.1);
    prod.steel += get("alchemy_tower").on * 40 * alchemy_tower_buff();
    prod.steel *= global_buff * crossroaded;
    if (!get("steel").unlocked)
        prod.steel = 0;

    prod.gold = get("blast_furnace").on * 1 * (1 + get("carbon_usage").upgraded * 0.1) * (1 + get("heat").upgraded * 0.1);
    prod.gold *= (1 + get("AI").on * 0.1);
    prod.gold += get("alchemy_tower").on * 15 * alchemy_tower_buff();
    prod.gold *=  (1 - get("government").upgraded * 0.05);
    prod.gold *= global_buff * crossroaded;
    if (get("heavy_element_collision").upgraded)
        prod.gold -= 5 * get("collider").on;
        
    prod.titanium = get("factory").on * 0.035 * (1 + get("carbon_usage").upgraded * 0.1) * (1 + get("redox").upgraded);
    prod.titanium += get("moon_base").on * 0.2 * get("moon_titanium").upgraded;
    prod.titanium += get("alchemy_tower").on * 1 * alchemy_tower_buff();
    prod.titanium *= global_buff * crossroaded;
    if (!get("titanium").unlocked)
        prod.titanium = 0;

    prod.uranium = get("mine").level * 0.0007;
    prod.uranium *= (1 + 0.1 * get("mine_upgrade").upgraded);
    prod.uranium *= (1 + get("AI").on * 0.1);
    prod.uranium *= global_buff * crossroaded;
    prod.uranium -= 0.01 * get("fission_powerplant").on * fuel_ratio();
    prod.uranium -= get("mercury_station").on * 0.3;
    if (get("heavy_element_collision").upgraded)
        prod.uranium -= 0.015 * get("collider").on * fuel_ratio();
    if (!get("uranium_extraction").upgraded)
        prod.uranium = 0;
    
    prod.faith = get("cathedral").level * 1 * get("person").capacity;
    prod.faith *= 1 + 0.3 * get("myth").upgraded;
    prod.faith *= 1 + get("mundus_tree").level * 1;
    prod.faith *= global_buff;

    prod.magic = get("cathedral").level * 0.001 * get("arcane").upgraded;
    prod.magic += get("planetarium").level * 0.001;
    prod.magic += get("priest").on * 0.001;
    prod.magic *= 1 + get("mundus_tree").level * 1;
    prod.magic *= global_buff;
    prod.magic -= get("alchemy_tower").on * 0.003 * (1 - 0.5 * get("autoalchemy").upgraded);
    prod.magic -= get("magic_powerplant").on * 0.01;

    prod.insight = get("university").level * 0.001 + get("professor").on * 0.001;
    prod.insight *= 1 + get("relativity").upgraded;
    prod.insight *= 1 + get("atomic_clock").level * 0.2;
    prod.insight *= global_buff;
    prod.insight -= get("fusion_powerplant").level * 0.045;
    if (!get("techno_explosion").upgraded)
        prod.insight = 0;

    prod.book = 0.02 * get("library").level * (1 + 7.5 * get("zlibrary").upgraded) * get("education").upgraded;
    prod.book -= 80 * get("moon_exotic_lab").on;

    prod.structure = 0;
    prod.structure -= 40 * get("supercritical_phase_shifter").on;

    prod.REE = 0.2 * get("moon_base").on;
    prod.REE *= global_buff;

    prod.dark_matter = 0.1 * get("moon_exotic_lab").on;
    prod.dark_matter *= global_buff;

    prod.element_126 = 0.0035 * (get("LHC").level >= 25);
    prod.element_126 *= 1 + get("LHC_consumption").upgraded * Math.sqrt(electricity) / 32;
    prod.element_126 *= global_buff;
    prod.element_126 -= get("mercury_station").on * 0.03;

    prod.antimatter = 1e-6 * get("antimatter_research").upgraded * (1 + get("electromagnetic_capture").upgraded);
    prod.antimatter *= 1 + get("electromagnetic_capture").upgraded * Math.sqrt(electricity) / 10;
    prod.antimatter *= global_buff;
    prod.antimatter -= get("supercritical_phase_shifter").on * 12.5e-6;

    prod.energy_crystal = 1 * get("mercury_station").on;
    prod.energy_crystal *= global_buff;
    prod.energy_crystal -= 70 * get("asteroid_station").on;

    prod.unobtainium = 0.0008 * get("asteroid_station").on;
    prod.unobtainium *= global_buff;

    prod.ancient_bio = 0.001 * get("mars_site").on;
    prod.ancient_bio *= 1 + 0.225 * get("sequencing_center").level * (1 + 0.15 * get("dna_peculiarity").upgraded)
                          + 0.05 * get("relics_station").level + 0.01 * get("chemlab").level * get("dna_replica").upgraded
                          + 0.15 * get("temple").level;
    prod.ancient_bio *= 1 + faith_buff() * get("ancient_theology").upgraded;
    prod.ancient_bio *= 1 + memory_buff() * get("self_clone").upgraded;
    prod.ancient_bio *= debug ? 1000 : 1;

    prod.supply = 0;
    prod.supply -= 0.01 * get("astronaut").on;
    prod.supply *= 1 - 0.15 * get("colive").upgraded;
    prod.supply -= 0.01 * get("moon_living_quarter").on;
    prod.supply *= Math.pow(0.99, get("mars_cargo").level);

    // craftsman
    for (let i = 0; i < craftables.length; i++) {
        let res = craftables[i];
        let price = requirement(res);
        let tag = 1;
        prod[res] = prod[res] ?? 0;
        for (let j = 0; j < price.length; j++)
            if (prod[price[j][0]] < price[j][1] / 10 && get(price[j][0]).storage <= 1e-8) {
                tag = 0;
                break;
            }
        if (!tag) continue;
        let eff = 0.005 * (1 + get("workshop_2").level * 0.1) * (1 + get("magic_workshop").upgraded);
        let person = get("craftsman_" + res);
        if (res == "book" && get("education").upgraded) {
            eff = 0.05 * (1 + get("workshop_2").level * 0.1 + get("university").level * 0.1) * (1 + get("magic_workshop").upgraded);
            person = get("professor");
        }
        prod[res] += eff * person.on * craft_effect(res, false);
        for (let j = 0; j < price.length; j++) {
            prod[price[j][0]] -= person.on * price[j][1] * eff;
            show_crafts[price[j][0]] = -person.on * price[j][1] * eff;
        }
    }
    
    global_prod = prod;
    return prod;
}

let percentage = function(x, clr) {
    if (clr == true)
        return percentage(x, x == 0 ? "black" : x > 0 ? "green" : "red");
    else if (clr)
        return "<font color='" + clr + "'>" + format(x * 100) + "%</font>";
    return format(x * 100) + "%";
}

let entext = function(x, what, is_percent) {
    if (what == 0)
        return "";
    return sprintf("<tr class='entext'><td>$</td><td><font color='$'>$$</font></td></tr>", x, what < 0 ? "red" : is_percent ? "green" : "black", what > 0 ? "+" : "", is_percent ? percentage(what) : format(what));
}

let show_crafts = {};
let show_production = function(x, self) {
    let text = "<table id='show_prod'>";
    let prod = production();
    if (!prod[x] || prod[x] <= 1e-8 && prod[x] >= -1e-8)
        return;
    let fuel_total = fuel_consumption();
    let crossroaded = get("crossroad").on * 0.015 * (1 + 1.5 * get("flight").upgraded);
    let metal_buff = 1 + get("carbon_usage").upgraded * 0.1;
    if (x == "food") {
        text += entext(get("collector").name, get("collector").on * 5);
        text += entext("升级", get("stone_ax").upgraded * 0.5 + get("slingshot").upgraded * 0.5 + get("copper_ax").upgraded * 0.5
                    + get("copper_sword").upgraded * 0.3 + get("iron_ax").upgraded * 0.3 + get("iron_sword").upgraded * 0.35
                    + get("metal_forge").upgraded * 0.15 + get("titanium_equip").upgraded * 0.5, true);
   
        text += entext(get("crossroad").name, crossroaded, true);
        text += entext(get("AI").name, get("AI").on * 0.15, true);
    }
    if (x == "wood") {
        text += entext(get("collector").name, get("collector").on * 2);
        text += entext("升级", get("stone_ax").upgraded * 0.5 + get("copper_ax").upgraded * 0.5 + get("iron_ax").upgraded * 0.3 + get("metal_forge").upgraded * 0.15
                                + get("titanium_equip").upgraded * 0.5, true);
        text += entext("木材厂", get("wood_factory").level * 0.2, true);
        text += entext(get("crossroad").name, crossroaded, true);
        text += entext(get("AI").name, get("AI").on * 0.15, true);
    }
    if (x == "thought") {
        text += entext("空闲", get("person").storage * 0.15);
        if (get("research_fund").upgraded)
            text += entext(get("university").name, get("university").level * 0.25 * (1 + 0.15 * get("collider").on * (1 + get("heavy_element_collision").upgraded)));
        text += sprintf("<tr class='entext'><td>遗忘</td><td><font color='red'>/$</font></td></tr>", format(forgetting()));
        if (get("discussion").upgraded)
            text += entext("商讨", get("person").storage * (0.05 + 0.05 * get("record").upgraded) * (1 + 0.1 * get("research_lab").level), true);
        text += entext(get("observatory").name,  get("observatory").level * 0.75 * (1 + 0.4 * get("kepler").upgraded + 0.2 * get("kinetics").upgraded + dim(0.001 * get("telescope").storage, 0.5) * (1 + get("inflection_law").upgraded * 0.2)) * (1 + get("planetarium").level * 1.35), true);
        text += entext(get("book").name, book_effect() - 1, true);
        text += entext("升级", get("+-*/").upgraded * 0.3, true);
        if (get("fire").on)
            text += entext(get("fire").name, (0.02 + 0.055 * get("heat_concentration").upgraded + 0.005 * get("heat").upgraded) * get("fire").on, true);
    }
    if (x == "stone") {
        if (get("copper_pickaxe").upgraded)
            text += entext(get("miner").name, get("miner").on * 5);
        else
            text += entext(get("quarry_worker").name, get("quarry_worker").on * 3);
        text += entext("升级", get("titanium_equip").upgraded * 0.5 + get("iron_pickax").upgraded * 0.25, true);
        text += entext(get("mine").name, get("mine").level * 0.2, true);
        text += entext(get("crossroad").name, crossroaded, true);
        text += entext(get("AI").name, get("AI").on * 0.15, true);
    }
    if (x == "fur") {
        text += entext(get("collector").name, 0.005 * food_base());
        text += entext(get("crossroad").name, crossroaded, true);
    }
    if (x == "discovered_area") {
        text += entext(get("adventurer").name, get("adventurer").on * 1);
        text += entext(get("directions").name, get("directions").upgraded * 0.5, true);
        text += entext("升级", get("iron_sword").upgraded * 0.45 + get("iron_shield").upgraded * 0.75 + get("metal_forge").upgraded * 0.15 + get("copper_sword").upgraded * 0.3 + get("titanium_equip").upgraded * 0.5, true);
        text += entext(get("map").name, get("map").level * 0.08, true);
        text += entext(get("AI").name, get("AI").on * 0.4, true);
    }
    if (x == "paper") {
        text += entext(get("paper_factory").name, get("paper_factory").on * 1);
        text += entext(get("crossroad").name, crossroaded, true);
    }
    if (x == "mineral") {
        text += entext(get("miner").name, get("miner").on * 0.5);
        text += entext("升级", get("copper_pickaxe").upgraded * 1 + get("metal_forge").upgraded * 0.15 + get("titanium_equip").upgraded * 0.5, true);
        text += entext(get("mine").name, get("mine").level * 0.2, true);
        text += entext(get("crossroad").name, crossroaded, true);
    }
    if (x == "copper") {
        text += entext(get("smelter").name, get("smelter").on * 1 * metal_buff);
        text += entext("升级", get("heat").upgraded * 0.1, true);
        text += entext(get("alchemy_tower").name, get("alchemy_tower").on * 10 * alchemy_tower_buff());
        text += entext(get("crossroad").name, crossroaded, true);
        text += entext(get("AI").name, get("AI").on * 0.1, true);
    }
    if (x == "carbon") {
        text += entext(get("smelter").name, get("smelter").on * 0.75);
        if (get("carbon_reveal").upgraded) {
            text += entext(get("mine").name, get("mine").level * 0.25);
            text += entext("└升级", get("mine_upgrade").upgraded * 0.6, true);
        }
        text += entext(get("alchemy_tower").name, get("alchemy_tower").on * 8 * alchemy_tower_buff());
        text += entext(get("crossroad").name, crossroaded, true);
    }   
    if (x == "iron") {
        text += entext(get("smelter").name, get("smelter").on * 0.75 * metal_buff);
        text += entext("升级", get("heat").upgraded * 0.1, true);
        text += entext(get("alchemy_tower").name, get("alchemy_tower").on * 6 * alchemy_tower_buff());
        text += entext(get("crossroad").name, crossroaded, true);
        text += entext(get("AI").name, get("AI").on * 0.1, true);
    }   
    if (x == "glass") {
        text += entext(get("furnace").name, get("furnace").on * 0.5);
        text += entext(get("crossroad").name, crossroaded, true);
    }
    if (x == "steel") {
        text += entext(get("furnace").name, get("furnace").on * 1 * metal_buff);
        text += entext("升级", get("heat").upgraded * 0.1, true);
        text += entext(get("alchemy_tower").name, get("alchemy_tower").on * 40 * alchemy_tower_buff());
        text += entext(get("crossroad").name, crossroaded, true);
        text += entext(get("AI").name, get("AI").on * 0.1, true);
    }
    if (x == "gold") {
        text += entext(get("blast_furnace").name, get("blast_furnace").on * 1 * metal_buff);
        text += entext("升级", get("heat").upgraded * 0.1, true);
        text += entext(get("alchemy_tower").name, get("alchemy_tower").on * 15 * alchemy_tower_buff());
        text += entext(get("government").name, -get("government").upgraded * 0.05, true);
        text += entext(get("crossroad").name, crossroaded, true);
        text += entext(get("AI").name, get("AI").on * 0.1, true);
    }
    if (x == "faith") {
        text += entext(get("cathedral").name, get("cathedral").level * get("person").capacity * 1);
        text += entext(get("priest").name, get("priest").on * 0.01, true);
        text += entext(get("mundus_tree").name, get("mundus_tree").on * 1, true);
    }
    if (x == "titanium") {
        text += entext(get("factory").name, get("factory").on * 0.035 * metal_buff);
        text += entext("升级", get("redox").upgraded * 1, true);
        text += entext(get("alchemy_tower").name, get("alchemy_tower").on * 1 * alchemy_tower_buff());
        text += entext(get("moon_base").name, get("moon_base").on * 0.2 * get("moon_titanium").upgraded * metal_buff);
        text += entext(get("crossroad").name, crossroaded, true);
    }
    if (x == "magic") {
        text += entext(get("cathedral").name, get("cathedral").level * 0.001);
        text += entext(get("priest").name, get("priest").on * 0.001);
        text += entext(get("planetarium").name, get("planetarium").level * 0.001);
        text += entext(get("mundus_tree").name, get("mundus_tree").on * 1, true);
    }
    if (x == "insight") {
        text += entext(get("university").name, get("university").level * 0.001);
        text += entext(get("professor").name, get("professor").on * 0.001);
        text += entext(get("atomic_clock").name, get("atomic_clock").level * 0.2, true);
    }
    if (x == "uranium") {
        text += entext(get("mine").name, get("mine").level * 0.0007);
        text += entext("升级", get("mine_upgrade").upgraded * 0.1, true);
        text += entext(get("crossroad").name, crossroaded, true);
        text += entext(get("AI").name, get("AI").on * 0.1, true);
    }
    if (x == "REE") {
        text += entext(get("moon_base").name, get("moon_base").level * 0.2);
    }
    if (x == "dark_matter") {
        text += entext("外星实验室", get("moon_exotic_lab").on * 0.1);
    }
    if (x == "element_126") {
        text += entext("大型对撞机", (get("LHC").level >= 25) * 0.0035);
        text += entext("电力", Math.sqrt(electricity) / 32, true);
    }
    if (x == "antimatter") {
        text += entext("大型对撞机", (get("LHC").level >= 25) * 1e-6 * (1 + get("electromagnetic_capture").upgraded));
        text += entext("电力", Math.sqrt(electricity) / 10, true);
    }
    if (x == "ancient_bio") {
        text += entext(get("mars_site").name, 0.001 * get("mars_site").on);
        text += entext("升级", 0.225 * get("sequencing_center").level * (1 + 0.15 * get("dna_peculiarity").upgraded) + 0.05 * get("relics_station").level
             + 0.01 * get("chemlab").level * get("dna_replica").upgraded + 0.15 * get("temple").level, true);
        if (get("faith").unlocked && get("ancient_theology").upgraded)
            text += entext(get("faith").name, faith_buff(), true);
        if (get("self_clone").upgraded)
            text += entext(get("memory").name, memory_buff(), true);
    }
    if (x == "energy_crystal") {
        text += entext(get("mercury_station").name, 1 * get("mercury_station").on);
    }
    if (x == "unobtainium") {
        text += entext("小行星采矿", 0.0008 * get("asteroid_station").on);
    }
    if (is_craftable(x)) {
        text += entext("工匠", get("craftsman_" + x).on * 0.0025);
        text += entext("效率", craft_effect(x, true) - 1, true);
        text += entext("加成", (global_buffs() - 1) * 0.1, true);
    } else if (x != "ancient_bio") {
        if (get("faith").unlocked)
            text += entext(get("faith").name, faith_buff(), true);
        if (get("worship").upgraded)
            text += entext(get("cathedral").name, Math.log(1 + get("faith").storage / 1000) / 2000 * get("cathedral").level, true);
        if (get("brewery").on)
            text += entext(get("brewery").name, 0.02 * get("brewery").on * (1 + 1 * get("magic_alcohol").upgraded), true);
        if (get("potion_factory").on >= 1)
            text += entext(get("potion_factory").name, get("potion_factory").on * get("cathedral").level * 0.002, true);
        if (get("HE_lab").on >= 1)
            text += entext("物理实验室", get("HE_lab").on * get("collider").on * 0.001, true);
        if (get("memory").unlocked)
            text += entext(get("memory").name, memory_buff(), true);
        if (get("supercritical_phase_shifter").on)
            text += entext("移相", 0.14 * get("supercritical_phase_shifter").on, true);
        if (get_level())
            text += entext("危机", get_level() * 0.02 * (1 + 0.2 * get("urgent").upgraded + 0.35 * get("frightened").upgraded + 0.45 * get("contigential").upgraded), true);
        if (get("person").capacity > 10)
            text += entext("稳定", stability() < 0.5 ? -0.75 : (stability() - 1), true);
        if (get("food").storage <= 1e-8 && x != "food")
            text += entext("饥饿", -0.75, true);
        if (debug)
            text += entext("调试", 100000, true);
    }

    
    // consumption
    // cannot be migrated with previous ones, because these are calculated after global_buff is applied
    if (x == "food") {
        text += entext(get("brewery").name, Math.pow(get("magic_alcohol").upgraded ? 0.94 : 0.97, get("brewery").on) - 1, true);
        text += entext("消耗", -food_eaten());
    }
    if (x == "wood") {
        text += entext("燃料", -fuel_total * (1 - 0.5 * get("carbon_usage").upgraded));
    }
    if (x == "carbon") {
        text += entext("燃料", -fuel_total * 0.1 * get("carbon_usage").upgraded);
    }
    if (x == "stone") {
        text += entext(get("slingshot").name, -2 * get("collector").on * get("slingshot").upgraded);
        text += entext(get("furnace").name, -3 * get("furnace").on * get("basic_materials").upgraded);
    }
    if (x == "mineral") {
        text += entext(get("smelter").name, -2 * get("smelter").on);
        text += entext(get("furnace").name, -5 * get("furnace").on * get("iron_enhancement").upgraded);
        text += entext(get("blast_furnace").name, -12.5 * get("blast_furnace").on);
        text += entext(get("mercury_station").name, -250 * get("mercury_station").on);
        text += entext("移相", -1000 * get("supercritical_phase_shifter").on);
    }
    if (x == "gold") {
        text += entext(get("collider").name, -get("heavy_element_collision").upgraded * 5 * get("collider").on);
    }
    if (x == "magic") {
        text += entext(get("alchemy_tower").name, -get("alchemy_tower").on * 3 * (1 - 0.5 * get("autoalchemy").upgraded));
        text += entext(get("magic_powerplant").name, -get("magic_powerplant").on * 0.01);
    }
    if (x == "insight") {
        text += entext(get("fusion_powerplant").name, -get("fusion_powerplant").on * 0.045);
    }
    if (x == "book") {
        text += entext(get("moon_exotic_lab").name, -get("moon_exotic_lab").on * 80);
    }
    if (show_crafts[x]) {
        text += entext("工匠", show_crafts[x]);
    }
    if (x == "uranium") {
        text += entext(get("collider").name, -get("heavy_element_collision").upgraded * 0.015 * get("collider").on * fuel_ratio());
        text += entext(get("fission_powerplant").name, -get("fission_powerplant").on * 0.1 * fuel_ratio());
        text += entext(get("mercury_station").name, -get("mercury_station").on * 0.3);
    }
    if (x == "element_126") {
        text += entext(get("mercury_station").name, -get("mercury_station").on * 0.03);
    }
    if (x == "antimatter") {
        text += entext("移相", -12.5e-6 * get("supercritical_phase_shifter").on);
    }
    if (x == "energy_crystal") {
        text += entext(get("mercury_station").name, -70 * get("asteroid_station").on);
    }
    text += "</table>";

    /* show */
    let float = $("float");
    float.innerHTML = text;
    float.style.display = "block";
    let estimated_h = float.offsetHeight;

    let place = self.getBoundingClientRect();
    let height = window.innerHeight;
    let x0 = place.left + place.width;
    let y0 = Math.min(height - estimated_h - 15, place.top) + window.scrollY;
    float.style.left = x0 + "px";
    float.style.top = y0 + "px";
}

let running_out = function(x) {
    return get(x).storage <= 1e-8 && production()[x] < 0
}

let turn_off = function(x) {
    get(x).on = 0;
    if ($(x) && get(x).level)
        $(x).innerHTML = get(x).name + " (" + 0 + "/" + get(x).level + ")";
}

let capacity_calc = function(x) {
    let cap_increase = {
        "food": 5000,
        "wood": 2000,
        "fur": 100,
        "paper": 2000,
        "stone": 2000,
        "mineral": 1500,
        "copper": 500,
        "carbon": 300,
        "iron": 750,
        "glass": 250,
        "steel": 150,
        "titanium": 1000,
    };

    let storages = get("harbor").level * 3 + get("warehouse").level + get("warehouse_2").level * 0.5 + get("mars_cargo").level * 7.5;
    let normal_buff = 1 + get("crossroad").level * 0.03 * (1 + 1.5 * get("flight").upgraded) + get("mercury_storage").level * 0.08;
    let common_buff = 1 + get("memory").storage * (get("closed_packing").upgraded ? 0.0003 : get("hoarding").upgraded * 0.00015);
    if (debug)
        common_buff *= 1000;
    common_buff *= [1, 0.9, 0.65, 0.4][get("unordered").on];

    let res = get(x);
    if (res.capacity == -1)
        return -1;
    if (x == "person")
        return get("person").capacity;
    let base = 0;
    if (["food", "wood", "fur", "stone", "paper", "mineral", "copper", "carbon", "iron", "glass", "steel", "titanium"].find(function(elem) { return elem == x; }) !== undefined) {
        base = (storages + 1) * cap_increase[x];
        base *= normal_buff;
    }
    if (x == "gold") {
        base = 100 + 400 * get("bank").level;
        base *= normal_buff;
    }
    if (x == "uranium") {
        base = 25 + 25 * get("fission_powerplant").on;
        base *= normal_buff;
    }
    if (x == "magic") {
        base = 60 + 60 * get("cathedral").level;
    }
    if (x == "insight") {
        base = 60 + 60 * get("university").level;
    }
    if (x == "REE") {
        base = 35000 + 35000 * get("moon_base").on;
        base *= normal_buff;
    }
    if (x == "dark_matter") {
        base = 20000 + 20000 * get("moon_exotic_lab").on;
    }
    if (x == "element_126") {
        base = 17500;
    }
    if (x == "energy_crystal") {
        base = 100000 + 100000 * get("mercury_storage").level;
    }
    if (x == "unobtainium") {
        base = 350 + 100 * get("asteroid_station").on;
        base *= normal_buff;
    }
    if (x == "antimatter") {
        base = 1;
    }
    return base * common_buff;
}

let pollute = function() {
    let base = 0;
    base += get("factory").on * 1;
    base += get("crossroad").on * 1.5;
    base += get("power_station").on * 0.7;
    base += get("fission_powerplant").on * 30;
    base += get("HE_lab").on * 2;
    
    let ashg = get("AsHg_collector").on * 12;
    ashg *= (1 + get("pollution_reuse").upgraded);

    let absorption = 0;
    absorption += ashg;
    absorption += get("fusion_energizer").upgraded * 48;
    absorption += get("moon_pollution_tube").level * 60;

    get("AsHg_collector").collected += Math.min(base, ashg) / tick_persec;
    pollution += (base - absorption) / tick_persec;
    if (pollution < 0)
        pollution = 0;
}

let autocraft = function() {
    if (time <= 5 || autoc_storage >= 1 || !get("autocraft").upgraded || get("professional").on)
        return;
    
    let able = function(id) {
        return get(id).storage > autoc_ratio * get(id).capacity;
    };
    let craft_all = function(id) {
        let price = requirement(id);
        let max = price.reduce(function(minimum, elem) { return Math.min(minimum, get(elem[0]).storage * (1 - autoc_storage) / elem[1]); }, 1e300);
        price.forEach(function(elem) { get(elem[0]).storage -= max * elem[1]; })
        get(id).storage += max * craft_effect(id, true);
    }
    craftables.forEach(function(id) {
        if (get(id).unlocked && requirement(id).reduce((flag, elem) => flag && able(elem[0]), true))
            craft_all(id);
    });
}

let autoupgrade = function() {
    if (time <= 5 || !get("autoupgrade").upgraded)
        return;

    let non_consume = ["thought", "discovered_area"];
    let excluded = [
        ["GM", () => stability() < 1.2],
        ["magic_insight", () => stability() < 1.3],
        ["AsHg_experiment", () => true],
        ["dyson_experiment", () => true],
        ["education", () => !get("perfect_insight").upgraded],
        ["faithful", () => !get("perfect_insight").upgraded],
        ["dna_peculiarity", () => get("sequencing_center").level < 10],
        ["self_clone", () => get("sequencing_center").level < 15],
        ["colive", () => stability() < 1.5],
    ];
    let able = (id) => (get(id).storage > autou_ratio * (get(id).capacity ?? 0)) || non_consume.includes(id);
    let leftover = (id) => get(id).storage - autou_storage * (get(id).capacity ?? 0) * !non_consume.includes(id);
    let needed = Object.keys(dictionary).filter((id) =>
        get(id).thought && get(id).unlocked && !get(id).upgraded &&
        requirement(id).every((elem) => able(elem[0]) && leftover(elem[0]) >= elem[1]) &&
        !excluded.some((elem) => id == elem[0] && elem[1]())
    );
    if (needed.length == 0)
        return;

    let evaluate = (id) =>
        requirement(id).reduce((result, elem) => 
            Math.min(result, leftover(elem[0]) / elem[1])
        ) * (priorities[id] ?? 100);
    let wanted = needed.reduce((id, elem) => evaluate(elem) > evaluate(id) ? elem : id);
    
    $("autoshow").innerHTML = sprintf("<b>自动升级</b>：$", get(wanted).name);
    get(wanted).clicked();
}

let get_resource_color = function(id) {
    if (get(id).special)
        return "#9400D3";
    if (get(id).spatial)
        return "#43CD80";
    if (is_craftable(id))
        return "#FF6347";
    return "#3A5FCD";
}

let render_craft = function() {
    $("crafting").innerHTML = "";
    for (let i = 0; i < resources.length; i++) {
        let id = resources[i];
        let res = get(id);
        if (!res.craftable || !res.unlocked)
            continue;
        let tr = document.createElement("tr");
        $("crafting").appendChild(tr);

        let name = document.createElement("td");
        name.innerHTML = res.name;
        name.style.color = get_resource_color(id);
        tr.appendChild(name);

        let storage = document.createElement("td");
        storage.innerHTML = format(res.storage);
        storage.id = id + "_storage";
        tr.appendChild(storage);

        if (get("professional").on)
            continue;
        let setcraft = (n) => {
            let td = document.createElement("td");
            let but = document.createElement("button");
            but.id = id + "_craft" + n;
            but.innerHTML = sprintf("+$%", n);
            td.appendChild(but);
            tr.appendChild(td);
            $(but.id).onclick = craft.bind(null, id, n, true);
            $(but.id).onmouseenter = () => { $(but.id).style.textDecoration = "underline"; };
            $(but.id).onmouseleave = () => { $(but.id).style.textDecoration = ""; };
        };

        setcraft(1);
        setcraft(10);
        setcraft(100);
    }
}

let refresh_resource = function() {
    if (!get("bonfire").unlocked)
        return;
    let productions = production();
    let is_active = get("carnival").active;
    get("carnival").active = true;      // let food_eaten() return the correct result
    get("carnival").active = is_active ? !running_out("food") : (get("food").storage > 0.5 * get("food").capacity || productions.food > 0);
    if (!get("carnival").upgraded)
        get("carnival").active = false;

    electricity = elec_produce() - elec_usage();
    pollute();

    if (electricity < 0) {
        turn_off("AI");
        turn_off("HE_lab");
        turn_off("factory");
        turn_off("collider");
        turn_off("AsHg_collector");
        turn_off("mars_site");
        turn_off("moon_base");
        turn_off("moon_exotic_lab");
        turn_off("mercury_station");
    }

    if (running_out("food")) {
        turn_off("potion_factory");
    }
    if (running_out("supply")) {
        get("person").storage += get("astronaut").on;
        get("astronaut").on = 0;
    }
    if (running_out("wood") || running_out("carbon")) {
        turn_off("fire");
        turn_off("furnace");
        turn_off("paper_factory");
        turn_off("smelter");
        turn_off("blast_furnace");
        turn_off("power_station");
    }
    if (running_out("mineral")) {
        turn_off("smelter");
        if (get("iron_enhancement").upgraded)
            turn_off("furnace");
    }
    if (running_out("stone")) {
        turn_off("furnace");
    }
    if (running_out("magic")) {
        turn_off("alchemy_tower");
    }
    if (running_out("insight")) {
        turn_off("fusion_powerplant");
    }
    if (running_out("gold") || running_out("uranium")) {
        turn_off("collider");
    }
    if (running_out("mineral") || running_out("uranium") || running_out("element_126")) {
        turn_off("mercury_station");
    }
    if (running_out("antimatter") || running_out("mineral")) {
        turn_off("supercritical_phase_shifter");
    }
    let spatial = Object.keys(dictionary).filter((id) => get(id).spatial);
    let astro = get("astronaut").on + 2 * get("mars_unmanned_factory").level;
    astro *= 1 + 0.2 * get("colive").upgraded;
    for (let i = 0; i < spatial.length; i++) {
        let id = spatial[i];
        let res = get(id);
        if (res.require && (astro -= (res.require ?? 0) * (res.on ?? 0)) < 0)
            turn_off(id);
    }
    $("spacemen_show").innerHTML = sprintf("宇航员冗余量: <font color='green'>$</font>", astro);

    // refresh productions, since buildings may have been turned off
    productions = production();
    for (let i = 0; i < resources.length; i++) {
        let id = resources[i];
        let res = get(id);
        let produce = productions[id];
        if (produce)
            res.storage += produce / tick_persec;
    }

    // render resources
    $("resources").innerHTML = "";
    for (let i = 0; i < resources.length; i++) {
        let id = resources[i];
        let res = get(id);
        let produce = productions[id];
        if (!res.unlocked || res.craftable)
            continue;
        res.capacity = capacity_calc(id);
        if (res.capacity >= 0)
            res.storage = Math.min(res.storage, res.capacity);
        if (res.storage < 0)
            res.storage = 0;
        let tr = document.createElement("tr");
        $("resources").appendChild(tr);

        let name = document.createElement("td");
        name.innerHTML = res.name;
        name.style.color = get_resource_color(id);
        tr.appendChild(name);

        let storage = document.createElement("td");
        storage.innerHTML = format(res.storage);
        if (res.capacity > 0 && res.storage > res.capacity * 0.85)
            storage.style.color = "#D2691E";
        if (res.capacity > 0 && res.storage > res.capacity * 0.95)
            storage.style.color = "#EE9A00";
        tr.appendChild(storage);

        let capacity = document.createElement("td");
        capacity.innerHTML = res.capacity > 0 ? "/" + format(res.capacity) : "";
        capacity.style.color = "gray";
        tr.appendChild(capacity);

        let prod = document.createElement("td");
        prod.id = id + "_prod";
        prod.innerHTML = produce ? ((produce > 0 ? " (+" : "(") + format(produce) + "/s)") : " ";
        if (produce < 0)
            prod.style.color = "red";
        tr.appendChild(prod);
        $(prod.id).onmouseenter = show_production.bind(null, id, $(prod.id));
        $(prod.id).onmouseleave = hide;
    }
    autocraft();
    autoupgrade();

    // render craft materials
    for (let i = 0; i < craftables.length; i++) {
        let id = craftables[i];
        if (!get(id).unlocked)
            continue;
        $(id + "_storage").innerHTML = format(get(id).storage);
    }
}

let statistics_refresh = function() {
    if (current_nav != "statistics")
        return;
    let text = "<h3>记忆加成</h3>";
    text += sprintf("总效果：+$<br>", percentage(memory_buff(), true));
    text += sprintf("└科学加成：+$<br>", percentage(science_buff(), true));
    if (challenge_level() >= 12 && get("contigential").upgraded)
        text += sprintf("└危机加成：+$<br>", percentage(0.5, true));

    text += "<h4>科学加成明细</h4>";
    text += sprintf("生物学：+$（来源于植物研究）<br>", percentage(botany(), true));
    text += sprintf("物理学：+$（研究了$个科技）<br>", percentage(newton_1(), true), (get("pv_nrt").upgraded ? physics + chemistry : physics) + get("atomic_clock").level);
    text += sprintf("对撞机：+$<br>", percentage(get("collider").on * 0.015 * (1 + get("heavy_element_collision").upgraded), true));
    text += sprintf("人工智能：+$<br>", percentage(get("AI").on * 0.1, true));
    text += sprintf("数学：+$（研究了$个科技）<br>", percentage(newton_2(), true), maths + get("atomic_clock").level * get("inspiration").upgraded);
    text += sprintf("化学：+$（研究了$个科技）<br>", percentage(element_buff(), true), chemistry + get("atomic_clock").level * get("inspiration").upgraded);
    if (get("arcane").upgraded)
        text += sprintf("魔法学：+$（研究了$个科技）<br>", percentage(magic_buff(), true), magics);
    text += "<br>";
    if (get("equations").upgraded)
        text += sprintf("当前思考总量使科学加成提升了$<br>", percentage(Math.log(get("thought").storage + 1) / Math.log(2) / 100, true));
    if (get("fundamental").upgraded)
        text += sprintf("大学使科学加成提升了$<br>", percentage(Math.sqrt(get("university").level) / 10, true));
    if (get("pollution_reuse").upgraded)
        text += sprintf("砷汞富集器使科学加成提升了$<br>", percentage(Math.log(get("AsHg_collector").collected / 10 + 1) / Math.log(3) / 100, true));
    if (get("photoelectric").upgraded)
        text += sprintf("教授使科学加成提升了$<br>", percentage(Math.sqrt(get("professor").on) / 20, true));
    if (get("two_slit_diffraction").upgraded)
        text += sprintf("洞察使科学加成提升了$<br>", percentage(Math.log(get("insight").storage + 1) / Math.log(2) / 60, true));
        
    text += "<br><br><h3>遗忘</h3>";
    text += sprintf("若思考总量为x，则其产量将除以1 + (x - $) ^ $ / $<br>", format(forgetting_ignored()), format(forgetting_ratio()), format(forgetting_denominator()));
    if (pollution != 0) {
        text += "<br><br><h3>污染</h3>";
        text += sprintf("当前污染为<font color='red'>$</font><br>", format(pollution));
        text += sprintf("污染使得稳定度$<br>", percentage(-pollution_debuff(), true));
    }
    if (get_level()) {
        text += "<br><br><h3>危机等级</h3>";
        text += sprintf("最高达到危机等级<font color='red'>$</font><br>", get_level());
        text += sprintf("全体建筑的价格底数减少<font color='green'>$</font><br>", (get_level() * 0.0005).toFixed(4));
        text += sprintf("全局产量提高$<br>", percentage(get_level() * 0.02 * (1 + 0.2 * get("urgent").upgraded + 0.35 * get("frightened").upgraded + 0.45 * get("contigential").upgraded), true));
    }
    $("statistics").innerHTML = text;
}

let clamp = function(x, min, max) {
    if (isNaN(x))
        x = min;
    return Math.min(max, Math.max(x, min));
}

let autocraft_confirm = function() {
    if ($('autocraft_ratio').value)
        autoc_ratio = clamp(parseFloat($('autocraft_ratio').value) / 100, 0, 1);
    if ($('autocraft_storage').value)
        autoc_storage = clamp(parseFloat($('autocraft_storage').value) / 100, 0, 1);
    render_auto();
}

let autoupgrade_confirm = function() {
    if ($('autoupgrade_ratio').value)
        autou_ratio = clamp(parseFloat($('autoupgrade_ratio').value) / 100, 0, 1);
    if ($('autoupgrade_storage').value)
        autou_storage = clamp(parseFloat($('autoupgrade_storage').value) / 100, 0, 1);
    if (!$("show_thoughts_list").checked) {
        render_auto();
        return;
    }

    for (id in dictionary) {
        let item = get(id);
        if (!item.thought)
            continue;

        if (!$(sprintf("thought_list_$", id))) {
            console.log("Non existent:", id);
            continue;
        }
        priorities[id] = clamp(parseFloat($(sprintf("thought_list_$", id)).value), 0, 1e30);
    }
    render_auto();
}

let render_auto = function() {
    if (get("autocraft").upgraded) {
        let autobar = $("settings_autocraft");
        let text = "";
        text += "<h3>自动工匠</h3>";
        text += "达到上限<input type='text' id='autocraft_ratio' size=10 />%之后才自动合成，";
        text += "但留存<input type='text' id='autocraft_storage' size=10 />%不合成";
        text += sprintf("<br> 目前达到$开始合成，留存$资源", percentage(autoc_ratio), percentage(autoc_storage));
        text +=  "<br> <button id='craft_confirm' onclick=autocraft_confirm()>设置</button>";
        autobar.innerHTML = text;
    }
    if (get("autoupgrade").upgraded) {
        let autobar = $("settings_autoupgrade_content");
        let text = "";
        text += "<h3>自动研究</h3>";
        text += "达到上限<input type='text' id='autoupgrade_ratio' size=10 />%之后才自动研究，";
        text += "但留存<input type='text' id='autoupgrade_storage' size=10 />%不研究";
        text += sprintf("<br> 目前达到$开始研究，留存$资源", percentage(autou_ratio), percentage(autou_storage));
        text +=  "<br> <button id='upgrade_confirm' onclick=autoupgrade_confirm()>设置</button>";
        autobar.innerHTML = text;

        $("thoughts_list").innerHTML = "";
        if (!$("show_thoughts_list").checked)
            return;

        for (id in dictionary) {
            let item = get(id);
            if (!item.thought)
                continue;

            let tr = document.createElement("tr");
            $("thoughts_list").appendChild(tr);

            let name = document.createElement("td");
            name.innerHTML = item.name;
            name.style.color = "#3A5FCD";
            tr.appendChild(name);

            let storage = document.createElement("td");
            // Deliberate || rather than ??, since 0 is not permitted
            storage.innerHTML = sprintf("<input type='text' id='thought_list_$' value='$' />", id, priorities[id] || 100);
            tr.appendChild(storage);
        }
    }
}

let refresh_button = function() {
    for (id in dictionary) {
        if (get(id).price === undefined || !$(id))
            continue;
        let color = requirement(id).reduce((total, elem) => 
            Math.max(3 * (elem[1] > get(elem[0]).capacity && get(elem[0]).capacity != -1),
                     2 * (elem[1] > get(elem[0]).storage), total)
        , 1);
        $(id).style.color = (color == 1 ? "black" : color == 2 ? "gray" : "red");
    }
}

let first_locked = 0;
let unlocks = function() {
    if (get("mineral_research").upgraded) {
        let x = get("discovered_area").storage;
        for (let i = first_locked; i < elements.length; i++)
            if (elements[i][1] < x && !get(elements[i][0]).unlocked) {
                unlock(elements[i][0]);
                first_locked = i;
            };
    }
    if (get("carbon").unlocked && !get("carbon_usage").unlocked) {
        push_button("carbon_usage", "thoughts");
    }
    if (get("iron").unlocked && !get("iron_ax").unlocked) {
        push_button("wood_process", "thoughts");
        push_button("iron_ax", "thoughts");
        push_button("iron_pickax", "thoughts");
        push_button("iron_sword", "thoughts");
        push_button("iron_shield", "thoughts");
        push_button("iron_enhancement", "thoughts");
        setguide("发现铁的存在，这将推动各种工具的发展。");
    }
    if (get("gold").unlocked && !get("blast_furnace").unlocked) {
        push_button("blast_furnace", "bonfire");
        push_button("bank", "bonfire");
        setguide("发现贵金属，可以作为货币使用。这将促进大学或是教堂的兴建。");
    }
    if (get("uranium").unlocked && !get("uranium_extraction").unlocked) {
        push_button("uranium_extraction", "thoughts");
        setguide("发现铀，一种极具潜力的能源。虽然危害性很大，但是没人在意。");
    }
    if (get("person").capacity >= 10 && !get("management").unlocked) {
        push_button("management", "thoughts");
        setguide("随着聚落的人越来越多，不稳定的思绪也悄然出现。聚落的人数每比10多1，就减少1%稳定度。较低的稳定度会降低全局产量，而较高的稳定度会增加产量。同时，<b>思考</b>面板下也解锁了与稳定度有关的升级。");
    }
    if (pollution != 0 && !pollution_guided) {
        pollution_guided = 1;
        setguide("工厂以及一些其它的工业设施将会产出污染，降低稳定度。研究砷汞富集器可以吸收污染。");
    }
    if (time == memory_elapsed) {
        setguide("随着文明的发展，大量的记忆在代际间传承。记忆能够加成全局产量；每隔100年，你将获得1记忆。部分升级可以缩短记忆获取的时间。");
    }
    if (get("AsHg_collector").collected >= 3000 / (1 + debug * 999) && !get("AsHg_experiment").unlocked) {
        push_button("AsHg_experiment", "thoughts");
        setguide("砷汞富集器里已经有了大量的毒性物质。有人对此提出了一种处理方法。");
    }
}

let time_update = function() {
    if (!get("bonfire").unlocked)
        return;
    time += 1;
    let text = sprintf("第$年 ", parseInt(time / 50));
    if (get("person").capacity >= 10) {
        let stab = stability();
        text += "<br>稳定度：" + percentage(stab, stab < 1 ? "red" : "green");
    }
    if (get("electricity").upgraded)
        text += sprintf("<br>电力：<font color='$'>$</font>", electricity > 0 ? "green" : "red", format(electricity));
    if (time - last_memory >= memory_elapsed) {
        get("memory").storage += 1 + get("restep").upgraded + 3 * get("anti_flow").upgraded + 5 * get("memory_retrace").upgraded;
        unlock("memory");
        last_memory = time;
        save_item("memory", get("memory").storage);
    }
    $("time").innerHTML = text;
}

let refresh = function() {
    refresh_resource();
    refresh_button();
    unlocks();
    statistics_refresh();
    time_update();

    if (show_type)
        $("float").innerHTML = show_string(show_type);
    
    if (time && time % 10 == 0)
        save();
}

let prestige_gain = function(type) {
    let gain = {
        memory: 0,
        history: 0,
        relic: 0,
    };
    if (type == 1) {
        let base = get("person").capacity * 2 + Math.log(1 + get("thought").storage) / Math.log(1.05);
        base *= (1 + challenge_level() * 0.1);
        gain.memory = parseInt(base);
    }
    if (type == 2) {
        let base = get("person").capacity * 3 + Math.log(1 + get("thought").storage) / Math.log(1.04);
        base *= (1 + challenge_level() * 0.1);
        gain.memory = parseInt(base);

        base = Math.log(1 + base) * 3;
        gain.history = parseInt(base);

        gain.relic = parseInt(dim(get("relics_station").level, 25));
    }
    return gain;
}

let prestige = function(x) {
    save_disabled = true;
    let gain = prestige_gain(x);
    get("memory").storage += gain.memory;
    get("history").storage += gain.history;
    get("relic").storage += gain.relic;
    save_item("memory", get("memory").storage);
    save_item("history", get("history").storage);
    save_item("relic", get("relic").storage);

    let lvl = challenge_level();
    highest_lvl = Math.max(lvl, load_item("highest_lvl") ?? 0);
    console.log(highest_lvl);
    save_item("highest_lvl", highest_lvl);

    save_item("genetics_upgrades", genetics_upgrades);
    delete_save(true);
    save_item("to_prestige", 1);
    save_disabled = false;
    console.log(highest_lvl);
    location.reload();
}

let init_1 = function() {
    memory_elapsed = 5000 - 1000 * get("restep").upgraded - 1000 * get("anti_flow").upgraded - 1000 * get("memory_retrace").upgraded;

    add_navigation("challenge");
    push_button("memory_loss", "challenge_default");
    push_button("catastrophe", "challenge_default");
    push_button("clumsy", "challenge_default");
    push_button("gluttony", "challenge_default");
    push_button("professional", "challenge_default");
    push_button("redundancy", "challenge_default");

    if (get("memory").storage = load_item("memory"))
        unlock("memory");
    if (get("history").storage = load_item("history"))
        unlock("history");
    if (get("relic").storage = load_item("relic"))
        unlock("relic");
    if (get("history").storage) {
        $("challenge_space_show").style = "display:block";
        push_button("inefficiency", "challenge_space");
        push_button("unordered", "challenge_space");
        push_button("resistance", "challenge_space");
        push_button("kenka", "challenge_space");
    }

    // Remember to change this: always push to the last <div>
    push_button("endeavour", "challenge_space");

    change_navigation("challenge");
}

let init_0 = function() {
    add_navigation("bonfire");
    add_navigation("society");
    add_navigation("statistics");
    push_button("fire", "bonfire");
    push_button("collector", "society");
    change_navigation("bonfire");

    setguide("你们是末世之后的几个未受教育的年轻人，试图在这片焦土之上从零开始重建文明。");

    if (get("memory").storage = load_item("memory")) {
        setguide("记忆可以加成全局产量，但效果有上限。");
        unlock("memory");
    }
    if (get("history").storage = load_item("history")) {
        setguide("历史可以提升记忆的效果上限。");
        unlock("history");
    }
    if (get("relic").storage = load_item("relic")) {
        setguide("遗物可以降低全体建筑的价格底数。");
        unlock("relic");
    }
    activate_gene();
}

load();
setInterval(refresh, 1000 / tick_persec);