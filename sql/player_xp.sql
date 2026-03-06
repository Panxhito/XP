CREATE TABLE IF NOT EXISTS `player_xp` (
  `citizenid` varchar(64) NOT NULL,
  `xp` int NOT NULL DEFAULT 0,
  `level` int NOT NULL DEFAULT 1,
  `prestige` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `player_xp_logs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(64) NOT NULL,
  `source` varchar(32) NOT NULL DEFAULT 'generic',
  `amount` int NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_xp_logs_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
