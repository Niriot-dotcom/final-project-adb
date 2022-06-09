/*
*
* Views
*
*/

-- View de ticket con información de pasajero

CREATE OR REPLACE VIEW passenger_ticket_info AS
SELECT `tickets`.`ticket_id`,pas.`first_name`, pas.`last_name`,`tickets`.`price`,`tickets`.`class`,`tickets`.`confirmation_number`,`tickets`.`flight_id` 
FROM `airport_db`.`tickets`
JOIN `airport_db`.`passengers` pas ON `tickets`.`passenger_id` = pas.`passenger_id`;

SELECT * FROM passenger_ticket_info;

-- View con información de vuelo completa

CREATE OR REPLACE VIEW flights_full_info AS
SELECT `flights`.`flight_id`,`flights`.`airline`,dep.`name` departure_airport,dep.`city` departure_city,`flights`.`departure` departure_time,arr.`city` arrival_city,arr.`name` arrival_airport,`flights`.`arrival` arrival_time,`flights`.`duration_min`,`flights`.`distance_km`
FROM `airport_db`.`flights`
JOIN `airport_db`.`airports` dep ON `flights`.`departure_airport_id` = dep.`iata_code`
JOIN `airport_db`.`airports` arr ON `flights`.`arrival_airport_id` = arr.`iata_code`;

SELECT * FROM flights_full_info;

-- View con información de pasajero e información completa de vuelo

CREATE OR REPLACE VIEW tickets_full_info AS
SELECT `passenger_ticket_info`.`ticket_id`,`passenger_ticket_info`.`first_name`,`passenger_ticket_info`.`last_name`,`passenger_ticket_info`.`price`,`passenger_ticket_info`.`class`,`passenger_ticket_info`.`confirmation_number`,ffi.`airline`,ffi.`departure_airport`,ffi.`departure_city`,ffi.`departure_time`,ffi.`arrival_city`,ffi.`arrival_airport`,ffi.`arrival_time`,ffi.`duration_min`
FROM `airport_db`.`passenger_ticket_info`
JOIN `airport_db`.`flights_full_info` ffi ON `passenger_ticket_info`.`flight_id` = ffi.`flight_id`;

SELECT * FROM tickets_full_info;

/*
*
* Stored procedures
*
*/

-- Procedure que retorna todos los vuelos disponibles de la aerolinea seleccionada

DROP PROCEDURE IF EXISTS get_flights_by_airline;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE get_flights_by_airline(airline varchar(100))
BEGIN
	IF airline = '' OR isnull(airline) THEN 
		SET airline = 'Hawaiian Airlines'; 
	END IF;
	IF airline NOT IN (SELECT ffi.airline FROM flights_full_info ffi) THEN
		SIGNAL SQLSTATE '19202'
		SET MESSAGE_TEXT = 'Invalid airline';
	END IF;
    SELECT * FROM flights_full_info ffi where ffi.airline = airline;
END$$
DELIMITER ;

CALL `airport_db`.`get_flights_by_airline`('Aeromexico');

-- Procedure que retorna todos lo boletos que ha comprado una persona, introduciendo su id

DROP PROCEDURE IF EXISTS get_my_tickets;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE get_my_tickets(id int)
BEGIN
	IF isnull(id) THEN 
		SET id = 1; 
	END IF;
	IF id NOT IN (SELECT tkt.passenger_id FROM tickets tkt) THEN
		SIGNAL SQLSTATE '19202'
		SET MESSAGE_TEXT = 'Invalid id';
	END IF;
    SELECT * FROM tickets_full_info tfi
    WHERE tfi.ticket_id IN (SELECT tkt.ticket_id FROM tickets tkt WHERE id = tkt.passenger_id);
END$$
DELIMITER ;

CALL `airport_db`.`get_my_tickets`(1);

-- Procedure que cambia los horarios de un vuelo

DROP PROCEDURE IF EXISTS change_flight_schedule;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE change_flight_schedule(id int,departure_time datetime)
BEGIN
	IF isnull(id) THEN 
		SET id = 1; 
	END IF;
    IF isnull(departure_time) THEN
		SET departure_time = now();
	END IF;
	IF id NOT IN (SELECT flt.flight_id FROM flights flt) THEN
		SIGNAL SQLSTATE '19202'
		SET MESSAGE_TEXT = 'Invalid id';
	END IF;
    UPDATE `airport_db`.`flights`
	SET
	`departure` = departure_time,`arrival` = DATE_ADD(departure_time, INTERVAL (SELECT duration_min WHERE flight_id = id) MINUTE)
	WHERE `flight_id` = id;
END$$
DELIMITER ;

CALL `airport_db`.`change_flight_schedule`(1, now());
