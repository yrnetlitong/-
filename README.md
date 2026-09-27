# 豆知宠物 PetKnow

一款面向养宠用户的宠物养护管理平台，包含 **微信小程序（用户端）**、**Web 管理后台（运营端）** 和 **PHP 后端 API**。支持宠物档案管理、养护记录、疫苗/驱虫提醒、宠物友好场所地图、用户点评等功能。

## 功能特性

### 用户端（微信小程序）
- **宠物档案**：支持添加多只宠物，记录品种、生日、性别、体重、头像等信息
- **养护记录**：按自定义记录类型（如疫苗、驱虫、洗澡、体检等）记录宠物养护日志，支持动态字段
- **提醒事项**：疫苗、驱虫等周期提醒，支持重复周期、完成打卡、过期提醒、订阅通知
- **豆玩地图**：基于高德地图展示附近宠物友好场所（餐厅、酒店、公园、洗护、医院），支持导航
- **场所点评**：对宠物友好场所打分（1-5 星）并发表评价
- **场所投稿**：用户可自行提交新的宠物友好场所，经管理员审核后上线
- **消息通知**：系统公告、审核结果等站内消息
- **微信登录**：基于 JWT 的鉴权体系

### 管理后台（Web）
- **数据看板**：宠物数量、用户数、记录数、场所数等概览统计
- **宠物管理**：查看和管理用户宠物档案
- **养护记录管理**：查看全平台宠物养护记录
- **场所管理**：审核用户投稿的场所、管理场所分类（餐厅/酒店/公园/洗护/医院等）
- **记录类型管理**：自定义养护记录类型及其表单字段（文本/多行文本/数字），支持排序和启停
- **点位类型管理**：自定义宠物友好场所分类
- **提醒管理**：查看和管理用户提醒
- **用户管理**：会员信息管理
- **系统管理**：管理员账号、角色权限、菜单管理、字典管理、系统配置、公告管理、登录日志、操作日志
- **文件管理**：上传文件管理（支持七牛云存储）

## 技术栈

| 端 | 技术 |
|---|---|
| 后端 | PHP >= 7.3, ThinkPHP 6.0, ThinkORM |
| 管理后台前端 | Vue 2.6, Element UI, EleAdmin, ECharts, Tinymce |
| 用户端 | 微信小程序原生 |
| 数据库 | MySQL >= 5.7 |
| 缓存 | 文件 / Redis |
| 鉴权 | JWT (firebase/php-jwt) |
| 地图 | 高德地图 JS API |
| 文件存储 | 七牛云 SDK |

## 目录结构

```
petknow/
├── app/                        # PHP 后端应用（ThinkPHP 多应用模式）
│   ├── admin/                  # 管理后台 API
│   │   ├── controller/        # 控制器（登录、用户、角色、菜单、字典、配置、宠物、场所等）
│   │   ├── middleware/         # 中间件（登录校验、跨域、初始化）
│   │   ├── model/              # 数据模型
│   │   └── service/            # 业务逻辑层
│   ├── api/                    # 小程序端 API
│   │   ├── controller/        # Pet（宠物/记录/提醒/场所/点评/消息）、Amap、Upload
│   │   └── middleware/         # JWT 鉴权中间件
│   ├── common/                 # 公共模块
│   │   └── service/            # PetService、ReminderService、WechatService、AmapService 等
│   ├── command/                # CLI 命令（安装、定时提醒任务）
│   ├── index/                  # 默认入口应用
│   ├── m/                      # H5 移动端应用
│   └── script/                 # 脚本入口
├── config/                     # ThinkPHP 配置文件（数据库、缓存、会话、路由等）
├── document/                   # 数据库 SQL 文件
│   ├── petknow.sql             # 建表语句 + 初始数据
│   └── test1.sql
├── evui/                       # 管理后台前端源码（Vue 2 + EleAdmin）
│   ├── public/                 # 构建产物（含 tinymce 编辑器资源）
│   └── src/
│       ├── api/                # 接口请求封装
│       ├── assets/             # 静态资源（图片、图标）
│       ├── components/         # 公共组件（上传图片、富文本编辑器）
│       ├── layout/             # 布局组件
│       ├── router/             # 路由
│       ├── store/              # Vuex 状态管理
│       ├── styles/             # 全局样式
│       ├── utils/              # 工具函数
│       └── views/              # 页面
│           ├── dashboard/      # 数据看板
│           ├── petknow/       # 宠物业务（概览、宠物、记录、提醒、场所、点位类型、记录类型、成员、设置）
│           ├── system/         # 系统管理（用户、角色、菜单、登录日志、操作日志）
│           ├── data/           # 数据字典管理
│           ├── member/         # 会员管理
│           ├── message/        # 公告管理
│           └── exception/     # 错误页（403/404/500）
├── miniprogram/                # 微信小程序源码
│   ├── pages/                  # 页面（首页、宠物、地图、我的、宠物详情、编辑、记录、提醒、场所、投稿、登录、消息、信息）
│   ├── images/                 # tabBar 图标
│   ├── utils/                  # API 封装、UI 工具
│   ├── templates/              # 公共模板
│   ├── app.js / app.json / app.wxss
│   └── project.config.json
├── public/                     # Web 入口目录（Nginx/Apache 站点根目录）
│   ├── index.php               # 后端入口文件
│   ├── adminadmin/             # 管理后台构建产物（已编译的静态文件）
│   ├── static/                 # 公共静态资源
│   ├── .htaccess               # URL 重写规则
│   └── router.php
├── route/                      # 路由定义
├── scripts/                    # 部署与运维脚本
│   ├── dev/                    # 本地开发脚本（启动、停止、日志）
│   ├── build-frontend.sh       # 构建管理后台
│   ├── build-miniprogram.sh    # 构建小程序
│   ├── init-project.sh         # 项目初始化
│   ├── import-database.sh      # 导入数据库
│   ├── db-backup.sh            # 数据库备份
│   └── srv_pull_master.sh      # 服务器拉取更新
├── tests/                      # 测试脚本
├── extend/                     # 扩展类库（JWT、验证码）
├── .example.env                 # 环境变量示例
├── .gitignore
├── composer.json                # PHP 依赖
├── Makefile                    # 常用命令快捷方式
└── think                       # ThinkPHP CLI 入口
```

## 环境要求

- PHP >= 7.3
- Composer >= 2.0
- Node.js 18
- MySQL >= 5.7
- Nginx / Apache

## 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/yrnetlitong/douzhichongwu.git
cd douzhichongwu
```

### 2. 配置环境变量

```bash
cp .example.env .env
```

编辑 `.env`，填写数据库连接信息、JWT 密钥、微信小程序 AppID/Secret、高德地图 Key、七牛云配置等。

### 3. 安装后端依赖

```bash
composer install
```

### 4. 导入数据库

```bash
mysql -u root -p your_database < document/petknow.sql
```

### 5. 构建管理后台前端

```bash
cd evui
npm install
npm run build:prod
# 构建产物会输出到 ../public/adminadmin/
```

### 6. 配置 Web 服务器

将 Nginx/Apache 站点根目录指向 `public/` 目录，开启 URL 重写（参考 `public/.htaccess` 或 `scripts/thinkphp-rewrite.conf`）。

### 7. 配置定时任务（宠物提醒推送）

```bash
# 每小时执行一次提醒检查
* */1 * * * cd /path/to/petknow && php think pet:remind
```

## 默认账号

安装后请及时修改默认管理员密码。

## License

Apache-2.0
