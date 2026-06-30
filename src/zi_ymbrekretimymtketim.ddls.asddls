@EndUserText.label: 'YM Börek Üretim YM Tüketim Tabl.'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_YmBRekRetimYmTKetim
  as select from zpp_t_conf_006
  association to parent ZI_YmBRekRetimYmTKetim_S as _YmBRekRetimYmTKeAll on $projection.SingletonID = _YmBRekRetimYmTKeAll.SingletonID
{
  key yarimamul as Yarimamul,
  key altyarimamul as Altyarimamul,
  stkklnsabitmik as Stkklnsabitmik,
  @Consumption.hidden: true
  1 as SingletonID,
  _YmBRekRetimYmTKeAll
}
