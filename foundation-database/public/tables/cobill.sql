select xt.add_column('cobill','cobill_shipitem_id', 'INTEGER', NULL, 'public');
select xt.add_constraint('cobill', 'cobill_cobill_shipitem_id_fkey', 'FOREIGN KEY (cobill_shipitem_id) REFERENCES shipitem(shipitem_id)', 'public');
