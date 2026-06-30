@EndUserText.label: 'Iskarta Malzeme Malz.'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_IskartaMalzemeMalz
  as select from ZPP_T_CONF_012
  association to parent ZI_IskartaMalzemeMalz_S as _IskartaMalzemeMaAll on $projection.SingletonID = _IskartaMalzemeMaAll.SingletonID
{
  key MATERIAL as Material,
  key SCRAP_MATERIAL as ScrapMaterial,
  @Consumption.hidden: true
  1 as SingletonID,
  _IskartaMalzemeMaAll
}
