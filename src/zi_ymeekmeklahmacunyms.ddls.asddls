@EndUserText.label: 'YM E.Ekmek-Lahmacun YM Stok Tabl.'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_YmEEkmekLahmacunYmS
  as select from ZPP_T_CONF_008
  association to parent ZI_YmEEkmekLahmacunYmS_S as _YmEEkmekLahmacunAll on $projection.SingletonID = _YmEEkmekLahmacunAll.SingletonID
{
  key MAMUL as Mamul,
  key YARIMAMUL as Yarimamul,
  STKKALKMIKTAR as Stkkalkmiktar,
  @Consumption.hidden: true
  1 as SingletonID,
  _YmEEkmekLahmacunAll
}
