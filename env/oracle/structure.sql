CREATE TABLE CUSTOMERS
(
    ID         NUMBER(19)                      NOT NULL
        CONSTRAINT CUSTOMERS_ID_PK
            PRIMARY KEY,
    FIRST_NAME VARCHAR2(255),
    LAST_NAME  VARCHAR2(255),
    BIRTHDAY   DATE                            NOT NULL,
    GENDER     CHAR,
    DISCOUNT   NUMBER(5)     DEFAULT 0         NOT NULL,
    BALANCE    NUMBER(10)    DEFAULT 0         NOT NULL,
    NOTE       CLOB,
    CREATED_AT TIMESTAMP(6),
    UPDATED_AT TIMESTAMP(6),
    STATUS     VARCHAR2(255) DEFAULT 'PENDING' NOT NULL
);

CREATE SEQUENCE CUSTOMERS_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

create trigger CUSTOMERS_ID_TRG
    before insert
    on CUSTOMERS
    for each row
begin
    if :new.ID is null then
        select customers_id_seq.nextval into :new.ID from dual;
    end if;
end;

CREATE TABLE CONTACTS
(
    ID          NUMBER(19)    NOT NULL
        CONSTRAINT CONTACTS_ID_PK
            PRIMARY KEY,
    CUSTOMER_ID NUMBER(19)
        CONSTRAINT CONTACTS_CUSTOMER_ID_FK
            REFERENCES CUSTOMERS
                ON DELETE SET NULL,
    VALUE       VARCHAR2(255) NOT NULL,
    TYPE        VARCHAR2(255) NOT NULL,
    CREATED_AT  TIMESTAMP(6),
    UPDATED_AT  TIMESTAMP(6)
);

create trigger CONTACTS_ID_TRG
    before insert
    on CONTACTS
    for each row
begin
    if :new.ID is null then
        select contacts_id_seq.nextval into :new.ID from dual;
    end if;
end;

CREATE SEQUENCE CONTACTS_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOCACHE;


CREATE TABLE LOYALTY_CARDS
(
    ID         NUMBER(19) NOT NULL
        CONSTRAINT LOYALTY_CARDS_ID_PK
            PRIMARY KEY
        CONSTRAINT LOYALTY_CARDS_ID_FK
            REFERENCES CUSTOMERS,
    CODE       VARCHAR2(255),
    STATUS     VARCHAR2(255) DEFAULT 'BASIC',
    CREATED_AT TIMESTAMP(6),
    UPDATED_AT TIMESTAMP(6)
);