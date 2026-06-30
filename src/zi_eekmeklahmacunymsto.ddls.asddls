@EndUserText.label: ' E.Ekmek-Lahmacun YM Stok Tabl.'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_EEkmekLahmacunYmSto
  as select from ZPP_T_CONF_009
  association to parent ZI_EEkmekLahmacunYmSto_S as _EEkmekLahmacunYmAll on $projection.SingletonID = _EEkmekLahmacunYmAll.SingletonID
{
  key MAMUL as Mamul,
  key YARIMAMUL as Yarimamul,
  MIKTAR as Miktar,
  @Consumption.hidden: true
  1 as SingletonID,
  _EEkmekLahmacunYmAll
}
