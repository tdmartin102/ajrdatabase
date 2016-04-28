

CREATE TABLE `ajr_sequence_data` (
	`sequence_name` varchar(100) NOT NULL,
	`sequence_increment` int(11) unsigned NOT NULL DEFAULT 1,
	`sequence_min_value` int(11) unsigned NOT NULL DEFAULT 1,
	`sequence_max_value` bigint(20) unsigned NOT NULL DEFAULT 18446744073709551615,
	`sequence_cur_value` bigint(20) unsigned DEFAULT 1,
	`sequence_cycle` boolean NOT NULL DEFAULT FALSE,
	PRIMARY KEY (`sequence_name`)
) ENGINE=InnoDB;


-- you might want to change the engine to InnoDB so that we can do a lock on the update

-- This code will create sequence with default values.
INSERT INTO ajr_sequence_data
	(sequence_name)
VALUE
	('sq_my_sequence')
;

 
-- You can also customize the sequence behavior.
INSERT INTO ajr_sequence_data
	(sequence_name, sequence_increment, sequence_max_value)
VALUE
	('sq_sequence_2', 10, 100)
;


DELIMITER $$

-- The folowing function is for convenience for SQL commands done on the command line.
-- The MySQL EOF Adaptor accesses the table directly and does not use the function
-- This is so that it can do row level locking AND also so that it can select a 
-- RANGE of sequence numbers.
DROP FUNCTION IF EXISTS `nextval` $$
CREATE FUNCTION `nextval` (`seq_name` varchar(100)) 
RETURNS bigint(20) NOT DETERMINISTIC
BEGIN
	DECLARE cur_val bigint(20);

	SELECT
		sequence_cur_value INTO cur_val
	FROM
		`ajr_sequence_data`
	WHERE
		sequence_name = seq_name;

	IF cur_val IS NOT NULL THEN
		UPDATE
			`ajr_sequence_data`
		SET
			sequence_cur_value = IF (
				(sequence_cur_value + sequence_increment) > sequence_max_value,
			IF (
				sequence_cycle = TRUE,
				sequence_min_value,
				NULL
			),
			sequence_cur_value + sequence_increment
		)
		WHERE
			sequence_name = seq_name;
	END IF;

	RETURN cur_val;

END $$

DELIMITER ;


SELECT nextval('sq_my_sequence') as next_sequence;


-- you might want to replace the SELECT with SELECT FOR UPDATE