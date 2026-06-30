@EndUserText.label: 'Duruş Kodu-Sebebi Tabl.'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_DuruKoduSebebiTabl
  as select from ZPP_T_CONF_007
  association to parent ZI_DuruKoduSebebiTabl_S as _DuruKoduSebebiTaAll on $projection.SingletonID = _DuruKoduSebebiTaAll.SingletonID
{
  key DURUSKODU as Duruskodu,
  DURUSSEBEBI as Durussebebi,
  @Consumption.hidden: true
  1 as SingletonID,
  _DuruKoduSebebiTaAll
}
