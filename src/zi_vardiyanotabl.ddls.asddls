@EndUserText.label: 'Vardiya No Tabl.'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_VardiyaNoTabl
  as select from ZPP_T_CONF_001
  association to parent ZI_VardiyaNoTabl_S as _VardiyaNoTablAll on $projection.SingletonID = _VardiyaNoTablAll.SingletonID
{
  key SHIFTNO as Shiftno,
  SHIFTDESC as Shiftdesc,
  @Consumption.hidden: true
  1 as SingletonID,
  _VardiyaNoTablAll
}
