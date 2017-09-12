# ************************************************************
# Sequel Pro SQL dump
# Version 4541
#
# http://www.sequelpro.com/
# https://github.com/sequelpro/sequelpro
#
# Host: localhost (MySQL 5.5.5-10.1.20-MariaDB)
# Database: riemer
# Generation Time: 2017-08-22 11:57:08 +0000
# ************************************************************


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# Dump of table ajr_sequence_data
# ------------------------------------------------------------

DROP TABLE IF EXISTS `ajr_sequence_data`;

CREATE TABLE `ajr_sequence_data` (
  `sequence_name` varchar(100) NOT NULL,
  `sequence_increment` int(11) unsigned NOT NULL DEFAULT '1',
  `sequence_min_value` int(11) unsigned NOT NULL DEFAULT '1',
  `sequence_max_value` bigint(20) unsigned NOT NULL DEFAULT '18446744073709551615',
  `sequence_cur_value` bigint(20) unsigned DEFAULT '1',
  `sequence_cycle` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`sequence_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `ajr_sequence_data` WRITE;
/*!40000 ALTER TABLE `ajr_sequence_data` DISABLE KEYS */;

INSERT INTO `ajr_sequence_data` (`sequence_name`, `sequence_increment`, `sequence_min_value`, `sequence_max_value`, `sequence_cur_value`, `sequence_cycle`)
VALUES
	('COUNTRY_SEQ',1,1,18446744073709551615,313,0),
	('REGION_SEQ',1,1,18446744073709551615,62,0);

/*!40000 ALTER TABLE `ajr_sequence_data` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table country
# ------------------------------------------------------------

DROP TABLE IF EXISTS `country`;

CREATE TABLE `country` (
  `id` int(10) NOT NULL COMMENT 'Unique sequence number that identifies a country.  (primary key)',
  `code` char(3) DEFAULT NULL COMMENT 'Country code.  A three letter code to identify a country (conformed to ISO published three-character codes).',
  `name` varchar(34) DEFAULT NULL COMMENT 'Full country name.',
  `region` int(10) NOT NULL COMMENT 'Refers to REGION.ID which is the geographical region this country is in.',
  `two_char_code` char(2) DEFAULT NULL COMMENT 'Two-character country code (per published ISO standard), alternative\nto CODE which is three-character code.',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='This table contains country information by sequence number.  It is a child of REGION and has a child STATE.';

LOCK TABLES `country` WRITE;
/*!40000 ALTER TABLE `country` DISABLE KEYS */;

INSERT INTO `country` (`id`, `code`, `name`, `region`, `two_char_code`)
VALUES
	(20,'USA','United States',7,'US'),
	(22,'CAN','Canada',7,'CA'),
	(25,'JPN','Japan',8,'JP'),
	(27,'ATG','Antigua - Barbuda',9,'AG'),
	(28,'HTI','Haiti',9,'HT'),
	(29,'DOM','Dominican Republic',9,'DO'),
	(30,'JAM','Jamaica',9,'JM'),
	(31,'BHS','Bahamas',9,'BS'),
	(32,'BRB','Barbados',9,'BB'),
	(33,'MTQ','Martinique',9,'MQ'),
	(34,'ANT','Netherlands Antilles',9,'AN'),
	(35,'LCA','St. Lucia',9,'LC'),
	(36,'TTO','Trinidad - Tobago',9,'TT'),
	(37,'VGB','Virgin Islands (British)',9,'VG'),
	(38,'BMU','Bermuda',7,'BM'),
	(39,'CRI','Costa Rica',10,'CR'),
	(40,'SLV','El Salvador',10,'SV'),
	(41,'GTM','Guatemala',10,'GT'),
	(42,'HND','Honduras',10,'HN'),
	(43,'MEX','Mexico',10,'MX'),
	(44,'NIC','Nicaragua',10,'NI'),
	(45,'PAN','Panama',10,'PA'),
	(46,'ARG','Argentina',11,'AR'),
	(47,'BLZ','Belize',10,'BZ'),
	(48,'BOL','Bolivia',11,'BO'),
	(49,'BRA','Brazil',11,'BR'),
	(50,'CHL','Chile',11,'CL'),
	(51,'COL','Colombia',11,'CO'),
	(52,'ECU','Ecuador',11,'EC'),
	(53,'GUY','Guyana',11,'GY'),
	(54,'PRY','Paraguay',11,'PY'),
	(55,'PER','Peru',11,'PE'),
	(56,'SUR','Suriname',11,'SR'),
	(57,'URY','Uruguay',11,'UY'),
	(58,'VEN','Venezuela',11,'VE'),
	(59,'VNM','Vietnam',8,'VN'),
	(61,'SRB','Serbia',12,'RS'),
	(62,'GBR','United Kingdom',12,'GB'),
	(63,'TUR','Turkey',12,'TR'),
	(64,'CHE','Switzerland',12,'CH'),
	(65,'SWE','Sweden',12,'SE'),
	(66,'ESP','Spain',12,'ES'),
	(67,'ROU','Romania',12,'RO'),
	(68,'PRT','Portugal',12,'PT'),
	(69,'POL','Poland',12,'PL'),
	(70,'NOR','Norway',12,'NO'),
	(71,'NLD','Netherlands',12,'NL'),
	(72,'MLT','Malta',12,'MT'),
	(73,'ITA','Italy',12,'IT'),
	(74,'IRL','Ireland',12,'IE'),
	(75,'ISL','Iceland',12,'IS'),
	(76,'HUN','Hungary',12,'HU'),
	(77,'GRC','Greece',12,'GR'),
	(78,'DEU','Germany',12,'DE'),
	(79,'FRA','France',12,'FR'),
	(80,'FIN','Finland',12,'FI'),
	(81,'DNK','Denmark',12,'DK'),
	(82,'CZE','Czech Republic',12,'CZ'),
	(83,'CYP','Cyprus',13,'CY'),
	(85,'RUS','Russia',12,'RU'),
	(86,'BGR','Bulgaria',12,'BG'),
	(87,'BEL','Belgium',12,'BE'),
	(88,'AUT','Austria',12,'AT'),
	(89,'YEM','Yemen',13,'YE'),
	(90,'ARE','United Arab Emirates',13,'AE'),
	(91,'SYR','Syria',13,'SY'),
	(92,'SAU','Saudi Arabia',13,'SA'),
	(93,'QAT','Qatar',13,'QA'),
	(94,'OMN','Oman',13,'OM'),
	(95,'LBN','Lebanon',13,'LB'),
	(96,'KWT','Kuwait',13,'KW'),
	(97,'JOR','Jordan',13,'JO'),
	(98,'ISR','Israel',13,'IL'),
	(99,'IRQ','Iraq',13,'IQ'),
	(100,'IRN','Iran',13,'IR'),
	(101,'EGY','Egypt',14,'EG'),
	(102,'BHR','Bahrain',13,'BH'),
	(103,'ZWE','Zimbabwe',14,'ZW'),
	(104,'ZMB','Zambia',14,'ZM'),
	(105,'COD','Congo Democratic Republic (Zaire)',14,'CD'),
	(106,'UGA','Uganda',14,'UG'),
	(107,'TUN','Tunisia',14,'TN'),
	(108,'TGO','Togo',14,'TG'),
	(109,'TZA','Tanzania',14,'TZ'),
	(110,'ZAF','South Africa',14,'ZA'),
	(111,'SEN','Senegal',14,'SN'),
	(112,'NGA','Nigeria',14,'NG'),
	(113,'MOZ','Mozambique',14,'MZ'),
	(114,'MAR','Morocco',14,'MA'),
	(115,'MWI','Malawi',14,'MW'),
	(116,'MDG','Madagascar',14,'MG'),
	(117,'LBY','Libya',14,'LY'),
	(118,'LBR','Liberia',14,'LR'),
	(119,'KEN','Kenya',14,'KE'),
	(120,'CIV','Ivory Coast',14,'CI'),
	(121,'GHA','Ghana',14,'GH'),
	(122,'GAB','Gabon',14,'GA'),
	(123,'ETH','Ethiopia',14,'ET'),
	(124,'CMR','Cameroon',14,'CM'),
	(125,'BDI','Burundi',14,'BI'),
	(126,'AGO','Angola',14,'AO'),
	(127,'DZA','Algeria',14,'DZ'),
	(128,'THA','Thailand',8,'TH'),
	(129,'TWN','Taiwan',8,'TW'),
	(130,'LKA','Sri Lanka',8,'LK'),
	(131,'KOR','South Korea',8,'KR'),
	(132,'SGP','Singapore',8,'SG'),
	(134,'PAK','Pakistan',8,'PK'),
	(135,'IND','India',8,'IN'),
	(136,'HKG','Hong Kong',8,'HK'),
	(137,'CHN','China (PRC)',8,'CN'),
	(138,'BGD','Bangladesh',8,'BD'),
	(139,'AFG','Afghanistan',8,'AF'),
	(141,'PHL','Philippines',8,'PH'),
	(142,'NZL','New Zealand',15,'NZ'),
	(143,'MNP','Northern Mariana Isl',15,'MP'),
	(144,'MYS','Malaysia',8,'MY'),
	(145,'IDN','Indonesia',8,'ID'),
	(146,'GUM','Guam',15,'GU'),
	(147,'FJI','Fiji',15,'FJ'),
	(148,'AUS','Australia',15,'AU'),
	(160,'ALL','All Locations',7,NULL),
	(161,'SVN','Slovenia',12,'SI'),
	(162,'LUX','Luxembourg',12,'LU'),
	(163,'BWA','Botswana',14,'BW'),
	(164,'ASM','American Samoa',15,'AS'),
	(165,'CYM','Cayman Islands',9,'KY'),
	(166,'BRN','Brunei',8,'BN'),
	(167,'NAM','Namibia',14,'NA'),
	(168,'GLP','Guadeloupe',9,'GP'),
	(169,'ALB','Albania',12,'AL'),
	(170,'COG','Congo',14,'CG'),
	(171,'VUT','Vanuatu',15,'VU'),
	(172,'PLW','Palau',15,'PW'),
	(174,'AND','Andorra',12,'AD'),
	(175,'HRV','Croatia',12,'HR'),
	(176,'ABW','Aruba',9,'AW'),
	(178,'EST','Estonia',12,'EE'),
	(179,'LVA','Latvia',12,'LV'),
	(180,'LTU','Lithuania',12,'LT'),
	(181,'BLR','Belarus',12,'BY'),
	(182,'UMI','U.S. Minor Outl Isl',15,'UM'),
	(183,'MHL','Marshall Islands',15,'MH'),
	(184,'IOT','British Indian Oc Terr',8,'IO'),
	(185,'NCL','New Caledonia',15,'NC'),
	(186,'GRD','Grenada',9,'GD'),
	(187,'BEN','Benin',14,'BJ'),
	(188,'BFA','Burkina Faso',14,'BF'),
	(189,'GIN','Guinea',14,'GN'),
	(190,'SLE','Sierra Leone',14,'SL'),
	(191,'SDN','Sudan',14,'SD'),
	(192,'SWZ','Swaziland',14,'SZ'),
	(193,'MUS','Mauritius',14,'MU'),
	(194,'REU','Reunion',14,'RE'),
	(195,'LAO','Laos',8,'LA'),
	(196,'MMR','Myanmar',8,'MM'),
	(197,'PNG','Papua New Guinea',15,'PG'),
	(198,'KIR','Kiribati',15,'KI'),
	(199,'CAF','Central African Rep',14,'CF'),
	(200,'UKR','Ukraine',12,'UA'),
	(202,'TON','Tonga',15,'TO'),
	(203,'MSR','Montserrat',9,'MS'),
	(204,'KNA','St. Kitts - Nevis',9,'KN'),
	(205,'VCT','St. Vincent - Gren',9,'VC'),
	(206,'NPL','Nepal',8,'NP'),
	(208,'GRL','Greenland',7,'GL'),
	(209,'PYF','French Polynesia',15,'PF'),
	(210,'AIA','Anguilla',9,'AI'),
	(211,'MAC','Macau',8,'MO'),
	(212,'SVK','Slovakia',12,'SK'),
	(213,'CUB','Cuba',9,'CU'),
	(216,'GMB','Gambia',14,'GM'),
	(235,'MKD','Macedonia',12,'MK'),
	(236,'MCO','Monaco',12,'MC'),
	(237,'DMA','Dominica',9,'DM'),
	(238,'LIE','Liechtenstein',12,'LI'),
	(239,'MNG','Mongolia',8,'MN'),
	(240,'GEO','Georgia',12,'GE'),
	(241,'CPV','Cape Verde',14,'CV'),
	(242,'TCD','Chad',14,'TD'),
	(243,'DJI','Djibouti',14,'DJ'),
	(244,'GNQ','Equatorial Guinea',14,'GQ'),
	(245,'ERI','Eritrea',14,'ER'),
	(246,'GNB','Guinea-Bissau',14,'GW'),
	(247,'LSO','Lesotho',14,'LS'),
	(248,'MLI','Mali',14,'ML'),
	(249,'MRT','Mauritania',14,'MR'),
	(250,'MYT','Mayotte',14,'YT'),
	(251,'RWA','Rwanda',14,'RW'),
	(252,'STP','Sao Tome - Principe',14,'ST'),
	(253,'SYC','Seychelles',14,'SC'),
	(254,'SOM','Somalia',14,'SO'),
	(255,'SHN','St. Helena',14,'SH'),
	(256,'ATA','Antarctica',61,'AQ'),
	(257,'AZE','Azerbaijan',8,'AZ'),
	(258,'BTN','Bhutan',8,'BT'),
	(259,'KHM','Cambodia',8,'KH'),
	(260,'CXR','Christmas Island',8,'CX'),
	(261,'CCK','Cocos (Keeling) Isl',8,'CC'),
	(262,'TLS','East Timor (Timor-Leste)',8,'TL'),
	(263,'KAZ','Kazakhstan',8,'KZ'),
	(264,'KGZ','Kyrgyzstan',8,'KG'),
	(265,'MDV','Maldives',8,'MV'),
	(266,'PRK','North Korea',8,'KP'),
	(267,'TJK','Tajikistan',8,'TJ'),
	(269,'TKM','Turkmenistan',8,'TM'),
	(270,'UZB','Uzbekistan',8,'UZ'),
	(271,'TCA','Turks - Caicos Isl',9,'TC'),
	(272,'ARM','Armenia',12,'AM'),
	(273,'BIH','Bosnia Herzegovina',12,'BA'),
	(274,'BVT','Bouvet Island',12,'BV'),
	(275,'FRO','Faroe Islands',12,'FO'),
	(276,'GIB','Gibraltar',12,'GI'),
	(277,'MDA','Moldova',12,'MD'),
	(278,'SMR','San Marino',12,'SM'),
	(279,'SJM','Svalbard',12,'SJ'),
	(280,'VAT','Vatican City',12,'VA'),
	(281,'SPM','St. Pierre - Miquelon',7,'PM'),
	(282,'COK','Cook Islands',15,'CK'),
	(283,'HMD','Heard - McDonald Isl',15,'HM'),
	(284,'FSM','Micronesia Fed St',15,'FM'),
	(285,'NRU','Nauru',15,'NR'),
	(286,'NIU','Niue',15,'NU'),
	(287,'NFK','Norfolk Island',15,'NF'),
	(288,'PCN','Pitcairn Islands',15,'PN'),
	(289,'WSM','Samoa',15,'WS'),
	(290,'SLB','Solomon Islands',15,'SB'),
	(291,'TKL','Tokelau',15,'TK'),
	(292,'TUV','Tuvalu',15,'TV'),
	(293,'WLF','Wallis - Futuna',15,'WF'),
	(294,'FLK','Falkland Islands',11,'FK'),
	(295,'GUF','French Guiana',11,'GF'),
	(296,'NER','Niger',14,'NE'),
	(297,'COM','Comoros',14,'KM'),
	(298,'MNE','Montenegro',12,'ME'),
	(299,'ATF','French Southern Territories',61,'TF'),
	(300,'MAF','Saint Martin (French Part)',9,'MF'),
	(301,'SXM','Sint Maarten (Dutch Part)',9,'SX'),
	(302,'CUW','Curacao',9,'CW'),
	(303,'BLM','Saint Barthelemy',9,'BL'),
	(304,'ALA','Åland',12,'AX'),
	(305,'IMN','Isle of Man',12,'IM'),
	(306,'ESH','Western Sahara',14,'EH'),
	(307,'GGY','Guernsey',12,'GG'),
	(308,'PRI','Puerto Rico',9,'PR'),
	(309,'PSE','Palestine, State of',13,'PS'),
	(310,'SGS','South Georgia',61,'GS'),
	(311,'JEY','Jersey',12,'JE'),
	(312,'VIR','Virgin Islands, U.S.',9,'VI'),
	(999,'UNK','Unknown',19,NULL);

/*!40000 ALTER TABLE `country` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table region
# ------------------------------------------------------------

DROP TABLE IF EXISTS `region`;

CREATE TABLE `region` (
  `id` int(10) unsigned NOT NULL COMMENT 'Primary Key',
  `name` varchar(34) DEFAULT NULL COMMENT 'Name of geographical region.',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='This table contains geographical region information by sequence number.  It is has a child of COUNTRY.';

LOCK TABLES `region` WRITE;
/*!40000 ALTER TABLE `region` DISABLE KEYS */;

INSERT INTO `region` (`id`, `name`)
VALUES
	(7,'North America'),
	(8,'Asia'),
	(9,'Caribbean'),
	(10,'Central America'),
	(11,'South America'),
	(12,'Europe'),
	(13,'Middle East'),
	(14,'Africa'),
	(15,'Pacific'),
	(19,'Unknown'),
	(61,'Antarctica');

/*!40000 ALTER TABLE `region` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table state
# ------------------------------------------------------------

DROP TABLE IF EXISTS `state`;

CREATE TABLE `state` (
  `code` char(2) NOT NULL DEFAULT '' COMMENT 'State or province code.  Two uppercase letters as defined by the US Postal Service.  This is the primary key of this table.',
  `country` int(10) NOT NULL COMMENT 'Country number.  Country number.  Refers to COUNTRY.ID where the long name is stored.  This is the country for which this state or province is a member of.',
  `name` varchar(34) NOT NULL DEFAULT '' COMMENT 'State or Province full name,  (Up-Low)',
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='State and Provence information.  Child table of country.';

LOCK TABLES `state` WRITE;
/*!40000 ALTER TABLE `state` DISABLE KEYS */;

INSERT INTO `state` (`code`, `country`, `name`)
VALUES
	('AA',20,'Military (FL)'),
	('AB',22,'Alberta'),
	('AE',20,'Military (NY)'),
	('AK',20,'Alaska'),
	('AL',20,'Alabama'),
	('AP',20,'Military (CA)'),
	('AR',20,'Arkansas'),
	('AZ',20,'Arizona'),
	('BC',22,'British Columbia'),
	('CA',20,'California'),
	('CO',20,'Colorado'),
	('CT',20,'Connecticut'),
	('DC',20,'District of Columbia'),
	('DE',20,'Delaware'),
	('FL',20,'Florida'),
	('GA',20,'Georgia'),
	('HI',20,'Hawaii'),
	('IA',20,'Iowa'),
	('ID',20,'Idaho'),
	('IL',20,'Illinois'),
	('IN',20,'Indiana'),
	('KS',20,'Kansas'),
	('KY',20,'Kentucky'),
	('LA',20,'Louisiana'),
	('MA',20,'Massachusetts'),
	('MB',22,'Manitoba'),
	('MD',20,'Maryland'),
	('ME',20,'Maine'),
	('MI',20,'Michigan'),
	('MN',20,'Minnesota'),
	('MO',20,'Missouri'),
	('MS',20,'Mississippi'),
	('MT',20,'Montana'),
	('NB',22,'New Brunswick'),
	('NC',20,'North Carolina'),
	('ND',20,'North Dakota'),
	('NE',20,'Nebraska'),
	('NH',20,'New Hampshire'),
	('NJ',20,'New Jersey'),
	('NL',22,'Newfoundland - Labrador'),
	('NM',20,'New Mexico'),
	('NS',22,'Nova Scotia'),
	('NT',22,'Northwest Territories'),
	('NU',22,'Nunavut'),
	('NV',20,'Nevada'),
	('NY',20,'New York'),
	('OH',20,'Ohio'),
	('OK',20,'Oklahoma'),
	('ON',22,'Ontario'),
	('OR',20,'Oregon'),
	('PA',20,'Pennsylvania'),
	('PE',22,'Prince Edward Island'),
	('QC',22,'Quebec'),
	('RI',20,'Rhode Island'),
	('SC',20,'South Carolina'),
	('SD',20,'South Dakota'),
	('SK',22,'Saskatchewan'),
	('TN',20,'Tennessee'),
	('TX',20,'Texas'),
	('UT',20,'Utah'),
	('VA',20,'Virginia'),
	('VT',20,'Vermont'),
	('WA',20,'Washington'),
	('WI',20,'Wisconsin'),
	('WV',20,'West Virginia'),
	('WY',20,'Wyoming'),
	('YT',22,'Yukon Territory');

/*!40000 ALTER TABLE `state` ENABLE KEYS */;
UNLOCK TABLES;



/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
