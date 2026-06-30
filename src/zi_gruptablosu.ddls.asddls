@EndUserText.label: 'Grup Tablosu'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_GrupTablosu
  as select from ZPP_T_CONF_002
  association to parent ZI_GrupTablosu_S as _GrupTablosuAll on $projection.SingletonID = _GrupTablosuAll.SingletonID
{
  key GRUP as Grup,
  TANIM as Tanim,
  @Consumption.hidden: true
  1 as SingletonID,
  _GrupTablosuAll
}
