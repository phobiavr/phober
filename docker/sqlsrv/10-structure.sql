create table phober_auth.dbo.password_resets
(
    email      nvarchar(255) not null,
    token      nvarchar(255) not null,
    created_at datetime
);

create index password_resets_email_index
    on phober_auth.dbo.password_resets (email);

create table phober_auth.dbo.permissions
(
    id         bigint identity
        primary key,
    name       nvarchar(255) not null,
    created_at datetime,
    updated_at datetime
);

create unique index permissions_name_unique
    on phober_auth.dbo.permissions (name);

create table phober_auth.dbo.personal_access_tokens
(
    id             bigint identity
        primary key,
    tokenable_type nvarchar(255) not null,
    tokenable_id   bigint        not null,
    name           nvarchar(255) not null,
    token          nvarchar(64)  not null,
    abilities      nvarchar(max),
    last_used_at   datetime,
    created_at     datetime,
    updated_at     datetime
);

create index personal_access_tokens_tokenable_type_tokenable_id_index
    on phober_auth.dbo.personal_access_tokens (tokenable_type, tokenable_id);

create unique index personal_access_tokens_token_unique
    on phober_auth.dbo.personal_access_tokens (token);

create table phober_auth.dbo.roles
(
    id         bigint identity
        primary key,
    name       nvarchar(255) not null,
    created_at datetime,
    updated_at datetime
);

create table phober_auth.dbo.role_permissions
(
    role_id       bigint not null
        constraint role_permissions_role_id_foreign
            references roles,
    permission_id bigint not null
        constraint role_permissions_permission_id_foreign
            references permissions
);

create unique index roles_name_unique
    on phober_auth.dbo.roles (name);

create table phober_auth.dbo.users
(
    id                bigint identity
        primary key,
    username          nvarchar(255) not null,
    first_name        nvarchar(255),
    last_name         nvarchar(255),
    telegram          nvarchar(255),
    telegram_chat_id  nvarchar(255),
    api_token         nvarchar(255),
    email             nvarchar(255),
    email_verified_at datetime,
    password          nvarchar(255) not null,
    remember_token    nvarchar(100),
    created_at        datetime,
    updated_at        datetime
);

create table phober_auth.dbo.user_permissions
(
    user_id       bigint not null
        constraint user_permissions_user_id_foreign
            references users,
    permission_id bigint not null
        constraint user_permissions_permission_id_foreign
            references permissions
);

create table phober_auth.dbo.user_roles
(
    user_id bigint not null
        constraint user_roles_user_id_foreign
            references users,
    role_id bigint not null
        constraint user_roles_role_id_foreign
            references roles
);

create unique index users_username_unique
    on phober_auth.dbo.users (username);


create table phober_staff.dbo.employees
(
    id         bigint identity
        primary key,
    first_name nvarchar(255) not null,
    last_name  nvarchar(255) not null,
    created_at datetime,
    updated_at datetime
);

create table phober_staff.dbo.invoices
(
    id             bigint identity
        primary key,
    customer_id    bigint,
    customer       nvarchar(255),
    status         nvarchar(255) default 'QUEUE' not null,
    payment_method nvarchar(255),
    created_at     datetime,
    updated_at     datetime
);

create table phober_staff.dbo.reservations
(
    id            bigint identity
        primary key,
    contacts      nvarchar(255)                 not null,
    date          datetime,
    customers_qty int,
    customers_yo  int,
    status        nvarchar(255) default 'QUEUE' not null,
    note          nvarchar(max),
    request_from  nvarchar(255),
    customer_id   bigint,
    created_at    datetime,
    updated_at    datetime
);

create table phober_staff.dbo.sessions
(
    id          bigint identity
        primary key,
    instance_id bigint,
    schedule_id bigint,
    serviced_by bigint
        constraint sessions_serviced_by_foreign
            references employees,
    time        int,
    price       float,
    status      nvarchar(255) default 'QUEUE' not null,
    discount    float         default '0'     not null,
    invoice_id  bigint
        constraint sessions_invoice_id_foreign
            references invoices,
    note        nvarchar(max),
    created_at  datetime,
    updated_at  datetime
);

create table phober_staff.dbo.snack_sales
(
    id         bigint identity
        primary key,
    snack      nvarchar(255) not null,
    quantity   int           not null,
    price      float         not null,
    invoice_id bigint
        constraint snack_sales_invoice_id_foreign
            references invoices,
    created_at datetime,
    updated_at datetime
);

create table phober_staff.dbo.snacks
(
    id         bigint identity
        primary key,
    name       nvarchar(255)     not null,
    stock      int   default '0' not null,
    price      float default '0' not null,
    created_at datetime,
    updated_at datetime
);


