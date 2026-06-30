@EndUserText.label: 'YM Dönüşüm Fak.Tabl.'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true

define view entity ZI_YmKurabiyeDNMFakTab
  as select from zpp_t_conf_003
  association to parent ZI_YmKurabiyeDNMFakTab_S as _YmKurabiyeDNMFakAll on $projection.SingletonID = _YmKurabiyeDNMFakAll.SingletonID
{
    

  key product     as Product,
      firinfiresi as Firinfiresi,
      @Consumption.hidden: true
      1           as SingletonID,
      _YmKurabiyeDNMFakAll
}
