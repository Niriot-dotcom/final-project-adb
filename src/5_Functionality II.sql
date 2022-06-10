
use airport_db;
/*Nuevas tablas usadas*/
CREATE TABLE Audit_changes
(
	ID int not null auto_increment,
    action_type nvarchar(50),
    action_table nvarchar(50),
    action_date datetime,
    primary key(ID)
); 

/*INSERT INTO Audit_changes (action_type, action_table, action_date) Values ("update","tickets",NOW());*/

CREATE TABLE backup_ticket
(
	curp_passenger varchar(20) primary key not null,
    price double not null,
    class enum('economy', 'business', 'first') not null,
    confirmation_number int not null,
    flight_id int not null
);


/*------------------------------------------Funciones--------------------------------------------*/


DELIMITER $$
CREATE FUNCTION `average_time_flight_hours` ()
RETURNS FLOAT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
	declare average decimal(6,2) default 0.0;
    select (sum(duration_min)/ count(*))/60
    into average
    from flights;
RETURN average;
END $$

select average_time_flight_hours();

DELIMITER $$
CREATE FUNCTION `revenue_airline` (airline_name varchar(50))
RETURNS FLOAT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
	declare total decimal(8,2) default 0.0;
    select sum(tickets.price) into total
    from flights 
	join tickets on tickets.flight_id = flights.flight_id
	where airline = airline_name;
RETURN total;
END $$

select revenue_airline('Hawaiian Airlines');

DELIMITER $$
CREATE FUNCTION `average_velocity_flights_m_s` ()
RETURNS FLOAT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
	declare average decimal(10,3) default 0.0;
	select sum(((distance_km * 1000)/(duration_min*60) ))/count(*)
    into average
    from flights;
RETURN average;
END $$

select average_velocity_flights_m_s();

/*------------------------------------------Triggers--------------------------------------------*/

DROP TRIGGER IF EXISTS add_action_after_update_tickets;
SHOW TRIGGERS;	

/*Actualiza los minutos en caso que la fecha de llegada se actualice por otra más temprana o por una más tardía. */

DELIMITER $$
CREATE TRIGGER change_duration_after_arrival_update 
BEFORE UPDATE ON flights
FOR EACH ROW
BEGIN
   IF (NEW.arrival != OLD.arrival) 
   THEN
       SET NEW.duration_min = TIMESTAMPDIFF(MINUTE, OLD.departure, NEW.arrival);
   END IF;
END $$
DELIMITER $$  

select flight_id, departure, arrival, TIMESTAMPDIFF(MINUTE, departure, arrival) from flights;

update flights 
set arrival = NOW()
where flight_id = 1;

select flight_id, departure, arrival, TIMESTAMPDIFF(MINUTE, departure, arrival) from flights;
/*https://dba.stackexchange.com/questions/120078/update-one-mysql-column-when-another-is-edited*/

/*2*/
/*hace un resplado de tickets que han sido eliminados*/

DELIMITER $$
CREATE TRIGGER backup_tickets
AFTER DELETE ON tickets
FOR EACH ROW
BEGIN
	insert into backup_ticket (curp_passenger,price,class,confirmation_number,flight_id)
    values ((select curp from passengers where passenger_id = old.passenger_id), old.price, old.class,old.confirmation_number, old.flight_id);
END $$
DELIMITER $$  

delete from tickets where ticket_id = 1
select * from backup_ticket;
select * from tickets;

/*3*/
/*inserta registros de auditoria cada vez se que actualiza la tabla de tickets. */
DELIMITER $$
CREATE TRIGGER add_action_after_update_tickets
	AFTER UPDATE ON tickets
	FOR EACH ROW
    BEGIN
		INSERT INTO Audit_changes (action_type, action_table, action_date)
		Values ("update","tickets",NOW());
	END $$
DELIMITER $$  

select * from Audit_changes;
update tickets, (select price from  tickets where ticket_id = 2) as p set tickets.price = p.price * 1.25 where ticket_id = 2;
select * from Audit_changes;


/*https://stackoverflow.com/questions/45494/mysql-error-1093-cant-specify-target-table-for-update-in-from-clause*/
/*----------------------------------------------------------------Eventos-------------------------------------------------------------*/
DELIMITER $$  
CREATE EVENT delete_audit_registers
    ON SCHEDULE
      EVERY 1 YEAR 
    COMMENT 'Clears out Audit table each year.'
    DO
		BEGIN
		  DELETE FROM Audit_changes;
		END $$
