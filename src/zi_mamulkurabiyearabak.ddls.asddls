@EndUserText.label: 'Mamul Kurabiye Araba KG. Tabl.'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_MamulKurabiyeArabaK
  as select from ZPP_T_CONF_004
  association to parent ZI_MamulKurabiyeArabaK_S as _MamulKurabiyeAraAll on $projection.SingletonID = _MamulKurabiyeAraAll.SingletonID
{
  key MAMUL as Mamul,
  key YARIMAMUL as Yarimamul,
  ARABAKG as Arabakg,
  @Consumption.hidden: true
  1 as SingletonID,
  _MamulKurabiyeAraAll
}
