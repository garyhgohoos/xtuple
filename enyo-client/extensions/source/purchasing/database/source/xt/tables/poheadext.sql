select xt.create_table('poheadext');

select xt.add_column('poheadext','poheadext_id', 'integer', 'primary key');
select xt.add_column('poheadext','poheadext_potype_id', 'integer');
select xt.add_constraint('poheadext', 'poheadext_potype_id_fkey', 'foreign key (poheadext_potype_id) references xt.potype (potype_id)');

comment on table xt.poheadext is 'Purchase Order extension table';

-- auto workflow generation trigger
drop trigger if exists powf_after_insert on xt.poheadext;
create trigger powf_after_insert after insert on xt.poheadext for each row
execute procedure xt.createwf_after_insert();
