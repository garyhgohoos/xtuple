select xt.add_column('cobmisc','cobmisc_shiphead_id', 'INTEGER', NULL, 'public');
select xt.add_constraint('cobmisc', 'cobmisc_cobmisc_shiphead_id_fkey', 'FOREIGN KEY (cobmisc_shiphead_id) REFERENCES shiphead(shiphead_id)', 'public');
