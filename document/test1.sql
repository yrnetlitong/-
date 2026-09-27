-- ThinkPHP 6 + Vue 2 initialization schema (MySQL 5.7, utf8mb4)

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for think_config
-- ----------------------------
DROP TABLE IF EXISTS `think_config`;
CREATE TABLE `think_config` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '配置名称',
  `code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '配置编码',
  `sort` int unsigned NOT NULL DEFAULT '0' COMMENT '排序',
  `note` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `create_user` int unsigned DEFAULT '0' COMMENT '添加人',
  `create_time` int unsigned DEFAULT '0' COMMENT '添加时间',
  `update_user` int unsigned DEFAULT '0' COMMENT '更新人',
  `update_time` int unsigned DEFAULT '0' COMMENT '更新时间',
  `mark` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '有效标识',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `index_name` (`name`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='配置分组表';

-- ----------------------------
-- Records of think_config
-- ----------------------------
BEGIN;
INSERT INTO `think_config` (`id`, `name`, `code`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (1, '网站配置', '', 1, NULL, 1, 1624760995, 0, 0, 1);
INSERT INTO `think_config` (`id`, `name`, `code`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (2, '微信公众号', '', 5, NULL, 1, 1624764674, 0, 0, 1);
INSERT INTO `think_config` (`id`, `name`, `code`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (3, '微信小程序', '', 7, NULL, 1, 1624764684, 0, 0, 1);
INSERT INTO `think_config` (`id`, `name`, `code`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (4, '阿里短信', 'alisms', 9, '阿里短信', 1, 1624764704, 1, 1651723038, 1);
COMMIT;

-- ----------------------------
-- Table structure for think_config_data
-- ----------------------------
DROP TABLE IF EXISTS `think_config_data`;
CREATE TABLE `think_config_data` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `title` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '配置标题',
  `code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '配置编码',
  `value` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '配置值',
  `options` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '配置项',
  `config_id` int unsigned NOT NULL DEFAULT '0' COMMENT '配置ID',
  `type` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '配置类型',
  `status` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '状态：1正常 2停用',
  `sort` smallint unsigned NOT NULL DEFAULT '0' COMMENT '排序',
  `note` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '配置说明',
  `create_user` int unsigned NOT NULL DEFAULT '0' COMMENT '添加人',
  `create_time` int unsigned NOT NULL DEFAULT '0' COMMENT '添加时间',
  `update_user` int unsigned NOT NULL DEFAULT '0' COMMENT '更新人',
  `update_time` int unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  `mark` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '有效标识：1正常 0删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `index_title` (`title`) USING BTREE,
  KEY `index_code` (`code`) USING BTREE,
  KEY `idx_config_mark_sort_id` (`config_id`,`mark`,`sort`,`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='配置表';

-- ----------------------------
-- Records of think_config_data
-- ----------------------------
BEGIN;
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (1, '网站全称', 'site_name', '初始化项目', '', 1, 'text', 1, 1, '暂无', 1, 1624761028, 1, 1680423605, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (2, '网站LOGO', 'site_logo', '', '', 1, 'image', 1, 5, '', 1, 1624761071, 1, 1680423605, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (3, '网站关键词', 'site_keywords', 'ThinkPHP 6、Vue 2、Element UI', '', 1, 'text', 1, 15, '', 1, 1624761820, 1, 1680423606, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (4, '网站描述', 'site_desc', 'ThinkPHP 6 + Vue 2 后台管理初始化模板', '', 1, 'textarea', 1, 19, '', 1, 1624761850, 1, 1680423606, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (5, '网站简称', 'site_nickname', '初始化项目', '', 1, 'text', 1, 3, '', 1, 1624761881, 1, 1680423605, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (6, '网站网址', 'site_url', '', '', 1, 'text', 1, 17, '', 1, 1624761907, 1, 1680423606, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (7, '版权信息', 'site_copyright', '', '', 1, 'text', 1, 13, '', 1, 1624761939, 1, 1680423606, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (8, '备案号', 'site_record', '', '', 1, 'text', 1, 15, '', 1, 1624762309, 1, 1680423606, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (9, '网站QQ', 'site_qq', '暂无', '', 1, 'text', 1, 20, '', 1, 1624762334, 1, 1680423606, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (10, '网站电话', 'site_phone', '暂无', '', 1, 'text', 1, 25, '', 1, 1624762397, 1, 1680423606, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (11, '公司地址', 'site_address', '', '', 1, 'text', 1, 21, '', 1, 1624762425, 1, 1680423606, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (12, '网站邮箱', 'site_email', '', '', 1, 'text', 1, 23, '', 1, 1624762447, 1, 1680423606, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (13, '统计代码', 'site_tongji', '暂无', '', 1, 'textarea', 1, 30, '', 1, 1624762537, 1, 1680423606, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (14, '网站宣传片', 'site_pic', '', '', 1, 'images', 1, 7, '', 1, 1624763080, 1, 1680423605, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (15, 'SEO标题', 'site_seo_title', '初始化项目', '', 1, 'text', 1, 9, '', 1, 1624764263, 1, 1680423605, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (16, 'SEO描述', 'site_seo_desc', 'ThinkPHP 6 + Vue 2 后台管理初始化模板', '', 1, 'textarea', 1, 11, '', 1, 1624764296, 1, 1680423605, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (17, '传真', 'site_fax', '暂无', '', 1, 'text', 1, 27, '', 1, 1624764615, 1, 1680423606, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (18, 'AppId', 'wx_appid', '', '', 2, 'text', 1, 1, '', 1, 1624764765, 1, 1664674238, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (19, 'AppSecret', 'wx_appsecret', '', '', 2, 'text', 1, 5, '', 1, 1624764783, 1, 1664674238, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (20, '微信token', 'wx_token', '暂无', '', 2, 'text', 1, 7, '', 1, 1624764920, 1, 1664674239, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (21, 'EncodingAESKey', 'wx_aeskey', '暂无', '', 2, 'text', 1, 9, '', 1, 1624764954, 1, 1664674239, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (22, '消息加密方式', 'wx_encryption', '1', '1:测试一\n2:测试二\n3:测试三', 2, 'radio', 1, 11, '', 1, 1624765054, 1, 1664674239, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (23, '公众号LOGO', 'wx_logo', '', '', 2, 'image', 1, 13, '', 1, 1624765133, 1, 1664674239, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (24, '微信分享图片', 'wx_share_pic', '', '', 2, 'image', 1, 15, '', 1, 1624765170, 1, 1664674239, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (25, '微信分享标题', 'wx_share_title', '初始化项目', '', 2, 'text', 1, 17, '', 1, 1624765364, 1, 1664674239, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (26, '微信分享描述', 'wx_share_desc', 'ThinkPHP 6 + Vue 2 后台管理初始化模板', '', 2, 'textarea', 1, 19, '', 1, 1624765395, 1, 1664674239, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (27, '小程序AppId', 'wechat_appid', '', '', 3, 'text', 1, 1, '', 1, 1624768308, 1, 1664674284, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (28, '小程序AppSecret', 'wechat_appsecret', '', '', 3, 'text', 1, 5, '', 1, 1624768327, 1, 1664674284, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (29, '小程序名称', 'wechat_name', '软件小程序', '', 3, 'text', 1, 10, '', 1, 1624768343, 1, 1664674284, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (30, '小程序LOGO', 'wechat_logo', '', '', 3, 'image', 1, 15, '', 1, 1624768361, 1, 1664674284, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (31, '小程序二维码', 'wechat_code', '', '', 3, 'image', 1, 20, '', 1, 1624768402, 1, 1664674284, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (32, '小程序分享标题', 'wechat_share_title', '软件小程序', '', 3, 'text', 1, 25, '', 1, 1624768425, 1, 1664674284, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (33, '小程序分享描述', 'wechat_share_desc', 'ThinkPHP 6 + Vue 2 后台管理初始化模板', '', 3, 'textarea', 1, 30, '', 1, 1624768449, 1, 1664674284, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (34, 'accessKeyId', 'accessKeyId', '', '', 4, 'text', 1, 1, '', 1, 1624769395, 1, 1664674291, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (35, 'accessKeySecret', 'accessKeySecret', '', '', 4, 'text', 1, 5, '', 1, 1624769407, 1, 1664674292, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (36, 'regionId', 'regionId', 'cn-hangzhou', '', 4, 'text', 1, 10, '', 1, 1624769419, 1, 1664674292, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (37, '短信签名', 'signName', '', '', 4, 'text', 1, 15, '', 1, 1624769437, 1, 1664674292, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (38, '模板Code', 'templateCode', '暂无', '', 4, 'text', 1, 20, '', 1, 1624769455, 1, 1664674292, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (39, '短信模板', 'sms_tpl', 'ThinkPHP 6 + Vue 2 后台管理初始化模板', '', 4, 'textarea', 1, 25, '', 1, 1624769688, 1, 1664674292, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (40, '网站标签', 'site_tags', '1,3', '1:复选框1\n2:复选框2\n3:复选框3\n4:复选框4', 1, 'checkbox', 1, 8, '', 1, 1625015744, 1, 1680423605, 1);
INSERT INTO `think_config_data` (`id`, `title`, `code`, `value`, `options`, `config_id`, `type`, `status`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (41, '投入平台', 'site_platform', '4', '1:下拉框1\n2:下拉框2\n3:下拉框3\n4:下拉框4\n5:下拉框5', 1, 'select', 1, 12, '', 1, 1625016270, 1, 1680423605, 1);
COMMIT;

-- ----------------------------
-- Table structure for think_dict
-- ----------------------------
DROP TABLE IF EXISTS `think_dict`;
CREATE TABLE `think_dict` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '字典名称',
  `code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '字典值',
  `sort` smallint unsigned NOT NULL DEFAULT '125' COMMENT '显示顺序',
  `note` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '字典备注',
  `create_user` int unsigned NOT NULL DEFAULT '0' COMMENT '添加人',
  `create_time` int unsigned NOT NULL DEFAULT '0' COMMENT '添加时间',
  `update_user` int unsigned NOT NULL DEFAULT '0' COMMENT '更新人',
  `update_time` int unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  `mark` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '有效标识',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `name` (`name`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='字典类型表';

-- ----------------------------
-- Records of think_dict
-- ----------------------------
BEGIN;
INSERT INTO `think_dict` (`id`, `name`, `code`, `sort`, `note`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (1, '机构类型', 'organization_type', 1, '', 1, 1625472423, 1, 1625473227, 1);
COMMIT;

-- ----------------------------
-- Table structure for think_dict_data
-- ----------------------------
DROP TABLE IF EXISTS `think_dict_data`;
CREATE TABLE `think_dict_data` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '字典项名称',
  `code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '字典项值',
  `dict_id` int unsigned NOT NULL DEFAULT '0' COMMENT '字典ID',
  `status` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '状态：1在用 2停用',
  `pet_fields` text DEFAULT NULL,
  `note` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `sort` smallint unsigned NOT NULL DEFAULT '125' COMMENT '显示顺序',
  `create_user` int unsigned NOT NULL DEFAULT '0' COMMENT '添加人',
  `create_time` int unsigned NOT NULL DEFAULT '0' COMMENT '添加时间',
  `update_user` int unsigned NOT NULL DEFAULT '0' COMMENT '更新人',
  `update_time` int unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  `mark` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '有效标记',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `title` (`name`) USING BTREE,
  KEY `idx_dict_mark_sort_id` (`dict_id`,`mark`,`sort`,`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='字典项管理表';

-- ----------------------------
-- Records of think_dict_data
-- ----------------------------
BEGIN;
INSERT INTO `think_dict_data` (`id`, `name`, `code`, `dict_id`, `status`, `note`, `sort`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (1, '公司', 'company', 1, 1, '暂无', 1, 1, 1625472646, 1, 1634268796, 1);
INSERT INTO `think_dict_data` (`id`, `name`, `code`, `dict_id`, `status`, `note`, `sort`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (2, '子公司', 'subsidiary', 1, 1, '', 5, 1, 1625472777, 0, 0, 1);
INSERT INTO `think_dict_data` (`id`, `name`, `code`, `dict_id`, `status`, `note`, `sort`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (3, '部门', 'department', 1, 1, '', 10, 1, 1625472789, 0, 0, 1);
INSERT INTO `think_dict_data` (`id`, `name`, `code`, `dict_id`, `status`, `note`, `sort`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (4, '小组', 'group', 1, 1, '', 15, 1, 1625472799, 0, 0, 1);
COMMIT;

-- ----------------------------
-- Table structure for think_file
-- ----------------------------
DROP TABLE IF EXISTS `think_file`;
CREATE TABLE `think_file` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '文件名',
  `length` int unsigned NOT NULL DEFAULT '0' COMMENT '文件大小(KB)',
  `url` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '文件地址',
  `directory` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '是否文件夹：0文件夹 1文件',
  `type` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '文件类型：1图片 2文件',
  `pid` int unsigned NOT NULL DEFAULT '0' COMMENT '上级ID',
  `sort` int unsigned NOT NULL DEFAULT '0' COMMENT '排序',
  `create_user` int unsigned NOT NULL DEFAULT '0' COMMENT '添加人',
  `create_time` int unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `update_user` int unsigned DEFAULT '0' COMMENT '修改人',
  `update_time` int unsigned DEFAULT '0' COMMENT '更新时间',
  `mark` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '有效标识：1正常 0删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `name` (`name`) USING BTREE,
  KEY `idx_pid_mark_id` (`pid`,`mark`,`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='文件管理表';

-- ----------------------------
-- Records of think_file
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for think_member
-- ----------------------------
DROP TABLE IF EXISTS `think_member`;
CREATE TABLE `think_member` (
  `id` int NOT NULL AUTO_INCREMENT,
  `openid` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户唯一标识',
  `username` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '用户名',
  `password` char(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '密码',
  `member_level` smallint NOT NULL DEFAULT '0' COMMENT '会员等级',
  `realname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '真实姓名',
  `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户昵称',
  `gender` tinyint(1) NOT NULL DEFAULT '3' COMMENT '性别（1男 2女 3未知）',
  `avatar` varchar(180) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '' COMMENT '用户头像',
  `birthday` int unsigned DEFAULT '0' COMMENT '出生日期',
  `province_code` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '户籍省份编号',
  `city_code` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '户籍城市编号',
  `district_code` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '户籍区/县编号',
  `address` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '详细地址',
  `intro` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '个人简介',
  `signature` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '个性签名',
  `device` tinyint(1) NOT NULL DEFAULT '0' COMMENT '设备类型：1苹果 2安卓 3WAP站 4PC站 5后台添加',
  `device_code` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '推送的别名',
  `push_alias` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '' COMMENT '推送的别名',
  `source` tinyint(1) NOT NULL DEFAULT '1' COMMENT '来源：1、APP注册；2、后台添加；',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否启用 1、启用  2、停用',
  `app_version` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '' COMMENT '客户端版本号',
  `code` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '我的推广码',
  `login_ip` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '最近登录IP',
  `login_time` int unsigned NOT NULL DEFAULT '0' COMMENT '登录时间',
  `login_region` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '上次登录地点',
  `login_count` int unsigned NOT NULL DEFAULT '0' COMMENT '登录总次数',
  `create_user` int NOT NULL DEFAULT '0' COMMENT '添加人',
  `create_time` int unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `update_user` int NOT NULL DEFAULT '0' COMMENT '修改人',
  `update_time` int unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  `mark` tinyint(1) NOT NULL DEFAULT '1' COMMENT '有效标识：1正常 0删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_username` (`username`) USING BTREE,
  KEY `idx_mark_status_id` (`mark`,`status`,`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=COMPACT COMMENT='用户表';

-- ----------------------------
-- Records of think_member
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for think_menu
-- ----------------------------
DROP TABLE IF EXISTS `think_menu`;
CREATE TABLE `think_menu` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `pid` int NOT NULL DEFAULT '0' COMMENT '父级ID',
  `title` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '菜单标题',
  `icon` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '图标',
  `path` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '菜单路径',
  `component` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '菜单组件',
  `target` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '打开方式：0组件 1内链 2外链',
  `permission` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '权限标识',
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '类型：0菜单 1节点',
  `status` tinyint(1) DEFAULT '1' COMMENT '状态：1正常 2禁用',
  `hide` tinyint unsigned DEFAULT '0' COMMENT '是否可见：0显示 1隐藏',
  `note` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `sort` smallint DEFAULT '125' COMMENT '显示顺序',
  `create_user` int NOT NULL DEFAULT '0' COMMENT '添加人',
  `create_time` int unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `update_user` int DEFAULT '0' COMMENT '更新人',
  `update_time` int unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  `mark` tinyint(1) NOT NULL DEFAULT '1' COMMENT '有效标识',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `index_pid` (`pid`) USING BTREE,
  KEY `index_name` (`title`) USING BTREE,
  KEY `idx_mark_status_pid_sort` (`mark`,`status`,`pid`,`sort`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=141 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=COMPACT COMMENT='系统菜单表';

-- ----------------------------
-- Records of think_menu
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for think_notice
-- ----------------------------
DROP TABLE IF EXISTS `think_notice`;
CREATE TABLE `think_notice` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '数据编号',
  `title` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '通知标题',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '通知内容',
  `source` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '通知来源：1云平台',
  `is_top` tinyint unsigned NOT NULL DEFAULT '2' COMMENT '是否置顶：1已置顶 2未置顶',
  `browse` int unsigned NOT NULL DEFAULT '0' COMMENT '阅读量',
  `status` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '发布状态：1草稿箱 2立即发布 3定时发布',
  `create_user` int unsigned NOT NULL DEFAULT '0' COMMENT '添加人',
  `create_time` int unsigned NOT NULL DEFAULT '0' COMMENT '添加时间',
  `update_user` int unsigned NOT NULL DEFAULT '0' COMMENT '更新人',
  `update_time` int unsigned DEFAULT '0' COMMENT '更新时间',
  `mark` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '有效标识(1正常 0删除)',
  `pet_member_id` int unsigned NOT NULL DEFAULT 0,
  `pet_object_id` int unsigned NOT NULL DEFAULT 0,
  `pet_kind` varchar(20) NOT NULL DEFAULT '',
  `pet_read_at` int unsigned NOT NULL DEFAULT 0,
  KEY `idx_pet_member` (`pet_member_id`,`mark`,`id`),
  PRIMARY KEY (`id`) USING BTREE,
  KEY `index_title` (`title`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=COMPACT COMMENT='通知公告表';

-- ----------------------------
-- Records of think_notice
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for think_role
-- ----------------------------
DROP TABLE IF EXISTS `think_role`;
CREATE TABLE `think_role` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '角色名称',
  `code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '角色标签',
  `status` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '状态：1正常 2禁用',
  `note` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `sort` smallint unsigned NOT NULL DEFAULT '125' COMMENT '排序',
  `create_user` int unsigned NOT NULL DEFAULT '0' COMMENT '添加人',
  `create_time` int unsigned NOT NULL DEFAULT '0' COMMENT '添加时间',
  `update_user` int unsigned NOT NULL DEFAULT '0' COMMENT '更新人',
  `update_time` int unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  `mark` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '有效标识(1正常 0删除)',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `name` (`name`) USING BTREE,
  KEY `idx_mark_status_sort_id` (`mark`,`status`,`sort`,`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='系统角色表';

-- ----------------------------
-- Records of think_role
-- ----------------------------
BEGIN;
INSERT INTO `think_role` (`id`, `name`, `code`, `status`, `note`, `sort`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (1, '超级管理员', 'super', 1, '超级管理员拥有绝对权限', 1, 1, 1621998864, 1, 1634197059, 1);
COMMIT;

-- ----------------------------
-- Table structure for think_role_menu
-- ----------------------------
DROP TABLE IF EXISTS `think_role_menu`;
CREATE TABLE `think_role_menu` (
  `role_id` smallint unsigned NOT NULL DEFAULT '0' COMMENT '角色ID',
  `menu_id` smallint unsigned NOT NULL DEFAULT '0' COMMENT '菜单ID',
  UNIQUE KEY `uk_role_menu` (`role_id`,`menu_id`) USING BTREE,
  KEY `idx_menu_id` (`menu_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='角色菜单关联表';

-- ----------------------------
-- Records of think_role_menu
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for think_user
-- ----------------------------
DROP TABLE IF EXISTS `think_user`;
CREATE TABLE `think_user` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `realname` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '真实姓名',
  `nickname` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '昵称',
  `gender` tinyint unsigned NOT NULL DEFAULT '3' COMMENT '性别:1男 2女 3保密',
  `avatar` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '头像',
  `mobile` char(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '手机号码',
  `email` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '邮箱地址',
  `birthday` int unsigned DEFAULT '0' COMMENT '出生日期',
  `province_code` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '省份编码',
  `city_code` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '市区编码',
  `district_code` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '0' COMMENT '区县编码',
  `address` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '详细地址',
  `city_name` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '所属城市',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '登录用户名',
  `password` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '登录密码',
  `salt` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '盐加密',
  `intro` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '个人简介',
  `status` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '状态：1正常 2禁用',
  `note` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `sort` smallint unsigned NOT NULL DEFAULT '125' COMMENT '显示顺序',
  `login_num` smallint unsigned NOT NULL DEFAULT '0' COMMENT '登录次数',
  `login_ip` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '最近登录IP',
  `login_time` int unsigned NOT NULL DEFAULT '0' COMMENT '最近登录时间',
  `create_user` int unsigned NOT NULL DEFAULT '0' COMMENT '添加人',
  `create_time` int unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `update_user` int unsigned NOT NULL DEFAULT '0' COMMENT '更新人',
  `update_time` int unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  `mark` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '有效标识(1正常 0删除)',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_username` (`username`) USING BTREE,
  KEY `realname` (`realname`) USING BTREE,
  KEY `idx_mark_status_id` (`mark`,`status`,`id`) USING BTREE,
  KEY `idx_mobile_mark` (`mobile`,`mark`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='后台用户管理表';

-- ----------------------------
-- Records of think_user
-- ----------------------------
BEGIN;
INSERT INTO `think_user` (`id`, `realname`, `nickname`, `gender`, `avatar`, `mobile`, `email`, `birthday`, `province_code`, `city_code`, `district_code`, `address`, `city_name`, `username`, `password`, `salt`, `intro`, `status`, `note`, `sort`, `login_num`, `login_ip`, `login_time`, `create_user`, `create_time`, `update_user`, `update_time`, `mark`) VALUES (1, '管理员', '管理员', 1, '', '', '', 1632326400, '320000', '320100', '320105', '南京市建邺区', '', 'admin', '43286a86708820e38c333cdd4c496355', '', '', 1, '暂无备注', 125, 0, NULL, 0, 1, 1621998864, 1, 1769767394, 1);
COMMIT;

-- ----------------------------
-- Table structure for think_user_role
-- ----------------------------
DROP TABLE IF EXISTS `think_user_role`;
CREATE TABLE `think_user_role` (
  `user_id` int unsigned NOT NULL DEFAULT '0' COMMENT '人员ID',
  `role_id` int unsigned NOT NULL DEFAULT '0' COMMENT '角色ID',
  UNIQUE KEY `uk_user_role` (`user_id`,`role_id`) USING BTREE,
  KEY `idx_role_id` (`role_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='人员角色表';

-- ----------------------------
-- Records of think_user_role
-- ----------------------------
BEGIN;
INSERT INTO `think_user_role` (`user_id`, `role_id`) VALUES (1, 1);
COMMIT;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE IF NOT EXISTS think_pet (
 id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 member_id INT UNSIGNED NOT NULL,
 name VARCHAR(40) NOT NULL,
 type VARCHAR(12) NOT NULL,
 breed VARCHAR(80) NOT NULL DEFAULT '',
 gender VARCHAR(12) NOT NULL DEFAULT 'unknown',
 birthday DATE DEFAULT NULL,
 weight DECIMAL(7,2) NOT NULL DEFAULT 0,
 color VARCHAR(60) NOT NULL DEFAULT '',
 neutered VARCHAR(12) NOT NULL DEFAULT 'unknown',
 vaccination VARCHAR(500) NOT NULL DEFAULT '',
 character_note VARCHAR(500) NOT NULL DEFAULT '',
 note TEXT,
 images TEXT,
 create_time INT UNSIGNED NOT NULL,
 update_time INT UNSIGNED NOT NULL,
 INDEX idx_member (member_id,id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS think_pet_record (
 id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 member_id INT UNSIGNED NOT NULL,
 pet_id INT UNSIGNED NOT NULL,
 type VARCHAR(12) NOT NULL,
 type_name VARCHAR(40) NOT NULL DEFAULT '',
 field_values MEDIUMTEXT,
 occurred_at INT UNSIGNED NOT NULL,
 product VARCHAR(120) NOT NULL DEFAULT '',
 amount VARCHAR(80) NOT NULL DEFAULT '',
 method VARCHAR(80) NOT NULL DEFAULT '',
 next_at INT UNSIGNED NOT NULL DEFAULT 0,
 note TEXT,
 images TEXT,
 create_time INT UNSIGNED NOT NULL,
 INDEX idx_pet_time (pet_id,occurred_at,id),
 INDEX idx_member_type (member_id,type,occurred_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS think_pet_reminder (
 id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 member_id INT UNSIGNED NOT NULL,
 pet_id INT UNSIGNED NOT NULL,
 series_id INT UNSIGNED NOT NULL DEFAULT 0,
 next_id INT UNSIGNED NOT NULL DEFAULT 0,
 title VARCHAR(80) NOT NULL,
 type VARCHAR(20) NOT NULL,
 type_name VARCHAR(40) NOT NULL DEFAULT '',
 cycle VARCHAR(12) NOT NULL,
 interval_days INT UNSIGNED NOT NULL DEFAULT 1,
 due_at INT UNSIGNED NOT NULL,
 advance_days INT UNSIGNED NOT NULL DEFAULT 0,
 enabled TINYINT UNSIGNED NOT NULL DEFAULT 1,
 status TINYINT UNSIGNED NOT NULL DEFAULT 0,
 subscribed TINYINT UNSIGNED NOT NULL DEFAULT 0,
 sent_at INT UNSIGNED NOT NULL DEFAULT 0,
 push_status VARCHAR(20) NOT NULL DEFAULT 'waiting',
 push_error VARCHAR(255) NOT NULL DEFAULT '',
 completed_at INT UNSIGNED NOT NULL DEFAULT 0,
 create_time INT UNSIGNED NOT NULL,
 update_time INT UNSIGNED NOT NULL,
 INDEX idx_member_status (member_id,status,due_at),
 INDEX idx_due (enabled,status,sent_at,due_at),
 INDEX idx_pet (pet_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS think_pet_place (
 id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 member_id INT UNSIGNED NOT NULL DEFAULT 0,
 name VARCHAR(100) NOT NULL,
 category VARCHAR(20) NOT NULL,
 address VARCHAR(255) NOT NULL,
 latitude DECIMAL(10,7) NOT NULL,
 longitude DECIMAL(10,7) NOT NULL,
 phone VARCHAR(30) NOT NULL DEFAULT '',
 hours VARCHAR(100) NOT NULL DEFAULT '',
 rules TEXT,
 note TEXT,
 images TEXT,
 source VARCHAR(12) NOT NULL DEFAULT 'user',
 status TINYINT UNSIGNED NOT NULL DEFAULT 0,
 rejection VARCHAR(500) NOT NULL DEFAULT '',
 is_top TINYINT UNSIGNED NOT NULL DEFAULT 0,
 review_user INT UNSIGNED NOT NULL DEFAULT 0,
 reviewed_at INT UNSIGNED NOT NULL DEFAULT 0,
 create_time INT UNSIGNED NOT NULL,
 update_time INT UNSIGNED NOT NULL,
 INDEX idx_public (status,category,id),
 INDEX idx_member (member_id,status,id),
 INDEX idx_location (status,latitude,longitude)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS think_pet_review (
 id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 member_id INT UNSIGNED NOT NULL,
 place_id INT UNSIGNED NOT NULL,
 rating TINYINT UNSIGNED NOT NULL,
 content VARCHAR(1000) NOT NULL,
 create_time INT UNSIGNED NOT NULL,
 UNIQUE KEY uk_member_place (member_id,place_id),
 INDEX idx_place (place_id,id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `think_config_data` (`id`,`title`,`code`,`value`,`options`,`config_id`,`type`,`status`,`sort`,`note`,`create_user`,`create_time`,`update_user`,`update_time`,`mark`) VALUES (44,'关于豆知','pet_about','豆知宠物，记录成长，照顾日常，一起发现友好去处。','',3,'textarea',1,0,'',0,0,0,0,1);
INSERT INTO `think_config_data` (`id`,`title`,`code`,`value`,`options`,`config_id`,`type`,`status`,`sort`,`note`,`create_user`,`create_time`,`update_user`,`update_time`,`mark`) VALUES (49,'用户协议','pet_agreement','','',3,'textarea',1,0,'',0,0,0,0,1);
INSERT INTO `think_config_data` (`id`,`title`,`code`,`value`,`options`,`config_id`,`type`,`status`,`sort`,`note`,`create_user`,`create_time`,`update_user`,`update_time`,`mark`) VALUES (43,'首页寄语','pet_announcement','把每一天的陪伴，认真记下来。','',3,'textarea',1,0,'',0,0,0,0,1);
INSERT INTO `think_config_data` (`id`,`title`,`code`,`value`,`options`,`config_id`,`type`,`status`,`sort`,`note`,`create_user`,`create_time`,`update_user`,`update_time`,`mark`) VALUES (47,'提醒参考天数JSON','pet_default_days','{"bath":7,"internal":30,"external":30}','',3,'textarea',1,0,'',0,0,0,0,1);
INSERT INTO `think_config_data` (`id`,`title`,`code`,`value`,`options`,`config_id`,`type`,`status`,`sort`,`note`,`create_user`,`create_time`,`update_user`,`update_time`,`mark`) VALUES (48,'隐私政策','pet_privacy','','',3,'textarea',1,0,'',0,0,0,0,1);
INSERT INTO `think_config_data` (`id`,`title`,`code`,`value`,`options`,`config_id`,`type`,`status`,`sort`,`note`,`create_user`,`create_time`,`update_user`,`update_time`,`mark`) VALUES (46,'模板字段映射JSON','pet_reminder_fields','{"thing1":"title","time2":"due_at"}','',3,'textarea',1,0,'',0,0,0,0,1);
INSERT INTO `think_config_data` (`id`,`title`,`code`,`value`,`options`,`config_id`,`type`,`status`,`sort`,`note`,`create_user`,`create_time`,`update_user`,`update_time`,`mark`) VALUES (45,'订阅模板ID','pet_reminder_template','','',3,'textarea',1,0,'',0,0,0,0,1);

INSERT INTO think_dict (id,name,code,mark) VALUES (2,'宠物记录类型','pet_record_types',1);
INSERT INTO think_dict_data (id,dict_id,name,code,status,mark,pet_fields) VALUES (5,2,'喂食','feed',1,1,'[{"key": "product", "label": "食物内容", "kind": "text", "required": true}, {"key": "amount", "label": "喂食量", "kind": "text", "required": false}, {"key": "method", "label": "喂食方式", "kind": "text", "required": false}]');
INSERT INTO think_dict_data (id,dict_id,name,code,status,mark,pet_fields) VALUES (6,2,'洗澡','bath',1,1,'[{"key": "product", "label": "洗护用品", "kind": "text", "required": true}, {"key": "amount", "label": "用量", "kind": "text", "required": false}, {"key": "method", "label": "洗澡方式", "kind": "text", "required": false}]');
INSERT INTO think_dict_data (id,dict_id,name,code,status,mark,pet_fields) VALUES (7,2,'内驱','internal',1,1,'[{"key": "product", "label": "驱虫药品", "kind": "text", "required": true}, {"key": "amount", "label": "用药量", "kind": "text", "required": false}]');
INSERT INTO think_dict_data (id,dict_id,name,code,status,mark,pet_fields) VALUES (8,2,'外驱','external',1,1,'[{"key": "product", "label": "驱虫药品", "kind": "text", "required": true}, {"key": "amount", "label": "用药量", "kind": "text", "required": false}]');
INSERT INTO think_dict_data (id,dict_id,name,code,status,mark,pet_fields) VALUES (9,2,'疫苗','vaccine',1,1,'[{"key": "product", "label": "疫苗名称", "kind": "text", "required": true}, {"key": "amount", "label": "接种剂量", "kind": "text", "required": false}]');
INSERT INTO think_dict_data (id,dict_id,name,code,status,mark,pet_fields) VALUES (10,2,'体检','exam',1,1,'[{"key": "product", "label": "体检项目", "kind": "text", "required": true}, {"key": "amount", "label": "检查结果", "kind": "text", "required": false}]');
INSERT INTO think_dict_data (id,dict_id,name,code,status,mark,pet_fields) VALUES (11,2,'自定义','custom',1,1,'[{"key": "product", "label": "记录内容", "kind": "text", "required": true}]');

INSERT INTO think_dict (id,name,code,mark) VALUES (3,'宠物点位类型','pet_place_types',1);
INSERT INTO think_dict_data (id,dict_id,name,code,status,mark) VALUES (12,3,'餐厅','restaurant',1,1);
INSERT INTO think_dict_data (id,dict_id,name,code,status,mark) VALUES (13,3,'酒店','hotel',1,1);
INSERT INTO think_dict_data (id,dict_id,name,code,status,mark) VALUES (14,3,'公园','park',1,1);
INSERT INTO think_dict_data (id,dict_id,name,code,status,mark) VALUES (15,3,'洗护','grooming',1,1);
INSERT INTO think_dict_data (id,dict_id,name,code,status,mark) VALUES (16,3,'医院','hospital',1,1);

-- 当前后台菜单与按钮权限
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('1','0','系统管理','el-icon-setting','/system','',NULL,'','0','1','0',NULL,'1','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('2','1','用户管理','el-icon-user','/system/user','/system/user/index',NULL,'sys:user:view','0','1','0',NULL,'1','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('3','1','角色管理','el-icon-s-custom','/system/role','/system/role/index',NULL,'sys:role:view','0','1','0',NULL,'2','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('4','1','菜单管理','el-icon-menu','/system/menu','/system/menu/index',NULL,'sys:menu:view','0','1','0',NULL,'3','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('6','1','登录日志','el-icon-document','/system/loginlog','/system/loginlog/index',NULL,'sys:loginlog:view','0','1','0',NULL,'4','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('7','1','操作日志','el-icon-document-copy','/system/operlog','/system/operlog/index',NULL,'sys:operlog:view','0','1','0',NULL,'5','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('15','0','个人中心','el-icon-user','/user/profile','/user/profile',NULL,'','0','1','1',NULL,'99','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('100','2','添加用户','','/user/edit','',NULL,'sys:user:add','1','1','0',NULL,'2','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('101','2','修改用户','','/user/edit','',NULL,'sys:user:edit','1','1','0',NULL,'3','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('102','2','删除用户','','/user/delete','',NULL,'sys:user:delete','1','1','0',NULL,'4','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('103','2','批量删除','','/user/delete','',NULL,'sys:user:dall','1','1','0',NULL,'5','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('104','2','重置密码','','/user/resetpwd','',NULL,'sys:user:resetPwd','1','1','0',NULL,'7','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('105','3','添加角色','','/role/edit','',NULL,'sys:role:add','1','1','0',NULL,'2','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('106','3','修改角色','','/role/edit','',NULL,'sys:role:edit','1','1','0',NULL,'3','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('107','3','删除角色','','/role/delete','',NULL,'sys:role:delete','1','1','0',NULL,'4','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('108','3','分配权限','','/role/savepermission','',NULL,'sys:role:permission','1','1','0',NULL,'7','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('109','4','添加菜单','','/menu/edit','',NULL,'sys:menu:add','1','1','0',NULL,'2','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('110','4','修改菜单','','/menu/edit','',NULL,'sys:menu:edit','1','1','0',NULL,'4','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('111','4','删除菜单','','/menu/delete','',NULL,'sys:menu:delete','1','1','0',NULL,'5','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('145','220','注册用户',NULL,'/petknow/members','/petknow/members',NULL,'pet:members:view','0','1','0',NULL,'1','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('146','145','查询',NULL,'','',NULL,'pet:members:view','1','1','0',NULL,'1','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('147','145','启用/停用',NULL,'','',NULL,'pet:members:edit','1','1','0',NULL,'4','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('148','220','宠物档案',NULL,'/petknow/pets','/petknow/pets',NULL,'pet:pets:view','0','1','0',NULL,'2','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('149','148','查询',NULL,'','',NULL,'pet:pets:view','1','1','0',NULL,'1','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('150','148','异常清理',NULL,'','',NULL,'pet:pets:edit','1','1','0',NULL,'4','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('151','225','养护记录',NULL,'/petknow/records','/petknow/records',NULL,'pet:records:view','0','1','0',NULL,'2','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('152','151','查询',NULL,'','',NULL,'pet:records:view','1','1','0',NULL,'1','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('153','151','删除',NULL,'','',NULL,'pet:records:edit','1','1','0',NULL,'4','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('154','232','友好点位',NULL,'/petknow/places','/petknow/places',NULL,'pet:places:view','0','1','0',NULL,'2','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('155','154','查询',NULL,'','',NULL,'pet:places:view','1','1','0',NULL,'1','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('156','154','新增/编辑与地图选点',NULL,'','',NULL,'pet:places:edit','1','1','0',NULL,'4','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('157','225','提醒与推送',NULL,'/petknow/reminders','/petknow/reminders',NULL,'pet:reminders:view','0','1','0',NULL,'3','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('158','157','查询',NULL,'','',NULL,'pet:reminders:view','1','1','0',NULL,'1','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('163','225','记录类型',NULL,'/petknow/recordtypes','/petknow/recordtypes',NULL,'pet:recordtypes:view','0','1','0',NULL,'1','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('164','163','查询',NULL,'','',NULL,'pet:recordtypes:view','1','1','0',NULL,'1','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('165','163','新增/编辑',NULL,'','',NULL,'pet:recordtypes:edit','1','1','0',NULL,'2','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('166','232','点位类型',NULL,'/petknow/placetypes','/petknow/placetypes',NULL,'pet:placetypes:view','0','1','0',NULL,'1','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('167','166','查询',NULL,'','',NULL,'pet:placetypes:view','1','1','0',NULL,'1','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('168','166','新增/编辑',NULL,'','',NULL,'pet:placetypes:edit','1','1','0',NULL,'2','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('205','2','查询用户',NULL,'/user/index','',NULL,'sys:user:view','1','1','0',NULL,'1','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('206','2','启用/停用',NULL,'/user/status','',NULL,'sys:user:status','1','1','0',NULL,'6','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('207','3','查询角色',NULL,'/role/index','',NULL,'sys:role:view','1','1','0',NULL,'1','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('208','3','批量删除',NULL,'/role/delete','',NULL,'sys:role:dall','1','1','0',NULL,'5','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('209','3','启用/停用',NULL,'/role/status','',NULL,'sys:role:status','1','1','0',NULL,'6','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('210','4','查询菜单',NULL,'/menu/index','',NULL,'sys:menu:view','1','1','0',NULL,'1','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('211','4','添加子级',NULL,'/menu/edit','',NULL,'sys:menu:addz','1','1','0',NULL,'3','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('212','4','启用/停用',NULL,'/menu/status','',NULL,'sys:menu:status','1','1','0',NULL,'6','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('213','6','查询登录日志',NULL,'/loginlog/index','',NULL,'sys:loginlog:view','1','1','0',NULL,'1','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('214','6','详情',NULL,'/loginlog/info','',NULL,'sys:loginlog:detail','1','1','0',NULL,'2','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('215','6','删除',NULL,'/loginlog/delete','',NULL,'sys:loginlog:delete','1','1','0',NULL,'3','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('216','6','导出',NULL,'/loginlog/export','',NULL,'sys:loginlog:export','1','1','0',NULL,'4','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('217','7','查询操作日志',NULL,'/actionlog/index','',NULL,'sys:operlog:view','1','1','0',NULL,'1','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('218','7','详情',NULL,'/actionlog/info','',NULL,'sys:operlog:detail','1','1','0',NULL,'2','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('219','7','导出',NULL,'/actionlog/export','',NULL,'sys:operlog:export','1','1','0',NULL,'3','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('220','0','用户信息','el-icon-user','/pet-users','',NULL,'','0','1','0',NULL,'2','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('221','145','详情',NULL,'','',NULL,'pet:members:detail','1','1','0',NULL,'2','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('222','145','导出',NULL,'','',NULL,'pet:members:export','1','1','0',NULL,'3','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('223','148','详情',NULL,'','',NULL,'pet:pets:detail','1','1','0',NULL,'2','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('224','148','导出',NULL,'','',NULL,'pet:pets:export','1','1','0',NULL,'3','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('225','0','记录管理','el-icon-notebook-2','/pet-records','',NULL,'','0','1','0',NULL,'3','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('226','163','启用/停用',NULL,'','',NULL,'pet:recordtypes:status','1','1','0',NULL,'3','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('227','163','删除',NULL,'','',NULL,'pet:recordtypes:remove','1','1','0',NULL,'4','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('228','151','详情',NULL,'','',NULL,'pet:records:detail','1','1','0',NULL,'2','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('229','151','导出',NULL,'','',NULL,'pet:records:export','1','1','0',NULL,'3','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('230','157','详情',NULL,'','',NULL,'pet:reminders:detail','1','1','0',NULL,'2','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('231','157','导出',NULL,'','',NULL,'pet:reminders:export','1','1','0',NULL,'3','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('232','0','友好点位','el-icon-location','/pet-places','',NULL,'','0','1','0',NULL,'4','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('233','166','启用/停用',NULL,'','',NULL,'pet:placetypes:status','1','1','0',NULL,'3','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('234','166','删除',NULL,'','',NULL,'pet:placetypes:remove','1','1','0',NULL,'4','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('235','154','详情',NULL,'','',NULL,'pet:places:detail','1','1','0',NULL,'2','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('236','154','导出',NULL,'','',NULL,'pet:places:export','1','1','0',NULL,'3','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('237','154','审核通过',NULL,'','',NULL,'pet:places:approve','1','1','0',NULL,'5','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('238','154','驳回',NULL,'','',NULL,'pet:places:reject','1','1','0',NULL,'6','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('239','154','上架/下架',NULL,'','',NULL,'pet:places:status','1','1','0',NULL,'7','1');
INSERT INTO think_menu (`id`,`pid`,`title`,`icon`,`path`,`component`,`target`,`permission`,`type`,`status`,`hide`,`note`,`sort`,`mark`) VALUES ('240','154','置顶/取消置顶',NULL,'','',NULL,'pet:places:top','1','1','0',NULL,'8','1');
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,1);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,2);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,3);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,4);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,6);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,7);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,15);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,100);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,101);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,102);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,103);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,104);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,105);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,106);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,107);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,108);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,109);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,110);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,111);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,145);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,146);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,147);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,148);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,149);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,150);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,151);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,152);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,153);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,154);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,155);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,156);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,157);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,158);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,163);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,164);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,165);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,166);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,167);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,168);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,205);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,206);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,207);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,208);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,209);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,210);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,211);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,212);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,213);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,214);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,215);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,216);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,217);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,218);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,219);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,220);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,221);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,222);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,223);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,224);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,225);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,226);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,227);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,228);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,229);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,230);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,231);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,232);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,233);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,234);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,235);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,236);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,237);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,238);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,239);
INSERT INTO think_role_menu (role_id,menu_id) VALUES (1,240);
INSERT INTO think_config_data (config_id,code,title,value,type,options,note,status,mark) VALUES (3,'pet_menu_revision','后台菜单迁移版本','20260924','text','','',1,1);
