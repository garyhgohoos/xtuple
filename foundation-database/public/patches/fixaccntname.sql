-- 4.8.0 fix accnt_name
-- accnt trigger will use fixed formatGLAccount to correctly format accnt_name
do $$
begin
if fetchMetricText('ServerVersion') < '4.9.0' then

update accnt set accnt_name='';

end if;
end$$;