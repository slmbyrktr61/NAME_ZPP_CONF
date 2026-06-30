@EndUserText.label: 'YM Börek Üretiminde Çarpan Sayı'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_YmBRekRetimindeArpan
  as select from ZPP_T_CONF_005
  association to parent ZI_YmBRekRetimindcArpa_S as _YmBRekRetimindeAAll on $projection.SingletonID = _YmBRekRetimindeAAll.SingletonID
{
  key CARPAN as Carpan,
  @Consumption.hidden: true
  1 as SingletonID,
  _YmBRekRetimindeAAll
}
