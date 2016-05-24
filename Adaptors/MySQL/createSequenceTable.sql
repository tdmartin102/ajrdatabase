

-- The following is the table to implement a table based sequence primary key
-- The table below is ALL that is needed for this implementation.  The
-- function 'nextval' is for command line convience ONLY the adaptor does not
-- use it.

CREATE TABLE `ajr_sequence_data` (
	`sequence_name` varchar(100) NOT NULL,
	`sequence_increment` int(11) unsigned NOT NULL DEFAULT 1,
	`sequence_min_value` int(11) unsigned NOT NULL DEFAULT 1,
	`sequence_max_value` bigint(20) unsigned NOT NULL DEFAULT 18446744073709551615,
	`sequence_cur_value` bigint(20) unsigned DEFAULT 1,
	`sequence_cycle` boolean NOT NULL DEFAULT FALSE,
	PRIMARY KEY (`sequence_name`)
) ENGINE=InnoDB;
