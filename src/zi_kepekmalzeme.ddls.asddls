@EndUserText.label: 'Kepek Malzeme Tabl.'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_KEPEKMALZEME
  as select from ZPP_T_CONF_014
  association to parent ZI_KEPEKMALZEME_S as _KepekMalzemeTablAll on $projection.SingletonID = _KepekMalzemeTablAll.SingletonID
{
  key MALZEME as Malzeme,
  @Consumption.hidden: true
  1 as SingletonID,
  _KepekMalzemeTablAll
}
