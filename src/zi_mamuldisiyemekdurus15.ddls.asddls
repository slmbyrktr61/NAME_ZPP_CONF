@EndUserText.label: 'Mamul Dışı Yemek Duruş Malz. Tabl.'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_MamulDisiYemekDurus15
  as select from ZPP_T_CONF_015
  association to parent ZI_MAMULDISIYEMEKDURUS as _MamulDYemekDuruMAll on $projection.SingletonID = _MamulDYemekDuruMAll.SingletonID
{
  key MALZEME as Malzeme,
  @Consumption.hidden: true
  1 as SingletonID,
  _MamulDYemekDuruMAll
}
