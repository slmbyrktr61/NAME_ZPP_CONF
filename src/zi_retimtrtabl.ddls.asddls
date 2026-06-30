@EndUserText.label: 'Üretim Türü Tabl.'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_RetimTRTabl
  as select from ZPP_T_CONF_T013
  association to parent ZI_RetimTRTablS13 as _RetimTRTablAll on $projection.SingletonID = _RetimTRTablAll.SingletonID
{
  key URETIMTURU as Uretimturu,
  @Consumption.hidden: true
  1 as SingletonID,
  _RetimTRTablAll
}
