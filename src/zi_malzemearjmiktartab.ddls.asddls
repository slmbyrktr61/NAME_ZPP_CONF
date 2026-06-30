@EndUserText.label: 'Malzeme Şarj Miktarı Tabl.'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_MalzemeArjMiktarTab
  as select from ZPP_T_CONF_011
  association to parent ZI_MalzemeArjMiktarTab_S as _MalzemeArjMiktarAll on $projection.SingletonID = _MalzemeArjMiktarAll.SingletonID
{
  key MALZEME as Malzeme,
  SARJMIKTARI as Sarjmiktari,
  @Consumption.hidden: true
  1 as SingletonID,
  _MalzemeArjMiktarAll
}
