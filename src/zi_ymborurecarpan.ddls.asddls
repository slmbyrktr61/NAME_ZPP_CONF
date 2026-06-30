@EndUserText.label: 'YM Börek Üretiminde Çarpan Sayı'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_YmBorUreCarpan
  as select from ZPP_T_CONF_005
  association to parent ZI_YmBorUreCarpan_S as _YmBorUreCarpanAAll on $projection.SingletonID = _YmBorUreCarpanAAll.SingletonID
{
  key CARPAN as Carpan,
  @Consumption.hidden: true
  1 as SingletonID,
  _YmBorUreCarpanAAll
}
