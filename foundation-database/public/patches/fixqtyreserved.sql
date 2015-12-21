-- 4.10.0 fix coitem_qtyreserved
-- changes coitem_qtyreserved from inv uom to order uom
do $$
begin
if (compareVersion(fetchMetricText('ServerVersion'), '4.10.0') = -1) then

update coitem set coitem_qtyreserved =
  (select itemuomtouom(itemsite_item_id, NULL, coitem_qty_uom_id, coitem_qtyreserved)
   from itemsite where itemsite_id=coitem_itemsite_id)
where (coitem_qtyreserved != 0.0);

update shipitemrsrv set shipitemrsrv_qty =
  (select itemuomtouom(itemsite_item_id, NULL, coitem_qty_uom_id, shipitemrsrv_qty)
   from shipitem join coitem on (coitem_id=shipitem_orderitem_id) join itemsite on (itemsite_id=coitem_itemsite_id)
   where shipitem_id=shipitemrsrv_shipitem_id)
where (shipitemrsrv_qty != 0.0);

--update reserve set reserve_qty =
--  (select itemuomtouom(itemsite_item_id, NULL, coitem_qty_uom_id, reserve_qty)
--   from coitem join itemsite on (itemsite_id=coitem_itemsite_id)
--   where coitem_id=reserve_demand_id)
--where (reserve_demand_type='SO')
--  and (reserve_qty != 0.0);

--update shipitemlocrsrv set shipitemlocrsrv_qty =
--  (select itemuomtouom(itemsite_item_id, NULL, coitem_qty_uom_id, shipitemlocrsrv_qty)
--   from shipitem join coitem on (coitem_id=shipitem_orderitem_id) join itemsite on (itemsite_id=coitem_itemsite_id)
--   where shipitem_id=shipitemlocrsrv_shipitem_id)
--where (shipitemlocrsrv_qty != 0.0);

end if;
end$$;