DELIMITER $$  

DELIMITER $$  
CREATE EVENT delete_backup_tickets
    ON SCHEDULE
      EVERY 3 YEAR 
    COMMENT 'Clears out back up tickets table each 3 years.'
    DO
		BEGIN
		  DELETE FROM backup_ticket;
		END $$
DELIMITER $$  

/*suponiendo que la edad no se pueda editar y que no tenemos una fecha de cumpleaños del pasajero, cada año actualiza las edades*/

DELIMITER $$  
CREATE EVENT update_ages
    ON SCHEDULE
      EVERY 1 YEAR 
    COMMENT "Update passenger's age every year."
    DO
		BEGIN
		  update passengers set age = age+1 WHERE passenger_id>=1;
		END $$
DELIMITER $$  

SHOW EVENTS;
/*----------------------------------------------------------------Transacciones-------------------------------------------------------------*/


/*1) Transaccion para cuando modificamos el precio de los boletos y a la vez queremos obtener dicho precio*/
/*Dirty read is the state of reading uncommitted data. */
/*Otra instancia*/


START TRANSACTION;
SELECT price FROM tickets where ticket_id = @ticket_id_1; 
COMMIT;

/*instancia principal*/
set transaction isolation level read committed; /*solución*/

SELECT * FROM tickets;

SET @ticket_id_1 = 2; 
START TRANSACTION;
UPDATE tickets SET price = price-20 where ticket_id = @ticket_id_1;
DO SLEEP(10); 
ROLLBACK; 

/*
	debido al Rollback volverá a su estado original, pero en la otra instancia el valor del precio será 20 unidades menos, por tanto es una lectura sucia
*/
SELECT * FROM tickets;

/*2) Transaccion para cuando modificamos la salida de los vuelos y a la vez queremos obtener dicha fecha dos veces en una misma transaccion*/
/*Non repeatable read*/
select * from flights;

SET @flight_id_ = 1; 
/*Otra instancia*/
START TRANSACTION;
UPDATE flights set departure = NOW() where flight_id = @flight_id_; 
COMMIT;

/*instancia principal*/
set transaction isolation level repeatable read; /*solución*/
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; /*error*/
select * from flights;


SET @flight_id_ = 1; 
START TRANSACTION;
select departure from flights where flight_id = @flight_id_; 
DO SLEEP(10);
select departure from flights where flight_id = @flight_id_;
COMMIT;


/*
	La transacción de la instancia principal deberá imprimir los mismos valores en ambos selects para la fecha de salida.
    Sin el "repeatable read" dichos selects en la transacción principal cambiarán. 
    Orden de ejecución:
		1.-Instancia principal
        2.-Otra instancia (antes de los 7 segundos de la instancia principal)
*/

/*3) Lost Updates -> actualizar el precio de los tickets en dos transacciones diferentes*/
select * from tickets;

SET @tickets_id = 2; /*2*/
/*Otra instancia*/
START TRANSACTION;
SET @precio = 0;
SELECT price INTO @precio FROM tickets where ticket_id = @tickets_id;
DO SLEEP(2);
UPDATE tickets SET price = @precio+20 where ticket_id = @tickets_id;
SELECT price FROM tickets where ticket_id = @tickets_id;
COMMIT;

/*instancia principal*/
set transaction isolation level repeatable read; /*solución, bloquea la transacción que intenta acceder a la misma información*/

select * from tickets;
SET @tickets_id = 2;

START TRANSACTION;
SET @precio = 0;
SELECT price INTO @precio FROM tickets where ticket_id = @tickets_id;
DO SLEEP(10);
UPDATE tickets SET price = @precio+100 where ticket_id = @tickets_id;
SELECT price FROM tickets where ticket_id = @tickets_id;
COMMIT;

/*
	Orden de ejecución:
		1.- Ejecutar instancia principal
        2.- Ejecutar instancia secundaria
        3.- La instancia secundaria deberá terminar primero, y generará el lost update dado que la instancia principal guardó un valor diferente.
        4.- Para evitar esto, se usa el repeatable read, que bloquea la segunda instancia.
*/

