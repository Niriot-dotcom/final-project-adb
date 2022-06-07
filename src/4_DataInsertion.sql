INSERT INTO `airport_db`.`airports`
(`iata_code`,`name`,`city`,`state`,`address`,`phone_number`)
VALUES
('MEX', 'Benito Juárez International Airport', 'Mexico City','Mexico City','Av. Capitán Carlos León S/N, Peñón de los Baños, Venustiano Carranza','55 2482 2400'),
('JFK', 'John F. Kennedy International Airport', 'Queens','New York','Queens, NY','+1 718-244-4444'),
('HND', 'Haneda International Airport', 'Ota City','Tokyo','Hanedakuko, Ota City','+81 3-5757-8111'),
('DME', 'Moscú-Domodédovo International Airport', 'Moscow Oblast','Moscow Oblast','Moscow Oblast','+7 495 933-66-66'),
('YQB', 'Québec City Jean-Lesage International Airport', 'Québec','Québec','505 Rue Principale, Québec','+1 418-640-3300');

INSERT INTO `airport_db`.`passengers`
(`first_name`,`last_name`,`age`,`curp`,`address`,`phone_number`,`sex`)
VALUES
('Juan Pablo','Enríquez Pedroza',21,'EIPJ001227HASNDNA8','Los Reales #119, Fracc. Paso de Argenta','449 781-57-40','male'),
('Paty','López Méndez',20,'LOMP729472894929MA','Paseo de la plata #215, Fracc. Paso de Argenta','449 769-73-79','female'),
('Ulises','Gallardo Rodríguez',20,'GARU193675PALRYCR9','Molienda de la mina #101, Fracc. Paso de Argenta','449 781-57-40','male'),
('Vanessa','Gómez Ramos',20,'GORV011115MTKMTIA2','Mineral de indene #130, Fracc. Paso de Argenta','449 993-18-99','female'),
('Francisco Javier','Enríquez Pedroza',23,'EIPF981013QRMJTPS1','Los Reales #119, Fracc. Paso de Argenta','449 364-73-19','male');

INSERT INTO `airport_db`.`flights`
(`airline`,`departure`,`arrival`,`duration_min`,`distance_km`,`departure_airport_id`,`arrival_airport_id`)
VALUES
('Hawaiian Airlines','2022-06-07 00:00:00','2022-06-07 04:27:00',267,3364,'MEX','JFK'),
('United Airlines','2023-02-19 02:00:00','2023-02-19 14:41:00',761,10368,'YQB','HND'),
('Viva Aerobus','2022-11-15 15:00:00','2022-11-15 16:20:00',80,710,'JFK','YQB'),
('Aeromexico','2022-12-27 01:00:00','2022-12-27 14:10:00',790,107775,'DME','MEX'),
('Air New Zealand','2023-01-31 13:00:00','2023-01-31 22:20:00',560,7518,'HND','DME');

INSERT INTO `airport_db`.`tickets`
(`price`,`class`,`confirmation_number`,`passenger_id`,`flight_id`)
VALUES
(1511,'first',1902,4,9),
(1511,'first',1902,1,9),
(2197,'business',3671,3,7),
(3759,'economy',9875,2,11),
(1547,'economy',3497,5,10);
