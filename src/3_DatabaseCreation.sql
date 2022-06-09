drop database if exists airport_db;
create database airport_db;
use airport_db;

create table passengers (
	passenger_id int primary key not null auto_increment,
    first_name varchar(255) not null,
    last_name varchar(255) not null,
    age int not null,
    curp varchar(20) not null,
    address varchar(255) not null,
    phone_number varchar(20) not null,
    sex enum('male', 'female', 'intersex') not null
);

create table airports (
	-- airport_id int primary key not null,
    iata_code varchar(50) primary key not null,
    name varchar(255) not null,
    city varchar(255) not null,
    state varchar(255) not null,
    address varchar(255) not null,
    phone_number varchar(20) not null
);

create table flights (
	flight_id int primary key not null auto_increment,
    airline enum('Hawaiian Airlines', 'United Airlines', 'Viva Aerobus', 'Aeromexico', 'Air New Zealand') not null,
    departure datetime not null,
    arrival datetime not null,
    duration_min int not null,
    distance_km int not null,
    departure_airport_id varchar(50) not null,
    arrival_airport_id varchar(50) not null,

    foreign key (departure_airport_id) references airports(iata_code),
    foreign key (arrival_airport_id) references airports(iata_code)
);

create table tickets (
	ticket_id int primary key not null auto_increment,
    price double not null,
    class enum('economy', 'business', 'first') not null,
    confirmation_number int not null,
    passenger_id int not null,
    flight_id int not null,

    foreign key (passenger_id) references passengers(passenger_id),
    foreign key (flight_id) references flights(flight_id)
);




