create trigger CUSTOMERS_ID_TRG
    before insert
    on CUSTOMERS
    for each row
begin
    if :new.ID is null then
        select customers_id_seq.nextval into :new.ID from dual;
    end if;
end;
/

create trigger CONTACTS_ID_TRG
    before insert
    on CONTACTS
    for each row
begin
    if :new.ID is null then
        select contacts_id_seq.nextval into :new.ID from dual;
    end if;
end;
/



