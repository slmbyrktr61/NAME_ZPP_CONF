@EndUserText.label: 'Üretim Türü Tabl.'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_UretimTuruTabl
  as select from ZPP_T_CONF_013
  association to parent ZI_UretimTuru_S as _UretimTuruTablAll on $projection.SingletonID = _UretimTuruTablAll.SingletonID
{
  key URETIMTURU as Uretimturu,
  @Consumption.hidden: true
  1 as SingletonID,
  _UretimTuruTablAll
}
