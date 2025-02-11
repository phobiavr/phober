create table phober_shared.authors
(
    id              bigint unsigned auto_increment
        primary key,
    authorable_type varchar(255)    not null,
    authorable_id   bigint unsigned not null,
    created_by      bigint unsigned null,
    last_updated_by bigint unsigned null,
    created_at      timestamp       null,
    updated_at      timestamp       null
);

create index authors_authorable_type_authorable_id_index
    on phober_shared.authors (authorable_type, authorable_id);

create table phober_shared.media
(
    id                    bigint unsigned auto_increment
        primary key,
    model_type            varchar(255)    not null,
    model_id              bigint unsigned not null,
    uuid                  char(36)        null,
    collection_name       varchar(255)    not null,
    name                  varchar(255)    not null,
    file_name             varchar(255)    not null,
    mime_type             varchar(255)    null,
    disk                  varchar(255)    not null,
    conversions_disk      varchar(255)    null,
    size                  bigint unsigned not null,
    manipulations         json            not null,
    custom_properties     json            not null,
    generated_conversions json            not null,
    responsive_images     json            not null,
    order_column          int unsigned    null,
    created_at            timestamp       null,
    updated_at            timestamp       null,
    constraint media_uuid_unique
        unique (uuid)
);

create index media_model_type_model_id_index
    on phober_shared.media (model_type, model_id);

create index media_order_column_index
    on phober_shared.media (order_column);

create table phober_shared.telescope_entries
(
    sequence                bigint unsigned auto_increment
        primary key,
    uuid                    char(36)             not null,
    batch_id                char(36)             not null,
    family_hash             varchar(255)         null,
    should_display_on_index tinyint(1) default 1 not null,
    type                    varchar(20)          not null,
    content                 longtext             not null,
    created_at              datetime             null,
    constraint telescope_entries_uuid_unique
        unique (uuid)
);

create index telescope_entries_batch_id_index
    on phober_shared.telescope_entries (batch_id);

create index telescope_entries_created_at_index
    on phober_shared.telescope_entries (created_at);

create index telescope_entries_family_hash_index
    on phober_shared.telescope_entries (family_hash);

create index telescope_entries_type_should_display_on_index_index
    on phober_shared.telescope_entries (type, should_display_on_index);

create table phober_shared.telescope_entries_tags
(
    entry_uuid char(36)     not null,
    tag        varchar(255) not null,
    constraint telescope_entries_tags_entry_uuid_foreign
        foreign key (entry_uuid) references phober_shared.telescope_entries (uuid)
            on delete cascade
);

create index telescope_entries_tags_entry_uuid_tag_index
    on phober_shared.telescope_entries_tags (entry_uuid, tag);

create index telescope_entries_tags_tag_index
    on phober_shared.telescope_entries_tags (tag);

create table phober_shared.telescope_monitoring
(
    tag varchar(255) not null
);

