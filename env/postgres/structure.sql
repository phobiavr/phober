create table devices
(
    id          bigserial
        primary key,
    name        varchar(255) not null,
    type        varchar(255) not null
        constraint devices_type_unique
            unique,
    slug        varchar(255) not null,
    description json,
    created_at  timestamp(0),
    updated_at  timestamp(0)
);

alter table devices
    owner to "user";

create table games
(
    id          bigserial
        primary key,
    name        varchar(255)          not null,
    slug        varchar(255),
    video       varchar(255),
    description json,
    rating      integer default 0,
    multiplayer boolean default false not null,
    created_at  timestamp(0),
    updated_at  timestamp(0)
);

alter table games
    owner to "user";

create table genres
(
    id         bigserial
        primary key,
    name       varchar(255) not null,
    slug       varchar(255),
    created_at timestamp(0),
    updated_at timestamp(0)
);

alter table genres
    owner to "user";

create table game_genre
(
    game_id  bigint not null
        constraint game_genre_game_id_foreign
            references games
            on delete cascade,
    genre_id bigint not null
        constraint game_genre_genre_id_foreign
            references genres
            on delete cascade
);

alter table game_genre
    owner to "user";

create table game_device
(
    game_id bigint       not null
        constraint game_device_game_id_foreign
            references games
            on delete cascade,
    device  varchar(255) not null
);

alter table game_device
    owner to "user";

create table instances
(
    id          bigserial
        primary key,
    mac_address varchar(255),
    device      varchar(255)         not null,
    active      boolean default true not null,
    created_at  timestamp(0),
    updated_at  timestamp(0)
);

alter table instances
    owner to "user";

create table schedules
(
    id          bigserial
        primary key,
    type        varchar(255) not null,
    instance_id bigint       not null
        constraint schedules_instance_id_foreign
            references instances
            on delete cascade,
    start       timestamp(0),
    "end"       timestamp(0),
    created_at  timestamp(0),
    updated_at  timestamp(0)
);

alter table schedules
    owner to "user";

create table tariff_plans
(
    id         bigserial
        primary key,
    tariff     varchar(255)     not null,
    time       varchar(255)     not null,
    price      double precision not null,
    device     varchar(255)     not null,
    created_at timestamp(0),
    updated_at timestamp(0)
);

alter table tariff_plans
    owner to "user";

create table posts
(
    id         bigserial
        primary key,
    title      varchar(255) not null,
    post       text         not null,
    created_at timestamp(0),
    updated_at timestamp(0)
);

alter table posts
    owner to "user";

