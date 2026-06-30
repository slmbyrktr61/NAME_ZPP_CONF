@EndUserText.label: 'Tüketim Stokta Kalacak Miktarlar Tabl.'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_TKetimStoktaKalacak
  as select from zpp_t_conf_006 as t6
  inner join I_Product on I_Product.Product = t6.altyarimamul
  association to parent ZI_TKetimStoktaKalacak_S14 as _TKetimStoktaKalaAll on $projection.SingletonID = _TKetimStoktaKalaAll.SingletonID
  
{
  key t6.yarimamul as Yarimamul,
  key t6.altyarimamul as Altyarimamul,
  t6.stkklnsabitmik as Stkklnsabitmik,
  I_Product.BaseUnit,
  @Consumption.hidden: true
  1 as SingletonID,
  _TKetimStoktaKalaAll
}
