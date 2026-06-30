@EndUserText.label: 'Kepek Malzeme Tabl.'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_KepekMalzemeTabl
  as select from ZPP_T_CONF_T012
  association to parent ZI_KepekMalzemeTabl_S12 as _KepekMalzemeTablAll on $projection.SingletonID = _KepekMalzemeTablAll.SingletonID
{
  key MALZEME as Malzeme,
  @Consumption.hidden: true
  1 as SingletonID,
  _KepekMalzemeTablAll
}
